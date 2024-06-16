if ($env:OS -ne 'Windows_NT'){
    Write-Host "Installation skipped: platform is not Windows ( ˘︹˘ ) - $env:OS"
    return
}

if((([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -notcontains "S-1-5-32-544")){
    Write-Host "Installation skipped: shell user is not an Administrator (╯°□°）╯︵ ┻━┻))"
    return
}

#--------
Write-Host -ForegroundColor White -BackgroundColor Blue 'Platform: Windows'
Write-Host ''
#--------

#--------
Write-Host -ForegroundColor black -BackgroundColor White 'installing PowerShell ⚡'

winget install --id Microsoft.Powershell --source winget

Write-Host -ForegroundColor black -BackgroundColor Green 'PowerShell installed ⚡'
Write-Host -ForegroundColor Black -BackgroundColor Gray 'NOTE: Remember change your default terminal shell to PowerShell'
Write-Host ''
#--------


#--------
Write-Host -ForegroundColor Black -BackgroundColor White 'installing Nerd Fonts 🔠'

Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/amnweb/nf-installer/main/install.ps1'))

Write-Host -ForegroundColor Black -BackgroundColor Green 'Nerd Fonts installed 🔠'
Write-Host -ForegroundColor Black -BackgroundColor Gray 'NOTE: Remember to change your default terminal font'
Write-Host ''
#--------


#--------
Write-Host -ForegroundColor Black -BackgroundColor White 'installing Chocolatey (package manager) 🍫'

$executionPolicy = Get-ExecutionPolicy
if($executionPolicy -eq 'Restricted'){
    Set-ExecutionPolicy AllSigned
}
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

Write-Host -ForegroundColor Black -BackgroundColor Green 'Chocolatey installed 🍫'
#--------


#--------
Write-Host -ForegroundColor Black -BackgroundColor White 'installing NeoVim 💲'
choco feature enable -n allowGlobalConfirmation
choco install neovim

Write-Host -ForegroundColor Black -BackgroundColor White 'installing NeoVim dependencies 💲'
choco install make
choco install ripgrep
choco install fd
choco install unzip
choco install zig

# needed for lazygit integration
choco install lazygit

Write-Host -ForegroundColor Black -BackgroundColor Green 'NeoVim installed 💲'
#--------



#--------
Write-Host -ForegroundColor Black -BackgroundColor White 'Copying NeoVim config 💅'

remove-item $env:LOCALAPPDATA/nvim -Recurse
$nvimPath = Resolve-Path -Path "../common/nvim"
New-Item -ItemType Junction -Path $env:LOCALAPPDATA -name nvim -Value $nvimPath

Write-Host -ForegroundColor Black -BackgroundColor Green 'NeoVim config copied 💅'
Write-Host -ForegroundColor Black -BackgroundColor White 'if you get ""Failed to connect to github.com port 443: connection timeout" run one the following:'
Write-Host -ForegroundColor Black -BackgroundColor White 'git config --global --unset https.proxy'
Write-Host -ForegroundColor Black -BackgroundColor White 'ipconfig /renew'
Write-Host -ForegroundColor Black -BackgroundColor White 'or visit: https://docs.github.com/en/authentication/troubleshooting-ssh/using-ssh-over-the-https-port'
#--------