CREATE PROCEDURE [dbo].[ccspRepOutboundKPI]
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

			DELETE FROM RepOutboundKPI WITH (ROWLOCK) WHERE DATE >= @from AND DATE < @to

			create table #UniqueRecords (date datetime, UniqueRecordsCalled int)
			create table #Connects(date datetime, Connects int)
			create table #CallsOut(date datetime, Abandono int, RPC int, PTP int, PK int)
			create table #Quejas(date datetime, Quejas int)
	

			;with t as( select distinct convert(date,[date]) as date,callKey,telephone from RepOutDialDetail  ) 
			insert into #UniqueRecords
				select distinct convert(date,[date]),count(*) from t group by convert(date,[date]) order by convert(date,[date])
	
			;with te as (select date from RepOutCallsDetail where USERID >0 and dialog>0 )
			insert into #Connects
				select distinct convert(date,[date]) as date,count(*) from te group by convert(date,[date]) 

			insert into #CallsOut
				select convert(date,date),
					sum(Abandono) as Abandono,
					sum(RPC) as RPC,
					sum(PTP) as PTP,
					sum(PK) as PK
				from(
					select [cal_Inicio] as date,
						case when statusCall_id in (6,7,8) then 1 else 0 end Abandono,
						case when calif_id in (5,6,7,8,9,22,23,24,25,26,29,30,31,32,33,34) then 1 else 0 end RPC,
						case when calif_id in (5,6,7,8,9) then 1 else 0 end as PTP,
						case when calif_id in (46,47,48,49) then 1 else 0 end as PK
					from ccoCallsOut
				) as temp
				group by convert(date,date)

			insert into #Quejas
				select convert(date,[date]), sum(cuenta) 
				from (
				(select convert(date,[date]) as date,count(1) as cuenta from RepInCallsDetail where callStatusId=13 and dispositionId in (5,6,7,8,9,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,29,30,31,32,33,34,48,49) group by convert(date,[date]))
				union all
				(select convert(date,[cal_Inicio]) as date,count(1) as cuenta from ccoCallsOut where calif_id in (31) group by convert(date,[cal_inicio]) )
				) as final
				group by convert(date,[date]);

			insert into RepOutboundKPI
			select convert(date,final.date) as date,
				ISNULL(UniqueRecordsCalled, 0) as UniqueRecordCalled,
				sum(DialsAttempted) as DialsAttemted,
				sum(dialsComplete) as DialsCompleteRing,
				sum(Answer) as Answer,
				ISNULL(Connects, 0) as Connects,
				ISNULL(Abandono, 0) as Abandono,
				ISNULL(RPC, 0) as RPC,
				ISNULL(PTP, 0) as PTP,
				ISNULL(PK, 0) as PK,
				ISNULL(Quejas, 0) as Quejas,
				datepart(yyyy,max(final.date)) as year,
				datepart(mm,max(final.date)) as month,
				datepart(dd,max(final.date)) as day,
				datepart(hh,max(final.date)) as hours,
				datepart(mi,max(final.date)) as minutes
			from (
				select date as date,
					1 as DialsAttempted,
					case when dialResultId in (1,2,3,8,11,13) then 1 else 0 end dialsComplete,
					case when dialResultId in (1) then 1 else 0 end Answer
				from RepOutDialDetail
			) as final
			left join #UniqueRecords a on convert(date,final.date) = convert(date, a.date)
			left join #CallsOut b on convert(date,final.date) = convert(date, b.date)
			left join #Quejas c on convert(date,final.date) = convert(date, c.date)
			left join #Connects d on convert(date,final.date) = convert(date, d.date)
			where final.date between @from and @to
			group by convert(date,final.date), UniqueRecordsCalled, Abandono, RPC, PTP, PK, Quejas, Connects
			order by convert(date,final.date)

			drop table #UniqueRecords
			drop table #Connects
			drop table #CallsOut
			drop table #Quejas
	end