/* html-kit 1.2.0
 *
 * agent-html-kit (https://github.com/leex279/agent-html-kit), restyled in a
 * plan-page theme: dark (light with <html data-theme="light">), Bricolage Grotesque / IBM Plex,
 * flat cards, mono labels.
 *
 * The design lives here, once. A document only carries content:
 *   <!doctype html><meta charset="utf-8"><script src="kit/kit.js" defer></script>
 *   <rk-header title="..."></rk-header> ...
 *
 * Components read their text content as short line-based data, so the agent
 * never writes CSS, SVG paths or table markup. See SKILL.md for the contract.
 * MIT licensed: see LICENSE beside this file.
 */
(() => {
  "use strict";

  const STYLE = `
:root{--bg:#0e1218;--panel:#151b24;--ink:#e4e9f0;--ink2:#c9d1dc;--muted:#98a3b4;--line:#273040;--soft:#1b2230;
--accent:#ff5c93;--accent-ink:#22040f;--accent-bg:#3a1424;
--err:#ff7480;--err-bg:#3a1419;--warn:#f2b65e;--warn-bg:#34250d;--info:#79b8ee;--info-bg:#12263a;--ok:#74d39a;--ok-bg:#11301e;
--bar:#4a5668;--code-bg:#090d13;--code-ink:#d6dfeb;color-scheme:dark;
--f-display:"Bricolage Grotesque","Segoe UI",system-ui,sans-serif;--f-body:"IBM Plex Sans","Segoe UI",system-ui,sans-serif;
--f-mono:"IBM Plex Mono",ui-monospace,"Cascadia Mono",Consolas,monospace}
:root[data-theme="light"]{--bg:#f3f5f8;--panel:#fff;--ink:#18202c;--ink2:#2b3442;--muted:#586374;--line:#dbe0e8;--soft:#eceff4;
--accent:#d81b60;--accent-ink:#fff;--accent-bg:#fbe3ec;
--err:#b8232f;--err-bg:#fbe4e6;--warn:#8f5400;--warn-bg:#fbefd9;--info:#1f5f93;--info-bg:#e0edf8;--ok:#1f7040;--ok-bg:#dff2e5;
--bar:#a7b2c2;--code-bg:#111822;color-scheme:light}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
@media (prefers-reduced-motion:reduce){html{scroll-behavior:auto}}
html,body{margin:0}
body.rk{background:var(--bg);color:var(--ink);font:400 15px/1.6 var(--f-body)}
.rk a{color:inherit;text-underline-offset:3px}
.rk a:focus-visible,.rk button:focus-visible,.rk-item:focus-visible{outline:2px solid var(--accent);outline-offset:2px;border-radius:4px}
.rk-wrap{max-width:1200px;margin:0 auto;padding:40px max(16px,env(safe-area-inset-right,0px)) 96px max(16px,env(safe-area-inset-left,0px))}
.rk-wrap.toc{display:grid;grid-template-columns:210px minmax(0,1fr);gap:48px}
.rk-wrap:not(.toc) .rk-page{max-width:940px;margin:0 auto}
@media (max-width:920px){.rk-wrap.toc{grid-template-columns:minmax(0,1fr);gap:0}.rk-toc{display:none}}
.rk-toc{position:sticky;top:28px;align-self:start;font-size:13.5px}
.rk-toc p{font:600 11px/1 var(--f-mono);letter-spacing:.08em;text-transform:uppercase;color:var(--muted);margin:0 0 12px}
.rk-toc ol{list-style:none;margin:0;padding:0;display:grid;gap:2px}
.rk-toc a{display:block;padding:5px 10px;border-radius:6px;text-decoration:none;color:var(--muted)}
.rk-toc a:hover{background:var(--soft);color:var(--ink)}
.rk-page{min-width:0}
.rk-page h1,.rk-page h2,.rk-page h3{font-family:var(--f-display);text-wrap:balance;letter-spacing:-.01em}
.rk-page>h1{font-size:clamp(34px,5vw,48px);font-weight:800;line-height:1.05;margin:0 0 18px}
.rk-page h2{font-size:28px;font-weight:800;line-height:1.15;margin:64px 0 12px;scroll-margin-top:24px}
.rk-page h3{font-size:19px;font-weight:600;line-height:1.25;margin:32px 0 8px}
.rk-page h4,.rk-page h5,.rk-page h6{font:600 12px/1.2 var(--f-mono);letter-spacing:.08em;text-transform:uppercase;color:var(--muted);margin:24px 0 8px}
.rk-page p{margin:0 0 12px;max-width:70ch;color:var(--ink2)}
.rk-page ul,.rk-page ol{margin:0 0 14px;padding-left:22px;max-width:70ch;color:var(--ink2)}
.rk-page li{margin:4px 0}
.rk-page li>ul,.rk-page li>ol{margin:4px 0 0}
.rk-page li.rk-task{list-style:none;margin-left:-22px}
.rk-page li.rk-task input{margin-right:8px;accent-color:var(--accent)}
.rk-page b,.rk-page strong{color:var(--ink);font-weight:600}
.rk-page code{font-family:var(--f-mono);font-size:.88em;color:var(--ink)}
.rk-page pre{background:var(--code-bg);color:var(--code-ink);padding:18px 20px;border-radius:12px;overflow:auto;font:400 12.8px/1.65 var(--f-mono);margin:0 0 16px}
.rk-page pre code{color:inherit;font-size:inherit}
.rk-page blockquote{margin:0 0 14px;padding:10px 16px;border-left:4px solid var(--line);color:var(--ink2)}
.rk-page hr{border:0;border-top:1px solid var(--line);margin:40px 0}
.rk-page img{max-width:100%;height:auto;border-radius:8px;border:1px solid var(--line)}
.rk-page footer{margin-top:72px;padding-top:18px;border-top:1px solid var(--line);color:var(--muted);font-size:13px}
.rk-id{font:600 12px var(--f-mono);color:var(--ink);background:var(--soft);border:1px solid var(--line);padding:1px 6px;border-radius:5px;white-space:nowrap}
rk-cols,.rk-cols{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:14px;align-items:start;margin:0 0 16px}
.rk-col{min-width:0}
.rk-col>h2:first-child,.rk-col>h3:first-child{margin-top:8px}
.rk-card{background:var(--panel);border:1px solid var(--line);border-radius:14px;min-width:0}
.rk-ctitle{font:600 16px/1.3 var(--f-display);margin:0 0 12px;color:var(--ink)}
rk-header{display:block}
.rk-hero{margin:0 0 8px}
.rk-hero .tag{font:600 12px/1.3 var(--f-mono);letter-spacing:.08em;text-transform:uppercase;color:var(--muted)}
.rk-hero .t{font-family:var(--f-display);font-size:clamp(38px,6vw,60px);font-weight:800;line-height:1.02;letter-spacing:-.01em;margin:14px 0 0;text-wrap:balance}
.rk-hero .tag+.t{margin-top:14px}.rk-hero .t:first-child{margin-top:0}
.rk-hero .s{font-size:18px;line-height:1.55;max-width:66ch;margin:18px 0 0;color:var(--ink2)}
.rk-stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:1px;margin:24px 0;background:var(--line);border:1px solid var(--line);border-radius:12px;overflow:hidden}
rk-header+rk-stats .rk-stats{margin-top:32px}
.rk-stat{background:var(--panel);padding:16px 18px}
.rk-stat .v{font:800 30px/1 var(--f-display);font-variant-numeric:tabular-nums;color:var(--ink)}
.rk-stat .l{margin-top:6px;color:var(--muted);font-size:13px;line-height:1.35}
.rk-stat .n{margin-top:6px;font:500 12px/1.3 var(--f-mono);color:var(--muted)}
.rk-stat .n.good{color:var(--ok)}.rk-stat .n.bad{color:var(--err)}
.rk-tablewrap{overflow-x:auto;margin:0 0 16px;border:1px solid var(--line);border-radius:12px;background:var(--panel)}
.rk-page table{width:100%;border-collapse:collapse;font-size:13.5px}
.rk-page th{text-align:left;font:600 11px/1.2 var(--f-mono);letter-spacing:.06em;text-transform:uppercase;color:var(--muted);background:var(--soft);padding:10px 14px;border-bottom:1px solid var(--line)}
.rk-page td{padding:10px 14px;border-bottom:1px solid var(--line);vertical-align:top;color:var(--ink2);overflow-wrap:anywhere}
.rk-page td code{overflow-wrap:normal}
.rk-page tr:last-child td{border-bottom:0}
.rk-page tr.rk-hot td:first-child{box-shadow:inset 3px 0 0 var(--err)}
.rk-page td.rk-strong{font-weight:600;color:var(--ink)}
.rk-sum{padding:14px 16px 12px;border-bottom:1px solid var(--line)}
.rk-sum .bar{display:flex;height:8px;border-radius:99px;overflow:hidden;gap:3px}
.rk-sum .bar span{display:block}
.rk-sum .leg{display:flex;flex-wrap:wrap;gap:6px 16px;margin-top:9px;font-size:13px;color:var(--muted)}
.rk-sum .leg b{color:var(--ink)}
.rk-sum .dot{display:inline-block;width:8px;height:8px;border-radius:50%;margin-right:6px}
.rk-pill{display:inline-block;font:600 11px/1 var(--f-mono);letter-spacing:.04em;text-transform:uppercase;padding:5px 8px;border-radius:6px;white-space:nowrap;vertical-align:1px}
.rk-pill.done,.rk-pill.ok{color:var(--ok);background:var(--ok-bg)}
.rk-pill.progress{color:var(--info);background:var(--info-bg)}
.rk-pill.blocked,.rk-pill.fail{color:var(--err);background:var(--err-bg)}
.rk-pill.warn{color:var(--warn);background:var(--warn-bg)}
.rk-pill.todo{color:var(--muted);background:var(--soft)}
rk-pill{display:contents}
.rk-callout{background:var(--panel);border:1px solid var(--line);border-left:4px solid var(--info);border-radius:10px;padding:12px 16px;margin:0 0 10px;color:var(--ink2);max-width:none}
.rk-callout>b:first-child{font-family:var(--f-display);font-weight:600;color:var(--ink)}
.rk-callout.risk{border-left-color:var(--err)}.rk-callout.warn{border-left-color:var(--warn)}
.rk-callout.ok{border-left-color:var(--ok)}.rk-callout.lesson{border-left-color:var(--accent)}
.rk-chart,.rk-diagram{padding:16px 18px 18px;margin:0 0 16px}
.rk-chart svg,.rk-diagram svg{display:block;width:100%;height:auto}
.rk-scroll{overflow-x:auto}.rk-chart .rk-scroll>svg{min-width:600px}
.rk-chart text,.rk-diagram text{font-family:var(--f-body);fill:var(--muted)}
.rk-chart .val{fill:var(--ink);font-family:var(--f-mono);font-weight:600}
.rk-chart .tick{fill:var(--muted);font-family:var(--f-mono)}
.rk-chart .grid{stroke:var(--line)}
.rk-chart .mk{fill:var(--bar)}.rk-chart .mk.peak{fill:var(--accent)}
.rk-chart .val.peak{fill:var(--accent)}
.rk-chart .avg{stroke:var(--warn)}.rk-chart text.avg{fill:var(--warn);stroke:none;font-family:var(--f-mono);font-weight:600}
.rk-chart .ln{stroke:var(--accent)}.rk-chart .pt{fill:var(--panel);stroke:var(--accent)}
.rk-diagram .edge{stroke:var(--muted)}.rk-diagram .arrow{fill:var(--muted)}
.rk-diagram .lab{fill:var(--panel);stroke:var(--line)}.rk-diagram text.lab{fill:var(--muted);stroke:none}
.rk-diagram text.name{fill:var(--ink);font-weight:600}
.rk-diagram .node{fill:var(--panel);stroke:var(--ink)}
.rk-diagram .node.user{fill:var(--info-bg);stroke:var(--info)}
.rk-diagram .node.db{fill:var(--ok-bg);stroke:var(--ok)}
.rk-diagram .node.queue{fill:var(--warn-bg);stroke:var(--warn)}
.rk-diagram .node.cache{fill:var(--accent-bg);stroke:var(--accent)}
.rk-diagram .node.ext{fill:var(--soft);stroke:var(--muted)}
.rk-steps,.rk-decide{list-style:none;padding:0!important;margin:0 0 16px!important;display:grid;gap:10px;max-width:none!important}
.rk-steps{counter-reset:s}
.rk-steps li{display:flex;gap:14px;align-items:flex-start;padding:14px 16px;margin:0}
.rk-steps li::before{counter-increment:s;content:counter(s);flex:none;width:22px;height:22px;border-radius:50%;display:grid;place-items:center;margin-top:1px;
background:var(--ink);color:var(--bg);font:600 12px/1 var(--f-mono)}
.rk-steps .st,.rk-decide .st{font-family:var(--f-display);font-weight:600;font-size:16px;color:var(--ink)}
.rk-steps .sd,.rk-decide .sd{color:var(--muted);font-size:14px;line-height:1.5}
.rk-decide{counter-reset:d}
.rk-decide li{position:relative;padding:14px 16px 14px 52px;margin:0}
.rk-decide li::before{counter-increment:d;content:"D" counter(d);position:absolute;left:14px;top:16px;font:600 12px/1 var(--f-mono);color:var(--accent)}
.rk-board{margin:0 0 16px}
.rk-board .bar{display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap;margin-bottom:10px}
.rk-board .lanes{display:grid;gap:12px;grid-template-columns:repeat(var(--n),minmax(0,1fr))}
.rk-lane{background:var(--soft);border:1px solid var(--line);border-radius:12px;padding:10px;min-height:160px;transition:background .15s}
.rk-lane.over{background:var(--info-bg)}
.rk-lane.inbox{display:grid;grid-template-columns:repeat(auto-fill,minmax(210px,1fr));gap:8px;min-height:90px;margin-bottom:12px;border-style:dashed}
.rk-lane.inbox .lh{grid-column:1/-1;padding-bottom:2px}.rk-lane.inbox .rk-item{margin:0}
.rk-lane .lh{display:flex;justify-content:space-between;font:600 11px/1.2 var(--f-mono);letter-spacing:.06em;text-transform:uppercase;color:var(--muted);padding:2px 4px 8px}
.rk-item{background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:9px 11px;margin-bottom:8px;cursor:grab;font-size:13.5px;color:var(--ink2)}
.rk-item .id{font:600 11.5px var(--f-mono);color:var(--muted)}
.rk-item.drag{opacity:.4}
.rk-item.pick{outline:2px solid var(--accent);outline-offset:1px}
.rk-board .hint{font-size:12.5px;color:var(--muted);margin:-4px 0 10px}
@media (max-width:700px){.rk-board .lanes{grid-template-columns:repeat(2,minmax(0,1fr))}}
.rk-btn{font:500 13px/1 var(--f-body);color:var(--bg);background:var(--ink);border:1px solid var(--ink);border-radius:999px;padding:8px 12px;cursor:pointer}
.rk-out{width:100%;min-height:120px;margin-top:10px;font:12.8px/1.5 var(--f-mono);color:var(--ink);background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:10px;display:none}
body.rk-plain .rk-page h2{font-size:24px;border-bottom:1px solid var(--line);padding-bottom:6px;margin:32px 0 14px}
body.rk-plain .rk-page th{text-transform:none;font:600 13px var(--f-body);letter-spacing:0;color:var(--ink)}
.rk-options{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:14px;margin:0 0 16px}
.rk-opt{padding:16px 18px 18px}
.rk-opt.rec{border-color:var(--accent)}
.rk-opt .oh{display:flex;align-items:center;gap:10px;flex-wrap:wrap}
.rk-opt .on{font:600 18px/1.25 var(--f-display);color:var(--ink)}
.rk-opt .rec-tag{font:600 11px/1 var(--f-mono);letter-spacing:.04em;text-transform:uppercase;padding:5px 8px;border-radius:6px;color:var(--accent);background:var(--accent-bg)}
.rk-page .rk-opt .os{margin:6px 0 0;color:var(--muted);font-size:14px}
.rk-page .rk-opt ul{list-style:none;margin:12px 0 0;padding:0;display:grid;gap:6px;max-width:none}
.rk-opt li{display:flex;gap:10px;margin:0;font-size:14px;line-height:1.45;color:var(--ink2)}
.rk-opt li::before{flex:none;width:12px;font:600 13px/1.45 var(--f-mono);text-align:center}
.rk-opt li.pro::before{content:"+";color:var(--ok)}.rk-opt li.con::before{content:"−";color:var(--err)}.rk-opt li.note::before{content:"·";color:var(--muted)}
.rk-tree{padding:16px 18px;margin:0 0 16px}
.rk-page .rk-tree ul{list-style:none;margin:0;padding:0;max-width:none}
.rk-page .rk-tree ul ul{margin-left:7px;padding-left:16px;border-left:1px solid var(--line)}
.rk-page .rk-tree li{margin:0;padding:3px 0;white-space:nowrap}
.rk-tree .tn{font:500 13.5px/1.5 var(--f-mono);color:var(--ink)}
.rk-tree .tc{font:500 11px/1 var(--f-mono);color:var(--muted);border:1px solid var(--line);border-radius:5px;padding:2px 5px;margin-left:8px;vertical-align:1px}
.rk-tree .tc.script{color:var(--info)}.rk-tree .tc.remote{color:var(--warn)}
.rk-tree .tt{color:var(--muted);font-size:13px;margin-left:10px}
@media (max-width:600px){.rk-tree .tt{display:block;margin:0 0 2px;white-space:normal}}
.rk-tree .add>.tn{color:var(--ok)}.rk-tree .add>.tn::before{content:"+ "}
.rk-tree .chg>.tn{color:var(--warn)}.rk-tree .chg>.tn::before{content:"~ "}
.rk-tree .del>.tn{color:var(--err);text-decoration:line-through}.rk-tree .del>.tn::before{content:"− "}
.rk-diagram .node.client{fill:var(--info-bg);stroke:var(--info)}
.rk-diagram .node.remote{fill:var(--warn-bg);stroke:var(--warn)}
.rk-seq .life{stroke:var(--line)}
.rk-seq text.msg{fill:var(--ink2)}.rk-seq .msgbg{fill:var(--panel)}
.rk-seq .seqn{fill:var(--ink)}.rk-seq text.seqn{fill:var(--bg);font-family:var(--f-mono);font-weight:600}
.rk-seq .bound{stroke:var(--accent)}.rk-seq text.bound{fill:var(--accent);stroke:none;font-family:var(--f-mono);font-weight:600;letter-spacing:.06em}
.rk-seq .noteb{fill:var(--soft);stroke:var(--line)}
.rk-page pre .lx-k{color:#ff7eb6}.rk-page pre .lx-s{color:#9ed9a6}.rk-page pre .lx-n{color:#f2b65e}
.rk-page pre .lx-c{color:#7d8aa0;font-style:italic}.rk-page pre .lx-g{color:#79b8ee}
:root{scrollbar-color:var(--line) transparent}
.rk-page pre,.rk-scroll,.rk-tablewrap{scrollbar-width:thin}
`;

  const PILLS = {
    done: "Done", progress: "In progress", blocked: "Blocked", todo: "To do",
    ok: "OK", warn: "At risk", fail: "Failed",
  };
  const FONTS = "https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,600;12..96,800&family=IBM+Plex+Mono:wght@400;500;600&family=IBM+Plex+Sans:wght@400;500;600&display=swap";
  // A page with this many h2 sections or more gets the contents rail.
  const TOC_MIN = 4;

  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const pill = (k, label) => `<span class="rk-pill ${esc(k)}">${esc(label || PILLS[k] || k)}</span>`;

  // Inline markdown subset: **bold**, *italic*, ~~strike~~, `code`, [text](url), ![alt](src), [done]-style pills.
  // Code spans stay literal; only the text between them is formatted.
  function inline(s, pills = true) {
    return String(s).split(/(`[^`]+`)/).map((part, i) => (i % 2 ? `<code>${esc(part.slice(1, -1))}</code>` : prose(part, pills))).join("");
  }
  function prose(s, pills) {
    // Link and image tags are parked as placeholders, so bold/pill/ID rules never touch an href.
    const keep = [];
    const hold = (html) => `\u0000${keep.push(html) - 1}\u0000`;
    let out = esc(s).replace(/\u0000/g, "");
    out = out.replace(/!\[([^\]]*)\]\(([^)\s]+)\)/g, (m, alt, u) => (safeUrl(u) ? hold(`<img src="${u}" alt="${alt}">`) : alt));
    out = out.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (m, t, u) => (safeUrl(u) ? hold(`<a href="${u}">`) + t + hold("</a>") : t));
    out = out.replace(/\*\*([^*]+)\*\*/g, "<b>$1</b>");
    out = out.replace(/(^|[^*])\*([^*\s][^*]*)\*/g, "$1<i>$2</i>");
    out = out.replace(/~~([^~]+)~~/g, "<s>$1</s>");
    if (pills) {
      out = out.replace(/\[(done|progress|blocked|todo|ok|warn|fail)\]/gi, (_, k) => pill(k.toLowerCase()));
      out = chipIds(out);
    }
    return out.replace(/\u0000(\d+)\u0000/g, (_, k) => keep[k]);
  }
  // Links and images: http(s), mailto, anchors and relative paths only (no javascript: and friends).
  const safeUrl = (u) => !/[\x00-\x1f]/.test(u) && (/^(https?:|mailto:|#|\/|\.)/i.test(u) || !/^[a-z][a-z0-9+.-]*:/i.test(u));
  // Ticket-style IDs (CHK-104, ENG-12) become mono chips, outside of tags only. UTF-8, SHA-256 & co. are not tickets.
  const NOT_ID = /^(UTF|SHA|ISO|GPT|RFC|CVE|ES|MP|AES|RSA|TLS|SSL|HTTP|IPV|PEP|COVID|ECMA|RTX|GTX|ANSI)-/;
  const chipIds = (html) => html.replace(/(<[^>]+>)|\b([A-Z][A-Z0-9]{1,9}-\d+)\b/g, (m, tag, id) => tag || (NOT_ID.test(id) ? id : `<span class="rk-id">${id}</span>`));

  // Raw text of a component, whether written as text or inside <script type="text/plain">.
  function rawText(el) {
    const s = el.querySelector(':scope > script[type^="text/"]');
    // md2html writes "<\/script" so a script tag inside the markdown cannot end the block early.
    return (s ? s.textContent.replace(/<\\\/script/gi, "</script") : el.textContent);
  }
  const lines = (txt) => txt.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
  const cells = (l) => l.replace(/^\|/, "").replace(/\|$/, "").split("|").map((c) => c.trim());

  // "key: value" header lines at the top of a block (used by markdown fences).
  function splitMeta(ls, keys) {
    const meta = {};
    while (ls.length) {
      const m = ls[0].match(/^(\w+):\s*(.*)$/);
      if (!m || !keys.includes(m[1].toLowerCase())) break;
      meta[m[1].toLowerCase()] = m[2];
      ls.shift();
    }
    return meta;
  }

  /* ---------- components ---------- */

  function header(el) {
    const tag = el.getAttribute("tag");
    el.innerHTML = `<header class="rk-hero">${tag ? `<div class="tag">${inline(tag, false)}</div>` : ""}<h1 class="t">${inline(el.getAttribute("title") || "")}</h1>${
      el.getAttribute("sub") || el.getAttribute("period") ? `<p class="s">${inline(el.getAttribute("sub") || el.getAttribute("period"))}</p>` : ""}</header>`;
  }

  function stats(el, ls) {
    // Lines "value | label | note", or child <rk-stat value label note|delta> elements.
    let rows = [];
    const kids = el.querySelectorAll("rk-stat");
    if (kids.length) rows = [...kids].map((k) => [k.getAttribute("value"), k.getAttribute("label"), k.getAttribute("note") || k.getAttribute("delta") || ""]);
    else rows = (ls || lines(rawText(el))).map(cells);
    el.innerHTML = `<div class="rk-stats">${rows.map(([v, l, n]) => {
      let cls = "";
      if (n && /^\+/.test(n)) cls = "good";
      if (n && /^!/.test(n)) cls = "bad";
      return `<div class="rk-stat"><div class="v">${inline(v || "")}</div><div class="l">${inline(l || "")}</div>${n ? `<div class="n ${cls}">${inline(n.replace(/^[+!]\s*/, ""))}</div>` : ""}</div>`;
    }).join("")}</div>`;
  }

  function table(el, ls, pills = true) {
    ls = (ls || lines(rawText(el))).filter((l) => !/^\|?\s*:?-{2,}/.test(l));
    if (!ls.length) return;
    const [head, ...rows] = ls.map(cells);
    const idCol = pills && rows.length && rows.every((r) => /^[A-Z][A-Z0-9]{1,9}-\d+$/.test(r[0] || ""));
    // Status summary bar, computed from the pills in the table: zero tokens for the agent.
    const counts = {};
    if (pills) rows.forEach((r) => r.forEach((c) => (c.match(/\[(done|progress|blocked|todo|ok|warn|fail)\]/gi) || []).forEach((t) => {
      const k = t.slice(1, -1).toLowerCase(); counts[k] = (counts[k] || 0) + 1;
    })));
    const COL = { done: "var(--ok)", ok: "var(--ok)", progress: "var(--info)", blocked: "var(--err)", fail: "var(--err)", warn: "var(--warn)", todo: "var(--bar)" };
    const total = Object.values(counts).reduce((a, b) => a + b, 0);
    const order = ["done", "ok", "progress", "warn", "todo", "blocked", "fail"].filter((k) => counts[k]);
    const sum = total > 2 ? `<div class="rk-sum"><div class="bar">${order.map((k) => `<span style="flex:${counts[k]};background:${COL[k]}"></span>`).join("")}</div><div class="leg">${
      order.map((k) => `<span><span class="dot" style="background:${COL[k]}"></span><b>${counts[k]}</b> ${esc((PILLS[k] || k).toLowerCase())}</span>`).join("")}</div></div>` : "";
    const row = (r) => {
      const hot = pills && r.some((c) => /\[(blocked|fail)\]/i.test(c));
      return `<tr${hot ? ' class="rk-hot"' : ""}>${head.map((_, i) => `<td${idCol && i === 1 ? ' class="rk-strong"' : ""}>${inline(r[i] || "", pills)}</td>`).join("")}</tr>`;
    };
    el.innerHTML = `<div class="rk-tablewrap">${sum}<table><thead><tr>${head.map((h) => `<th>${inline(h, pills)}</th>`).join("")}</tr></thead><tbody>${
      rows.map(row).join("")}</tbody></table></div>`;
  }

  function callout(el, kind, title, bodyHtml) {
    kind = kind || el.getAttribute("kind") || "note";
    title = title ?? el.getAttribute("title");
    const body = bodyHtml ?? el.innerHTML.trim();
    el.innerHTML = `<div class="rk-callout ${esc(kind)}">${title ? `<b>${inline(title)}</b> ` : ""}${body}</div>`;
  }

  // "Label: 1,234.5" or "Label | 1e3". dp = decimals as written, so a value is shown the way it was given.
  function parsePoints(ls) {
    return ls.map((l) => {
      const m = l.match(/^(.*?)\s*[:|]\s*(-?(?:\d[\d,]*)?\.?\d+(?:e[+-]?\d+)?)\s*(\S*)$/i);
      if (!m) return null;
      const raw = m[2].replace(/,/g, ""), value = Number(raw);
      const dp = /e/i.test(raw) ? null : (raw.split(".")[1] || "").length;
      return Number.isFinite(value) ? { label: m[1], value, dp } : null;
    }).filter(Boolean);
  }

  function chart(el, ls, meta) {
    meta = meta || {};
    const type = (meta.type || el.getAttribute("type") || "bar").toLowerCase();
    const title = meta.title || el.getAttribute("title") || "";
    const unit = esc(meta.unit || el.getAttribute("unit") || "");
    let pts;
    const attr = el.getAttribute("data");
    if (!ls && attr) pts = parsePoints(attr.split(","));
    else pts = parsePoints(ls || lines(rawText(el)));
    if (!pts.length) return;
    if (pts.some((p) => p.value < 0)) {
      // Bars grow from zero; a negative value would be drawn wrong, so say so instead of guessing.
      el.innerHTML = `<div class="rk-callout warn"><b>Chart not drawn.</b> rk-chart supports values of 0 or more.</div>`;
      return;
    }
    const max = Math.max(...pts.map((p) => p.value), 0) || 1;
    const nice = niceMax(max);
    const fmt = (v, dp) => (dp == null ? num(v) : v.toFixed(dp)) + unit;
    let svg;
    if (type === "hbar") {
      const rowH = 34, labW = 170, W = 640, H = pts.length * rowH + 10;
      svg = `<svg viewBox="0 0 ${W} ${H}">${pts.map((p, i) => {
        const w = ((W - labW - 60) * p.value) / nice, y = i * rowH + 6;
        return `<text x="${labW - 10}" y="${y + 17}" text-anchor="end" font-size="13">${esc(p.label)}</text>
<rect class="mk" x="${labW}" y="${y + 3}" width="${Math.max(w, 2)}" height="20" rx="4"/>
<text class="val" x="${labW + w + 8}" y="${y + 17}" font-size="12.5">${fmt(p.value, p.dp)}</text>`;
      }).join("")}</svg>`;
    } else {
      const W = 900, H = 300, L = 40, B = 34, T = 22, R = 84;
      const pw = W - L - R, ph = H - B - T;
      const grid = [0, 0.25, 0.5, 0.75, 1].map((f) => {
        const y = T + ph - f * ph;
        return `<line class="grid" x1="${L}" x2="${W - R}" y1="${y}" y2="${y}"/><text class="tick" x="${L - 8}" y="${y + 4}" text-anchor="end" font-size="11">${fmt(nice * f)}</text>`;
      }).join("");
      const step = pw / pts.length;
      const xy = pts.map((p, i) => [L + step * i + step / 2, T + ph - (p.value / nice) * ph]);
      const labels = pts.map((p, i) => `<text x="${xy[i][0]}" y="${H - 12}" text-anchor="middle" font-size="12">${esc(p.label)}</text>`).join("");
      let marks;
      if (type === "line") {
        marks = `<polyline class="ln" points="${xy.map((q) => q.join(",")).join(" ")}" fill="none" stroke-width="2.5" stroke-linejoin="round"/>` +
          xy.map((q, i) => `<circle class="pt" cx="${q[0]}" cy="${q[1]}" r="4.5" stroke-width="2.5"/><text class="val" x="${q[0]}" y="${q[1] - 12}" text-anchor="middle" font-size="12">${fmt(pts[i].value, pts[i].dp)}</text>`).join("");
      } else {
        // Peak bar and average line are derived here, so the agent never writes them.
        const bw = Math.min(64, step * 0.5);
        const peak = Math.max(...pts.map((p) => p.value));
        const showAvg = pts.length >= 3 && !el.hasAttribute("noavg") && !meta.noavg;
        const avg = pts.reduce((a, p) => a + p.value, 0) / pts.length;
        marks = xy.map((q, i) => {
          const top = pts[i].value === peak;
          const hi = top ? " peak" : "";
          return `<rect class="mk${hi}" x="${q[0] - bw / 2}" y="${Math.min(q[1], T + ph)}" width="${bw}" height="${Math.max(0, T + ph - q[1])}" rx="4"/><text class="val${hi}" x="${q[0]}" y="${q[1] - 8}" text-anchor="middle" font-size="12.5">${fmt(pts[i].value, pts[i].dp)}</text>`;
        }).join("");
        if (showAvg) {
          const ay = T + ph - (avg / nice) * ph;
          marks += `<line class="avg" x1="${L}" x2="${W - R + 4}" y1="${ay}" y2="${ay}" stroke-width="1.5" stroke-dasharray="6 5"/><text class="avg" x="${W - R + 8}" y="${ay + 4}" font-size="11.5">avg ${fmt(avg)}</text>`;
        }
      }
      svg = `<svg viewBox="0 0 ${W} ${H}">${grid}${marks}${labels}</svg>`;
    }
    el.innerHTML = `<div class="rk-card rk-chart">${title ? `<div class="rk-ctitle">${inline(title)}</div>` : ""}<div class="rk-scroll">${svg}</div></div>`;
  }
  // Axis ticks and the average: three to four significant digits, no float noise (0.07500000001 -> 0.075).
  const num = (v) => (Number.isInteger(v) ? String(v) : String(+v.toPrecision(Math.abs(v) >= 1 ? 4 : 3)));
  function niceMax(v) {
    const p = Math.pow(10, Math.floor(Math.log10(v)));
    for (const m of [1, 1.2, 1.6, 2, 2.4, 3, 4, 5, 6, 8, 10]) if (m * p >= v) return m * p; // quarters stay round
    return 10 * p;
  }

  // Diagram: "A -> B: label" edges, "Name [db]" node kinds. Layered left-to-right layout.
  const KINDS = new Set(["svc", "user", "db", "queue", "cache", "ext"]);
  // A diagram never draws its text smaller than this share of full size; past that it scrolls.
  const MIN_SCALE = 0.8;
  // Edge labels longer than this wrap onto two lines, so one long label can't widen a whole gap.
  const LABEL_WRAP = 22;
  function labelLines(text) {
    if (text.length <= LABEL_WRAP) return [text];
    const mid = text.length / 2;
    let cut = -1;
    for (let i = 0; i < text.length; i++) if (text[i] === " " && (cut < 0 || Math.abs(i - mid) < Math.abs(cut - mid))) cut = i;
    return cut < 0 ? [text] : [text.slice(0, cut), text.slice(cut + 1)];
  }
  function diagram(el, ls, meta) {
    meta = meta || {};
    const title = meta.title || el.getAttribute("title") || "";
    ls = ls || lines(rawText(el));
    const nodes = new Map(), edges = [];
    const node = (tok) => {
      const m = tok.trim().match(/^(.*?)\s*(?:\[(\w+)\])?$/);
      const name = m[1].trim();
      if (!nodes.has(name)) nodes.set(name, { name, kind: "svc", out: [], inn: [] });
      if (m[2]) nodes.get(name).kind = m[2].toLowerCase();
      return nodes.get(name);
    };
    for (const l of ls) {
      const m = l.match(/^(.+?)\s*(-->|->|<->|--)\s*(.+?)(?:\s*:\s*(.+))?$/);
      if (m) {
        const a = node(m[1]), b = node(m[3]);
        const e = { a, b, label: m[4] || "", both: m[2] === "<->", plain: m[2] === "--" };
        edges.push(e); a.out.push(e); b.inn.push(e);
      } else node(l.replace(/:.*$/, ""));
    }
    if (!nodes.size) return;
    // Layer = longest path from a source, ignoring back edges (DFS order).
    const order = [...nodes.values()], state = new Map(), back = new Set();
    const visit = (n) => {
      state.set(n, 1);
      for (const e of n.out) {
        if (state.get(e.b) === 1) back.add(e);
        else if (!state.get(e.b)) visit(e.b);
      }
      state.set(n, 2);
    };
    order.filter((n) => !n.inn.length).concat(order).forEach((n) => !state.get(n) && visit(n));
    const layer = new Map();
    const busy = new Set();
    const depth = (n) => {
      if (layer.has(n)) return layer.get(n);
      if (busy.has(n)) return 0; // only reachable through an undetected cycle
      busy.add(n);
      let d = 0;
      for (const e of n.inn) if (!back.has(e)) d = Math.max(d, depth(e.a) + 1);
      busy.delete(n);
      layer.set(n, d);
      return d;
    };
    order.forEach((n) => depth(n));
    const layers = [];
    order.forEach((n) => (layers[layer.get(n)] ||= []).push(n));
    // Two barycenter sweeps to reduce crossings.
    const pos = new Map();
    layers.forEach((L) => L.forEach((n, i) => pos.set(n, i)));
    for (let pass = 0; pass < 2; pass++) {
      for (let i = 1; i < layers.length; i++) {
        layers[i].sort((x, y) => bary(x) - bary(y));
        layers[i].forEach((n, k) => pos.set(n, k));
      }
    }
    function bary(n) {
      const ps = n.inn.filter((e) => !back.has(e)).map((e) => pos.get(e.a));
      return ps.length ? ps.reduce((a, b) => a + b, 0) / ps.length : pos.get(n);
    }
    const NH = 46, VG = 30, CW = 7.6;
    const widthOf = (n) => Math.max(110, n.name.length * CW + 36);
    const labW = (e) => (e.label ? Math.max(...labelLines(e.label).map((s) => s.length)) * 6.6 + 16 : 0);
    // The card's inner width: the card adds 18px padding and a 1px border on each side.
    const avail = Math.max(240, (el.parentElement?.clientWidth || 880) - 38);
    const dir = (meta.direction || el.getAttribute("direction") || (layers.length > 6 ? "down" : "right")).toLowerCase();
    if (dir === "down") {
      const out = layoutDown({ layers, edges, layer, back, widthOf, labW, NH });
      return finishDiagram(el, title, out.W, out.H, out.paths, order, NH);
    }
    // Fan-out edges carry their label next to the target, fan-in edges next to the source,
    // so labels sit on straight segments where the edges have already separated.
    const fwd = edges.filter((e) => layer.get(e.b) > layer.get(e.a));
    fwd.forEach((e) => (e.atTarget = e.a.out.length >= e.b.inn.length));
    const gap = layers.map((_, i) => {
      let need = 0;
      for (const e of fwd) {
        if (e.atTarget && layer.get(e.b) === i + 1) need = Math.max(need, labW(e));
        if (!e.atTarget && layer.get(e.a) === i) need = Math.max(need, labW(e));
      }
      return Math.max(72, need + 64);
    });
    const colW = layers.map((L) => Math.max(...L.map(widthOf)));
    const colH = layers.map((L) => L.length * NH + (L.length - 1) * VG);
    const H = Math.max(...colH) + 40;
    let x = 16;
    layers.forEach((L, i) => {
      const y0 = (H - colH[i]) / 2;
      L.forEach((n, k) => { n.w = widthOf(n); n.x = x + (colW[i] - n.w) / 2; n.y = y0 + k * (NH + VG); });
      x += colW[i] + (i < layers.length - 1 ? gap[i] : 0);
    });
    const W = x + 16;
    const paths = edges.map((e) => {
      const { a, b } = e;
      const lw = labW(e);
      let d, lx, ly;
      if (layer.get(b) > layer.get(a)) {
        const x1 = a.x + a.w, y1 = a.y + NH / 2, x2 = b.x - 4, y2 = b.y + NH / 2;
        if (!lw) {
          const mx = (x1 + x2) / 2;
          d = `M${x1},${y1} C${mx},${y1} ${mx},${y2} ${x2},${y2}`;
        } else if (e.atTarget) {
          const xe = x2 - lw - 22, cx = (x1 + xe) / 2;
          d = `M${x1},${y1} C${cx},${y1} ${cx},${y2} ${xe},${y2} L${x2},${y2}`; lx = x2 - 12 - lw / 2; ly = y2;
        } else {
          const xs = x1 + lw + 22, cx = (xs + x2) / 2;
          d = `M${x1},${y1} L${xs},${y1} C${cx},${y1} ${cx},${y2} ${x2},${y2}`; lx = x1 + 10 + lw / 2; ly = y1;
        }
      } else {
        const x1 = a.x + a.w / 2, y1 = a.y + NH, x2 = b.x + b.w / 2, y2 = b.y + NH + 4, low = Math.max(y1, y2) + 36;
        d = `M${x1},${y1} C${x1},${low} ${x2},${low} ${x2},${y2}`; lx = (x1 + x2) / 2; ly = low - 9;
      }
      return edgeOut(e, d, lw ? labelBox(lx, ly, lw, e.label) : "");
    });
    const extraH = edges.some((e) => layer.get(e.b) <= layer.get(e.a)) ? 46 : 0;
    // "right" is a preference: when it would shrink the text past MIN_SCALE in this column, a
    // narrower top-down layout wins. layoutDown moves the nodes, so they go back if it loses.
    if (avail / W < MIN_SCALE) {
      const saved = order.map((n) => [n.x, n.y, n.w]);
      const out = layoutDown({ layers, edges, layer, back, widthOf, labW, NH });
      if (out.W < W) return finishDiagram(el, title, out.W, out.H, out.paths, order, NH);
      order.forEach((n, i) => ([n.x, n.y, n.w] = saved[i]));
    }
    finishDiagram(el, title, W, H + extraH, paths, order, NH);
  }

  const edgeOut = (e, d, lab) => ({ p: `<path class="edge" d="${d}" fill="none" stroke-width="1.6" ${e.plain ? "" : 'marker-end="url(#rka)"'} ${e.both ? 'marker-start="url(#rkb)"' : ""}/>`, l: lab });
  function labelBox(lx, ly, lw, text) {
    const rows = labelLines(text), h = rows.length > 1 ? 32 : 20;
    return `<rect class="lab" x="${lx - lw / 2}" y="${ly - h / 2}" width="${lw}" height="${h}" rx="6"/>` + rows.map((s, i) =>
      `<text class="lab" x="${lx}" y="${ly + 4 + (i - (rows.length - 1) / 2) * 13}" text-anchor="middle" font-size="11">${esc(s)}</text>`).join("");
  }

  // Top-down layout for deep graphs (flowcharts). Rows follow their parents so the main
  // chain runs straight; labels get stacked slots so they never overlap; edges that skip
  // rows run along a side rail instead of cutting through nodes.
  function layoutDown({ layers, edges, layer, back, widthOf, labW, NH }) {
    const span = (e) => layer.get(e.b) - layer.get(e.a);
    const rail = edges.filter((e) => !back.has(e) && span(e) > 1);
    const left = edges.filter((e) => back.has(e) || span(e) < 1);
    const railNodes = new Set(rail.flatMap((e) => [e.a, e.b]));
    const GAPX = 44;
    layers.forEach((L, i) => {
      L.forEach((n) => (n.w = widthOf(n)));
      const want = (n) => {
        const ps = n.inn.filter((e) => span(e) === 1 && !back.has(e)).map((e) => e.a.x + e.a.w / 2);
        return ps.length ? ps.reduce((a, b) => a + b, 0) / ps.length : null;
      };
      if (i === 0) { let x = 0; L.forEach((n) => { n.x = x; x += n.w + GAPX; }); return; }
      // Siblings that continue the chain take the slot under their parent; leaves go to the side.
      const leaf = (n) => (n.out.length ? 0 : 1);
      L.sort((a, b) => (railNodes.has(a) - railNodes.has(b)) || ((want(a) ?? 1e9) - (want(b) ?? 1e9)) || (leaf(a) - leaf(b)));
      let cursor = -1e9;
      L.forEach((n) => {
        const w = want(n);
        const x = (w === null ? cursor + GAPX : w - n.w / 2);
        n.x = Math.max(x, cursor === -1e9 ? x : cursor + GAPX);
        cursor = n.x + n.w;
      });
    });
    // Label slots per gap: greedy rows so boxes never overlap.
    const gaps = layers.map(() => []);
    edges.filter((e) => span(e) === 1 && !back.has(e) && e.label).forEach((e) => {
      const g = gaps[layer.get(e.a)], lw = labW(e);
      const cx = (e.a.x + e.a.w / 2 + e.b.x + e.b.w / 2) / 2;
      let slot = 0;
      while (g.some((o) => o.slot === slot && Math.abs(o.cx - cx) < (o.lw + lw) / 2 + 8)) slot++;
      g.push({ e, cx, lw, slot });
    });
    // A gap holding a two-line label spaces its label rows further apart.
    const tall = gaps.map((g) => g.some((o) => labelLines(o.e.label).length > 1));
    const slotStep = (i) => (tall[i] ? 38 : 26);
    let y = 16;
    layers.forEach((L, i) => {
      L.forEach((n) => (n.y = y));
      const slots = gaps[i].length ? Math.max(...gaps[i].map((o) => o.slot)) + 1 : 0;
      y += NH + Math.max(42, 22 + slots * slotStep(i) + (tall[i] ? 6 : 0));
    });
    const leftW = left.length ? Math.max(...left.map(labW), 0) + 40 + left.length * 14 : 0;
    const allNodes = layers.flat(), labs = gaps.flat();
    // Shift nodes and their branch labels together; the bounds include the labels, so none is cut off.
    const minX = Math.min(...allNodes.map((n) => n.x), ...labs.map((o) => o.cx - o.lw / 2));
    const dx = 16 + leftW - minX;
    allNodes.forEach((n) => (n.x += dx));
    labs.forEach((o) => (o.cx += dx));
    const maxRight = Math.max(...allNodes.map((n) => n.x + n.w), ...labs.map((o) => o.cx + o.lw / 2));
    const railLab = Math.max(0, ...rail.map(labW));
    const paths = [];
    gaps.forEach((g, i) => g.forEach((o) => {
      const { e } = o, x1 = e.a.x + e.a.w / 2, y1 = e.a.y + NH, x2 = e.b.x + e.b.w / 2, y2 = e.b.y - 4;
      const ly = y1 + (tall[i] ? 25 : 21) + o.slot * slotStep(i), lx = o.cx; // branch labels float at the curve's midpoint, clear of the main line
      paths.push(edgeOut(e, `M${x1},${y1} C${x1},${(y1 + y2) / 2} ${x2},${(y1 + y2) / 2} ${x2},${y2}`, labelBox(lx, ly, o.lw, e.label)));
    }));
    edges.filter((e) => span(e) === 1 && !back.has(e) && !e.label).forEach((e) => {
      const x1 = e.a.x + e.a.w / 2, y1 = e.a.y + NH, x2 = e.b.x + e.b.w / 2, y2 = e.b.y - 4;
      paths.push(edgeOut(e, `M${x1},${y1} C${x1},${(y1 + y2) / 2} ${x2},${(y1 + y2) / 2} ${x2},${y2}`, ""));
    });
    let W = maxRight + 16;
    rail.forEach((e, r) => {
      const rx = maxRight + railLab + 40 + r * 14, ay = e.a.y + NH / 2 + (r % 3 - 1) * 6, by = e.b.y + NH / 2 + (r % 3 - 1) * 6;
      const lw = labW(e);
      W = Math.max(W, rx + 16);
      paths.push(edgeOut(e, `M${e.a.x + e.a.w},${ay} H${rx} V${by} H${e.b.x + e.b.w + 4}`, lw ? labelBox(e.a.x + e.a.w + 12 + lw / 2, ay, lw, e.label) : ""));
    });
    left.forEach((e, r) => {
      const lx = 16 + leftW - 24 - r * 14, ay = e.a.y + NH / 2, by = e.b.y + NH / 2, lw = labW(e);
      // A node further left in the same row would sit on the line, so leave from the bottom and pass under it.
      const boxedIn = allNodes.some((n) => n !== e.a && n.y === e.a.y && n.x < e.a.x);
      const under = e.a.y + NH + 6 + r * 4;
      const start = boxedIn ? `M${e.a.x + e.a.w / 2},${e.a.y + NH} V${under} H${lx}` : `M${e.a.x},${ay} H${lx}`;
      // The label sits on the rail's vertical run, clear of the nodes beside the source.
      paths.push(edgeOut(e, `${start} V${by} H${e.b.x - 4}`, lw ? labelBox(Math.max(16 + lw / 2, lx), ((boxedIn ? under : ay) + by) / 2, lw, e.label) : ""));
    });
    return { W, H: y - 30, paths };
  }

  function finishDiagram(el, title, W, H, paths, order, NH) {
    const boxes = order.map((n) => {
      const cls = `node ${KINDS.has(n.kind) ? n.kind : "svc"}`;
      const shape = n.kind === "db"
        ? `<path class="${cls}" d="M${n.x},${n.y + 8} a${n.w / 2},8 0 0,0 ${n.w},0 v${NH - 16} a${n.w / 2},8 0 0,1 ${-n.w},0 z" stroke-width="1.5"/><ellipse class="${cls}" cx="${n.x + n.w / 2}" cy="${n.y + 8}" rx="${n.w / 2}" ry="8" stroke-width="1.5"/>`
        : `<rect class="${cls}" x="${n.x}" y="${n.y}" width="${n.w}" height="${NH}" rx="${n.kind === "user" ? 23 : 10}" stroke-width="1.5" ${n.kind === "ext" ? 'stroke-dasharray="5 4"' : ""}/>`;
      return `${shape}<text class="name" x="${n.x + n.w / 2}" y="${n.y + NH / 2 + 5 + (n.kind === "db" ? 3 : 0)}" text-anchor="middle" font-size="13.5">${esc(n.name)}</text>`;
    });
    const defs = `<defs><marker id="rka" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path class="arrow" d="M0,0 L10,5 L0,10 z"/></marker><marker id="rkb" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path class="arrow" d="M0,0 L10,5 L0,10 z"/></marker></defs>`;
    el.innerHTML = `<div class="rk-card rk-diagram">${title ? `<div class="rk-ctitle">${inline(title)}</div>` : ""}<div class="rk-scroll"><svg viewBox="0 0 ${W} ${H}" style="max-width:${W}px;min-width:${Math.round(W * MIN_SCALE)}px;margin:0 auto">${defs}${paths.map((x) => x.p).join("")}${boxes.join("")}${paths.map((x) => x.l).join("")}</svg></div></div>`;
  }

  function steps(el, ls) {
    ls = ls || lines(rawText(el));
    el.innerHTML = `<ol class="rk-steps">${ls.map((l) => {
      const [t, ...rest] = cells(l.replace(/^\d+[.)]\s*/, ""));
      return `<li class="rk-card"><div><div class="st">${inline(t)}</div>${rest.length ? `<div class="sd">${inline(rest.join(" | "))}</div>` : ""}</div></li>`;
    }).join("")}</ol>`;
  }

  // Decisions the reader has to make, numbered D1, D2...: "Question | options or recommendation".
  function decisions(el, ls) {
    ls = ls || lines(rawText(el));
    el.innerHTML = `<ol class="rk-decide">${ls.map((l) => {
      const [t, ...rest] = cells(l.replace(/^D?\d+[.)]?\s*/i, ""));
      return `<li class="rk-card"><div class="st">${inline(t)}</div>${rest.length ? `<div class="sd">${inline(rest.join(" | "))}</div>` : ""}</li>`;
    }).join("")}</ol>`;
  }

  // Options side by side: "Name [recommended] | summary" starts a card; "+ pro", "- con" and
  // "~ note" lines below it fill that card.
  function options(el, ls) {
    ls = ls || lines(rawText(el));
    const cards = [];
    const KIND_OF = { "+": "pro", "-": "con", "~": "note" };
    for (const l of ls) {
      const m = l.match(/^([+~-])\s+(.*)$/);
      if (m && cards.length) {
        cards[cards.length - 1].items.push({ kind: KIND_OF[m[1]], text: m[2] });
        continue;
      }
      const [head, ...rest] = cells(l);
      const rec = /\[recommended\]/i.test(head);
      cards.push({ name: head.replace(/\[recommended\]/i, "").trim(), rec, sum: rest.join(" | "), items: [] });
    }
    el.innerHTML = `<div class="rk-options">${cards.map((c) => `<div class="rk-card rk-opt${c.rec ? " rec" : ""}"><div class="oh"><span class="on">${inline(c.name)}</span>${
      c.rec ? '<span class="rec-tag">Recommended</span>' : ""}</div>${c.sum ? `<p class="os">${inline(c.sum)}</p>` : ""}${
      c.items.length ? `<ul>${c.items.map((i) => `<li class="${i.kind}">${inline(i.text)}</li>`).join("")}</ul>` : ""}</div>`).join("")}</div>`;
  }

  // Instance tree: one item per line, indented under its parent: "Name [ClassName] | note". A
  // leading "+ ", "~ " or "- " marks an item the plan adds, changes or removes.
  const TREE_MARK = { "+": "add", "~": "chg", "-": "del" };
  function tree(el, raw, meta) {
    meta = meta || {};
    const title = meta.title || el.getAttribute("title") || "";
    const rows = (raw || rawText(el).split(/\r?\n/)).filter((l) => l.trim())
      .map((l) => ({ indent: l.replace(/\t/g, "  ").match(/^ */)[0].length, text: l.trim() }));
    if (!rows.length) return;
    const root = { kids: [] }, stack = [{ indent: -1, node: root }];
    for (const r of rows) {
      while (stack[stack.length - 1].indent >= r.indent) stack.pop();
      const mark = r.text.match(/^([+~-])\s+/);
      const [head, ...note] = (mark ? r.text.slice(mark[0].length) : r.text).split("|");
      const m = head.trim().match(/^(.*?)\s*(?:\[([^\]]+)\])?$/);
      const node = { name: m[1], cls: m[2] || "", note: note.join("|").trim(), mark: mark ? TREE_MARK[mark[1]] : "", kids: [] };
      stack[stack.length - 1].node.kids.push(node);
      stack.push({ indent: r.indent, node });
    }
    const clsKind = (c) => (/^(Script|LocalScript|ModuleScript)$/.test(c) ? " script" : /^(Remote|UnreliableRemote|Bindable)/.test(c) ? " remote" : "");
    const item = (n) => `<li${n.mark ? ` class="${n.mark}"` : ""}><span class="tn">${esc(n.name)}</span>${n.cls ? `<span class="tc${clsKind(n.cls)}">${esc(n.cls)}</span>` : ""}${
      n.note ? `<span class="tt">${inline(n.note)}</span>` : ""}${n.kids.length ? `<ul>${n.kids.map(item).join("")}</ul>` : ""}</li>`;
    el.innerHTML = `<div class="rk-card rk-tree">${title ? `<div class="rk-ctitle">${inline(title)}</div>` : ""}<div class="rk-scroll"><ul>${root.kids.map(item).join("")}</ul></div></div>`;
  }

  // Sequence: "A -> B: label" calls in order, "A --> B: label" replies, "note A: text". Lanes keep
  // the order they first appear in. When every [client]/[user] lane comes before every
  // [server]/[db] lane, a client|server line runs between them, through a [remote] lane if one sits there.
  const SIDE = { user: "client", client: "client", server: "server", db: "server" };
  function sequence(el, ls, meta) {
    meta = meta || {};
    const title = meta.title || el.getAttribute("title") || "";
    ls = ls || lines(rawText(el));
    const lanes = new Map(), steps = [];
    const lane = (tok) => {
      const m = tok.trim().match(/^(.*?)\s*(?:\[(\w+)\])?$/);
      const name = m[1].trim();
      if (!lanes.has(name)) lanes.set(name, { name, kind: "svc", i: lanes.size });
      if (m[2]) lanes.get(name).kind = m[2].toLowerCase();
      return lanes.get(name);
    };
    for (const l of ls) {
      let m;
      if ((m = l.match(/^note\s+(.+?)\s*:\s*(.+)$/i))) steps.push({ note: true, a: lane(m[1]), label: m[2] });
      else if ((m = l.match(/^(.+?)\s*(-->|->)\s*(.+?)(?:\s*:\s*(.+))?$/))) steps.push({ a: lane(m[1]), b: lane(m[3]), reply: m[2] === "-->", label: m[4] || "" });
      else lane(l);
    }
    const order = [...lanes.values()];
    if (!order.length) return;
    const textW = (s) => (s ? Math.max(...labelLines(s).map((t) => t.length)) * 7.2 : 0);
    const boxW = (n) => Math.max(110, n.name.length * 7.6 + 30);
    // Each gap fits half of both name boxes and the labels of the messages that cross it.
    const gap = order.slice(0, -1).map((n, i) => (boxW(n) + boxW(order[i + 1])) / 2 + 24);
    let selfRight = 0;
    for (const s of steps) {
      if (s.note) continue;
      if (s.a === s.b) {
        const need = textW(s.label) + 64;
        if (s.a.i < gap.length) gap[s.a.i] = Math.max(gap[s.a.i], need);
        else selfRight = Math.max(selfRight, need - boxW(s.a) / 2);
        continue;
      }
      const lo = Math.min(s.a.i, s.b.i), hi = Math.max(s.a.i, s.b.i);
      for (let k = lo; k < hi; k++) gap[k] = Math.max(gap[k], (textW(s.label) + 48) / (hi - lo));
    }
    const xs = [16 + boxW(order[0]) / 2];
    gap.forEach((g) => xs.push(xs[xs.length - 1] + g));
    const W = xs[xs.length - 1] + boxW(order[order.length - 1]) / 2 + 16 + Math.max(0, selfRight);
    const client = order.filter((n) => SIDE[n.kind] === "client"), server = order.filter((n) => SIDE[n.kind] === "server");
    let boundX = null;
    if (client.length && server.length) {
      const lastClient = Math.max(...client.map((n) => n.i)), firstServer = Math.min(...server.map((n) => n.i));
      if (lastClient < firstServer) {
        const remote = order.find((n) => n.kind === "remote" && n.i > lastClient && n.i < firstServer);
        boundX = remote ? xs[remote.i] : (xs[lastClient] + xs[firstServer]) / 2;
      }
    }
    const HEAD = 40, top = boundX === null ? 14 : 34;
    let y = top + HEAD + 26;
    const parts = [];
    let num = 0;
    for (const s of steps) {
      const rows = s.label ? labelLines(s.label).length : 1, extra = (rows - 1) * 14;
      const xa = xs[s.a.i];
      if (s.note) {
        const w = textW(s.label) + 24, h = 26 + extra;
        parts.push(`<rect class="noteb" x="${xa - w / 2}" y="${y - 6}" width="${w}" height="${h}" rx="6"/>` + labelLines(s.label).map((t, k) =>
          `<text class="msg" x="${xa}" y="${y + 11 + k * 14}" text-anchor="middle" font-size="12">${esc(t)}</text>`).join(""));
        y += h + 14;
        continue;
      }
      num++;
      const dash = s.reply ? ' stroke-dasharray="5 4"' : "";
      // Each label line sits on a panel-colored box, so lifelines and the client|server line break around it.
      const label = (x, anchor, baseY) => labelLines(s.label).map((t, k) => {
        const w = t.length * 6.4 + 8, left = anchor === "middle" ? x - w / 2 : x - 4;
        return `<rect class="msgbg" x="${left}" y="${baseY + k * 14 - 11}" width="${w}" height="15" rx="3"/>` +
          `<text class="msg" x="${x}" y="${baseY + k * 14}" text-anchor="${anchor}" font-size="12">${esc(t)}</text>`;
      }).join("");
      const badge = (cy) => `<circle class="seqn" cx="${xa}" cy="${cy}" r="9"/><text class="seqn" x="${xa}" y="${cy + 3.5}" text-anchor="middle" font-size="10">${num}</text>`;
      if (s.a === s.b) {
        const ly = y + 4;
        parts.push(`<path class="edge" d="M${xa + 9},${ly} H${xa + 40} V${ly + 20} H${xa + 6}" fill="none" stroke-width="1.6" marker-end="url(#rka)"${dash}/>` +
          label(xa + 48, "start", ly + 14 - extra / 2) + badge(ly));
        y += 44 + extra;
        continue;
      }
      const xb = xs[s.b.i], dir = xb > xa ? 1 : -1, ly = y + extra + 10;
      parts.push(`<line class="edge" x1="${xa + dir * 10}" y1="${ly}" x2="${xb - dir * 3}" y2="${ly}" stroke-width="1.6" marker-end="url(#rka)"${dash}/>` +
        label((xa + xb) / 2, "middle", ly - 7 - extra) + badge(ly));
      y += 38 + extra;
    }
    const H = y + 6;
    const heads = order.map((n) => {
      const w = boxW(n), cls = `node ${KINDS.has(n.kind) || n.kind === "client" || n.kind === "remote" ? n.kind : "svc"}`;
      return `<line class="life" x1="${xs[n.i]}" y1="${top + HEAD}" x2="${xs[n.i]}" y2="${H - 6}" stroke-width="1.2" stroke-dasharray="4 4"/>` +
        `<rect class="${cls}" x="${xs[n.i] - w / 2}" y="${top}" width="${w}" height="${HEAD}" rx="${n.kind === "user" ? 20 : 10}" stroke-width="1.5"/>` +
        `<text class="name" x="${xs[n.i]}" y="${top + HEAD / 2 + 5}" text-anchor="middle" font-size="13.5">${esc(n.name)}</text>`;
    }).join("");
    const bound = boundX === null ? "" : `<line class="bound" x1="${boundX}" y1="8" x2="${boundX}" y2="${H - 4}" stroke-width="1.5" stroke-dasharray="7 5"/>` +
      `<text class="bound" x="${boundX - 10}" y="22" text-anchor="end" font-size="10.5">CLIENT</text><text class="bound" x="${boundX + 10}" y="22" font-size="10.5">SERVER</text>`;
    const defs = `<defs><marker id="rka" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path class="arrow" d="M0,0 L10,5 L0,10 z"/></marker></defs>`;
    el.innerHTML = `<div class="rk-card rk-diagram rk-seq">${title ? `<div class="rk-ctitle">${inline(title)}</div>` : ""}<div class="rk-scroll"><svg viewBox="0 0 ${W} ${H}" style="max-width:${W}px;min-width:${Math.round(W * MIN_SCALE)}px;margin:0 auto">${defs}${bound}${heads}${parts.join("")}</svg></div></div>`;
  }

  // Luau coloring for code blocks: comments, strings, numbers, keywords, and common globals.
  const LUAU_KEYWORDS = new Set("and break const continue do else elseif end export false for function if in local nil not or repeat return then true type typeof until while".split(" "));
  const LUAU_GLOBALS = new Set(("game workspace script require task self Instance Vector2 Vector3 CFrame Color3 UDim UDim2 Enum math string table " +
    "buffer coroutine os print warn error assert pcall xpcall ipairs pairs next select tostring tonumber setmetatable getmetatable").split(" "));
  // Groups: 1 comment (2 its level), 3 string (4 its level), 5 number, 6 identifier.
  const LUAU_TOKEN = /(--\[(=*)\[[\s\S]*?\]\2\]|--[^\n]*)|(\[(=*)\[[\s\S]*?\]\4\]|"(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*'|`(?:\\.|[^`\\])*`)|(\b0[xX][\da-fA-F_]+\b|\b\d[\d_]*(?:\.\d+)?(?:[eE][+-]?\d+)?\b)|([A-Za-z_]\w*)/g;
  // Unlabeled blocks count as Luau when they read like it; a class="language-x" for another language opts out.
  const LOOKS_LUAU = /\b(local|const|function|end|require|then|return)\b/;
  function colorLuau(pre) {
    const code = pre.querySelector(":scope > code") || pre;
    const lang = (code.className.match(/language-(\w+)/) || [])[1];
    if (lang ? !/^(lua|luau)$/i.test(lang) : !LOOKS_LUAU.test(code.textContent)) return;
    const src = code.textContent;
    let out = "", last = 0;
    for (const m of src.matchAll(LUAU_TOKEN)) {
      const t = m[0];
      const cls = m[1] ? "c" : m[3] ? "s" : m[5] ? "n" : LUAU_KEYWORDS.has(t) ? "k" : LUAU_GLOBALS.has(t) ? "g" : "";
      out += esc(src.slice(last, m.index)) + (cls ? `<span class="lx-${cls}">${esc(t)}</span>` : esc(t));
      last = m.index + t.length;
    }
    code.innerHTML = out + esc(src.slice(last));
  }

  // Board: "ID | title | column" items, drag between columns, export as markdown.
  function board(el, ls, meta) {
    meta = meta || {};
    const cols = (meta.columns || el.getAttribute("columns") || "Now,Next,Later").split(",").map((s) => s.trim()).filter(Boolean);
    const items = (ls || lines(rawText(el))).map(cells).filter((c) => !/^id$/i.test(c[0]))
      .map(([id, title, col]) => ({ id, title: title || "", col }));
    const hasInbox = items.some((i) => !i.col || !cols.includes(i.col));
    const lanes = (hasInbox ? ["Inbox"] : []).concat(cols);
    items.forEach((i) => { if (!lanes.includes(i.col)) i.col = lanes[0]; });
    const title = meta.title || el.getAttribute("title") || "";
    el.innerHTML = `<div class="rk-board"><div class="bar"><div class="rk-ctitle" style="margin:0">${inline(title)}</div><button class="rk-btn">Export as markdown</button></div>
<div class="hint">Drag a card, or tap a card and then a column. Keyboard: focus a card and press 1-${lanes.length}.</div>
${hasInbox ? `<div class="rk-lane inbox" data-col="Inbox"><div class="lh"><span>Inbox</span><span class="c"></span></div></div>` : ""}<div class="lanes" style="--n:${cols.length}">${cols.map((c) => `<div class="rk-lane" data-col="${esc(c)}"><div class="lh"><span>${esc(c)}</span><span class="c"></span></div></div>`).join("")}</div>
<textarea class="rk-out" readonly></textarea></div>`;
    const laneEl = (c) => el.querySelector(`.rk-lane[data-col="${CSS.escape(c)}"]`);
    let dragging = null, picked = null;
    const pick = (d) => { picked?.classList.remove("pick"); picked = picked === d ? null : d; picked?.classList.add("pick"); };
    items.forEach((it) => {
      const d = document.createElement("div");
      d.className = "rk-item"; d.draggable = true; d.tabIndex = 0; d.dataset.id = it.id;
      d.innerHTML = `<div class="id">${esc(it.id)}</div>${inline(it.title)}`;
      d.addEventListener("dragstart", () => { dragging = d; d.classList.add("drag"); });
      d.addEventListener("dragend", () => { d.classList.remove("drag"); dragging = null; count(); });
      // Touch screens have no HTML drag and drop: tap a card, then tap the column it goes to.
      d.addEventListener("click", (e) => { e.stopPropagation(); pick(d); });
      // Keyboard: number keys move the focused card to that column (1 = first column on screen).
      d.addEventListener("keydown", (e) => {
        const all = [...el.querySelectorAll(".rk-lane")], n = Number(e.key);
        if (n >= 1 && n <= all.length) { all[n - 1].appendChild(d); d.focus(); count(); }
      });
      laneEl(it.col).appendChild(d);
    });
    el.querySelectorAll(".rk-lane").forEach((lane) => {
      lane.addEventListener("click", () => { if (picked) { lane.appendChild(picked); pick(picked); count(); } });
      lane.addEventListener("dragover", (e) => { e.preventDefault(); lane.classList.add("over"); });
      lane.addEventListener("dragleave", () => lane.classList.remove("over"));
      lane.addEventListener("drop", (e) => {
        e.preventDefault(); lane.classList.remove("over");
        if (!dragging) return;
        const after = [...lane.querySelectorAll(".rk-item:not(.drag)")].find((c) => e.clientY < c.getBoundingClientRect().top + c.offsetHeight / 2);
        lane.insertBefore(dragging, after || null);
      });
    });
    function count() { el.querySelectorAll(".rk-lane").forEach((l) => (l.querySelector(".c").textContent = l.querySelectorAll(".rk-item").length)); }
    count();
    el.querySelector(".rk-btn").addEventListener("click", () => {
      const md = [...el.querySelectorAll(".rk-lane")].map((l) =>
        `## ${l.dataset.col}\n` + [...l.querySelectorAll(".rk-item")].map((i) => `- ${i.dataset.id} ${i.textContent.slice(i.dataset.id.length).trim()}`).join("\n")).join("\n\n");
      const out = el.querySelector(".rk-out");
      out.style.display = "block"; out.value = md;
      navigator.clipboard?.writeText(md).catch(() => {});
    });
  }

  /* ---------- markdown renderer (for .md written by the agent) ---------- */

  const FENCES = {
    chart: (ls) => { const m = splitMeta(ls, ["title", "type", "unit"]); return mk(chart, ls, m); },
    diagram: (ls) => { const m = splitMeta(ls, ["title"]); return mk(diagram, ls, m); },
    board: (ls) => { const m = splitMeta(ls, ["title", "columns"]); return mk(board, ls, m); },
    stats: (ls) => mk(stats, ls),
    steps: (ls) => mk(steps, ls),
    decisions: (ls) => mk(decisions, ls),
    options: (ls) => mk(options, ls),
    sequence: (ls) => { const m = splitMeta(ls, ["title"]); return mk(sequence, ls, m); },
    // A tree needs its indentation, so it reads the untrimmed lines.
    tree: (ls, raw) => {
      const body = raw.filter((l) => l.trim());
      const t = body.length && body[0].trim().match(/^title:\s*(.*)$/i);
      return mk(tree, t ? body.slice(1) : body, t ? { title: t[1] } : {});
    },
  };
  function mk(fn, ls, meta) { const d = document.createElement("div"); fn(d, ls, meta); return d; }

  // A list and the lists nested under its items (deeper indent = child of the previous item).
  const LI = /^(\s*)([-*+]|\d+[.)])\s+(.*)$/;
  function list(L, i, plain) {
    const base = L[i].match(LI)[1].length, ordered = /^\d/.test(L[i].match(LI)[2]), items = [];
    while (i < L.length) {
      const m = L[i].match(LI);
      if (!m || m[1].length < base) break;
      if (m[1].length > base && items.length) {
        const sub = list(L, i, plain);
        items[items.length - 1] = items[items.length - 1].replace(/<\/li>$/, sub.html + "</li>");
        i = sub.i; continue;
      }
      let t = m[3]; i++;
      while (i < L.length && /^\s{2,}\S/.test(L[i]) && !LI.test(L[i])) t += " " + L[i++].trim();
      const task = t.match(/^\[([ xX])\]\s+(.*)$/);
      items.push(task ? `<li class="rk-task"><input type="checkbox" ${task[1] !== " " ? "checked" : ""}>${inline(task[2], !plain)}</li>` : `<li>${inline(t, !plain)}</li>`);
    }
    return { html: `<${ordered ? "ol" : "ul"}>${items.join("")}</${ordered ? "ol" : "ul"}>`, i };
  }

  function renderMarkdown(src, plain) {
    const root = document.createElement("div");
    const L = src.replace(/\r/g, "").split("\n");
    let i = 0, para = [];
    const flush = () => {
      if (para.length) { const p = document.createElement("p"); p.innerHTML = inline(para.join(" "), !plain); root.appendChild(p); para = []; }
    };
    const add = (html) => { const t = document.createElement("template"); t.innerHTML = html; root.appendChild(t.content); };
    while (i < L.length) {
      const line = L[i];
      let m;
      if ((m = line.match(/^```\s*(\w*)/))) {
        flush();
        const lang = m[1].toLowerCase(), body = [];
        i++;
        while (i < L.length && !/^```/.test(L[i])) body.push(L[i++]);
        i++;
        if (!plain && FENCES[lang]) root.appendChild(FENCES[lang](body.map((s) => s.trim()).filter(Boolean), body));
        else add(`<pre><code${lang ? ` class="language-${lang}"` : ""}>${esc(body.join("\n"))}</code></pre>`);
        continue;
      }
      if ((m = line.match(/^(#{1,6})\s+(.*)$/))) {
        flush();
        if (!plain && m[1].length === 1 && !root.querySelector("rk-header")) {
          const h = document.createElement("rk-header"); h.setAttribute("title", m[2]); header(h); root.appendChild(h);
        } else add(`<h${m[1].length}>${inline(m[2], !plain)}</h${m[1].length}>`);
        i++; continue;
      }
      if (/^\s*(-{3,}|\*{3,})\s*$/.test(line)) { flush(); add("<hr>"); i++; continue; }
      if (!plain && (m = line.match(/^stats:\s*(.+)$/i))) {
        flush();
        root.appendChild(mk(stats, m[1].split("|").map((s) => {
          const t = s.trim(), k = t.indexOf(" ");
          return k > 0 ? `${t.slice(0, k)} | ${t.slice(k + 1)}` : t;
        })));
        i++; continue;
      }
      if (/^\s*\|/.test(line)) {
        flush();
        const rows = [];
        while (i < L.length && /^\s*\|/.test(L[i])) rows.push(L[i++].trim());
        const d = document.createElement("div");
        table(d, rows, !plain);
        root.appendChild(d);
        continue;
      }
      if (/^>\s?/.test(line)) {
        flush();
        const q = [];
        while (i < L.length && /^>\s?/.test(L[i])) q.push(L[i++].replace(/^>\s?/, ""));
        const text = q.join(" ");
        const cm = !plain && text.match(/^\**(Risk|Warning|Note|OK|Lesson)\**:\s*(.*)$/i);
        if (cm) {
          const kind = { risk: "risk", warning: "warn", note: "note", ok: "ok", lesson: "lesson" }[cm[1].toLowerCase()];
          const d = document.createElement("div"); callout(d, kind, "", inline(cm[2])); root.appendChild(d);
        } else add(`<blockquote>${inline(text, !plain)}</blockquote>`);
        continue;
      }
      if (LI.test(line)) {
        flush();
        const r = list(L, i, plain);
        add(r.html); i = r.i;
        continue;
      }
      if (!line.trim()) { flush(); i++; continue; }
      para.push(line.trim()); i++;
    }
    flush();
    return root;
  }

  // Plain HTML the agent wrote (<p>, <li>, callout text...): same inline formatting as the components,
  // so **bold**, `code`, [done] and CHK-1 work in any text. Component data and code are left alone.
  const SKIP = "pre,code,script,style,textarea,svg,a,rk-header,rk-stats,rk-chart,rk-table,rk-diagram,rk-steps,rk-decisions,rk-options,rk-tree,rk-sequence,rk-board,rk-pill";
  function formatText(root) {
    const walk = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    const todo = [];
    for (let n; (n = walk.nextNode());) {
      if (/[*`~[]|[A-Z]-\d/.test(n.data) && !n.parentElement.closest(SKIP)) todo.push(n);
    }
    todo.forEach((n) => {
      const html = inline(n.data);
      if (html === esc(n.data)) return;
      const t = document.createElement("template");
      t.innerHTML = html;
      n.replaceWith(t.content);
    });
  }

  /* ---------- boot ---------- */

  // A sticky contents rail beside the page, linking each h2. Hidden on narrow screens by the stylesheet.
  function contents(wrap, page) {
    const heads = [...page.querySelectorAll("h2")].filter((h) => !h.closest(".rk-card, .rk-board"));
    if (heads.length < TOC_MIN) return;
    const used = new Set();
    const links = heads.map((h) => {
      if (!h.id) {
        const base = h.textContent.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "section";
        let id = base;
        for (let k = 2; used.has(id) || document.getElementById(id); k++) id = `${base}-${k}`;
        h.id = id;
      }
      used.add(h.id);
      return `<li><a href="#${encodeURIComponent(h.id)}">${esc(h.textContent)}</a></li>`;
    });
    const nav = document.createElement("nav");
    nav.className = "rk-toc";
    nav.setAttribute("aria-label", "Contents");
    nav.innerHTML = `<p>Contents</p><ol>${links.join("")}</ol>`;
    wrap.classList.add("toc");
    wrap.prepend(nav);
  }

  function boot() {
    if (!document.querySelector(`link[href="${FONTS}"]`)) {
      const f = document.createElement("link"); f.rel = "stylesheet"; f.href = FONTS; document.head.appendChild(f);
    }
    const st = document.createElement("style");
    st.textContent = STYLE;
    document.head.appendChild(st);
    if (!document.querySelector('meta[name="viewport"]')) {
      const v = document.createElement("meta"); v.name = "viewport"; v.content = "width=device-width,initial-scale=1"; document.head.appendChild(v);
    }
    const body = document.body;
    body.classList.add("rk");
    const wrap = document.createElement("div");
    wrap.className = "rk-wrap";
    const page = document.createElement("main");
    page.className = "rk-page";
    while (body.firstChild) page.appendChild(body.firstChild);
    wrap.appendChild(page);
    body.appendChild(wrap);

    const md = page.querySelector("rk-md");
    if (md) {
      const plain = md.hasAttribute("plain");
      if (plain) body.classList.add("rk-plain");
      md.replaceWith(...renderMarkdown(rawText(md), plain).childNodes);
    } else formatText(page);
    if (!document.title) {
      const h = page.querySelector("rk-header[title], h1");
      if (h) document.title = (h.getAttribute("title") || h.textContent).replace(/[`*~]/g, "");
    }
    // The rail goes in first: it narrows the page column that diagrams measure to fit.
    contents(wrap, page);
    const run = (sel, fn) => page.querySelectorAll(sel).forEach((el) => fn(el));
    run("rk-cols", (el) => [...el.children].forEach((c) => c.classList.add("rk-col")));
    run("rk-header", (el) => { if (!el.querySelector(".rk-hero")) header(el); });
    run("rk-stats", (el) => stats(el));
    run("rk-chart", (el) => chart(el));
    run("rk-table", (el) => table(el));
    run("rk-callout", (el) => callout(el));
    run("rk-diagram", (el) => diagram(el));
    run("rk-steps", (el) => steps(el));
    run("rk-decisions", (el) => decisions(el));
    run("rk-options", (el) => options(el));
    run("rk-tree", (el) => tree(el));
    run("rk-sequence", (el) => sequence(el));
    run("pre", (el) => colorLuau(el));
    run("rk-board", (el) => board(el));
    run("rk-pill", (el) => { el.outerHTML = pill((el.getAttribute("s") || "todo").toLowerCase(), el.textContent.trim()); });
    run("table", (t) => { if (!t.closest(".rk-tablewrap")) { const w = document.createElement("div"); w.className = "rk-tablewrap"; t.replaceWith(w); w.appendChild(t); } });
    document.documentElement.dataset.rkReady = "1";
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot);
  else boot();
})();
