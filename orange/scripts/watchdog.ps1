# Giám sát RAM: nếu RAM trống < MinFreeGB thì dừng tiến trình Julia ĐÃ CHẠY ÍT NHẤT (ít thời gian CPU nhất, để không mất công việc dài)\n# trong số các tiến trình dùng > 0.8 GB (trừ các PID trong ExcludeFile,
# ví dụ tiến trình Julia của IDE) để máy không bị treo. Ghi log vào LogFile. Dừng sau MaxHours giờ.
param(
    [string]$ExcludeFile = "$PSScriptRoot\..\results\watch_exclude.txt",
    [string]$LogFile = "$PSScriptRoot\..\results\watchdog.log",
    [double]$MinFreeGB = 1.5,
    [int]$IntervalSec = 15,
    [double]$MaxHours = 48
)
$end = (Get-Date).AddHours($MaxHours)
"[{0}] watchdog started (min free {1} GB, interval {2}s)" -f (Get-Date -Format s), $MinFreeGB, $IntervalSec | Add-Content $LogFile
while ((Get-Date) -lt $end) {
    $free = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
    if ($free -lt $MinFreeGB) {
        $exclude = @()
        if (Test-Path $ExcludeFile) { $exclude = @(Get-Content $ExcludeFile | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }) }
        $procs = @(Get-Process julia -ErrorAction SilentlyContinue | Where-Object { $exclude -notcontains $_.Id })
        if ($procs.Count -gt 0) {
            $big = @($procs | Where-Object { $_.WorkingSet64 -gt 0.8GB })
            if ($big.Count -eq 0) { $big = $procs }
            $victim = $big | Sort-Object CPU | Select-Object -First 1
            "[{0}] free {1:N2} GB < {2} GB: stopping julia PID {3} ({4:N2} GB)" -f (Get-Date -Format s), $free, $MinFreeGB, $victim.Id, ($victim.WorkingSet64 / 1GB) | Add-Content $LogFile
            Stop-Process -Id $victim.Id -Force
        }
    }
    Start-Sleep -Seconds $IntervalSec
}

