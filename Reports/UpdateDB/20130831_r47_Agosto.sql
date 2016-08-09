/*
Autor: Raymundo Gonzalez
Fecha: 2013/08/31
Descripcion: 
	Se crea el indice IX_ccoCallBacks para mejora de rendimiento
	Se crea el indice IX_ccoLogDials_8 para mejora de rendimiento
	Se modifica el SP ccspGenMktIntervaloSalida para mejopra de rendimiento
	
Version requerida: 46
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '47'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @process = 'IX_ccoCallBacks - Create Index'
		set @Sql='IF NOT EXISTS (SELECT name FROM sysindexes WHERE name = ''IX_ccoCallBacks'')
BEGIN
	CREATE NONCLUSTERED INDEX [IX_ccoCallBacks] ON [dbo].[ccoCallBacks]
	(
	[callout_id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
END'
 
 	EXEC(@Sql)
 	
 		set @process = 'IX_ccoLogDials_8 - Create Index'
		set @Sql='CREATE NONCLUSTERED INDEX [IX_ccoLogDials_8] ON [dbo].[ccoLogDials]
(
	[cal_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
		
	EXEC(@Sql)

 		set @process = 'ccspGenMktIntervaloSalida - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccspGenMktIntervaloSalida]
AS
declare @from datetime
declare @to datetime
declare @tresDialog AS smallint
declare @tresRing AS smallint
declare @number int
declare @cam smallint
declare @cam2 smallint

set nocount on

select @from = convert(datetime,convert(varchar(11),dateadd(dd,-1,getdate())))
select @to = dateadd(dd,-1,getdate())

EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresRing=ccspConfigTresRing

select @number = 0

CREATE TABLE #times(
[Id]     [int],
[fecha]  [datetime],
[rango1] [varchar](5),
[rango2] [varchar](5)
)

while @number < (datediff(mi,@from,DATEADD(DD,1,@from))/30) 
begin
	insert into #times
	SELECT @number,
	@from,
	StartTime = right(''00'' + cast(datepart(hh,DATEADD(mi, @number*30, @from)) as varchar(2)),2) + '':'' + right(''00'' + cast(datepart(mi,DATEADD(mi, @number*30, @from)) as varchar(2)),2),
	EndTime = right(''00'' + cast(datepart(hh,DATEADD(mi, (@number+1)*30, @from)) as varchar(2)),2) + '':'' + right(''00'' + cast(datepart(mi,DATEADD(mi, (@number+1)*30, @from)) as varchar(2)),2)

	set @number = @number +1
end

delete ccGenMktIntervaloSalida where dia = convert(varchar(10),@from,121)

declare camps cursor for
	
select distinct cam_id
from ccPosicionCamps with(nolock)
where fecha >= @from
and fecha <= @to

open camps
fetch next from camps into @cam
while @@fetch_status = 0
begin
	create table #sessionTime (
	[user_id] int,
	[tlogueo] int,
	[login] datetime,
	logout datetime,
	login2 varchar(5),
	logout2 varchar(5)
	)

	insert into #sessionTime
	select [user_id], datediff(ss, min(login), max(logout)) as tlogueo, min(login) as login, max(logout) as logout,
	case when datepart(mi,min(login)) < 30 then right(''00'' + cast(datepart(hh,min(login)) as varchar(2)),2) + '':00'' 
	else right(''00'' + cast(datepart(hh,min(login)) as varchar(2)),2) + '':30'' end as login2,
	case when datepart(mi,max(logout)) < 30 then right(''00'' + cast(datepart(hh,max(logout)) as varchar(2)),2) + '':30'' 
	else right(''00'' + cast(datepart(hh,max(logout)) + 1 as varchar(2)),2) + '':00'' end as logout2
	from
	(
	select a.[user_id], a.fecha as ''login'',
	(select isnull(max(Fecha),getdate())
	from ccPosicionCamps b with(nolock)
	where b.user_id = a.user_id and
	b.tipo = 0 and
	b.cam_id = @cam and
	b.fecha >= a.fecha and
	b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
			from ccPosicionCamps with(nolock)
			where [user_id] = b.[user_id] and
			tipo = 1 and
			fecha > a.fecha
			and cam_id = @cam)
	) as ''logout''
	from ccPosicionCamps a
	where a.tipo=1
	and fecha >= @from
	and fecha <= @to
	and cam_id = @cam
	union
	select *
	from(
	select a.[user_id],
	(select isnull(max(Fecha),getdate())
		from ccPosicionCamps b with(nolock)
		where b.[user_id] = a.[user_id] and
		b.tipo = 1 and
		b.cam_id = @cam and
		b.fecha <= a.fecha and
		b.fecha >= (select isnull(max(fecha),b.fecha)
					from ccPosicionCamps with(nolock)
					where [user_id] = b.[user_id] and
					tipo = 0 and
					fecha < a.fecha and
					cam_id = @cam)
		) as ''login'', a.fecha as ''logout''
	from ccPosicionCamps a
	where a.tipo = 0
	and fecha >= @from
	and fecha <= @to
	and cam_id = @cam
	) as session
	where datediff(day,[login],logout) >= 1
	) as Detail
	group by [user_id]
	order by [user_id], login

	insert into ccGenMktIntervaloSalida (dia,rango1,rango2,Recibidas,Staff,Contactos,Ocupado,NoContestan,Fax,Buzon,SinTono,NoServicie,Otro,Congestion,Cancelado,
	Contestadas,Abandonadas,SinAgentes,NoContestadas,CortadasRing,CortadasDespRing,CortadasDlg,TMO,TiempoTotalTT,TiempoTotalHold,TiempoTotalACW,TiempoTotalRing,
	TiempoTotalAvail,TiempoTotalAUX,TiempoPersonal,VelocidadResp,Reductor,Abandono,OcupacionCOPC,Cam_id)
	select convert(varchar(10),@from,121),r.rango1,r.rango2,isnull(Recibidas,0),isnull(uid,0),isnull(Contactos,0),isnull(Ocupado,0),isnull(NoContestan,0),
	isnull(Fax,0),isnull(Buzon,0),isnull(SinTono,0),isnull(NoServicie,0),isnull(Otro,0),isnull(Congestion,0),isnull(Cancelado,0),isnull(Contestadas,0),
	isnull(Abandonadas,0),isnull(SinAgentes,0),isnull(NoContestadas,0),isnull(CortadasRing,0),isnull(CortadasDespRing,0),isnull(CortadasDlg,0),
	isnull(TMO,''00:00:00''),isnull(TiempoTotalTT,''00:00:00''),isnull(TiempoTotalHold,''00:00:00''),isnull(TiempoTotalACW,''00:00:00''),isnull(TiempoTotalRing,''00:00:00''),
	dbo.fgethhmmss(A.tdispo),dbo.fgethhmmss(A.tnodispo),dbo.fgethhmmss(L.tlogueofra),isnull(VelocidadResp,''00:00:00''),
	isnull(case when L.tlogueofra=0 then 0 else (Reductor1+A.tnodispo)*100/L.tlogueofra end,0),isnull(Abandono,0),
	isnull(case when L.tlogueofra=0 then 0 else Ocupacion*100.00/L.tlogueofra end,0),@cam
	from(
		select 	
			case when CONVERT(int, SUBSTRING(CONVERT(char(30),case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end), 16, 2)) / 30=0 then 
			CONVERT(varchar(2), case when ({ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then 
			''0''+convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else 
			convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''00'' else 
			CONVERT(varchar(2),case when ({ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then 
			''0''+convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else 
			convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''30'' end
			as rango1,
			COUNT(*) [Recibidas],
			COUNT(case when tipoResDial_id = 2 then 1 else null end) Ocupado,
			COUNT(case when tipoResDial_id = 3 then 1 else null end) NoContestan,
			COUNT(case when tipoResDial_id = 4 then 1 else null end) Fax,
			COUNT(case when tipoResDial_id = 11 then 1 else null end) Buzon,
			COUNT(case when tipoResDial_id = 5 then 1 else null end) SinTono,
			COUNT(case when tipoResDial_id = 10 then 1 else null end) NoServicie,
			COUNT(case when tipoResDial_id = 8 then 1 else null end) Otro,
			COUNT(case when tipoResDial_id = 12 then 1 else null end) Congestion,
			COUNT(case when tipoResDial_id = 13 then 1 else null end) Cancelado,
			COUNT(case when tipoResDial_id = 1 then 1 else null end) [Contactos], --contactos sistema
			COUNT(case when statuscall_id=13 and cal_tdialog > @tresDialog then 1 else null end) [Contestadas], --contactos agente
			COUNT(case when statusCall_id in (6,10,11,12,14,15,16) or (canceledNoAgents<>0 and answerbit=1) or (statuscall_id=13 and cal_tdialog <=@tresDialog) then 1 else null end) [Abandonadas],
			COUNT(case when statuscall_id = 6 then 1 else null end) SinAgentes,
			COUNT(case when statuscall_id in (15,16) then 1 else null end) NoContestadas,
			COUNT(case when statuscall_id in (11,10,12,14) and cal_tring<=@tresRing then 1 else null end) CortadasRing,
			COUNT(case when statuscall_id in (11,10,12,14) and cal_tring>@tresRing then 1 else null end) CortadasDespRing,
			COUNT(case when statuscall_id=13 and cal_tdialog <=@tresDialog then 1 else null end) CortadasDlg,
			dbo.fgethhmmss(case when COUNT(case when statuscall_id=13 then 1 else null end)=0 then 0 else SUM(cal_tDialog+cal_tNotas+cal_tRing+cal_tXfer+cal_tMoh)/COUNT(case when statuscall_id=13 then 1 else null end) end) [TMO],
			dbo.fgethhmmss(case when COUNT(case when statuscall_id=13 then 1 else null end)=0 then 0 else SUM(cal_tDialog)/COUNT(case when statuscall_id=13 then 1 else null end) end) [TiempoTotalTT],
			dbo.fgethhmmss(SUM(cal_tMoh)) [TiempoTotalHold],
			dbo.fgethhmmss(sum(cal_tnotas)) [TiempoTotalACW],
			dbo.fGetHHmmSS(sum(cal_tring+cal_txfer)) [TiempoTotalRing],
			dbo.fGetHHmmSS(case when COUNT(case when statuscall_id=13 then 1 else null end)=0 then 0 else sum(cal_twait)/COUNT(case when statuscall_id=13 then 1 else null end) end) [VelocidadResp],
			SUM(cal_tnotas) Reductor1,
			cast(case when count(case when statusCall_id=13 then 1 else null end)=0 then 0 else count(case when statusCall_id in (6,10,11,12,14,15,16) or (canceledNoAgents<>0 and answerbit=1) or (statuscall_id=13 and cal_tdialog <=@tresDialog) then 1 else null end)*100.00/count(case when tipoResDial_id=1 then 1 else null end) end as decimal(5,2)) [Abandono],
			SUM(cal_tDialog+cal_tNotas+cal_tRing+cal_tXfer+cal_tMoh) [Ocupacion]
		from ccologdials lo (nolock) 
		left join ccoCallsOut co (nolock) on co.cal_id=lo.cal_id
		where fecha between @from and @to 
		and lo.cam_id=@cam 
		group by case when CONVERT(int, SUBSTRING(CONVERT(char(30), case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end), 16, 2)) / 30=0 then 
			CONVERT(varchar(2), case when ({ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then 
			''0''+convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else 
			convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''00'' else 
			CONVERT(varchar(2),case when ({ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then 
			''0''+convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else 
			convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''30'' end)x
		right join #times r on r.rango1=x.rango1	
		inner join(
			select Pg.rango1 rango1, Pg.rango2 rango2, count(distinct Pg.uid) uid, sum(Pg.tlogueofra) tlogueofra
			from(
				select Ss.rango1 rango1, Ss.rango2 rango2, Tt.user_id uid,
				sum(case when convert(varchar(8),Tt.login,108)>Ss.rango1 and convert(varchar(8),Tt.logout,108)<(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,convert(varchar(8),Tt.login,108),convert(varchar(8),Tt.logout,108))
							when convert(varchar(8),Tt.login,108)>Ss.rango1 and convert(varchar(8),Tt.logout,108)>(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,convert(varchar(8),Tt.login,108),(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end))
							when convert(varchar(8),Tt.login,108)<Ss.rango1 and convert(varchar(8),Tt.logout,108)>(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then 1800
							when convert(varchar(8),Tt.login,108)<Ss.rango1 and convert(varchar(8),Tt.logout,108)<(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,Ss.rango1,convert(varchar(8),Tt.logout,108))
				else 0 end) tlogueofra 						
				from #times Ss
				LEFT OUTER JOIN #sessionTime Tt ON Tt.login2 <= Ss.rango1 and (Tt.logout2 >= case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end or Tt.logout2 is null)		
				group by Ss.rango1,	Ss.rango2, Tt.user_id) PG
			group by Pg.rango1,	Pg.rango2) L on L.rango1=r.rango1 and L.rango2=r.rango2
		inner join(
			select Tm.fecha fecha, Tm.rango1 rango1, Tm.rango2 rango2, isnull(sum(case when Tm.TipoStatusAge_id=2 then Tm.tstatusfra end),0) tnodispo,
				isnull(count(case when Tm.TipoStatusAge_id=2 then Tm.nstatusfra end),0) nnodispo, isnull(sum(case when Tm.TipoStatusAge_id=3 then Tm.tstatusfra end),0) tdispo,
				isnull(count(case when Tm.TipoStatusAge_id=3 then Tm.nstatusfra end),0) ndispo, ISNULL(sum(Tm.tstatusfra),0) TTotal, ISNULL(count(Tm.nstatusfra),0) NTotal
			from(
				select G.fecha fecha,G.rango1 rango1,G.rango2 rango2,G.user_id user_id,
					case when G.login >= Rg.RangoFinal then 0
						 when G.tlogueofra = 1800 and Rg.tstatusfra = 1800 then 1800 
						 -- Donde solamente RangoInicial y RangoFinal se encuentran fuera del Rango					 
						 when Rg.tstatusfra = 1800 then G.tlogueofra 
						 -- Donde solamente Login y Logout se encuentran fuera del Rango
						 when G.tlogueofra = 1800 then Rg.tstatusfra 
						 -- Rangos de ccLogLogin y ccPosicionEspecialidad se ubican entre Rango1 y Rango2
						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and Rg.RangoInicial >= G.login and Rg.RangoFinal >= G.logout) then datediff(ss,Rg.RangoInicial,G.logout) 
						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(8),G.login,108) >= G.rango1 and convert(varchar(8),G.logout,108) <= G.rango2) and (G.login >= Rg.RangoInicial and G.logout <= Rg.RangoFinal) then datediff(ss,G.login,G.logout) 
						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(8),G.login,108) >= G.rango1 and convert(varchar(8),G.logout,108) <= G.rango2) and (G.login >= Rg.RangoInicial and G.logout >= Rg.RangoFinal) then datediff(ss,G.login,Rg.RangoFinal)
						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(8),G.login,108) >= G.rango1 and convert(varchar(8),G.logout,108) <= G.rango2) and (G.login <= Rg.RangoInicial and G.logout <= Rg.RangoFinal) then datediff(ss,Rg.RangoInicial,G.logout)
						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(8),G.login,108) >= G.rango1 and convert(varchar(8),G.logout,108) <= G.rango2) and (G.login <= Rg.RangoInicial and G.logout >= Rg.RangoFinal) then datediff(ss,Rg.RangoInicial,Rg.RangoFinal)
						 -- Donde solamente Logout se encuentra fuera del Rango1 y Rango2
						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(8),G.login,108) >= G.rango1 and convert(varchar(8),G.logout,108) >= G.rango2) and (G.login >= Rg.RangoInicial) then datediff(ss,G.login,Rg.RangoFinal) 
						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(8),G.login,108) >= G.rango1 and convert(varchar(8),G.logout,108) >= G.rango2) and (G.login <= Rg.RangoInicial) then datediff(ss,Rg.RangoInicial,Rg.RangoFinal) 
						 -- Donde solamente login se encuentra fuera del Rango1 y Rango2
						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(8),G.login,108) <= G.rango1 and convert(varchar(8),G.logout,108) <= G.rango2) and (G.logout <= Rg.RangoFinal) then datediff(ss,Rg.RangoInicial,G.logout) 
						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(8),G.login,108) <= G.rango1 and convert(varchar(8),G.logout,108) <= G.rango2) and (G.logout >= Rg.RangoFinal) then datediff(ss,Rg.RangoInicial,Rg.RangoFinal)
						 -- Donde solamente RangoFinal se encuentra fuera del Rango1 y Rango2
						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(8),G.login,108) >= G.rango1 and convert(varchar(8),G.logout,108) <= G.rango2) and (G.login >= Rg.RangoInicial) then datediff(ss,G.login,G.logout) 
						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(8),G.login,108) >= G.rango1 and convert(varchar(8),G.logout,108) <= G.rango2) and (G.login <= Rg.RangoInicial) then datediff(ss,Rg.RangoInicial,G.logout) 
						 -- Donde solamente Rangoinicial se encuentra fuera del Rango1 y Rango2
						 when (convert(varchar(8),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(8),G.login,108) >= G.rango1 and convert(varchar(8),G.logout,108) <= G.rango2) and (G.logout <= Rg.RangoFinal) then datediff(ss,G.login,G.logout) 
						 when (convert(varchar(8),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(8),G.login,108) >= G.rango1 and convert(varchar(8),G.logout,108) <= G.rango2) and (G.logout >= Rg.RangoFinal) then datediff(ss,G.login,Rg.RangoFinal)
						 -- Donde solamente RangoInicial y Login son menores a Rango1
						 when (convert(varchar(8),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(8),G.login,108) <= G.rango1 and convert(varchar(8),G.logout,108) <= G.rango2) and (G.logout <= Rg.RangoFinal) then datediff(ss,G.Rango1,convert(varchar(8),G.logout,108)) 
						 when (convert(varchar(8),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(8),G.login,108) <= G.rango1 and convert(varchar(8),G.logout,108) <= G.rango2) and (G.logout >= Rg.RangoFinal) then datediff(ss,G.Rango1,convert(varchar(8),Rg.RangoFinal,108)) 
						 -- Donde solamente RangoFinal y Logout son mayores a Rango2
						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(8),G.login,108) >= G.rango1 and convert(varchar(8),G.logout,108) >= G.rango2) and (G.login >= Rg.RangoInicial) then datediff(ss,convert(varchar(8),G.login,108),G.Rango2) 
						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(8),G.login,108) >= G.rango1 and convert(varchar(8),G.logout,108) >= G.rango2) and (G.login <= Rg.RangoInicial) then datediff(ss,convert(varchar(8),Rg.RangoInicial,108),G.Rango2)
						 -- Donde logout y RangoInicial no pertenecen al Rango1 y Rango2
						 when (convert(varchar(8),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(8),G.login,108) >= G.rango1 and convert(varchar(8),G.logout,108) >= G.rango2) and (G.login <= Rg.RangoFinal) then datediff(ss,G.login,Rg.RangoFinal) 
						 when (convert(varchar(8),Rg.RangoInicial,108) <= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) <= G.rango2 and convert(varchar(8),G.login,108) >= G.rango1 and convert(varchar(8),G.logout,108) >= G.rango2) and (G.login >= Rg.RangoFinal) then datediff(ss,Rg.RangoFinal,G.login) 
						 -- Donde login y RangoFinal no pertenecen al Rango1 y Rango2
 						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(8),G.login,108) <= G.rango1 and convert(varchar(8),G.logout,108) <= G.rango2) and (G.logout <= Rg.RangoInicial) then datediff(ss,G.logout,Rg.RangoInicial) 
 						 when (convert(varchar(8),Rg.RangoInicial,108) >= G.rango1 and convert(varchar(8),Rg.RangoFinal,108) >= G.rango2 and convert(varchar(8),G.login,108) <= G.rango1 and convert(varchar(8),G.logout,108) <= G.rango2) and (G.logout >= Rg.RangoInicial) then datediff(ss,Rg.RangoInicial,G.logout) 
						 else 0     
					end  tstatusfra,
					case when Rg.tstatusfra is not null then 1 else 0 end nstatusfra,G.tlogueofra tlogueofra,Rg.TipoStatusAge_id TipoStatusAge_id
				from(
					select distinct (S.fecha + S.rango1) fecha, S.rango1 rango1, S.rango2 rango2, T.user_id user_id, T.tlogueo tlogueo, T.login login, T.logout logout,
						T.login2 login2, T.logout2 logout2,
						case when convert(varchar(8),t.login,108)>s.rango1 and convert(varchar(8),t.logout,108)<(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,convert(varchar(8),t.login,108),convert(varchar(8),t.logout,108))
				    			 when convert(varchar(8),t.login,108)>s.rango1 and convert(varchar(8),t.logout,108)>(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,convert(varchar(8),t.login,108),(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end))
								 when convert(varchar(8),t.login,108)<s.rango1 and convert(varchar(8),t.logout,108)>(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then 1800
								 when convert(varchar(8),t.login,108)<s.rango1 and convert(varchar(8),t.logout,108)<(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,s.rango1,convert(varchar(8),t.logout,108))
						else 0 end tlogueofra 						
					from #times S
					LEFT OUTER JOIN #sessionTime t ON t.login2 <= s.rango1 and (t.logout2 >= case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end or t.logout2 is null))G
				LEFT OUTER JOIN
					(select	lg.user_id user_id, lg.rangoinicial rangoinicial, lg.rangofinal rangofinal, V.rango1 rango1, V.rango2 rango2,
						sum(case when convert(varchar(8),lg.rangoInicial,108)>V.rango1 and convert(varchar(8),lg.rangoFinal,108)<(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,convert(varchar(8),lg.rangoInicial,108),convert(varchar(8),lg.rangoFinal,108))
								 when convert(varchar(8),lg.rangoInicial,108)>V.rango1 and convert(varchar(8),lg.rangoFinal,108)>(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,convert(varchar(8),lg.rangoInicial,108),(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end))
								 when convert(varchar(8),lg.rangoInicial,108)<V.rango1 and convert(varchar(8),lg.rangoFinal,108)>(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then 1800
								 when convert(varchar(8),lg.rangoInicial,108)<V.rango1 and convert(varchar(8),lg.rangoFinal,108)<(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,V.rango1,convert(varchar(8),lg.rangoFinal,108))
						else 0 end) tstatusfra, sum(lg.tstatus) tstatus, lg.TipoStatusAge_id TipoStatusAge_id
					 from(
						select user_id as user_id, dateadd(ss,-1*(t.tStatus),t.fecha) rangoInicial,t.fecha rangoFinal,							
							isnull(case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,-1*(t.tstatus),t.fecha)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''30'' end,0) rango1,
							isnull(case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(t.fecha) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(t.fecha) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) end)+'':''+''30'' end,0) rango2,														
							sum(t.tStatus) tstatus, t.TipoStatusAge_id TipoStatusAge_id
						from  cclogagentesdia t with (index(ccLogAgentesDia_fecAsc),nolock) 
						where t.fecha between @from and @to
						group by user_id,dateadd(ss,-1*(t.tStatus),t.fecha),t.fecha,
							isnull(case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,-1*(t.tstatus),t.fecha)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''30'' end,0),
							isnull(case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(t.fecha) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(t.fecha) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) end)+'':''+''30'' end,0),
							t.TipoStatusAge_id) lg
				left outer join 
					(SELECT rango1,rango2 from #times) V on (V.rango1 >= lg.rango1 and case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end <= lg.rango2)
			group by lg.user_id,lg.rangoinicial,lg.rangofinal,V.rango1,V.rango2,lg.TipoStatusAge_id ) Rg
		on (Rg.user_id = G.user_id and Rg.rango1 = G.rango1 and Rg.rangoinicial < G.logout and Rg.rangofinal > G.login)) Tm
	group by Tm.fecha,Tm.rango1,Tm.rango2)A on A.rango1 = r.rango1 and A.rango2 = r.rango2 

	drop table #sessionTime

	fetch next from camps into @cam
end
	
close camps
deallocate camps

declare camps2 cursor for
	
select distinct cam_id
from ccCamps with(nolock)
where cam_id not in (select cam_id 
					from ccPosicionCamps
					where fecha >= @from
					and fecha <= @to)

open camps2
fetch next from camps2 into @cam2
while @@fetch_status = 0
begin

	insert into ccGenMktIntervaloSalida (dia,rango1,rango2,Recibidas,Staff,Contactos,Ocupado,NoContestan,Fax,Buzon,SinTono,NoServicie,Otro,Congestion,Cancelado,
	Contestadas,Abandonadas,SinAgentes,NoContestadas,CortadasRing,CortadasDespRing,CortadasDlg,TMO,TiempoTotalTT,TiempoTotalHold,TiempoTotalACW,TiempoTotalRing,
	TiempoTotalAvail,TiempoTotalAUX,TiempoPersonal,VelocidadResp,Reductor,Abandono,OcupacionCOPC,Cam_id)
	select convert(varchar(10),fecha,121), rango1, rango2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
	''00:00:00'', ''00:00:00'', ''00:00:00'', ''00:00:00'', ''00:00:00'', ''00:00:00'', ''00:00:00'', ''00:00:00'', ''00:00:00'',
	0.00, 0.00, 0.00, @cam2
	from #times

	fetch next from camps2 into @cam2

end

close camps2
deallocate camps2

drop table #times'
		
	EXEC(@Sql)

------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
