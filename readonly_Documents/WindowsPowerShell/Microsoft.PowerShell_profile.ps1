# Alias
function ll {
    Get-ChildItem -Force
}

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias -Name vim -Value nvim -Force
}

if (Get-Command lazygit.exe -ErrorAction SilentlyContinue) {
    Set-Alias -Name lg -Value lazygit 
}

# ob sync commands
if (Get-Command ob -ErrorAction SilentlyContinue) {
    function ob-sync-list-remote {
        ob sync-list-remote
    }
    function ob-sync {
        ob sync
    }
    function ob-sync-cont {
        ob sync --continuous
    }
    function ob-sync-config-custom {
        ob sync-config --file-types "image,audio,video,pdf,unsupported"
        ob sync-config --configs "app,appearance,appearance-data,hotkey,core-plugin,core-plugin-data,community-plugin,community-plugin-data"
    }
}

if (Get-Command chezmoi.exe -ErrorAction SilentlyContinue) {
    Set-Alias -Name cmoi -Value chezmoi -Force
    function cmoicd {
        if (-not (Test-Path -Path $env:HOMEPATH\.local\share\chezmoi) ) { 
            return
        } else {
            Set-Location $env:HOMEPATH\.local\share\chezmoi
        }
    }
    function cmoisync {
        $chezmoi = "$env:HOMEPATH\.local\share\chezmoi"
        if (-not (Test-Path -Path $chezmoi)) { 
            return
        }
        git -C $chezmoi add -A
        $status = git -C $chezmoi status --porcelain
        if (-not $status) {
            Write-Host "cmoisync: nothing to commit, already up to date." -ForegroundColor DarkGray
            return
        }
        git -C $chezmoi commit -m "update $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git -C $chezmoi push --force
    }
    function cmoi-onedrive-apply {
        <#
    .SYNOPSIS
        Copies the PowerShell and WindowsPowerShell profile files to the
        OneDrive-mapped Documents folder.
    #>

        $oneDriveDocs = [Environment]::GetFolderPath('MyDocuments')
        $localDocs = Join-Path $env:USERPROFILE 'Documents'

        if (-not $oneDriveDocs) {
            Write-Error "cmoi-onedrive-apply: Could not resolve Documents special folder."
            return
        }

        if ($oneDriveDocs -eq $localDocs) {
            Write-Host "cmoi-onedrive-apply: Documents is not redirected to OneDrive. Nothing to do." -ForegroundColor DarkGray
            return
        }

        Write-Host "Local Documents:    $localDocs" -ForegroundColor DarkGray
        Write-Host "OneDrive Documents: $oneDriveDocs" -ForegroundColor DarkGray

        $profiles = @(
            @{ Source = Join-Path $localDocs 'PowerShell\Microsoft.PowerShell_profile.ps1'
                Dest  = Join-Path $oneDriveDocs 'PowerShell' 
            }
            @{ Source = Join-Path $localDocs 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
                Dest  = Join-Path $oneDriveDocs 'WindowsPowerShell' 
            }
        )

        $copied = 0

        foreach ($p in $profiles) {
            if (-not (Test-Path $p.Source)) {
                Write-Verbose "Skipping - $($p.Source) does not exist"
                continue
            }

            if (-not (Test-Path $p.Dest)) {
                New-Item -Path $p.Dest -ItemType Directory -Force | Out-Null
                Write-Host "  Created: $($p.Dest)" -ForegroundColor Yellow
            }

            Copy-Item -Path $p.Source -Destination $p.Dest -Force
            Write-Host "  Copied: $($p.Source) -> $($p.Dest)" -ForegroundColor Green
            $copied++
        }

        if ($copied -eq 0) {
            Write-Host "cmoi-onedrive-apply: No profile files found to copy." -ForegroundColor DarkGray
        } else {
            Write-Host "cmoi-onedrive-apply: Synced $copied profile(s) to OneDrive." -ForegroundColor Cyan
        }
    }
}

# Normal windows ssh
function sshnt {
    & 'C:\Windows\System32\OpenSSH\ssh.exe' @args
}

###############################
# Active Directory Stuff
###############################
if (Get-Command Get-ADUser -ErrorAction SilentlyContinue) {
    function Set-ADUserPasswordCustom {
        param (
            [Parameter(Mandatory)]
            [string]$Identity,     # samAccountName

            [Parameter(Mandatory)]
            [string]$NewPassword,  # New Password

            [switch]$ChangeAtLogon
        )

        # Reset password
        Set-ADAccountPassword `
            -Identity $Identity `
            -Reset `
            -NewPassword (ConvertTo-SecureString $NewPassword -AsPlainText -Force)

        if ($ChangeAtLogon) {
            # Get current user properties
            $user = Get-ADUser -Identity $Identity -Properties PasswordNeverExpires

            if ($user.PasswordNeverExpires) {
                Write-Warning "User '$Identity' has PasswordNeverExpires set. Cannot force change at next logon."
            } else {
                Set-ADUser -Identity $Identity -ChangePasswordAtLogon $true
            }
        }
    }
    function Get-ADUserCustom {
        param (
            [Parameter(Mandatory)]
            [string]$SearchPattern,

            [Parameter(Mandatory=$false)]
            [ValidateSet("Name", "DisplayName", "Description", "Title", "Department", "Manager", "UserPrincipalName", "samaccountname", "mail")]
            [string]$FilterProperty = "Name"     # samAccountName
        )
        $SearchString = "*" + $SearchPattern + "*" 
        Get-ADUser -Filter { $FilterProperty -like $SearchString } -Properties * | select Name, DisplayName, Description, Title, Department, Manager, UserPrincipalName, samaccountname, mail, Created, Modified, AccountExpirationDate, Enabled, LockedOut
    }
}
###############################
# Active Directory Stuff END
###############################


# Funcion to list active serial ports
function Get-ActiveSerialPorts {
    <#
    .SYNOPSIS
        Lists all active COM ports with detailed information as PowerShell objects.
    .EXAMPLE
        Get-ActiveSerialPorts
    .EXAMPLE
        Get-ActiveSerialPorts | Where-Object Status -eq 'OK'
    .EXAMPLE
        Get-ActiveSerialPorts | Sort-Object Port | Format-Table -AutoSize
    #>
    [CmdletBinding()]
    param()

    Get-CimInstance -ClassName Win32_PnPEntity |
        Where-Object { $_.Name -match 'COM(\d+)' } |
        ForEach-Object {
            [PSCustomObject]@{
                Port         = [regex]::Match($_.Name, 'COM\d+').Value
                Name         = $_.Name
                Description  = $_.Description
                Manufacturer = $_.Manufacturer
                DeviceID     = $_.DeviceID
                Status       = $_.Status
                Present      = $_.Present
            }
        } |
        Sort-Object { [int]($_.Port -replace 'COM', '') }
}

# Use wsl ssh instead of windows ssh if wsl distro exists
if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
    $wslSshCheck = wsl.exe which ssh 2>$null
    if ($wslSshCheck) {
        function ssh {
            wsl.exe ssh @args
        }
    } else {
        # Do nothing
        # Falback to windows ssh
    }
}


function cdy {
    param([string[]]$Args)

    if (-not (Get-Command yazi -ErrorAction SilentlyContinue)) {
        Write-Warning "cdy: 'yazi' not found in PATH."
        return
    }

    $tmp = [System.IO.Path]::GetTempFileName()
    Remove-Item $tmp -ErrorAction SilentlyContinue

    $yaziArgs = @("--cwd-file", $tmp)
    if ($Args) {
        $yaziArgs += $Args 
    }

    & yazi @yaziArgs

    if (Test-Path $tmp) {
        $dir = (Get-Content $tmp -Raw).Trim()
        Remove-Item $tmp -ErrorAction SilentlyContinue
        if ($dir -and (Test-Path -LiteralPath $dir)) {
            Set-Location -LiteralPath $dir
            return
        }
    }

    Write-Warning "cdy: yazi did not write a valid directory."
}


# -- Chezmoi Unmanaged File Tracking ----------------------------------
$global:ChezmoiWatchedFolders = @(
    "$env:USERPROFILE\.config\nvim"
    "$env:USERPROFILE\.config\yazi"
    # Add more folders here:
    # "$env:USERPROFILE\.config\some-app"
)

# -- Prompt Cache (chezmoi only -- git runs synchronously) -------------
$global:ChezmoiUnmanagedCache = @()
$global:ChezmoiStatusCache = $null

# -- Background Job State (chezmoi only) -------------------------------
$global:PromptBgJob = $null
$global:PromptLastCheck = [datetime]::MinValue
$global:PromptCheckInterval = 30  # seconds between background checks

function Start-PromptBgCheck {
    <#
    .SYNOPSIS
        Kicks off a background job for chezmoi status and unmanaged checks.
        Git is NOT included -- it runs synchronously in the prompt.
    #>
    if ($global:PromptBgJob -and $global:PromptBgJob.State -eq 'Running') {
        return
    }

    $elapsed = (Get-Date) - $global:PromptLastCheck
    if ($elapsed.TotalSeconds -lt $global:PromptCheckInterval) {
        return
    }

    if ($global:PromptBgJob) {
        Remove-Job $global:PromptBgJob -Force -ErrorAction SilentlyContinue
    }

    $folders = $global:ChezmoiWatchedFolders

    $global:PromptBgJob = Start-Job -ScriptBlock {
        param($watchedFolders)

        $result = @{
            CzStatus    = $null
            CzUnmanaged = @()
        }

        $result.CzStatus = chezmoi status 2>$null

        foreach ($folder in $watchedFolders) {
            if (-not (Test-Path -LiteralPath $folder)) {
                continue 
            }
            $files = chezmoi unmanaged $folder 2>$null
            if ($files) {
                $result.CzUnmanaged += $files 
            }
        }

        return $result
    } -ArgumentList (, $folders)
}

function Receive-PromptBgCheck {
    <#
    .SYNOPSIS
        Collects chezmoi results from a completed background job into cache.
        Also cleans up failed/stopped jobs so the next cycle can retry.
    #>
    if (-not $global:PromptBgJob) {
        return 
    }

    $state = $global:PromptBgJob.State
    if ($state -eq 'Running') {
        return 
    }

    if ($state -eq 'Completed') {
        $result = Receive-Job $global:PromptBgJob
        if ($result) {
            $global:ChezmoiStatusCache = $result.CzStatus
            $global:ChezmoiUnmanagedCache = if ($result.CzUnmanaged) {
                $result.CzUnmanaged 
            } else {
                @() 
            }
        }
    }

    # Clean up regardless of outcome (Completed, Failed, Stopped, etc.)
    Remove-Job $global:PromptBgJob -Force -ErrorAction SilentlyContinue
    $global:PromptBgJob = $null
    $global:PromptLastCheck = Get-Date
}

# -- Synchronous helpers for explicit commands -------------------------

function Get-ChezmoiUnmanaged {
    if (-not (Get-Command chezmoi.exe -ErrorAction SilentlyContinue)) {
        return @()
    }

    $allUnmanaged = @()
    foreach ($folder in $global:ChezmoiWatchedFolders) {
        if (-not (Test-Path -LiteralPath $folder)) {
            continue 
        }
        $result = chezmoi unmanaged $folder 2>$null
        if ($result) {
            $allUnmanaged += $result 
        }
    }

    $global:ChezmoiUnmanagedCache = $allUnmanaged
    $global:PromptLastCheck = Get-Date
    return $allUnmanaged
}

function cmoistatus {
    if (-not (Get-Command chezmoi.exe -ErrorAction SilentlyContinue)) {
        Write-Warning "cmoistatus: chezmoi not found in PATH."
        return
    }

    Write-Host "-- Chezmoi Status --" -ForegroundColor Cyan
    $czStatus = chezmoi status 2>$null
    $global:ChezmoiStatusCache = $czStatus
    if ($czStatus) {
        $czStatus | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "  (no changes)" -ForegroundColor DarkGray
    }

    Write-Host ""

    Write-Host "-- Unmanaged Files in Watched Folders --" -ForegroundColor Cyan
    $unmanaged = Get-ChezmoiUnmanaged
    if ($unmanaged.Count -gt 0) {
        foreach ($file in $unmanaged) {
            Write-Host "  + $file" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "  $($unmanaged.Count) unmanaged file(s) found." -ForegroundColor Yellow
        Write-Host "  Run " -NoNewline -ForegroundColor DarkGray
        Write-Host "cmoireadd" -NoNewline -ForegroundColor Green
        Write-Host " to re-add tracked changes and add these files." -ForegroundColor DarkGray
    } else {
        Write-Host "  (all watched folders fully tracked)" -ForegroundColor DarkGray
    }
}

function cmoireadd {
    if (-not (Get-Command chezmoi.exe -ErrorAction SilentlyContinue)) {
        Write-Warning "cmoireadd: chezmoi not found in PATH."
        return
    }

    Write-Host "-- Re-adding tracked files --" -ForegroundColor Cyan
    chezmoi re-add
    Write-Host "  Done." -ForegroundColor Green

    Write-Host ""

    Write-Host "-- Adding unmanaged files from watched folders --" -ForegroundColor Cyan
    $unmanaged = Get-ChezmoiUnmanaged
    if ($unmanaged.Count -gt 0) {
        $added = 0
        foreach ($file in $unmanaged) {
            $fullPath = Join-Path $env:USERPROFILE $file
            if (Test-Path -LiteralPath $fullPath) {
                Write-Host "  + $file" -ForegroundColor Green
                chezmoi add $fullPath
                $added++
            } else {
                Write-Host "  X $file (not found, skipping)" -ForegroundColor Yellow
            }
        }
        Write-Host ""
        Write-Host "  $added file(s) added to chezmoi." -ForegroundColor Green
    } else {
        Write-Host "  (no unmanaged files found)" -ForegroundColor DarkGray
    }

    $global:ChezmoiUnmanagedCache = @()
    $global:ChezmoiStatusCache = $null
}

# -- Custom Prompt -----------------------------------------------------
$global:ChezmoiCheck = $true

function Enable-ChezmoiCheck {
    $global:ChezmoiCheck = $true; Write-Host "Chezmoi check ON" 
}
function Disable-ChezmoiCheck {
    $global:ChezmoiCheck = $false; Write-Host "Chezmoi check OFF" 
}

function prompt {
    $lastSuccess = $?

    try {
        $user = $env:USERNAME
        $host_name = $env:COMPUTERNAME
        $path = $executionContext.SessionState.Path.CurrentLocation.Path
        $path = $path -replace '\\', '/'

        # Collect any finished chezmoi background results (instant)
        Receive-PromptBgCheck

        Write-Host ""
        Write-Host "" -NoNewline -ForegroundColor White
        Write-Host "$user" -NoNewline -ForegroundColor Cyan
        Write-Host "@" -NoNewline -ForegroundColor White
        Write-Host "$host_name" -NoNewline -ForegroundColor Magenta
        Write-Host " $path" -NoNewline -ForegroundColor Blue

        # Git -- synchronous (fast enough for most repos)
        $branch = git branch --show-current 2>$null
        if ($branch) {
            $dirty = git status --porcelain 2>$null
            $branchColor = if ($dirty) {
                "Yellow" 
            } else {
                "Green" 
            }
            Write-Host "  $branch" -NoNewline -ForegroundColor $branchColor
            if ($dirty) {
                Write-Host " X" -NoNewline -ForegroundColor Red
            }
        }

        # Chezmoi -- from background cache (zero cost)
        if ($global:ChezmoiCheck) {
            if ($global:ChezmoiStatusCache) {
                Write-Host " cmoi +/-" -NoNewline -ForegroundColor Yellow
            }
            if ($global:ChezmoiUnmanagedCache.Count -gt 0) {
                Write-Host " cmoiFolder +$($global:ChezmoiUnmanagedCache.Count)" -NoNewline -ForegroundColor Red
            }
        }

        Write-Host ""
        $promptColor = if ($lastSuccess) {
            "Green" 
        } else {
            "Red" 
        }
        Write-Host "-" -NoNewline -ForegroundColor White
        Write-Host ">" -NoNewline -ForegroundColor $promptColor

        # Fire off chezmoi background check for next prompt (non-blocking)
        Start-PromptBgCheck

        return " "
    } catch {
        return "-> "
    }
}

# zoxide config
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

