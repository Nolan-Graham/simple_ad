# Requires -Modules ActiveDirectory
Import-Module ActiveDirectory

# --- CONFIG ---
$CSVPath = "scripts\create users"  #may change based on where the file is located
$DefaultPassword = ConvertTo-SecureString "Password1" -AsPlainText -Force
$DomainDN = "DC=mydomain.com"     # Change to your domain
$PathMap = @{
    "DEVELOPER"  = "OU=DEVELOPERS,$DomainDN"
    "PEOPLEOPS"  = "OU=PEOPLE_OPS,$DomainDN"
}
$GroupMap = @{
    "DEVELOPER"  = "DEVELOPERS"
    "PEOPLEOPS"  = "PEOPLE_OPS"
}

# --- SAFETY CHECK ---
if (-not (Test-Path $CSVPath)) {
    Write-Error "CSV not found at $CSVPath"
    exit 1
}

$Users = Import-Csv $CSVPath
$Created = 0
$Skipped = 0
$Errors = 0

foreach ($User in $Users) {
    try {
        # Skip if user already exists
        if (Get-ADUser -Filter "SamAccountName -eq '$($User.Username)'" -ErrorAction SilentlyContinue) {
            Write-Warning "User $($User.Username) already exists. Skipping."
            $Skipped++
            continue
        }

        $OUPath = $PathMap[$User.Department]
        $Group = $GroupMap[$User.Department]

        if (-not $OUPath -or -not $Group) {
            Write-Error "No OU/Group mapping for department: $($User.Department). Skipping $($User.Username)"
            $Errors++
            continue
        }

        # Create the user
        $NewUserParams = @{
            Name                = $User.DisplayName
            GivenName           = $User.FirstName
            Surname             = $User.LastName
            SamAccountName      = $User.Username
            UserPrincipalName   = $User.Email
            DisplayName         = $User.DisplayName
            EmployeeID          = $User.EmployeeID
            Department          = $User.Department
            Title               = $User.JobTitle
            Office              = $User.Office
            Path                = $OUPath
            AccountPassword     = $DefaultPassword
            Enabled             = $true
            ChangePasswordAtLogon = $true   # Force password change on first login
            Description         = "Created via bulk import $(Get-Date -Format yyyy-MM-dd)"
        }

        New-ADUser @NewUserParams
        Write-Host "Created: $($User.Username) in $OUPath" -ForegroundColor Green

        # Add to security group
        Add-ADGroupMember -Identity $Group -Members $User.Username
        Write-Host "Added $($User.Username) to group $Group" -ForegroundColor Cyan
        
        $Created++

    } catch {
        Write-Error "Failed for $($User.Username): $_"
        $Errors++
    }
}

Write-Host "`n--- SUMMARY ---" -ForegroundColor Yellow
Write-Host "Created: $Created"
Write-Host "Skipped: $Skipped" 
Write-Host "Errors:  $Errors"
Write-Host "`nIMPORTANT: Default password is 'Password1'. Users must change at next logon."
