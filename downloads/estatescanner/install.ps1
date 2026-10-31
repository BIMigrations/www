# Estate Scanner installer for Windows (PowerShell 5.1 or newer).
#
#   irm https://bimigrations.com/downloads/estatescanner/install.ps1 | iex
#
# Walks you through it in four steps: which BI platform you will scan, Python (found, or
# installed for you with no administrator rights), Estate Scanner itself, and a Start menu
# shortcut. Then it starts the app. Run it again any time: it updates to the latest version,
# and offers the platforms you chose last time.
#
# Run as a file it can also install without the website:
#   powershell -ExecutionPolicy Bypass -File install.ps1   (or double-click install.cmd)
#       from the folder a zip unpacks to (beside latest.txt and its wheel): installs that wheel
#       and fetches nothing from bimigrations.com
#   powershell -ExecutionPolicy Bypass -File packaging\install.ps1
#       from a checkout of the repository: installs that checkout, so a branch can be tried
# Under `irm | iex` there is no file, so customers never take either path.
#
# Settings (environment variables, all optional, mostly for testing and support):
#   ESTATE_SCANNER_SOURCE      install from this checkout (found on its own when run from one)
#   ESTATE_SCANNER_PLATFORMS   platforms to install without asking: all, or keys like domo,powerbi
#   ESTATE_SCANNER_BASE        where latest.txt (version, platforms) and the wheel are downloaded from
#   ESTATE_SCANNER_HOME        install folder (default %USERPROFILE%\.estate-scanner)
#   ESTATE_SCANNER_CHECK=1     install, run the self-test, do not open the app
#   ESTATE_SCANNER_FORCE_UV=1  ignore any Python already on the machine
#   ESTATE_SCANNER_UV_INSTALLER  where the Python installer (uv) is fetched from if one is needed
#   ESTATE_SCANNER_NO_LAUNCH=1 install only
#   ESTATE_SCANNER_NO_APP=1    skip the Start menu shortcut
#   ESTATE_SCANNER_PLAIN=1     no colour, spinner or prompts (also when NO_COLOR is set or output is redirected)
#
# This file is plain ASCII on purpose: `irm` decodes what it downloads, and a stray character
# in the wrong encoding would break the script. The few symbols it draws are built from code points.
# The same script runs under PowerShell 7 on a Mac or Linux box (the paths that differ are the
# $onWindows lines), which is how its logic is tested without a Windows machine.

# A function, so `exit` never closes the user's terminal, nothing leaks into their session,
# and a truncated download runs nothing at all.
function Install-EstateScanner {
    param([string]$ScriptDir = '')

    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'   # progress bars make Invoke-WebRequest very slow on 5.1
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }

    $onWindows = ($env:OS -eq 'Windows_NT')
    $userHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
    $base = if ($env:ESTATE_SCANNER_BASE) { $env:ESTATE_SCANNER_BASE.TrimEnd('/') } else { 'https://bimigrations.com/downloads/estatescanner' }
    $homeDir = if ($env:ESTATE_SCANNER_HOME) { $env:ESTATE_SCANNER_HOME } else { Join-Path $userHome '.estate-scanner' }
    $uvInstaller = if ($env:ESTATE_SCANNER_UV_INSTALLER) { $env:ESTATE_SCANNER_UV_INSTALLER } else { 'https://astral.sh/uv/install.ps1' }
    $venv = Join-Path $homeDir 'venv'
    $venvBin = Join-Path $venv $(if ($onWindows) { 'Scripts' } else { 'bin' })
    $venvPy = Join-Path $venvBin $(if ($onWindows) { 'python.exe' } else { 'python' })
    $venvPyw = Join-Path $venvBin $(if ($onWindows) { 'pythonw.exe' } else { 'python' })   # no console window
    $uvName = if ($onWindows) { 'uv.exe' } else { 'uv' }
    $shellExe = if ($onWindows) { 'powershell.exe' } else { 'pwsh' }
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ('estate-scanner-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $homeDir, $tmp | Out-Null
    $log = Join-Path $homeDir 'install.log'   # everything the steps print, kept for support; the last run only
    [IO.File]::WriteAllText($log, '')

    # State the nested functions below can change (they cannot assign to this function's variables).
    $state = @{ Tail = $false; Cancelled = $false; CursorHidden = $false }

    # --- the terminal ------------------------------------------------------------
    # $fancy: colour, spinner and symbols. $ask: we can also read keys.
    $plain = [bool]$env:ESTATE_SCANNER_PLAIN -or [bool]$env:NO_COLOR -or ($env:TERM -eq 'dumb')
    $fancy = $false; $ask = $false
    try {
        $fancy = (-not $plain) -and ($Host.Name -eq 'ConsoleHost') -and (-not [Console]::IsOutputRedirected)
        $ask = $fancy -and (-not [Console]::IsInputRedirected)
    } catch { $fancy = $false; $ask = $false }
    $utf = $fancy -and ([bool]$env:WT_SESSION -or $PSVersionTable.PSVersion.Major -ge 7 -or [Console]::OutputEncoding.CodePage -eq 65001)
    if ($utf) {
        $gOk = [string][char]0x2714; $gBad = [string][char]0x2718; $gOn = [string][char]0x25C9; $gOff = [string][char]0x25EF
        $gSoon = [string][char]0x25CC; $gCur = [string][char]0x276F; $gMark = [string][char]0x25C6; $gDot = [string][char]0x00B7
        $gRule = [string][char]0x2500; $gUp = [string][char]0x2191; $gDown = [string][char]0x2193
        $spin = @(0x280B, 0x2819, 0x2839, 0x2838, 0x283C, 0x2834, 0x2826, 0x2827, 0x2807, 0x280F) | ForEach-Object { [string][char]$_ }
    } else {
        $gOk = '+'; $gBad = 'x'; $gOn = '[x]'; $gOff = '[ ]'; $gSoon = '[-]'; $gCur = '>'; $gMark = '*'; $gDot = '-'; $gRule = '-'
        $gUp = 'up'; $gDown = 'down'; $spin = @('|', '/', '-', '\')
    }
    $rule = $gRule * 52

    # W: write text in a colour (colours only on a real console).
    function W([string]$Text, [string]$Color = '', [bool]$NewLine = $false) {
        if ($fancy -and $Color) { Write-Host -NoNewline $Text -ForegroundColor $Color } else { Write-Host -NoNewline $Text }
        if ($NewLine) { Write-Host '' }
    }
    function Ok([string]$Text, [string]$Dim = '') {
        W '   ' ; W $gOk 'Cyan'; W (' ' + $Text); if ($Dim) { W (' ' + $Dim) 'DarkGray' }; Write-Host ''
    }
    function Warn([string]$Text) { W '   ' ; W '!' 'Yellow'; W (' ' + $Text) '' $true }
    function Note([string]$Text) { W ('     ' + $Text) 'DarkGray' $true }
    function Step([string]$Number, [string]$Title) { Write-Host ''; W ('   ' + $Number + '  ') 'DarkGray'; W $Title 'White' $true; Write-Host '' }
    function Tilde([string]$Path) { if ($userHome -and $Path.StartsWith($userHome)) { '~' + $Path.Substring($userHome.Length) } else { $Path } }
    function Add-Log([string]$Text) { [IO.File]::AppendAllText($log, $Text + "`n") }
    function Show-Cursor { if ($fancy) { try { [Console]::CursorVisible = $true } catch { } } }
    function Hide-Cursor { if ($fancy) { try { [Console]::CursorVisible = $false; $state.CursorHidden = $true } catch { } } }

    # Fail "what went wrong" [-Tail]: stops the install; -Tail also shows the failed step's last output.
    function Fail([string]$Message, [bool]$WithTail = $false) { $state.Tail = $WithTail; throw $Message }

    function Quote-Arg([string]$Arg) { if ($Arg -match '[\s"]') { '"' + ($Arg -replace '"', '\"') + '"' } else { $Arg } }

    # Wait-Spinning "message" { still running? }: a spinner on a console, one line otherwise.
    function Wait-Spinning([string]$Message, [scriptblock]$Running) {
        if (-not $fancy) { Write-Host ('   ... ' + $Message); while (& $Running) { Start-Sleep -Milliseconds 200 }; return }
        $n = 0; Hide-Cursor
        while (& $Running) {
            W ("`r   ") ''; W $spin[$n % $spin.Count] 'Cyan'; W (' ' + $Message)
            $n++; Start-Sleep -Milliseconds 100
        }
        Write-Host -NoNewline ("`r" + (' ' * ($Message.Length + 8)) + "`r"); Show-Cursor
    }

    # Invoke-Step "what is happening" file arg...  Quiet: its output goes to the log, and a spinner
    # shows it is working. Returns $true when the command exits 0.
    function Invoke-Step([string]$Message, [string]$File, [string[]]$ArgList = @()) {
        Add-Log ("`n>>> " + $Message)
        $outFile = Join-Path $tmp ([Guid]::NewGuid().ToString('N') + '.out')
        $errFile = $outFile + '.err'
        $params = @{ FilePath = $File; NoNewWindow = $true; PassThru = $true; RedirectStandardOutput = $outFile; RedirectStandardError = $errFile }
        if ($ArgList.Count -gt 0) { $params.ArgumentList = (($ArgList | ForEach-Object { Quote-Arg $_ }) -join ' ') }
        try { $proc = Start-Process @params }
        catch { Add-Log $_.Exception.Message; return $false }   # the program is not there, or would not start
        $null = $proc.Handle   # keeps the exit code readable once the process has ended
        Wait-Spinning $Message { -not $proc.HasExited }
        $proc.WaitForExit()
        foreach ($f in $outFile, $errFile) { if (Test-Path $f) { [IO.File]::AppendAllText($log, [IO.File]::ReadAllText($f)) } }
        return ($proc.ExitCode -eq 0)
    }

    # Show-Busy / Clear-Busy: a transient line for a step with no spinner of its own (a download).
    function Show-Busy([string]$Message) {
        if ($fancy) { W "`r   " ''; W $spin[0] 'Cyan'; W (' ' + $Message) } else { Write-Host ('   ... ' + $Message) }
    }
    function Clear-Busy([string]$Message) {
        if ($fancy) { Write-Host -NoNewline ("`r" + (' ' * ($Message.Length + 8)) + "`r") }
    }

    # --- the app window (Windows) ---------------------------------------------------
    # pywebview draws the window with Microsoft Edge WebView2, and loads through .NET Framework 4.7.2 or
    # newer. Windows 11 has both; Windows 10 usually does, but not always (older builds, managed PCs).
    # Without WebView2, pywebview quietly falls back to the Internet Explorer engine, which cannot show
    # this app, so the app checks for itself (desktop.py) and opens in the browser instead. Here we say so
    # while someone is looking, and offer to add WebView2: a Microsoft download of about 2 MB.
    $webview2Url = if ($env:ESTATE_SCANNER_WEBVIEW2_URL) { $env:ESTATE_SCANNER_WEBVIEW2_URL } else { 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' }   # the Evergreen bootstrapper
    function Get-DotNetRelease {
        try { return [int](Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction Stop).Release } catch { return 0 }
    }
    function Test-WebView2 {
        # ESTATE_SCANNER_ASSUME_WEBVIEW2 is a test hook (present, missing, installable), so this flow can be run off Windows.
        if ($env:ESTATE_SCANNER_ASSUME_WEBVIEW2) { return (($env:ESTATE_SCANNER_ASSUME_WEBVIEW2 -eq 'present') -or (Test-Path (Join-Path $homeDir 'webview2-installed'))) }
        $ids = '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}', '{2CD8A007-E189-409D-A2C8-9AF4EF3C72AA}', '{0D50BFEC-CD6A-4F9A-964C-C7416E3ACB10}', '{65C35B14-6C1D-4122-AC46-7148CC9D6497}'
        $roots = 'HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients', 'HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients'
        foreach ($id in $ids) {
            foreach ($root in $roots) {
                try {
                    $pv = (Get-ItemProperty -LiteralPath (Join-Path $root $id) -ErrorAction Stop).pv
                    if ($pv -and ([version]$pv -ge [version]'86.0.622.0')) { return $true }   # the version pywebview asks for
                } catch { }
            }
        }
        return $false
    }
    # Install-WebView2: Microsoft's own bootstrapper, run only if Microsoft signed it. Returns $true if WebView2 is there afterwards.
    function Install-WebView2 {
        if ($env:ESTATE_SCANNER_ASSUME_WEBVIEW2) {
            if ($env:ESTATE_SCANNER_ASSUME_WEBVIEW2 -ne 'installable') { return $false }
            [IO.File]::WriteAllText((Join-Path $homeDir 'webview2-installed'), 'x'); return $true
        }
        $setup = Join-Path $tmp 'MicrosoftEdgeWebview2Setup.exe'
        Show-Busy 'Downloading Microsoft Edge WebView2'
        try { Invoke-WebRequest -UseBasicParsing $webview2Url -OutFile $setup }
        catch { Clear-Busy 'Downloading Microsoft Edge WebView2'; Add-Log $_.Exception.Message; return $false }
        Clear-Busy 'Downloading Microsoft Edge WebView2'
        $signature = Get-AuthenticodeSignature $setup
        if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
            Add-Log ('The WebView2 installer is not signed by Microsoft (' + $signature.Status + '), so it was not run.')
            return $false
        }
        if (-not (Invoke-Step 'Installing Microsoft Edge WebView2 (about a minute)' $setup @('/silent', '/install'))) { return $false }
        return (Test-WebView2)
    }
    # Confirm "question": Enter or Y for yes. With nobody to ask it is no, so an unattended run installs nothing it was not told to.
    function Confirm-Yes([string]$Question) {
        if (-not $ask) { return $false }
        W ('   ' + $Question + ' ') ''; W '[Y/n]' 'DarkGray'
        while ($true) {
            $k = [Console]::ReadKey($true)
            if ($k.Key -eq 'Enter' -or $k.Key -eq 'Y') { Write-Host ' yes'; return $true }
            if ($k.Key -eq 'N' -or $k.Key -eq 'Escape') { Write-Host ' no'; return $false }
        }
    }

    function Get-LogTail { if (Test-Path $log) { Get-Content $log -Tail 8 | Where-Object { $_ -and $_ -notlike '>>> *' } } }

    try {
        # --- hello -----------------------------------------------------------------
        Write-Host ''
        W '   ' ; W $gMark 'Yellow'; W '  '; W 'Estate Scanner' 'White'; W '   '; W 'BI / MIGRATIONS' 'DarkGray' $true
        Note 'Inventory your BI estate. Everything stays on this computer.'
        W ('   ' + $rule) 'DarkGray' $true
        Write-Host ''

        # --- where Estate Scanner comes from ---------------------------------------
        # A checkout (found around this file, or named by ESTATE_SCANNER_SOURCE), a folder (a zip
        # unpacks to this file beside latest.txt and its wheel), or the website.
        $src = $env:ESTATE_SCANNER_SOURCE
        $folder = ''
        if ($ScriptDir) {
            $repo = Split-Path -Parent $ScriptDir
            if (-not $src -and (Test-Path (Join-Path $ScriptDir 'platforms.txt')) -and $repo `
                    -and (Test-Path (Join-Path $repo 'pyproject.toml')) -and (Test-Path (Join-Path (Join-Path $repo 'src') 'estate_scanner'))) {
                $src = $repo
            } elseif (-not $src -and (Test-Path (Join-Path $ScriptDir 'latest.txt'))) {
                $named = Get-Content (Join-Path $ScriptDir 'latest.txt') | Where-Object { $_ -match '^wheel=' } | Select-Object -First 1
                if ($named -and (Test-Path (Join-Path $ScriptDir ($named -replace '^wheel=', '').Trim()))) { $folder = $ScriptDir }
            }
        }
        if ($src) {
            if (-not ((Test-Path (Join-Path $src 'pyproject.toml')) -and (Test-Path (Join-Path (Join-Path $src 'packaging') 'platforms.txt')))) {
                Fail "ESTATE_SCANNER_SOURCE is not a checkout of Estate Scanner: $src"
            }
            $src = (Resolve-Path $src).Path
        }

        # latest.txt: `key=value` lines (version, wheel, sha256, built) and `platform=` lines, which are
        # the menu (the same rows as packaging/platforms.txt). Returns both.
        function Read-Manifest([string]$Text) {
            $result = @{ Info = @{}; Platforms = @() }
            foreach ($line in ($Text -split "`r?`n")) {
                if ($line -match '^platform=(.*)$') { $result.Platforms += $Matches[1].Trim() }
                elseif ($line -match '^(\w+)=(.*)$') { $result.Info[$Matches[1]] = $Matches[2].Trim() }
            }
            return $result
        }
        $info = @{}
        $platformLines = @()
        if ($src) {
            $version = ((Get-Content (Join-Path $src 'pyproject.toml')) | Where-Object { $_ -match '^version\s*=' } | Select-Object -First 1) -replace '^version\s*=\s*"([^"]*)".*$', '$1'
            $platformLines = @(Get-Content (Join-Path (Join-Path $src 'packaging') 'platforms.txt') | Where-Object { $_.Trim() -and -not $_.TrimStart().StartsWith('#') })
            $rev = ''
            if (Get-Command git -ErrorAction SilentlyContinue) {
                $branch = & git -C $src rev-parse --abbrev-ref HEAD 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $short = & git -C $src rev-parse --short HEAD 2>$null
                    $rev = " ($branch $short"
                    if (& git -C $src status --porcelain 2>$null) { $rev += ', modified' }
                    $rev += ')'
                }
            }
            Ok "Installing from this checkout" $rev.Trim(); Note (Tilde $src)
        } elseif ($folder) {
            $manifest = Read-Manifest ([IO.File]::ReadAllText((Join-Path $folder 'latest.txt')))
            $info = $manifest.Info; $platformLines = $manifest.Platforms
            foreach ($k in 'version', 'wheel', 'sha256') { if (-not $info[$k]) { Fail "The version information in $(Tilde $folder)\latest.txt is incomplete." } }
            $version = $info['version']
            Ok 'Installing from this folder' ("(version " + ($version -replace '\+.*$', '') + ')'); Note (Tilde $folder)
        } else {
            Show-Busy 'Checking for the latest version'
            try { $text = (Invoke-WebRequest -UseBasicParsing "$base/latest.txt").Content }
            catch { Clear-Busy 'Checking for the latest version'; Add-Log $_.Exception.Message; Fail "Could not reach $base/latest.txt. Check your internet connection." $true }
            Clear-Busy 'Checking for the latest version'
            if ($text -is [byte[]]) { $text = [Text.Encoding]::UTF8.GetString($text) }
            $manifest = Read-Manifest $text
            $info = $manifest.Info; $platformLines = $manifest.Platforms
            foreach ($k in 'version', 'wheel', 'sha256') { if (-not $info[$k]) { Fail "The version information at $base/latest.txt is incomplete." } }
            $version = $info['version']
            Ok ('Latest version is ' + ($version -replace '\+.*$', ''))
        }
        $shortVersion = $version -replace '\+.*$', ''
        # A latest.txt from before the list existed: Domo and Power BI are what it could install.
        if (-not $platformLines -or $platformLines.Count -eq 0) {
            $platformLines = @('domo|Domo|domo|available|chrome', 'powerbi|Power BI|powerbi|available|system')
        }

        # =========================================================================
        # Step 1: platforms
        # =========================================================================
        # packaging/platforms.txt is the whole menu (build.py puts it in latest.txt), so a new
        # platform needs a line there and nothing here.
        $rows = @()
        foreach ($line in $platformLines) {
            $f = $line.Split('|')
            if ($f.Count -ge 5) { $rows += [pscustomobject]@{ Key = $f[0]; Name = $f[1]; Extra = $f[2]; Status = $f[3]; Browser = $f[4] } }
        }
        $avail = @(0..($rows.Count - 1) | Where-Object { $rows[$_].Status -eq 'available' })
        if ($avail.Count -eq 0) { Fail 'The download offers no platform that can be installed yet.' }

        # What was chosen last time comes back ticked.
        $selected = @{}
        $savedFile = Join-Path $homeDir 'platforms'
        if (Test-Path $savedFile) {
            foreach ($k in ((Get-Content $savedFile -Raw) -split '[,\s]+')) {
                if (-not $k) { continue }
                $i = 0; foreach ($r in $rows) { if ($r.Key -eq $k -and $r.Status -eq 'available') { $selected[$i] = $true }; $i++ }
            }
        }

        Step 'Step 1 of 4' 'Choose your platform'
        if ($env:ESTATE_SCANNER_PLATFORMS) {
            $selected = @{}
            if ($env:ESTATE_SCANNER_PLATFORMS -eq 'all') { foreach ($i in $avail) { $selected[$i] = $true } }
            else {
                foreach ($k in ($env:ESTATE_SCANNER_PLATFORMS -split '[,\s]+')) {
                    if (-not $k) { continue }
                    $idx = -1; for ($i = 0; $i -lt $rows.Count; $i++) { if ($rows[$i].Key -eq $k) { $idx = $i } }
                    if ($idx -lt 0) { Fail ("ESTATE_SCANNER_PLATFORMS names '$k', which is not a platform. Choose from: " + (($rows | ForEach-Object { $_.Key }) -join ' ')) }
                    if ($rows[$idx].Status -ne 'available') { Fail ($rows[$idx].Name + ' is not available yet.') }
                    $selected[$idx] = $true
                }
            }
        } elseif ($ask) {
            $hint = { param($r) if ($r.Browser -eq 'chrome') { 'signs in with Chrome or Edge' } elseif ($r.Browser -eq 'system') { 'signs in with your browser' } else { '' } }
            $cur = $avail[0]
            W '   Which BI platforms will you scan?' '' $true
            W ("   $gUp $gDown move   space select   a all   enter continue") 'DarkGray' $true
            Write-Host ''
            $width = 80; try { $width = [Math]::Max(40, [Console]::WindowWidth - 1) } catch { }
            $draw = {
                for ($i = 0; $i -lt $rows.Count; $i++) {
                    $r = $rows[$i]
                    $line = [Console]::CursorTop
                    Write-Host -NoNewline (' ' * $width); [Console]::SetCursorPosition(0, $line)
                    if ($r.Status -ne 'available') {
                        W ('     ' + $gSoon + ' ' + $r.Name.PadRight(16) + ' coming soon') 'DarkGray' $true
                    } else {
                        W '   '
                        if ($i -eq $cur) { W $gCur 'Yellow' } else { W ' ' }
                        W ' '
                        if ($selected[$i]) { W $gOn 'Cyan' } else { W $gOff 'DarkGray' }
                        W ' '
                        if ($i -eq $cur) { W $r.Name.PadRight(16) 'White' } else { W $r.Name.PadRight(16) }
                        W (' ' + (& $hint $r)) 'DarkGray' $true
                    }
                }
            }
            Hide-Cursor
            & $draw
            $menuTop = [Console]::CursorTop - $rows.Count   # taken after drawing, so a scrolled window is right
            $done = $false
            while (-not $done) {
                $key = [Console]::ReadKey($true)
                $pos = [array]::IndexOf($avail, $cur)
                switch ($key.Key.ToString()) {
                    { $_ -in 'UpArrow', 'K' } { $cur = $avail[($pos - 1 + $avail.Count) % $avail.Count] }
                    { $_ -in 'DownArrow', 'J' } { $cur = $avail[($pos + 1) % $avail.Count] }
                    'Spacebar' { if ($selected[$cur]) { $selected.Remove($cur) } else { $selected[$cur] = $true } }
                    'A' { if (@($avail | Where-Object { $selected[$_] }).Count -ge $avail.Count) { $selected = @{} } else { foreach ($i in $avail) { $selected[$i] = $true } } }
                    'Enter' { if ($selected.Count -eq 0) { $selected[$cur] = $true }; $done = $true }
                    { $_ -in 'Q', 'Escape' } { $state.Cancelled = $true; throw 'Cancelled.' }
                }
                if (-not $done) { [Console]::SetCursorPosition(0, $menuTop); & $draw }
            }
            # Fold the menu (question, hint, blank, the rows) into the one-line summary below.
            $blockTop = $menuTop - 3
            for ($i = 0; $i -lt ($rows.Count + 3); $i++) { [Console]::SetCursorPosition(0, $blockTop + $i); Write-Host -NoNewline (' ' * $width) }
            [Console]::SetCursorPosition(0, $blockTop)
            Show-Cursor
        } elseif ($selected.Count -eq 0) {
            foreach ($i in $avail) { $selected[$i] = $true }   # nobody to ask and nothing chosen before: everything available
        }

        $chosen = @(0..($rows.Count - 1) | Where-Object { $selected[$_] })
        if ($chosen.Count -eq 0) { Fail 'No platform was chosen.' }
        $chosenKeys = ($chosen | ForEach-Object { $rows[$_].Key }) -join ','
        $chosenNames = ($chosen | ForEach-Object { $rows[$_].Name }) -join ', '
        $extraList = @('ui')
        foreach ($i in $chosen) { if ($rows[$i].Extra -and ($extraList -notcontains $rows[$i].Extra)) { $extraList += $rows[$i].Extra } }
        $extras = $extraList -join ','
        # (@(...).Count, not [bool](...): Domo is row 0, and a lone 0 is falsy.)
        $needBrowser = (@($chosen | Where-Object { $rows[$_].Browser -eq 'chrome' }).Count -gt 0)
        Set-Content -Path $savedFile -Value $chosenKeys -Encoding ASCII
        Ok ('Platforms: ' + $chosenNames)

        # =========================================================================
        # Step 2: Python 3.11 or newer
        # =========================================================================
        Step 'Step 2 of 4' 'Python'
        # 64-bit only: Playwright (Domo) has no 32-bit Windows build, so a 32-bit Python would fail to install it.
        # No double quotes in code passed to `python -c`: Windows PowerShell 5.1 strips them from native arguments.
        $probe = 'import sys, venv, ensurepip; sys.exit(0 if sys.version_info >= (3, 11) and sys.maxsize > 2**32 else 1)'
        function Test-Python([string[]]$Cmd) {
            try {
                $exe = $Cmd[0]; $rest = @($Cmd | Select-Object -Skip 1)
                & $exe @rest -c $probe 2>$null | Out-Null
                return ($LASTEXITCODE -eq 0)
            } catch { return $false }
        }
        $py = $null
        if ($env:ESTATE_SCANNER_FORCE_UV -ne '1') {
            $candidates = @(@('py', '-3.13'), @('py', '-3.12'), @('py', '-3.11'), @('python3.13'), @('python3.12'), @('python3.11'), @('python3'), @('python'))
            foreach ($c in $candidates) {
                $found = Get-Command $c[0] -ErrorAction SilentlyContinue
                if (-not $found) { continue }
                if ($found.Source -like '*\WindowsApps\*') { continue }   # the Store stub, not a real Python
                if (Test-Python $c) {
                    $exe = $c[0]; $rest = @($c | Select-Object -Skip 1)
                    $py = (& $exe @rest -c 'import sys; print(sys.executable)').Trim()
                    break
                }
            }
        }
        function Get-PyVersion([string]$Exe) { (& $Exe -c 'import sys; print(*sys.version_info[:3], sep=chr(46))').Trim() }
        if ($py) {
            Ok ('Python ' + (Get-PyVersion $py) + ' found') ('at ' + (Tilde $py))
        } else {
            $here = if ($onWindows) { 'this PC' } else { 'this computer' }
            Note "There is no Python 3.11 or newer on $here, so one is being set up for you."
            Note ('It is kept inside ' + (Tilde $homeDir) + "; nothing else on $here is changed.")
            $env:UV_UNMANAGED_INSTALL = Join-Path $homeDir 'uv'
            $uvScript = Join-Path $tmp 'uv-install.ps1'
            try { Invoke-WebRequest -UseBasicParsing $uvInstaller -OutFile $uvScript }
            catch { Add-Log $_.Exception.Message; Fail 'Could not download the Python installer (uv) from astral.sh.' $true }
            if (-not (Invoke-Step 'Installing Python 3.12 (a few minutes, no administrator rights needed)' $shellExe @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $uvScript))) { Fail 'Could not install Python 3.12.' $true }
            $uv = Join-Path $env:UV_UNMANAGED_INSTALL $uvName
            # A script that reported errors can still exit 0, so check it really put uv there.
            if (-not (Test-Path $uv)) { Fail 'Could not install Python 3.12.' $true }
            $env:UV_PYTHON_INSTALL_DIR = Join-Path $homeDir 'python'
            if (-not (Invoke-Step 'Installing Python 3.12' $uv @('python', 'install', '3.12'))) { Fail 'Could not install Python 3.12.' $true }
            $py = (& $uv python find 3.12).Trim()
            if (-not (Test-Python @($py))) {
                $hint = if ($onWindows) { ' It may need the free Microsoft Visual C++ Redistributable: https://aka.ms/vs/17/release/vc_redist.x64.exe' } else { '' }
                Fail "The Python that was installed ($(Tilde $py)) does not work.$hint"
            }
            Ok ('Python ' + (Get-PyVersion $py) + ' installed') ('in ' + (Tilde (Join-Path $homeDir 'python')))
        }

        # =========================================================================
        # Step 3: Estate Scanner
        # =========================================================================
        Step 'Step 3 of 4' 'Install Estate Scanner'
        if ((Test-Path $venvPy) -and -not (Test-Python @($venvPy))) { Remove-Item -Recurse -Force $venv }
        if (-not (Test-Path $venvPy)) {
            if (-not (Invoke-Step 'Creating a private environment' $py @('-m', 'venv', $venv))) { Fail ('Could not create a Python environment in ' + (Tilde $venv) + '.') $true }
        }
        # The extras are part of the stamp: choosing another platform later must install its libraries.
        $stampFile = Join-Path $venv '.installed-version'
        $stamp = "$version|$extras"
        $installed = if (Test-Path $stampFile) { (Get-Content $stampFile -Raw).Trim() } else { '' }
        $pipArgs = @('-m', 'pip', 'install', '--quiet', '--disable-pip-version-check', '--upgrade')
        if ($src) {
            # A checkout changes without its version changing, so it is always reinstalled, and its
            # stamp can never match a published version's.
            if (-not (Invoke-Step "Installing Estate Scanner for $chosenNames (about a minute the first time)" $venvPy ($pipArgs + "$src[$extras]"))) { Fail 'Installing from the checkout failed.' $true }
            Set-Content -Path $stampFile -Value "checkout|$extras" -Encoding ASCII
            Ok "Installed Estate Scanner $shortVersion" "$gDot from this checkout"
        } elseif ($installed -ne $stamp) {
            $wheel = Join-Path $tmp $info['wheel']
            if ($folder) {
                try { Copy-Item (Join-Path $folder $info['wheel']) $wheel } catch { Fail ('Could not read ' + (Tilde $folder) + '\' + $info['wheel'] + '.') }
                $gotWord = 'Checked'
            } else {
                Show-Busy "Downloading Estate Scanner $shortVersion"
                try { Invoke-WebRequest -UseBasicParsing ($base + '/' + $info['wheel']) -OutFile $wheel }
                catch { Clear-Busy "Downloading Estate Scanner $shortVersion"; Add-Log $_.Exception.Message; Fail ('Could not download ' + $base + '/' + $info['wheel'] + '.') $true }
                Clear-Busy "Downloading Estate Scanner $shortVersion"
                $gotWord = 'Downloaded'
            }
            $got = (Get-FileHash -Algorithm SHA256 $wheel).Hash.ToLower()
            if ($got -ne $info['sha256'].ToLower()) { Fail 'The file is corrupt (checksum mismatch). Download it again.' }
            Ok "$gotWord $shortVersion" "$gDot checksum verified"
            if (-not (Invoke-Step "Installing Estate Scanner for $chosenNames (about a minute the first time)" $venvPy ($pipArgs + "$wheel[$extras]"))) { Fail "Installing the app's libraries failed." $true }
            Set-Content -Path $stampFile -Value $stamp -Encoding ASCII
            Ok "Installed Estate Scanner $shortVersion"
        } else {
            Ok "Estate Scanner $shortVersion is already installed"
        }

        # A command for next time.
        $bin = Join-Path $homeDir 'bin'
        New-Item -ItemType Directory -Force -Path $bin | Out-Null
        Set-Content -Path (Join-Path $bin 'estate-scanner.cmd') -Encoding ASCII -Value @(
            '@echo off',
            "if ""%~1""=="""" ( ""$venvPy"" -m estate_scanner ui ) else ( ""$venvPy"" -m estate_scanner %* )")

        # =========================================================================
        # Step 4: the shortcut, and the sign-in browser
        # =========================================================================
        Step 'Step 4 of 4' 'Finish setting up'
        $windowIssue = $false
        if ($onWindows -or $env:ESTATE_SCANNER_ASSUME_WEBVIEW2) {
            if (-not $env:ESTATE_SCANNER_ASSUME_WEBVIEW2 -and (Get-DotNetRelease) -lt 461808) {
                $windowIssue = $true
                Warn 'This PC has a .NET Framework older than 4.7.2 (Windows Update installs it), which the app window needs.'
            } elseif (Test-WebView2) {
                Ok 'Microsoft Edge WebView2 found' 'for the app window'
            } else {
                Note 'The app window is drawn by Microsoft Edge WebView2, a free Microsoft component this PC does not have yet.'
                $setting = $env:ESTATE_SCANNER_INSTALL_WEBVIEW2   # 1 installs without asking, 0 never
                $install = if ($setting -eq '1') { $true } elseif ($setting -eq '0') { $false } else { Confirm-Yes 'Install it now (about 2 MB; Windows may ask for permission)?' }
                if ($install -and (Install-WebView2)) { Ok 'Microsoft Edge WebView2 installed' 'for the app window' }
                else { $windowIssue = $true; Warn 'Not installed.' }
            }
            if ($windowIssue) {
                Note 'Estate Scanner will open in your web browser instead. To get its own window, install WebView2'
                Note 'from https://developer.microsoft.com/microsoft-edge/webview2/ whenever you like; there is no need'
                Note 'to run this installer again.'
            }
        }
        $shortcut = ''
        if ($onWindows -and $env:ESTATE_SCANNER_NO_APP -ne '1') {
            # A Start menu shortcut to the windowless Python, with the app's icon, so the app has its own
            # name and icon and the next start is a click. Nothing is downloaded: it points at what was just installed.
            try {
                $lnk = Join-Path ([Environment]::GetFolderPath('Programs')) 'Estate Scanner.lnk'
                $wsh = New-Object -ComObject WScript.Shell
                $sc = $wsh.CreateShortcut($lnk)
                $sc.TargetPath = $venvPyw
                $sc.Arguments = '-m estate_scanner ui'
                $sc.WorkingDirectory = $homeDir
                $sc.Description = 'Inventory your BI estate'
                $ico = Join-Path $venv 'Lib\site-packages\estate_scanner\assets\EstateScanner.ico'
                if (Test-Path $ico) { $sc.IconLocation = $ico }
                $sc.Save()
                $shortcut = $lnk
                Ok 'Estate Scanner added to the Start menu'
            } catch {
                Add-Log $_.Exception.Message
                Warn ('The Start menu shortcut could not be created. It still starts with ' + (Tilde (Join-Path $bin 'estate-scanner.cmd')))
            }
        }
        if ($needBrowser) {
            $browsers = @(
                "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
                "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
                "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
                "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
                "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe")
            $haveBrowser = [bool]($browsers | Where-Object { $_ -and (Test-Path $_) })
            if ($haveBrowser -or -not $onWindows) { Ok 'Chrome or Edge found' 'for signing in' }
            else { Warn 'Install Google Chrome or Microsoft Edge before you sign in to your BI platform.' }
        }

        Write-Host ''
        W ('   ' + $rule) 'DarkGray' $true
        Write-Host ''
        W '   ' ; W $gOk 'Cyan'; W '  '; W 'All set.' 'White' $true
        if ($shortcut) { Note 'Next time, open Estate Scanner from the Start menu.' }
        else { Note ('Next time, run  ' + (Tilde (Join-Path $bin 'estate-scanner.cmd'))) }
        Note 'Run this installer again to update, or to add another platform.'
        Note ('Your scans are kept in ' + (Tilde $homeDir) + ', on this computer.')
        Note 'Installing downloaded Python packages from PyPI (and Python from astral.sh if you had none).'
        Note 'Running Estate Scanner contacts only your BI platform.'

        $global:LASTEXITCODE = 0
        if ($env:ESTATE_SCANNER_NO_LAUNCH -eq '1') { return }
        if ($env:ESTATE_SCANNER_CHECK -eq '1') {
            Write-Host ''; Write-Host '   Running the self-test ...'; Write-Host ''
            & $venvPy -m estate_scanner ui --check
            if ($LASTEXITCODE -ne 0) { Fail 'The self-test failed (see above).' }
            return
        }
        Write-Host ''; Write-Host '   Starting Estate Scanner ...'; Write-Host ''
        # Detached, with no console window, so closing this terminal does not close the app.
        if ($onWindows) { Start-Process -FilePath $venvPyw -ArgumentList '-m estate_scanner ui' -WorkingDirectory $homeDir }
        else { & $venvPy -m estate_scanner ui }
    }
    catch {
        Show-Cursor
        Write-Host ''
        if ($state.Cancelled) { Write-Host '   Cancelled.'; Write-Host ''; $global:LASTEXITCODE = 130 }
        else {
            $message = $_.Exception.Message
            if ($fancy) { Write-Host ('   ' + $gBad + ' ' + $message) -ForegroundColor Red } else { Write-Host ('   ' + $gBad + ' ' + $message) }
            if ($state.Tail) {
                foreach ($l in (Get-LogTail)) { Note ($l.Substring(0, [Math]::Min(72, $l.Length))) }
                Write-Host ''; Note ('The full details are in ' + (Tilde $log))
            }
            Write-Host ''
            $global:LASTEXITCODE = 1
        }
    }
    finally {
        Show-Cursor
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
}

Install-EstateScanner -ScriptDir $PSScriptRoot
# Run as a file (install.cmd, or -File), hand the result to whoever started it; under `irm | iex`
# there is no file, and exit here would close the user's own terminal.
if ($PSCommandPath) { exit $global:LASTEXITCODE }
