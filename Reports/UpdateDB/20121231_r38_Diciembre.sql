/*
Autor: Raymundo Gonzalez
Fecha: 2012/12/31
Descripcion: 
	Se elimina trigger trigPosicionEspecialidad para crearse en CCenterRia usado en Muñoz
	Se agrega el campo cal_twait en la tabla ccoCallsOut para paso de informacion usada en reporte de Muñoz
	Se crea el SP ccspGenMktIntervaloSalida para reporte en Muñoz
	Se crea el SP sp_mkt_intervalos_out para reporte en Muñoz
	Se modifica el SP sp_mkt_intervalo_TiemposAcumuladosTotales para reporte de Muñoz
	
Version requerida: 37
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '38'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @Sql='IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N''[dbo].[trigPosicionEspecialidad]''))
DROP TRIGGER [dbo].[trigPosicionEspecialidad]'
	
	EXEC(@Sql)

		set @Sql='ALTER TABLE ccoCallsOut 
ADD cal_twait smallint not null default 0'
	
	EXEC(@Sql)

		set @Sql = 'DECLARE @var1 varchar(max)

SELECT @var1 = cols + '',cal_twait'' FROM exportReports WHERE jobId = 1

UPDATE exportReports SET cols = @var1 WHERE jobId = 1'

	EXEC(@Sql)
	
		set @Sql='CREATE PROCEDURE [dbo].[ccspGenMktIntervaloSalida]
AS
declare @from datetime
declare @cam smallint
declare @to datetime
declare @from3 datetime
declare @from2 datetime
declare @tresDialog AS smallint
declare @tresRing AS smallint

EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresRing=ccspConfigTresRing

select @from=dateadd(dd,-1,getdate())

select @from=CONVERT(datetime,CONVERT(varchar(4),YEAR(@from))+''-''+CONVERT(varchar(2), MONTH(@from))+''-''+CONVERT(varchar(2), DAY(@from)))
select @to=convert(varchar(10),dateadd(dd,1,@from),121)
select @from3=convert(varchar(10),@from,121)

delete ccGenMktIntervaloSalida where dia=@from

create table #ccintervalos
   ([Id]     [int],
    [fecha]  [datetime],
    [rango1] [varchar](5),
	[rango2] [varchar](5))

insert into #ccintervalos values(0,@from3,''00:00'',''00:30'')	
insert into #ccintervalos values(1,@from3,''00:30'',''01:00'')	
insert into #ccintervalos values(2,@from3,''01:00'',''01:30'')
insert into #ccintervalos values(3,@from3,''01:30'',''02:00'')
insert into #ccintervalos values(4,@from3,''02:00'',''02:30'')
insert into #ccintervalos values(5,@from3,''02:30'',''03:00'')
insert into #ccintervalos values(6,@from3,''03:00'',''03:30'')
insert into #ccintervalos values(7,@from3,''03:30'',''04:00'')
insert into #ccintervalos values(8,@from3,''04:00'',''04:30'')
insert into #ccintervalos values(9,@from3,''04:30'',''05:00'')
insert into #ccintervalos values(10,@from3,''05:00'',''05:30'')
insert into #ccintervalos values(11,@from3,''05:30'',''06:00'')	
insert into #ccintervalos values(12,@from3,''06:00'',''06:30'')
insert into #ccintervalos values(13,@from3,''06:30'',''07:00'')
insert into #ccintervalos values(14,@from3,''07:00'',''07:30'')
insert into #ccintervalos values(15,@from3,''07:30'',''08:00'')
insert into #ccintervalos values(16,@from3,''08:00'',''08:30'')
insert into #ccintervalos values(17,@from3,''08:30'',''09:00'')
insert into #ccintervalos values(18,@from3,''09:00'',''09:30'')
insert into #ccintervalos values(19,@from3,''09:30'',''10:00'')
insert into #ccintervalos values(20,@from3,''10:00'',''10:30'')
insert into #ccintervalos values(21,@from3,''10:30'',''11:00'')
insert into #ccintervalos values(22,@from3,''11:00'',''11:30'')
insert into #ccintervalos values(23,@from3,''11:30'',''12:00'')
insert into #ccintervalos values(24,@from3,''12:00'',''12:30'')
insert into #ccintervalos values(25,@from3,''12:30'',''13:00'')
insert into #ccintervalos values(26,@from3,''13:00'',''13:30'')
insert into #ccintervalos values(27,@from3,''13:30'',''14:00'')
insert into #ccintervalos values(28,@from3,''14:00'',''14:30'')
insert into #ccintervalos values(29,@from3,''14:30'',''15:00'')
insert into #ccintervalos values(30,@from3,''15:00'',''15:30'')
insert into #ccintervalos values(31,@from3,''15:30'',''16:00'')
insert into #ccintervalos values(32,@from3,''16:00'',''16:30'')
insert into #ccintervalos values(33,@from3,''16:30'',''17:00'')
insert into #ccintervalos values(34,@from3,''17:00'',''17:30'')
insert into #ccintervalos values(35,@from3,''17:30'',''18:00'')
insert into #ccintervalos values(36,@from3,''18:00'',''18:30'')
insert into #ccintervalos values(37,@from3,''18:30'',''19:00'')
insert into #ccintervalos values(38,@from3,''19:00'',''19:30'')
insert into #ccintervalos values(39,@from3,''19:30'',''20:00'')
insert into #ccintervalos values(40,@from3,''20:00'',''20:30'')
insert into #ccintervalos values(41,@from3,''20:30'',''21:00'')
insert into #ccintervalos values(42,@from3,''21:00'',''21:30'')
insert into #ccintervalos values(43,@from3,''21:30'',''22:00'')
insert into #ccintervalos values(44,@from3,''22:00'',''22:30'')
insert into #ccintervalos values(45,@from3,''22:30'',''23:00'')
insert into #ccintervalos values(46,@from3,''23:00'',''23:30'')
insert into #ccintervalos values(47,@from3,''23:30'',''00:00'')
BEGIN

	declare camps cursor for
	
	select distinct cam_id from cccamps (nolock)

	open camps
	fetch next from camps into @cam
	while @@fetch_status = 0
	begin
		--print ''Campaña: ''+convert(varchar(5),@cam)+'' ''+convert(varchar(10),@from,121)
		
		
		--if @cam=43534534
		--begin
			insert into ccGenMktIntervaloSalida (dia,rango1,rango2,Recibidas,Staff,Contactos,Ocupado,NoContestan,Fax,Buzon,
									SinTono,NoServicie,Otro,Congestion,Cancelado,Contestadas,Abandonadas,SinAgentes,NoContestadas,CortadasRing,CortadasDespRing,
									CortadasDlg,TMO,TiempoTotalTT,TiempoTotalHold,
									TiempoTotalACW,TiempoTotalRing,TiempoTotalAvail,TiempoTotalAUX,TiempoPersonal,VelocidadResp,Reductor,Abandono,OcupacionCOPC,Cam_id)
	select convert(varchar(10),@from,121),r.rango1,r.rango2,isnull(Recibidas,0),isnull(uid,0),isnull(Contactos,0),isnull(Ocupado,0),isnull(NoContestan,0),
	isnull(Fax,0),isnull(Buzon,0),isnull(SinTono,0),isnull(NoServicie,0),isnull(Otro,0),isnull(Congestion,0),isnull(Cancelado,0),isnull(Contestadas,0),
	isnull(Abandonadas,0),isnull(SinAgentes,0),isnull(NoContestadas,0),isnull(CortadasRing,0),isnull(CortadasDespRing,0),isnull(CortadasDlg,0),
	isnull(TMO,''00:00:00''),isnull(TiempoTotalTT,''00:00:00''),isnull(TiempoTotalHold,''00:00:00''),isnull(TiempoTotalACW,''00:00:00''),isnull(TiempoTotalRing,''00:00:00''),
	dbo.fgethhmmss(A.tdispo),dbo.fgethhmmss(A.tnodispo),dbo.fgethhmmss(L.tlogueofra),isnull(VelocidadResp,''00:00:00''),
	isnull(case when L.tlogueofra=0 then 0 else (Reductor1+A.tnodispo)*100/L.tlogueofra end,0),isnull(Abandono,0),
	isnull(case when L.tlogueofra=0 then 0 else Ocupacion*100.00/L.tlogueofra end,0),@cam from (
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
	from ccologdials lo (nolock) left join ccoCallsOut co (nolock) on co.cal_id=lo.cal_id
	where fecha between @from  and @to and lo.cam_id=@cam group by 
	case when CONVERT(int, SUBSTRING(CONVERT(char(30), case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end), 16, 2)) / 30=0 then 
	CONVERT(varchar(2), case when ({ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then 
	''0''+convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else 
	convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''00'' else 
	CONVERT(varchar(2),case when ({ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then 
	''0''+convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else 
	convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''30'' end)x
	right join #ccintervalos r on r.rango1=x.rango1	
	inner join (select 
				Pg.rango1 rango1,
				Pg.rango2 rango2,
				count(distinct Pg.uid) uid,
				sum(Pg.tlogueofra) tlogueofra
			from	
			(select 
				Ss.rango1 rango1, 
				Ss.rango2 rango2,
				Tt.user_id uid,
				sum(case when convert(varchar(8),Tt.login,108)>Ss.rango1 and convert(varchar(8),Tt.logout,108)<(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,convert(varchar(8),Tt.login,108),convert(varchar(8),Tt.logout,108))
			    		 when convert(varchar(8),Tt.login,108)>Ss.rango1 and convert(varchar(8),Tt.logout,108)>(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,convert(varchar(8),Tt.login,108),(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end))
						 when convert(varchar(8),Tt.login,108)<Ss.rango1 and convert(varchar(8),Tt.logout,108)>(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then 1800
						 when convert(varchar(8),Tt.login,108)<Ss.rango1 and convert(varchar(8),Tt.logout,108)<(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,Ss.rango1,convert(varchar(8),Tt.logout,108))
				else 0 end) tlogueofra 						
			from #ccintervalos Ss
			LEFT OUTER JOIN
				(select CCLOG.uid user_id, 
						case when convert(varchar(10),CCLOG.login,121) = convert(varchar(10),getdate(),121)
						then 
							datediff(ss,CCLOG.login,isnull(CCLOG.logout,getdate()))	
						else 
							datediff(ss,CCLOG.login,CCLOG.logout)	
						end as tlogueo,
						CCLOG.login login,
						case when convert(varchar(10),CCLOG.login,121) = convert(varchar(10),getdate(),121)
						then	
							isnull(CCLOG.logout,getdate())
						else 	
							CCLOG.logout
						end	as logout,						
						case when CONVERT(int, SUBSTRING(CONVERT(char(30), CCLOG.login), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(CCLOG.login) })<10 then ''0''+convert(varchar(2),{ fn HOUR(CCLOG.login) }) else convert(varchar(2),{ fn HOUR(CCLOG.login) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(CCLOG.login) })<10 then ''0''+convert(varchar(2),{ fn HOUR(CCLOG.login) }) else convert(varchar(2),{ fn HOUR(CCLOG.login) }) end )+'':''+''30'' end as login2,
						case when convert(varchar(10),CCLOG.login,121) = convert(varchar(10),getdate(),121)
						then 
							case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), isnull(CCLOG.logout,getdate())), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(isnull(CCLOG.logout,getdate())) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(isnull(CCLOG.logout,getdate())) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })) else convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })) end)+'':''+''30'' end 
						else
							case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), CCLOG.logout), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(CCLOG.logout) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(CCLOG.logout) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(CCLOG.logout) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(CCLOG.logout) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(CCLOG.logout) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(CCLOG.logout) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(CCLOG.logout) })) else convert(varchar(2),CONVERT(int, { fn HOUR(CCLOG.logout) })) end)+'':''+''30'' end
						end	as logout2
						from
						(select uid, cam_id, login, max(logout) as logout
							from 
							(
								select uid, cam_id, login, ISNULL(logout, 
								(
									select MIN(fecha) from ccPosicionCamps (nolock)
									where tipo = 1 AND fecha > Detail.login AND [user_id] = Detail.uid AND cam_id = Detail.cam_id
								)) as logout
								from
								(
									select ccPosicionCamps.[user_id] AS [uid],ccPosicionCamps.cam_id as cam_id, fecha AS [login], Login.logout
									from 
									(	
										select uid,cam_id, MAX(login) as login, logout
										from
										(
											select Login.[user_id] AS [uid],cam_id AS [cam_id], fecha AS [login], 
											(
												select MIN(subLogin.fecha) from ccPosicionCamps subLogin (nolock)
												where subLogin.tipo = 0 AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id] AND sublogin.[cam_id] = Login.[cam_id]
											) AS [logout]
											from ccPosicionCamps Login (nolock)
											where tipo = 1 AND cam_id = @cam
											and login.fecha >= dateadd( dd, -2, @from3 )
											group by  Login.[user_id],Login.cam_id, Login.fecha
										) LogDet
										group by uid,cam_id, logout
									) Login
									RIGHT OUTER JOIN ccPosicionCamps (nolock)
									ON (ccPosicionCamps.[user_id] = Login.uid AND ccPosicionCamps.fecha = Login.login AND ccPosicionCamps.cam_id = Login.cam_id)
									where tipo = 1
									and ccPosicionCamps.cam_id = @cam
									and ccPosicionCamps.fecha >= dateadd( dd, -2, @from3 )
								) Detail
							) LoginDet
						where login >= @from3 AND login < @to
						group by uid,cam_id,login) CCLOG
				) Tt
				ON Tt.login2 <= Ss.rango1	
					and (Tt.logout2 >= case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end or Tt.logout2 is null)						
			group by Ss.rango1,	Ss.rango2, Tt.user_id
			) PG
			group by Pg.rango1,	Pg.rango2) L on L.rango1=r.rango1 and L.rango2=r.rango2
	inner join (
	select
				Tm.fecha fecha,
				Tm.rango1 rango1,
				Tm.rango2 rango2,
				isnull(sum(case when Tm.TipoStatusAge_id=2 then Tm.tstatusfra end),0) tnodispo,
				isnull(count(case when Tm.TipoStatusAge_id=2 then Tm.nstatusfra end),0) nnodispo,
				isnull(sum(case when Tm.TipoStatusAge_id=3 then Tm.tstatusfra end),0) tdispo,
				isnull(count(case when Tm.TipoStatusAge_id=3 then Tm.nstatusfra end),0) ndispo,
				ISNULL(sum(Tm.tstatusfra),0) TTotal,
				ISNULL(count(Tm.nstatusfra),0) NTotal
			from
				(
					--Parte 2
					
					select 
					G.fecha fecha,
					G.rango1 rango1,
					G.rango2 rango2,
					G.user_id user_id,
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
					case when Rg.tstatusfra is not null then 1 else 0 end nstatusfra,
					G.tlogueofra tlogueofra,
					Rg.TipoStatusAge_id TipoStatusAge_id
				from
					(
					--Primera Parte
					select distinct
					(S.fecha + S.rango1) fecha,
					S.rango1 rango1, 
					S.rango2 rango2,
					T.user_id user_id,
					T.tlogueo tlogueo,
					T.login login,
					T.logout logout,
					T.login2 login2,
					T.logout2 logout2,
					case when convert(varchar(8),t.login,108)>s.rango1 and convert(varchar(8),t.logout,108)<(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,convert(varchar(8),t.login,108),convert(varchar(8),t.logout,108))
				    		 when convert(varchar(8),t.login,108)>s.rango1 and convert(varchar(8),t.logout,108)>(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,convert(varchar(8),t.login,108),(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end))
							 when convert(varchar(8),t.login,108)<s.rango1 and convert(varchar(8),t.logout,108)>(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then 1800
							 when convert(varchar(8),t.login,108)<s.rango1 and convert(varchar(8),t.logout,108)<(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,s.rango1,convert(varchar(8),t.logout,108))
					else 0 end tlogueofra 						
				from #ccintervalos S
				LEFT OUTER JOIN
					(select CCLOGLOGIN.uid user_id, 
						case when convert(varchar(10),CCLOGLOGIN.login,121) = convert(varchar(10),getdate(),121)
						then 
							datediff(ss,CCLOGLOGIN.login,isnull(CCLOGLOGIN.logout,getdate()))	
						else 
							datediff(ss,CCLOGLOGIN.login,CCLOGLOGIN.logout)	
						end as tlogueo,
						CCLOGLOGIN.login login,
						case when convert(varchar(10),CCLOGLOGIN.login,121) = convert(varchar(10),getdate(),121)
						then	
							isnull(CCLOGLOGIN.logout,getdate())
						else 	
							CCLOGLOGIN.logout
						end	as logout,						
						case when CONVERT(int, SUBSTRING(CONVERT(char(30), CCLOGLOGIN.login), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(CCLOGLOGIN.login) })<10 then ''0''+convert(varchar(2),{ fn HOUR(CCLOGLOGIN.login) }) else convert(varchar(2),{ fn HOUR(CCLOGLOGIN.login) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(CCLOGLOGIN.login) })<10 then ''0''+convert(varchar(2),{ fn HOUR(CCLOGLOGIN.login) }) else convert(varchar(2),{ fn HOUR(CCLOGLOGIN.login) }) end )+'':''+''30'' end as login2,
						case when convert(varchar(10),CCLOGLOGIN.login,121) = convert(varchar(10),getdate(),121)
						then 
							case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), isnull(CCLOGLOGIN.logout,getdate())), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })) else convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })) end)+'':''+''30'' end 
						else
							case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), CCLOGLOGIN.logout), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(CCLOGLOGIN.logout) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(CCLOGLOGIN.logout) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })) else convert(varchar(2),CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })) end)+'':''+''30'' end
						end	as logout2
							from
							(select uid, cam_id, login, max(logout) as logout
								from 
								(
									select uid, cam_id, login, ISNULL(logout, 
									(
										select MIN(fecha) from ccPosicionCamps (nolock)
										where tipo = 1 AND fecha > det.login AND [user_id] = det.uid AND cam_id = det.cam_id
									)) as logout
									from
									(
										select ccPosicionCamps.[user_id] AS [uid],ccPosicionCamps.cam_id as cam_id, fecha AS [login], Login.logout
										from 
										(	
											select uid,cam_id, MAX(login) as login, logout
											from
											(
												select Login.[user_id] AS [uid],cam_id AS [cam_id], fecha AS [login], 
												(
													select MIN(subLogin.fecha) from ccPosicionCamps subLogin (nolock)
													where subLogin.tipo = 0 AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id] AND sublogin.[cam_id] = Login.[cam_id]
												) AS [logout]
												from ccPosicionCamps Login (nolock)
												where tipo = 1 AND cam_id = @cam
												and login.fecha >= dateadd( dd, -2, @from3 )
												group by  Login.[user_id],Login.cam_id, Login.fecha
											) LogDetail
											group by uid,cam_id, logout
										) Login
										RIGHT OUTER JOIN ccPosicionCamps (nolock)
										ON (ccPosicionCamps.[user_id] = Login.uid AND ccPosicionCamps.fecha = Login.login AND ccPosicionCamps.cam_id = Login.cam_id)
										where tipo = 1
										and ccPosicionCamps.cam_id = @cam
										and ccPosicionCamps.fecha >= dateadd( dd, -2, @from3 )
									) Det
								) LoginDetail
							where login >= @from3 AND login < @to
							group by uid,cam_id,login) CCLOGLOGIN
					) T
				ON t.login2 <= s.rango1	
					and (t.logout2 >= case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end or t.logout2 is null)
					
					--Primera parte
					)G
					
					LEFT OUTER JOIN
				(select	
					lg.user_id user_id,
					lg.rangoinicial rangoinicial,
					lg.rangofinal rangofinal,
					V.rango1 rango1,
					V.rango2 rango2,
					sum(case when convert(varchar(8),lg.rangoInicial,108)>V.rango1 and convert(varchar(8),lg.rangoFinal,108)<(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,convert(varchar(8),lg.rangoInicial,108),convert(varchar(8),lg.rangoFinal,108))
							 when convert(varchar(8),lg.rangoInicial,108)>V.rango1 and convert(varchar(8),lg.rangoFinal,108)>(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,convert(varchar(8),lg.rangoInicial,108),(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end))
							 when convert(varchar(8),lg.rangoInicial,108)<V.rango1 and convert(varchar(8),lg.rangoFinal,108)>(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then 1800
							 when convert(varchar(8),lg.rangoInicial,108)<V.rango1 and convert(varchar(8),lg.rangoFinal,108)<(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,V.rango1,convert(varchar(8),lg.rangoFinal,108))
					else 0 end) tstatusfra,							
					sum(lg.tstatus) tstatus,
					lg.TipoStatusAge_id TipoStatusAge_id
				from
					(
					select user_id as user_id,
						dateadd(ss,-1*(t.tStatus),t.fecha) rangoInicial,							
						t.fecha rangoFinal,							
						isnull(case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,-1*(t.tstatus),t.fecha)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''30'' end,0) rango1,
						isnull(case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(t.fecha) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(t.fecha) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) end)+'':''+''30'' end,0) rango2,														
						sum(t.tStatus) tstatus,
						t.TipoStatusAge_id TipoStatusAge_id
					from  cclogagentesdia t with (index(ccLogAgentesDia_fecAsc),nolock) 
					where t.fecha between @from and @to
					group by user_id,dateadd(ss,-1*(t.tStatus),t.fecha),t.fecha,
						isnull(case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,-1*(t.tstatus),t.fecha)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''30'' end,0),
						isnull(case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(t.fecha) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(t.fecha) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) end)+'':''+''30'' end,0),
						t.TipoStatusAge_id
					 ) lg
				left outer join 
					(SELECT rango1,rango2 from #ccintervalos) V
				on (V.rango1 >= lg.rango1
					and case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end <= lg.rango2)
				group by lg.user_id,lg.rangoinicial,lg.rangofinal,V.rango1,V.rango2,lg.TipoStatusAge_id
				) Rg
			on (Rg.user_id = G.user_id and Rg.rango1 = G.rango1 and Rg.rangoinicial < G.logout and Rg.rangofinal > G.login)
			
			--Parte 2
			) Tm
			group by Tm.fecha,Tm.rango1,Tm.rango2)A on A.rango1 = r.rango1 and A.rango2 = r.rango2 
			
			
			
			--close camps
			--deallocate camps
			--return
			--end

	fetch next from camps into @cam
	end
	
	close camps
	deallocate camps

END'
		
	EXEC(@Sql)
	
		set @Sql='CREATE PROCEDURE [dbo].[sp_mkt_intervalos_out] 
@cam smallint,
@from datetime,
@to datetime
AS

declare @cam_id varchar(5),
		@fecini datetime,
		@fecfin datetime,
		@fechaI datetime,
		@fechaF datetime,
		@sql varchar(8000),
		@sql1 varchar(8000),
		@sql2 varchar(8000),
		@sql3 varchar(8000),
		@from3 datetime,
		@flag bit,
		@tresDialog AS smallint,
		@tresRing AS smallint

EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresRing=ccspConfigTresRing
		
set @cam_id = CONVERT(varchar(5),@cam)
set @from = CONVERT(varchar(10),@from,121)
set	@fechaI = CONVERT(varchar(10),@from,121)
set @fechaF = CONVERT(varchar(10),@to,121)
set @from3 = CONVERT(varchar(10),@from,121)
set @flag=0 -- No Crea Tablas Temporales

IF @from = CONVERT(VARCHAR(10),getdate(),121) 
BEGIN
	set @from = CONVERT(varchar(10),getdate(),121)
	set @to = CONVERT(varchar(10),dateadd(dd,1,getdate()),121)
	set @from3= CONVERT(varchar(10),getdate(),121)
	set @flag=1
END	
IF @from < CONVERT(varchar(10),getdate(),121) AND @to >= CONVERT(varchar(10),getdate(),121)
BEGIN
	set @fecini = @from
	set @fecfin = CONVERT(varchar(10),getdate(),121)
	set @from = CONVERT(varchar(10),getdate(),121)
	set @to = CONVERT(varchar(10),dateadd(dd,1,getdate()),121)
	set @from3= CONVERT(varchar(10),getdate(),121)
	set @flag=1
END
IF (@fechaI = @fechaF) AND (@fechaI < CONVERT(VARCHAR(10),getdate(),121) AND @fechaF < CONVERT(VARCHAR(10),getdate(),121))
BEGIN
	set @fecini = @fechaI
	set @fecfin = CONVERT(varchar(10),dateadd(dd,1,@fechaF),121)
END
IF (@fechaI <> @fechaF) AND @fechaI < CONVERT(VARCHAR(10),getdate(),121) AND @fechaF < CONVERT(VARCHAR(10),getdate(),121)
BEGIN
	set @fecini = @fechaI
	set @fecfin = CONVERT(varchar(10),dateadd(dd,1,@fechaF),121)
END

set @sql=''''
set @sql1=''''
set @sql2=''''
set @sql3=''''

BEGIN

IF @flag=1
BEGIN
	CREATE TABLE #ccintervalos
	   ([Id]     [int],
		[fecha]  [datetime],
		[rango1] [varchar](5),
		[rango2] [varchar](5))
		
	CREATE TABLE #ccTempMktIntervaloSalida(
		[dia] [varchar](10) NULL,
		[rango1] [varchar](5) NULL,
		[rango2] [varchar](5) NULL,
		[Staff] [smallint] NULL,
		[Recibidas] [smallint] NULL,		
		Ocupado [smallint] NULL,
		[No Contestan] [smallint] NULL,
		[Fax/Modem] [smallint] NULL,
		[Buzon/Maquina] [smallint] NULL,
		SinTono [smallint] NULL,
		NoServicie [smallint] NULL,
		Otro [smallint] NULL,
		Congestion [smallint] NULL,
		Cancelado [smallint] NULL,
		[Contactos] [smallint] NULL,
		[Contestadas] [smallint] NULL,
		[Abandonadas] [smallint] NULL,
		SinAgentes [smallint] NULL, --Colgada 6
		NoContestadas [smallint] NULL, --Asignada y No Contestada 15 - 16
		CortadasRing [smallint] NULL, --Asignada 11 - 10,12,14 <= thresring
		CortadasDespRing [smallint] NULL, --Asignada 11 - 10,12,14 > thresring
		CortadasDlg [smallint] NULL, --dialogo<=threshold dialog
		[TMO] [varchar] (8) NULL,
		[TiempoTotalTT] [varchar] (8) NULL,
		[TiempoTotalHold] [varchar](8) NULL,
		[TiempoTotalACW] [varchar] (8) NULL,
		[TiempoTotalRing] [varchar](8) NULL,
		[TiempoTotalAvail] [varchar](8) NULL,
		[TiempoTotalAUX] [varchar](8) NULL,
		[TiempoPersonal] [varchar](8) NULL,
		[VelocidadResp] [varchar](8) NULL,
		[Reductor] [numeric] (18,2) NULL,
		[Abandono] [numeric] (18,2) NULL,
		[OcupacionCOPC] [numeric](18,2) NULL)
		

	insert into #ccintervalos values(0,@from,''00:00'',''00:30'')	
	insert into #ccintervalos values(1,@from,''00:30'',''01:00'')	
	insert into #ccintervalos values(2,@from,''01:00'',''01:30'')
	insert into #ccintervalos values(3,@from,''01:30'',''02:00'')
	insert into #ccintervalos values(4,@from,''02:00'',''02:30'')
	insert into #ccintervalos values(5,@from,''02:30'',''03:00'')
	insert into #ccintervalos values(6,@from,''03:00'',''03:30'')
	insert into #ccintervalos values(7,@from,''03:30'',''04:00'')
	insert into #ccintervalos values(8,@from,''04:00'',''04:30'')
	insert into #ccintervalos values(9,@from,''04:30'',''05:00'')
	insert into #ccintervalos values(10,@from,''05:00'',''05:30'')
	insert into #ccintervalos values(11,@from,''05:30'',''06:00'')	
	insert into #ccintervalos values(12,@from,''06:00'',''06:30'')
	insert into #ccintervalos values(13,@from,''06:30'',''07:00'')
	insert into #ccintervalos values(14,@from,''07:00'',''07:30'')
	insert into #ccintervalos values(15,@from,''07:30'',''08:00'')
	insert into #ccintervalos values(16,@from,''08:00'',''08:30'')
	insert into #ccintervalos values(17,@from,''08:30'',''09:00'')
	insert into #ccintervalos values(18,@from,''09:00'',''09:30'')
	insert into #ccintervalos values(19,@from,''09:30'',''10:00'')
	insert into #ccintervalos values(20,@from,''10:00'',''10:30'')
	insert into #ccintervalos values(21,@from,''10:30'',''11:00'')
	insert into #ccintervalos values(22,@from,''11:00'',''11:30'')
	insert into #ccintervalos values(23,@from,''11:30'',''12:00'')
	insert into #ccintervalos values(24,@from,''12:00'',''12:30'')
	insert into #ccintervalos values(25,@from,''12:30'',''13:00'')
	insert into #ccintervalos values(26,@from,''13:00'',''13:30'')
	insert into #ccintervalos values(27,@from,''13:30'',''14:00'')
	insert into #ccintervalos values(28,@from,''14:00'',''14:30'')
	insert into #ccintervalos values(29,@from,''14:30'',''15:00'')
	insert into #ccintervalos values(30,@from,''15:00'',''15:30'')
	insert into #ccintervalos values(31,@from,''15:30'',''16:00'')
	insert into #ccintervalos values(32,@from,''16:00'',''16:30'')
	insert into #ccintervalos values(33,@from,''16:30'',''17:00'')
	insert into #ccintervalos values(34,@from,''17:00'',''17:30'')
	insert into #ccintervalos values(35,@from,''17:30'',''18:00'')
	insert into #ccintervalos values(36,@from,''18:00'',''18:30'')
	insert into #ccintervalos values(37,@from,''18:30'',''19:00'')
	insert into #ccintervalos values(38,@from,''19:00'',''19:30'')
	insert into #ccintervalos values(39,@from,''19:30'',''20:00'')
	insert into #ccintervalos values(40,@from,''20:00'',''20:30'')
	insert into #ccintervalos values(41,@from,''20:30'',''21:00'')
	insert into #ccintervalos values(42,@from,''21:00'',''21:30'')
	insert into #ccintervalos values(43,@from,''21:30'',''22:00'')
	insert into #ccintervalos values(44,@from,''22:00'',''22:30'')
	insert into #ccintervalos values(45,@from,''22:30'',''23:00'')
	insert into #ccintervalos values(46,@from,''23:00'',''23:30'')
	insert into #ccintervalos values(47,@from,''23:30'',''00:00'')	
	
	INSERT INTO #ccTempMktIntervaloSalida (dia,rango1,rango2,Recibidas,Staff,Contactos,Ocupado,[No Contestan],[Fax/Modem],[Buzon/Maquina],
									SinTono,NoServicie,Otro,Congestion,Cancelado,Contestadas,Abandonadas,SinAgentes,NoContestadas,CortadasRing,CortadasDespRing,
									CortadasDlg,TMO,TiempoTotalTT,TiempoTotalHold,
									TiempoTotalACW,TiempoTotalRing,TiempoTotalAvail,TiempoTotalAUX,TiempoPersonal,VelocidadResp,Reductor,Abandono,OcupacionCOPC)
	select convert(varchar(10),@from,121),r.rango1,r.rango2,isnull(Recibidas,0),isnull(uid,0),isnull(Contactos,0),isnull(Ocupado,0),isnull(NoContestan,0),
	isnull(Fax,0),isnull(Buzon,0),isnull(SinTono,0),isnull(NoServicie,0),isnull(Otro,0),isnull(Congestion,0),isnull(Cancelado,0),isnull(Contestadas,0),
	isnull(Abandonadas,0),isnull(SinAgentes,0),isnull(NoContestadas,0),isnull(CortadasRing,0),isnull(CortadasDespRing,0),isnull(CortadasDlg,0),
	isnull(TMO,''00:00:00''),isnull(TiempoTotalTT,''00:00:00''),isnull(TiempoTotalHold,''00:00:00''),isnull(TiempoTotalACW,''00:00:00''),isnull(TiempoTotalRing,''00:00:00''),
	dbo.fgethhmmss(A.tdispo),dbo.fgethhmmss(A.tnodispo),dbo.fgethhmmss(L.tlogueofra),isnull(VelocidadResp,''00:00:00''),
	isnull(case when L.tlogueofra=0 then 0 else (Reductor1+A.tnodispo)*100/L.tlogueofra end,0),isnull(Abandono,0),
	isnull(case when L.tlogueofra=0 then 0 else Ocupacion*100.00/L.tlogueofra end,0) from (
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
	cast(case when count(case when statusCall_id=13 then 1 else null end)=0 then 0 else count(case when statusCall_id in (6,10,11,12,14,15,16) or (canceledNoAgents<>0 and answerbit=1) or (statuscall_id=13 and cal_tdialog <=@tresDialog) then 1 else null end)*100.00/count(case when tipoResDial_id=1 then 1 else null end) end as decimal(5,2)) [Abandono], --Cambio
	SUM(cal_tDialog+cal_tNotas+cal_tRing+cal_tXfer+cal_tMoh) [Ocupacion]
	from ccologdials lo (nolock) left join ccoCallsOut co (nolock) on co.cal_id=lo.cal_id
	where fecha between @from  and @to and lo.cam_id=@cam_id group by 
	case when CONVERT(int, SUBSTRING(CONVERT(char(30), case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end), 16, 2)) / 30=0 then 
	CONVERT(varchar(2), case when ({ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then 
	''0''+convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else 
	convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''00'' else 
	CONVERT(varchar(2),case when ({ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) })<10 then 
	''0''+convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) else 
	convert(varchar(2),{ fn HOUR(case when statusCall_id=13 then dateadd(ss,(co.cal_tDialog + co.cal_tWait + co.cal_tXfer + co.cal_tRing),co.cal_inicio) else DATEADD(ss,tDialing,fecha) end) }) end )+'':''+''30'' end)x
	right join #ccintervalos r on r.rango1=x.rango1	
	inner join (select 
				Pg.rango1 rango1,
				Pg.rango2 rango2,
				count(distinct Pg.uid) uid,
				sum(Pg.tlogueofra) tlogueofra
			from	
			(select 
				Ss.rango1 rango1, 
				Ss.rango2 rango2,
				Tt.user_id uid,
				sum(case when convert(varchar(8),Tt.login,108)>Ss.rango1 and convert(varchar(8),Tt.logout,108)<(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,convert(varchar(8),Tt.login,108),convert(varchar(8),Tt.logout,108))
			    		 when convert(varchar(8),Tt.login,108)>Ss.rango1 and convert(varchar(8),Tt.logout,108)>(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,convert(varchar(8),Tt.login,108),(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end))
						 when convert(varchar(8),Tt.login,108)<Ss.rango1 and convert(varchar(8),Tt.logout,108)>(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then 1800
						 when convert(varchar(8),Tt.login,108)<Ss.rango1 and convert(varchar(8),Tt.logout,108)<(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,Ss.rango1,convert(varchar(8),Tt.logout,108))
				else 0 end) tlogueofra 						
			from #ccintervalos Ss
			LEFT OUTER JOIN
				(select CCLOG.uid user_id, 
						case when convert(varchar(10),CCLOG.login,121) = convert(varchar(10),getdate(),121)
						then 
							datediff(ss,CCLOG.login,isnull(CCLOG.logout,getdate()))	
						else 
							datediff(ss,CCLOG.login,CCLOG.logout)	
						end as tlogueo,
						CCLOG.login login,
						case when convert(varchar(10),CCLOG.login,121) = convert(varchar(10),getdate(),121)
						then	
							isnull(CCLOG.logout,getdate())
						else 	
							CCLOG.logout
						end	as logout,						
						case when CONVERT(int, SUBSTRING(CONVERT(char(30), CCLOG.login), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(CCLOG.login) })<10 then ''0''+convert(varchar(2),{ fn HOUR(CCLOG.login) }) else convert(varchar(2),{ fn HOUR(CCLOG.login) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(CCLOG.login) })<10 then ''0''+convert(varchar(2),{ fn HOUR(CCLOG.login) }) else convert(varchar(2),{ fn HOUR(CCLOG.login) }) end )+'':''+''30'' end as login2,
						case when convert(varchar(10),CCLOG.login,121) = convert(varchar(10),getdate(),121)
						then 
							case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), isnull(CCLOG.logout,getdate())), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(isnull(CCLOG.logout,getdate())) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(isnull(CCLOG.logout,getdate())) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })) else convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })) end)+'':''+''30'' end 
						else
							case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), CCLOG.logout), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(CCLOG.logout) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(CCLOG.logout) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(CCLOG.logout) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(CCLOG.logout) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(CCLOG.logout) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(CCLOG.logout) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(CCLOG.logout) })) else convert(varchar(2),CONVERT(int, { fn HOUR(CCLOG.logout) })) end)+'':''+''30'' end
						end	as logout2
						from
						(select uid, cam_id, login, max(logout) as logout
							from 
							(
								select uid, cam_id, login, ISNULL(logout, 
								(
									select MIN(fecha) from ccPosicionCamps (nolock)
									where tipo = 1 AND fecha > Detail.login AND [user_id] = Detail.uid AND cam_id = Detail.cam_id
								)) as logout
								from
								(
									select ccPosicionCamps.[user_id] AS [uid],ccPosicionCamps.cam_id as cam_id, fecha AS [login], Login.logout
									from 
									(	
										select uid,cam_id, MAX(login) as login, logout
										from
										(
											select Login.[user_id] AS [uid],cam_id AS [cam_id], fecha AS [login], 
											(
												select MIN(subLogin.fecha) from ccPosicionCamps subLogin (nolock)
												where subLogin.tipo = 0 AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id] AND sublogin.[cam_id] = Login.[cam_id]
											) AS [logout]
											from ccPosicionCamps Login (nolock)
											where tipo = 1 AND cam_id = @cam
											and login.fecha >= dateadd( dd, -2, @from3 )
											group by  Login.[user_id],Login.cam_id, Login.fecha
										) LogDet
										group by uid,cam_id, logout
									) Login
									RIGHT OUTER JOIN ccPosicionCamps (nolock)
									ON (ccPosicionCamps.[user_id] = Login.uid AND ccPosicionCamps.fecha = Login.login AND ccPosicionCamps.cam_id = Login.cam_id)
									where tipo = 1
									and ccPosicionCamps.cam_id = @cam
									and ccPosicionCamps.fecha >= dateadd( dd, -2, @from3 )
								) Detail
							) LoginDet
						where login >= @from3 AND login < @to
						group by uid,cam_id,login) CCLOG
				) Tt
				ON Tt.login2 <= Ss.rango1	
					and (Tt.logout2 >= case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end or Tt.logout2 is null)						
			group by Ss.rango1,	Ss.rango2, Tt.user_id
			) PG
			group by Pg.rango1,	Pg.rango2) L on L.rango1=r.rango1 and L.rango2=r.rango2
	inner join (
	select
				Tm.fecha fecha,
				Tm.rango1 rango1,
				Tm.rango2 rango2,
				isnull(sum(case when Tm.TipoStatusAge_id=2 then Tm.tstatusfra end),0) tnodispo,
				isnull(count(case when Tm.TipoStatusAge_id=2 then Tm.nstatusfra end),0) nnodispo,
				isnull(sum(case when Tm.TipoStatusAge_id=3 then Tm.tstatusfra end),0) tdispo,
				isnull(count(case when Tm.TipoStatusAge_id=3 then Tm.nstatusfra end),0) ndispo,
				ISNULL(sum(Tm.tstatusfra),0) TTotal,
				ISNULL(count(Tm.nstatusfra),0) NTotal
			from
				(
					--Parte 2
					
					select 
					G.fecha fecha,
					G.rango1 rango1,
					G.rango2 rango2,
					G.user_id user_id,
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
					case when Rg.tstatusfra is not null then 1 else 0 end nstatusfra,
					G.tlogueofra tlogueofra,
					Rg.TipoStatusAge_id TipoStatusAge_id
				from
					(
					--Primera Parte
					select distinct
					(S.fecha + S.rango1) fecha,
					S.rango1 rango1, 
					S.rango2 rango2,
					T.user_id user_id,
					T.tlogueo tlogueo,
					T.login login,
					T.logout logout,
					T.login2 login2,
					T.logout2 logout2,
					case when convert(varchar(8),t.login,108)>s.rango1 and convert(varchar(8),t.logout,108)<(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,convert(varchar(8),t.login,108),convert(varchar(8),t.logout,108))
				    		 when convert(varchar(8),t.login,108)>s.rango1 and convert(varchar(8),t.logout,108)>(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,convert(varchar(8),t.login,108),(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end))
							 when convert(varchar(8),t.login,108)<s.rango1 and convert(varchar(8),t.logout,108)>(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then 1800
							 when convert(varchar(8),t.login,108)<s.rango1 and convert(varchar(8),t.logout,108)<(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,s.rango1,convert(varchar(8),t.logout,108))
					else 0 end tlogueofra 						
				from #ccintervalos S
				LEFT OUTER JOIN
					(select CCLOGLOGIN.uid user_id, 
						case when convert(varchar(10),CCLOGLOGIN.login,121) = convert(varchar(10),getdate(),121)
						then 
							datediff(ss,CCLOGLOGIN.login,isnull(CCLOGLOGIN.logout,getdate()))	
						else 
							datediff(ss,CCLOGLOGIN.login,CCLOGLOGIN.logout)	
						end as tlogueo,
						CCLOGLOGIN.login login,
						case when convert(varchar(10),CCLOGLOGIN.login,121) = convert(varchar(10),getdate(),121)
						then	
							isnull(CCLOGLOGIN.logout,getdate())
						else 	
							CCLOGLOGIN.logout
						end	as logout,						
						case when CONVERT(int, SUBSTRING(CONVERT(char(30), CCLOGLOGIN.login), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(CCLOGLOGIN.login) })<10 then ''0''+convert(varchar(2),{ fn HOUR(CCLOGLOGIN.login) }) else convert(varchar(2),{ fn HOUR(CCLOGLOGIN.login) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(CCLOGLOGIN.login) })<10 then ''0''+convert(varchar(2),{ fn HOUR(CCLOGLOGIN.login) }) else convert(varchar(2),{ fn HOUR(CCLOGLOGIN.login) }) end )+'':''+''30'' end as login2,
						case when convert(varchar(10),CCLOGLOGIN.login,121) = convert(varchar(10),getdate(),121)
						then 
							case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), isnull(CCLOGLOGIN.logout,getdate())), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })) else convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })) end)+'':''+''30'' end 
						else
							case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), CCLOGLOGIN.logout), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(CCLOGLOGIN.logout) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(CCLOGLOGIN.logout) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })) else convert(varchar(2),CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })) end)+'':''+''30'' end
						end	as logout2
							from
							(select uid, cam_id, login, max(logout) as logout
								from 
								(
									select uid, cam_id, login, ISNULL(logout, 
									(
										select MIN(fecha) from ccPosicionCamps (nolock)
										where tipo = 1 AND fecha > det.login AND [user_id] = det.uid AND cam_id = det.cam_id
									)) as logout
									from
									(
										select ccPosicionCamps.[user_id] AS [uid],ccPosicionCamps.cam_id as cam_id, fecha AS [login], Login.logout
										from 
										(	
											select uid,cam_id, MAX(login) as login, logout
											from
											(
												select Login.[user_id] AS [uid],cam_id AS [cam_id], fecha AS [login], 
												(
													select MIN(subLogin.fecha) from ccPosicionCamps subLogin (nolock)
													where subLogin.tipo = 0 AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id] AND sublogin.[cam_id] = Login.[cam_id]
												) AS [logout]
												from ccPosicionCamps Login (nolock)
												where tipo = 1 AND cam_id = @cam
												and login.fecha >= dateadd( dd, -2, @from3 )
												group by  Login.[user_id],Login.cam_id, Login.fecha
											) LogDetail
											group by uid,cam_id, logout
										) Login
										RIGHT OUTER JOIN ccPosicionCamps (nolock)
										ON (ccPosicionCamps.[user_id] = Login.uid AND ccPosicionCamps.fecha = Login.login AND ccPosicionCamps.cam_id = Login.cam_id)
										where tipo = 1
										and ccPosicionCamps.cam_id = @cam
										and ccPosicionCamps.fecha >= dateadd( dd, -2, @from3 )
									) Det
								) LoginDetail
							where login >= @from3 AND login < @to
							group by uid,cam_id,login) CCLOGLOGIN
					) T
				ON t.login2 <= s.rango1	
					and (t.logout2 >= case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end or t.logout2 is null)
					
					--Primera parte
					)G
					
					LEFT OUTER JOIN
				(select	
					lg.user_id user_id,
					lg.rangoinicial rangoinicial,
					lg.rangofinal rangofinal,
					V.rango1 rango1,
					V.rango2 rango2,
					sum(case when convert(varchar(8),lg.rangoInicial,108)>V.rango1 and convert(varchar(8),lg.rangoFinal,108)<(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,convert(varchar(8),lg.rangoInicial,108),convert(varchar(8),lg.rangoFinal,108))
							 when convert(varchar(8),lg.rangoInicial,108)>V.rango1 and convert(varchar(8),lg.rangoFinal,108)>(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,convert(varchar(8),lg.rangoInicial,108),(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end))
							 when convert(varchar(8),lg.rangoInicial,108)<V.rango1 and convert(varchar(8),lg.rangoFinal,108)>(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then 1800
							 when convert(varchar(8),lg.rangoInicial,108)<V.rango1 and convert(varchar(8),lg.rangoFinal,108)<(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,V.rango1,convert(varchar(8),lg.rangoFinal,108))
					else 0 end) tstatusfra,							
					sum(lg.tstatus) tstatus,
					lg.TipoStatusAge_id TipoStatusAge_id
				from
					(
					select user_id as user_id,
						dateadd(ss,-1*(t.tStatus),t.fecha) rangoInicial,							
						t.fecha rangoFinal,							
						isnull(case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,-1*(t.tstatus),t.fecha)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''30'' end,0) rango1,
						isnull(case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(t.fecha) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(t.fecha) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) end)+'':''+''30'' end,0) rango2,														
						sum(t.tStatus) tstatus,
						t.TipoStatusAge_id TipoStatusAge_id
					from  cclogagentesdia t with (index(ccLogAgentesDia_fecAsc),nolock) 
					where t.fecha between @from and @to
					group by user_id,dateadd(ss,-1*(t.tStatus),t.fecha),t.fecha,
						isnull(case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,-1*(t.tstatus),t.fecha)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''30'' end,0),
						isnull(case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(t.fecha) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(t.fecha) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) end)+'':''+''30'' end,0),
						t.TipoStatusAge_id
					 ) lg
				left outer join 
					(SELECT rango1,rango2 from #ccintervalos) V
				on (V.rango1 >= lg.rango1
					and case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end <= lg.rango2)
				group by lg.user_id,lg.rangoinicial,lg.rangofinal,V.rango1,V.rango2,lg.TipoStatusAge_id
				) Rg
			on (Rg.user_id = G.user_id and Rg.rango1 = G.rango1 and Rg.rangoinicial < G.logout and Rg.rangofinal > G.login)
			
			--Parte 2
			) Tm
			group by Tm.fecha,Tm.rango1,Tm.rango2)A on A.rango1 = r.rango1 and A.rango2 = r.rango2 
	
END

	set @sql=''SELECT 
			dia [Dia], 
			rango1 [Rango1],
			rango2 [Rango2],			
			Staff [Staff],
			Recibidas [Llamadas Realizadas],									
			Ocupado,NoContestan [No Contestan],
			Fax [Fax/Modem],Buzon [Buzon/Maquina],
			SinTono,NoServicie,Otro,Congestion,Cancelado,
			Contactos [Contactadas],
			Contestadas,
			Abandonadas [Llamadas Aban.],	
			SinAgentes [Sin Agentes Disp.],
			NoContestadas [No Contestadas],
			CortadasRing [Cortadas Antes Timbrar],	
			CortadasDespRing [Cortadas Desp Timbrar],
			CortadasDlg [Cortadas Inicio Dialogo],
			TMO [TMO],					
			TiempoTotalTT [Tiempo Total TT],		
			TiempoTotalHold [Tiempo Total Hold],
			TiempoTotalACW [Tiempo Total ACW],
			TiempoTotalRing [Tiempo Total Ring],	
			TiempoTotalAvail [Tiempo Total Avail],			
			TiempoTotalAUX [Tiempo Total AUX],
			TiempoPersonal [Tiempo con Personal],
			VelocidadResp [Velocidad de Resp.],
			Reductor [% Reductor],
			Abandono [% Abandono],
			OcupacionCOPC [OcupacionCOPC]
		FROM	
			ccGenMktIntervaloSalida (nolock)
			WHERE   cam_id = '' + @cam_id + '' AND dia >= '' + char(0x27) + CONVERT(VARCHAR(10),@fecini,121) + char(0x27) + '' AND dia < '' + char(0x27) + CONVERT(VARCHAR(10),@fecfin,121) + char(0x27) + ''''

	set @sql1=''order by dia,rango1 asc''
	set @sql2=''UNION ALL''
	
	set @sql3=''SELECT 
			dia collate SQL_Latin1_General_CP1_CI_AS [Dia], 
			rango1 collate SQL_Latin1_General_CP1_CI_AS [Rango1],
			rango2 collate SQL_Latin1_General_CP1_CI_AS [Rango2],
			Staff [Staff],
			Recibidas [Llamadas Realizadas],						
			Ocupado,[No Contestan],[Fax/Modem],[Buzon/Maquina],
			SinTono,NoServicie,Otro,Congestion,Cancelado,
			Contactos [Contactadas],
			Contestadas,
			Abandonadas [Llamadas Aban.],		
			SinAgentes [Sin Agentes Disp.],
			NoContestadas [No Contestadas],
			CortadasRing [Cortadas Antes Timbrar],
			CortadasDespRing [Cortadas Desp Timbrar],
			CortadasDlg [Cortadas Inicio Dialogo],
			TMO collate SQL_Latin1_General_CP1_CI_AS [TMO],					
			TiempoTotalTT collate SQL_Latin1_General_CP1_CI_AS [Tiempo Total TT],		
			TiempoTotalHold collate SQL_Latin1_General_CP1_CI_AS [Tiempo Total Hold],
			TiempoTotalACW collate SQL_Latin1_General_CP1_CI_AS [Tiempo Total ACW],
			TiempoTotalRing collate SQL_Latin1_General_CP1_CI_AS [Tiempo Total Ring],	
			TiempoTotalAvail collate SQL_Latin1_General_CP1_CI_AS [Tiempo Total Avail],			
			TiempoTotalAUX collate SQL_Latin1_General_CP1_CI_AS [Tiempo Total AUX],
			TiempoPersonal collate SQL_Latin1_General_CP1_CI_AS [Tiempo con Personal],
			VelocidadResp collate SQL_Latin1_General_CP1_CI_AS [Velocidad de Resp.],
			Reductor [% Reductor],
			Abandono [% Abandono],
			OcupacionCOPC [OcupacionCOPC]
		FROM	
			#ccTempMktIntervaloSalida ''
	
	IF @fechaI = CONVERT(VARCHAR(10),getdate(),121) 
	BEGIN
		exec(@sql3+ '' '' + @sql1)
		--select @sql3 
		--select @sql1 
	END	
	IF @fechaI < CONVERT(VARCHAR(10),getdate(),121) AND @fechaF >= CONVERT(VARCHAR(10),getdate(),121) 
	BEGIN
		exec(@sql + '' '' + @sql2 + '' '' + @sql3 + '' '' + @sql1)
		--select @sql 
		--select @sql2 
		--select @sql3 
		--select @sql1 
	END	
	IF @fechaI < CONVERT(VARCHAR(10),getdate(),121) AND @fechaF < CONVERT(VARCHAR(10),getdate(),121)
	BEGIN
		exec(@sql + '' '' + @sql1)
		--select @sql
		--select @sql1 
	END

END'
		
	EXEC(@Sql)
	
		set @Sql='ALTER PROCEDURE [dbo].[sp_mkt_intervalo_TiemposAcumuladosTotales]
@inb smallint,
@from datetime,
@to datetime
AS

declare @inbound_id varchar(5),
		@descripcion varchar(50),
		@fecini datetime,
		@fecfin datetime,
		@fechaI datetime,
		@fechaF datetime,
		@sql varchar(8000),
		@sql1 varchar(8000),
		@sql2 varchar(8000),
		@sql3 varchar(8000),
		@from3 datetime,
		@Flag bit

select @descripcion=descripcion from ccinbound (nolock) where inbound_id=@inb
set @inbound_id = CONVERT(varchar(5),@inb)
set @from = CONVERT(datetime,CONVERT(varchar(4),YEAR(@from))+''-''+CONVERT(varchar(2), MONTH(@from))+''-''+CONVERT(varchar(2), DAY(@from)))
set @from3 = CONVERT(datetime,CONVERT(varchar(4),YEAR(@from))+''-''+CONVERT(varchar(2), MONTH(@from))+''-''+CONVERT(varchar(2), DAY(@from)))
set @to = CONVERT(datetime,CONVERT(varchar(4),YEAR(@to))+''-''+CONVERT(varchar(2), MONTH(@to))+''-''+CONVERT(varchar(2), DAY(@to)))
set	@fechaI = CONVERT(datetime,CONVERT(varchar(4),YEAR(@from))+''-''+CONVERT(varchar(2), MONTH(@from))+''-''+CONVERT(varchar(2), DAY(@from)))
set @fechaF = CONVERT(datetime,CONVERT(varchar(4),YEAR(@to))+''-''+CONVERT(varchar(2), MONTH(@to))+''-''+CONVERT(varchar(2), DAY(@to)))
set @flag=0 -- No Crea Tablas Temporales

IF @from = CONVERT(VARCHAR(10),getdate(),121) 
BEGIN
	set @from = CONVERT(varchar(10),getdate(),121)
	set @from3 = CONVERT(varchar(10),getdate(),121)
	set @to = CONVERT(varchar(10),dateadd(dd,1,getdate()),121)	
	set @flag=1
END	
IF @from < CONVERT(varchar(10),getdate(),121) AND @to >= CONVERT(varchar(10),getdate(),121)
BEGIN
	set @fecini = @from
	set @fecfin = CONVERT(varchar(10),getdate(),121)
	set @from = CONVERT(varchar(10),getdate(),121)
	set @from3 = CONVERT(varchar(10),getdate(),121)
	set @to = CONVERT(varchar(10),dateadd(dd,1,getdate()),121)
	set @flag=1
END
IF (@fechaI = @fechaF) AND (@fechaI < CONVERT(VARCHAR(10),getdate(),121) AND @fechaF < CONVERT(VARCHAR(10),getdate(),121))
BEGIN
	set @fecini = @fechaI
	set @fecfin = CONVERT(varchar(10),dateadd(dd,1,@fechaF),121)
END
IF (@fechaI <> @fechaF) AND @fechaI < CONVERT(VARCHAR(10),getdate(),121) AND @fechaF < CONVERT(VARCHAR(10),getdate(),121)
BEGIN
	set @fecini = @fechaI
	set @fecfin = CONVERT(varchar(10),dateadd(dd,1,@fechaF),121)
END

set @sql=''''
set @sql1=''''
set @sql2=''''
set @sql3=''''

BEGIN

IF @flag=1
BEGIN

	CREATE TABLE #ccintervalos
	   ([Id]     [int],
		[fecha]  [datetime],
		[rango1] [varchar](5),
		[rango2] [varchar](5))
		
	CREATE TABLE #ccTempIntervaloTieAcuTot
		([dia] [varchar](10) NULL,
		[rango1] [varchar](5) NULL,
		[rango2] [varchar](5) NULL,
		[inbound_id] varchar(5) NULL,
		[descripcion] varchar(50) NULL,
		[PromPosicionPersonal] [numeric](18, 1) NULL,
		[LlamadasRecibidas] [int] NULL,
		[LlamadasAtendidas] [int] NULL,
		[LlamadasAban] [int] NULL,
		[TiempoACD] [varchar](8) NULL,
		[TiempoACW] [varchar](8) NULL,
		[TiempoLogout] [varchar](8) NULL,
		[TiempoDescon] [varchar](8) NULL,
		[TiempoNoDispo] [varchar](8) NULL,
		[TiempoDispo] [varchar](8) NULL,
		[TiempoXfer] [varchar](8) NULL,
		[TiempoOtra] [varchar](8) NULL,
		[TiempoCliente] [varchar](8) NULL,
		[TiempoRing] [varchar](8) NULL,
		[TiempoProblema] [varchar](8) NULL,
		[TiempoManual] [varchar](8) NULL,
		[TiempoReten] [varchar](8) NULL,
		[LlamadasSalidaExt] [int] NULL,
		[TiempoSalidaExt] [varchar](8) NULL,
		[PorcNiveldeServicio4080] [int] NULL,
		[AHT] [int] NULL,
		[LlamadasRetenidas] [int] NULL,
		[LlamadasenRing] [int] NULL)
		
	insert into #ccintervalos values(0,@from,''00:00'',''00:30'')	
	insert into #ccintervalos values(1,@from,''00:30'',''01:00'')	
	insert into #ccintervalos values(2,@from,''01:00'',''01:30'')
	insert into #ccintervalos values(3,@from,''01:30'',''02:00'')
	insert into #ccintervalos values(4,@from,''02:00'',''02:30'')
	insert into #ccintervalos values(5,@from,''02:30'',''03:00'')
	insert into #ccintervalos values(6,@from,''03:00'',''03:30'')
	insert into #ccintervalos values(7,@from,''03:30'',''04:00'')
	insert into #ccintervalos values(8,@from,''04:00'',''04:30'')
	insert into #ccintervalos values(9,@from,''04:30'',''05:00'')
	insert into #ccintervalos values(10,@from,''05:00'',''05:30'')
	insert into #ccintervalos values(11,@from,''05:30'',''06:00'')	
	insert into #ccintervalos values(12,@from,''06:00'',''06:30'')
	insert into #ccintervalos values(13,@from,''06:30'',''07:00'')
	insert into #ccintervalos values(14,@from,''07:00'',''07:30'')
	insert into #ccintervalos values(15,@from,''07:30'',''08:00'')
	insert into #ccintervalos values(16,@from,''08:00'',''08:30'')
	insert into #ccintervalos values(17,@from,''08:30'',''09:00'')
	insert into #ccintervalos values(18,@from,''09:00'',''09:30'')
	insert into #ccintervalos values(19,@from,''09:30'',''10:00'')
	insert into #ccintervalos values(20,@from,''10:00'',''10:30'')
	insert into #ccintervalos values(21,@from,''10:30'',''11:00'')
	insert into #ccintervalos values(22,@from,''11:00'',''11:30'')
	insert into #ccintervalos values(23,@from,''11:30'',''12:00'')
	insert into #ccintervalos values(24,@from,''12:00'',''12:30'')
	insert into #ccintervalos values(25,@from,''12:30'',''13:00'')
	insert into #ccintervalos values(26,@from,''13:00'',''13:30'')
	insert into #ccintervalos values(27,@from,''13:30'',''14:00'')
	insert into #ccintervalos values(28,@from,''14:00'',''14:30'')
	insert into #ccintervalos values(29,@from,''14:30'',''15:00'')
	insert into #ccintervalos values(30,@from,''15:00'',''15:30'')
	insert into #ccintervalos values(31,@from,''15:30'',''16:00'')
	insert into #ccintervalos values(32,@from,''16:00'',''16:30'')
	insert into #ccintervalos values(33,@from,''16:30'',''17:00'')
	insert into #ccintervalos values(34,@from,''17:00'',''17:30'')
	insert into #ccintervalos values(35,@from,''17:30'',''18:00'')
	insert into #ccintervalos values(36,@from,''18:00'',''18:30'')
	insert into #ccintervalos values(37,@from,''18:30'',''19:00'')
	insert into #ccintervalos values(38,@from,''19:00'',''19:30'')
	insert into #ccintervalos values(39,@from,''19:30'',''20:00'')
	insert into #ccintervalos values(40,@from,''20:00'',''20:30'')
	insert into #ccintervalos values(41,@from,''20:30'',''21:00'')
	insert into #ccintervalos values(42,@from,''21:00'',''21:30'')
	insert into #ccintervalos values(43,@from,''21:30'',''22:00'')
	insert into #ccintervalos values(44,@from,''22:00'',''22:30'')
	insert into #ccintervalos values(45,@from,''22:30'',''23:00'')
	insert into #ccintervalos values(46,@from,''23:00'',''23:30'')
	insert into #ccintervalos values(47,@from,''23:30'',''00:00'')

	INSERT INTO #ccTempIntervaloTieAcuTot
	SELECT 
		FF.Dia [Dia],
		FF.Rango1 [Rango1],
		FF.Rango2 [Rango2],
		@inbound_id [inbound_id],
		@descripcion [descripcion],		
		FF.posicion [Prom. Posicion Personal],
		FF.Recibidas [Llamadas Recibidas],
		FF.Atendidas [Llamadas Atendidas],
		FF.Abandonadas [Llamadas Aban.],
		
		--dbo.fGetHHmmSS(FF.PosicionMAX) [Tiempo Maximo],
		
		--------------------------------------------------------------------------------------------
		--dbo.fGetHHmmSS(case when FF.PosicionMAX <= FF.acd and FF.acd>0 then 
		--					case when isnull(FF.acd - ((FF.Total_log+FF.Total_call)-FF.PosicionMAX),0)>0 then 
		--						isnull(FF.acd - ((FF.Total_log+FF.Total_call)-FF.PosicionMAX),0)
		--					else
		--						FF.acd
		--					end		
		--					when FF.PosicionMAX > FF.acd and FF.PosicionMAX < (FF.Total_log+FF.Total_call) and FF.Dispo<((FF.Total_log+FF.Total_call)-FF.PosicionMAX) then 
		--					case when isnull(FF.acd - ((FF.Total_log+FF.Total_call)-FF.PosicionMAX),0)>0 then 
		--						isnull(FF.acd - ((FF.Total_log+FF.Total_call)-FF.PosicionMAX),0)
		--					else
		--						FF.acd
		--					end							
		--			   else isnull(FF.acd,0) end +
		--(FF.ACW)+(FF.Logout)+(FF.Desconocido)+(FF.NoDispo)+
		--case when FF.PosicionMAX > FF.acd and FF.PosicionMAX < (FF.Total_log+FF.Total_call) and FF.Dispo>((FF.Total_log+FF.Total_call)-FF.PosicionMAX) then isnull(FF.Dispo - ((FF.Total_log+FF.Total_call)-FF.PosicionMAX),0)
		--	 --when FF.PosicionMAX > FF.acd and FF.PosicionMAX < (FF.Total_log+FF.Total_call) and FF.Dispo<((FF.Total_log+FF.Total_call)-FF.PosicionMAX) then 0
		--	 when FF.PosicionMAX > FF.acd and FF.PosicionMAX > (FF.Total_log+FF.Total_call) then isnull(FF.Dispo + (FF.PosicionMAX-(FF.Total_log+FF.Total_call)),0)
		--	 else FF.Dispo
		--end +	
		--(FF.Xfer)+(FF.Otra)+(FF.Cliente)+(FF.Ring)+(FF.Problem)+(FF.Manual)),
		--------------------------------------------------------------------------------------------
		
		dbo.fGetHHmmSS(case when FF.PosicionMAX <= FF.acd and FF.acd>0 then 
							case when isnull(FF.acd - ((FF.Total_log+FF.Total_call)-FF.PosicionMAX),0)>0 then 
								isnull(FF.acd - ((FF.Total_log+FF.Total_call)-FF.PosicionMAX),0)
							else
								FF.acd
							end		
							when FF.PosicionMAX > FF.acd and FF.PosicionMAX < (FF.Total_log+FF.Total_call) and FF.Dispo<((FF.Total_log+FF.Total_call)-FF.PosicionMAX) then 
							case when isnull(FF.acd - ((FF.Total_log+FF.Total_call)-FF.PosicionMAX),0)>0 then 
								isnull(FF.acd - ((FF.Total_log+FF.Total_call)-FF.PosicionMAX),0)
							else
								FF.acd
							end							
					   else isnull(FF.acd,0) end) [Tiempo ACD],					
		dbo.fGetHHmmSS(FF.ACW) [Tiempo ACW],		
		dbo.fGetHHmmSS(FF.Logout) [Tiempo Logout],
		dbo.fGetHHmmSS(FF.Desconocido) [Tiempo Descon],
		dbo.fGetHHmmSS(FF.NoDispo) [Tiempo Nodispo],	
		case when FF.PosicionMAX > FF.acd and FF.PosicionMAX < (FF.Total_log+FF.Total_call) and FF.Dispo>((FF.Total_log+FF.Total_call)-FF.PosicionMAX) then dbo.fGetHHmmSS(isnull(FF.Dispo - ((FF.Total_log+FF.Total_call)-FF.PosicionMAX),0))
			 --when FF.PosicionMAX > FF.acd and FF.PosicionMAX < (FF.Total_log+FF.Total_call) and FF.Dispo<((FF.Total_log+FF.Total_call)-FF.PosicionMAX) then dbo.fGetHHmmSS(0)
			 when FF.PosicionMAX > FF.acd and FF.PosicionMAX > (FF.Total_log+FF.Total_call) then dbo.fGetHHmmSS(isnull(FF.Dispo + (FF.PosicionMAX-(FF.Total_log+FF.Total_call)),0))
			 else dbo.fGetHHmmSS(FF.Dispo)
		end		[Tiempo Dispo],			
		dbo.fGetHHmmSS(FF.Xfer) [Tiempo Xfer],
		dbo.fGetHHmmSS(FF.Otra) [Tiempo Otra],
		dbo.fGetHHmmSS(FF.Cliente) [Tiempo Cliente],
		dbo.fGetHHmmSS(FF.Ring) [Tiempo Ring],
		dbo.fGetHHmmSS(FF.Problem) [Tiempo Problema],
		dbo.fGetHHmmSS(FF.Manual) [Tiempo Manual],		
		
		dbo.fGetHHmmSS(FF.Reten) [Tiempo Reten],
		FF.LlamadaSalidaExt [Llamadas Salida Ext],
		FF.TiempoSalidaExt [Tiempo Salida Ext],
		FF.servicio [% Nivel de servicio 80/40],
		FF.AHT [AHT],
		FF.Retenidas [Llamadas Retenidas],
		FF.LlamadasRing [Llamadas en Ring]
		from
		(SELECT
			convert(varchar(10),R.fecha,121) [Dia],
			R.rango1 [Rango1],
			R.rango2 [Rango2],
			--isnull(round(case when sum(PS.uid)>0 then ((convert(float,(sum(c.tacd+c.tacw+Tp.tlogout+Tp.tdesconocido+Tp.tnodispo+Tp.tdispo+c.txfer+Tp.totra+Tp.tcliente+c.tring+Tp.tproblem+Tp.tmanual)*100))/convert(float,sum(PS.uid)*1800))*sum(PS.uid))/100 else 0 end,1),0) [Posicion],
			isnull(round(case when sum(PS.uid)>0 then ((convert(float,(sum(PS.tlogueofra)*100))/convert(float,sum(PS.uid)*1800))*sum(PS.uid))/100 else 0 end,1),0) [Posicion],
			isnull(sum(c.ncalls),0) [Recibidas],
			isnull(sum(c.nacd),0) [Atendidas],
			isnull(sum(c.nabnd),0) [Abandonadas],		
			--isnull(round(case when sum(PS.uid)>0 then ((convert(float,(sum(PS.tlogueofra)*100))/convert(float,sum(PS.uid)*1800))*sum(PS.uid))/100 else 0 end,1)*1800,0) [PosicionMAX],		
			isnull(round(case when sum(PS.uid)>0 then ((convert(float,(sum(PS.tlogueofra)*100))/convert(float,sum(PS.uid)*1800))*sum(PS.uid))/100 else 0 end,1),0)*1800 [PosicionMAX],		
			isnull(sum(Tp.tlogout+Tp.tdesconocido+Tp.tnodispo+Tp.tdispo+Tp.totra+Tp.tcliente+Tp.tproblem+Tp.tmanual),0) [TOTAL_log],
			isnull(sum(c.tacd+c.tacw+c.txfer+c.tring),0) [TOTAL_call],
			isnull(sum(PS.uid),0)	[uid],
			isnull(sum(PS.tlogueofra),0) [tlogueofra],


			isnull(sum(c.tacd),0) [ACD],
			isnull(sum(c.tacw),0) [ACW],			
			isnull(sum(Tp.tlogout),0) [Logout],
			isnull(sum(Tp.tdesconocido),0) [Desconocido],
			isnull(sum(Tp.tnodispo),0) [Nodispo],
			isnull(sum(Tp.tdispo),0) [Dispo],
			isnull(sum(c.txfer),0) [Xfer],
			isnull(sum(Tp.totra),0) [Otra],
			isnull(sum(Tp.tcliente),0) [Cliente],
			isnull(sum(c.tring),0) [Ring],
			isnull(sum(Tp.tproblem),0) [Problem],
			isnull(sum(Tp.tmanual),0) [Manual],		
			
			isnull(sum(c.thold),0) [Reten],
			isnull(sum(l.SalExt),0) [LlamadaSalidaExt],
			isnull(case when sum(l.SalExt)>0 then sum(l.tprosalext) else 0 end,0) [TiempoSalidaExt],
			--dbo.fGetHHmmSS(isnull(sum(Tp.tdispo),0)) [TiempoDispon],
			--dbo.fGetHHmmSS(isnull(sum(Tp.tring),0)) [TiempoRing],
			sum(isnull(case when c.ncalls>0 then (c.nserv * 100) / c.ncalls else 0 end,0)) [servicio],
			sum(((case when c.nacd>0 then c.tacd/c.nacd else 0 end)+(case when c.nacw>0 then c.tacw/c.nacw else 0 end)+(case when c.nring>0 then c.tring/c.nring else 0 end)+(case when c.nhold>0 then c.thold/c.nhold else 0 end))) [AHT],
			isnull(sum(c.nhold),0) [Retenidas],
			isnull(sum(c.nring),0) [LlamadasRing]
		FROM
			(SELECT ID,FECHA,RANGO1,RANGO2
			 FROM   #ccintervalos) R
		LEFT OUTER JOIN	
			(SELECT case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,(i.cal_tDialog + i.cal_tWait + i.cal_tXfer + i.cal_tRing),i.cal_inicio)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,(i.cal_tDialog + i.cal_tWait + i.cal_tXfer + i.cal_tRing),i.cal_inicio)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,(i.cal_tDialog + i.cal_tWait + i.cal_tXfer + i.cal_tRing),i.cal_inicio)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,(i.cal_tDialog + i.cal_tWait + i.cal_tXfer + i.cal_tRing),i.cal_inicio)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,(i.cal_tDialog + i.cal_tWait + i.cal_tXfer + i.cal_tRing),i.cal_inicio)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,(i.cal_tDialog + i.cal_tWait + i.cal_tXfer + i.cal_tRing),i.cal_inicio)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,(i.cal_tDialog + i.cal_tWait + i.cal_tXfer + i.cal_tRing),i.cal_inicio)) }) end )+'':''+''30'' end as RANGO1,
			count(i.cal_id) ncalls, 	
			count(case when i.statusCall_id=13 then 1 else null end) nacd,
			count(case when i.statusCall_id=13 and i.cal_tnotas>0 then 1 else null end) nacw,		
			count(case when i.statusCall_id=13 and i.cal_tmoh>0 then 1 else null end) nhold,
			count(case when i.statusCall_id=13 and i.cal_tring>0 then 1 else null end) nring,
			count(case when i.statusCall_id=13 and (i.cal_twait+i.cal_txfer+i.cal_tring)<40 then 1 else null end) nserv,
			sum(case when i.statuscall_id = 13 then i.cal_tmoh else 0 end) thold,
			sum(case when i.statusCall_id=13 and i.cal_tdialog>=0 then i.cal_tdialog else null end) tacd,
			sum(case when i.statusCall_id=13 then i.cal_tnotas else null end) tacw,
			sum(case when i.statusCall_id=13 then i.cal_tring else null end) tring,
			sum(case when i.statusCall_id=13 then i.cal_txfer else null end) txfer,
			count(case when (i.statuscall_id <> 13) then 1 else null end) nabnd
			from cccallsin i (nolock)
			where i.inbound_id=@inb and i.cal_inicio between @from and @to
			GROUP BY case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,(i.cal_tDialog + i.cal_tWait + i.cal_tXfer + i.cal_tRing),i.cal_inicio)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,(i.cal_tDialog + i.cal_tWait + i.cal_tXfer + i.cal_tRing),i.cal_inicio)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,(i.cal_tDialog + i.cal_tWait + i.cal_tXfer + i.cal_tRing),i.cal_inicio)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,(i.cal_tDialog + i.cal_tWait + i.cal_tXfer + i.cal_tRing),i.cal_inicio)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,(i.cal_tDialog + i.cal_tWait + i.cal_tXfer + i.cal_tRing),i.cal_inicio)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,(i.cal_tDialog + i.cal_tWait + i.cal_tXfer + i.cal_tRing),i.cal_inicio)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,(i.cal_tDialog + i.cal_tWait + i.cal_tXfer + i.cal_tRing),i.cal_inicio)) }) end )+'':''+''30'' end) C
				ON C.rango1 = R.rango1
		LEFT OUTER JOIN
			(select case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,(t.tAntesXfer + t.tDespuesXfer),t.fechaFin)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,(t.tAntesXfer + t.tDespuesXfer),t.fechaFin)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,(t.tAntesXfer + t.tDespuesXfer),t.fechaFin)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,(t.tAntesXfer + t.tDespuesXfer),t.fechaFin)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,(t.tAntesXfer + t.tDespuesXfer),t.fechaFin)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,(t.tAntesXfer + t.tDespuesXfer),t.fechaFin)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,(t.tAntesXfer + t.tDespuesXfer),t.fechaFin)) }) end )+'':''+''30'' end as rango1,
					COUNT(CASE WHEN t.modo in (0,3,4) and t.tipo=1 then 1 else NULL end) as SalExt,
					SUM(CASE WHEN t.modo in (0,3,4) and t.tipo=1 then (t.tAntesXfer + t.tDespuesXfer) else 0 end) as tprosalext
			from ccLogTransfers t (nolock)
				inner join ccCallsIn i (nolock) on (i.cal_id = t.cal_id and i.inbound_id=@inb and i.cal_inicio between @from and @to)
			where t.fechafin between @from and @to
			group by case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,(t.tAntesXfer + t.tDespuesXfer),t.fechaFin)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,(t.tAntesXfer + t.tDespuesXfer),t.fechaFin)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,(t.tAntesXfer + t.tDespuesXfer),t.fechaFin)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,(t.tAntesXfer + t.tDespuesXfer),t.fechaFin)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,(t.tAntesXfer + t.tDespuesXfer),t.fechaFin)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,(t.tAntesXfer + t.tDespuesXfer),t.fechaFin)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,(t.tAntesXfer + t.tDespuesXfer),t.fechaFin)) }) end )+'':''+''30'' end) L
		ON L.rango1 = R.rango1
		LEFT OUTER JOIN
			(select 
				Pg.rango1 rango1,
				Pg.rango2 rango2,
				count(distinct Pg.uid) uid,
				sum(Pg.tlogueofra) tlogueofra
			from	
			(select 
				Ss.rango1 rango1, 
				Ss.rango2 rango2,
				Tt.user_id uid,
				sum(case when convert(varchar(8),Tt.login,108)>Ss.rango1 and convert(varchar(8),Tt.logout,108)<(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,convert(varchar(8),Tt.login,108),convert(varchar(8),Tt.logout,108))
			    		 when convert(varchar(8),Tt.login,108)>Ss.rango1 and convert(varchar(8),Tt.logout,108)>(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,convert(varchar(8),Tt.login,108),(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end))
						 when convert(varchar(8),Tt.login,108)<Ss.rango1 and convert(varchar(8),Tt.logout,108)>(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then 1800
						 when convert(varchar(8),Tt.login,108)<Ss.rango1 and convert(varchar(8),Tt.logout,108)<(case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end) then datediff(ss,Ss.rango1,convert(varchar(8),Tt.logout,108))
				else 0 end) tlogueofra 						
			from #ccintervalos Ss
			LEFT OUTER JOIN
				(select CCLOG.uid user_id, 
						case when convert(varchar(10),CCLOG.login,121) = convert(varchar(10),getdate(),121)
						then 
							datediff(ss,CCLOG.login,isnull(CCLOG.logout,getdate()))	
						else 
							datediff(ss,CCLOG.login,CCLOG.logout)	
						end as tlogueo,
						CCLOG.login login,
						case when convert(varchar(10),CCLOG.login,121) = convert(varchar(10),getdate(),121)
						then	
							isnull(CCLOG.logout,getdate())
						else 	
							CCLOG.logout
						end	as logout,						
						case when CONVERT(int, SUBSTRING(CONVERT(char(30), CCLOG.login), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(CCLOG.login) })<10 then ''0''+convert(varchar(2),{ fn HOUR(CCLOG.login) }) else convert(varchar(2),{ fn HOUR(CCLOG.login) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(CCLOG.login) })<10 then ''0''+convert(varchar(2),{ fn HOUR(CCLOG.login) }) else convert(varchar(2),{ fn HOUR(CCLOG.login) }) end )+'':''+''30'' end as login2,
						case when convert(varchar(10),CCLOG.login,121) = convert(varchar(10),getdate(),121)
						then 
							case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), isnull(CCLOG.logout,getdate())), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(isnull(CCLOG.logout,getdate())) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(isnull(CCLOG.logout,getdate())) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })) else convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOG.logout,getdate())) })) end)+'':''+''30'' end 
						else
							case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), CCLOG.logout), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(CCLOG.logout) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(CCLOG.logout) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(CCLOG.logout) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(CCLOG.logout) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(CCLOG.logout) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(CCLOG.logout) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(CCLOG.logout) })) else convert(varchar(2),CONVERT(int, { fn HOUR(CCLOG.logout) })) end)+'':''+''30'' end
						end	as logout2
						from
						(select uid, inbound_id, login, max(logout) as logout
							from 
							(
								select uid, inbound_id, login, ISNULL(logout, 
								(
									select MIN(fecha) from ccPosicionEspecialidad (nolock)
									where tipo = 1 AND fecha > Detail.login AND [user_id] = Detail.uid AND inbound_id = Detail.inbound_id
								)) as logout
								from
								(
									select ccPosicionEspecialidad.[user_id] AS [uid],ccPosicionEspecialidad.inbound_id as inbound_id, fecha AS [login], Login.logout
									from 
									(	
										select uid,inbound_id, MAX(login) as login, logout
										from
										(
											select Login.[user_id] AS [uid],inbound_id AS [inbound_id], fecha AS [login], 
											(
												select MIN(subLogin.fecha) from ccPosicionEspecialidad subLogin (nolock)
												where subLogin.tipo = 0 AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id] AND sublogin.[inbound_id] = Login.[inbound_id]
											) AS [logout]
											from ccPosicionEspecialidad Login (nolock)
											where tipo = 1 AND inbound_id = @inb
											and login.fecha >= dateadd( dd, -2, @from3 )
											group by  Login.[user_id],Login.inbound_id, Login.fecha
										) LogDet
										group by uid,inbound_id, logout
									) Login
									RIGHT OUTER JOIN ccPosicionEspecialidad (nolock)
									ON (ccPosicionEspecialidad.[user_id] = Login.uid AND ccPosicionEspecialidad.fecha = Login.login AND ccPosicionEspecialidad.inbound_id = Login.inbound_id)
									where tipo = 1
									and ccPosicionEspecialidad.inbound_id = @inb
									and ccPosicionEspecialidad.fecha >= dateadd( dd, -2, @from3 )
								) Detail
							) LoginDet
						where login >= @from3 AND login < @to
						group by uid,inbound_id,login) CCLOG
				) Tt
				ON Tt.login2 <= Ss.rango1	
					and (Tt.logout2 >= case when Ss.rango2=''00:00'' then ''24:00'' else Ss.rango2 end or Tt.logout2 is null)						
			group by Ss.rango1,	Ss.rango2, Tt.user_id
			) PG
			group by Pg.rango1,	Pg.rango2
			) PS
			ON PS.rango1 = R.Rango1
		LEFT OUTER JOIN
			(select
				Tm.fecha fecha,
				Tm.rango1 rango1,
				Tm.rango2 rango2,
				--Tm.user_id user_id,
				isnull(sum(case when Tm.TipoStatusAge_id=0 then Tm.tstatusfra end),0) tlogout,
				isnull(count(case when Tm.TipoStatusAge_id=0 then Tm.nstatusfra end),0) nlogout,
				isnull(sum(case when Tm.TipoStatusAge_id=1 then Tm.tstatusfra end),0) tdesconocido,
				isnull(count(case when Tm.TipoStatusAge_id=1 then Tm.nstatusfra end),0) ndesconocido,
				isnull(sum(case when Tm.TipoStatusAge_id=2 then Tm.tstatusfra end),0) tnodispo,
				isnull(count(case when Tm.TipoStatusAge_id=2 then Tm.nstatusfra end),0) nnodispo,
				isnull(sum(case when Tm.TipoStatusAge_id=3 then Tm.tstatusfra end),0) tdispo,
				isnull(count(case when Tm.TipoStatusAge_id=3 then Tm.nstatusfra end),0) ndispo,
				isnull(sum(case when Tm.TipoStatusAge_id=4 then Tm.tstatusfra end),0) tdialog,
				isnull(count(case when Tm.TipoStatusAge_id=4 then Tm.nstatusfra end),0) ndialog,
				isnull(sum(case when Tm.TipoStatusAge_id=5 then Tm.tstatusfra end),0) txfer,
				isnull(count(case when Tm.TipoStatusAge_id=5 then Tm.nstatusfra end),0) nxfer,
				isnull(sum(case when Tm.TipoStatusAge_id=6 then Tm.tstatusfra end),0) tnotas,
				isnull(count(case when Tm.TipoStatusAge_id=6 then Tm.nstatusfra end),0) nnotas,
				isnull(sum(case when Tm.TipoStatusAge_id=7 then Tm.tstatusfra end),0) totra,			
				isnull(count(case when Tm.TipoStatusAge_id=7 then Tm.nstatusfra end),0) notra,			
				isnull(sum(case when Tm.TipoStatusAge_id=8 then Tm.tstatusfra end),0) tcliente,			
				isnull(count(case when Tm.TipoStatusAge_id=8 then Tm.nstatusfra end),0) ncliente,			
				isnull(sum(case when Tm.TipoStatusAge_id=9 then Tm.tstatusfra end),0) tring,			
				isnull(count(case when Tm.TipoStatusAge_id=9 then Tm.nstatusfra end),0) nring,			
				isnull(sum(case when Tm.TipoStatusAge_id=11 then Tm.tstatusfra end),0) tproblem,			
				isnull(count(case when Tm.TipoStatusAge_id=11 then Tm.nstatusfra end),0) nproblem,			
				isnull(sum(case when Tm.TipoStatusAge_id=21 then Tm.tstatusfra end),0) tmanual,			
				isnull(count(case when Tm.TipoStatusAge_id=21 then Tm.nstatusfra end),0) nmanual		
			from
				(select 
					G.fecha fecha,
					G.rango1 rango1,
					G.rango2 rango2,
					--G.login login_,
					--G.logout logout_,
					--G.tlogueofra tlogueofra_,
					--Rg.rangoinicial rangoinicial_,
					--Rg.rangofinal rangofinal_,
					G.user_id user_id,
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
					case when Rg.tstatusfra is not null then 1 else 0 end nstatusfra,
					G.tlogueofra tlogueofra,
					Rg.TipoStatusAge_id TipoStatusAge_id
				from
				(select distinct
					(S.fecha + S.rango1) fecha,
					S.rango1 rango1, 
					S.rango2 rango2,
					T.user_id user_id,
					T.tlogueo tlogueo,
					T.login login,
					T.logout logout,
					T.login2 login2,
					T.logout2 logout2,
					case when convert(varchar(8),t.login,108)>s.rango1 and convert(varchar(8),t.logout,108)<(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,convert(varchar(8),t.login,108),convert(varchar(8),t.logout,108))
				    		 when convert(varchar(8),t.login,108)>s.rango1 and convert(varchar(8),t.logout,108)>(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,convert(varchar(8),t.login,108),(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end))
							 when convert(varchar(8),t.login,108)<s.rango1 and convert(varchar(8),t.logout,108)>(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then 1800
							 when convert(varchar(8),t.login,108)<s.rango1 and convert(varchar(8),t.logout,108)<(case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end) then datediff(ss,s.rango1,convert(varchar(8),t.logout,108))
					else 0 end tlogueofra 						
				from #ccintervalos S
				LEFT OUTER JOIN
					(select CCLOGLOGIN.uid user_id, 
						case when convert(varchar(10),CCLOGLOGIN.login,121) = convert(varchar(10),getdate(),121)
						then 
							datediff(ss,CCLOGLOGIN.login,isnull(CCLOGLOGIN.logout,getdate()))	
						else 
							datediff(ss,CCLOGLOGIN.login,CCLOGLOGIN.logout)	
						end as tlogueo,
						CCLOGLOGIN.login login,
						case when convert(varchar(10),CCLOGLOGIN.login,121) = convert(varchar(10),getdate(),121)
						then	
							isnull(CCLOGLOGIN.logout,getdate())
						else 	
							CCLOGLOGIN.logout
						end	as logout,						
						case when CONVERT(int, SUBSTRING(CONVERT(char(30), CCLOGLOGIN.login), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(CCLOGLOGIN.login) })<10 then ''0''+convert(varchar(2),{ fn HOUR(CCLOGLOGIN.login) }) else convert(varchar(2),{ fn HOUR(CCLOGLOGIN.login) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(CCLOGLOGIN.login) })<10 then ''0''+convert(varchar(2),{ fn HOUR(CCLOGLOGIN.login) }) else convert(varchar(2),{ fn HOUR(CCLOGLOGIN.login) }) end )+'':''+''30'' end as login2,
						case when convert(varchar(10),CCLOGLOGIN.login,121) = convert(varchar(10),getdate(),121)
						then 
							case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), isnull(CCLOGLOGIN.logout,getdate())), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })) else convert(varchar(2),CONVERT(int, { fn HOUR(isnull(CCLOGLOGIN.logout,getdate())) })) end)+'':''+''30'' end 
						else
							case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), CCLOGLOGIN.logout), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(CCLOGLOGIN.logout) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(CCLOGLOGIN.logout) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })) else convert(varchar(2),CONVERT(int, { fn HOUR(CCLOGLOGIN.logout) })) end)+'':''+''30'' end
						end	as logout2
							from
							(select uid, inbound_id, login, max(logout) as logout
								from 
								(
									select uid, inbound_id, login, ISNULL(logout, 
									(
										select MIN(fecha) from ccPosicionEspecialidad (nolock)
										where tipo = 1 AND fecha > det.login AND [user_id] = det.uid AND inbound_id = det.inbound_id
									)) as logout
									from
									(
										select ccPosicionEspecialidad.[user_id] AS [uid],ccPosicionEspecialidad.inbound_id as inbound_id, fecha AS [login], Login.logout
										from 
										(	
											select uid,inbound_id, MAX(login) as login, logout
											from
											(
												select Login.[user_id] AS [uid],inbound_id AS [inbound_id], fecha AS [login], 
												(
													select MIN(subLogin.fecha) from ccPosicionEspecialidad subLogin (nolock)
													where subLogin.tipo = 0 AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id] AND sublogin.[inbound_id] = Login.[inbound_id]
												) AS [logout]
												from ccPosicionEspecialidad Login (nolock)
												where tipo = 1 AND inbound_id = @inb
												and login.fecha >= dateadd( dd, -2, @from3 )
												group by  Login.[user_id],Login.inbound_id, Login.fecha
											) LogDetail
											group by uid,inbound_id, logout
										) Login
										RIGHT OUTER JOIN ccPosicionEspecialidad (nolock)
										ON (ccPosicionEspecialidad.[user_id] = Login.uid AND ccPosicionEspecialidad.fecha = Login.login AND ccPosicionEspecialidad.inbound_id = Login.inbound_id)
										where tipo = 1
										and ccPosicionEspecialidad.inbound_id = @inb
										and ccPosicionEspecialidad.fecha >= dateadd( dd, -2, @from3 )
									) Det
								) LoginDetail
							where login >= @from3 AND login < @to
							group by uid,inbound_id,login) CCLOGLOGIN
					) T
				ON t.login2 <= s.rango1	
					and (t.logout2 >= case when s.rango2=''00:00'' then ''24:00'' else s.rango2 end or t.logout2 is null)						
				) G
			LEFT OUTER JOIN
				(select	
					lg.user_id user_id,
					lg.rangoinicial rangoinicial,
					lg.rangofinal rangofinal,
					V.rango1 rango1,
					V.rango2 rango2,
					sum(case when convert(varchar(8),lg.rangoInicial,108)>V.rango1 and convert(varchar(8),lg.rangoFinal,108)<(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,convert(varchar(8),lg.rangoInicial,108),convert(varchar(8),lg.rangoFinal,108))
							 when convert(varchar(8),lg.rangoInicial,108)>V.rango1 and convert(varchar(8),lg.rangoFinal,108)>(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,convert(varchar(8),lg.rangoInicial,108),(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end))
							 when convert(varchar(8),lg.rangoInicial,108)<V.rango1 and convert(varchar(8),lg.rangoFinal,108)>(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then 1800
							 when convert(varchar(8),lg.rangoInicial,108)<V.rango1 and convert(varchar(8),lg.rangoFinal,108)<(case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end) then datediff(ss,V.rango1,convert(varchar(8),lg.rangoFinal,108))
					else 0 end) tstatusfra,							
					sum(lg.tstatus) tstatus,
					lg.TipoStatusAge_id TipoStatusAge_id
				from
					(
					select user_id as user_id,
						dateadd(ss,-1*(t.tStatus),t.fecha) rangoInicial,							
						t.fecha rangoFinal,							
						isnull(case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,-1*(t.tstatus),t.fecha)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''30'' end,0) rango1,
						isnull(case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(t.fecha) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(t.fecha) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) end)+'':''+''30'' end,0) rango2,														
						sum(t.tStatus) tstatus,
						t.TipoStatusAge_id TipoStatusAge_id
					from  cclogagentesdia t with (index(ccLogAgentesDia_fecAsc),nolock) 
					where t.fecha between @from and @to
					group by user_id,dateadd(ss,-1*(t.tStatus),t.fecha),t.fecha,
						isnull(case when CONVERT(int, SUBSTRING(CONVERT(char(30), dateadd(ss,-1*(t.tstatus),t.fecha)), 16, 2)) / 30=0 then CONVERT(varchar(2), case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''00'' else CONVERT(varchar(2),case when ({ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) })<10 then ''0''+convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) else convert(varchar(2),{ fn HOUR(dateadd(ss,-1*(t.tstatus),t.fecha)) }) end )+'':''+''30'' end,0),
						isnull(case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2), case when(CONVERT(int, { fn HOUR(t.fecha) })+1)<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })+1) end)+'':''+''00'' else CONVERT(varchar(2),case when(CONVERT(int, { fn HOUR(t.fecha) }))<10 then ''0''+convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) else convert(varchar(2),CONVERT(int, { fn HOUR(t.fecha) })) end)+'':''+''30'' end,0),
						t.TipoStatusAge_id
					 ) lg
				left outer join 
					(SELECT rango1,rango2 from #ccintervalos) V
				on (V.rango1 >= lg.rango1
					and case when V.rango2=''00:00'' then ''24:00'' else V.rango2 end <= lg.rango2)
				group by lg.user_id,lg.rangoinicial,lg.rangofinal,V.rango1,V.rango2,lg.TipoStatusAge_id
				) Rg
			on (Rg.user_id = G.user_id and Rg.rango1 = G.rango1 and Rg.rangoinicial < G.logout and Rg.rangofinal > G.login)
			) Tm
			group by Tm.fecha,Tm.rango1,Tm.rango2
			) Tp	
			on Tp.rango1 = R.rango1			
		group by R.id,R.fecha,R.rango1,R.rango2) FF 
		order by FF.Dia,FF.Rango1 asc
END


	set @sql=''SELECT 
			dia [Dia], 
			rango1 [Rango1],
			rango2 [Rango2],
			inbound_id [Split/Skill Numero],
			descripcion [Split/Skill Nombre],			
			PromPosicionPersonal [Prom. Posicion Personal],
			LlamadasRecibidas [Llamadas Recibidas],
			LlamadasAtendidas [Llamadas Atendidas],
			LlamadasAban [Llamadas Aban.],		
			TiempoACD [Tiempo ACD],					
			TiempoACW [Tiempo ACW],		
			TiempoLogout [Tiempo Logout],
			TiempoDescon [Tiempo Descon],
			TiempoNoDispo [Tiempo Nodispo],	
			TiempoDispo [Tiempo Dispo],			
			TiempoXfer [Tiempo Xfer],
			TiempoOtra [Tiempo Otra],
			TiempoCliente [Tiempo Cliente],
			TiempoRing [Tiempo Ring],
			TiempoProblema [Tiempo Problema],
			TiempoManual [Tiempo Manual],		
			TiempoReten [Tiempo Reten],
			LlamadasSalidaExt [Llamadas Salida Ext],
			TiempoSalidaExt [Tiempo Salida Ext],
			PorcNiveldeServicio4080 [% Nivel de servicio 80/40],
			AHT [AHT],
			LlamadasRetenidas [Llamadas Retenidas],
			LlamadasenRing [Llamadas en Ring]
		FROM	
			ccGenIntervaloTieAcuTot (nolock)
			WHERE   inbound_id = '' + @inbound_id + '' AND dia >= '' + char(0x27) + CONVERT(VARCHAR(10),@fecini,121) + char(0x27) + '' AND dia < '' + char(0x27) + CONVERT(VARCHAR(10),@fecfin,121) + char(0x27) + ''''

	set @sql1=''order by dia,rango1 asc''
	set @sql2=''UNION ALL''
	
	set @sql3=''SELECT 
			dia collate SQL_Latin1_General_CP1_CI_AS [Dia], 
			rango1 collate SQL_Latin1_General_CP1_CI_AS [Rango1],
			rango2 collate SQL_Latin1_General_CP1_CI_AS [Rango2],
			inbound_id [Split/Skill Numero],
			descripcion  collate SQL_Latin1_General_CP1_CI_AS [Split/Skill Nombre],			
			PromPosicionPersonal [Prom. Posicion Personal],
			LlamadasRecibidas [Llamadas Recibidas],
			LlamadasAtendidas [Llamadas Atendidas],
			LlamadasAban [Llamadas Aban.],		
			TiempoACD collate SQL_Latin1_General_CP1_CI_AS [Tiempo ACD],					
			TiempoACW collate SQL_Latin1_General_CP1_CI_AS [Tiempo ACW],		
			TiempoLogout collate SQL_Latin1_General_CP1_CI_AS [Tiempo Logout],
			TiempoDescon collate SQL_Latin1_General_CP1_CI_AS [Tiempo Descon],
			TiempoNoDispo collate SQL_Latin1_General_CP1_CI_AS [Tiempo Nodispo],	
			TiempoDispo collate SQL_Latin1_General_CP1_CI_AS [Tiempo Dispo],			
			TiempoXfer collate SQL_Latin1_General_CP1_CI_AS [Tiempo Xfer],
			TiempoOtra collate SQL_Latin1_General_CP1_CI_AS [Tiempo Otra],
			TiempoCliente collate SQL_Latin1_General_CP1_CI_AS [Tiempo Cliente],
			TiempoRing collate SQL_Latin1_General_CP1_CI_AS [Tiempo Ring],
			TiempoProblema collate SQL_Latin1_General_CP1_CI_AS [Tiempo Problema],
			TiempoManual collate SQL_Latin1_General_CP1_CI_AS [Tiempo Manual],		
			TiempoReten collate SQL_Latin1_General_CP1_CI_AS [Tiempo Reten],
			LlamadasSalidaExt [Llamadas Salida Ext],
			TiempoSalidaExt collate SQL_Latin1_General_CP1_CI_AS [Tiempo Salida Ext],
			PorcNiveldeServicio4080 [% Nivel de servicio 80/40],
			AHT [AHT],
			LlamadasRetenidas [Llamadas Retenidas],
			LlamadasenRing [Llamadas en Ring]
		FROM	
			#ccTempIntervaloTieAcuTot ''					
	
	IF @fechaI = CONVERT(VARCHAR(10),getdate(),121)
	BEGIN
		exec(@sql3+ '' '' + @sql1)
		--select @sql3 
		--select @sql1 
	END	
	IF @fechaI < CONVERT(VARCHAR(10),getdate(),121) AND @fechaF >= CONVERT(VARCHAR(10),getdate(),121) 
	BEGIN
		exec(@sql + '' '' + @sql2 + '' '' + @sql3 + '' '' + @sql1)
		--select @sql 
		--select @sql2 
		--select @sql3 
		--select @sql1 
	END	
	IF @fechaI < CONVERT(VARCHAR(10),getdate(),121) AND @fechaF < CONVERT(VARCHAR(10),getdate(),121)
	BEGIN
		exec(@sql + '' '' + @sql1)
		--select @sql
		--select @sql1 
	END

END'
		
	EXEC(@Sql)
	
------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC]
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
