# linkedserver_health_check
SQL Server's linked server and kerberos related T-SQL scripts to check what might be wrong with their configuration. First part of the file contains code to run on the original instance, the second part to run on the target server.

# Prerequisites (for sure not minimum)
1. xp_cmdshell enabled
2. powershell's ActiveDirecotry module installed
3. local admin account on the servers.
4. sysadmin account