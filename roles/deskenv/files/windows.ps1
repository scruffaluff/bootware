# Configure Windows desktop.
#
# Most commands are taken from
# https://github.com/ChrisTitusTech/winutil/blob/main/winutil.ps1.

# Show hidden files in File Explorer.
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Type DWord -Value 0
Stop-Process -Force -ProcessName: Explorer

# Remove news and interests from task bar.
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' -Name 'EnableFeeds' -Type DWord -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds' -Name 'ShellFeedsTaskbarViewMode' -Type DWord -Value 2
