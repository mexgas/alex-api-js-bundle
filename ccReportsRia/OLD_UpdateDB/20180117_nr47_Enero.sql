/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Hugo Longoria
Date: 2018/01/17
Description:
**********************************************************************************************
CW-1043 - faltan relaciones en las tablas de survey
**********************************************************************************************
Database: ccReportsRia
Required version: 46


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =47
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion  in(@version,@version - 1) begin
	begin tran
	begin try

	set @process = 'CW-1043 - SP ccspRepIVRSurveys'
	set @Sql= '
		ALTER PROCEDURE [dbo].[ccspRepIVRSurveys]
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
			select
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
			case when ivro.selectedOption = '''' then ''systemTranslated_No_Option''
			when r.questionId is null then ivro.selectedOption
			when r.answerId is not null and ivro.selectedOption = convert(varchar(5),r.digit) then r.desAnswer
			else ''systemTranslated_Invalid'' end as ''Count'',
			datepart(yy,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [year],
			datepart(MM,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [month],
			datepart(DD,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [day],
			datepart(HH,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [hour],
			datepart(MI,convert(datetime, convert(varchar(14),cci.cal_Inicio,121)+ ''00'',121)) as [minutes]
			,rsq.orden, cal_ani clientPhoneNumber
			from ccCallsIn cci with(nolock)
			inner join IVROptions ivro on ivro.cal_id = cci.cal_id
			inner join ccUsers ccu on cci.User_id = ccu.User_id
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
			case when ivro.selectedOption = '''' then ''systemTranslated_No_Option''
			when r.questionId is null then ivro.selectedOption
			when r.answerId is not null and ivro.selectedOption = convert(varchar(5),r.digit) then r.desAnswer
			else ''systemTranslated_Invalid'' end as ''Count'',
				datepart(yy,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [year],
			datepart(MM,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [month],
			datepart(DD,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [day],
			datepart(HH,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [hour],
			datepart(MI,convert(datetime, convert(varchar(14),cco.cal_Inicio,121)+ ''00'',121)) as [minutes]
			,rsq.orden, cal_telefono clientPhoneNumber
			from ccoCallsOut cco
			inner join IVROptions ivro on cco.cal_id = ivro.cal_id
			inner join ccUsers ccu on cco.User_id = ccu.User_id
			inner join Survey s on ivro.surveyId = s.surveyId
			inner join ccCamps ccc on cco.cam_id = ccc.cam_id
			inner join SurveyQuestion sq on ivro.questionId = sq.questionId
			inner join relationSurveyQuestion rsq on rsq.surveyId = ivro.surveyId and rsq.questionId=sq.questionId
			left join (
			select rqa.surveyId,rqa.questionId,min(rqa.answerId) answerId,sa.digit,min(description) as desAnswer from relationQuestionAnswer rqa
			inner join SurveyAnswer sa on  rqa.answerId=sa.answerId group by rqa.surveyId,rqa.questionId,sa.digit
			)r on convert(varchar(5),r.digit) = ivro.selectedOption and r.surveyId=ivro.surveyId and ivro.questionId=r.questionId
			where cal_inicio between @from and @to

		)surveys
		order by calId,orden
		end
'
	EXEC(@sql)

	
	if @actualVersion  = @version - 1
		exec ccsp_getVersion 'BD', @version


	commit tran
	end try

	begin catch

	/* Error generated based on sintax */
	select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch
end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off