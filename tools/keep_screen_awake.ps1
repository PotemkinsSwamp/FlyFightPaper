# Keeps the screen awake during a recording: one-pixel mouse nudge there and back every 20 s, for at most 8 minutes.
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Nudge {
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, int dx, int dy, uint d, UIntPtr e);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
}
"@
$studio = Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if ($studio) { "minimised=" + [Nudge]::IsIconic($studio.MainWindowHandle) } else { "minimised=unknown (no Studio window found)" }
if ($args[0] -eq "check") { exit }
$end = (Get-Date).AddMinutes(8)
while ((Get-Date) -lt $end) {
    [Nudge]::mouse_event(1, 1, 0, 0, [UIntPtr]::Zero)
    [Nudge]::mouse_event(1, -1, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Seconds 20
}
