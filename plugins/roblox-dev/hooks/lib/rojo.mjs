// Rojo repos: a game whose code lives in a Git repo, which `rojo serve` syncs into Studio. A
// folder is a Rojo repo when it holds a `default.project.json` with a `tree`. The project maps
// files to DataModel paths, so a hook can name the script a file becomes. A repo with several
// places has no project at its root, only `places/<name>/default.project.json`: a file inside a
// place folder uses that place's project, and the root or a file outside every place folder
// (`shared/`) uses all the places' projects together.
// A pesde workspace of shared packages (a `pesde.toml` with `workspace_members`) holds game Luau
// too, but nothing maps it into a place.

import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';

const PROJECT_FILE = 'default.project.json';
const PLACES_DIR = 'places';
const PESDE_FILE = 'pesde.toml';
const MAX_DEPTH = 40;
const LUAU_FILE = /\.(luau|lua)$/i;
const SCRIPT_SUFFIX = /(\.server|\.client)?\.(luau|lua)$/i;
const INIT_FILE = /^init(\.server|\.client)?\.(luau|lua)$/i;
// pesde installs packages here and rewrites every file in it on each install.
export const INSTALLED_PACKAGES_DIR = 'roblox_packages';

export function isLuauFile(path) {
  return typeof path === 'string' && LUAU_FILE.test(path);
}

function readJson(path) {
  try {
    return JSON.parse(readFileSync(path, 'utf8'));
  } catch {
    return undefined;
  }
}

function isDirectory(path) {
  try {
    return statSync(path).isDirectory();
  } catch {
    return false;
  }
}

export function forwardSlashes(path) {
  return path.split(sep).join('/');
}

// Each project node that names a file or folder, as { instancePath, filePath }: the DataModel
// path it builds (no leading "game") and its path relative to `root`. Rojo resolves `$path`
// against the project's own folder, which may sit below `root` or mount from above it
// (`../../shared`), so filePath can start with `..`.
function mountsOf(tree, projectDir, root) {
  const mounts = [];
  const visit = (node, segments) => {
    if (!node || typeof node !== 'object') {
      return;
    }
    const nodePath = typeof node.$path === 'string' ? node.$path : node.$path?.optional;
    if (typeof nodePath === 'string' && segments.length > 0) {
      mounts.push({
        instancePath: segments.join('.'),
        filePath: forwardSlashes(relative(root, resolve(projectDir, nodePath))) || '.',
      });
    }
    for (const [key, child] of Object.entries(node)) {
      if (!key.startsWith('$')) {
        visit(child, [...segments, key]);
      }
    }
  };
  visit(tree, []);
  return mounts;
}

function insideInstalledPackages(dir) {
  return forwardSlashes(dir).split('/').includes(INSTALLED_PACKAGES_DIR);
}

// True for a path inside a `roblox_packages` folder, which pesde regenerates on every install.
// Each installed package there carries its own default.project.json, so this is checked by path
// segment rather than through the nearest project.
export function isInInstalledPackages(file) {
  return typeof file === 'string' && insideInstalledPackages(resolve(file));
}

// The parsed default.project.json in a folder when it holds a `tree`, else undefined.
function projectIn(dir) {
  const projectPath = join(dir, PROJECT_FILE);
  if (!existsSync(projectPath)) {
    return undefined;
  }
  const project = readJson(projectPath);
  return project && typeof project.tree === 'object' && project.tree !== null ? project : undefined;
}

// The places of a multi-place repo rooted at `dir` (each `places/<name>/default.project.json`
// with a `tree`), as { root, mounts, places }: mounts is the union over the places, with paths
// relative to `dir`. Undefined when no place has one.
function multiPlaceProject(dir) {
  const placesDir = join(dir, PLACES_DIR);
  if (!isDirectory(placesDir)) {
    return undefined;
  }
  let names;
  try {
    names = readdirSync(placesDir, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name)
      .sort();
  } catch {
    return undefined;
  }
  const places = [];
  for (const name of names) {
    const placeDir = join(placesDir, name);
    const project = projectIn(placeDir);
    if (project) {
      places.push({ name, mounts: mountsOf(project.tree, placeDir, dir) });
    }
  }
  if (places.length === 0) {
    return undefined;
  }
  // Places that mount the same folder at the same path (shared code, the installed packages)
  // list it once.
  const mounts = new Map();
  for (const mount of places.flatMap((place) => place.mounts)) {
    const key = `${mount.instancePath}\n${mount.filePath}`;
    if (!mounts.has(key)) {
      mounts.set(key, mount);
    }
  }
  return { root: dir, mounts: [...mounts.values()], places };
}

// The Rojo repo holding a file or folder, as { root, mounts }, or undefined outside one. The
// nearest default.project.json with a `tree` wins, so a file in a place folder of a multi-place
// repo gets that place's project; a folder without one but with place projects under `places/`
// gives the combined project (with `places` set) described at multiPlaceProject. Project files
// pesde writes into installed packages are skipped, so a package file belongs to the game.
export function findRojoProject(start) {
  if (typeof start !== 'string' || start === '') {
    return undefined;
  }
  let dir = resolve(start);
  if (!isDirectory(dir)) {
    dir = dirname(dir);
  }
  for (let depth = 0; depth < MAX_DEPTH; depth += 1) {
    if (!insideInstalledPackages(dir)) {
      const project = projectIn(dir);
      if (project) {
        return { root: dir, mounts: mountsOf(project.tree, dir, dir) };
      }
      const multiPlace = multiPlaceProject(dir);
      if (multiPlace) {
        return multiPlace;
      }
    }
    const parent = dirname(dir);
    if (parent === dir) {
      return undefined;
    }
    dir = parent;
  }
  return undefined;
}

// True inside a pesde workspace of shared packages.
export function inPesdeWorkspace(start) {
  if (typeof start !== 'string' || start === '') {
    return false;
  }
  let dir = dirname(resolve(start));
  for (let depth = 0; depth < MAX_DEPTH; depth += 1) {
    const manifest = join(dir, PESDE_FILE);
    if (existsSync(manifest)) {
      try {
        if (/^\s*workspace_members\s*=/m.test(readFileSync(manifest, 'utf8'))) {
          return true;
        }
      } catch {
        // Unreadable manifest: keep looking above it.
      }
    }
    const parent = dirname(dir);
    if (parent === dir) {
      return false;
    }
    dir = parent;
  }
  return false;
}

// True for a Luau file the hooks watch: one in a Rojo repo or a pesde workspace.
export function isWatchedLuauFile(file) {
  return isLuauFile(file) && (findRojoProject(file) !== undefined || inPesdeWorkspace(file));
}

// The file path relative to the project root, with forward slashes. It starts with `..` for a
// file above the root, which only a mount from above the project folder can map.
function relativeFile(project, file) {
  const rel = forwardSlashes(relative(project.root, resolve(file)));
  return rel === '' ? undefined : rel;
}

// The DataModel path of the script a Luau file becomes, or undefined when the project doesn't
// map the file into the place (a Lune tool, a file outside every mount).
export function instancePathOfFile(project, file) {
  const rel = relativeFile(project, file);
  if (rel === undefined || !isLuauFile(rel)) {
    return undefined;
  }
  let best;
  for (const mount of project.mounts) {
    if (rel.startsWith(`${mount.filePath}/`) && (!best || mount.filePath.length > best.filePath.length)) {
      best = mount;
    }
  }
  if (!best) {
    return undefined;
  }
  const segments = rel.slice(best.filePath.length + 1).split('/');
  const last = segments.pop();
  if (!INIT_FILE.test(last)) {
    segments.push(last.replace(SCRIPT_SUFFIX, ''));
  }
  return [best.instancePath, ...segments].join('.');
}
