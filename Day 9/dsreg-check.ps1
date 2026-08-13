$out = dsregcmd /status
$out | Select-String -Pattern 'AzureAdJoined|DomainJoined|DeviceId|TenantId' | ForEach-Object { $_.Line }
