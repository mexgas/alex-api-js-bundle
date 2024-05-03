/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCReportsRIA
Required version: 128

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
SET @version = 132 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
	----------------------------------------------- Ulises Espinosa Begin ----------------------------------------------------------------------------------
	set @process = 'KR140001 - se modifica sp ccspRepOutDialDetail'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail] 
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

	DELETE FROM RepOutDialDetail WHERE date >= @from AND date < @to
        
    IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL drop table #dials
    IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL drop table #codeSip;
    IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL drop table #relationCodeSip;

    SELECT  dial.logDial_id
        ,dial.callout_id
        ,dial.cam_id
        ,CASE WHEN dial.canceledNoAgents = 1 THEN 14 ELSE dial.tipoResDial_id END AS tipoResDial_id
        ,ISNULL(tr.descTranslate ,'''') as resultDialDesc
        ,dial.Telefono
        ,dial.Puerto
        ,dial.fecha
        ,dial.tDialing
        ,CASE WHEN dial.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview'' 
              WHEN dial.TipoDialingMode =  ''10000000'' THEN ''systemTranslated_Assisted'' 
			  WHEN RIGHT(dial.TipoDialingMode,5) IN (''01000'',''10000'') THEN ''systemTranslated_Callback''
              WHEN RIGHT(dial.TipoDialingMode, 2) = ''00'' THEN ''systemTranslated_Auto'' 
              WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' END AS dialType            
        ,dial.tBusy
        ,dial.answerbit
        ,dial.canceledNoAgents
        ,dial.cal_id
        ,dial.disconnectCause
        ,co.cal_key
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
    left join ccoCallsOut ccoa (NOLOCK) ON reg.callout_id = ccoa.callout_id
    left join ccTypeProcessPreview cctyp (NOLOCK) ON  cctyp.typeProcess_id = reg.process
    WHERE reg.reg_date >= @from AND reg.reg_date < @to AND reg.process not in (5,7,13,14)
    )

	select distinct cast(codeSip as int) as codeSip,disconnectCause into #codeSip from #dials where codeSip<>'''' and IsNumeric(codeSip)=1

	select A.codeSip,A.disconnectCause,B.description into #relationCodeSip from #codeSip A
	inner join DC_Extra B on A.codeSip=B.id


    INSERT INTO RepOutDialDetail
        SELECT fecha as [date]
        ,case when dials.cal_key is null and cs.cal_key is null then '''' when dials.cal_key is not null then dials.cal_key else cs.cal_key end cal_key
        ,ISNULL(dials.Telefono,'''') telephone
        ,dials.tiporesdial_id as tiporesdialId
        ,CASE WHEN dials.tipoResDial_id = 14 THEN 
                CASE WHEN camps.campType = 6 THEN ''systemTranslated_CancelledByEngaged'' ELSE ''systemTranslated_CancelledBySystem'' END
            ELSE ISNULL(dials.resultDialDesc, '''') END AS dialResult
        ,ISNULL(dials.[cam_id],'''')campaignId
        ,ISNULL(RTRIM(LTRIM(camps.cam_descripcion)),''systemTranslated_NoCampaign'') AS campaign
        ,dials.tbusy AS timeMessage
        ,DATEPART(yyyy, fecha) year 
        ,DATEPART(mm, fecha) month  
        ,DATEPART(dd, fecha) day    
        ,DATEPART(hh, fecha) hour   
        ,DATEPART(mi, fecha) minutes
        ,ISNULL(rl.name, '''') listName
        ,CASE WHEN answerbit = 1 THEN ''systemTranslated_Charged'' ELSE ''systemTranslated_NotCharged'' END AS billed
        ,ISNULL(ldd.Data1,ISNULL(cs.Dato1, '''')) AS data1
        ,ISNULL(ldd.Data2,ISNULL(cs.Dato2, '''')) AS data2
        ,ISNULL(ldd.Data3,ISNULL(cs.Dato3, '''')) AS data3
        ,ISNULL(ldd.Data4,ISNULL(cs.Dato4, '''')) AS data4
		,ISNULL(ldd.Data5,ISNULL(cs.Dato5, '''')) AS data5
        ,CASE WHEN dials.[file_moved] = 1 THEN ''systemTranslated_Remoto'' 
            WHEN dials.file_moved = 2 THEN ''systemTranslated_noRecordingCamp''
            ELSE ''systemTranslated_Local'' END AS fileMoved
		,dials.disconnectCause
        ,COALESCE(dat.description, descTranslate, ''N/A'') DCCustomer
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
	LEFT JOIN ccoLogDialsData ldd (NOLOCK) on ldd.logDial_id = dials.logDial_id
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
	EXEC(@sql)

	set @process = 'KR140002 - se modifica sp ccspRepOutCallsDetail'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail] 
@action as tinyint,
@from as datetime = NULL,
@to as datetime = NULL
AS

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

DECLARE @IVA INT, @IVAstring varchar(3)
DECLARE @country AS TINYINT

SELECT @IVA = convert(INT, isnull(valor, 0))
FROM ccsettings
WHERE setting_id = 25

SELECT @IVAstring =CONVERT(VARCHAR(5),@IVA) + ''%''

SELECT @country = convert(TINYINT, isnull(valor, 1))
FROM ccsettings
WHERE setting_id = 104

IF @country IS NULL
	SET @country = 1

IF @action = 1
BEGIN
	DELETE FROM RepOutCallsDetail WITH (ROWLOCK)
	WHERE DATE >= @from AND DATE < @to

	INSERT INTO RepOutCallsDetail
	SELECT Call.cal_inicio AS [date],
		Call.cal_key AS [callKey],
		Call.cal_telefono AS [telephone],
		Call.cal_txfer + call.cal_tring AS [transfer],
		Call.cal_tdialog AS [dialog],
		ISNULL(Call.cal_tMoh, 0) AS [nque],
		Call.cal_tnotas AS [wrapup],
		ISNULL(Tipo.[description], '''') AS [CallDisposition],
		Call.cal_extension AS [extension],
		isnull(Usr.user_id, 0) AS [userId],
		ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''')[login],
		ISNULL(convert(VARCHAR(255), Usr.LOGIN), ''systemTranslated_NoUserName'')  AS [username],
		camps.cam_id AS [campaignId],
		ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
		(CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60) AS [duration],
		CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country)) AS [ncost],

		@IVAstring AS iva,
		CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country) * (1 + (@IVA / 100.00))) AS total,
		CASE 
			WHEN prov.descrip IS NOT NULL THEN prov.descrip
			ELSE ''systemTranslated_NoCarrier'' 
		END AS [ByCarrier],
		case 
			when @country<>1 then '''' 
			WHEN ld.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo'' 
			WHEN ld.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone'' 
			ELSE ''systemTranslated_Indefinite'' END [Calltypes],
		CASE 
		WHEN ld.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview'' 
		WHEN ld.TipoDialingMode =  ''10000000'' THEN ''systemTranslated_Assisted'' 
		WHEN ld.TipoDialingMode IN (''00001000'',''00010000'', ''000010000'') THEN ''systemTranslated_Callback'' 
		WHEN RIGHT(ld.TipoDialingMode, 3) = ''100'' THEN ''systemTranslated_Auto'' 
		WHEN RIGHT(ld.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' 
		WHEN ld.TipoDialingMode = ''000000000'' THEN ''systemTranslated_Auto''
		ELSE ''''
		END AS [dialType], 
		CASE 
			WHEN Call.cal_whoHung = 0 THEN ''systemTranslated_Client'' 
			WHEN Call.cal_whoHung = 1 THEN ''systemTranslated_Agent'' 
			ELSE ''systemTranslated_AgentSurvey'' 
		END [whoHangUp], 
		CASE 
			WHEN call.califsub_id = 0 THEN ''systemTranslated_NoSubDisposition'' 
			ELSE isnull(sub.califSubDesc, '''') 
		END AS [subDisposition],
		sta.descTranslated AS [dialResult], 
		Call.cal_id as [calId],
		datepart(yyyy, Call.cal_inicio) AS [year],
		datepart(mm, Call.cal_inicio) AS [month],
		datepart(dd, Call.cal_inicio) AS [day],
		datepart(hh, Call.cal_inicio) AS [hour],
		datepart(mi, Call.cal_inicio) AS [minutes],
		Call.cal_puerto,
		ISNULL(cod.Data1,ISNULL(cs.Dato1, '''')) AS [data1],
		ISNULL(cod.Data2,ISNULL(cs.Dato2, '''')) AS [data2],
		ISNULL(cod.Data3,ISNULL(cs.Dato3, '''')) AS [data3],
		ISNULL(cod.Data4,ISNULL(cs.Dato4, '''')) AS [data4],
		ISNULL(cod.Data5,ISNULL(cs.Dato5, '''')) AS [data5],
		ISNULL(Call.cal_tMsg, 0) AS [MessageTime],
		ISNULL(rc.grab_id, 0) as grabId
	FROM ccoCallsOut Call (nolock)
		LEFT JOiN ccoLogDials ld (nolock) ON Call.cal_id=ld.cal_id
		LEFT JOIN ccTipoCalifOUT Tipo (nolock) ON Call.calif_id = Tipo.calif_id
		LEFT JOIN ccUserView Usr (nolock) ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
		LEFT JOIN ccCamps camps (nolock) ON camps.[cam_id] = Call.[cam_id]
		LEFT JOIN ccStatusLlamada sta (nolock) ON call.statuscall_id = sta.statuscall_id
		LEFT JOIN cstoProvedor prov (nolock) ON prov.[provedor_id] = Call.[provedor_id]
		LEFT JOIN cstoTipoLlamada tl (nolock) ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] AND tl.Country_id = @country)
		LEFT JOIN ccTipoCalifSubOut sub (nolock) ON call.califsub_id = sub.califsub_id
		LEFT JOIN ccoDialers di (nolock) ON di.dialer_id = Call.cal_puerto AND call.provedor_id = di.provedor_id
		LEFT JOIN ccoCallsOutSource cs (nolock) ON Call.callout_id = cs.callout_id
		LEFT JOIN ccoCallsOutData cod (NOLOCK) on cod.cal_id = call.cal_id
		LEFT JOIN ccCallCost_RIA cc (nolock) ON cc.country_id = tl.country_id AND cc.tipoLlamada_id = tl.tipoLlamada_id
		LEFT JOIN Ria_grabacion rc (nolock) on (rc.cal_id = Call.cal_id and rc.tipo_llamada = 2)
	WHERE Call.cal_inicio >= @from AND Call.cal_inicio < @to AND Call.cal_manual IN (0, 2) and ld.TipoDialingMode IS NOT NULL
	ORDER BY DATE
END'
	EXEC(@sql)
	-------------------------------------------------- END MACL -----------------------------------------------------------------------------------

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
