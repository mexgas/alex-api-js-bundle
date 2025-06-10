/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 02/02/2024
Description: K089000

Database: CCenterRia
Required version: 125.48

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
SET @versionfix = 48
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
        ---------------------------------------------------- BEGIN Marco García --------------------------------------------------------------

        set @process = 'Alter SP ccsp_RIAOUTInsertNewJOBS_WT_Camp se modifica la linea 
		210, 282-284'
        set @sql = ' ALTER PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000 -- cambio para el ticket #1863
    AS
    SET NOCOUNT ON

    DECLARE @prioridad VARCHAR(8)
    DECLARE @batchsizeIni AS INT
    DECLARE @batchsizeFin AS INT
    DECLARE @rango AS DECIMAL
    DECLARE @rowstoInsert AS INT
    DECLARE @campType AS INT
    DECLARE @recordsQuantitySetting VARCHAR(8)
    DECLARE @settingValueP1 VARCHAR(25)

    SET @rowstoInsert = 0
    SET @batchsizeIni = 0
    SET @batchsizeFin = 0
    SET @rango = 0.00

    IF EXISTS(SELECT * FROM sys.views WHERE NAME = ''VIEW_SETTINGS'') BEGIN
        SELECT @recordsQuantitySetting = [valor] FROM VIEW_SETTINGS WHERE setting_id = 257;
        IF(@recordsQuantitySetting IS NOT NULL AND @recordsQuantitySetting <> '''') BEGIN
            SELECT @settingValueP1 = SUBSTRING(@recordsQuantitySetting, CHARINDEX(''|'', @recordsQuantitySetting)+1, LEN(@recordsQuantitySetting)),
                   @top = (SUBSTRING(@settingValueP1, 1, CHARINDEX(''|'', @settingValueP1)-1));
        END ELSE SET @top = 3000
    END ELSE SET @top = 3000

    SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
    FROM ccCampsPrioridadTel WITH (NOLOCK)
    WHERE cam_id = @camp_id

    SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id = @camp_id;

    DELETE ccUploadTemporal
    WHERE cam_id = @camp_id

    IF(@campType = 7)
    BEGIN
            CREATE TABLE #tempsmsOutSource (Id INT PRIMARY KEY identity, smsout_id INT, cam_id INT, sms_phoneNumber VARCHAR(19), sms_status TINYINT, sms_dateDial DATETIME, cal_keyw VARCHAR(40), iTimeZone INT, iTimeZone_summer INT, iTimeZone2 INT, iTimeZone_summer2 INT, iTimeZone3 INT, iTimeZone_summer3 INT, iTimeZone4 INT, iTimeZone_summer4 INT, iTimeZone5 INT, iTimeZone_summer5 INT, list_id INT)

            CREATE NONCLUSTERED INDEX [IX_TempSMSO] ON [dbo].[#tempsmsOutSource] ([Id] ASC)
                WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

            CREATE TABLE #smsoutIdSource (smsout_id INT NOT NULL PRIMARY KEY)

            CREATE TABLE #smsoutIdSource2 (smsout_id INT NOT NULL PRIMARY KEY)

            INSERT INTO #smsoutIdSource
            SELECT top(@top) sos.smsout_id
            FROM dbo.smsOutSource AS sos  WITH (INDEX (IX_smsOutSource_2), NOLOCK)
            inner join dbo.smsWorkingTable AS swt WITH (INDEX (IX_smsWorkingTable_2), NOLOCK) 
            on sos.callkey = swt.cal_keyw AND sos.cam_id = swt.cam_id 
            WHERE sos.cam_id = @camp_id and sos.sms_status IN (0, 7) AND swt.sms_status <= 2

            UNION

            SELECT top(@top) swt2.smsout_id
            FROM dbo.smsOutSource AS sos2 WITH (INDEX (IX_smsOutSource_2), NOLOCK)
            inner join dbo.smsWorkingTable AS swt2 (NOLOCK)on sos2.smsout_id = swt2.smsout_id 
            WHERE sos2.cam_id = @camp_id AND (sos2.sms_status < 2 OR sos2.sms_status = 7)

            INSERT INTO #smsoutIdSource2
            SELECT top(@top) sos.smsout_id
            FROM dbo.smsOutSource AS sos WITH (INDEX (IX_smsOutSource_1), NOLOCK)
            WHERE sos.sms_status IN (0, 1, 7) AND cam_id = @camp_id

            INSERT #tempsmsOutSource(smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, cal_keyw, iTimeZone, 
            iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4,
             iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id)
            SELECT TOP(@top) smsout_id, cam_id, RTRIM(LEFT(LTRIM(sms_phoneNumber + ''        '' + sms_phoneNumber2 + ''         '' 
            + sms_phoneNumber3 + ''         '' + sms_phoneNumber4 + ''         '' + sms_phoneNumber5 + ''         ''), 13)) AS sms_phoneNumber,
             CASE sms_status WHEN 7 THEN 1 ELSE sms_status END sms_status, sms_dateDial, callkey, 
             CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone ELSE NULL END iTimeZone,
              CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone_summer ELSE NULL END iTimeZone_summer, 
              CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone2 ELSE NULL END iTimeZone2,
               CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone_summer2 ELSE NULL END iTimeZone_summer2, 
               CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone3 ELSE NULL END iTimeZone3, 
               CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone_summer3 ELSE NULL END iTimeZone_summer3,
                CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone4 ELSE NULL END iTimeZone4, 
                CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone_summer4 ELSE NULL END iTimeZone_summer4, 
                CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone5 ELSE NULL END iTimeZone5, 
                CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone_summer5 ELSE 
                        NULL END iTimeZone_summer5, list_id
            FROM dbo.smsOutSource  WITH (INDEX (IX_smsOutSource_1), NOLOCK)
            WHERE cam_id = @camp_id AND (sms_status < 2 OR sms_status = 7) 

            SELECT @rowstoInsert = COUNT(*) FROM #tempsmsOutSource AS tos;

            
            IF EXISTS(SELECT * FROM #tempsmsOutSource)
            BEGIN
                SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
                FROM #tempsmsOutSource  WITH (NOLOCK)

                SET @batchsizeFin = @batchsizeFin + @rango

                WHILE 1 = 1
                BEGIN
                    -- Nuevos Jobs
                    INSERT INTO dbo.smsWorkingTable
                    WITH (TABLOCKX) (smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, attemps, user_id,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id)
                    SELECT smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, 0, 0 ,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id
                    FROM #tempsmsOutSource 
                    WHERE id > @batchsizeIni AND id <= @batchsizeFin

                    IF @batchsizeFin > @rowstoInsert
                        BREAK
                    ELSE
                    BEGIN
                        SET @batchsizeIni = @batchsizeIni + @rango
                        SET @batchsizeFin = @batchsizeFin + @rango
                    END
                END

                UPDATE dbo.smsOutSource
                SET sms_status = 2
                FROM dbo.smsOutSource AS sos WITH (NOLOCK), #smsoutIdSource2  cis3 WITH (NOLOCK)
                WHERE sos.smsout_id = cis3.smsout_id
            END

            DROP TABLE #smsoutIdSource

            DROP TABLE #smsoutIdSource2

            DROP TABLE #tempsmsOutSource
    END
    ELSE
    BEGIN
            CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19), cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(40), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT, iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT, iZonaHoraria_verano5 INT, list_id INT)

            CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
                WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

            CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

            CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

            INSERT INTO #calloutIdSource
            SELECT top(@top) cs.callout_id
            FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_15), NOLOCK)
            inner join ccoWorkingTable wt WITH (INDEX (IX_ccoWorkingTable_15), NOLOCK) 
            on cs.callout_id = wt.callout_id AND cs.cam_id = wt.cam_id 
            WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

            UNION

            SELECT top(@top) Cout.callout_id
            FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK)
            inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id 
			AND cout.cam_id = Wtab.cam_id
            WHERE Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)
    

            INSERT INTO #calloutIdSource2
            SELECT top(@top) callout_id
            FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_11), NOLOCK)
            WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

            IF exists(SELECT * FROM #calloutIdSource) 
            BEGIN
                UPDATE ccoCallBacks
                SET [status] = 6, schedulerStatus = 1
                WHERE callout_id IN (
                        SELECT callout_id
                        FROM #calloutIdSource cis
                        )

                UPDATE ccoCallsOutSource
                SET cal_Status = 4
                WHERE callout_id IN (
                        SELECT callout_id
                        FROM #calloutIdSource cis
                        )
            END

            INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, 
            iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
             iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
            SELECT TOP(@top) callout_id, cam_id, CASE WHEN ISNULL(recycleType, 1) = 0 THEN 
            CASE 
                WHEN recyclePhone = 1 THEN cal_telefono
                WHEN recyclePhone = 2 THEN cal_telefono2
                WHEN recyclePhone = 3 THEN cal_telefono3
                WHEN recyclePhone = 4 THEN cal_telefono4
                else cal_telefono5
            END
            ELSE rtrim(left(ltrim(cal_telefono + ''        '' + cal_telefono2 + ''         '' 
                + cal_telefono3 + ''         '' + cal_telefono4 + ''         '' + cal_telefono5 + ''         ''), 13)) 
            END AS cal_telefono,
             CASE cal_status WHEN 7 THEN 1 ELSE cal_status END cal_status, cal_fechaDial, cal_key, 
             CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria ELSE NULL END iZonaHoraria,
              CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano, 
              CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria2 ELSE NULL END iZonaHoraria2,
               CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2, 
               CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria3 ELSE NULL END iZonaHoraria3, 
               CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
                CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria4 ELSE NULL END iZonaHoraria4, 
                CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4, 
                CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria5 ELSE NULL END iZonaHoraria5, 
                CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE 
                        NULL END iZonaHoraria_verano5, list_id
            FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
            WHERE cam_id = @camp_id AND (cal_status < 2 OR cal_status = 7) /*AND CONVERT(VARCHAR(10),cal_fechaDial, 103) >= CONVERT(VARCHAR(10), GETDATE(), 103)*/

            SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

            IF EXISTS(SELECT * FROM #tempCallsOutSource)
            BEGIN
                SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
                FROM #tempCallsOutSource WITH (NOLOCK)

                SET @batchsizeFin = @batchsizeFin + @rango

                WHILE 1 = 1
                BEGIN
                    -- Nuevos Jobs
                    INSERT INTO ccoWorkingTable
                    WITH (TABLOCKX) (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
                    SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id
                    FROM #tempCallsOutSource AS t
                    WHERE id > @batchsizeIni AND id <= @batchsizeFin
					AND NOT EXISTS (
						  SELECT 1 FROM ccoWorkingTable cw WHERE cw.callout_id = t.callout_id
						)


                    IF @batchsizeFin > @rowstoInsert
                        BREAK
                    ELSE
                    BEGIN
                        SET @batchsizeIni = @batchsizeIni + @rango
                        SET @batchsizeFin = @batchsizeFin + @rango
                    END
                END

                UPDATE ccoCallsOutSource
                SET cal_status = 2, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
                FROM ccoCallsOutSource co WITH (NOLOCK), #calloutIdSource2 cis3 WITH (NOLOCK)
                WHERE co.callout_id = cis3.callout_id
            END

            DROP TABLE #calloutIdSource

            DROP TABLE #calloutIdSource2

            DROP TABLE #tempCallsOutSource
    END

    UPDATE ccCampsNvosCB
    SET dateUpdate = NULL
    WHERE id = @camp_id

    SET NOCOUNT OFF
    
    '
    EXEC(@sql)

    

---------------------------------------- End   -------------------------------------------------        

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

