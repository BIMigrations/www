---
title: Install BIMControl
heading: "Install <em>BIMControl.</em>"
description: One line to install and start BIMControl on macOS, Windows or Linux. It runs on your machine and, once installed, contacts only your BI platforms, your warehouse and the converter service.
permalink: /bimcontrol/
noindex: true
sitemap: false
---

BIMControl reads the estate scan Estate Scanner made, migrates dashboards, data and logic to Power BI / Fabric, and checks for each element whether the numbers match the source. It runs on your computer.

<div class="install">
<h2>macOS or Linux</h2>
<p>Open Terminal, paste this line and press Return.</p>
<pre><code id="cmd-unix">curl -fsSL https://bimigrations.com/downloads/bimcontrol/install.sh | sh</code></pre>
<button type="button" class="copy" data-target="cmd-unix">Copy</button>

<h2>Windows</h2>
<p>Open PowerShell (Start menu, type "PowerShell"), paste this line and press Enter.</p>
<pre><code id="cmd-win">irm https://bimigrations.com/downloads/bimcontrol/install.ps1 | iex</code></pre>
<button type="button" class="copy" data-target="cmd-win">Copy</button>
</div>

## What we have and have not run

We have run the macOS install end to end, with Python already present. We have **not** run the Windows installer on Windows PowerShell 5.1, and we have not run the path that installs Python for you. If one of those fails for you, the terminal says why and the full output is in `.bimcontrol/install.log`; send it to us.

## What the line does

- Checks for Python 3.11 or newer. If it is missing, it installs Python 3.12 for you, inside your own home folder. No administrator rights are needed.
- Downloads the latest BIMControl, checks it is intact, and installs it in `~/.bimcontrol` (Windows: `C:\Users\<you>\.bimcontrol`).
- Starts the app. Run the same line again any time to update to the newest version and start it.

## Before you start

- An estate scan made with [Estate Scanner](/estate-scanner/), saved as `estate.db` in the `.estate-scanner` folder in your home folder. If the scan was made on another computer, copy `estate.db` into that folder, or use "Import a scan" on the Estate screen.
- Google Chrome or Microsoft Edge, for signing in to Domo.
- Internet access, and a network that can reach your source platform and Power BI / Fabric (VPN if required).

## Using it

Start on the Connections screen. Sign in to your source platform (your Chrome or Edge opens: sign in as you normally would) and to Power BI with the account that can publish to your workspace. Then choose the dashboards to migrate and start the run. Domo Magic ETL dataflows need a converter service: your BI Migrations representative gives you its address, and you paste it into the Converter box.

## What stays where

Everything BIMControl keeps is in the `.bimcontrol` folder in your home folder. It only ever reads the scan; it never changes it. Installing or updating downloads BIMControl from this site and Python packages from PyPI (and Python from astral.sh if you have none). Running BIMControl contacts only your BI platforms, your warehouse and the converter service.

## If something goes wrong

The terminal prints what failed, and the full output of the last install is in `.bimcontrol/install.log`. To test your machine without opening the app, run the line with a self-test and send us the output:

```
curl -fsSL https://bimigrations.com/downloads/bimcontrol/install.sh | BIMCONTROL_CHECK=1 sh
```

```
$env:BIMCONTROL_CHECK=1; irm https://bimigrations.com/downloads/bimcontrol/install.ps1 | iex
```

To remove it, delete the `.bimcontrol` folder in your home folder. That deletes your migration runs too.

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
