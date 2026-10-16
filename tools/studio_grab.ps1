# Saves the main screen (2560x1080) to the given PNG path.
param([string]$out)
Add-Type -AssemblyName System.Drawing
$b = New-Object System.Drawing.Bitmap 2560, 1080
$g = [System.Drawing.Graphics]::FromImage($b)
$g.CopyFromScreen(0, 0, 0, 0, $b.Size)
$b.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
