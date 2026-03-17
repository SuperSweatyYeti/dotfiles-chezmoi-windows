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

if (Get-Command chezmoi.exe -ErrorAction SilentlyContinue) {
    Set-Alias -Name cmoi -Value chezmoi -Force
    function cmoicd {
        if (-not (Test-Path -Path $env:HOMEPATH\.local\share\chezmoi) ) { 
           return
        }
        else {
           Set-Location $env:HOMEPATH\.local\share\chezmoi
        }
    }
    function cmoisync {
        $chezmoi = "$env:HOMEPATH\.local\share\chezmoi"
        if (-not (Test-Path -Path $chezmoi)) { 
           return
        }
        git -C $chezmoi add -A
        git -C $chezmoi commit -m "update $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git -C $chezmoi push --force
    }
}

# Use wsl ssh instead of windows ssh if wsl distro exists
function ssh {
    if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
        $wslSshCheck = wsl.exe which ssh 2>$null
        if ($wslSshCheck) {
            wsl.exe ssh @args
            return
        }
    }
    & ssh.exe @args
}

function cdy {
  param([string[]]$Args)

  if (-not (Get-Command yazi -ErrorAction SilentlyContinue)) {
    Write-Warning "cdy: 'yazi' not found in PATH."
    return
  }

  $tmp = [System.IO.Path]::GetTempFileName()
  # ensure yazi writes to a fresh file
  Remove-Item $tmp -ErrorAction SilentlyContinue

  $yaziArgs = @("--cwd-file", $tmp)
  if ($Args) { $yaziArgs += $Args }

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

# Accept inline history suggestion with Ctrl+Y
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function AcceptSuggestion

# Make prediction/suggestion text a more distinct color
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -Colors @{
  Command            = 'Cyan'
  InlinePrediction   = '#6c6c6c'  # dim grey → clearly distinct from typed text
}

# ── Chezmoi Unmanaged File Tracking ──────────────────────────────────
# Add folders you want to watch for new unmanaged files here.
# Use full paths (supports ~ expansion via $env:USERPROFILE).
$global:ChezmoiWatchedFolders = @(
    "$env:USERPROFILE\.config\nvim"
    "$env:USERPROFILE\.config\yazi"
    # Add more folders here:
    # "$env:USERPROFILE\.config\some-app"
)

function Get-ChezmoiUnmanaged {
    <#
    .SYNOPSIS
        Checks watched folders for files not tracked by chezmoi.
    .DESCRIPTION
        Iterates through $global:ChezmoiWatchedFolders and runs
        'chezmoi unmanaged' scoped to each one. Returns a list of
        unmanaged file paths, or an empty array if everything is tracked.
    .EXAMPLE
        Get-ChezmoiUnmanaged
        # Returns: @("~/.config/nvim/plugin/new-plugin.lua", ...)
    #>
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
            # chezmoi unmanaged returns paths relative to home dir
            $allUnmanaged += $result
        }
    }
    return $allUnmanaged
}

function cmoistatus {
    <#
    .SYNOPSIS
        Shows chezmoi status plus any unmanaged files in watched folders.
    .DESCRIPTION
        Runs 'chezmoi status' to show tracked file changes, then checks
        all $global:ChezmoiWatchedFolders for unmanaged files and lists them.
    .EXAMPLE
        cmoistatus
    #>
    if (-not (Get-Command chezmoi.exe -ErrorAction SilentlyContinue)) {
        Write-Warning "cmoistatus: chezmoi not found in PATH."
        return
    }

    # 1. Normal chezmoi status
    Write-Host "── Chezmoi Status ──" -ForegroundColor Cyan
    $czStatus = chezmoi status 2>$null
    if ($czStatus) {
        $czStatus | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "  (no changes)" -ForegroundColor DarkGray
    }

    Write-Host ""

    # 2. Unmanaged files in watched folders
    Write-Host "── Unmanaged Files in Watched Folders ──" -ForegroundColor Cyan
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
    <#
    .SYNOPSIS
        Re-adds tracked files and adds any unmanaged files in watched folders.
    .DESCRIPTION
        Runs 'chezmoi re-add' to update all already-tracked files, then finds
        unmanaged files in $global:ChezmoiWatchedFolders and runs 'chezmoi add'
        on each one to start tracking them.
    .EXAMPLE
        cmoireadd
    #>
    if (-not (Get-Command chezmoi.exe -ErrorAction SilentlyContinue)) {
        Write-Warning "cmoireadd: chezmoi not found in PATH."
        return
    }

    # 1. Normal chezmoi re-add
    Write-Host "── Re-adding tracked files ──" -ForegroundColor Cyan
    chezmoi re-add
    Write-Host "  Done." -ForegroundColor Green

    Write-Host ""

    # 2. Add unmanaged files from watched folders
    Write-Host "── Adding unmanaged files from watched folders ──" -ForegroundColor Cyan
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
                Write-Host "  ✗ $file (not found, skipping)" -ForegroundColor Yellow
            }
        }
        Write-Host ""
        Write-Host "  $added file(s) added to chezmoi." -ForegroundColor Green
    } else {
        Write-Host "  (no unmanaged files found)" -ForegroundColor DarkGray
    }
}

# Custom Prompt
$global:ChezmoiCheck = $true

function Enable-ChezmoiCheck { $global:ChezmoiCheck = $true; Write-Host "Chezmoi check ON" }
function Disable-ChezmoiCheck { $global:ChezmoiCheck = $false; Write-Host "Chezmoi check OFF" }

function prompt {
    # Capture success/failure FIRST before anything else resets it
    $lastSuccess = $?

    try {
        $user = $env:USERNAME
        $host_name = $env:COMPUTERNAME
        $path = $executionContext.SessionState.Path.CurrentLocation.Path
        $path = $path -replace '\\', '/'

        Write-Host ""
        Write-Host "╭╴" -NoNewline -ForegroundColor White
        Write-Host "$user" -NoNewline -ForegroundColor Cyan
        Write-Host "@" -NoNewline -ForegroundColor White
        Write-Host "$host_name" -NoNewline -ForegroundColor Magenta
        Write-Host " $path" -NoNewline -ForegroundColor Blue

        # Git branch
        $branch = git branch --show-current 2>$null
        if ($branch) {
            $dirty = git status --porcelain 2>$null
        }

        # Chezmoi status — only when toggled on
        if ($global:ChezmoiCheck) {
            $czStatus = chezmoi status 2>$null
            if ($czStatus) {
                Write-Host " 🏠±" -NoNewline -ForegroundColor Yellow
            }

            # Check watched folders for unmanaged files
            $unmanaged = Get-ChezmoiUnmanaged
            if ($unmanaged.Count -gt 0) {
                Write-Host " 📁+$($unmanaged.Count)" -NoNewline -ForegroundColor Red
            }
        }

        Write-Host ""
        $promptColor = if ($lastSuccess) { "Green" } else { "Red" }
        Write-Host "╰─ " -NoNewline -ForegroundColor White
        Write-Host "❯" -NoNewline -ForegroundColor $promptColor
        return " "
    }
    catch {
        return "╰─ ❯ "
    }
}
