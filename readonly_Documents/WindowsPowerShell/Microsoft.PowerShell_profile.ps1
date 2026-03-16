Set-Alias -Name ll -Value Get-ChildItem -Force

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


# Custom Prompt
$global:ChezmoiCheck = $true

function Enable-ChezmoiCheck { $global:ChezmoiCheck = $true; Write-Host "Chezmoi check ON" }
function Disable-ChezmoiCheck { $global:ChezmoiCheck = $false; Write-Host "Chezmoi check OFF" }

function prompt {
    try {
        $user = $env:USERNAME
        $host_name = $env:COMPUTERNAME
        $path = $executionContext.SessionState.Path.CurrentLocation.Path
        $path = $path -replace '\\', '/'

        Write-Host ""
        Write-Host "$user" -NoNewline -ForegroundColor Cyan
        Write-Host "@" -NoNewline -ForegroundColor White
        Write-Host "$host_name" -NoNewline -ForegroundColor Magenta
        Write-Host " $path" -NoNewline -ForegroundColor Blue

        # Git branch
        $branch = git branch --show-current 2>$null
        if ($branch) {
            $dirty = git status --porcelain 2>$null
            $branchColor = if ($dirty) { "Yellow" } else { "Green" }
            Write-Host "  $branch" -NoNewline -ForegroundColor $branchColor
        }

        # Chezmoi status — only when toggled on
        if ($global:ChezmoiCheck) {
            $czStatus = chezmoi status 2>$null
            if ($czStatus) {
                Write-Host " chezmoi-diff" -NoNewline -ForegroundColor Yellow
            }
        }

        Write-Host ""
        return "-> "
    }
    catch {
        return "-> "
    }
}

