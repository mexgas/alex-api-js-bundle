/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio Chagolla
Date: 2024/09/30
Description: Release 126.20241218.0.0
Database: CCenterRia
Required version: 126.6
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 29
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
--- Validacion para cuando pasamos a una nueva version LTS
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

	------------------------------------------- BEGIN Gaby ----------------------------------------

	SET @process = 'Se elimina SP ccsp_WAOUTResetJobs'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_WAOUTResetJobs'')
    BEGIN
        DROP PROCEDURE ccsp_WAOUTResetJobs;
    END
    '
	EXEC(@sql)

    SET @process = 'Update ccsp_WAOUTResetJobs se cambia el status en los where para los registros que se van a actualizar'
	SET @sql = '
					ALTER PROCEDURE ccsp_WAOUTResetJobs
                    @camid AS INT= 0
                    AS
                    BEGIN

                      CREATE TABLE #TempccoLogDials ( 
                        waout_id INT, PRIMARY KEY (waout_id)
                      );
                      DECLARE @today DATETIME;

                      SELECT @today = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 121), 121);
                      
                      IF @camid = 0
                      BEGIN
                        INSERT INTO #TempccoLogDials
                             SELECT WaOutId
                             FROM ccoWhatsLogDials AS ld WITH(NOLOCK)
                             WHERE TimeSpam >= @today
                             GROUP BY WaOutId;
                      END;
                         ELSE
                        IF @camid > 0
                        BEGIN
                          INSERT INTO #TempccoLogDials
                               SELECT WaOutId
                               FROM ccoWhatsLogDials AS ld WITH(NOLOCK)
                               WHERE CamId = @camid AND 
                                 TimeSpam >= @today
                               GROUP BY WaOutId;
                        END;

                      IF @camid = 0
                      BEGIN
                        -- NUEVAS - Nunca se han marcado
                        UPDATE ccoWAWorkingTable 
                          SET WaStatus = 0
                        WHERE WaStatus = 2;
                      END;
                         ELSE
                      BEGIN  
                        -- NUEVAS - Nunca se han marcado
                        UPDATE ccoWAWorkingTable WITH(ROWLOCK)
                          SET WaStatus = 0
                        WHERE WaStatus = 2 AND 
                            CamId = @camid;
                      END;

                      UPDATE c
                      SET c.cam_procesando = 0
                      FROM ccCamps c
                      WHERE c.cam_id = @camid
                      

                      DROP TABLE #TempccoLogDials;
                    END;'
	EXEC(@sql)


	SET @process = 'Se elimina SP ccspOutboundWhatsApp'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspOutboundWhatsApp'')
    BEGIN
        DROP PROCEDURE ccspOutboundWhatsApp;
    END
    '
	EXEC(@sql)

    SET @process = 'Update ccspOutboundWhatsApp - se agrega action 3 '
	SET @sql = '
	ALTER procedure ccspOutboundWhatsApp
@action int,
@camId int = null,
@campType int = null,
@templateName varchar(512)=null,
@waMsgIds varchar(max)=null
as
if @action=1 begin
declare @Url as varchar(50)
set @Url = (select Url from ccMetaWhatsAppConfigurations where Id=1)

IF @camId IS NULL AND @campType IS NULL
BEGIN
	select 
		distinct 
		cast(c. cam_id as int) as CamId,
		cam_descripcion as [Name],
		1 AS CampType,
		cam_procesando as [Start],
		Number as PhoneNumber, 
		REPLACE(@Url, ''phoneId'', PhoneNumberId) as Url, 
		Token,
		CAST(c.IDArea AS int) as AreaId
	from ccCamps c with(nolock)
	left join ccCampsNvosCB w with(nolock) on c.cam_id = w.id
	left join  ccCampsHorarios s ON s.cam_id = c.cam_id
	left join ccMetaWhatsAppNumbers wn on wn.cam_id = c.cam_id
	WHERE CampType=5 AND c.IDArea IS NOT NULL
	UNION
	SELECT -- load acd
		DISTINCT 
		CAST(ci.Inbound_id AS INT) AS CamId,
		ci.descripcion AS [Name],
		0 AS CampType,
		CAST(ci.Status AS BIT) AS [Start],
		cmw.Number AS PhoneNumber,
		REPLACE(@Url, ''phoneId'', cmw.PhoneNumberId) AS Url,
		cmw.Token AS Token,
		CAST(ci.IDArea AS int) as AreaId
	FROM ccInbound ci WITH(NOLOCK)
	LEFT JOIN ccInboundHorarios cih ON cih.Inbound_id = ci.Inbound_id
	LEFT JOIN ccMetaWhatsAppNumbers cmw ON cmw.Inbound_Id = ci.Inbound_id
	WHERE ci.chat = 5  AND ci.IDArea IS NOT NULL
END
ELSE IF @campType IS NOT NULL
BEGIN
	IF @campType = 0
	BEGIN
		SELECT -- load acd
			DISTINCT 
			CAST(ci.Inbound_id AS INT) AS CamId,
			ci.descripcion AS [Name],
			0 AS CampType,
			CAST(ci.Status AS BIT) AS [Start],
			cmw.Number AS PhoneNumber,
			REPLACE(@Url, ''phoneId'', cmw.PhoneNumberId) AS Url,
			cmw.Token AS Token,
			CAST(ci.IDArea AS int) as AreaId
		FROM ccInbound ci WITH(NOLOCK)
		LEFT JOIN ccInboundHorarios cih ON cih.Inbound_id = ci.Inbound_id
		LEFT JOIN ccMetaWhatsAppNumbers cmw ON cmw.Inbound_Id = ci.Inbound_id
		WHERE ci.chat = 5  AND ci.IDArea IS NOT NULL AND (@camId IS NULL or @camId=0 OR ci.Inbound_id = @camId)
	END
	ELSE
	BEGIN
		select 
			distinct 
			cast(c. cam_id as int) as CamId,
			cam_descripcion as [Name],
			1 AS CampType,
			cam_procesando as [Start],
			Number as PhoneNumber, 
			REPLACE(@Url, ''phoneId'', PhoneNumberId) as Url, 
			Token,
			CAST(c.IDArea AS int) as AreaId
		from ccCamps c with(nolock)
		left join ccCampsNvosCB w with(nolock) on c.cam_id = w.id
		left join  ccCampsHorarios s ON s.cam_id = c.cam_id
		left join ccMetaWhatsAppNumbers wn on wn.cam_id = c.cam_id
		WHERE CampType=5 AND c.IDArea IS NOT NULL AND(@camId IS NULL or @camId=0 OR c.cam_id = @camId)
	END
END

end
else if @action=2 begin -- cargar valores del template para envio manual
	SELECT TOP 1
		A.id AS Id
	   ,A.LanguageCode AS LanguageCode
	   ,B.Number AS Number
	   ,ISNULL(A.header, '''') AS Header
	   ,ISNULL(A.body, '''') AS Body
	   ,ISNULL(A.footer, '''') AS Footer
	   ,ISNULL(A.buttons, '''') AS Buttons
	   ,ISNULL(A.headerLink, '''') AS HeaderLink
	FROM ccMetaWAOutboundTemplates A
	INNER JOIN ccMetawhatsAppNumbers B ON B.MetaId = A.MetaId
	WHERE A.TemplateName = @templateName
	AND B.Cam_Id = @camId

end
else if @action=3 begin 
declare @sql varchar(max)
	set @sql=''delete from ccoWAWorkingTable with(rowlock) where WAOut_id in(''+@waMsgIds+'')''
	exec (@sql)
end'
	EXEC(@sql)

    -------------------------------------------- END Gaby -----------------------------------------
	

        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
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
