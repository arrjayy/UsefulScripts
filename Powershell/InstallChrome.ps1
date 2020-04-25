$Path = $env:TEMP;
$Installer = "chrome_installer.exe";
$ChromeVersion = 375.126;
Invoke-WebRequest "http://dl.google.com/chrome/install/$ChromeVersion/$Installer" -OutFile $Path\$Installer;
Start-Process -FilePath $Path\$Installer -Args "/silent /install" -Verb RunAs -Wait;
Remote-Item $Path\$Installer