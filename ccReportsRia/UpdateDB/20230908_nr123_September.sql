SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 123

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY


	SET @process = 'DEV2-253 DROP PROCEDURE ccspRepOutDialDetail'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccspRepOutDialDetail'')
    begin
        DROP PROCEDURE ccspRepOutDialDetail;
    end'
	EXEC(@sql)

	SET @process = 'DEV2-253 CREATE PROCEDURE ccspRepOutDialDetail'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccspRepOutDialDetail] 
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
	
		--Inserta informacon de reporte  
			INSERT INTO RepOutDialDetail
				SELECT fecha as [date]
				,case when dials.cal_key is null and cs.cal_key is null then '''' when dials.cal_key is not null then dials.cal_key else cs.cal_key end cal_key
				,ISNULL(telefono,'''') telephone
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
				,ISNULL(cs.Dato1, '''') AS data1
				,ISNULL(cs.Dato2, '''') AS data2
				,ISNULL(cs.Dato3, '''') AS data3
				,ISNULL(cs.Dato4, '''') AS data4
				,CASE WHEN dials.[file_moved] = 1 THEN ''systemTranslated_Remoto'' 
					WHEN dials.file_moved = 2 THEN ''systemTranslated_noRecordingCamp''
					ELSE ''Local'' END AS fileMoved
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
		END
	'
	EXEC(@sql)


	--------------------------------------------------------------------START HL----------------------------------------------------------------------------------------
	set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
		begin
			DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
		end'
	EXEC(@sql)
 
	SET @process = 'KR093000-add column callerAni into ccLogTransfers'
	SET @sql = 'if not exists (select * from sys.columns where name = N''callerAni'' and Object_ID = Object_ID(N''ccLogTransfers''))
		begin
			alter table ccLogTransfers add callerAni varchar(50) null
		end'
	EXEC(@sql)
 
	set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
	set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
			begin
				ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
			end'
	EXEC(@sql)

	SET @process = 'KR093000-add column clientPhoneNumber into RepCallXfer'
	SET @sql = 'if not exists (select * from sys.columns where name = N''clientPhoneNumber'' and Object_ID = Object_ID(N''RepCallXfer''))
		begin
			alter table RepCallXfer add clientPhoneNumber varchar(50) null
		end'
	EXEC(@sql)
	
	SET @process = 'KR093000-DROP PROCEDURE ccspRepCallXfer'
	SET @sql = 'if exists (select * from sys.procedures where name = N''ccspRepCallXfer'')
		begin
			DROP PROCEDURE ccspRepCallXfer;
		end'
	EXEC(@sql)

	SET @process = 'KR093000-CREATE PROCEDURE ccspRepCallXfer'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccspRepCallXfer]
					@action as tinyint,
					@from AS datetime = null,
					@to AS datetime = null
					AS

					SET NOCOUNT ON
		
					if @action = 1
					begin
						if @from is null
							select @from = convert(datetime,convert(varchar(11),getdate()))
						if @to is null	
							select @to = getdate()
		
						delete RepCallXfer with(rowlock)	where [date] between @from and @to
						
						insert RepCallXfer 
						select convert(varchar(10),fechafin,121) [date],
						clt.cal_id callid, case when tipo = 1 then ''systemTranslated_inbound'' else ''systemTranslated_outbound'' end CallTypes, 
						isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccUserView nolock where user_id = 
						(case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') Agent,	
						case when modo = 0 then ''systemTranslated_blindXfer'' 
						when modo = 1 then ''systemTranslated_Agent'' 
						when modo = 2 then 
							case when cast(clt.destino as int) >= 0 then ''systemTranslated_acd'' else ''systemTranslated_Survey'' end
						when modo = 3 then ''systemTranslated_conference'' 
						when modo = 4 then ''systemTranslated_supXfer'' 
						when modo in(5,6) then ''systemTranslated_overflow'' end as xfertype,
						case when modo = 0 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
						when modo = 1 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),''systemTranslated_Indefinite'') 
						when modo = 2 then 
							case when cast(clt.destino as bigint) >= 0 then
								isnull((select descripcion from ccinbound where inbound_id = clt.destino),''systemTranslated_Indefinite'') 
							else
								isnull((select top 1 description from survey where active=1 and scriptId = abs(cast(clt.destino as int))),''systemTranslated_Indefinite'') 
							end
						when modo = 3 then isnull((select nombre from telefonosConferencia where tel = clt.destino),clt.destino) 
						when modo = 4 then isnull((select top 1 nombre from telefonosTransferencia where tel = clt.destino),clt.destino) 
						when modo in(5,6) then  isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end destination,
						tantesxfer timebeforexfer,
						tdespuesxfer timeafterxfer,
						dateadd(ss,-(tantesxfer + tdespuesxfer),fechafin) startDate,
						fechafin as endDate,		
						case when camp.cam_descripcion is not null then  camp.cam_descripcion 
						when inbound.descripcion is not null then  inbound.descripcion				
						else ''systemTranslated_Indefinite'' end as Origin,
						tantesxfer+tdespuesxfer as TotalTimeDuration,				
						isnull((select case clt.tipoLlamada_id when 1 then ''systemTranslated_fijo''
							when 3 then ''systemTranslated_cellPhone'' else ''systemTranslated_interno'' end
							),''systemTranslated_Indefinite'') as TipoTel,
						(case tipo when 1 then ci.User_id else co.User_id end) User_ID,
						isnull(callerAni, '''')
						from cclogtransfers clt 
						left join ccocallsout co (nolock) on co.cal_id=clt.cal_id and tipo=2 
						left join cccallsin ci (nolock) on ci.cal_id=clt.cal_id and tipo=1
						left join cccamps camp on camp.cam_id =co.cam_id
						left join ccinbound inbound on inbound.Inbound_id =ci.Inbound_id
						WHERE fechafin >= @from and fechafin < @to
					end'
	EXEC(@sql)
	---------------------------------------------------------------------END HL-----------------------------------------------------------------------------------------

	
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
