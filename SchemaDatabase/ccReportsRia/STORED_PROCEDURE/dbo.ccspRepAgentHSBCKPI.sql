CREATE PROCEDURE [dbo].[ccspRepAgentHSBCKPI]
		@action as tinyint,
		@from as datetime = null,
		@to as datetime = null
		AS

		SET NOCOUNT ON

		if @from is null
			select @from = convert(datetime,convert(varchar(11),getdate()))
		if @to is null
			select @to = getdate()

		if @action = 1
		begin
	
			DELETE	FROM RepAgentHSBCKPI WITH (ROWLOCK) WHERE DATE >= @from AND DATE < @to

			create table #General (date datetime, General decimal(10,2), OpHoursOutBound decimal(10,2), OpHoursInbound decimal(10,2), SignIn decimal(10,2))
			create table #AvgIdle(fecha datetime, IdleSeconds decimal(10,2), analistas int)

			insert into #General
			select convert(date, [date]) as date, sum(General), sum(OpHoursOutBound), sum(OpHoursInbound), sum(SignIn)
			from (
				(select convert(date,[cal_inicio]) as date,
					(CONVERT(decimal(10,2),(sum(cal_tDialog)+sum(cal_tNotas)+sum(cal_tXfer)+sum(cal_tRing)))) as general,
					(CONVERT(decimal(10,2),(sum(cal_tDialog)+sum(cal_tNotas)+sum(cal_tXfer)+sum(cal_tRing)))) as OpHoursOutBound,
					0 as OpHoursInbound,
					(CONVERT(decimal(10,2),(sum(cal_tDialog)+sum(cal_tNotas)+sum(cal_tXfer)+sum(cal_tRing)))) as SignIn
				from ccoCallsOut 
				group by convert(date,[cal_inicio]))
			union all
				(select convert(date,[date]) as date,
					(CONVERT(decimal(10,2),sum(xfertime)+sum(ringingTime)+sum(dialogTime))) as general,
					0 as OpHoursOutBound,
					(CONVERT(decimal(10,2),sum(xfertime)+sum(ringingTime)+sum(dialogTime))) as OpHoursInbound,
					(CONVERT(decimal(10,2),sum(xfertime)+sum(ringingTime)+sum(dialogTime))) as SignIn
				from RepInCallsDetail 
				group by convert(date,[date]))
			union all
				(select convert(date,[date]) as date, 
					(CONVERT(decimal(10,2),sum(tnotesout)+sum(tringout)+sum(tav)+sum(tnotav))) as general,
					0 as OpHoursOutBound,
					0 as OpHoursInbound,
					(CONVERT(decimal(10,2),sum(tnotesout)+sum(tringout))) as SignIn
				from RepAgentGI 
				group by convert(date,[date]))
			) as final
			group by convert(date,[date])

			;with calls as(select convert(date, cal_inicio) date, count(DISTINCT User_id) cuenta from ccoCallsOut where User_id > 0 group by convert(date,cal_inicio))
			insert into #AvgIdle
				select convert(date,a.date), 
					case when b.cuenta > 0 
						then CAST((cast(sum(tnotav) as float)/cast(b.cuenta as float))/3600 as decimal(10,2))
						else 0
					end IdleSeconds,
					b.cuenta as analistas
				from calls b
				join RepAgentGI a on convert(date,a.date) = convert(date, b.date)
				group by convert(date,a.date), cuenta
				order by convert(date,a.date)

			insert into RepAgentHSBCKPI
			select convert(date,a.date), 
				ISNULL(OpHoursOutBound, 0) / 3600 as OpHoursOutbound,
				ISNULL(OpHoursInbound, 0) / 3600 as OpHoursInbound,
				ISNULL(General, 0) / 3600  as PaidHours,
				case when analistas > 0 then ((ISNULL(General, 0) / analistas )) / 3600 else 0 end OffLineActivities,
				ISNULL(SignIn ,0) / 3600  as SignIn,
				ISNULL(IdleSeconds, 0) as AvgIdleSeconds,
				ISNULL(cast((cast(sum(tdialogout) as float) / 3600) as decimal(10,3)), 0) as AvgTalkSeconds,
				ISNULL(cast((cast(sum(tnotesout) as float) / 3600) as decimal(10,3)), 0) as AvgWrapSeconds,
				ISNULL(cast((cast((sum(tdialogout)+sum(tnotesout)) as float) / 3600) as decimal(10,3)), 0) as AvgAHTSeconds,
				datepart(yyyy,max(a.date)) as Year,
				datepart(mm,max(a.date)) as Month,
				datepart(dd,max(a.date)) as Day,
				datepart(hh,max(a.date)) as Hours,
				datepart(mi,max(a.date)) as Minutes
			from #General a
			left join RepAgentGI b on  convert(date,a.date) = convert(date,b.date)
			left join #AvgIdle c on convert(date,a.date) = convert(date,fecha)
			where a.date between @from and @to 
			group by convert(date,a.date), OpHoursOutBound, OpHoursInbound, General, SignIn, analistas, IdleSeconds
			order by convert(date,a.date)

			drop table #General
			drop table #AvgIdle
		end