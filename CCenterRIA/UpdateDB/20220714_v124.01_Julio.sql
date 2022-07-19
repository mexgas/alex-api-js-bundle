/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/02/15
Description: Merge con los cambios de sorteos

Database: CCenterRia
Required version: 123.27

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
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 1
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion in(@version,@version-1) and @actualVersionFix >= 53
BEGIN
	BEGIN TRAN

	BEGIN TRY

	
	 -------------------------  Start CCC --------------------------------------------------
	 set @process = 'K002124-Mensajes recibidos en conversación al existir una desconexión en el servicio MultimediaCommon'
     set @sql = 'ALTER PROCEDURE [dbo].[ccsp_Multimedia2] @action INT, @inboundId INT = NULL, @userId INT = NULL, @senderId INT = NULL
				AS
				BEGIN
					SET NOCOUNT ON;

					IF @action = 1
					BEGIN --Lista  ACD
						SELECT DISTINCT A.inbound_id AS Id, A.chat AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets, 
						cast(isnull(C.maxWhats, 3) AS TINYINT) AS MaxWhats, A.IDArea AS AreaId
						FROM ccInbound A
						INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
						WHERE @inboundId IS NULL OR @inboundId = A.Inbound_id
					END
					ELSE IF @action = 2
					BEGIN --Lista Agentes  
						SELECT DISTINCT A.User_id AS [Id], C.idCampEsp AcdId, isnull(skill, 8) Skill
						FROM ccRIAWorkGroupUsers A
						INNER JOIN ccusers B ON A.User_id = B.User_id
						INNER JOIN ccRIACampEspWG C ON C.IDWG = A.IDWG AND C.Tipo = 0
						INNER JOIN ccInbound D ON C.idCampEsp = D.inbound_id
						LEFT JOIN ccskills S ON S.inbound_id = D.inbound_id AND S.user_id = B.user_id
						WHERE B.TipoUser_id = 1 AND (@userId IS NULL OR @userId = A.User_id)
						ORDER BY A.User_id
					END
					ELSE IF @action = 3
					BEGIN --List Sender Mail
						SELECT A.contactMeanOutId AS Id, ISNULL(R.inboundId, 0) AS AcdId, A.isActive AS IsActive
						FROM contactMeanOut A
						LEFT JOIN relationContactMeanOutInbound R ON A.contactMeanOutId = R.contactMeanOutId
						WHERE @senderId IS NULL OR @senderId = A.contactMeanOutId
					END
					ELSE IF @action = 4
					BEGIN --List ACD Whatsapp
						SELECT  inboundId AS Id
						FROM contactMeanIn
						WHERE meanContactTypeId = 5
					END
				END'
	 EXEC(@sql)

	-------------------------  END CCC --------------------------------------------------
   
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


