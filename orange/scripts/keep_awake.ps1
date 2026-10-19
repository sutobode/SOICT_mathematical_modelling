# Giữ máy không tự ngủ (Modern Standby) trong lúc chạy thực nghiệm dài, không đổi cài đặt nguồn của hệ thống:
# chỉ yêu cầu ES_SYSTEM_REQUIRED cho tới khi script này dừng. Không ngăn được việc gập nắp laptop nếu "lid close action"
# là Sleep; khi đó hãy cắm sạc, mở nắp, hoặc đổi "When I close the lid" thành "Do nothing" trong Power Options.
# Dừng bằng: Stop-Process -Id <PID của powershell chạy script này>.
param([double]$MaxHours = 48, [int]$IntervalSec = 30)
Add-Type -Namespace Native -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$flags = [uint32]2147483649    # ES_CONTINUOUS (0x80000000) | ES_SYSTEM_REQUIRED (0x00000001)
$end = (Get-Date).AddHours($MaxHours)
"[{0}] keep_awake started" -f (Get-Date -Format s) | Add-Content "$PSScriptRoot\..\results\keep_awake.log"
while ((Get-Date) -lt $end) {
    [void][Native.Power]::SetThreadExecutionState($flags)
    Start-Sleep -Seconds $IntervalSec
}
[void][Native.Power]::SetThreadExecutionState([uint32]2147483648)   # ES_CONTINUOUS: bỏ yêu cầu
