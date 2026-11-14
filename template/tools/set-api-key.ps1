<#
Stores the Open Cloud API key as this GitHub repo's ROBLOX_API_KEY secret.
The key is read from hidden input and piped to `gh secret set`, so it never
shows on screen, in the terminal history, or on a command line.

Run it yourself in a terminal at the repo root (not through Claude):
    powershell -ExecutionPolicy Bypass -File tools/set-api-key.ps1
#>
$ErrorActionPreference = "Stop"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
	throw "The GitHub CLI (gh) isn't on PATH. Install it, then open a new terminal."
}
gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
	throw "Sign in to GitHub first with: gh auth login"
}

$secure = Read-Host -AsSecureString "Paste the Open Cloud API key (it stays hidden), then press Enter"
$key = [System.Net.NetworkCredential]::new("", $secure).Password.Trim()
if ($key.Length -eq 0) {
	throw "No key was entered, so nothing was stored."
}
if ($key -match "\s") {
	throw "The key contains spaces or line breaks. Copy it again from the Creator Dashboard."
}

$key | gh secret set ROBLOX_API_KEY
if ($LASTEXITCODE -ne 0) {
	throw "gh secret set failed, so the key wasn't stored."
}
Write-Host "Stored ROBLOX_API_KEY. GitHub only ever shows its name from now on."
