# BIMControl installer for Windows (PowerShell 5.1 or newer).
#
#   irm https://bimigrations.com/downloads/bimcontrol/install.ps1 | iex
#
# Finds Python 3.11 or newer (or installs one for you, with no administrator rights), installs
# BIMControl into a private environment, and starts it. Run it again any time: it updates to the
# latest version. Nothing outside %USERPROFILE%\.bimcontrol is changed.
#
# Run as a file it can also install without the website:
#   powershell -ExecutionPolicy Bypass -File install.ps1  
#       from the folder a zip unpacks to (beside latest.txt and its wheel): installs that wheel
#       and fetches nothing from bimigrations.com
#   powershell -ExecutionPolicy Bypass -File packaging\install.ps1
#       from a checkout of the repository: installs that checkout
# Under `irm | iex` there is no file, so customers never take either path.
#
# Settings (environment variables, all optional, mostly for testing and support):
#   BIMCONTROL_SOURCE         install from this checkout (found on its own when run from one)
#   BIMCONTROL_BASE           where latest.txt and the wheel are downloaded from
#   BIMCONTROL_HOME           install folder (default %USERPROFILE%\.bimcontrol; the same folder holds the app's data)
#   BIMCONTROL_CHECK=1        install, run the self-test (ui --check), do not open the app
#   BIMCONTROL_FORCE_UV=1     ignore any Python already on the machine
#   BIMCONTROL_UV_INSTALLER   where the Python installer (uv) is fetched from if one is needed
#   BIMCONTROL_NO_LAUNCH=1    install only
#
# This file is plain ASCII on purpose: `irm` decodes what it downloads, and a stray character
# in the wrong encoding would break the script. It also runs under PowerShell 7 on a Mac or Linux
# box (the paths that differ are the $onWindows lines), which is how its logic is tested.

# A function, so `exit` never closes the user's terminal, nothing leaks into their session,
# and a truncated download runs nothing at all.
function Install-BIMControl {
    param([string]$ScriptDir = '')

    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'   # progress bars make Invoke-WebRequest very slow on 5.1
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch { }

    $onWindows = ($env:OS -eq 'Windows_NT')
    $userHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
    $base = if ($env:BIMCONTROL_BASE) { $env:BIMCONTROL_BASE.TrimEnd('/') } else { 'https://bimigrations.com/downloads/bimcontrol' }
    $homeDir = if ($env:BIMCONTROL_HOME) { $env:BIMCONTROL_HOME } else { Join-Path $userHome '.bimcontrol' }
    $uvInstaller = if ($env:BIMCONTROL_UV_INSTALLER) { $env:BIMCONTROL_UV_INSTALLER } else { 'https://astral.sh/uv/install.ps1' }
    $extras = 'ui,powerbi,domo,warehouse'   # what packaging/start.py installs too
    $venv = Join-Path $homeDir 'venv'
    $venvBin = Join-Path $venv $(if ($onWindows) { 'Scripts' } else { 'bin' })
    $venvPy = Join-Path $venvBin $(if ($onWindows) { 'python.exe' } else { 'python' })
    $uvName = if ($onWindows) { 'uv.exe' } else { 'uv' }
    $shellExe = if ($onWindows) { 'powershell.exe' } else { 'pwsh' }
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ('bimcontrol-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $homeDir, $tmp | Out-Null
    $log = Join-Path $homeDir 'install.log'   # everything the steps print, kept for support; the last run only
    [IO.File]::WriteAllText($log, '')

    $state = @{ Tail = $false }

    function Say([string]$Text = '') { Write-Host $Text }
    function Step([string]$Title) { Write-Host ''; Write-Host ('== ' + $Title) }
    function Add-Log([string]$Text) { [IO.File]::AppendAllText($log, $Text + "`n") }
    # Fail "what went wrong" [$true]: stops the install; $true also shows the failed step's last output.
    function Fail([string]$Message, [bool]$WithTail = $false) { $state.Tail = $WithTail; throw $Message }
    function Quote-Arg([string]$Arg) { if ($Arg -match '[\s"]') { '"' + ($Arg -replace '"', '\"') + '"' } else { $Arg } }

    # Invoke-Step "what is happening" file arg...  Quiet: its output goes to the log.
    # Returns $true when the command exits 0.
    function Invoke-Step([string]$Message, [string]$File, [string[]]$ArgList = @()) {
        Say ('   ... ' + $Message)
        Add-Log ("`n>>> " + $Message)
        $outFile = Join-Path $tmp ([Guid]::NewGuid().ToString('N') + '.out')
        $errFile = $outFile + '.err'
        $params = @{ FilePath = $File; NoNewWindow = $true; PassThru = $true; RedirectStandardOutput = $outFile; RedirectStandardError = $errFile }
        if ($ArgList.Count -gt 0) { $params.ArgumentList = (($ArgList | ForEach-Object { Quote-Arg $_ }) -join ' ') }
        try { $proc = Start-Process @params }
        catch { Add-Log $_.Exception.Message; return $false }   # the program is not there, or would not start
        $null = $proc.Handle   # keeps the exit code readable once the process has ended
        $proc.WaitForExit()
        foreach ($f in $outFile, $errFile) { if (Test-Path $f) { [IO.File]::AppendAllText($log, [IO.File]::ReadAllText($f)) } }
        return ($proc.ExitCode -eq 0)
    }

    function Get-Field([string]$Text, [string]$Name) {
        $line = ($Text -split "`n") | Where-Object { $_ -match ('^' + $Name + '=') } | Select-Object -First 1
        if ($line) { return ($line -replace ('^' + $Name + '='), '').Trim() } else { return '' }
    }

    try {
        Say ''
        Say 'BIMControl  (BI Migrations)'
        Say 'Migrates dashboards, data and logic to Power BI / Fabric, and checks the numbers match.'

        # --- where the app comes from -------------------------------------------------
        # A checkout (found around this file, or BIMCONTROL_SOURCE), or a folder with latest.txt and
        # its wheel beside this file (the zip), or the website. $ScriptDir is empty under `irm | iex`.
        $src = $env:BIMCONTROL_SOURCE
        $folder = ''
        if ($ScriptDir) {
            $repo = Split-Path -Parent $ScriptDir
            if (-not $src -and (Test-Path (Join-Path $ScriptDir 'start.py')) -and $repo `
                -and (Test-Path (Join-Path $repo 'pyproject.toml')) -and (Test-Path (Join-Path $repo 'src\bimcontrol'))) {
                $src = $repo
            } elseif (-not $src -and (Test-Path (Join-Path $ScriptDir 'latest.txt'))) {
                $named = Get-Field (Get-Content (Join-Path $ScriptDir 'latest.txt') -Raw) 'wheel'
                if ($named -and (Test-Path (Join-Path $ScriptDir $named))) { $folder = $ScriptDir }
            }
        }
        if ($src) {
            if (-not ((Test-Path (Join-Path $src 'pyproject.toml')) -and (Test-Path (Join-Path $src 'src\bimcontrol')))) { Fail "BIMCONTROL_SOURCE is not a checkout of BIMControl: $src" }
            $src = (Resolve-Path $src).Path
        }

        $info = ''
        if ($src) {
            $pyproject = Get-Content (Join-Path $src 'pyproject.toml') | Where-Object { $_ -match '^version\s*=\s*"' } | Select-Object -First 1
            $version = ($pyproject -replace '^version\s*=\s*"([^"]*)".*', '$1')
            Say "Installing from the checkout $src"
        } elseif ($folder) {
            $info = Get-Content (Join-Path $folder 'latest.txt') -Raw
            Say "Installing from the folder $folder"
        } else {
            try { $info = (Invoke-WebRequest -UseBasicParsing "$base/latest.txt").Content }
            catch { Add-Log $_.Exception.Message; Fail "Could not reach $base/latest.txt. Check your internet connection." }
            if ($info -is [byte[]]) { $info = [Text.Encoding]::UTF8.GetString($info) }
        }
        if (-not $src) {
            $version = Get-Field $info 'version'; $wheelName = Get-Field $info 'wheel'; $sha = Get-Field $info 'sha256'
            if (-not ($version -and $wheelName -and $sha)) { Fail 'The version information (latest.txt) is incomplete.' }
        }
        $shortVersion = ($version -split '\+')[0]
        Say "Version: $shortVersion"

        # --- Python 3.11 or newer -----------------------------------------------------
        Step 'Python'
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
        if ($env:BIMCONTROL_FORCE_UV -ne '1') {
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
        if ($py) {
            Say "   Python found at $py"
        } else {
            Say "   There is no Python 3.11 or newer here, so one is being set up inside $homeDir."
            Say '   Nothing else on this computer is changed.'
            $env:UV_UNMANAGED_INSTALL = Join-Path $homeDir 'uv'
            $env:UV_PYTHON_INSTALL_DIR = Join-Path $homeDir 'python'
            $uvScript = Join-Path $tmp 'uv-install.ps1'
            try { Invoke-WebRequest -UseBasicParsing $uvInstaller -OutFile $uvScript }
            catch { Add-Log $_.Exception.Message; Fail 'Could not download the Python installer (uv) from astral.sh.' $true }
            if (-not (Invoke-Step 'Installing Python 3.12 (a few minutes, no administrator rights needed)' $shellExe @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $uvScript))) { Fail 'Could not install Python 3.12.' $true }
            $uv = Join-Path $env:UV_UNMANAGED_INSTALL $uvName
            # A script that reported errors can still exit 0, so check it really put uv there.
            if (-not (Test-Path $uv)) { Fail 'Could not install Python 3.12.' $true }
            if (-not (Invoke-Step 'Installing Python 3.12' $uv @('python', 'install', '3.12'))) { Fail 'Could not install Python 3.12.' $true }
            $py = (& $uv python find 3.12).Trim()
            if (-not (Test-Python @($py))) { Fail "The Python that was installed ($py) does not work." }
            Say "   Python installed in $homeDir\python"
        }

        # --- BIMControl itself --------------------------------------------------------
        Step 'BIMControl'
        if ((Test-Path $venvPy) -and -not (Test-Python @($venvPy))) { Remove-Item -Recurse -Force $venv }
        if (-not (Test-Path $venvPy)) {
            if (-not (Invoke-Step "Creating a private environment in $venv" $py @('-m', 'venv', $venv))) { Fail "Could not create a Python environment in $venv." $true }
        }
        # start.py writes .installed-wheel; this installer writes .installed-version. Running one after
        # the other is harmless: the other's stamp does not match and pip reinstalls.
        $stampFile = Join-Path $venv '.installed-version'
        $stamp = "$version|$extras"
        $installed = if (Test-Path $stampFile) { (Get-Content $stampFile -Raw).Trim() } else { '' }
        $pipArgs = @('-m', 'pip', 'install', '--quiet', '--disable-pip-version-check', '--upgrade')
        if ($src) {
            # A checkout changes without its version changing, so it is always reinstalled.
            if (-not (Invoke-Step 'Installing BIMControl from the checkout (a few minutes the first time)' $venvPy ($pipArgs + "$src[$extras]"))) { Fail 'Installing from the checkout failed.' $true }
            Set-Content -Path $stampFile -Value "checkout|$extras" -Encoding ASCII
        } elseif ($installed -ne $stamp) {
            $wheel = Join-Path $tmp $wheelName
            if ($folder) {
                try { Copy-Item (Join-Path $folder $wheelName) $wheel } catch { Fail "Could not read $folder\$wheelName." }
            } else {
                Say "   ... Downloading BIMControl $shortVersion"
                try { Invoke-WebRequest -UseBasicParsing "$base/$wheelName" -OutFile $wheel }
                catch { Add-Log $_.Exception.Message; Fail "Could not download $base/$wheelName." $true }
            }
            $got = (Get-FileHash -Algorithm SHA256 $wheel).Hash.ToLower()
            if ($got -ne $sha.ToLower()) { Fail 'The file is corrupt (checksum mismatch). Download it again.' }
            Say '   Checksum verified'
            if (-not (Invoke-Step "Installing BIMControl $shortVersion and its libraries (a few minutes the first time)" $venvPy ($pipArgs + "$wheel[$extras]"))) { Fail "Installing the app's libraries failed." $true }
            Set-Content -Path $stampFile -Value $stamp -Encoding ASCII
        } else {
            Say "   BIMControl $shortVersion is already installed"
        }

        # A command for next time.
        $binDir = Join-Path $homeDir 'bin'
        New-Item -ItemType Directory -Force -Path $binDir | Out-Null
        if ($onWindows) {
            Set-Content -Path (Join-Path $binDir 'bimcontrol.cmd') -Encoding ASCII -Value @('@echo off', "rem Starts BIMControl. Re-run the installer to update it.", "if `"%~1`"==`"`" (`"$venvPy`" -m bimcontrol ui) else (`"$venvPy`" -m bimcontrol %*)")
        }

        Say ''
        Say 'All set.'
        Say "Next time, run  $(Join-Path $binDir 'bimcontrol')"
        Say "Your migrations are kept in $homeDir, on this computer."
        Say 'Installing downloaded Python packages from PyPI (and Python from astral.sh if you had none).'
        Say 'Running BIMControl contacts only your BI platforms, your warehouse and the converter service.'
        Say 'BIMControl reads the scan EstateScanner made (.estate-scanner\estate.db in your home folder).'

        if ($env:BIMCONTROL_NO_LAUNCH -eq '1') { $global:LASTEXITCODE = 0; return }
        if ($env:BIMCONTROL_CHECK -eq '1') {
            Say ''; Say 'Running the self-test ...'; Say ''
            & $venvPy -m bimcontrol ui --check
            $global:LASTEXITCODE = $LASTEXITCODE
            return
        }
        Say ''; Say 'Starting BIMControl ...'; Say ''
        # Its own process, in a console of its own (python.exe, not pythonw.exe) so that a startup failure
        # or "opened in your browser instead" is readable; this installer's window can be closed.
        Start-Process -FilePath $venvPy -ArgumentList '-m bimcontrol ui' -WorkingDirectory $homeDir
        $global:LASTEXITCODE = 0
    }
    catch {
        Say ''
        Write-Host ('BIMControl cannot be installed: ' + $_.Exception.Message) -ForegroundColor Red
        if ($state.Tail) {
            Say ''; Say ('--- last lines of ' + $log + ' ---')
            Get-Content $log -Tail 15 | ForEach-Object { Say $_ }
        }
        Say ''
        $global:LASTEXITCODE = 1
    }
    finally {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
}

Install-BIMControl -ScriptDir $PSScriptRoot
# Run as a file (-File), hand the result to whoever started it; under `irm | iex`
# there is no file, and exit here would close the user's own terminal.
if ($PSCommandPath) { exit $global:LASTEXITCODE }
