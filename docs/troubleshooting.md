# Troubleshooting

|Problem| Cause | Resolution| 


|Clients were unable to login through the active directory. | The DNS server was pointing to the external internet 8.8.8.8 where it could not see.| Set the DNS server to the DC01 IP address 172.16.0.1|

|Unable to ADD OU 'DEVELOPERS' access to network 'DEV_RESOURCES' network drive. | Oversight - did not configure a security group that could be added via share to grant read/write persmissions| Created Security Group Developers|

|