/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Ernesto Rangel
Date: 2019/07/08
Description: CW-3145


Database: ccReportsRia
Required version: 67


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 68

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
		

		SET @process = 'CW-3145 ST_2019_06_494 No muestra la información de Twitter en el sitio de los Reportes.'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepTwitterACD]

@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS
if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1	begin

	delete from RepTwitterACD with(rowlock) where date >= @from AND date < @to

	insert into RepTwitterACD
	select CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121) date,
		isnull(descripcion,'''') as inboundName, isnull(inboundid,0) as inboundid,
		isnull(count(*),0) Downloads,isnull(sum(unassigned),0) as unassigned, isnull(sum(onTrack),0) onTrack,
		isnull(sum(rejected),0) rejected,isnull(sum(assigned),0) assigned,isnull(sum(actives),0) actives,
		isnull(sum(pendingSend),0) as pendingSend,
		isnull(sum(abandonedsystem),0) abandonedsystem, isnull(sum(abandonedbyagent),0) abandonedbyagent,
		isnull(sum(abandonedsystem+abandonedbyagent),0) finishedconversation,
		isnull(isnull(sum(sendMail),0)/nullif(cast(count(*) as float) ,0),0) * 100 as  sentvsdownloaded,
		isnull(sum(tQueue),0) tQueue, isnull(sum(tsent),0) tsent, isnull(sum(twait),0) twait,
		isnull(sum(tatention)/nullif(sum(pendingSend+onTrack+rejected+abandonedsystem+abandonedbyagent),0),0) tAvgAtentionMultimedia,
		isnull(sum(twrapup),0) twrapup,
		datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [year],
		datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [mounth],
		datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [day],
		datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [hour],
		datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121)) [minute]
	 from (
		select msg.date date,
				 inbo.descripcion descripcion ,inbo.inbound_id inboundid,
				 case when msg.messagestatusid in (1,4) then 1 else 0 end unassigned,
				 case when msg.messagestatusid = 2 then 1 else 0 end assigned,
				 case when msg.messagestatusid = 3 then 1 else 0 end actives,
				 case when msg.messagestatusid = 5 then 1 else 0 end pendingSend,
				 case when msg.messagestatusid = 6 then 1 else 0 end onTrack,
				 case when msg.messagestatusid in (7,8,9) then 1 else 0 end rejected,
				 case when msg.messagestatusid = 10 then 1 else 0 end abandonedsystem,
				 case when msg.messagestatusid = 11 then 1 else 0 end abandonedbyagent,
				 case when msg.messagestatusid in(6,10,11) then 1 else 0 end sendMail,
				 datediff(second,msg.date,isnull(msg.tqueue,getdate())) tQueue,
				 datediff(ss,dateadd(ss, msg.twait + msg.tretention + msg.tresponse + msg.twrapup,msg.tqueue),msg.tsend) tsent,
				 msg.twait twait,
				 msg.twait + msg.tretention + msg.tresponse tatention,
				 msg.twrapup twrapup
				 from [messageOutTwitter] msg
				 inner join [conversationTwitter] conv
				on msg.conversationTwitterId = conv.conversationTwitterId
				left join [ccInbound] inbo on inbo.inbound_Id = conv.inboundId
				left join ccusers usuario on usuario.User_id = msg.userid
				where msg.date >= @from AND msg.date < @to
				)x
				group by CONVERT(smalldatetime,CONVERT(varchar(13), date, 121)+'':00'',121),descripcion ,inboundid

end'
		EXEC (@sql)

		


		--IF @actualVersion = @version - 1
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
