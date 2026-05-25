Import-Module ActiveDirectory

$DomainDN = "DC=mydomain,DC=com" # this might change in other lab scenarios
$Departments = @("DEVELOPER", "PEOPLEOPS")

foreach ($Dept in $Departments) {
    #create OU for each department
    $OUPath = "OU=$Dept,$DomainDN"
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$Dept'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Dept -Path $DomainDN -ProtectedFromAccidentalDeletion $true
        Write-Host "Created OU: $OUPath"
    } else {
        Write-Host "OU already exists: $OUPath"
    }

    #create Users security group in each OU
    $GroupName = "$($Dept)_Users"
    
    if (-not (Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue)) {
        New-ADGroup `
            -Name $GroupName `
            -SamAccountName $GroupName `
            -GroupCategory Security `
            -GroupScope Global `
            -DisplayName "$Dept Users" `
            -Path $OUPath `
            -Description "Security group for $Dept department users"
        Write-Host "Created Group: $GroupName in $OUPath"
    } else {
        Write-Host "Group already exists: $GroupName"
    }
}

Write-Host "`nDone. OUs and Users groups created for $DomainDN"