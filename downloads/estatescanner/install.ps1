# Estate Scanner installer for Windows (PowerShell 5.1 or newer).
#
#   irm https://bimigrations.com/downloads/estatescanner/install.ps1 | iex
#
# Finds Python 3.11+ (or installs one for you, no administrator rights needed),
# installs the latest Estate Scanner into %USERPROFILE%\.estate-scanner, then
# starts it. Run it again any time: it updates and starts the app.
#
# Optional settings (environment variables), mostly for testing and support:
#   ESTATE_SCANNER_BASE, ESTATE_SCANNER_HOME, ESTATE_SCANNER_CHECK=1,
#   ESTATE_SCANNER_FORCE_UV=1, ESTATE_SCANNER_NO_LAUNCH=1

# A function, so `exit` never closes the user's terminal and a truncated
# download runs nothing.
function Install-EstateScanner {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'   # progress bars make Invoke-WebRequest very slow on 5.1
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $base = if ($env:ESTATE_SCANNER_BASE) { $env:ESTATE_SCANNER_BASE } else { 'https://bimigrations.com/downloads/estatescanner' }
    $home_dir = if ($env:ESTATE_SCANNER_HOME) { $env:ESTATE_SCANNER_HOME } else { Join-Path $env:USERPROFILE '.estate-scanner' }
    $venv = Join-Path $home_dir 'venv'
    $venv_py = Join-Path $venv 'Scripts\python.exe'
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("estate-scanner-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $home_dir, $tmp | Out-Null

    try {
        Write-Host 'Looking up the latest Estate Scanner ...'
        try { $manifest = (Invoke-WebRequest -UseBasicParsing "$base/latest.txt").Content }
        catch { throw "could not reach $base/latest.txt (check your internet connection)." }
        $info = @{}
        foreach ($line in ($manifest -split "`r?`n")) { if ($line -match '^(\w+)=(.*)$') { $info[$Matches[1]] = $Matches[2].Trim() } }
        foreach ($k in 'version', 'wheel', 'sha256') { if (-not $info[$k]) { throw "the version information at $base/latest.txt is incomplete." } }

        # --- Python 3.11 or newer ------------------------------------------
        $probe = 'import sys, venv, ensurepip; sys.exit(0 if sys.version_info >= (3, 11) else 1)'
        function Test-Python([string[]]$cmd) {
            try {
                $exe = $cmd[0]; $rest = @($cmd | Select-Object -Skip 1)
                & $exe @rest -c $probe 2>$null | Out-Null
                return ($LASTEXITCODE -eq 0)
            } catch { return $false }
        }
        $py = $null
        if ($env:ESTATE_SCANNER_FORCE_UV -ne '1') {
            $candidates = @(
                @('py', '-3.13'), @('py', '-3.12'), @('py', '-3.11'), @('python3'), @('python'))
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
        if (-not $py) {
            Write-Host "No suitable Python found. Installing Python 3.12 into $home_dir\python (no administrator rights needed) ..."
            $env:UV_UNMANAGED_INSTALL = Join-Path $home_dir 'uv'
            try { Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression | Out-Null }
            catch { throw 'could not download the Python installer (uv) from astral.sh.' }
            $uv = Join-Path $env:UV_UNMANAGED_INSTALL 'uv.exe'
            $env:UV_PYTHON_INSTALL_DIR = Join-Path $home_dir 'python'
            & $uv python install 3.12 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'could not install Python 3.12.' }
            $py = (& $uv python find 3.12).Trim()
            if (-not (Test-Python @($py))) { throw "the Python that was installed ($py) does not work." }
        }
        Write-Host "Using Python at $py"

        # --- private environment -------------------------------------------
        if ((Test-Path $venv_py) -and -not (Test-Python @($venv_py))) { Remove-Item -Recurse -Force $venv }
        if (-not (Test-Path $venv_py)) {
            & $py -m venv $venv
            if ($LASTEXITCODE -ne 0) { throw "could not create a Python environment in $venv." }
        }

        $stamp = Join-Path $venv '.installed-version'
        $installed = if (Test-Path $stamp) { (Get-Content $stamp -Raw).Trim() } else { '' }
        if ($installed -ne $info['version']) {
            Write-Host "Downloading Estate Scanner $($info['version']) ..."
            $wheel = Join-Path $tmp $info['wheel']
            try { Invoke-WebRequest -UseBasicParsing "$base/$($info['wheel'])" -OutFile $wheel }
            catch { throw "could not download $base/$($info['wheel'])." }
            $got = (Get-FileHash -Algorithm SHA256 $wheel).Hash.ToLower()
            if ($got -ne $info['sha256'].ToLower()) { throw 'the download is corrupt (checksum mismatch). Try again.' }
            Write-Host 'Installing (about a minute the first time) ...'
            & $venv_py -m pip install --quiet --disable-pip-version-check --upgrade "$wheel[ui,domo]"
            if ($LASTEXITCODE -ne 0) { throw "installing the app's libraries failed (see the messages above)." }
            Set-Content -Path $stamp -Value $info['version']
        } else {
            Write-Host "Estate Scanner $($info['version']) is already installed."
        }

        # --- a command for next time ---------------------------------------
        $bin = Join-Path $home_dir 'bin'
        New-Item -ItemType Directory -Force -Path $bin | Out-Null
        Set-Content -Path (Join-Path $bin 'estate-scanner.cmd') -Encoding ASCII -Value @(
            '@echo off',
            "if ""%~1""=="""" ( ""$venv_py"" -m estate_scanner ui ) else ( ""$venv_py"" -m estate_scanner %* )")

        # --- the browser used for the Domo sign-in -------------------------
        $browsers = @(
            "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
            "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
            "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe")
        if (-not ($browsers | Where-Object { Test-Path $_ })) {
            Write-Host 'Note: install Google Chrome or Microsoft Edge before you sign in to your BI platform.'
        }

        Write-Host ''
        Write-Host "Installed. To start it again later run:  $bin\estate-scanner.cmd"
        Write-Host "Your scan data is kept in ~\.estate-scanner (estate.db). Nothing is sent anywhere except to your BI platform."

        if ($env:ESTATE_SCANNER_NO_LAUNCH -eq '1') { return }
        if ($env:ESTATE_SCANNER_CHECK -eq '1') {
            & $venv_py -m estate_scanner ui --check
            if ($LASTEXITCODE -ne 0) { throw 'the self-test failed (see above).' }
            return
        }
        Write-Host 'Starting Estate Scanner ...'
        & $venv_py -m estate_scanner ui
    }
    catch {
        Write-Host ''
        Write-Host "Estate Scanner could not be installed: $($_.Exception.Message)" -ForegroundColor Red
        $global:LASTEXITCODE = 1
    }
    finally {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
}

Install-EstateScanner
