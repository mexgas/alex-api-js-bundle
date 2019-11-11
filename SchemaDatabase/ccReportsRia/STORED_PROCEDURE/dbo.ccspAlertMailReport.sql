CREATE PROCEDURE [dbo].[ccspAlertMailReport]
@action int,@dateStart  datetime=null,@dateEnd datetime=null,@type int=0
AS
BEGIN
	if @action = 0 begin --Lista de accciones a ejecutar
		select id from ccRiaExecMailReport where tipo=1
	end
	if @action= 1 begin
		declare @schedule_id int,@nameSchudule sysname,@job_id uniqueidentifier
		declare @runDate int,@runDateTime datetime,@run_duration int
		set @runDate= cast (CONVERT(varchar(11),getdate(),112) as int)
		set @dateStart=CONVERT(datetime,getdate(),112)

		select  @job_id=A.job_id FROM msdb.dbo.sysjobs A where A.name='ReportsMasterProcess'

		select top 1
		@runDateTime=
		convert(datetime,
			cast(run_date as varchar(11))+' '+
			convert(varchar(max),STUFF(STUFF(RIGHT(REPLICATE('0', 6) +  CAST(run_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':') )
		)


		,@run_duration=run_duration
		from  msdb.dbo.sysjobhistory
		where job_id=@job_id and run_status=1 and
		run_date=@runDate
		and step_id=1
		order by instance_id desc

		select  @dateStart as dateStart,convert(datetime,CONVERT(varchar(13),dateadd(ss,-@run_duration,@runDateTime),121)+':00:00') as dateEnd,@run_duration as duration,@runDateTime as jobRun
	end
	else if @action=2 begin
		select distinct A.mailBox from ccRIAMailReports A
		inner join ccRIARelationValidateMailReports B on A.id=B.id and tipo=@type
	end
	else if @action=3 begin
		if @dateStart is null and @dateEnd is null select @dateStart = convert(datetime,convert(varchar(11),getdate())),@dateEnd=getdate()
		SELECT  [date], [userId],[user],[login] , sum([tlog]) AS [tlog]
		,sum(tunknown) as tunknown,sum(tnotav) as tnotav,sum(tav) as tav,sum(tother) as tother,sum(tprob) as tprob,sum(tChatting) as tChatting
		,sum(tdialogin) as tdialogin,sum(tnotesin) as tnotesin,sum(tringin) as tringin,sum(txferin) as txferin
		,sum(tdialogout) as tdialogout,sum(tnotesout) as tnotesout,sum(tringout) as tringout,sum(txferout) as txferout
		,sum(tundefined) as tundefined
		FROM RepAgentGI WITH(NOLOCK)
		WHERE date >= @dateStart AND date < @dateEnd
		GROUP BY [date], [userId],[user],[login]
		having sum(tlog)=0 or
		(sum(tdialogin)+sum(tnotesin)+sum(tringin)+sum(txferin)+sum(tdialogout)+sum(tnotesout)+sum(tringout)+sum(txferout)+sum(tunknown)+sum(tnotav)+sum(tav)+sum(tother)+sum(tprob)+sum(tChatting))>900
		or sum(tundefined)<0 or sum(tlog)>900
		order by tundefined
	end
	else if @action=4 begin
		select convert(datetime,CONVERT(varchar(13),fecha,121)+':00:00') as fecha,
		COUNT(*) as [Total de llamadas],
		isnull(cast(SUM(case when tipoResDial_id=1  then 1 end) as Decimal(8,2)),0) [TotalContesta],
		isnull(cast(SUM(case when tipoResDial_id=2  then 1 end) as Decimal(8,2)),0) [Total_Ocupado],
		isnull(cast(SUM(case when tipoResDial_id=3  then 1 end) as Decimal(8,2)),0) [Total_NoContesta],
		isnull(cast(SUM(case when tipoResDial_id=4  then 1 end) as Decimal(8,2)),0) [Total_Fax/Modem],
		isnull(cast(SUM(case when tipoResDial_id=5  then 1 end)as Decimal(8,2)),0) [Total_NoDialTone],
		isnull(cast(SUM(case when tipoResDial_id=8  then 1 end) as Decimal(8,2)),0) [Total_Otro],
		isnull(cast(SUM(case when tipoResDial_id=10  then 1 end)as Decimal(8,2)),0) [Total_NoService],
		isnull(cast(SUM(case when tipoResDial_id=11  then 1 end) as Decimal(8,2)),0) [Total_Buzon/Maquina],
		isnull(cast(SUM(case when tipoResDial_id=12  then 1 end) as Decimal(8,2)),0) [Total_Congestion],
		isnull(cast(SUM(case when tipoResDial_id=13  then 1 end) as Decimal(8,2)),0) [Total_Cancelado],
		isnull(cast(SUM(case when tipoResDial_id=80  then 1 end) as Decimal(8,2)),0) [Total_Rechazada p/central],
		isnull(cast(SUM(case when tipoResDial_id=90  then 1 end)as Decimal(8,2)),0) [Total_Otro_],
		isnull(cast(SUM(case when tipoResDial_id=1  then 1 end)*100.0/COUNT(*) as Decimal(8,2)),0) [%_Contesta],

		isnull(cast(SUM(case when tipoResDial_id=2  then 1 end)*100.0/COUNT(*)as Decimal(8,2)),0) [%_Ocupado],
		isnull(cast(SUM(case when tipoResDial_id=3  then 1 end)*100.0/COUNT(*)as Decimal(8,2)),0) [%_NoContesta],
		isnull(cast(SUM(case when tipoResDial_id=4  then 1 end)*100.0/COUNT(*)as Decimal(8,2)),0) [%_Fax/Modem],
		isnull(cast(SUM(case when tipoResDial_id=5  then 1 end)*100.0/COUNT(*)as Decimal(8,2)),0) [%_NoDialTone],
		isnull(cast(SUM(case when tipoResDial_id=8  then 1 end)*100.0/COUNT(*)as Decimal(8,2)),0) [%_Otro],
		isnull(cast(SUM(case when tipoResDial_id=10  then 1 end)*100.0/COUNT(*)as Decimal(8,2)),0) [%_NoService],
		isnull(cast(SUM(case when tipoResDial_id=11  then 1 end)*100.0/COUNT(*)as Decimal(8,2)),0) [%_Buzon/Maquina],
		isnull(cast(SUM(case when tipoResDial_id=12  then 1 end)*100.0/COUNT(*)as Decimal(8,2)),0) [%_Congestion],
		isnull(cast(SUM(case when tipoResDial_id=13  then 1 end)*100.0/COUNT(*)as Decimal(8,2)),0) [%_Cancelado],
		isnull(cast(SUM(case when tipoResDial_id=80  then 1 end)*100.0/COUNT(*)as Decimal(8,2)),0) [%_Rechazada p/central],
		isnull(cast(SUM(case when tipoResDial_id=90  then 1 end)*100.0/COUNT(*)as Decimal(8,2)),0) [%_Otro_]

		from ccoLogDials nolock
		where  fecha between CONVERT(datetime,GETDATE(),121) and GETDATE()
		group by convert(datetime,CONVERT(varchar(13),fecha,121)+':00:00')
		order by fecha asc
	end
END