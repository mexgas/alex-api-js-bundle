SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 121

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

---------------------------------------BEGIN KR091000 Setting grabar llamadas por campaña ---------------------------------------------------------
	set @process = 'KR091000 '
	set @Sql= ''
	EXEC(@Sql)	

	
	SET @process = 'KR091000 Alter Column ccoCallsout.file_moved tinyint'
	SET @sql = 'if exists (SELECT COLUMN_NAME, DATA_TYPE 
	FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = ''ccoCallsout'' and COLUMN_NAME=''file_moved'' and DATA_TYPE=''bit''
	)
	begin
	    alter table ccoCallsout alter column file_moved tinyint;
	end'
	EXEC(@sql)

	SET @process = 'KR091000 Alter Column ccCallsIn.file_moved tinyint'
	SET @sql = 'if exists (SELECT COLUMN_NAME, DATA_TYPE 
	FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = ''ccCallsIn'' and COLUMN_NAME=''file_moved'' and DATA_TYPE=''bit''
	)
	begin
	    alter table ccCallsIn alter column file_moved tinyint;
	end'
	EXEC(@sql)

	set @process = 'KR091000 Alter SP ccspRepInCallsDetail add WHEN a.file_moved = 2 THEN ''systemTranslated_noRecordingCamp'''
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepInCallsDetail] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS

SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	DECLARE @tab TABLE (callId INT PRIMARY KEY, [Dato1] VARCHAR(255), [Dato2] VARCHAR(255), [Dato3] VARCHAR(255), [Dato4] VARCHAR(255), [Dato5] VARCHAR(255))

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
	WHERE DATE >= @from AND DATE < @to

	INSERT INTO RepInCallsDetail (DATE, callid, inboundId, ACDGroup, callStatusId, callStatus, dispositionId, disposition, subDispositionId, subDisposition, dnisId, dnis, userId, [user], callKey, ANI, queueTime, xferTime, ringingTime, dialogTime, extension, agentName, whoHangUp, mohTime, year, month, day, hour, minutes, provedorId, provider, trunk, fileMoved, twrapup, AverageHandleTime, Dato1, Dato2, Dato3, Dato4, Dato5, grabId, nameDNI, numDNI, collectCall, timeTotalInCallSec, timeTotalInCallMin)
	SELECT cal_inicio, 
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
		cal_ANI, 
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
			WHEN a.file_moved = 1 THEN ''systemTranslated_Remoto''
			WHEN a.file_moved = 2 THEN ''systemTranslated_noRecordingCamp''
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
		( CAST(cal_tDialog AS INT) + CAST(cal_tXfer AS INT) + CAST(cal_tWait AS INT) + CAST(cal_tRing AS INT)) AS timeTotalInCallSec,
		(FLOOR( ( CAST(cal_tDialog AS INT) + CAST(cal_tXfer AS INT) + CAST(cal_tWait AS INT) + CAST(cal_tRing AS INT) )/ 60) + 
			CASE 
				WHEN CEILING(( CAST(cal_tDialog AS INT) + CAST(cal_tXfer AS INT) + CAST(cal_tWait AS INT) + CAST(cal_tRing AS INT) ) % 60) != 0 THEN 1 
				ELSE 0 
			END) AS timeTotalInCallMin
FROM cccallsin a
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
WHERE cal_inicio >= @from
		AND cal_inicio < @to;

END
	'
	EXEC(@Sql)	

	set @process = 'KR091000 Alter SP ccspRepOutDialDetail add WHEN dials.file_moved = 2 THEN ''systemTranslated_noRecordingCamp'''
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
		,CASE WHEN dials.[file_moved] = 1 THEN ''systemTranslated_Remoto'' 
			WHEN dials.file_moved = 2 THEN ''systemTranslated_noRecordingCamp''
			ELSE ''Local'' END AS fileMoved
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

	set @process = 'KR091000 '
	set @Sql= ''
	EXEC(@Sql)	

	set @process = 'KR091000 '
	set @Sql= ''
	EXEC(@Sql)	

	set @process = 'KR091000 '
	set @Sql= ''
	EXEC(@Sql)	

	set @process = 'KR091000 '
	set @Sql= ''
	EXEC(@Sql)	
---------------------------------------END KR091000 Setting grabar llamadas por campaña ---------------------------------------------------------
	
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
