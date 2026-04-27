--linkedserver_kerberos_problem_check_bundle_pack

DECLARE @query VARCHAR(8000); --query variable

DECLARE @xp_cmdshell_enabled INT; --variable to check if xp_cmdshell is enabled
SELECT @xp_cmdshell_enabled =
CAST(value_in_use AS INT)
FROM sys.configurations
WHERE name = 'xp_cmdshell';

--BELOW QUERIES RUN ON THE SOURCE SERVER

--check your linked servers configuration
SELECT	server_id,
		name,
		product,
		provider,
		data_source,
		is_data_access_enabled, --must be 1
		is_remote_login_enabled AS 'is_RPC_enabled', --must be 1
		is_rpc_out_enabled --must be 1
FROM sys.servers 

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

--check spns for your engine account
SET @query = 'setspn -l ' + @EngineServiceAccount;
EXEC xp_cmdshell @query;

--check service port of your engine account
SELECT 
    local_tcp_port
FROM sys.dm_exec_connections
WHERE session_id = @@SPID;

--check kerberos delegation
SET @query = 'powershell "Import-Module ActiveDirectory; Get-ADUser '+@EngineServiceAccount+' -Properties TrustedForDelegation,TrustedToAuthForDelegation"'
EXEC xp_cmdshell @query;
PRINT ERROR_MESSAGE();

--is tcp\ip enabled?
DECLARE @tcpEnabled INT;
EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib\Tcp',
    N'Enabled',
    @tcpEnabled OUTPUT;
SELECT 
	'Is TCP\IP Enabled?',
    CASE
        WHEN @tcpEnabled = 1 THEN 'YES'
        WHEN @tcpEnabled = 0 THEN 'NO'
        ELSE 'IDK'
    END AS 'Answer'

--check DTC settings
--properly working for:
--AuthenticationLevel               : NoAuth
--InboundTransactionsEnabled        : True
--OutboundTransactionsEnabled       : True
--RemoteClientAccessEnabled         : True
--RemoteAdministrationAccessEnabled : True
--XATransactionsEnabled             : True
--LUTransactionsEnabled             : True
SET @query = 'powershell "Get-DtcNetworkSetting"'
EXEC xp_cmdshell @query;

--BELOW QUERIES RUN ON THE TARGET SERVER
SELECT auth_scheme 
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID;

SELECT ORIGINAL_LOGIN(), SUSER_SNAME();