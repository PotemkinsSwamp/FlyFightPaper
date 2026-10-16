# Prints the title of the topmost visible (not cloaked) large window on the main screen.
Add-Type @'
using System; using System.Text; using System.Runtime.InteropServices;
public class Z { public delegate bool CB(IntPtr h, IntPtr l);
[DllImport("user32.dll")] public static extern bool EnumWindows(CB cb, IntPtr l);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
[DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
[DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h, int a, out int v, int s);
[DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
public struct R { public int L, T, Rt, B; }
public static string Top() { string found = null;
  EnumWindows((h, l) => { if (!IsWindowVisible(h) || IsIconic(h)) return true; int cl; DwmGetWindowAttribute(h, 14, out cl, 4); if (cl != 0) return true; var sb = new StringBuilder(256); GetWindowText(h, sb, 256);
    R r; GetWindowRect(h, out r); if (sb.Length == 0) return true;
    if (r.L < 2500 && r.Rt > 100 && r.T < 1000 && r.B > 100 && (r.Rt - r.L) > 1000) { found = sb.ToString(); return false; } return true; }, IntPtr.Zero);
  return found; } }
'@
[Z]::Top()
