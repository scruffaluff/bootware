# Configure Windows desktop.
#
# Most commands are taken from
# https://github.com/ChrisTitusTech/winutil/blob/main/winutil.ps1.

# Show hidden files in File Explorer.
If (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -ErrorAction SilentlyContinue) {
    Set-ItemProperty `
        -Name 'HideFileExt' `
        -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' `
        -Type DWord `
        -Value 0
    Stop-Process -Force -ProcessName Explorer
}

# Disable beep sounds on errors after next restart.
#
# Beep service cannot be stopped directly.
Set-Service -Name Beep -StartupType Disabled

# Remove news and interests from task bar.
If (Get-ItemProperty 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' -ErrorAction SilentlyContinue) {
    Set-ItemProperty `
        -Name 'EnableFeeds' `
        -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' `
        -Type DWord `
        -Value 0
}
If (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds' -ErrorAction SilentlyContinue) {
    Set-ItemProperty `
        -Name 'ShellFeedsTaskbarViewMode' `
        -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds' `
        -Type DWord `
        -Value 2
}
