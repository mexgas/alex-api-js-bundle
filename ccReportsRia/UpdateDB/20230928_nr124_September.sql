SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 124

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	---------------------------------------BEGIN Rodrigo Salazar-----------------------------------------------------------
	SET @process = 'KR096006 DROP PROCEDURE ccspRepInDispositions'
	SET @sql = '
		if exists(select * from sys.procedures where name = ''ccspRepInDispositions'')
		begin
			DROP PROCEDURE ccspRepInDispositions
		end'
	EXEC(@sql)

	SET @process = 'KR096006 CREATE PROCEDURE ccspRepInDispositions'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccspRepInDispositions] 
        @action AS TINYINT, 
        @from AS DATETIME = NULL, 
        @to AS DATETIME = NULL
        AS
        IF @from IS NULL
            SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

        IF @to IS NULL
            SELECT @to = getdate()

        IF @action = 1
        BEGIN
            --Borrar lo que esta para no repetir
            DELETE
            FROM RepInDispositions WITH (ROWLOCK)
            WHERE DATE >= @from AND DATE < @to

            INSERT INTO RepInDispositions
            SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), dateHour, 121) + '':00'', 121), Inbound_id, ACDGroup, dispositionId, DispName, disposition_count, count(dispositionId) DispAmount, User_id, LOGIN, username, IDArea, areaName, IDWG AS wgId, wg, datepart(yyyy, max(dateHour)) AS year, datepart(mm, max(dateHour)) AS mes, datepart(dd, max(dateHour)) AS dia, datepart(hh, max(dateHour)), 0
            FROM (
                SELECT a.cal_inicio AS dateHour, a.Inbound_id, isnull(b.descripcion, '''') as ACDGroup, a.calif_id AS dispositionId, case when description is not null then ''InDisp-'' + cast(a.calif_id as varchar) else ''systemTranslated_Dispositionless'' end as DispName, case when description is not null then ''InDisp-'' + cast(a.calif_id as varchar) + ''_Count''  else ''systemTranslated_Dispositionless_Count'' end as disposition_count, a.User_id, LOGIN = isnull(LOGIN, ''''), username = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, ''''), b.IDArea, isnull(AreaName, '''') AS areaName, c.IDWG, isnull(c.WGName,''systemTranslated_WorkGroup'') AS wg
                FROM cccallsin a
                INNER JOIN ccWgByAcdView b ON a.Inbound_id=b.Inbound_id
                LEFT JOIN ccRIACat_WorkGroup c ON c.IDWG=b.IDWG
                --INNER JOIN ccRIACampEspWG c ON b.Inbound_id=c.IdCampEsp
                LEFT JOIN cctipocalif tc ON a.calif_id = tc.calif_id
                LEFT JOIN ccUserView d ON a.User_id = d.user_id
                LEFT JOIN ccRIACat_Areas e ON b.IdArea = e.IDArea
                WHERE cal_inicio >= @from AND cal_inicio < @to AND a.statuscall_id = 13 --Constestada
                    AND b.IDArea IS NOT NULL
                
                UNION

                SELECT requestDate, a.inboundId, isnull(b.descripcion, '''') as ACDGroup, a.disposition, case when description is not null then ''InDisp-'' + cast(a.disposition as varchar) else ''systemTranslated_Dispositionless'' end as DispName, case when description is not null then ''InDisp-'' + cast(a.disposition as varchar) + ''_Count''  else ''systemTranslated_Dispositionless_Count'' end as disposition_count, a.userId, LOGIN = isnull(LOGIN, ''''), username = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, ''''), b.IDArea, isnull(AreaName, '''') AS areaName, b.IDWG, isnull(c.WGName,''systemTranslated_WorkGroup'') AS wg
                FROM ccRIAChats a
                --LEFT JOIN ccInbound b ON b.Inbound_id = a.inboundId
                INNER JOIN ccWgByAcdView b ON a.inboundId=b.Inbound_id
                LEFT JOIN ccRIACat_WorkGroup c ON c.IDWG=b.IDWG
                --INNER JOIN ccRIACampEspWG c ON b.Inbound_id=c.IdCampEsp
                LEFT JOIN cctipocalif tc ON a.disposition = tc.calif_id
                LEFT JOIN ccUserView d ON a.userId = d.user_id
                LEFT JOIN ccRIACat_Areas e ON b.IdArea = e.IDArea
                WHERE requestDate >= @from AND requestDate < @to AND a.chatStatus = 3 --Assigned
                    AND b.IDArea IS NOT NULL
                ) AS x
            GROUP BY CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), dateHour, 121) + '':00'', 121), Inbound_id, ACDGroup, dispositionId,  DispName, disposition_count, user_id, LOGIN, username, IDArea, areaName, IDWG, wg
        END'
	EXEC(@sql)

	SET @process = 'KR096007 DROP PROCEDURE ccspRepInSubDispositions'
	SET @sql = '
		if exists(select * from sys.procedures where name = ''ccspRepInSubDispositions'')
		begin
			DROP PROCEDURE ccspRepInSubDispositions
		end'
	EXEC(@sql)

	SET @process = 'KR096007 CREATE PROCEDURE ccspRepInSubDispositions'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccspRepInSubDispositions] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
        AS
        IF @from IS NULL
            SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

        IF @to IS NULL
            SELECT @to = getdate()

        IF @action = 1
        BEGIN
            --Borrar lo que esta para no repetir
            DELETE
            FROM RepInSubDispositions WITH (ROWLOCK)
            WHERE DATE >= @from AND DATE < @to

            INSERT INTO RepInSubDispositions
            SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), dateHour, 121) + '':00'', 121), Inbound_id, '''' AS ACDGroup, subDispositionId, '''' AS DispName, '''', count(dispositionId) DispAmount, user_id, '''' AS LOGIN, '''' AS username, IDArea, '''' AS areaName, 1 AS wgId, ''systemTranslated_WorkGroup'' AS wg, datepart(yyyy, max(dateHour)) AS year, datepart(mm, max(dateHour)), datepart(dd, max(dateHour)), datepart(hh, max(dateHour)), 0
            FROM (
                SELECT cal_inicio AS dateHour, a.Inbound_id, isnull(a.califSub_id, 0) AS subDispositionId, calif_id AS dispositionId, user_id, b.IDArea
                FROM cccallsin a
                LEFT JOIN ccInbound b ON b.Inbound_id = a.Inbound_id
                WHERE cal_inicio >= @from AND cal_inicio < @to AND a.statuscall_id = 13 AND b.IDArea IS NOT NULL
                
                UNION
                
                SELECT requestDate, a.inboundId, a.subDisposition, a.disposition, a.userId, b.IDArea
                FROM ccRIAChats a
                LEFT JOIN ccInbound b ON b.Inbound_id = a.inboundId
                WHERE requestDate >= @from AND requestDate < @to AND a.chatStatus = 3 --Assigned
                    AND b.IDArea IS NOT NULL
                ) AS x
            GROUP BY CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), dateHour, 121) + '':00'', 121), Inbound_id, subDispositionId, user_id, IDArea

            UPDATE a
            SET acdGroup = isnull(descripcion, '''')
            FROM RepInSubDispositions a
            LEFT JOIN ccInbound b ON a.inboundId = b.Inbound_id
            WHERE [date] >= @from AND [date] < @to

            UPDATE a
            SET subDisposition = case when califSubDesc is not null then ''InDisp-'' + cast(a.subDispositionId as varchar) else ''systemTranslated_Dispositionless'' end, 
            subDisposition_count = case when califSubDesc is not null then ''InDisp-'' + cast(a.subDispositionId as varchar) + ''_Count'' else ''systemTranslated_Dispositionless_Count'' end 
            FROM RepInSubDispositions a
            LEFT JOIN cctipocalifsub b ON a.subDispositionId = b.califSub_id
            WHERE [date] >= @from AND [date] < @to

            UPDATE a
            SET [user] = isnull(LOGIN, '''')
            FROM RepInSubDispositions a
            LEFT JOIN ccUserView b ON a.userId = b.user_id
            WHERE [date] >= @from AND [date] < @to

            UPDATE a
            SET agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''')
            FROM RepInSubDispositions a
            LEFT JOIN ccUserView b ON a.userId = b.user_id
            WHERE [date] >= @from AND [date] < @to

            UPDATE a
            SET area = isnull(AreaName, '''')
            FROM RepInSubDispositions a
            LEFT JOIN ccRIACat_Areas b ON a.areaId = b.IDArea
            WHERE [date] >= @from AND [date] < @to
        END'
	EXEC(@sql)

	SET @process = 'KR096012 DROP PROCEDURE ccspRepOutDispositions'
	SET @sql = '
		if exists(select * from sys.procedures where name = ''ccspRepOutDispositions'')
		begin
			DROP PROCEDURE ccspRepOutDispositions
		end'
	EXEC(@sql)

	SET @process = 'KR096012 CREATE PROCEDURE ccspRepOutDispositions'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccspRepOutDispositions] @action AS TINYINT
            ,@from AS DATETIME = NULL
            ,@to AS DATETIME = NULL
        AS
        IF @from IS NULL
            SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

        IF @to IS NULL
            SELECT @to = getdate()

        IF @action = 1
        BEGIN
            --Borrar lo que esta para no repetir
            DELETE
            FROM RepOutDispositions
            WHERE DATE >= @from
                AND DATE < @to;

            WITH detailWorkGroup
            AS (
                SELECT min(IDWG) IDWG
                    ,IdCampEsp
                    ,min(WGName) WGName
                FROM ccRIACampEspWGView
                WHERE Tipo = 1
                GROUP BY IdCampEsp
                )
                ,callOut
            AS (
                SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), a.cal_inicio, 121) + '':00'', 121) AS DATE
                    ,a.cam_id
                    ,a.calif_id
                    ,count(calif_id) DispAmount
                    ,user_id
                FROM ccocallsout a
                WHERE cal_inicio >= @from
                    AND cal_inicio < @to
                    AND a.statuscall_id = 13
                    AND cal_manual IN (0, 2)
                GROUP BY CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), a.cal_inicio, 121) + '':00'', 121)
                    ,a.cam_id
                    ,a.calif_id
                    ,user_id
                )

            insert into RepOutDispositions
            SELECT A.DATE
                ,a.cam_id campaignId
                ,ISNULL(b.cam_descripcion, '''') AS Campaign
                ,a.calif_id dispositionId
                ,case when c.Description is not null then ''InDisp-'' + cast(a.calif_id as varchar) else ''systemTranslated_Dispositionless'' end as disposition
                ,case when c.Description is not null then ''InDisp-'' + cast(a.calif_id as varchar) + ''_Count'' else ''systemTranslated_Dispositionless_Count'' end as disposition_count                
                ,a.DispAmount AS [count]
                ,A.user_id userId
                ,ISNULL(d.LOGIN, '''') [agentName]
                ,isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''') AS username
                ,isnull(b.IDArea, 0) AS areaId
                ,isnull(e.AreaName, '''') AS area
                ,isnull(wg.IDWG, 0) AS workgroupId
                ,isnull(wg.WGName, ''-'') AS wg
                ,datepart(yyyy, DATE) AS year
                ,datepart(mm, DATE) AS mounth
                ,datepart(dd, DATE) AS day
                ,datepart(hh, DATE) AS hour
                ,datepart(mi, DATE) AS min
            FROM callOut A
            LEFT JOIN cccamps b ON a.cam_id = b.cam_id
            LEFT JOIN cctipocalifout c ON A.calif_id = c.calif_id
            LEFT JOIN ccUserView d ON a.User_id = d.User_id
            LEFT JOIN ccRIACat_Areas e ON b.IDArea = e.IDArea
            LEFT JOIN detailWorkGroup wg ON wg.IdCampEsp = A.cam_id
        END'
	EXEC(@sql)

	SET @process = 'KR096013 DROP PROCEDURE ccspRepOutSubDispositions'
	SET @sql = '
		if exists(select * from sys.procedures where name = ''ccspRepOutSubDispositions'')
		begin
			DROP PROCEDURE ccspRepOutSubDispositions
		end'
	EXEC(@sql)

	SET @process = 'KR096013 CREATE PROCEDURE ccspRepOutSubDispositions'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccspRepOutSubDispositions] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
        AS
        IF @from IS NULL
            SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

        IF @to IS NULL
            SELECT @to = getdate()

        IF @action = 1
        BEGIN
            --Borrar lo que esta para no repetir
            DELETE
            FROM RepOutSubDispositions WITH (ROWLOCK)
            WHERE DATE >= @from AND DATE < @to

            INSERT INTO RepOutSubDispositions
            SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), a.cal_inicio, 121) + '':00'', 121) AS dateHour, a.cam_id, '''' AS Campaign, isnull(a.califSub_id, 0), '''' AS DispName, '''', count(calif_id) DispAmount, user_id, '''' AS LOGIN, '''' AS username, b.IDArea, '''' AS areaName, 1 AS wgId, ''systemTranslated_WorkGroup'' AS wg, datepart(yyyy, max(cal_inicio)) AS year, datepart(mm, max(cal_inicio)), datepart(dd, max(cal_inicio)), datepart(hh, max(cal_inicio)), datepart(mi, max(cal_inicio))
            FROM ccocallsout a(NOLOCK)
            LEFT JOIN ccCamps b ON b.cam_Id = a.cam_id
            WHERE cal_inicio >= @from AND cal_inicio < @to AND a.statuscall_id = 13 AND cal_manual IN (0, 2) AND b.IDArea IS NOT NULL
            GROUP BY CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), a.cal_inicio, 121) + '':00'', 121), a.cam_id, a.califSub_id, user_id, b.IDArea

            UPDATE a
            SET campaign = isnull(cam_descripcion, '''')
            FROM RepOutSubDispositions a
            LEFT JOIN ccCamps b ON a.campaignId = b.cam_id
            WHERE [date] >= @from AND [date] < @to

            UPDATE a
            --SET subDisposition = isnull(califSubDesc, ''systemTranslated_Dispositionless''), 
            --subDisposition_count = isnull(califSubDesc, ''systemTranslated_Dispositionless'') + ''_Count''
            SET subDisposition = case when califSubDesc is not null then ''InDisp-'' + cast(a.subDispositionId as varchar) else ''systemTranslated_Dispositionless'' end, 
            subDisposition_count = case when califSubDesc is not null then ''InDisp-'' + cast(a.subDispositionId as varchar) + ''_Count'' else ''systemTranslated_Dispositionless_Count'' end
            FROM RepOutSubDispositions a
            LEFT JOIN cctipocalifsubout b ON a.subDispositionId = b.califSub_id
            WHERE [date] >= @from AND [date] < @to

            UPDATE a
            SET [user] = isnull(LOGIN, '''')
            FROM RepOutSubDispositions a
            LEFT JOIN ccUserView b ON a.userId = b.user_id
            WHERE [date] >= @from AND [date] < @to

            UPDATE a
            SET agentName = isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''')
            FROM RepOutSubDispositions a
            LEFT JOIN ccUserView b ON a.userId = b.user_id
            WHERE [date] >= @from AND [date] < @to

            UPDATE a
            SET area = isnull(AreaName, '''')
            FROM RepOutSubDispositions a
            LEFT JOIN ccRIACat_Areas b ON a.areaId = b.IDArea
            WHERE [date] >= @from AND [date] < @to
        END'
	EXEC(@sql)

	SET @process = 'KR096008 ALTER TABLE RepOutDialDetail -> callDisposition'
	SET @sql = '
		if exists(select * from sys.columns where name = ''callDisposition'' and object_id = OBJECT_ID(''RepOutDialDetail''))
		begin
			ALTER TABLE RepOutDialDetail ALTER COLUMN callDisposition varchar(150)
		end'
	EXEC(@sql)

	SET @process = 'KR096008 ALTER TABLE RepOutDialDetail -> callSubDisposition'
	SET @sql = '
		if exists(select * from sys.columns where name = ''callSubDisposition'' and object_id = OBJECT_ID(''RepOutDialDetail''))
		begin
			ALTER TABLE RepOutDialDetail ALTER COLUMN callSubDisposition varchar(150)
		end'
	EXEC(@sql)

	SET @process = 'KR096010 ALTER TABLE RepOutManagementBase -> disposition'
	SET @sql = '
		if exists(select * from sys.columns where name = ''disposition'' and object_id = OBJECT_ID(''RepOutManagementBase''))
		begin
			ALTER TABLE RepOutManagementBase ALTER COLUMN disposition varchar(150)
		end'
	EXEC(@sql)

	SET @process = 'KR096010 ALTER TABLE RepOutManagementBase -> subDisposition'
	SET @sql = '
		if exists(select * from sys.columns where name = ''subDisposition'' and object_id = OBJECT_ID(''RepOutManagementBase''))
		begin
			ALTER TABLE RepOutManagementBase ALTER COLUMN subDisposition varchar(150)
		end'
	EXEC(@sql)

	SET @process = 'KR096010 insert into ReportsFiltersMenus'
	SET @sql = '
		if not exists (select * from ReportsFiltersMenus where idReport = 4170 and filterMenuName = ''filterby'')
		begin
			insert into ReportsFiltersMenus values (4170, ''filterby'', 1, '''')
		end'
	EXEC(@sql)

	SET @process = 'KR096011 ALTER TABLE RepAnsweredCallsByDialingRetries -> disposition'
	SET @sql = '
		if exists(select * from sys.columns where name = ''disposition'' and object_id = OBJECT_ID(''RepAnsweredCallsByDialingRetries''))
		begin
			ALTER TABLE RepAnsweredCallsByDialingRetries ALTER COLUMN disposition varchar(150)
		end'
	EXEC(@sql)

	SET @process = 'KR096011 ALTER TABLE RepAnsweredCallsByDialingRetries -> subDisposition'
	SET @sql = '
		if exists(select * from sys.columns where name = ''subDisposition'' and object_id = OBJECT_ID(''RepAnsweredCallsByDialingRetries''))
		begin
			ALTER TABLE RepAnsweredCallsByDialingRetries ALTER COLUMN subDisposition varchar(150)
		end'
	EXEC(@sql)

	SET @process = 'KR096015 ALTER TABLE RepWhatsAppDetailConversationIn -> disposition'
	SET @sql = '
		if exists(select * from sys.columns where name = ''disposition'' and object_id = OBJECT_ID(''RepWhatsAppDetailConversationIn''))
		begin
			ALTER TABLE RepWhatsAppDetailConversationIn ALTER COLUMN disposition varchar(150) 
		end'
	EXEC(@sql)

	SET @process = 'KR096015 ALTER TABLE RepWhatsAppDetailConversationIn -> subDisposition'
	SET @sql = '
		if exists(select * from sys.columns where name = ''subDisposition'' and object_id = OBJECT_ID(''RepWhatsAppDetailConversationIn''))
		begin
			ALTER TABLE RepWhatsAppDetailConversationIn ALTER COLUMN subDisposition varchar(150)
		end'
	EXEC(@sql)
	---------------------------------------END Rodrigo Salazar-----------------------------------------------------------
	
	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
