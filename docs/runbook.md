# Runbook

## Resource Inventory

- Home LAN > Router with Default Gateway to public internet
- ThinkCentre m910q (12GB RAM, intel) Intel(R) Core(TM) i5-6500T CPU @ 2.50GHz (2.50 GHz)
- Virtual Box VM
- WINDOWS SERVER 2022 ISO
- WINDOWS 11 ENTERPRISE ISO
- 

## Initial System Setup
- Ensure that Visual C++ requirements for Virtialbox are installed avaiable at [https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170]
- Install Virtualbox [https://www.virtualbox.org/wiki/Downloads]
- Install the Virtualbox Extension pack
- Install Windows Server 2022 ISO, available at [https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022?msockid=36524841bdb86d412e5b5f1cbc506cf2]
- Install Windows 11 Enterprise Edition, available at [https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise?msockid=36524841bdb86d412e5b5f1cbc506cf2]

## Virual Machine Configuration

#### Domain Contoller

VM NAME: DC01
VM FOLDER: .\Virtualbox VMs (default)
ISO Image: WINDOWS SERVER 2022
Username: domain_contoller
PW: *admins discretion, stored in organiztions password vault and password management software*
Product Key: *Add product key corresponding with license*
HOSTNAME: DC01

### dns




### Security Groups
- DEV_DRIVE_ACCESS  
- PEOPLEOPS_DRIVE_ACCESS

### Network Drives
- Generate two resource folders
-  Folder for dev resources on the C: drive of DC01
-  Folder for peopleops resources on C: drive of DC01

### Group Polices

**DEVELOPERS** > Configured to 'DEVELOPERS OU' AND 'USERS' OU
- Deferred Updates (14 days)
- Password Policies
  - Enforce Password history (10)
  - Maximum Password Age (60 days0)
  - Minimum Password Age  (15 days)
  - Miniumum Password Length (10 Characters)
  - Password Complexity Requirments (ENABLED)
- Control Panel Access Disabled

**DEV_DRIVE_ACCESS** configured to 'DEVELOPERS' OU

- Drive Mapping > C:\SHARE\DEV_RESOURCES

**PEOPLEOPS_DRIVE_ACCESS** configured to 'PEOPLE_OPS' OU 

- Drive Mapping > C:\SHARE\PEOPLEOPS_RESOURCES

