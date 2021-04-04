# Change desktop background image.
#
# Taken from https://stackoverflow.com/a/43188780.
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "C:\Users\$1\Pictures\background\$2" /f
Start-Sleep -s 10
rundll32.exe user32.dll, UpdatePerUserSystemParameters, 0, $false
