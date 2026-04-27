--linkedserver_kerberos_problem_check_bundle_pack

--query variable
DECLARE @query VARCHAR(8000);

--BELOW QUERIES RUN ON THE SOURCE SERVER

--check engine service account and their spns
DECLARE @EngineServiceAccount VARCHAR(256);
SELECT @EngineServiceAccount = 
	SUBSTRING(service_account, CHARINDEX('\',service_account)+1,LEN(service_account)) --get login without domain name
FROM sys.dm_server_services 
WHERE 
	filename LIKE '%sqlservr.exe%'

SELECT 
	service_account AS 'Engine Service Account' --show account with domain name
FROM sys.dm_server_services 
WHERE 
	filename LIKE '%sqlservr.exe%'

--check spns
SET @query = 'setspn -l ' + @EngineServiceAccount;
EXEC xp_cmdshell @query;


--check kerberos delegation
SET @query = 'powershell "Import-Module ActiveDirectory; Get-ADUser '+@EngineServiceAccount+' -Properties TrustedForDelegation,TrustedToAuthForDelegation"'
EXEC xp_cmdshell @query;

--check service port 
SELECT 
    local_tcp_port
FROM sys.dm_exec_connections
WHERE session_id = @@SPID;


--is tcp\ip enabled?
DECLARE @tcpEnabled INT;
EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib\Tcp',
    N'Enabled',
    @tcpEnabled OUTPUT;
SELECT 
	'Is TCP\IP Enabled?',
@tcpEnabled AS '1 or 0';

--BELOW QUERIES RUN ON THE TARGET SERVER
SELECT auth_scheme 
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID;

SELECT ORIGINAL_LOGIN(), SUSER_SNAME();