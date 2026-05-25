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
CORES: Min of 1 *for lab context, on real world implementations more cores would be needed*
RAM: 2048mb *for lab context, real world implementations would be more*
NIC1: NAT
NIC2: Interal Network  

## Windows Server 2022 Installation 

- For lab context use the WIN Server 2022 License Key 
- set local user to DC01

## VirtualBox Guest Additions Installations

- Ensure that 'Virtualbox Guest Additions' virtual CD it moutned to the vm
- Run the installation from file explorer, with defualt options selected.
- Restart the VM to ensure that drivers from the installation are working correctly.

## Initial Network Configurations

Control Panel > Network and Internet > Network Connections
NIC 1 > Rename to _INTERNET > Details> Confirm that it is receiving an IP address from home router. 
NIC 2 > Rename to INTERNAL > Properties > IPv4 Settings > Set IP address to 172.16.0.1, Subnet mask to 255.255.255.0, DNS Server to Loopback or 172.16.0.1
## Rename the System 

Settings > System > About > Rename > 'DC01'


## Domina Creation

Server Manager > Add Roles and Features > Active Directory Domains Services > Install

Perform Post Delployment Configuration > Promote DC01 to domain > add a new forest > labdomain.com (domain may change based on the context) > Install

## Creating Administration Account

Active Directory Users and Computers > labdomiain.com > Create OU called 'ADMINS' > Create New User (Nolan in my case) > create logon name which alligns for enterprise naming convention > Properties > Member Of> Add > Add to 'Domain Admins' 

Sign out of the default administrator and log into the personalized domain account (this isn't necessary for setu, but preferred)


### RAS/ NAT

Add roles and features > Remote Access > Ensure that 'Routing' is selected > Install

Server Manager > Tools > Routing and remote access > DC Local > Select NAT > select the interface that will be used to connect to the public internet, in thos lab context its '_INTERNET'

## DCHP Configuration 

Server Manager  > Add roles and Features > DHCP Server > Install

Tools > DHCP > labdomain.com >  IPv4 > New Scope > Give a name to the scrop (in this case I am just using the range of 172.16.0.100-200)

 Input IP Range: Start: 172.16.0.100, End: 172.16.0.200 > Input Subnet Mask: 255.255.255.0

Exclusions: NA

Lease: 8 days

Configure DHCP Options: Yes 

Routing Gateway: 172.16.0.1

DNS: 172.16.0.1 (configured with the active directory)

WINS: NA

Activate the scope> finish > Refresh the Server

Server Options > Router > Add the routing Ip address 172.16.0.1

## QoL

Turn off 'Internet Explorer Enahnced Security Configuration'

Turn off 

Set execution policies for scripts > Set-ExecutionPolicy Unrestricted (Ensure that this is done in an adminstrative console)

### Network Drives
- Generate two resource folders
-  Folder for dev resources on the C: drive of DC01
-  Folder for peopleops resources on C: drive of DC01


## Creating OUs and Security Groups
Run the `scripts\create_ou_sg.ps1` > For naming consistency when writing/running other ps1 scripts.


OUs: DEVELOPERS, PEOPLE OPS
SECURITY GROUPS: DEVELOPERS, PEOPLEOPS

### Initial User Provisioning

Run `scripts\create_initial_users.ps1`, this pulls user information from an ssot - in this case a csv file. Organizes those users into the respecrtive work groups and as well as security groups giving them access to shared resource drives.


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

## Client Creation

*as many clients can be created as needed within the lab environment, for this example only one is needed*

### Client VM Configuration
VM NAME: client1
VM FOLDER: .\Virtualbox VMs (default)
ISO Image: WINDOWS 11 Enterprise
Username: client1
PW: *admins discretion, stored in organiztions password vault and password management software*
Product Key: *Add product key corresponding with license*
HOSTNAME: client1
CORES: Min of 1 *for lab context, on real world implementations more cores would be needed*
RAM: 2048mb *for lab context, real world implementations would be more*
NIC1: Interal Network  *only one NIC on the client device which is connecting to the internal network. It will receieved routing to public internet through the NAT on DC01.*

### OS Configuration

Region: Canada
Keyboard: US English
Network Connection: No internet
Local Account Name: client1 *this option will change depending on the version, if a network account is required, use start ms-cxh:localonly* from shift+f10

### Client Network Configuration

Ensure that the client is recieving correct IP addressing from the domain server> ipconfig /all
Check that the client is receiving an ip adress within the 172.16.0.100-200 scope
Ping 8.8.8.8 to ensure that the client can reach the public internet. 

### System Configuration (Joining Active Directory)

Settings > System > Advanced System Settings > Rename: Client1 > join active directory > labdomain.com > login with an account with access

*When logging back into the account, it will go through some initial account setup* 

## User Lifecycle Management

### Onboarding

- **SSOT Update**: Add new hire record to `assets\ssot.csv` with `Status: New`
- **Script**: Run `scripts\new_onboarding.ps1` 
- **What it does**:
  - Audits SSOT for users with status "New"
  - Creates AD account using company naming convention from CSV
  - Sets temporary password (user changes on first logon)
  - Adds user to department-specific OU and security group
  - Updates SSOT status to "Active"
- **Reference**: Department-to-OU mapping defined in `scripts\create_ou_sg.ps1`

### Offboarding

- **Trigger**: Update user status to "Terminated" requirement or run script directly
- **Script**: Run `scripts\deactivate_user.ps1`
- **What it does**:
  - Prompts for employee number (references SSOT)
  - Removes user from all security groups
  - Moves account to `OU=deactivated` container
  - Updates SSOT status to "Terminated"
  - Requires confirmation before making changes

### Transfers / Department Changes

- **Script**: Run `scripts\transfer_users.ps1`
- **What it does**:
  - Prompts for employee number and target department code
  - References `assets\department_mapping.csv` for OU and security group mappings
  - Moves user to target OU
  - Adds to target security group, removes from other department groups
  - Provides confirmation message upon completion
- **Department Codes**: 101=DEVELOPER, 102=PEOPLEOPS (see `department_mapping.csv`)
