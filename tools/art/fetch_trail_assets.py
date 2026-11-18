"""Read the approved Legendary trail package in Studio Edit and export the Glass wake template.
Works on a detached Roblox model. Run from the repo root after the two upload operations finish.
"""
import base64
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "assets/models/trails"
ENV = dict(os.environ, PYTHONIOENCODING="utf-8", FULL="1", T="30")
def studio(tool, data=None):
    args = [sys.executable, str(ROOT/"tools/studio_cli.py"), tool]
    if data is not None:
        args.append(json.dumps(data))
    output = subprocess.check_output(args, env=ENV, cwd=ROOT, encoding="utf-8", timeout=80)
    return json.loads(output)

sessions = studio("list_roblox_studios")["studios"]
target = next(s for s in sessions if s["placeId"] == 132768925825316 and s["mode"] == "Edit")
model_id = int(json.loads((ART/"upload-legendary-pieces.json").read_text())["response"]["assetId"])
code = r"""
local model = game:GetService("InsertService"):LoadAsset(PACKAGE_ID)
local data = {parts={},stations={}}
local wake
for _,part in model:GetDescendants() do
    if part:IsA("MeshPart") then
        local s = part.Size
        data.parts[part.Name] = {mesh=part.MeshId, size={s.X,s.Y,s.Z}, basis={part.CFrame:GetComponents()}}
        if part.Name == "cloak_stream" then wake = part end
    end
end
assert(wake and #wake:GetChildren() < 20)
local editable = game:GetService("AssetService"):CreateEditableMeshAsync(Content.fromUri(wake.MeshId))
local indices = editable:GetBones()
assert(#indices == 13)
-- Roblox imports each independent FBX root under a separate RootPart. Its mesh
-- asset retains the original joint palette and weights, in the MeshPart's own frame.
wake.Parent = nil
wake:ClearAllChildren()
wake.Name = "CloakStream"
wake.PivotOffset = CFrame.identity
wake.CFrame = CFrame.identity
wake.Anchored = true
wake.CanCollide, wake.CanQuery, wake.CanTouch, wake.CastShadow = false, false, false, false
wake.Material, wake.Color, wake.Transparency = Enum.Material.Glass, Color3.fromRGB(226,239,250), 0.72
wake.DoubleSided = true
local influenced = {}
for _,v in editable:GetVertices() do
    local joints,weights = editable:GetVertexBones(v),editable:GetVertexBoneWeights(v)
    for i,joint in joints do
        if weights[i] > 0 then influenced[joint] = true end
    end
end
for _,index in indices do
    assert(editable:GetBoneParent(index) == 0 and influenced[index])
    local bone = Instance.new("Bone")
    bone.Name = editable:GetBoneName(index)
    local number = assert(tonumber(bone.Name:match("^wake_(%d+)$")))
    bone.CFrame = editable:GetBoneCFrame(index)
    bone:SetAttribute("WakeK",number/12)
    bone.Parent = wake
    data.stations[bone.Name] = {bone.CFrame:GetComponents()}
end
local bytes = game:GetService("SerializationService"):SerializeInstancesAsync({wake})
data.binary = buffer.tostring(game:GetService("EncodingService"):Base64Encode(bytes))
data.bytes = buffer.len(bytes)
wake:Destroy()
editable:Destroy()
model:Destroy()
return game:GetService("HttpService"):JSONEncode(data)
""".replace("PACKAGE_ID", str(model_id))
with tempfile.TemporaryDirectory() as temp:
    path = Path(temp)/"trail_package.luau"
    path.write_text(code, encoding="utf-8")
    result = studio("execute_luau", {"studio_id":target["id"],"datamodel_type":"Edit","code":str(path)})
binary = base64.b64decode(result.pop("binary"), validate=True)
assert len(binary) == result.pop("bytes") and binary.startswith(b"<roblox!")
assert len(result["stations"]) == 13 and len(result["parts"]) == 8
(ART/"cloak-stream.rbxm").write_bytes(binary)
(ART/"legendary-uploaded.json").write_text(json.dumps(result, indent=2, sort_keys=True)+"\n")
print("Read 8 mesh IDs and 13 weighted bind poses. Wrote", len(binary), "bytes for CloakStream.")
