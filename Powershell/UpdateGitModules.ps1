# Update the .gitmodules file

Set-Content -Path $(System.DefaultWorkingDirectory)\.gitmodules @"
[submodule "Example/Path/ToGitHash"]
     path = Example/Path/ToGitHash
     url = ../../_git/ReplacementPath
"@

Get-Content -Path $(System.DefaultWorkingDirectory)\.gitmodules

# submodule update using latest .gitmodules
git -c http.https://tunstallgroup.visualstudio.com.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" submodule update --init --force --recursive
