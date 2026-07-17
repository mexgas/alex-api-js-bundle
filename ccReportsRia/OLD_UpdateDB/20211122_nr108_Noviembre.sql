SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 108

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	SET @process = 'CW-6053 update PivotReports'
	SET @sql = 'update PivotReports set complementColumns=''date|userId|login|scriptId|surveyId|survey|calId|calKey|clientPhoneNumber|campACDDescription'' where id=6050'
	EXEC (@sql)

	set @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
    begin
    DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
    end'
EXEC(@sql)

	set @process = 'CW-6053 Reporte IVR Encuestas ADD IVROptions COLUMNS'
    set @sql = 'IF NOT EXISTS(SELECT 1 FROM sys.columns 
						  WHERE Name = N''callType''
						  AND Object_ID = Object_ID(N''dbo.IVROptions''))
				BEGIN
					alter table IVROptions add callType tinyint null
				END'
	EXEC(@sql)


	set @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
set @sql='if exists(select * from sys.triggers where name = N''MSmerge_tr_altertable'')
        begin
        ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
        end'
EXEC(@sql)

	SET @process = 'CW-6053 alter sp ccspRepIVRSurveys'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepIVRSurveys]
		@action as tinyint,
		@from AS datetime = null,
		@to AS datetime = null
		AS

		if @action = 1
		begin
		if @from is null
			select @from = convert(datetime,convert(varchar(14),getdate(),121)+ ''00'',121)
		if @to is null
			select @to = getdate()


		delete RepIVRSurveys with(rowlock)
			where [date] between @from and @to


		insert RepIVRSurveys select [date],userId,[login],scriptId,surveyId,survey,calId,calKey,campaignId,inboundId,campACDDescription,
		questionId,questionDescription,question_Count,[Count],[year],[month],[day],[hour],[minutes],clientPhoneNumber
		from
		(
			select distinct
			cci.cal_Inicio as [date],
			isnull(cci.User_id, 0) as ''userId'',
			isnull(ccu.Login, ''No agent'') as ''login'',
			isnull(ivro.IVR_id, 0) as ''scriptId'',
				isnull(s.surveyId, 0) as ''surveyId'',
			isnull(s.description, '''') as ''survey'',
			isnull(cci.cal_id, 0) as ''calId'',
			isnull(cci.cal_Key, '''') as ''calKey'',
			0 as ''campaignId'',
			isnull(cci.Inbound_id, '''') as ''inboundId'',
			''ACD - '' + isnull(ccin.descripcion,'''') as ''campACDDescription'',
			isnull(ivro.questionId, 0) as ''questionId'',
			isnull(sq.description,'''') as ''questionDescription'',
			isnull(sq.description,'''')+ ''_UnCount'' as ''question_Count'',
			case when ivro.selectedOption is null then ''systemTranslated_NA''
			when ivro.selectedOption = '''' then ''systemTranslated_No_Option''
			when r.questionId is null then ivro.selectedOption
			when r.answerId is not null and ivro.selectedOption = convert(varchar(5),r.digit) then r.desAnswer
			else ''systemTranslated_Invalid'' end as ''Count'',
			datepart(yy,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [year],
			datepart(MM,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [month],
			datepart(DD,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [day],
			datepart(HH,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [hour],
			datepart(MI,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [minutes]
			,rsq.orden, cal_ani clientPhoneNumber 
			from (select q.IVR_id,ivro.selectedOption,saveType,q.questionId,q.surveyId,q.cal_id,orden from IVROptions ivro right join
			(select distinct IVR_id,name,rsq.questionId,rsq.surveyId,cal_id,orden from IVROptions ivro (nolock) cross join relationSurveyQuestion rsq 
				where ivro.date between @from and @to and ivro.surveyId=rsq.surveyId and ivro.surveyId=rsq.surveyId)q
			on q.IVR_id=ivro.IVR_id and q.questionId=ivro.questionId)ivro
			join ccCallsIn cci with(nolock) on cci.cal_id=ivro.cal_id
			inner join ccUserView ccu on cci.User_id = ccu.User_id
			inner join Survey s on ivro.surveyId = s.surveyId
			inner join ccInbound ccin on cci.Inbound_id = ccin.Inbound_id
			inner join SurveyQuestion sq on ivro.questionId = sq.questionId
			inner join relationSurveyQuestion rsq on rsq.surveyId = ivro.surveyId and rsq.questionId=sq.questionId
			left join (
			select rqa.surveyId,rqa.questionId,min(rqa.answerId) answerId,sa.digit,min(description) as desAnswer from relationQuestionAnswer rqa
			inner join SurveyAnswer sa on  rqa.answerId=sa.answerId group by rqa.surveyId,rqa.questionId,sa.digit
			)r on convert(varchar(5),r.digit) = ivro.selectedOption and r.surveyId=ivro.surveyId and ivro.questionId=r.questionId
			where cal_inicio between @from and @to

			union all

			select distinct
			cco.cal_Inicio as [date],cco.User_id as ''userId'',
			isnull(ccu.Login, ''No agent'') as ''login'',
			isnull(ivro.IVR_id, 0) as ''scriptId'',
			isnull(s.surveyId, 0) as ''surveyId'',
			isnull(s.description, '''') as ''survey'',
			isnull(cco.cal_id, 0) as ''calId'',
			isnull(cco.cal_Key, '''') as ''calKey'',
			isnull(ccc.[cam_id], '''') as ''campaignId'',
			0 as ''inboundId'',
			''Camp - '' + isnull(ccc.[cam_descripcion],'''') as ''campACDDescription'',
			isnull(ivro.questionId, 0) as ''questionId'',
			isnull(sq.description,'''') as ''questionDescription'',
			isnull(sq.description,'''')+ ''_UnCount'' as ''question_Count'',
			case when ivro.selectedOption is null then ''systemTranslated_NA''
			when ivro.selectedOption = '''' then ''systemTranslated_No_Option''
			when r.questionId is null then ivro.selectedOption
			when r.answerId is not null and ivro.selectedOption = convert(varchar(5),r.digit) then r.desAnswer
			else ''systemTranslated_Invalid'' end as ''Count'',
				datepart(yy,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [year],
			datepart(MM,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [month],
			datepart(DD,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [day],
			datepart(HH,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [hour],
			datepart(MI,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [minutes]
			,ivro.orden, cal_telefono clientPhoneNumber
			from (select q.IVR_id,ivro.selectedOption,saveType,q.questionId,q.surveyId,q.cal_id,orden from IVROptions ivro right join
			(select distinct IVR_id,name,rsq.questionId,rsq.surveyId,cal_id,orden from IVROptions ivro (nolock) cross join relationSurveyQuestion rsq 
				where ivro.date between @from and @to and ivro.surveyId=rsq.surveyId and ivro.surveyId=rsq.surveyId and ivro.callType=2)q
			on q.IVR_id=ivro.IVR_id and q.questionId=ivro.questionId)ivro
			join ccoCallsOut cco (nolock) on cco.cal_id=ivro.cal_id
			inner join ccUserView ccu on cco.User_id = ccu.User_id
			inner join Survey s on ivro.surveyId = s.surveyId
			inner join ccCamps ccc on cco.cam_id = ccc.cam_id
			inner join SurveyQuestion sq on ivro.questionId = sq.questionId
			left join (
			select rqa.surveyId,rqa.questionId,min(rqa.answerId) answerId,sa.digit,min(description) as desAnswer from relationQuestionAnswer rqa
			inner join SurveyAnswer sa on  rqa.answerId=sa.answerId group by rqa.surveyId,rqa.questionId,sa.digit
			)r on convert(varchar(5),r.digit) = ivro.selectedOption and r.surveyId=ivro.surveyId and ivro.questionId=r.questionId
			where cal_inicio between @from and @to

			union all

			select distinct
			cco.tAnswerBit as [date],0 as ''userId'',
			''n/a'' as ''login'',
			isnull(ivro.IVR_id, 0) as ''scriptId'',
			isnull(s.surveyId, 0) as ''surveyId'',
			isnull(s.description, '''') as ''survey'',
			isnull(cco.cal_id, 0) as ''calId'',
			isnull(cco.cal_Key, '''') as ''calKey'',
			isnull(ccc.[cam_id], '''') as ''campaignId'',
			0 as ''inboundId'',
			''Camp - '' + isnull(ccc.[cam_descripcion],'''') as ''campACDDescription'',
			isnull(ivro.questionId, 0) as ''questionId'',
			isnull(sq.description,'''') as ''questionDescription'',
			isnull(sq.description,'''')+ ''_UnCount'' as ''question_Count'',
			case when ivro.selectedOption is null then ''systemTranslated_NA''
			when ivro.selectedOption = '''' then ''systemTranslated_No_Option''
			when r.questionId is null then ivro.selectedOption
			when r.answerId is not null and ivro.selectedOption = convert(varchar(5),r.digit) then r.desAnswer
			else ''systemTranslated_Invalid'' end as ''Count'',
				datepart(yy,convert(datetime, convert(varchar(14),cco.tAnswerBit,121)+ ''00'',121)) as [year],
			datepart(MM,convert(datetime, convert(varchar(14),cco.tAnswerBit,121)+ ''00'',121)) as [month],
			datepart(DD,convert(datetime, convert(varchar(14),cco.tAnswerBit,121)+ ''00'',121)) as [day],
			datepart(HH,convert(datetime, convert(varchar(14),cco.tAnswerBit,121)+ ''00'',121)) as [hour],
			datepart(MI,convert(datetime, convert(varchar(14),cco.tAnswerBit,121)+ ''00'',121)) as [minutes]
			,ivro.orden, Telefono clientPhoneNumber
			from (select q.IVR_id,ivro.selectedOption,saveType,q.questionId,q.surveyId,q.cal_id,orden from IVROptions ivro right join
			(select distinct IVR_id,name,rsq.questionId,rsq.surveyId,cal_id,orden from IVROptions ivro (nolock) cross join relationSurveyQuestion rsq 
				where ivro.date between @from and @to and ivro.surveyId=rsq.surveyId and ivro.surveyId=rsq.surveyId and ivro.callType=0)q
			on q.IVR_id=ivro.IVR_id and q.questionId=ivro.questionId)ivro
			join ccoLogDials cco (nolock) on cco.logDial_id=ivro.cal_id
			inner join Survey s on ivro.surveyId = s.surveyId
			inner join ccCamps ccc on cco.cam_id = ccc.cam_id
			inner join SurveyQuestion sq on ivro.questionId = sq.questionId
			left join (
			select rqa.surveyId,rqa.questionId,min(rqa.answerId) answerId,sa.digit,min(description) as desAnswer from relationQuestionAnswer rqa
			inner join SurveyAnswer sa on  rqa.answerId=sa.answerId group by rqa.surveyId,rqa.questionId,sa.digit
			)r on convert(varchar(5),r.digit) = ivro.selectedOption and r.surveyId=ivro.surveyId and ivro.questionId=r.questionId
			where tAnswerBit between @from and @to

		)surveys
		order by calId,orden
		end'
	EXEC (@sql)

		IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

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
