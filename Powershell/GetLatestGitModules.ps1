cd $(System.DefaultWorkingDirectory)\Path\To\GitModule\Hash
ls
git -c http.https://example.visualstudio.com.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" pull origin master