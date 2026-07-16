cd /d "%~dp0"
git pull
start "" "..\fx-artifacts\FXServer.exe" +exec config/dev/variables.cfg +set onesync on +set sv_enforceGameBuild 3095
