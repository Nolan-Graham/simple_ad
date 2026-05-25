Import-Module ActiveDirectory


$CsvPath = "assets\ssot.csv"  # in-real world scenarios I would not be keeping a a ssot on a public github - however in this case I am placing it here to it can be access with a relative path.
$DomainDN = "DC=mydomain,DC=com"


$Users = Import-Csv -Path $CsvPath #loads the csv

foreach ($User in $Users) {
    $Username = $User.Username
    $Dept = $User.Department.ToUpper()  # DEVELOPER or PEOPLEOPS
    $TargetOU = "OU=$Dept,$DomainDN"
    $TargetGroup = "$($Dept)_Users"

    # skip if Status is not Active
    if ($User.Status -ne "Active") {
        Write-Host "Skipping inactive user: $Username" -ForegroundColor Yellow
        continue
    }

    try {
        # 1. Get AD user object
        $ADUser = Get-ADUser -Identity $Username -ErrorAction Stop

        # 2. Move user to correct OU if not already there
        if ($ADUser.DistinguishedName -notlike "*$TargetOU") {
            Move-ADObject -Identity $ADUser.DistinguishedName -TargetPath $TargetOU
            Write-Host "Moved $Username to $TargetOU" -ForegroundColor Green
        } else {
            Write-Host "$Username already in $TargetOU" -ForegroundColor Cyan
        }

        # 3. Add user to department Users group if not already a member
        $Group = Get-ADGroup -Identity $TargetGroup -ErrorAction Stop
        $IsMember = Get-ADGroupMember -Identity $Group -Recursive | Where-Object {$_.SamAccountName -eq $Username}
        
        if (-not $IsMember) {
            Add-ADGroupMember -Identity $Group -Members $Username
            Write-Host "Added $Username to $TargetGroup" -ForegroundColor Green
        } else {
            Write-Host "$Username already member of $TargetGroup" -ForegroundColor Cyan
        }

    } catch {
        Write-Host "ERROR with $Username : $_" -ForegroundColor Red
    }
}

Write-Host "`nUser organization complete. No users added to Management groups." -ForegroundColor Magenta