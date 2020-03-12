SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 77

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
		

		SET @process = 'CW-3930 alter ccspRepAgentNotReady'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentNotReady]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

SET ANSI_WARNINGS OFF
SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

create table #timeDetailAgent(
	[User_id] int not null,
	dateStartDetail datetime null,dateEndDetail datetime null,dateNext datetime null
	,timegroup datetime null,
	timegroup_next datetime null,tunknown int null,
	tnot_av int null,tav int null,tprob int null,
	tother int null,nother int null,tmanualcall int null,
	tunknown2 decimal(10,3)
	)

create table #sessionTime(
	[User_id] int not null,
	[login] [datetime] NOT NULL,
	[logout] [datetime] NULL,
	[extension] [varchar](7) NOT NULL
	)

CREATE TABLE #times(
	[ID] INT primary key, 
	[Start] DATETIME,	
	[Stop] DATETIME	
	)

CREATE TABLE #notReadyTimeGroup(	
	[user_id] [smallint] NOT NULL,
	[dateStartDetail] [datetime] NOT NULL,
	[dateEndDetail] [datetime] NULL,
	[timegroup] [datetime]  NOT NULL,
	[timegroup_next] [datetime]  NOT NULL, 
	typeNotReadyId [INT] NULL,
	timeNotReady int,
	[count] int
	)

CREATE TABLE #notReadyTimeGroupMayores(	
	[user_id] [smallint] NOT NULL,
	[dateStartDetail] [datetime] NOT NULL,
	[dateEndDetail] [datetime] NULL,
	[timegroup] [datetime] NOT NULL,
	[timegroup_next] [datetime] NOT NULL, 
	typeNotReadyId [INT] NULL,
	timeNotReady int,
	[count] int
	)

create nonclustered index ix_times on #times([Start] DESC,[Stop] DESC)
create nonclustered index ix_times2 on #times([Start] DESC)

declare @dateNow datetime
declare @starttime datetime,@number int
set @dateNow=getdate()
set @starttime = CONVERT(smalldatetime,CONVERT(varchar(13),@from,121)+ '':00'',121)
set @number = 0


if @action = 1
begin

insert into #times
exec ccspTimesReports @from=@from,@to=@to,@interval=60

insert into #sessionTime
exec [ccspGenSession] @from=@from,@to=@to

insert into #timeDetailAgent
exec ccsprepLogAgentriaseparate @from=@from,@to=@to

insert into #notReadyTimeGroup
	SELECT [User_id], DATEADD(ss,-(tStatus),(fecha)) as dateStartDetail,(fecha) as dateEndDetail,
		convert(smalldatetime,convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000'',121) AS timegroup,
		dateadd(hh,1,convert(smalldatetime,convert(varchar(13),fecha,121) + '':00:00.000'',121)) as timegroup_next, TipoNotReady_id,
		(tStatus) as [timeNotReady],1 as [count]
		FROM ccLogAgentesNotReady
		WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to
  
INSERT into #notReadyTimeGroupMayores SELECT * from #notReadyTimeGroup where datediff(mi,timegroup,timegroup_next)>15
delete #notReadyTimeGroup where  datediff(mi,timegroup,timegroup_next)>15


delete from RepAgentNotReady with(rowlock) 	where date >= @from AND date < @to

insert into RepAgentNotReady
	
select th.Start,
	c.Login,
	a.User_id as userId,
	c.ApellidoPaterno + '' '' + c.ApellidoMaterno + '' '' + c.Nombres as [user],
	datediff(ss,sT.login,sT.logout) as sessionTime,
	d.TipoNotReady_id as tiponotreadyId,
	d.Descripcion as Descripcion,
	d.Descripcion + ''_Count'' as descripcion_count,
	nR.count as count,
	d.Descripcion + ''_Time'' as descripcion_time,
	isnull(dbo.TimeInterval(th.start,th.stop,nR.dateStartDetail,nR.dateEndDetail), 0) as time,
	isnull(dbo.TimeInterval(th.start,th.stop,nR.dateStartDetail,nR.dateEndDetail), 0) as timeSeconds,
	datepart(yyyy,a.timegroup) year, 
	datepart(mm,a.timegroup) [month],
	datepart(dd,a.timegroup) [day], 
	datepart(hh,a.timegroup) [hour], 
	datepart(mi,a.timegroup) [minutes]
from #timeDetailAgent a
left outer join #notReadyTimeGroupMayores nR on (nR.user_id = a.User_id and nR.timegroup = a.timegroup)
inner join #times th on (nR.timegroup > th.Start and nR.timegroup < th.stop) OR th.Start between nR.timegroup and nR.timegroup_next
left outer join  ccUserView as c on (a.user_id = c.user_id)
left outer join #sessionTime as sT on (sT.User_id = a.User_id)
left outer join ccTipoNotReady as d on (nR.typeNotReadyId = d.tiponotready_id)
	
drop table #sessionTime
drop table #timeDetailAgent
drop table #times
drop table #notReadyTimeGroup
drop table #notReadyTimeGroupMayores

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
