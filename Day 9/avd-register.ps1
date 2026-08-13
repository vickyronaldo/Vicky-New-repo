param([string]$RegistrationToken)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Write-Output 'START_AVD_REG'
$work='C:\Temp\avd'
New-Item -ItemType Directory -Path $work -Force | Out-Null
Set-Location $work
$u1='https://go.microsoft.com/fwlink/?linkid=2310011'
$u2='https://go.microsoft.com/fwlink/?linkid=2311028'
$f1='AVD-Agent.msi'
$f2='AVD-BootLoader.msi'
Invoke-WebRequest -Uri $u1 -UseBasicParsing -OutFile $f1
Invoke-WebRequest -Uri $u2 -UseBasicParsing -OutFile $f2
Write-Output "DOWNLOADED=$f1,$f2"
$agentArgs = "/i `"$f1`" /quiet /norestart REGISTRATIONTOKEN=$RegistrationToken /l*v C:\Temp\avd\agent.log"
$bootArgs = "/i `"$f2`" /quiet /norestart /l*v C:\Temp\avd\boot.log"
$agent = Start-Process msiexec.exe -ArgumentList $agentArgs -Wait -PassThru
$boot = Start-Process msiexec.exe -ArgumentList $bootArgs -Wait -PassThru
Write-Output "AGENT_EXIT=$($agent.ExitCode)"
Write-Output "BOOT_EXIT=$($boot.ExitCode)"
Write-Output 'SERVICES:'
Get-Service RdAgent,RDAgentBootLoader -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType
