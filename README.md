# Small Enterprise Infrastructure Lab

Enterprise-style Windows environment built in VirtualBox. Basic setup using GUI with limited ps1 scripting.

## Objectives
Mimic a small scale enterpise/office active directory using onsite ssot. 

- Deploy Active Directory
- Configure DNS + DHCP
- Enable NAT internet access
- Join client devices to domain
- Automate some simple administrative tasks

## Environment

Server:
- Windows Server 2022

Client:
- Windows 11 Enterprise

Services:
- AD DS
- DNS
- DHCP
- RRAS

## Architecture

[network-diagram.png]

### IP Adressing Architecture

Class B Network, subnetted into a CIDR /24 subnet. Class B allows for for most hosts to be added to the subnet if needed, as an example, with a subnet of 255.255.240.0. 

Class B Network - 65536 potential Hosts

DC01 Static IP: 172.16.0.1
Subnet Mask: 255.255.255.0/24
Usable Clients: 254



