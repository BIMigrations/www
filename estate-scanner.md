---
title: Install Estate Scanner
heading: "Install <em>Estate Scanner.</em>"
description: One line to install and start Estate Scanner on macOS, Windows or Linux. It runs on your machine and sends nothing anywhere except to your own BI platform.
permalink: /estate-scanner/
noindex: true
sitemap: false
---

Estate Scanner signs in to your BI platform as you and builds an inventory of what it can see: datasets, dashboards, calculations, users and how they connect. It runs on your computer and the result is one file you send us.

<div class="install">
<h2>macOS or Linux</h2>
<p>Open Terminal, paste this line and press Return.</p>
<pre><code id="cmd-unix">curl -fsSL https://bimigrations.com/downloads/estatescanner/install.sh | sh</code></pre>
<button type="button" class="copy" data-target="cmd-unix">Copy</button>

<h2>Windows</h2>
<p>Open PowerShell (Start menu, type "PowerShell"), paste this line and press Enter.</p>
<pre><code id="cmd-win">irm https://bimigrations.com/downloads/estatescanner/install.ps1 | iex</code></pre>
<button type="button" class="copy" data-target="cmd-win">Copy</button>
</div>

## What the line does

- Checks for Python 3.11 or newer. If it is missing, it installs Python 3.12 for you, inside your own home folder. No administrator rights are needed.
- Downloads the latest Estate Scanner, checks it is intact, and installs it in `~/.estate-scanner` (Windows: `C:\Users\<you>\.estate-scanner`).
- Starts the app. Run the same line again any time to update to the newest version and start it.

## Before you start

- Google Chrome or Microsoft Edge, for the sign-in window.
- Internet access, and a network that can reach your BI platform (VPN if required).

## Using it

Choose your platform, enter your instance name and click Connect. A Chrome or Edge window opens: sign in as you normally would. A full scan can take about half an hour; leave the computer awake. When it finishes, use the export button in the app and send us the file.

## What stays where

Everything stays on your computer. The only network requests are to your own BI platform, and to this site when you install or update. The scan is saved as `estate.db` in the `.estate-scanner` folder. The export we ask for removes your sign-in sessions first.

## If something goes wrong

The terminal prints what failed. To test your machine without opening the app, run the line with a self-test and send us the output:

```
curl -fsSL https://bimigrations.com/downloads/estatescanner/install.sh | ESTATE_SCANNER_CHECK=1 sh
```

```
$env:ESTATE_SCANNER_CHECK=1; irm https://bimigrations.com/downloads/estatescanner/install.ps1 | iex
```

To remove it, delete the `.estate-scanner` folder in your home folder. Export your scan first: this deletes it too.

<style>
.install pre { margin-bottom: 12px; }
.install .copy { margin: 0 0 32px; padding: 8px 16px; font: inherit; font-size: 14px; color: var(--ink); background: var(--bg2); border: 1px solid var(--line2); border-radius: 999px; cursor: pointer; }
.install .copy:hover, .install .copy:focus-visible { border-color: var(--ink); }
</style>
<script>
document.querySelectorAll('.install .copy').forEach(function (button) {
  button.addEventListener('click', function () {
    var text = document.getElementById(button.dataset.target).textContent;
    var done = function () { button.textContent = 'Copied'; setTimeout(function () { button.textContent = 'Copy'; }, 2000); };
    if (navigator.clipboard) { navigator.clipboard.writeText(text).then(done); }
  });
});
</script>
