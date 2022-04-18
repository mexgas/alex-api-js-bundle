CREATE PROCEDURE [dbo].[ccspRepInboundKPI]
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
	
			DELETE	FROM RepInboundKPI WITH (ROWLOCK) WHERE DATE >= @from AND DATE < @to
	
			CREATE TABLE #NumQuejas (fecha datetime, quejas int)
			CREATE TABLE #AvgSeconds (fecha datetime, TalkSeconds decimal(10,2), WrapSeconds decimal(10,2))
			create table #AvgIdle(fecha datetime, IdleSeconds decimal(10,2))

			insert into #NumQuejas
				select convert(date,[date]), sum(cuenta) 
				from (
				(select convert(date,[date]) as date,count(1) as cuenta from RepInCallsDetail where callStatusId=13 and dispositionId in (5,6,7,8,9,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,29,30,31,32,33,34,48,49) group by convert(date,[date]))
				union all
				(select convert(date,[cal_Inicio]) as date,count(1) as cuenta from ccoCallsOut where calif_id in (31) group by convert(date,[cal_inicio]) )
				) as final
				group by convert(date,[date])

			insert into #AvgSeconds
				select convert(date,[date]) as date,
					cast(sum(tdialogin) as float) / 3600 as TalkSeconds, 
					cast(sum(tnotesin) as float) / 3600 as WrapSeconds  
				from RepAgentGI 
				group by convert(date,[date]); 

			with calls as(select convert(date, cal_inicio) date, count(DISTINCT User_id) cuenta from ccoCallsOut group by convert(date,cal_inicio))
			insert into #AvgIdle
				select convert(date,a.date), 
					case when b.cuenta > 0 
						then CAST((cast(sum(tnotav) as float)/cast(b.cuenta as float))/3600 as decimal(10,2))
						else 0
					end IdleSeconds
				from calls b
				join RepAgentGI a on convert(date,a.date) = convert(date, b.date)
				group by convert(date,a.date), cuenta
				order by convert(date,a.date)

			insert into RepInboundKPI
			select convert(date,[date]) as date, 
				sum(NCO) as NCO, 
				sum(NCH) as NCH, 
				sum(Abandoned) as Abandoned,
				case when sum(SL2) > 0 
					then CAST( ( (cast(sum(SL1) as float) / cast(sum(SL2) as float)) * 100 ) as decimal(10,2)) 
					else 0 
				end as SL,
				sum(RPC) as RPC,
				sum(PTP) as PTP,
				SUM(PK) as PK,
				case when quejas > 0 then quejas else 0 end Quejas,
				ISNULL(IdleSeconds, 0) as AVGIdle,
				ISNULL(TalkSeconds, 0) as AVGTalkSeconds,
				ISNULL(WrapSeconds, 0) as AVGWrapSeconds,
				datepart(yyyy,max(date)) as year,
				datepart(mm,max(date)) as month,
				datepart(dd,max(date)) as day,
				datepart(hh,max(date)) as hours,
				datepart(mi,max(date)) as minutes
			from(
				select date as date, 1 as NCO,
					case when userid > 0 then 1 else 0 end NCH,
					case when callStatusId in (6,7,8) then 1 else 0 end Abandoned,
					case when callStatusId = 13 and queueTime < 21 then 1 else 0 end SL1,
					case when date between @from and @to then 1 else 0 end SL2,
					case when callStatusId=13 and dispositionId in (5,6,7,8,9,22,23,24,25,26,29,30,31,32,33,34) then 1 else 0 end RPC, 
					case when callStatusId=13 and dispositionId in (5,6,7,8,9) then 1 else 0 end PTP,
					case when callStatusId=13 and dispositionId in (46,47,48,49) then 1 else 0 end PK
				from RepInCallsDetail
			) as final
			left join #NumQuejas b on convert(date, date) = convert(date, fecha)
			left join #AvgSeconds c on convert(date, date) = convert(date, c.fecha)
			left join #AvgIdle d on convert(date, date) =convert(date, d.fecha)
			where date between @from and @to 
			group by convert(date,final.date), quejas, WrapSeconds, TalkSeconds, IdleSeconds
			order by convert(date,[date])

			drop table #NumQuejas
			drop table #AvgSeconds
			drop table #AvgIdle
	end