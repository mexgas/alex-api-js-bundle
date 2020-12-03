SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 92

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY


		SET @process = 'CW-4461 Modify SP ccspRepACDChats'
		SET @sql = '
		ALTER PROCEDURE [dbo].[ccspRepACDChats]
		@action as tinyint,
		@from as datetime = null,
		@to as datetime = null
		AS

		if @from is null
		Begin
			select @from = convert(datetime,convert(varchar(11),getdate()))
		End
		if @to is null 
		begin
			select @to = convert(datetime,convert(varchar(11),getdate()))
		end

		if @action = 1 
			begin
			
				delete from RepACDChats with(rowlock)
				where date >= @from AND date < @to
				
				insert into RepACDChats
					select fecha,
					inboundId, b.descripcion, ChatDetail.domain, b.IDArea, c.AreaName,
					max([totalChats]),
					sum([waitingAbandoned]),
					sum([waitingConnected]),
					max(maxTQueue),
					max(avgTQueue),
					sum([onQueue]),
					sum([Connected]),
					sum([UnavailableAgents] + [OutOfService] + [OutOfSchedule] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]),
					0.00 as levelService,
					sum([byCostumer]) as finishedByCostumer,
					sum([byAgent]) as finishedByAgent,
					sum([bySystem]) as finishedBySystem,
					sum([byAdmin]) as finishedByAdmin,
					datepart(yyyy,CONVERT(varchar(20), fecha, 120)) as [year],
					datepart(mm,CONVERT(varchar(20), fecha, 120)) as [month],
					datepart(dd,CONVERT(varchar(20), fecha, 120)) as [day],
					datepart(hh,CONVERT(varchar(20), fecha, 120)) as [hour],
					datepart(mi,CONVERT(varchar(20), fecha, 120)) as [minutes]
					from(

						select inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as fecha,
						count(*) as [totalChats],
						domain,
						ISNULL(count(CASE WHEN (chatstatus = 9) and onQueue = 1 THEN 1 ELSE NULL END),0)AS [waitingAbandoned],
						ISNULL(count(CASE WHEN (chatstatus = 4) and onQueue = 1 THEN 1 ELSE NULL END),0)AS [waitingConnected],
						ISNULL(count(CASE WHEN (chatstatus = 4) THEN 1 ELSE NULL END),0)AS [Connected],
						ISNULL(count(CASE WHEN onQueue = 1 THEN 1 ELSE NULL END),0)AS [onQueue],
						ISNULL(count(CASE WHEN(chatstatus = 2)THEN 1 ELSE NULL END),0)AS [UnavailableAgents],
						ISNULL(count(CASE WHEN(chatstatus = 5)THEN 1 ELSE NULL END),0)AS [OutOfService],
						ISNULL(count(CASE WHEN(chatstatus = 6)THEN 1 ELSE NULL END),0)AS [OutOfSchedule],
						ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
						ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
						ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
						ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow],
						ISNULL(count(CASE WHEN(finishedBy = 0)THEN 1 ELSE NULL END),0) AS [byCostumer],
						ISNULL(count(CASE WHEN(finishedBy = 1)THEN 1 ELSE NULL END),0) AS [byAgent],
						ISNULL(count(CASE WHEN(finishedBy = 2)THEN 1 ELSE NULL END),0) AS [bySystem],
						ISNULL(count(CASE WHEN(finishedBy = 3)THEN 1 ELSE NULL END),0) AS [byAdmin],
						max(tqueue) as maxTQueue,
						avg(tqueue) as avgTQueue
						from ccRIAChats a
						where
						chatStatus in (2,5,4,7,9,10,11)
						group by inboundId, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121), domain
						
					) as ChatDetail
					left join ccInbound b on (b.inbound_id = ChatDetail.inboundId)
					left join ccRIACat_Areas c on (c.IDArea = b.IDArea)
					where fecha >= @from and fecha < @to
					group by inboundId, fecha, b.descripcion, ChatDetail.domain, b.IDArea, c.AreaName
					
					declare @DTChat as int
					select @DTChat = valor from ccsettings where setting_id = 33
					
					
					select inboundId, descripcion, date,
					isnull(convert(decimal(10,2),convert(float,[Connected]+[AbandonnedValid])/ NULLIF(convert(float, Total),0)) * 100.00,0) as NS
					into #tmpns
					from
					(select inboundId, descripcion, Date,
					sum([Connected>DT]) as [Connected], 
					sum([CCAb]) as [AbandonnedValid],
					sum([Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as NotConnected,
					sum([Connected>DT] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as Total
					from (
					select inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121) as Date ,
					ISNULL(count(case when chatStatus=9 and tQueue<@DTChat then 1 else null end),0) As [CCAb],
					ISNULL(count(CASE WHEN chatstatus = 4 and tChatting >= @DTChat THEN 1 ELSE NULL END),0)AS [Connected>DT],
					ISNULL(count(CASE WHEN chatstatus = 4 and tChatting < @DTChat THEN 1 ELSE NULL END),0)AS [Connected<DT],
					ISNULL(count(CASE WHEN(chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
					ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
					ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
					ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
					ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow]
					from ccRIAChats a
					left outer join ccInbound c on (inboundId = inbound_id)
					where chatStatus in (3,4,7,9,10,11)
					and chatDate is not null 
					and requestDate  >= @from and requestDate < @to
					group by inboundId, descripcion, CONVERT(smalldatetime,CONVERT(varchar(13),requestDate,121)+ '':00'',121)) as ChatDetail
					group by inboundId, descripcion, Date) as ChatSummary order by date, inboundid

					update RepACDChats set SL = b.NS
					from RepACDChats a, #tmpns b where a.date = b.date and a.inboundId = b.inboundId and b.date >= @from and b.date < @to
					drop table #tmpns
			end
		'
		EXEC(@sql)
		
		

		SET @process = 'CW-4447 Se modifica SP ccspTmpSessionTimeGroup'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspTmpSessionTimeGroup]
@from as smalldatetime,
@to as smalldatetime 
AS
set nocount on

if @from is null begin
	select @from = convert(datetime,convert(varchar(11),getdate()))
end

if @to is null begin
	select @to = dateadd(mi,1, convert(varchar(15),getdate(),121)+'':00'')
end

IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup
IF OBJECT_ID(''tempdb..#sessionTimeMayores'') IS NOT NULL drop table #sessionTimeMayores;

CREATE TABLE #sessionTimeGroup(	[user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)
CREATE TABLE #sessionTimeMayores([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)


if not exists( select * from sys.tables where name=''tmpSessionTimeGroup'') begin
	CREATE TABLE tmpSessionTimeGroup([user_id] [smallint] NOT NULL,[login] [datetime] NOT NULL,[logout] [datetime] NULL,[extension] [varchar](7) NOT NULL,[timegroup] [datetime]  NOT NULL,[timegroup_next] [datetime]  NOT NULL, [tlog] [INT] NULL)
end
else begin
	truncate table tmpSessionTimeGroup	
	--drop table tmpSessionGeneral
end


INSERT INTO #sessionTimeGroup
select * from tmpSessionGeneral

INSERT into #sessionTimeMayores SELECT * from #sessionTimeGroup where datediff(mi,timegroup,timegroup_next)>15
delete #sessionTimeGroup where  datediff(mi,timegroup,timegroup_next)>15

insert into #sessionTimeGroup
	select [User_id],login,logout,extension, convert(varchar,th.start,121) as timegroup, convert(varchar, th.stop,121) as timegroup_next,
	dbo.TimeInterval(th.start,th.stop,login,logout) as [tlog seg]	 

from #sessionTimeMayores t
inner join TmpTimesInterval th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
where  datediff(ss,th.start,timegroup_next)>0;

delete from #sessionTimeGroup where tlog=0 and DATEPART(MS,logout)<=700
	
update  #sessionTimeGroup set tlog=1 where tlog=0 and DATEPART(MS,logout)>700


insert into tmpSessionTimeGroup
select user_id,min([login]) as [login],max([logout]) as [logout],min(extension) as extension,timegroup,timegroup_next,sum(tlog) as tlog from #sessionTimeGroup	
group by user_id,timegroup,timegroup_next	
	

IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL drop table #sessionTimeGroup
IF OBJECT_ID(''tempdb..#sessionTimeMayores'') IS NOT NULL drop table #sessionTimeMayores;

set nocount off'
		EXEC(@sql)
		

		SET @process = ''
		SET @sql = ''
		EXEC(@sql)
				
		
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

