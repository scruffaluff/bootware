# Taken from https://superuser.com/a/896408.
Function ShowFileExtensions() {
    Push-Location
    Set-Location HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
    Set-ItemProperty . HideFileExt "0"
    Pop-Location

    # Restart File Explorer sfor changes to take effect.
    Stop-Process -Force -ProcessName: Explorer
}
 
ShowFileExtensions
