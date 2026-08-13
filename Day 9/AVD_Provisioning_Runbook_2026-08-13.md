# Azure Virtual Desktop Provisioning Runbook (FinBridge)

Date: 2026-08-13
Engineer context: DWP engineer with Azure CLI access

## Scope
This runbook captures the exact provisioning and validation flow executed for Azure Virtual Desktop in subscription `6639d04c-e224-4ac7-818e-9908781a2305` and resource group `dwp-lab-rg`.

Environment:
- Region: Central US
- Tenant: zippyops.in
- Target host pool: POOL-FIN-01
- Target workspace: FinBridge-Workspace
- Target session host VM: shfin01
- User access target: p28@zippyops.in

## 1) Pre-check: signed-in identity and RBAC
Verified active account and role assignments before any changes.

Commands used:
```powershell
az account show --query "{user:user.name,userType:user.type,tenantId:tenantId,subscription:id,subscriptionName:name}" -o json

$sub='6639d04c-e224-4ac7-818e-9908781a2305'
$rg='dwp-lab-rg'
$objId=az ad signed-in-user show --query id -o tsv
az role assignment list --assignee-object-id $objId --scope "/subscriptions/$sub" --include-inherited --query "[].{role:roleDefinitionName,scope:scope}" -o table
az role assignment list --assignee-object-id $objId --scope "/subscriptions/$sub/resourceGroups/$rg" --include-inherited --query "[].{role:roleDefinitionName,scope:scope}" -o table
```

Outcome:
- Signed-in user had `Owner` role at subscription scope (sufficient to create role assignments).

## 2) Validate CLI and platform prerequisites
Commands used:
```powershell
az config set extension.use_dynamic_install=yes_without_prompt
az config set extension.dynamic_install_allow_preview=true
az extension add --name desktopvirtualization --allow-preview true --upgrade
az extension show --name desktopvirtualization --query "{name:name,version:version}" -o json

az provider show --namespace Microsoft.DesktopVirtualization --query registrationState -o tsv
az vm image list --location centralus --publisher MicrosoftWindowsDesktop --offer windows-11 --all --query "[?contains(sku, 'avd')].{sku:sku,urn:urn}" -o table
```

Outcome:
- `desktopvirtualization` extension installed and available.
- `Microsoft.DesktopVirtualization` provider registered.
- Windows 11 AVD images confirmed in Central US.

## 3) Validate core AVD resources
Commands used:
```powershell
az desktopvirtualization hostpool show -g dwp-lab-rg -n POOL-FIN-01 --query "{name:name,type:hostPoolType,loadBalancerType:loadBalancerType,maxSessionLimit:maxSessionLimit,preferredAppGroupType:preferredAppGroupType}" -o json

az desktopvirtualization applicationgroup show -g dwp-lab-rg -n DAG-POOL-FIN-01 --query "{name:name,applicationGroupType:applicationGroupType,hostPoolArmPath:hostPoolArmPath}" -o json

az desktopvirtualization workspace show -g dwp-lab-rg -n FinBridge-Workspace --query "{name:name,applicationGroupReferences:applicationGroupReferences}" -o json
```

Outcome:
- Host pool is `Pooled`, `BreadthFirst`, `maxSessionLimit=5`.
- Desktop application group exists and points to the host pool.
- Workspace contains the desktop app group reference.

## 4) Validate session host VM baseline
Commands used:
```powershell
az vm show -g dwp-lab-rg -n shfin01 --query "{name:name,size:hardwareProfile.vmSize,securityType:securityProfile.securityType,secureBoot:securityProfile.uefiSettings.secureBootEnabled,vTPM:securityProfile.uefiSettings.vTpmEnabled,imageRef:storageProfile.imageReference}" -o json

az vm extension list -g dwp-lab-rg --vm-name shfin01 --query "[].{name:name,publisher:publisher,provisioningState:provisioningState}" -o table
```

Outcome:
- VM size: `Standard_B2ms`
- Security type: `TrustedLaunch`
- Secure Boot: `true`
- vTPM: `true`
- Image: Windows 11 AVD multi-session SKU
- Entra sign-in extension present: `AADLoginForWindows`

## 5) Host registration diagnosis and fix
Initial check showed no session host objects registered in POOL-FIN-01.

### 5.1 Generate host pool registration token
```powershell
$exp=(Get-Date).ToUniversalTime().AddHours(8).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
az desktopvirtualization hostpool update -g dwp-lab-rg -n POOL-FIN-01 --registration-info expiration-time=$exp registration-token-operation=Update --query registrationInfo -o json

$token = az desktopvirtualization hostpool retrieve-registration-token -g dwp-lab-rg -n POOL-FIN-01 --query token -o tsv
```

### 5.2 Register VM with AVD agent installers
Used script: `Day 9/avd-register.ps1`

Script purpose:
- Downloads AVD Agent and Boot Loader from official Microsoft fwlinks.
- Installs both MSIs silently.
- Passes `REGISTRATIONTOKEN` to agent installer.
- Emits exit codes and service status.

Execution pattern:
```powershell
$token = az desktopvirtualization hostpool retrieve-registration-token -g dwp-lab-rg -n POOL-FIN-01 --query token -o tsv
az vm run-command invoke -g dwp-lab-rg -n shfin01 --command-id RunPowerShellScript --scripts @"Day 9/avd-register.ps1" --parameters "RegistrationToken=$token" -o json
```

Observed outcome:
- `AGENT_EXIT=0`
- `BOOT_EXIT=0`
- Services running: `RdAgent`, `RDAgentBootLoader`

## 6) Verify Entra ID join-only state
Used script: `Day 9/dsreg-check.ps1`

Script purpose:
- Parses `dsregcmd /status` for join indicators.

Execution:
```powershell
az vm run-command invoke -g dwp-lab-rg -n shfin01 --command-id RunPowerShellScript --scripts @"Day 9/dsreg-check.ps1" -o json
```

Expected key output:
- `AzureAdJoined : YES`
- `DomainJoined : NO`

## 7) Assign user access roles (p28@zippyops.in)
Commands used:
```powershell
$uid = az ad user show --id p28@zippyops.in --query id -o tsv
$vmScope = az vm show -g dwp-lab-rg -n shfin01 --query id -o tsv
$agScope = '/subscriptions/6639d04c-e224-4ac7-818e-9908781a2305/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/applicationGroups/DAG-POOL-FIN-01'

az role assignment create --assignee-object-id $uid --assignee-principal-type User --role "Virtual Machine User Login" --scope $vmScope
az role assignment create --assignee-object-id $uid --assignee-principal-type User --role "Desktop Virtualization User" --scope $agScope
```

Validation:
```powershell
az role assignment list --assignee-object-id $uid --scope $vmScope --query "[].{role:roleDefinitionName,scope:scope}" -o table
az role assignment list --assignee-object-id $uid --scope $agScope --query "[].{role:roleDefinitionName,scope:scope}" -o table
```

## 8) Final host health confirmation
Command used:
```powershell
$sub='6639d04c-e224-4ac7-818e-9908781a2305'
az rest --method get --url "https://management.azure.com/subscriptions/$sub/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts?api-version=2024-04-03" --query "value[].{name:name,status:properties.status,allowNewSession:properties.allowNewSession,sessions:properties.sessions,lastHeartBeat:properties.lastHeartBeat,agentVersion:properties.agentVersion,updateState:properties.updateState}" -o table
```

Final observed status:
- Name: `POOL-FIN-01/shfin01`
- Status: `Available`
- AllowNewSession: `True`
- Sessions: `0`
- UpdateState: `Succeeded`

## Scripts moved to Day 9
- `Day 9/avd-register.ps1`
- `Day 9/dsreg-check.ps1`

## Notes
- The AVD registration token is sensitive and time-bound. Do not store it in source files.
- If session host is not visible after install, check VM service state and MSI logs first before retrying install.
