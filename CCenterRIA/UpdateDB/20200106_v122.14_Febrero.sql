/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/02/19
Description:

Database: CCenterRia
Required version: 122.14

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
SET @version = 122 --**********actualizar a 122 sin fix
SET @versionfix = 14
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF (@actualVersion = @version AND @actualVersionFix >= 11) OR (@actualVersion = @version-1 AND @actualVersionFix >= 41)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'CW-3732 - Actualizar sp ccsp_DLRGetPBXInfo'
		set @sql='ALTER procedure [dbo].[ccsp_DLRGetPBXInfo]
				@pbx_id int
				AS
				set nocount on

				declare @port varchar(5), @remotes varchar(300)
				select @port = valor from ccsettings where setting_id=119
				select @remotes = valor from ccsettings where setting_id=143
				select
				case when charindex('':'',pbxIp)>0 then substring(pbxIp, 0, charindex('':'',pbxIp)) else pbxIp end pbxUri,
				case when charindex('':'',pbxIp)>0 then substring(pbxIp, charindex('':'',pbxIp)+1, 5) else @port end port
				from
				(select
				substring(value,0,charindex(''|'',value)) pbxId,
				substring(value,charindex(''|'',value)+1,len(value)) pbxIp
				from dbo.fn_RIASplitDelimited(@remotes, '','')
				where cast(substring(value,0,charindex(''|'',value)) as int)=@pbx_id) x

				set nocount off'
		EXEC(@sql)

		set @process = '(CenterScript) Alter getadminprops sp'
		set @sql = '
						ALTER PROCEDURE [dbo].[CS_GetAdminProps] @admin_id INT
AS
SET NOCOUNT ON;

SELECT convert(int,user_id) as [user_id], Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno as [name]
	,Upper(left(nombres, 1) + left(apellidopaterno, 1)) AS [initials]
FROM ccUsers a
WHERE TipoUser_id = 2
	AND User_id = @admin_id
		'

		exec(@sql)

		set @process = '(Centerscript) alter cs_getAcdCampList'
		set @sql = '
			ALTER PROCEDURE [dbo].[cs_GetACDCampaignList] @action AS SMALLINT
AS
IF (@action = 1)
BEGIN
	SELECT cam_id AS [cam_id]
		,cam_descripcion AS [name]
	FROM ccCamps
	WHERE cam_activo = 1
		AND cam_id NOT IN (
			SELECT Cam_id
			FROM CW_CenterScript..Campaign
			)
		AND IDArea > 0 
END

IF (@action = 2)
BEGIN
	SELECT inbound_id
		,descripcion AS [name]
	FROM ccInbound
	WHERE STATUS = 1
		AND Inbound_id NOT IN (
			SELECT Inbound_id
			FROM CW_CenterScript..Inbound_Campaign

			)
		AND IDArea > 0 and chat = 0
END

IF (@action = 3)
BEGIN
	SELECT cam_id AS [cam_id]
		,cam_descripcion AS [name]
	FROM ccCamps
	WHERE cam_activo = 1
		AND IDArea > 0
END

IF (@action = 4)
BEGIN
	SELECT inbound_id
		,descripcion AS [name]
	FROM ccInbound
	WHERE STATUS = 1
		AND IDArea > 0
		AND chat = 0
END

		'
exec (@sql)


		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
