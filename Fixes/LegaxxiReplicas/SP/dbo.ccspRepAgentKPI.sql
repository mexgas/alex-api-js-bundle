ALTER PROCEDURE [dbo].[ccspRepAgentKPI]
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
	delete RepAgentKPI with(rowlock)
	where date >= @from AND date < @to

	create table #ccCalls_Temp(
	cal_id int, 
	User_id smallint, 
	statusCall_id tinyint, 
	cal_tDialog smallint, 
	cal_Inicio datetime, 
	cal_whoHung smallint, 
	tipoTabla tinyint)

	CREATE NONCLUSTERED INDEX IX_ccCalls_Temp ON #ccCalls_Temp (cal_id ASC)

	insert into #ccCalls_Temp 
	select cal_id, User_id, statusCall_id, cal_tDialog, convert(varchar(8), cal_Inicio, 112)+' 00:00', cal_whoHung, 0 
	from ccoCallsOut with(nolock)
	where cal_inicio between @from and @to and cal_manual < 3

	insert into #ccCalls_Temp 
	select cal_id, User_id, statusCall_id, cal_tDialog, convert(varchar(8), cal_Inicio, 112)+' 00:00', cal_whoHung, 1 
	from ccCallsIn with(nolock)
	where cal_inicio between @from and @to 

	insert into RepAgentKPI
	select convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121)) date, Fst.Login as login, Fst.user_id as [userId],
	Nombres + isnull(' '+ApellidoPaterno, '') + isnull(' '+ApellidoMaterno, '') as [user], Total as totalCalls, Cin as callsIn, 
	Cout as callsOut, C10 as [finishedCalls10], C20 as [finishedCalls20], C30 as [finishedCalls30], cal_whoHung as whoHung, 
	isnull(avg_fCalc, 0) as callsAvgTime,
	datepart(yyyy,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(mm,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(dd,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(hh,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121))), 
	datepart(mi,convert(datetime,convert(varchar(11), Snd.cal_Inicio, 121)))
	from 
	(
	select User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno 
	from ccUserView
	) as Fst
	join
	(
	select user_id, cal_Inicio, sum(Total) Total, sum(Cin) Cin, sum(Cout) Cout, sum(C10) C10, sum(C20) C20, sum(C30) C30, sum(cal_whoHung) cal_whoHung
	from (select user_id, cal_Inicio, 1 Total, tipoTabla Cin, case tipoTabla when 0 then 1 else 0 end Cout,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<10 then 1 else 0 end C10,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<20 then 1 else 0 end C20,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<30 then 1 else 0 end C30,
		cal_whoHung from #ccCalls_Temp
	) as Conteos group by user_id, cal_Inicio
	) as Snd
	on Fst.User_id = Snd.User_id
	left join 
	(
	select User_id, cast((AVG(convert(bigint,fecha_Calc_ms)))/1000.0 as decimal(10,0)) avg_fCalc 
	from ccLogAgentesDia_Dialog with(nolock)
	where fecha_Dialog between @from and @to 
	group by User_id
	) as Trd
	on Snd.User_id = Trd.User_id

	drop table #ccCalls_Temp
end