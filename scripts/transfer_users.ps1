Import-Module ActiveDirectory

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SsotPath = [IO.Path]::GetFullPath((Join-Path $ScriptDir '..\assets\ssot.csv'))
$MapPath = [IO.Path]::GetFullPath((Join-Path $ScriptDir '..\assets\department_mapping.csv'))

$EmployeeNumber = Read-Host 'Enter employee number (EmployeeID)'
if (-not $EmployeeNumber.Trim()) {
    Write-Host 'Employee number is required.' -ForegroundColor Red
    exit 1
}

$Users = Import-Csv -Path $SsotPath
$UserRecord = $Users | Where-Object { $_.EmployeeID -eq $EmployeeNumber }
if (-not $UserRecord) {
    Write-Host "No SSOT row matched employee number $EmployeeNumber." -ForegroundColor Red
    exit 1
}

$Username = $UserRecord.Username
Write-Host "Found user: $($UserRecord.DisplayName) ($Username) - Current Department: $($UserRecord.Department)"

$Mappings = Import-Csv -Path $MapPath
Write-Host "`nAvailable departments and codes:"
$Mappings | ForEach-Object { Write-Host ("Code: {0}  Dept: {1}  OU: {2}  SG: {3}" -f $_.Code, $_.Department, $_.OU, $_.SecurityGroup) }

$TargetCode = Read-Host 'Enter target department Code (e.g. 101)'
$Target = $Mappings | Where-Object { $_.Code -eq $TargetCode }
if (-not $Target) {
    Write-Host "No mapping found for code $TargetCode." -ForegroundColor Red
    exit 1
}

$TargetDept = $Target.Department
$TargetOU = $Target.OU
$TargetGroup = $Target.SecurityGroup

$ConfirmMsg = "About to transfer '$($UserRecord.DisplayName)' ($Username) to department $TargetDept`nOU: $TargetOU`nSecurityGroup: $TargetGroup`nContinue?"
$resp = Read-Host "$ConfirmMsg [Y/N]"
if (($resp.Trim().ToUpper()) -notin @('Y','YES')) {
    Write-Host 'Aborted by user. No changes made.' -ForegroundColor Yellow
    exit 0
}

try {
    $ADUser = Get-ADUser -Identity $Username -Properties DistinguishedName,MemberOf,SamAccountName -ErrorAction Stop

    if ($TargetOU -and ($ADUser.DistinguishedName -notlike "*$TargetOU*")) {
        Move-ADObject -Identity $ADUser.DistinguishedName -TargetPath $TargetOU -ErrorAction Stop
        Write-Host "Moved $Username to $TargetOU" -ForegroundColor Green
    } else {
        Write-Host "$Username is already in $TargetOU" -ForegroundColor Cyan
    }

    if ($TargetGroup -and $TargetGroup.Trim()) {
        $Group = Get-ADGroup -Identity $TargetGroup -ErrorAction SilentlyContinue
        if ($Group) {
            $IsMember = Get-ADGroupMember -Identity $Group -Recursive | Where-Object { $_.SamAccountName -eq $Username }
            if (-not $IsMember) {
                Add-ADGroupMember -Identity $Group -Members $Username -ErrorAction Stop
                Write-Host "Added $Username to group $($Group.Name)" -ForegroundColor Green
            } else {
                Write-Host "$Username already in $($Group.Name)" -ForegroundColor Cyan
            }
        } else {
            Write-Host "Target group '$TargetGroup' not found. Skipping group add." -ForegroundColor Yellow
        }
    }

    # Remove from other department-specific groups listed in mapping (except target)
    $OtherGroups = $Mappings | Where-Object { $_.SecurityGroup -and ($_.SecurityGroup -ne $TargetGroup) } | Select-Object -ExpandProperty SecurityGroup -Unique
    foreach ($gname in $OtherGroups) {
        $g = Get-ADGroup -Identity $gname -ErrorAction SilentlyContinue
        if ($g) {
            $isMember = Get-ADGroupMember -Identity $g -Recursive | Where-Object { $_.SamAccountName -eq $Username }
            if ($isMember) {
                Remove-ADGroupMember -Identity $g -Members $Username -Confirm:$false -ErrorAction Stop
                Write-Host "Removed $Username from $($g.Name)" -ForegroundColor Yellow
            }
        }
    }

    Write-Host "Transfer complete for $($UserRecord.DisplayName) ($Username) to $TargetDept." -ForegroundColor Green
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
