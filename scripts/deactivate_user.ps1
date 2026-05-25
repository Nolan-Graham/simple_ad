Import-Module ActiveDirectory

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CsvPath = [IO.Path]::GetFullPath((Join-Path $ScriptDir '..\assets\ssot.csv'))
$DomainDN = 'DC=mydomain,DC=com'
$DeactivatedOUName = 'deactivated'
$DeactivatedOUPath = "OU=$DeactivatedOUName,$DomainDN"

$EmployeeNumber = Read-Host 'Enter employee number'
if (-not $EmployeeNumber.Trim()) {
    Write-Host 'Employee number is required.' -ForegroundColor Red
    exit 1
}

$Users = Import-Csv -Path $CsvPath
$UserRecord = $Users | Where-Object { $_.EmployeeID -eq $EmployeeNumber }
if (-not $UserRecord) {
    Write-Host "No SSOT row matched employee number $EmployeeNumber." -ForegroundColor Red
    exit 1
}

$Username = $UserRecord.Username

$ConfirmMsg = "About to deactivate user '$Username' (employee $EmployeeNumber). This will remove the account from security groups, move it to OU='$DeactivatedOUName', and update SSOT status to Terminated. Continue?"
if (-not (Read-Host "$ConfirmMsg [Y/N]" | ForEach-Object { $_.Trim().ToUpper() } | Where-Object { $_ -in 'Y','YES' })) {
    Write-Host 'Aborted by user. No changes were made.' -ForegroundColor Yellow
    exit 0
}

try {
    $ADUser = Get-ADUser -Identity $Username -Properties DistinguishedName,MemberOf -ErrorAction Stop

    $DeactivatedOU = Get-ADOrganizationalUnit -Filter "Name -eq '$DeactivatedOUName'" -ErrorAction SilentlyContinue
    if (-not $DeactivatedOU) {
        New-ADOrganizationalUnit -Name $DeactivatedOUName -Path $DomainDN -ProtectedFromAccidentalDeletion $false -ErrorAction Stop
        Write-Host "Created OU: $DeactivatedOUPath" -ForegroundColor Green
    }

    $DirectGroups = @()
    if ($ADUser.MemberOf) {
        $DirectGroups = $ADUser.MemberOf | ForEach-Object { Get-ADGroup -Identity $_ -ErrorAction SilentlyContinue }
    }

    $AllGroups = Get-ADPrincipalGroupMembership -Identity $ADUser | Where-Object { $_.GroupCategory -eq 'Security' }
    $GroupsToRemove = ($DirectGroups + $AllGroups | Where-Object { $_ } | Sort-Object -Property DistinguishedName -Unique)

    if ($GroupsToRemove.Count -gt 0) {
        foreach ($Group in $GroupsToRemove) {
            try {
                Remove-ADGroupMember -Identity $Group -Members $ADUser.SamAccountName -Confirm:$false -ErrorAction Stop
                Write-Host "Removed $Username from group $($Group.Name)" -ForegroundColor Yellow
            } catch {
                Write-Host "Could not remove $Username from $($Group.Name): $_" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "$Username is not a member of any security groups." -ForegroundColor Cyan
    }

    if ($ADUser.DistinguishedName -notlike "*$DeactivatedOUName,$DomainDN") {
        Move-ADObject -Identity $ADUser.DistinguishedName -TargetPath $DeactivatedOUPath -ErrorAction Stop
        Write-Host "Moved $Username to $DeactivatedOUPath" -ForegroundColor Green
    } else {
        Write-Host "$Username is already in $DeactivatedOUPath" -ForegroundColor Cyan
    }

    $Updated = $false
    foreach ($row in $Users) {
        if ($row.EmployeeID -eq $EmployeeNumber) {
            $row.Status = 'Terminated'
            $Updated = $true
        }
    }

    if ($Updated) {
        $Users | Export-Csv -Path $CsvPath -NoTypeInformation
        Write-Host "Updated SSOT status to Terminated for employee $EmployeeNumber." -ForegroundColor Green
    } else {
        Write-Host "No SSOT records updated for employee $EmployeeNumber." -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
