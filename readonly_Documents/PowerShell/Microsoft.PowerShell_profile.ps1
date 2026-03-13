Set-Alias -Name ll -Value Get-ChildItem -Force

if (Get-Command lazygit.exe -ErrorAction SilentlyContinue) {
    Set-Alias -Name lg -Value lazygit 
}

if (Get-Command chezmoi.exe -ErrorAction SilentlyContinue) {
    Set-Alias -Name cmoi -Value chezmoi -Force
    function chezcd {
        if (-not (Test-Path -Path $env:HOMEPATH\.local\share\chezmoi) ) { 
           return
        }
        else {
           Set-Location $env:HOMEPATH\.local\share\chezmoi
        }
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
            $branchColor = if ($dirty) { "Yellow" } else { "Green" }
            Write-Host "  $branch" -NoNewline -ForegroundColor $branchColor
        }

        # Chezmoi status — only when toggled on
        if ($global:ChezmoiCheck) {
            $czStatus = chezmoi status 2>$null
            if ($czStatus) {
                Write-Host " 🏠±" -NoNewline -ForegroundColor Yellow
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
