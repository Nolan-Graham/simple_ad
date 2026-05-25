Import-Module ActiveDirectory

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SsotPath = [IO.Path]::GetFullPath((Join-Path $ScriptDir '..\assets\ssot.csv'))
$DomainDN = 'DC=mydomain,DC=com'
$DefaultPassword = 'TempPassword123!' # CHANGE THIS IN PRODUCTION

$Users = Import-Csv -Path $SsotPath
$NewUsers = $Users | Where-Object { $_.Status -eq 'New' }

if ($NewUsers.Count -eq 0) {
    Write-Host 'No users with status "New" found in SSOT.' -ForegroundColor Cyan
    exit 0
}

Write-Host "Found $($NewUsers.Count) user(s) with status 'New':" -ForegroundColor Yellow
$NewUsers | ForEach-Object { Write-Host "  - $($_.DisplayName) ($($_.Username)) - $($_.Department)" }
Write-Host ''

$Proceed = Read-Host 'Create onboarding profiles for these users? [Y/N]'
if (($Proceed.Trim().ToUpper()) -notin @('Y', 'YES')) {
    Write-Host 'Aborted by user. No changes made.' -ForegroundColor Yellow
    exit 0
}

foreach ($User in $NewUsers) {
    $Username = $User.Username
    $DisplayName = $User.DisplayName
    $Email = $User.Email
    $Dept = $User.Department.ToUpper()
    $TargetOU = "OU=$Dept,$DomainDN"
    $TargetGroup = "$($Dept)_Users"

    Write-Host "`nProcessing: $DisplayName ($Username)"

    try {
        # 1. Check if user already exists
        $ExistingUser = Get-ADUser -Identity $Username -ErrorAction SilentlyContinue
        if ($ExistingUser) {
            Write-Host "  User $Username already exists in AD. Skipping creation." -ForegroundColor Yellow
        } else {
            # 2. Create the user account
            New-ADUser `
                -SamAccountName $Username `
                -UserPrincipalName "$Username@mydomain.com" `
                -Name $DisplayName `
                -DisplayName $DisplayName `
                -EmailAddress $Email `
                -Path $TargetOU `
                -ChangePasswordAtLogon $true `
                -Enabled $true `
                -ErrorAction Stop

            # 3. Set default password
            Set-ADAccountPassword -Identity $Username -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $DefaultPassword -Force) -ErrorAction Stop
            Write-Host "  Created user account: $Username" -ForegroundColor Green
            Write-Host "  Set temporary password (user must change on first logon)" -ForegroundColor Green
        }

        # 4. Add user to department security group
        $Group = Get-ADGroup -Identity $TargetGroup -ErrorAction SilentlyContinue
        if ($Group) {
            $IsMember = Get-ADGroupMember -Identity $Group -Recursive | Where-Object { $_.SamAccountName -eq $Username }
            if (-not $IsMember) {
                Add-ADGroupMember -Identity $Group -Members $Username -ErrorAction Stop
                Write-Host "  Added $Username to group $TargetGroup" -ForegroundColor Green
            } else {
                Write-Host "  $Username already in group $TargetGroup" -ForegroundColor Cyan
            }
        } else {
            Write-Host "  WARNING: Group $TargetGroup not found. User not added to group." -ForegroundColor Yellow
        }

        # 5. Update SSOT status to Active
        foreach ($row in $Users) {
            if ($row.EmployeeID -eq $User.EmployeeID) {
                $row.Status = 'Active'
            }
        }
        Write-Host "  Marked status as Active in SSOT" -ForegroundColor Green

    } catch {
        Write-Host "  ERROR: $_" -ForegroundColor Red
    }
}

# 6. Write updated SSOT back to file
try {
    $Users | Export-Csv -Path $SsotPath -NoTypeInformation
    Write-Host "`nOnboarding complete. SSOT updated." -ForegroundColor Green
} catch {
    Write-Host "ERROR updating SSOT: $_" -ForegroundColor Red
    exit 1
}
