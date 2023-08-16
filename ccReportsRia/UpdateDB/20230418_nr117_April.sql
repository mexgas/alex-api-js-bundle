SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 117

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	----------------------------------------------------- Begin B. Dunzz -----------------------------------------------------------------
	set @process = 'KR051000  Verifica si la columna telephone existe en la tabla RepCallbackQueue'
	set @sql = '
	IF NOT EXISTS (
		SELECT *
		FROM 
			INFORMATION_SCHEMA.COLUMNS
		WHERE 
			COLUMN_NAME = ''telephone''
			AND TABLE_NAME = ''RepCallbackQueue''
	)
	BEGIN 
		ALTER TABLE RepCallbackQueue
		ADD telephone varchar(20);
	END
	'
	EXEC(@sql)

	
	set @process = 'KR051000 ccspRepCallbackQueue DROP SP'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepCallbackQueue'')
	begin
        DROP PROCEDURE ccspRepCallbackQueue;
    end
	'
	EXEC(@sql)


	set @process = 'KR051000 ccspRepCallbackQueue CREATE SP'
	set @sql = '
		CREATE PROCEDURE [dbo].[ccspRepCallbackQueue]
		@action as tinyint,
		@from as datetime = null,
		@to as datetime = null
		AS

		set nocount on
		set ansi_nulls off
		set ANSI_WARNINGS off

		if @from is null
			select @from = convert(datetime,convert(varchar(11),getdate()))
		if @to is null
			select @to = getdate()

		if @action = 1
		begin
			delete from RepCallbackQueue with(rowlock) where [date] >= @from and [date] < @to

			insert into RepCallbackQueue ([date], calid, CALANI, inboundCampaignId, inboundCampaign, retry, xferDate, duration, [year], [mounth], [day], [hour], [minutes], telephone)
			select 
			a.datestamp, 
			a.cal_id, 
			a.CAL_ANI, 
			a.inbound_id, 
			c.descripcion, 
			a.retry, 
			a.xferDate, 
			b.cal_tDialog, 
			datepart(yy,convert(datetime,a.datestamp)) as [year], 
			datepart(mm,convert(datetime,a.datestamp)) as [mounth],
			datepart(dd,convert(datetime,a.datestamp)) as [day],
			datepart(hh,convert(datetime,a.datestamp)) as [hour],
			datepart(mi,convert(datetime,a.datestamp)) as [minutes],
			b.cal_ANI
			from ccRIACallBack_Queue as a 
			left join ccCallsIn as b on a.cal_id = b.cal_id 
			left join ccInbound as c on a.inbound_id = c.Inbound_id
			where a.datestamp >= @from and a.datestamp < @to
		end
	'
	EXEC(@sql)

	EXEC(@sql)

	set @process = 'CW-7888 DROP SP ccspTimesccLogAgentesDia'
	set @sql = '
		IF exists (select * from sys.procedures where name = N''ccspTimesccLogAgentesDia'')
		begin
			DROP PROCEDURE ccspTimesccLogAgentesDia;
		end
	'
	EXEC(@sql)

	set @process = 'CW-7888 CREATE SP ccspTimesccLogAgentesDia con Index'
	set @sql = '
		CREATE PROCEDURE [dbo].[ccspTimesccLogAgentesDia] @from AS SMALLDATETIME
	,@to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia'', N''U'') IS NOT NULL
	DROP TABLE #tempccLogAgentesDia

IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia2'', N''U'') IS NOT NULL
	DROP TABLE #tempccLogAgentesDia2

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = ''tmpccLogAgentesDia''
		)
BEGIN
	CREATE TABLE tmpccLogAgentesDia (
		id INT NOT NULL IDENTITY PRIMARY KEY
		,userId INT NOT NULL
		,TipoStatusAge_id TINYINT NOT NULL
		,tStatus FLOAT NOT NULL
		,dateIni DATETIME NOT NULL
		,dateEnd DATETIME NOT NULL
		,currentStatus INT NOT NULL
		,timeGroup DATETIME NOT NULL
		,timeGroupNext DATETIME NOT NULL
		,camId SMALLINT
		,camType SMALLINT
		,callId INT
		);
END
ELSE
BEGIN
	TRUNCATE TABLE tmpccLogAgentesDia
		--drop table tmpccLogAgentesDia
END

IF EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_tmpccLogAgentesDia_TipoStatusAge_id'')   
DROP INDEX IX_tmpccLogAgentesDia_TipoStatusAge_id ON [dbo].[tmpccLogAgentesDia] 

CREATE NONCLUSTERED INDEX [IX_tmpccLogAgentesDia_TipoStatusAge_id]
ON [dbo].[tmpccLogAgentesDia] ([TipoStatusAge_id])
INCLUDE ([tStatus],[timeGroupNext])

CREATE TABLE #tempccLogAgentesDia (
	row INT NOT NULL
	,user_id INT NOT NULL
	,TipoStatusAge_id TINYINT NOT NULL
	,tStatus FLOAT NOT NULL
	,dateIni DATETIME NOT NULL
	,dateEnd DATETIME NOT NULL
	,currentStatus INT
	,timeGroup DATETIME NOT NULL
	,timeGroupNext DATETIME NOT NULL
	,camId SMALLINT
	,camType SMALLINT
	,callId INT
	);;

WITH tmpLog
AS (
	SELECT User_id AS userId
		,TipoStatusAge_id
		,tStatus
		,DATEADD(ss, - tStatus, fecha) dateIni
		,fecha dateEnd
		,ISNULL(currentStatus, 0) AS currentStatus
		,dbo.GetTimeGroup(DATEADD(ss, - tStatus, fecha), 0) AS timegroup
		,dbo.GetTimeGroup(fecha, 1) AS timegroup_next
		,IdCampEsp AS camId
		,Tipo AS camType
		,callId
	FROM ccLogAgentesDia
	WHERE DATEADD(ss, - tStatus, fecha) BETWEEN @from AND @to 
	)
INSERT INTO #tempccLogAgentesDia
SELECT ROW_NUMBER() OVER (
		PARTITION BY userId ORDER BY dateIni
		) AS Row
	,userId
	,TipoStatusAge_id
	,tStatus
	,dateIni
	,dateEnd
	,currentStatus
	,timegroup
	,timegroup_next
	,camId
	,camType
	,callId
FROM tmpLog

DELETE A
FROM (
	SELECT CASE WHEN A.tStatus > S.tStatus THEN S.row ELSE A.row END row
		,A.user_id
	FROM #tempccLogAgentesDia A
	LEFT JOIN #tempccLogAgentesDia S ON A.Row = S.Row - 1
		AND A.user_id = S.user_id
	WHERE A.dateIni >= @from
		AND A.dateIni < @to
		AND A.TipoStatusAge_id = S.TipoStatusAge_id
		AND (
			S.dateEnd BETWEEN A.dateIni
				AND A.dateEnd
			OR S.dateIni BETWEEN A.dateIni
				AND A.dateEnd
			)
		AND ABS(DATEDIFF(ss, A.dateEnd, S.dateIni)) > 1
	) x
INNER JOIN #tempccLogAgentesDia A ON A.row = x.row
	AND A.user_id = x.user_id;

-----------Se agrega el estado actual
DECLARE @dateNow DATETIME
	,@date DATE
	,@maxLogout DATETIME;

SET @dateNow = GETDATE();

SELECT @maxLogout = MAX(logout)
FROM TmpSessionTimeGroup;

IF CONVERT(DATE, @dateNow, 121) = CONVERT(DATE, @to, 121)
BEGIN

	declare @today date

	set @today=convert(DATE, @to, 121)
		;

	WITH tempAgentLastStatus
	AS (
		SELECT User_id AS userId
			,MAX(fecha) AS fecha
		FROM ccLogAgentesDia
		WHERE fecha BETWEEN @today AND @to
		GROUP BY User_id
		)		

	INSERT INTO #tempccLogAgentesDia
	SELECT 0
		,A.user_id
		,A.currentStatus
		,DATEDIFF(ss, A.dateEnd, @dateNow) AS tStatus
		,A.dateEnd
		,@dateNow
		,A.currentStatus
		,dbo.GetTimeGroup(B.fecha, 0) AS timegroup
		,dbo.GetTimeGroup(@dateNow, 1) AS timegroup_next
		,A.camId
		,A.camType
		,A.callId
	FROM #tempccLogAgentesDia A
	INNER JOIN tempAgentLastStatus B ON A.dateEnd = B.fecha
		AND A.User_id = B.userId
	WHERE A.dateIni BETWEEN convert(DATE, @to, 121)
			AND @to
		AND A.currentStatus NOT IN (- 2, - 1, 0);
END

SELECT *
INTO #tempccLogAgentesDia2
FROM #tempccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15

DELETE #tempccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15;

INSERT INTO #tempccLogAgentesDia
SELECT 1
	,t.user_id
	,TipoStatusAge_id
	,dbo.TimeInterval(th.start, th.stop, dateIni, dateEnd) AS tStatus
	,dateIni
	,dateEnd
	,currentStatus
	,th.start AS timegroup
	,th.stop AS timegroup_next
	,t.camId
	,t.camType
	,t.callId
FROM #tempccLogAgentesDia2 t
INNER JOIN TmpTimesInterval th ON (
		t.timegroup > th.Start
		AND t.timegroup < th.stop
		)
	OR th.Start BETWEEN t.timegroup
		AND t.timeGroupNext
WHERE DATEDIFF(ss, th.start, timeGroupNext) > 0
	AND th.Start BETWEEN @from
		AND @to;

INSERT INTO tmpccLogAgentesDia (
	userId
	,TipoStatusAge_id
	,tStatus
	,dateIni
	,dateEnd
	,currentStatus
	,timeGroup
	,timeGroupNext
	,camId
	,camType
	,callId
	)
SELECT user_id AS userId
	,TipoStatusAge_id
	,SUM(tStatus) tStatus
	,MIN(dateIni) dateIni
	,MIN(dateEnd) dateEnd
	,currentStatus
	,timeGroup
	,timeGroupNext
	,min(camId) AS camId
	,min(camType) AS camType
	,min(callId) AS callId
FROM #tempccLogAgentesDia
GROUP BY timeGroup
	,user_id
	,TipoStatusAge_id
	,currentStatus
	,timeGroupNext
ORDER BY dateIni
	,userId

IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia'', N''U'') IS NOT NULL
	DROP TABLE #tempccLogAgentesDia

IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia2'', N''U'') IS NOT NULL
	DROP TABLE #tempccLogAgentesDia2
	'
	EXEC(@sql)

	----------------------------------------------------- END B. Dunzz -----------------------------------------------------------------

-------------------------------------------- Daniel Hernandez y Jesus Gallardo CW-7842 Zendere------------------------------
		
	
	set @process = 'ALTER SP ccspRepOutDialDetail FIX-It was fixed the source of the cal_key from ccocallsout to ccoLogDials, to ensure that the cal_key is correct regardless of the dialing result'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail] 
@action AS TINYINT, 
@from AS   DATETIME = NULL, 
@to AS     DATETIME = NULL
AS
SET NOCOUNT ON

IF @from IS NULL
	SELECT @from =CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE())) - 15
if @to is null
	SELECT @to = GETDATE()

IF @action = 1
BEGIN  

DECLARE @country SMALLINT
SELECT @country = valor
FROM ccSettings
WHERE setting_id = 104

--Borrar lo que esta para no repetir          
DELETE FROM RepOutDialDetail WHERE date >= @from            AND date < @to
        
	IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL drop table #dials
	IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL drop table #codeSip;
	IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL drop table #relationCodeSip;

	SELECT	dial.logDial_id
		,dial.callout_id
		,dial.cam_id
		,CASE WHEN dial.canceledNoAgents = 1 THEN 14 ELSE dial.tipoResDial_id END AS tipoResDial_id
		,ISNULL(tr.descripcion ,'''') as resultDialDesc
		,dial.Telefono
		,dial.Puerto
		,dial.fecha
		,dial.tDialing
		,CASE WHEN dial.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview'' 
			  WHEN LEFT(dial.TipoDialingMode, 1) = ''1'' THEN ''systemTranslated_Assisted'' 
			  WHEN RIGHT(dial.TipoDialingMode, 2) = ''00'' THEN ''systemTranslated_Auto'' 
			  WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' END AS dialType			  
		,dial.tBusy
		,dial.answerbit
		,dial.canceledNoAgents
		,dial.cal_id
		,dial.disconnectCause
		,isnull(co.cal_key,dial.cal_key) cal_key 
		,co.file_moved
		,dial.tipoLlamada_id
		,tco.[Description] AS CallDisposition
		,tsco.califSubDesc
		,CASE WHEN dial.disconnectCause <> '''' THEN SUBSTRING(dial.disconnectCause, 21, 3) ELSE '''' END codeSip
		,case when @country<>1 then '''' WHEN dial.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo'' 
			WHEN dial.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone'' ELSE ''systemTranslated_Indefinite'' END TipoTel
		,ISNULL(regp.tPreview,'''') as tpreview
		,co.User_id as UserID
	INTO #dials
	FROM ccoLogDials dial(NOLOCK)
	LEFT JOIN ccocallsout co(NOLOCK) ON dial.cal_id = co.cal_id
	LEFT JOIN cctipocalifout tco WITH (NOLOCK) ON tco.calif_id = co.calif_id
	LEFT JOIN cctipocalifsubout tsco WITH (NOLOCK) ON tsco.califSub_id = co.califSub_id
	LEFT JOIN RegProcessPreviewRecord regp WITH (NOLOCK) ON regp.callout_id = co.callout_id and regp.callId = co.cal_id
	LEFT JOIN cctipoResultadoDial tr(NOLOCK) ON dial.tipoResDial_id = tr.tiporesdial_id
	WHERE fecha >= @from AND fecha < @to
	union
	(
	select 
			''''
			,reg.callout_id
			,ccoa.cam_id
			,reg.process
			,ISNULL(cctyp.translatedDesc,'''')
			,ccoa.cal_telefono
			,''''
			,reg.reg_date
			,''''
			,''systemTranslated_Preview'' 		  
			,''''
			,''''
			,''''
			,''''
			,''''
			,ccoa.cal_Key
			,''''
			,''''
			,''''
			,''''
			,''''
			,''''	
			,reg.tPreview
			,reg.userId 
	FROM RegProcessPreviewRecord reg(NOLOCK)
	left join ccoCallsOutSource ccoa (NOLOCK) ON reg.callout_id = ccoa.callout_id
	left join ccTypeProcessPreview cctyp (NOLOCK) ON  cctyp.typeProcess_id = reg.process
	WHERE reg.reg_date >= @from AND reg.reg_date < @to AND reg.process !=7
	)

		select distinct cast(codeSip as int) as codeSip,disconnectCause into #codeSip from #dials where codeSip<>'''' and IsNumeric(codeSip)=1
	
		select A.codeSip,A.disconnectCause,B.description into #relationCodeSip from #codeSip A
		inner join DC_Extra B on A.codeSip=B.id

--Inserta informacon de reporte  
	INSERT INTO RepOutDialDetail
		SELECT fecha as [date]
		,case when dials.cal_key is null or  cs.cal_key is null then '''' when dials.cal_key is not null then dials.cal_key else cs.cal_key end cal_key
		,telefono telephone
		,dials.tiporesdial_id as tiporesdialId
		,CASE WHEN dials.tipoResDial_id = 14 THEN ''systemTranslated_CancelledBySystem'' ELSE ISNULL(dials.resultDialDesc, '''') END AS dialResult
		,dials.[cam_id] campaignId
		,ISNULL(RTRIM(LTRIM(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') AS campaign
		,dials.tbusy AS timeMessage
		,DATEPART(yyyy, fecha) year	
		,DATEPART(mm, fecha) month	
		,DATEPART(dd, fecha) day	
		,DATEPART(hh, fecha) hour	
		,DATEPART(mi, fecha) minutes
		,ISNULL(rl.name, '''') listName
		,CASE WHEN answerbit = 1 THEN ''systemTranslated_Charged'' ELSE ''systemTranslated_NotCharged'' END AS billed
		,ISNULL(cs.Dato1, '''') AS data1
		,ISNULL(cs.Dato2, '''') AS data2
		,ISNULL(cs.Dato3, '''') AS data3
		,ISNULL(cs.Dato4, '''') AS data4
		,ISNULL(cs.Dato5, '''') AS data5
		,CASE WHEN dials.[file_moved] = 1 THEN ''systemTranslated_Remoto'' ELSE ''Local'' END AS fileMoved
		,dials.disconnectCause
		,COALESCE(dat.description, descripcion, ''N/A'') DCCustomer
		,dials.dialType
		,TipoTel
		,ISNULL(CallDisposition, ''N/A'') AS CallDisposition
		,ISNULL(califSubDesc, ''N/A'') AS CallSubDisposition
		,ISNULL(csP.Dato6, '''') AS data6
		,ISNULL(csP.Dato7, '''') AS data7
		,ISNULL(csP.Dato8, '''') AS data8
		,ISNULL(csP.Dato9, '''') AS data9
		,ISNULL(csP.Dato10, '''') AS data10
		,ISNULL(csP.Dato11, '''') AS data11
		,ISNULL(csP.Dato12, '''') AS data12
		,ISNULL(csP.Dato13, '''') AS data13
		,ISNULL(csP.Dato14, '''') AS data14
		,ISNULL(csP.Dato15, '''') AS data15
		,dials.tpreview AS preview_Time
		,ISNULL(us.Login,'''')
	FROM #dials as dials
	LEFT JOIN ccoCallsOutSource cs(NOLOCK) ON dials.callout_id = cs.callout_id
	LEFT JOIN cctipoResultadoDial tr(NOLOCK) ON dials.tiporesdial_id = tr.tiporesdial_id
	LEFT JOIN ccCamps camps(NOLOCK) ON camps.[cam_id] = dials.[cam_id]
	LEFT JOIN ccRIARegistryLists rl(NOLOCK) ON cs.list_id = rl.list_id
	LEFT JOIN #relationCodeSip dat ON dat.disconnectCause = dials.disconnectCause
	LEFT JOIN ccoCallsPreviewData csP ON (dials.cal_Key = csP.cal_Key AND dials.cam_id = csP.cam_id)
	LEFT JOIN ccUsers us (NOLOCK) ON  us.User_id = dials.UserID

	IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL drop table #dials
	IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL drop table #codeSip;
	IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL drop table #relationCodeSip;
END'
	EXEC(@Sql)	
-------------------------------------------------------------------------------------------------------------------


------------------------------------------- Begin Roberto Nava ------------------------------------------------------
SET @process = 'CW-7976 Se agregan columnas nuevas para RepIVRDetails (ivrName)'
SET @sql = '
	IF NOT EXISTS
	(
		SELECT *
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''RepIVRDetail''
		AND COLUMN_NAME = ''ivrName''
	)
	BEGIN
		ALTER TABLE RepIVRDetail
		ADD ivrName VARCHAR(50) NULL
	END
'
EXEC(@sql)

SET @process = 'CW-7976 Se agregan columnas nuevas para RepIVRDetails (callStatus)'
SET @sql = '
	IF NOT EXISTS
	(
		SELECT *
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''RepIVRDetail''
		AND COLUMN_NAME = ''callStatus''
	)
	BEGIN
		ALTER TABLE RepIVRDetail
		ADD callStatus VARCHAR(50) NULL
	END
'
EXEC(@sql)

SET @process = 'CW-7976 Se agregan columnas nuevas para RepIVRDetails (IVR_ID)'
SET @sql = '
	IF NOT EXISTS
	(
		SELECT *
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''RepIVRDetail''
		AND COLUMN_NAME = ''IVR_ID''
	)
	BEGIN
		ALTER TABLE RepIVRDetail
		ADD IVR_ID INT NULL
	END
'
EXEC(@sql)

SET @process = 'CW-7976 Se agregan columnas nuevas (statusCallByIVR)'
SET @sql = '
	IF NOT EXISTS
	(
		SELECT *
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''RepInCallsDetail''
		AND COLUMN_NAME = ''statusCallByIVR''
	)
	BEGIN
		ALTER TABLE RepInCallsDetail
		ADD statusCallByIVR VARCHAR(50) NULL
	END
'
EXEC(@sql)


SET @process = 'CW-7976 Se agregan columnas nuevas (IVR_ID)'
SET @sql = '
	IF NOT EXISTS
	(
		SELECT *
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''RepInCallsDetail''
		AND COLUMN_NAME = ''IVR_ID''
	)
	BEGIN
		ALTER TABLE RepInCallsDetail
		ADD IVR_ID INT NULL
	END
'
EXEC(@sql)

SET @process = 'CW-7976 Se agregan columnas nuevas (callHung)'
SET @sql = '
	IF NOT EXISTS
	(
		SELECT *
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''RepInCallsDetail''
		AND COLUMN_NAME = ''callHung''
	)
	BEGIN
		ALTER TABLE RepInCallsDetail
		ADD callHung VARCHAR(50) NULL
	END
'
EXEC(@sql)


SET @process = 'CW-7976 Se agregan columnas nuevas (recibeCallBy)'
SET @sql = '
	IF NOT EXISTS
	(
		SELECT *
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''RepInCallsDetail''
		AND COLUMN_NAME = ''recibeCallBy''
	)
	BEGIN
		ALTER TABLE RepInCallsDetail
		ADD recibeCallBy VARCHAR(50) NULL
	END
'
EXEC(@sql)

SET @process = 'CW-8013 Almacenar en BD tiempo inicial y final de la llamada de entrada'
SET @sql = '
	IF NOT EXISTS
	(
		SELECT *
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''RepInCallsDetail''
		AND COLUMN_NAME = ''cal_final''
	)
	BEGIN
		ALTER TABLE RepInCallsDetail
		ADD cal_final DATETIME NULL
	END
'
EXEC(@sql)

SET @process = 'CW-7976 Validación para SP ccspRepIVRDetail para agregar datos de IVR a llamadas de entradas'
SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspRepIVRDetail'')
	BEGIN
	    DROP PROCEDURE ccspRepIVRDetail;
	END
'

EXEC(@sql)

SET @process = 'CW-7976 Generación del SP ccspRepIVRDetail para agregar datos de IVR'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccspRepIVRDetail]
	@action as tinyint,
	@from as datetime = null,
	@to as datetime = null
	AS

	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null
	select @to = getdate()

	if @action = 1 
		begin

		create table #IVRLlamadas(
		IVR_id int not null,
		cal_ani varchar(30) null,
		User_id smallint not null,
		calif_id smallint not null,
		cal_id int not null,
		date datetime not null,
		dnis varchar(50) not null,
		callStatus varchar(50) not null,
		tincall int not null
		)

		insert into #IVRLlamadas
		select A.Ivr_id, A.cal_ani, isnull(B.user_id,0) as [user_id], isnull(B.calif_id,0) as [calif_id],
		isnull(B.cal_id,0) as [cal_id], 
		ISNULL(B.cal_inicio, A.[date]) as date,
		ISNULL(A.dnis,'''') as dnis,
		case when ISNULL(B.cal_id,0) > 0 then ''systemTranslated_TransferredToACD'' else ''systemTranslated_AbandonedInIVR'' end as callStatus,
		ISNULL(A.tincall, 0) as tincall
		from IVRCallsIn as A with (nolock)
		left join ccCallsIn As B with(nolock) on  A.IVR_id = B.IVR_id
		where date >= @from and date < @to

		delete from RepIVRDetail with(rowlock) where date >= @from AND date < @to
		
		insert into RepIVRDetail
		select #IVRLlamadas.date as fecha, 
		cal_ani as telefono
		, isNull(u.nombres + '' '' + u.apellidopaterno + '' '' + u.apellidomaterno,'''') as nombre
		, isnull(calif.description, #IVRLlamadas.calif_id) as calificacion, cal_id as cal_id
		, isnull(
		(
			select
			case when selectedOption = '''' then ''''	else selectedOption + '',''	end
				from IVROptions with(nolock)
			where IVROptions.ivr_id = #IVRLlamadas.ivr_id
			order by IVROptions.date for xml path('''')
		),'''') as opciones	
		,#IVRLlamadas.tincall as tiempo,
		datepart(yyyy,[date]),
		datepart(mm,[date]),
		datepart(dd,[date]),
		datepart(hh,[date]),
		datepart(mi,[date]),
		dnis as DNIS,
		case when name is NULL then ''systemTranslated_NoName'' when name = '''' then ''systemTranslated_NoName'' else name end
		, callStatus
		, #IVRLlamadas.IVR_id
		from #IVRLlamadas
		left join
		(
			select ivr_id,name
			from IVROptions with(nolock)
			where date >= @from and date < @to
			group by ivr_id,name
		) optName on #IVRLlamadas.ivr_id = optName.ivr_id
		left join ccUserView u with(nolock) on (u.user_id = #IVRLlamadas.user_id)
		left join cctipocalif calif with(nolock) on (calif.calif_id = #IVRLlamadas.calif_id)
		where #IVRLlamadas.date >= @from and #IVRLlamadas.date < @to
		AND #IVRLlamadas.IVR_id > 0
		order by date
	
		drop table #IVRLlamadas

	end
'

EXEC(@sql)


SET @process = 'CW-7976 Validación para SP SupportReportCallInIVR para agregar datos de IVR a llamadas de entradas'
SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''SupportReportCallInIVR'')
	BEGIN
	    DROP PROCEDURE SupportReportCallInIVR;
	END
'

EXEC(@sql)

SET @process = 'CW-7976 Generación de un SP SupportReportCallInIVR para agregar datos de IVR a llamadas de entradas'
SET @sql = '
	CREATE PROCEDURE [dbo].[SupportReportCallInIVR] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
	AS

	SET NOCOUNT ON

	IF @from IS NULL
		SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

	IF @to IS NULL
		SELECT @to = getdate()

	IF @action = 1
	BEGIN

		INSERT INTO RepInCallsDetail (DATE, callid, inboundId, ACDGroup, callStatusId, callStatus, dispositionId, disposition, subDispositionId, subDisposition, dnisId, dnis, userId, [user], callKey, ANI, queueTime, xferTime, ringingTime, dialogTime, extension, agentName, whoHangUp, mohTime, year, month, day, hour, minutes, provedorId, provider, trunk, fileMoved, twrapup, AverageHandleTime, Dato1, Dato2, Dato3, Dato4, Dato5, grabId, nameDNI, numDNI, collectCall, timeTotalInCallSec, timeTotalInCallMin, statusCallByIVR, IVR_ID, callHung, recibeCallBy, cal_final)
		SELECT b.date, 
			0,--a.cal_id,
			0,--a.Inbound_id,
			'''' AS Inbound, 
			0,--a.statusCall_id, 
			'''' AS statusCall, 
			0,--a.calif_id, 
			'''' AS calif, 
			0,--ISNULL(a.califSub_id, 0), 
			'''' AS califSub, 
			'''',--a.dni_id, 
			B.dnis AS dni, 
			0,--a.user_id, 
			'''' AS [user], 
			'''' as cal_key, 
			B.telephone,--a.cal_ANI, 
			0,--cal_tWait, 
			0,--cal_tXfer, 
			0,--cal_tRing, 
			B.statusTime,--cal_tDialog, 
			0,--a.cal_extension, 
			'''' AS agentName,
			''systemTranslated_ClientSystem'' [whoHangUp], 
			0,--a.cal_tMoh, 
			DATEPART(yyyy, B.date) [year], 
			DATEPART(mm, B.date) [month], 
			DATEPART(dd, B.date) [day], 
			DATEPART(hh, B.date) [hour], 
			DATEPART(mi, B.date) [minute], 
			0,--di.provedor_id, 
			'''',--prov.descrip [Proveedor], 
			0,
			'''' AS file_Moved, 
			0,--cal_tNotas, 
			AverageHandleTime = 0, --cal_tNotas + cal_tDialog, 
			'''' AS Dato1, 
			'''' AS Dato2, 
			'''' AS Dato3, 
			'''' AS Dato4, 
			'''' AS Dato5, 
			0 AS grabId,
			ISNULL(dnis.dni_Descripcion,'''') AS nameDNI,
			ISNULL(dnis.dni_numero,'''') AS dni,
			CASE
					WHEN B.statusTime > 0 THEN ''Si''
					ELSE ''No''
			END AS collectCall,
			B.statusTime  AS timeTotalInCallSec,
			(FLOOR( ( B.statusTime )/ 60) + 
			CASE 
				WHEN CEILING( (B.statusTime ) % 60) != 0 THEN 1 
				ELSE 0 
			END) AS timeTotalInCallMin,
			CASE 
				WHEN B.callStatus IS NULL THEN ''systemTranslated_AbandonedInIVR''
				ELSE ''systemTranslated_AbandonedInIVR''
			END AS statusCallByIV,
			ISNULL(B.IVR_id,0) AS IVR,
			''systemTranslated_ClientSystem'' AS statusCallByIVR,
			''systemTranslated_SystemIVR'' AS [recibeCallBy],
			NULL AS cal_final
	FROM RepIVRDetail B
	LEFT JOIN ccdnis dnis on dnis.dni_numero=B.dnis
	WHERE B.date >= @from
			AND B.date < @to
			AND B.IVR_ID NOT IN(SELECT IVR_ID FROM RepInCallsDetail WHERE IVR_ID IS NOT NULL);

	END
'

EXEC(@sql)


SET @process = 'CW-7976 Se elimina SP ccspRepInCallsDetail'
SET @sql = '
	IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspRepInCallsDetail'')
	BEGIN
	    DROP PROCEDURE ccspRepInCallsDetail;
	END
'

EXEC(@sql)


SET @process = 'CW-7976 Llamadas IVR que no son transferidas a campañas de entrada'
SET @sql = '
	CREATE PROCEDURE [dbo].[ccspRepInCallsDetail] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
		AS

		SET NOCOUNT ON

		IF @from IS NULL
			SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

		IF @to IS NULL
			SELECT @to = getdate()

		IF @action = 1
		BEGIN

			DECLARE @tab TABLE (callId INT PRIMARY KEY, [Dato1] VARCHAR(255), [Dato2] VARCHAR(255), [Dato3] VARCHAR(255), [Dato4] VARCHAR(255), [Dato5] VARCHAR(255))
			DECLARE @fechaSUM DATETIME
			INSERT INTO @tab
			SELECT callId, [Dato 1], [Dato 2], [Dato 3], [Dato 4], [Dato 5]
			FROM (
				SELECT A.CallId, [Data], [Description]
				FROM DataCallIn A
				INNER JOIN ccCallsIn B ON A.CallId = B.cal_id
				WHERE b.cal_Inicio >= @from AND b.cal_Inicio < @to
				) AS SourceTable
			pivot(max([Data]) FOR [Description] IN ([Dato 1], [Dato 2], [Dato 3], [Dato 4], [Dato 5])) AS pvt

			--Borrar lo que esta para no repetir
			DELETE
			FROM RepInCallsDetail
			WHERE [date] >= @from AND [date] < @to

			
			INSERT INTO RepInCallsDetail (DATE, callid, inboundId, ACDGroup, callStatusId, callStatus, dispositionId, disposition, subDispositionId, subDisposition, dnisId, dnis, userId, [user], callKey, ANI, queueTime, xferTime, ringingTime, dialogTime, extension, agentName, whoHangUp, mohTime, year, month, day, hour, minutes, provedorId, provider, trunk, fileMoved, twrapup, AverageHandleTime, Dato1, Dato2, Dato3, Dato4, Dato5, grabId, nameDNI, numDNI, collectCall, timeTotalInCallSec, timeTotalInCallMin, statusCallByIVR, IVR_ID, callHung, recibeCallBy, cal_final)
			SELECT 
			   a.cal_inicio AS cal_ini, 
			   a.cal_id,
			   a.Inbound_id,
			   ISNULL(ccIn.descripcion, '''') AS Inbound, 
			   a.statusCall_id, 
			   ISNULL(statusLlamada.descripcion, '''') AS statusCall, 
			   a.calif_id, 
			   ISNULL(disposition.description, '''') AS calif, 
			   ISNULL(a.califSub_id, 0), 
			   ISNULL(subDisposition.califSubDesc, '''') AS califSub, 
			   a.dni_id, 
			   ISNULL(dnis.dni_numero, '''') AS dni, 
			   a.user_id, 
			   ISNULL(LOGIN, '''') AS [user], 
			   ISNULL(a.cal_key, '''') as cal_key, 
			   a.cal_ANI, 
			   cal_tWait, 
			   cal_tXfer, 
			   cal_tRing, 
			   cal_tDialog, 
			   a.cal_extension, 
			   ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno, '''') AS agentName,
			   CASE
				   WHEN a.cal_whoHung = 0
				   THEN ''systemTranslated_Client''
				   WHEN a.cal_whoHung = 1
				   THEN ''systemTranslated_Agent''
				   ELSE ''systemTranslated_AgentSurvey''
			   END [whoHangUp], 
			   a.cal_tMoh, 
			   DATEPART(yyyy, cal_inicio) [year], 
			   DATEPART(mm, cal_inicio) [month], 
			   DATEPART(dd, cal_inicio) [day], 
			   DATEPART(hh, cal_inicio) [hour], 
			   DATEPART(mi, cal_inicio) [minute], 
			   di.provedor_id, 
			   prov.descrip [Proveedor], 
			   a.cal_puerto,
			   CASE
				   WHEN a.file_moved = 1
				   THEN ''systemTranslated_Remoto''
				   ELSE ''Local''
			   END AS file_Moved, 
			   cal_tNotas, 
			   AverageHandleTime = cal_tNotas + cal_tDialog, 
			   ISNULL(tab.Dato1, '''') AS Dato1, 
			   ISNULL(tab.Dato2, '''') AS Dato2, 
			   ISNULL(tab.Dato3, '''') AS Dato3, 
			   ISNULL(tab.Dato4, '''') AS Dato4, 
			   ISNULL(tab.Dato5, '''') AS Dato5, 
			   ISNULL(rc.grab_id, 0) AS grabId,
			   ISNULL(dni_Descripcion, '''') AS nameDNI,
			   ISNULL(dnis.dni_numero, '''') AS dni,
			   CASE
					 WHEN statusLlamada.descripcion IS NOT NULL THEN ''Si''
					 ELSE ''No''
			   END AS collectCall,
			   CASE
					WHEN A.cal_final IS NULL THEN 0
					ELSE CAST( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) AS INT)
			   END AS timeTotalInCallSec,
			   CASE
					WHEN A.cal_final IS NULL THEN 0
					ELSE CAST( FLOOR( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) / 60 ) AS INT) 
			   END + 
			   CASE
					WHEN A.cal_final IS NULL THEN 0
					ELSE
						CASE
							WHEN CAST(CEILING( DATEDIFF(SECOND, A.cal_Inicio, A.cal_final) ) AS INT) % 60 != 0 THEN 1
							ELSE 0
						END
			   END AS timeTotalInCallMin,
			   CASE 
					WHEN a.IVR_id != 0 and ivrCIN.callStatus = ''systemTranslated_AbandonedInIVR'' THEN ''systemTranslated_AbandonedInIVR''
					WHEN a.statusCall_id = 13 THEN ''systemTranslated_Answered''
					WHEN a.statusCall_id != 13 THEN ''''
					ELSE ''''
				END AS statusCallByIVR,
				ISNULL(ivrCIN.IVR_ID, 0) AS IVR,
				CASE
					WHEN ivrCIN.callStatus = ''systemTranslated_AbandonedInIVR'' THEN ''systemTranslated_ClientSystem''
					ELSE ''''
				END AS statusCallByIVR,
				CASE
					WHEN ivrCIN.callid = a.cal_id THEN ''systemTranslated_SystemIVR''
					WHEN a.IVR_id = 0 THEN ''systemTranslated_CallInbound'' 
					ELSE ''''
				END AS [recibeCallBy], 
				ISNULL(a.cal_final, NULL) AS cal_final
		FROM cccallsin A   
			 LEFT JOIN ccoDialers di ON di.dialer_id = a.cal_puerto
			 LEFT JOIN cstoProvedor prov ON di.provedor_id = prov.provedor_id
			 LEFT JOIN @tab tab ON tab.callId = a.cal_id
			 LEFT JOIN Ria_grabacion rc ON rc.cal_id = a.cal_id and rc.tipo_llamada=1
			 LEFT JOIN ccInbound ccIn ON a.Inbound_id = ccIn.Inbound_id
			 LEFT JOIN ccstatusllamada statusLlamada ON a.statusCall_id = statusLlamada.statusCall_id
			 LEFT JOIN cctipocalif disposition ON a.calif_id = disposition.calif_id
			 LEFT JOIN cctipocalifsub subDisposition ON a.califSub_id = subDisposition.califSub_id
			 LEFT JOIN ccdnis dnis ON a.dni_id = dnis.dni_id
			 LEFT JOIN ccUserView ccuser ON a.User_id = ccuser.user_id
			 LEFT JOIN repIVRDetail ivrCIN ON a.IVR_id = ivrCIN.IVR_ID 
		WHERE a.cal_inicio >= @from
			  AND a.cal_inicio < @to


		EXEC SupportReportCallInIVR 1, @from, @to

		END

'

EXEC(@sql)

SET @process = 'CW-7976 Se agregan filtros para los reportes de llamada de entrada'
SET @sql = '
	UPDATE
		TranslatedReports
	SET
		columns = ''whoHangUp|fileMoved|recibeCallBy|statusCallByIVR''
	WHERE
		id = 3010
'

EXEC(@sql)

-------------------------------------------- END Roberto Nava -------------------------------------------------------


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
