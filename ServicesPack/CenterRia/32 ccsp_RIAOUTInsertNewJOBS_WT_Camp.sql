ALTER PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000
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

IF EXISTS(SELECT * FROM sys.views WHERE NAME = 'VIEW_SETTINGS') BEGIN
    SELECT @recordsQuantitySetting = [valor] FROM VIEW_SETTINGS WHERE setting_id = 257;
    IF(@recordsQuantitySetting IS NOT NULL AND @recordsQuantitySetting <> '') BEGIN
        SELECT @settingValueP1 = SUBSTRING(@recordsQuantitySetting, CHARINDEX('|', @recordsQuantitySetting)+1, LEN(@recordsQuantitySetting)),
                @top = (SUBSTRING(@settingValueP1, 1, CHARINDEX('|', @settingValueP1)-1));
    END ELSE SET @top = 3000
END ELSE SET @top = 3000

SELECT @prioridad = isnull(Prioridad, '12345NNN')
FROM ccCampsPrioridadTel WITH (NOLOCK)
WHERE cam_id = @camp_id

SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id = @camp_id;

DELETE ccUploadTemporal
WHERE cam_id = @camp_id

IF(@campType = 7)
BEGIN
        CREATE TABLE #tempsmsOutSource (Id INT PRIMARY KEY identity, smsout_id INT, cam_id INT, sms_phoneNumber VARCHAR(19), sms_status TINYINT, sms_dateDial DATETIME, cal_keyw VARCHAR(40), iTimeZone INT, iTimeZone_summer INT, iTimeZone2 INT, iTimeZone_summer2 INT, iTimeZone3 INT, iTimeZone_summer3 INT, iTimeZone4 INT, iTimeZone_summer4 INT, iTimeZone5 INT, iTimeZone_summer5 INT, list_id INT, sms_dateDialEnd datetime, isSegmentLoad bit)

        CREATE NONCLUSTERED INDEX [IX_TempSMSO] ON [dbo].[#tempsmsOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

        CREATE TABLE #smsoutIdSource (smsout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #smsoutIdSource2 (smsout_id INT NOT NULL PRIMARY KEY)
        --UPDATING TABLES BEFORE LOADING
        DECLARE @date datetime = GETDATE()
        UPDATE smsOutSource SET sms_status = 2 where sms_dateDialEnd < @date and isSegmentLoad = 1
        UPDATE smsWorkingTable SET sms_status = 2 where sms_dateDialEnd < @date and isSegmentLoad = 1

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
            iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
        SELECT TOP(@top) smsout_id, cam_id, RTRIM(LEFT(LTRIM(sms_phoneNumber + '        ' + sms_phoneNumber2 + '         '
        + sms_phoneNumber3 + '         ' + sms_phoneNumber4 + '         ' + sms_phoneNumber5 + '         '), 13)) AS sms_phoneNumber,
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
                    NULL END iTimeZone_summer5, list_id, sms_dateDialEnd, ISNULL(isSegmentLoad, 0)
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
               INSERT INTO dbo.smsWorkingTable  WITH (ROWLOCK)
                (smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, attemps, user_id,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id, sms_dateDialEnd, isSegmentLoad)
                SELECT t.smsout_id, t.cam_id, t.sms_phoneNumber, t.sms_status, t.sms_dateDial, 0, 0
                ,t.cal_keyw, t.iTimeZone, t.iTimeZone_summer, t.iTimeZone2, t.iTimeZone_summer2, t.iTimeZone3, t.iTimeZone_summer3
                , t.iTimeZone4, t.iTimeZone_summer4, t.iTimeZone5, t.iTimeZone_summer5, t.list_id,t.sms_dateDialEnd, t.isSegmentLoad
                FROM #tempsmsOutSource t
                WHERE id > @batchsizeIni AND id <= @batchsizeFin
                AND NOT EXISTS (
                    SELECT 1 FROM smsWorkingTable swt WHERE swt.smsout_id = t.smsout_id
                )

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
ELSE IF(@campType = 5)
BEGIN
    CREATE TABLE #tempWhatsAppOutSource (Id INT PRIMARY KEY identity, WAOut_Id INT, CallKey VARCHAR(40), camId INT, PhoneNumber VARCHAR(30), Status INT, TimeZone int, TimeZone_Summer int, List_id INT, User_id SMALLINT, dateDial DATETIME)
    CREATE NONCLUSTERED INDEX [IX_TempWAO] ON [dbo].[#tempWhatsAppOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

    CREATE TABLE #WAIdSource (WAOut_Id INT NOT NULL PRIMARY KEY)

    INSERT INTO #WAIdSource
    SELECT top(@top) cwaos.WAOut_Id
        FROM dbo.ccWhatsAppOutSource AS cwaos WITH (INDEX (IX_WASource_1), NOLOCK)
        WHERE cwaos.Status IN (0) AND cwaos.camId = @camp_id

    INSERT INTO #tempWhatsAppOutSource
    (
        WAOut_Id,
        CallKey,
        camId,
        PhoneNumber,
        Status,
        TimeZone,
        TimeZone_Summer,
        List_id,
        User_id,
        dateDial
    )
        SELECT TOP(@top) cwaos.WAOut_Id, cwaos.CallKey,cwaos.camId, RTRIM(LEFT(LTRIM(cwaos.PhoneNumber + '        ' ), 13)) AS phoneNumber,
            cwaos.Status AS WAStatus,
            CASE WHEN cwaos.TimeZone = 0 THEN  dbo.fnGetTimeZone(cwaos.PhoneNumber,0) ELSE cwaos.TimeZone END,
            CASE WHEN cwaos.TimeZone_Summer = 0 THEN  dbo.fnGetTimeZone(cwaos.PhoneNumber,1) ELSE cwaos.TimeZone_Summer END,
            list_id, cwaos.User_id, cwaos.dateDial
        FROM dbo.ccWhatsAppOutSource AS cwaos  WITH (INDEX (IX_WASource_1), NOLOCK)
        WHERE cwaos.camId = @camp_id AND (cwaos.Status = 0)

    SELECT @rowstoInsert = COUNT(*) FROM #tempWhatsAppOutSource AS tos;

        IF EXISTS(SELECT * FROM #tempWhatsAppOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempWhatsAppOutSource  WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                -- Nuevos Jobs
                INSERT INTO dbo.ccoWAWorkingTable(WAOut_id, PhoneNumber, Callkey, CamId, WaStatus, dateDial, UserId,TimeZone, TimeZone_Summer)
                SELECT WAOut_Id, PhoneNumber, CallKey, camId, Status, dateDial , User_id, TimeZone ,TimeZone_Summer
                FROM #tempWhatsAppOutSource
                WHERE id > @batchsizeIni AND id <= @batchsizeFin

                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE dbo.ccWhatsAppOutSource
            SET
            Status = 2,
            TimeZone = cis3.TimeZone,
            TimeZone_Summer = cis3.TimeZone_Summer
            FROM dbo.ccWhatsAppOutSource AS cwaos  WITH (NOLOCK), #tempWhatsAppOutSource  cis3 WITH (NOLOCK)
            WHERE cwaos.WAOut_Id = cis3.WAOut_Id
        END

        DROP TABLE #WAIdSource

        DROP TABLE #tempWhatsAppOutSource
END
ELSE
BEGIN
        CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19),
        cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(40), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT,
        iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT,
        iZonaHoraria_verano5 INT, list_id INT, new_status int)

        CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

        CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

        INSERT INTO #calloutIdSource
        SELECT top(@top) cs.callout_id
        FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
        inner join ccoWorkingTable wt WITH (INDEX (PK_ccoWorkingTable), NOLOCK)
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
        ELSE rtrim(left(ltrim(cal_telefono + '        ' + cal_telefono2 + '         '
            + cal_telefono3 + '         ' + cal_telefono4 + '         ' + cal_telefono5 + '         '), 13))
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

		--Se elimina de workingtable en caso de que no se hayan borrado correctamente no genere error al insertar nuevos registros
		DELETE wt FROM ccoWorkingTable wt
		INNER JOIN #tempCallsOutSource tcs on wt.callout_id = tcs.callout_id
		WHERE wt.cam_id = @camp_id

        SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

        IF EXISTS(SELECT * FROM #tempCallsOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempCallsOutSource WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                -- Nuevos Jobs
                 INSERT INTO ccoWorkingTable  WITH (ROWLOCK)
                (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
                SELECT t.callout_id, t.cam_id, t.cal_telefono, t.cal_status, t.cal_fechaDial, t.cal_keyw,
                       t.iZonaHoraria, t.iZonaHoraria_verano, t.iZonaHoraria2, t.iZonaHoraria_verano2,
                       t.iZonaHoraria3, t.iZonaHoraria_verano3, t.iZonaHoraria4, t.iZonaHoraria_verano4,
                       t.iZonaHoraria5, t.iZonaHoraria_verano5, t.list_id
                FROM #tempCallsOutSource t
                WHERE t.id > @batchsizeIni AND t.id <= @batchsizeFin
                  AND NOT EXISTS (
                    SELECT 1 FROM ccoWorkingTable w WHERE w.callout_id = t.callout_id
                );


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