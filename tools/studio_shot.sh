# Aim Studio's edit camera and grab the main screen, only if Studio is the top window there. usage: bash tools/studio_shot.sh NAME x,y,z lookx,looky,lookz  -> $TMP/shots/NAME.png
mkdir -p "$TMP/shots"
# usage: shoot.sh NAME cx,cy,cz lx,ly,lz
cd /d/FlyFightPaper
S=fd0dc60f-47bb-4bd5-8a5a-3fd5bdd5d4a9
printf 'workspace.CurrentCamera.CFrame = CFrame.lookAt(Vector3.new(%s), Vector3.new(%s))\nworkspace.CurrentCamera.FieldOfView = 70\nreturn "ok"' "$2" "$3" > $TMP/cam.lua
T=30 python tools/studio_cli.py execute_luau "{\"studio_id\":\"$S\",\"datamodel_type\":\"Edit\",\"code\":\"$(cygpath -m $TMP/cam.lua)\"}" > /dev/null
powershell -NoProfile -Command "Start-Sleep -Milliseconds 4000"
if ! powershell -NoProfile -File "$(cygpath -w tools/studio_top.ps1)" | grep -q "Roblox Studio"; then echo "$1 SKIPPED: Studio not on top"; exit 1; fi
powershell -NoProfile -File "$(cygpath -w tools/studio_grab.ps1)" "$(cygpath -w $TMP/shots/$1.png)"
echo "$1 done"
