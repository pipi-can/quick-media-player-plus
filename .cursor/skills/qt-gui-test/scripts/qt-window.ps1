param(
    [ValidateSet("list", "screenshot", "click", "move")]
    [string]$Action = "screenshot",
    [string]$Title = "QMediaPlayer",
    [int]$X = 0,
    [int]$Y = 0,
    [string]$Out = ""
)

$ErrorActionPreference = "Stop"

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class QtWin {
    public delegate bool EnumProc(IntPtr h, IntPtr l);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, UIntPtr e);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint f);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    public const uint LEFTDOWN = 0x0002;
    public const uint LEFTUP = 0x0004;
}
public struct RECT { public int Left, Top, Right, Bottom; }
public struct POINT { public int X, Y; }
"@

function Get-WindowsByTitle([string]$part) {
    $found = New-Object System.Collections.Generic.List[Object]
    $cb = [QtWin+EnumProc]{
        param([IntPtr]$h, [IntPtr]$l)
        if (-not [QtWin]::IsWindowVisible($h)) { return $true }
        $sb = New-Object System.Text.StringBuilder 512
        [void][QtWin]::GetWindowText($h, $sb, $sb.Capacity)
        $t = $sb.ToString()
        if ($t.Length -gt 0) {
            $script:all += [pscustomobject]@{ Handle = $h; Title = $t }
        }
        return $true
    }
    $script:all = @()
    [void][QtWin]::EnumWindows($cb, [IntPtr]::Zero)
    if ([string]::IsNullOrWhiteSpace($part)) { return $script:all }
    return @($script:all | Where-Object { $_.Title -like "*$part*" })
}

function Resolve-Target {
    $wins = Get-WindowsByTitle $Title
    if ($wins.Count -eq 0) {
        throw "找不到标题含 '$Title' 的可见窗口。先 -Action list。"
    }
    return $wins[0]
}

function Move-Client([IntPtr]$h, [int]$cx, [int]$cy) {
    $p = New-Object POINT
    $p.X = $cx
    $p.Y = $cy
    [void][QtWin]::ClientToScreen($h, [ref]$p)
    [void][QtWin]::SetCursorPos($p.X, $p.Y)
    return $p
}

switch ($Action) {
    "list" {
        Get-WindowsByTitle "" | ForEach-Object { $_.Title }
    }
    "screenshot" {
        $w = Resolve-Target
        [void][QtWin]::ShowWindow($w.Handle, 9)
        [void][QtWin]::SetForegroundWindow($w.Handle)
        Start-Sleep -Milliseconds 200
        $r = New-Object RECT
        [void][QtWin]::GetWindowRect($w.Handle, [ref]$r)
        $width = [Math]::Max(1, $r.Right - $r.Left)
        $height = [Math]::Max(1, $r.Bottom - $r.Top)
        Add-Type -AssemblyName System.Drawing
        $bmp = New-Object System.Drawing.Bitmap $width, $height
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $hdc = $g.GetHdc()
        $ok = [QtWin]::PrintWindow($w.Handle, $hdc, 2)
        $g.ReleaseHdc($hdc)
        if (-not $ok) {
            $g.CopyFromScreen($r.Left, $r.Top, 0, 0, (New-Object System.Drawing.Size $width, $height))
        }
        $g.Dispose()
        if ([string]::IsNullOrWhiteSpace($Out)) {
            $Out = Join-Path $env:TEMP ("qt-win-" + [DateTime]::Now.ToString("yyyyMMdd-HHmmss") + ".png")
        }
        $bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        Write-Output $Out
    }
    "click" {
        $w = Resolve-Target
        [void][QtWin]::ShowWindow($w.Handle, 9)
        [void][QtWin]::SetForegroundWindow($w.Handle)
        Start-Sleep -Milliseconds 150
        Move-Client $w.Handle $X $Y | Out-Null
        Start-Sleep -Milliseconds 40
        [QtWin]::mouse_event([QtWin]::LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
        [QtWin]::mouse_event([QtWin]::LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
        Write-Output "clicked $($w.Title) at client $X,$Y"
    }
    "move" {
        $w = Resolve-Target
        [void][QtWin]::ShowWindow($w.Handle, 9)
        [void][QtWin]::SetForegroundWindow($w.Handle)
        $p = Move-Client $w.Handle $X $Y
        Write-Output "moved to screen $($p.X),$($p.Y)"
    }
}
