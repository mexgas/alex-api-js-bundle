/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K089000

Database: CCenterRia
Required version: 125.37

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
SET @versionfix = 0
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

        ----------------------------------------------------- BEGIN Fri ----------------------------------------------------------------
		SET @process = 'KR110000 ADD COLUMN recordsNotLoadedPort'
        SET @sql = '
		if not exists (select * from sys.columns where name = N''recordsNotLoadedPort'' and Object_ID = Object_ID(N''ccRIALoading''))
		begin
			alter table ccRIALoading add recordsNotLoadedPort int null
		end'
        EXEC(@sql);

		SET @process = 'KR110000 ADD COLUMN phonesNotLoadedPort '
        SET @sql = '
		if not exists (select * from sys.columns where name = N''phonesNotLoadedPort'' and Object_ID = Object_ID(N''ccRIALoading''))
		begin
			alter table ccRIALoading add phonesNotLoadedPort int null
		end'
        EXEC(@sql);

		SET @process = 'KR110000 ADD COLUMN INTERNATIONAL'
        SET @sql = '
		if not exists (select * from sys.columns where name = N''international'' and Object_ID = Object_ID(N''ccoCallsOutSource''))
		begin
			alter table ccoCallsOutSource add international bit null
		end'
        EXEC(@sql);

		SET @process = 'KR110000 ALTER COLUMN MOTIVO'
        SET @sql = '
		if exists (select * from sys.columns where name = N''motivo'' and Object_ID = Object_ID(N''ccRIALogPhones''))
		begin
			alter table ccRIALogPhones alter column motivo varchar(100)
		end'
        EXEC(@sql);

        SET @process = 'KR110000 DROP SP ccsp_GalateaGetOutboundConfiguration'
        SET @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_GalateaGetOutboundConfiguration'')
		begin
			DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration;
		end'
        EXEC(@sql);

		SET @process = 'KR110000 CREATE SP ccsp_GalateaGetOutboundConfiguration'
        SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT
		,@campID INT
		AS
		BEGIN
		DECLARE @AllCampaigns TABLE (
		cam_id SMALLINT
		,cam_Descripcion VARCHAR(60)
		,cam_tNotas SMALLINT
		,cam_ocupado SMALLINT
		,cam_noInt_ocupado SMALLINT
		,cam_inter_ocupado SMALLINT
		,cam_nocontesto SMALLINT
		,cam_noInt_nocontesto SMALLINT
		,cam_inter_nocontesto SMALLINT
		,cam_fax SMALLINT
		,cam_noInt_fax SMALLINT
		,cam_inter_fax SMALLINT
		,cam_modomanual SMALLINT
		,ANI VARCHAR(15)
		,cam_ShowCalifWnd BIT
		,cam_StartTimerOnHangUp BIT
		,editableCallKey BIT
		,cam_tNoContesta SMALLINT
		,iTipoDial SMALLINT
		,detectAnswerMachine SMALLINT
		,detectVoiceMail SMALLINT
		,compliance SMALLINT
		,cam_inter_graba SMALLINT
		,cam_noint_graba SMALLINT
		,progDial SMALLINT
		,excCallBack SMALLINT
		,dialOrder SMALLINT
		,dialPrefix VARCHAR(10)
		,dialPrefixMan VARCHAR(10)
		,dialPrefixXfe VARCHAR(10)
		,listenManualCall BIT
		,stopRecording BIT
		,abandonCallback BIT
		,frame SMALLINT
		,t_autoCB SMALLINT
		,id_anilist INT
		,tDialonWrapUp SMALLINT
		,viewMode TINYINT
		,queSize SMALLINT
		,DNCScrub INT
		,callerIdDesc VARCHAR(15)
		,timeZoneRule INT
		,callsBySurvey INT
		,ivrScript INT
		,surveyPctg INT
		,call_record SMALLINT
		,startStopRecording BIT
		,leaveRecMessage BIT
		,manualCallOnChat BIT
		,callBackSurveyAgent BIT
		,callBackSurveyClient BIT
		,isRelationSurvey BIT
		,funcEspDtmf INT
		,sipHdrFormat VARCHAR(255)
		,cam_inter_cancelled SMALLINT
		,prefijo VARCHAR(40)
		,enbleprefix BIT
		,exitAssisted BIT
		,previewDiscard BIT
		,CampType INT
		,conexionInfo VARCHAR(50)
		,connUser VARCHAR(15)
		,closeConversationTime INT
		,answerTimeoutClient INT
		,allowFileAttachments BIT
		,selectRotativeANI INT
		,rotativeAlgo TINYINT
		,autoStart BIT
		,messagingOrder BIT
		,CamTPreview SMALLINT
		,TimesPreview TINYINT
		,timesDiscard TINYINT
		,recordHold BIT
		,zipCodeSchedule BIT
		,RecordCalls tinyint
		,simultaneousRecs smallint
		,EditableContactData bit
		,internationalDialingPortsAssigned bit
		)
		DECLARE @numbers VARCHAR(max)

		SELECT @numbers = COALESCE(@numbers + '''', '''', '''''''') + number
		FROM ccWhatsAppNumbers
		WHERE camp_id = 0
		AND STATUS = 1

		INSERT INTO @AllCampaigns
		EXEC ccsp_RIAConfCamp @adminID
		,@campID

		SELECT dialPrefixMan DialPrefixMan
		,dialPrefixXfe DialPrefixXfe
		,listenManualCall ListenManualCall
		,stopRecording StopRecording
		,abandonCallback AbandonCallBack
		,t_autoCB AutoCB
		,id_anilist IdIstANI
		,tDialonWrapUp TDialOnWrapup
		,queSize Quesize
		,DNCScrub
		,callerIdDesc CallerIdDesc
		,timeZoneRule TimeZoneRule
		,callsBySurvey CallsBySurvey
		,ivrScript IvrScript
		,surveyPctg SurveyPctg
		,call_record CallRecord
		,startStopRecording StartStopRecording
		,leaveRecMessage LeaveRecMessage
		,manualCallOnChat ManualCallOnChat
		,callBackSurveyClient CallBackSurveyClient
		,callBackSurveyAgent CallBackSurveyAgent
		,funcEspDtmf FuncEspDtmf
		,sipHdrFormat SipHdrsCfg
		,dialPrefix DialPrefix
		,prefijo Prefix
		,dialOrder DialOrder
		,progDial ProgDial
		,cam_Descripcion CamDescription
		,cam_tNotas CamTnotas
		,cam_ocupado CamBusy
		,cam_noInt_ocupado CamNoIntBusy
		,cam_inter_ocupado CamInterBusy
		,cam_nocontesto CamNoAnswer
		,cam_noInt_nocontesto CamNoIntNoAnswer
		,cam_inter_nocontesto CamInterNoAnswer
		,(cam_inter_cancelled / 60) CamInterCancelled
		,cam_fax CamFax
		,cam_noInt_fax CamNoIntFax
		,cam_inter_fax CamInterFax
		,cam_modomanual CamModoManual
		,ANI
		,cam_StartTimerOnHangUp CamStartTimerOnHangUp
		,editableCallKey EditableCallKey
		,cam_tNoContesta CamTNoAnswer
		,iTipoDial CamIntensiveDialing
		,detectAnswerMachine DetectAnswerMachine
		,detectVoiceMail DetectVoiceMail
		,compliance Compliance
		,cam_inter_graba CamInterRecord
		,cam_noint_graba CamNoIntRecord
		,excCallBack ExcCallBack
		,cam_ShowCalifWnd CamShowCalifWnd
		,frame Frame
		,exitAssisted ExitAssistedDialMode
		,previewDiscard PreviewDiscard
		,CampType
		,conexionInfo ConexionInfo
		,connUser ConnUser
		,closeConversationTime CloseConversationTime
		,answerTimeoutClient MUTimeOutClient
		,allowFileAttachments AllowFileAttachments
		,CamTPreview
		,CAST(TimesPreview AS SMALLINT) TimesPreview
		,@numbers AS FreeNumbers
		,selectRotativeANI SelectRotativeANIManualCall
		,rotativeAlgo RotativeAlgo
		,autoStart AutoStart
		,messagingOrder MessagingOrder
		,timesDiscard TimesDiscard
		,recordHold RecordHold
		,zipCodeSchedule ZipCodeSchedule
		,RecordCalls RecordCalls
		,simultaneousRecs SimultaneousRecs
		,EditableContactData EditableContactData
		,internationalDialingPortsAssigned internationalDialingPortsAssigned
		FROM @AllCampaigns
		WHERE cam_id = @campID
		END
			'
        EXEC(@sql);

		SET @process = 'KR110000 DROP SP ccsp_RIAConfCamp'
        SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAConfCamp'')
		begin
			DROP PROCEDURE ccsp_RIAConfCamp;
		end'
        EXEC(@sql);

	    SET @process = 'KR110000 CREATE SP ccsp_RIAConfCamp'
        SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_RIAConfCamp] @User_id SMALLINT, @campID INT = NULL
		AS
		SET NOCOUNT ON

		DECLARE @tableExistsRec TABLE (
			camId INT PRIMARY KEY
			,existRec BIT
			)
		DECLARE @camByUser TABLE (
			camId INT PRIMARY KEY
			,isCheck BIT
			)
		DECLARE @camId INT
			,@id INT;
		DEClARE @intenationalDialingPorts bit;
		declare @tempInternationalCode int
 
		if((select COUNT(*) from ( select  IdCode from ccoDialers ccoDial inner join ccoDialerCamp ccoDialCamp on ccoDialCamp.dialer_id = ccoDial.dialer_id where ccoDialCamp.cam_id = @campID and ccoDial.DialingType=0  ) result ) > 0)
		BEGIN
			set @intenationalDialingPorts = 1
		END
		ElSE
		BEGIN
			set @intenationalDialingPorts = 0;
		END

		IF NOT EXISTS (
				SELECT *
				FROM ccUsers_Roles
				WHERE User_id = @User_id
					AND Rol_id = 7
				)
		BEGIN
			INSERT INTO @camByUser
			SELECT *
				,0
			FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
			WHERE @campID IS NULL
				OR cam_id = @campID
		END
		ELSE
		BEGIN
			INSERT INTO @camByUser
			SELECT cam_id
				,0
			FROM ccCamps
			WHERE (
					IDArea > 0
					OR IDArea IS NULL
					)
				AND (
					@campID IS NULL
					OR cam_id = @campID
					)
		END

		WHILE EXISTS (
				SELECT *
				FROM @camByUser
				WHERE isCheck = 0
				)
		BEGIN
			SELECT TOP 1 @camId = camId
			FROM @camByUser
			WHERE isCheck = 0

			IF EXISTS (
					SELECT cam_id
					FROM ccoCallsOut
					WHERE cam_id = @camId
					)
			BEGIN
				INSERT INTO @tableExistsRec
				VALUES (
					@camId
					,1
					)
			END
			ELSE
			BEGIN
				INSERT INTO @tableExistsRec
				VALUES (
					@camId
					,0
					)
			END

			UPDATE @camByUser
			SET isCheck = 1
			WHERE camId = @camId
		END

		SELECT a1.cam_id
			,cam_Descripcion
			,cam_tNotas
			,cast(cam_ocupado AS INT) AS cam_ocupado
			,cam_noInt_ocupado
			,cam_inter_ocupado
			,cast(cam_nocontesto AS INT) AS cam_nocontesto
			,cam_noInt_nocontesto
			,cam_inter_nocontesto
			,cast(cam_fax AS INT) AS cam_fax
			,cam_noInt_fax
			,cam_inter_fax
			,cast(cam_modomanual AS INT) AS cam_modomanual
			,ANI
			,cam_ShowCalifWnd
			,cam_StartTimerOnHangUp
			,editableCallKey
			,cam_tNoContesta
			,iTipoDial
			,detectAnswerMachine
			,detectVoiceMail
			,compliance
			,cam_inter_graba
			,cam_noint_graba
			,cast(progDial AS TINYINT) progDial
			,cast(excCallBack AS TINYINT) excCallBack
			,dialOrder
			,dialPrefix
			,dialPrefixMan
			,dialPrefixXfe
			,listenManualCall
			,stopRecording
			,cast(abandonCallback AS TINYINT) abandonCallback
			,a3.frame
			,a1.t_autoCB
			,a1.id_anilist
			,a1.tDialonWrapUp
			,dbo.fn_viewMode(@User_id, 10) viewMode
			,cam_maxqueue AS queSize
			,DNCScrub
			,callerIdDesc
			,timeZoneRule
			,callsBySurvey
			,ivrScript
			,surveyPctg
			,isnull(a1.call_record, 1) AS call_record
			,cast(startStopRecording AS TINYINT) startStopRecording
			,leaveRecMessage
			,manualCallOnChat
			,callBackSurveyAgent
			,callBackSurveyClient
			,CASE 
				WHEN surveycamid IS NULL
					OR surveycamid = 0
					THEN 0
				ELSE 1
				END isRelationSurvey
			,isnull(a1.funcEspDtmf, 0)
			,isnull(sipHdrFormat, '''') sipHdrFormat
			,cam_inter_cancelled
			,prefijo
			,enbleprefix = CASE 
				WHEN existRec = 0
					THEN 1
				ELSE 0
				END
			,isnull(exitAssisted, 0) exitAssisted
			,isnull(previewDiscard, 0) PreviewDiscard	
			,isnull(CampType, 0) CampType
			,isnull(contact.conexionInfo, '''') conexionInfo
			,isnull(contact.connUser, '''') connUser
			,isnull(contact.closeConversationTime, 0) closeConversationTime
			,isnull(contact.answerTimeoutClient, 0) answerTimeoutClient
			,isnull(contact.allowFileAttachments, 0) allowFileAttachments
			,isnull(selectRotativeANI, 0) selectRotativeANI
			,ISNULL(rotativeAlgo, 0) rotativeAlgo
			,isnull(autoStart, 0) autoStart
			,isnull(messagingOrder, 0) messagingOrder
			,ISNULL(cam_tPreview, 0) AS CamTPreview
			,ISNULL(timesPreview, 0) AS TimesPreview
			,isnull(timesDiscard, 0) TimesDiscard
			,ISNULL(recordHold, 0) recordHold
			,isnull(campsExtention.zipCodeSchedule, 0) ZipCodeSchedule
			,isnull(campsExtention.RecordCalls, 1) RecordCalls
			,isnull(campsExtention.simultaneousRecs, 1) simultaneousRecs
			,isnull(campsExtention.EditableContactData, 0) EditableContactData
			,@intenationalDialingPorts intenationalDialingPorts 
		FROM ccCamps a1
		INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
		INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
		INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
		LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
		LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
		ORDER BY cam_descripcion

		RETURN (0)

		SET NOCOUNT OFF
		'
        EXEC(@sql);

		SET @process = 'KR110000 DROP SP ccsp_RIALogPhones'
        SET @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_RIALogPhones'')
		begin
			DROP PROCEDURE ccsp_RIALogPhones;
		end'
        EXEC(@sql);

		SET @process = 'KR110000 CREATE SP ccsp_RIALogPhones'
        SET @sql = '
		CREATE procedure [dbo].[ccsp_RIALogPhones]
		@load_id int,
		@Type smallint,
		@GenCSV bit = 1, -- 0:100 / 1:todos
		@isKolob bit = 0,
		@PageIndex      INT = 0,
		@PageSize       INT = 0,
		@option SMALLINT = NULL
		as
		set nocount ON

		declare @CaseType varchar(2000), @sql nvarchar(MAX), @nType char(5), @MovType SMALLINT, @language int
		SELECT @language = cs.valor FROM dbo.ccSettings AS cs WHERE cs.setting_id = 27;
		declare @PageStart int,@PageEnd int

		select @CaseType = '''', @nType = right(''0000''+cast(@Type as varchar(5)), 5)

		if @nType like ''%____1%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov in (0,8)
			''

		if @nType like ''%___1_%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov in(-1,0,8) 
			''

		if @nType like ''%__1__%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 1 
			''

		if @nType like ''%_1___%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov = 1 
			''

		if @nType like ''%1____%''
			select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 2 ''

		if @CaseType = '''' and @nType <> 0
			return(0)

		if @nType like ''%____1%''
			select @CaseType = @CaseType + ''  or telefono<>'''''''' and crlp.tipoMov = 0''

		select @PageStart=@PageSize*(@PageIndex-1),@PageEnd=@PageSize*@PageIndex

		IF(@option = 1)
		BEGIN	
			SET @sql = ''SELECT count(*) AS listSize FROM (
		select crlp.load_id
		from ccRIALogPhones AS crlp 
		where crlp.load_id = @load_id'' 
		+ @CaseType +'') tmp '' +
		case @GenCSV when 0 then ''WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd'' else '''' end
					--EXEC(@sql);
			
				Exec sp_executesql @sql
						 , N''@PageStart int,@PageEnd int,@language int,@load_id int''
						 , @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id
					RETURN (0);
				END
				ELSE 
				BEGIN
						IF(@isKolob = 1)
						BEGIN

						declare @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200), @typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
						@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @typeUpdatedRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200), @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max);


						select @typeDescriptionPhoneBlocked=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-num''
						select @typeDescriptionPhoneUpdated=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-num''
						select @typeIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-incorrect-records''
						select @typeBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-records''
						select @typeDescriptionPhoneNotLoaded=translate from tableLangueDbLoader where languageId=@language and tag=''type-not-loaded-num''

						select @typeDescriptionPhoneBlackList=translate from tableLangueDbLoader where languageId=@language and tag=''description-dnc-list''
						select @descriptionIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-incorrect-records''
						select @descriptionBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-blocked-records''
						select @typeUpdatedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-records''
						select @descriptionInternationalPortNotFound=TRANSLATE from tableLangueDbLoader where languageId=@language and tag=''type-camp-no-international-port''


						select @column=translate from tableLangueDbLoader where languageId=@language and tag=''column-file-field''

						select @headerPhone=header_phone,@headerPhone2=header_phone2,@headerPhone3=header_phone3,@headerPhone4=header_phone4 
						,@headerPhone5=header_phone5
						from fileHeadersPhoneLoad where load_id=@load_id
			
							set @CaseType=case when @CaseType <> '''' then '' and ('' + substring(@CaseType, 5, len(@CaseType)) + '')'' else '''' END
							SET @sql = '';with result as(
							SELECT * FROM (select  
							ROW_NUMBER() OVER(ORDER BY crlp.cal_key ASC) AS RowNum,
							crlp.load_id,
							crlp.cal_key, 
							crlp.telefono AS phone,
							CASE
								WHEN crlp.tipoMov in (1,4)  THEN @typeDescriptionPhoneBlocked  
								WHEN crlp.tipoMov = 2 THEN @typeUpdatedRecords	
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @typeIncorrectRecords
								WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @typeBlockedRecords
								WHEN crlp.tipoMov in(-1,0) THEN @typeDescriptionPhoneNotLoaded
								WHEN crlp.tipoMov in(8) THEN @descriptionInternationalPortNotFound
								WHEN crlp.keyTranslate is not null THEN isnull(tlan.translate,crlp2.descTipoMov)
							ELSE 
								crlp2.descTipoMov  
							END AS Tipo,
							case when CHARINDEX('''':'''',crlp.motivo)=0 then 0 else
								convert(int,substring(crlp.motivo ,CHARINDEX('''':'''',crlp.motivo)-1 ,1))
							end
							 AS ColumnFile, 
							CASE  WHEN crlp.tipoMov = 2 THEN ''''N/A'''' 
									WHEN crlp.tipoMov in (1,4) THEN @typeDescriptionPhoneBlackList							  
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @descriptionIncorrectRecords
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @descriptionBlockedRecords
									WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-camp-no-international-port'''') THEN  @descriptionInternationalPortNotFound
									WHEN crlp.keyTranslate is not null THEN tlan.translate 
							ELSE crlp.motivo END AS motivo
							from ccRIALogPhones AS crlp 
							INNER JOIN dbo.ccRIACATLogPhones AS  crlp2 ON crlp.tipoMov = crlp2.tipoMov
							left join tableLangueDbLoader tlan on tlan.tag=crlp.keyTranslate and tlan.languageId=@language
							where crlp.load_id = @load_id '' 				
							+ @CaseType +'') tmp '' +
							case @GenCSV when 0 then '' WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd '' else '''' end +'' 
							) 
							select  crlp.RowNum,
							crlp.load_id,
							crlp.cal_key, 
							crlp.phone,
							crlp.Tipo,
							case when crlp.ColumnFile=1 then @headerPhone
							when crlp.ColumnFile=2 then @headerPhone2
							when crlp.ColumnFile=3 then @headerPhone3
							when crlp.ColumnFile=4 then @headerPhone4
							when crlp.ColumnFile=5 then @headerPhone5
							else '''''''' end ColumnFile,
							crlp.motivo
							from result crlp ''
			END
			ELSE
			BEGIN
				set @sql = ''select '' + case @GenCSV when 0 then ''top 100 '' else '''' end 
				+ ''load_id, cal_key, telefono, tipoMov, motivo from ccRIALogPhones AS crlp where load_id = @load_id '' 
				+ @CaseType
			END  
			--PRINT(@sql);



			Exec sp_executesql @sql, N''@PageStart int,@PageEnd int,@language int,@load_id int, @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200),
			@typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
			@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200),  @descriptionInternationalPortNotFound VARCHAR(200)
			, @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max), @typeUpdatedRecords varchar(200)''
			, @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id,@column=@column,@typeDescriptionPhoneNotLoaded=@typeDescriptionPhoneNotLoaded
			,@typeDescriptionPhoneBlocked=@typeDescriptionPhoneBlocked,@typeDescriptionPhoneUpdated=@typeDescriptionPhoneUpdated,@typeDescriptionPhoneBlackList=@typeDescriptionPhoneBlackList
			,@typeBlockedRecords=@typeBlockedRecords,@typeIncorrectRecords=@typeIncorrectRecords,@descriptionBlockedRecords=@descriptionBlockedRecords,@descriptionIncorrectRecords=@descriptionIncorrectRecords,
			 @descriptionInternationalPortNotFound= @descriptionInternationalPortNotFound 
			,@headerPhone=@headerPhone,@headerPhone2=@headerPhone2,@headerPhone3=@headerPhone3,@headerPhone4=@headerPhone4,@headerPhone5=@headerPhone5,@typeUpdatedRecords=@typeUpdatedRecords
	
		return(0)
		END
		set nocount OFF'
        EXEC(@sql);

		SET @process = 'KR110000 DROP SP ccsp_GalateaGetRecordsImportStatus'
        SET @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_GalateaGetRecordsImportStatus'')
		begin
			DROP PROCEDURE ccsp_GalateaGetRecordsImportStatus;
		end'
        EXEC(@sql);

		SET @process = 'KR110000 CREATE SP ccsp_GalateaGetRecordsImportStatus'
        SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaGetRecordsImportStatus]
		-- @Type = 1:Detalle general de carga de registros | 2:Detalle específico de carga de registros | 3:Porcentaje de carga de registros
		@action tinyint, 
		@loadID int = NULL, 
		@userID smallint = NULL

		AS
		declare @today datetime
		select @today =convert(datetime, convert(varchar(11),getdate(),121),121)
		SET nocount ON
		if @action not IN (1,2,3)
		raiserror(''ERROR. No se ingreso parametro de entrada'', 18, 1)

		if @action=1 -- Detalle general de carga de registros
		BEGIN
		if not exists(SELECT User_id FROM ccUsers WHERE TipoUser_id IN(2,6) AND Status>0 AND User_id=@userID)
		 BEGIN
		  raiserror(''ERROR. invalid user id'', 18, 1)
		  return(0)
		 END

		if exists (select * from ccUsers_Roles where User_id = @userID and Rol_id = (select Rol_id from ccRoles where Level = 7))
			BEGIN
				SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked+isnull(regsNotLoadedCp,0)+ISNULL(recordsNotLoadedPort,0) as regsNotLoaded, state, loadDate	
				FROM ccRIALoading riaLoad
				JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
				WHERE 
				loadDate>=@today and loadType = 0
				ORDER BY riaLoad.loadDate DESC
			END
		else
			BEGIN
				SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked+isnull(regsNotLoadedCp,0)+ISNULL(recordsNotLoadedPort,0) as regsNotLoaded, state, loadDate
		
				FROM ccRIALoading riaLoad
				JOIN ccSupervisorCam superCam ON riaLoad.cam_id = superCam.cam_id
				JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
				WHERE 
				loadDate>=@today AND
				superCam.user_id = @userID
				AND superCam.tipo = 1
				ORDER BY riaLoad.loadDate DESC
			END

		return(0)
		END

		if @action=2 -- Detalle específico de carga de registros
		BEGIN
		if not exists(SELECT load_id FROM ccRIALoading)
		 BEGIN
		  raiserror(''ERROR. invalid template ID'', 18, 1)
		  return(0)
		 END

		  SELECT regsLoaded, alreadyLoaded, regsBlocked, regsNotLoaded,
				 telsLoaded, telsBlocked, telsNotLoaded, isnull(regsNotLoadedCp,0) as regsNotLoadedCp
				 , isnull(telsNotLoadedCp,0) as telsNotLoadedCp, ISNULL(recordsNotLoadedPort,0) as recordsNotLoadedPort, ISNULL(phonesNotLoadedPort, 0) as phonesNotLoadedPort
		  FROM ccRIALoading
		  WHERE load_id  = @loadID

		END

		if @action=3 -- Porcentaje de carga de registros
		BEGIN
		if not exists(SELECT load_id FROM ccRIALoading)
		 BEGIN
		  raiserror(''ERROR. invalid load ID'', 18, 1)
		  return(0)
		 END

		  SELECT state, pctg
		  FROM ccRIALoading
		  WHERE load_id  = @loadID

		END
		SET nocount off'
        EXEC(@sql);

		SET @process = 'KR110000 INSERT INTO tableLangueDbLoader tag=type-camp-no-international-port, languageId=0'
        SET @sql = '
		if not exists(select tag from tableLangueDbLoader where tag = ''type-camp-no-international-port'' and languageId=0)
		begin
			insert into tableLangueDbLoader (languageId,tag, translate) values (0,''type-camp-no-international-port'',''Puerto internacional no encontrado'')
		end'
        EXEC(@sql);

		
		SET @process = 'KR110000 INSERT INTO tableLangueDbLoader tag=type-camp-no-international-port, languageId=1'
        SET @sql = '
		if not exists(select tag from tableLangueDbLoader where tag = ''type-camp-no-international-port'' and languageId=1)
		begin
			insert into tableLangueDbLoader (languageId,tag, translate) values (1,''type-camp-no-international-port'',''International port not found'')
		end'
        EXEC(@sql);

		SET @process = 'KR110000 INSERT INTO tableLangueDbLoader tag = type-camp-no-international-port, languageId=2'
        SET @sql = '
		if not exists(select tag from tableLangueDbLoader where tag = ''type-camp-no-international-port'' and languageId=2)
		begin
			insert into tableLangueDbLoader (languageId,tag, translate) values (2,''type-camp-no-international-port'',''Porta internacional não encontrada'')
		end'
        EXEC(@sql);

		
		SET @process = 'KR110000 INSERT INTO ccGalateaIdentifiers'
        SET @sql = '
		if not exists(select Description from ccGalateaIdentifiers where Description = ''LOAD_INTERNATIONAL_RECORDS'')
		begin
			insert into ccGalateaIdentifiers (Description,TagEs,TagEn,TagPt) values (''LOAD_INTERNATIONAL_RECORDS'',''Registros internacionales'',''International records'',''Registros internacionais'')
		end'
        EXEC(@sql);

		SET @process = 'KR110000 INSERT INTO  ccRIACATLogPhones tipoMov = 8'
        SET @sql = '
		if not exists(select tipoMov from ccRIACATLogPhones where tipoMov = 8)
		begin
			insert into ccRIACATLogPhones (tipoMov,descTipoMov) values (8,''No cargados sin puertos'')
		end
 '
        EXEC(@sql);

		      
       ----------------------------------------------------- END Fri----------------------------------------------------------------

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
