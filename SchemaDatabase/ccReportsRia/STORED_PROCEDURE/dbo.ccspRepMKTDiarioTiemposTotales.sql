CREATE PROCEDURE [dbo].[ccspRepMKTDiarioTiemposTotales]
@action as tinyint,
@from as datetime = null,
@to as datetime = null

AS

SET NOCOUNT ON

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

declare @dateNow datetime,@maxLogout datetime

if @action = 1
begin



select 
	convert(datetime,convert(date,login)) fecha,
	SUM(DATEDIFF(ss, login, logout)) t_ses,
	count(distinct user_id) user_id
into #infoSession
from TmpSessionGeneral
GROUP BY convert(datetime,convert(date,login))

SELECT 
		i.cal_Inicio as [date],
		i.user_id as acduser,
		i.Inbound_id as inboundId,
		case when i.statuscall_id=13 then i.cal_tmoh else 0 end thold,
		case when i.statusCall_id=13 then i.cal_tring else 0 end tring,
		case when i.statusCall_id=13 and i.cal_tdialog>=0 then i.cal_tdialog else 0 end tacd,
		case when i.statusCall_id=13 then i.cal_tnotas else 0 end tacw,
		case when i.statusCall_id=13 then 1 else null end nacd,
		case when i.statusCall_id=13 and i.cal_tnotas>0 then 1 else null end nacw,
		case when i.statusCall_id=13 and i.cal_tmoh>0 then 1 else null end nhold,
		case when i.statusCall_id=13 and i.cal_tring>0 then 1 else null end nring	
	into #inboundData2			
	FROM	cccallsin i (NOLOCK)	
	WHERE	i.cal_inicio between @from and @to

SELECT user_id AS agtuser_id,
	login AS agtlogin,
	ISNULL(apellidopaterno,'')+' '+ISNULL(apellidomaterno,'')+' '+ISNULL(nombres,'') agt_name
	into #users
	FROM ccUserView (NOLOCK)

	delete from [RepMKTDiarioTiemposTotales] with(rowlock) 	where date >= @from AND date <= @to 

	insert RepMKTDiarioTiemposTotales 
	select c.[date]	--
		,isnull(l.agtlogin,'N/A') as [OpaId]
		,isnull(l.agt_name,'') [NombreDeOperadora]
		,[InboundID]--
		,[TiempoPromACD]--
		,[TiempoPromACW]--
		,[TiempoPromReten]
		,[TiempoPromRing]
		,[AHT]
		,[LlamadasAtendidas]
		,DATEPART(YYYY, c.[date]) as [year] 
		,DATEPART(mm, c.[date]) as [month]
		,DATEPART(dd, c.[date]) as [day]
		,DATEPART(hh, c.[date]) as [hour]
		,DATEPART(mi, c.[date]) as [minutes]
	 from (
		select convert(datetime,convert(date,[date])) as [date],
			acduser as [user],
			inboundId as [InboundId]
			,case when sum(c.nacd)>0 then sum(c.tacd)/sum(c.nacd) else 0 end as [TiempoPromACD]
			,case when sum(c.nacw)>0 then sum(c.tacw)/sum(c.nacw) else 0 end as [TiempoPromACW]
			,case when sum(c.nhold)>0 then sum(c.thold)/sum(c.nhold) else 0 end as [TiempoPromReten]
			,case when sum(c.nring)>0 then sum(c.tring)/sum(c.nring) else 0 end as [TiempoPromRing]
			,sum(((case when c.nacd>0 then c.tacd/c.nacd else 0 end)+(case when c.nacw>0 then c.tacw/c.nacw else 0 end)+(case when c.nring>0 then c.tring/c.nring else 0 end)+(case when c.nhold>0 then c.thold/c.nhold else 0 end))) [AHT]
			,isnull(sum(c.nacd),0) as [LlamadasAtendidas]
		from #inboundData2 as c 
		group by convert(datetime,convert(date,[date])),inboundId,acduser
	) c
	LEFT JOIN #infoSession G on G.fecha = c.date
	left join #users l on [user]=l.agtuser_id	
	WHERE @from <= C.[date] AND @to >= c.[date] and [LlamadasAtendidas]>0
	order by [date]

drop table #inboundData2
drop table #infoSession 
drop table #users

end