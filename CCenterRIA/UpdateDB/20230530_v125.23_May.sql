/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 23
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci�n para cuando pasamos a una nueva versi�n LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	---------------------------------------BEGIN HUGO LONGORIA ---------------------------------------------------------
	set @process = 'KR06700 DROP ccTrunkConfiguration'
	set @sql = 'DECLARE 
    @SchemaName SYSNAME,
    @TableName  SYSNAME,
    @Sql        NVARCHAR(MAX);

SELECT
    @SchemaName = SCHEMA_NAME(t.schema_id),
    @TableName  = t.name
FROM sys.key_constraints kc
INNER JOIN sys.tables t
    ON t.object_id = kc.parent_object_id
WHERE kc.name = ''PK_ccTrunkConfiguration''
  AND kc.type = ''PK'';

IF @TableName IS NOT NULL
   AND @TableName <> ''ccTrunkConfiguration''
BEGIN
    SET @Sql =
        N''ALTER TABLE ''
        + QUOTENAME(@SchemaName)
        + N''.''
        + QUOTENAME(@TableName)
        + N'' DROP CONSTRAINT ''
        + QUOTENAME(''PK_ccTrunkConfiguration'')
        + N'';'';

    PRINT @Sql;
    EXEC sys.sp_executesql @Sql;
END
ELSE
BEGIN
    PRINT ''No se eliminó el constraint. No existe o pertenece a ccTrunkConfiguration.'';
END;'
    EXEC(@sql)

	set @process = 'KR06700 DROP ccTrunkConfiguration'
	set @sql = 'IF EXISTS (SELECT 1 
			FROM sys.tables WHERE name = ''ccTrunkConfiguration'') 
            BEGIN
                DROP TABLE [dbo].[ccTrunkConfiguration]
            END'
    EXEC(@sql)

	set @process = 'KR06700 CREATE ccTrunkConfiguration'
	set @sql = 'CREATE TABLE ccTrunkConfiguration (
			[TrunkId] int IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
			[description] varchar(50) NOT NULL,
			[domain] varchar(50) NOT NULL,
			[proxy] varchar(50) NULL,
			[user] varchar(50) NOT NULL,
			[authName] varchar(50) NULL,
			[encPassword] varchar(50) NULL,
			[realm] varchar(50) NULL,
			[ttl] smallint NOT NULL,
			[ipNatOut] varchar(50) NULL,
			[sipAgent] varchar(50) NULL,
			[fixedDomain] varchar(50) NULL,
			[allowReinvite] bit NULL,
			[options] tinyint NULL,
			[calloutHdr] varchar(50) NULL,
			[pbxId] tinyint NULL,
			[sipId] tinyint NULL,
			[sipPriority] tinyint NULL,
			[active] bit NOT NULL,
		 CONSTRAINT [PK_ccTrunkConfiguration] PRIMARY KEY CLUSTERED 
		(
			[TrunkId] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
		) ON [PRIMARY]'
   -- EXEC(@sql)

	set @process = 'KR06700 DROP ccsp_DLRGetTrunkConfig'
	set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_DLRGetTrunkConfig'')
            BEGIN
                DROP PROCEDURE [dbo].[ccsp_DLRGetTrunkConfig]
            END'
    EXEC(@sql)

	set @process = 'KR06700 CREATE ccsp_DLRGetTrunkConfig'
	set @sql = 'CREATE procedure [dbo].[ccsp_DLRGetTrunkConfig]
		@pbx_id int
		AS
		set nocount on

		select 
		domain,
		isnull(proxy,'''') proxy,
		[user],
		isnull(authName,'''') authName,
		isnull(encPassword,'''') encPassword,
		isnull(realm,'''') realm,
		ttl,
		isnull(ipNatOut,'''') ipNatOut,
		isnull(sipAgent,'''') sipAgent,
		isnull(fixedDomain,'''') fixedDomain,
		isnull(allowReinvite,0) allowReinvite,
		isnull(options,0) options,
		isnull(calloutHdr,'''') calloutHdr,
		isnull(sipId,1) sipId,
		isnull(sipPriority,1) sipPriority
		from ccTrunkConfiguration nolock 
		where pbxid=@pbx_id and active=1
		order by sipId,sipPriority

		set nocount off'
    EXEC(@sql)

	---------------------------------------END HUGO LONGORIA ---------------------------------------------------------

	
		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
		EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
