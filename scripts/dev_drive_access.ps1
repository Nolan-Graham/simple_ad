# Requires -Modules ActiveDirectory
Import-Module ActiveDirectory

# --- CONFIG ---
$CSVPath = "C:\Temp\employees.csv"  # Update to your CSV location
$TargetGroup = "DEV_DRIVE_ACCESS"   # Security group to add devs to
$DeveloperDept = "DEVELOPER"        # Department value in CSV

# --- VALIDATION ---
if (-not (Test-Path $CSVPath)) {
    Write-Error "CSV not found at $CSVPath"
    exit 1
}

if (-not (Get-ADGroup $TargetGroup -ErrorAction SilentlyContinue)) {
    Write-Error "Security group '$TargetGroup' not found in AD. Create it first."
    exit 1
}

$Users = Import-Csv $CSVPath
$Devs = $Users | Where-Object { $_.Department -eq $DeveloperDept }

Write-Host "Found $($Devs.Count) developers in CSV" -ForegroundColor Yellow

$Added = 0
$AlreadyMember = 0
$NotFound = 0
$Errors = 0

foreach ($Dev in $Devs) {
    try {
        # Check if AD user exists
        $ADUser = Get-ADUser -Identity $Dev.Username -ErrorAction Stop
        
        # Check if already a member to avoid errors
        $IsMember = Get-ADGroupMember -Identity $TargetGroup | Where-Object { $_.SamAccountName -eq $Dev.Username }
        
        if ($IsMember) {
            Write-Host "SKIP: $($Dev.Username) already in $TargetGroup" -ForegroundColor DarkGray
            $AlreadyMember++
        } else {
            Add-ADGroupMember -Identity $TargetGroup -Members $ADUser
            Write-Host "ADDED: $($Dev.Username) to $TargetGroup" -ForegroundColor Green
            $Added++
        }
        
    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Warning "NOT FOUND: AD user $($Dev.Username) does not exist yet"
        $NotFound++
    } catch {
        Write-Error "ERROR for $($Dev.Username): $($_.Exception.Message)"
        $Errors++
    }
}

Write-Host "`n--- SUMMARY ---" -ForegroundColor Yellow
Write-Host "Developers in CSV: $($Devs.Count)"
Write-Host "Added to group:    $Added"
Write-Host "Already members:   $AlreadyMember"
Write-Host "AD user not found: $NotFound"
Write-Host "Other errors:      $Errors"