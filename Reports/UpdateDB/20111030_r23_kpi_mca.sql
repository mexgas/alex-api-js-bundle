/*
Autor: Armando Rodriguez, Mauricio perez
Fecha: 2011/10/30
Descripcion: reportes de kpi, correccion reportes mca
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '23'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='ALTER PROCEDURE [dbo].[sp_mkt_agentes]
@from datetime,
@to datetime
AS

BEGIN

SELECT acd.user_id [user],login [Usuario],agt_name [Nombre Agente],
isnull(nacd,0) [Llamadas ACD],
tprom_acd [Tiempo prom ACD],
tprom_acw [Tiempo prom ACW],
t_acd [Tiempo ACD],
t_acw [Tiempo ACW],
tresp [Tiempo Llamado Agente], 
t_otra [Otra Hora],
t_aux [Tiempo AUX],
t_disp [Tiempo Disponible],
t_pers [Tiempo Personal],
cayuda [Ayuda], xfersal [Trans Salida] 
FROM
	(select
		c.user_id,
		count(case when c.statusCall_id=13 then 1 else null end) nacd,
		substring(convert(varchar,dateadd(ss,isnull(avg(case when c.statusCall_id=13 then c.cal_tdialog else null end),0),''''),120),12,8) tprom_acd,
		substring(convert(varchar,dateadd(ss,isnull(avg(case when c.statusCall_id=13 then c.cal_tnotas else null end),0),''''),120),12,8) tprom_acw,
		substring(convert(varchar,dateadd(ss,sum(case when c.statusCall_id=13 then c.cal_tdialog else 0 end),''''),120),12,8) t_acd,
		substring(convert(varchar,dateadd(ss,sum(c.cal_tnotas),''''),120),12,8) t_acw,
		substring(convert(varchar,dateadd(ss,sum(case when c.statuscall_id = 13 then (c.cal_twait + c.cal_txfer + c.cal_tring) else NULL end),''''),120),12,8) tresp,
		count(case when l.modo in (3,4) and l.tipo=1 then 1 else NULL end) cayuda, 
		count(case when l.modo in (0,3,4) and l.tipo=1 then 1 else NULL end) xfersal
	from cccallsin c (nolock) 
	LEFT OUTER JOIN ccLogTransfers l (nolock) on (l.cal_id = c.cal_id and l.fechaFin between @from and @to)
	where c.cal_inicio between @from and @to and c.user_id>0 and c.inbound_id>0 group by c.user_id) acd
LEFT OUTER JOIN
	(select user_id,
	substring(convert(varchar,dateadd(ss,sum(case when TipoStatusAge_id in (5,6,7) then tstatus else 0 end),''''),120),12,8) t_otra,
	substring(convert(varchar,dateadd(ss,sum(case when TipoStatusAge_id = 2 then tstatus else 0 end),''''),120),12,8) t_aux, 	
	substring(convert(varchar,dateadd(ss,sum(case when TipoStatusAge_id = 3 then tstatus else 0 end),''''),120),12,8) t_disp, 
	substring(convert(varchar,dateadd(ss,sum(tstatus),''''),120),12,8) t_pers
	from cclogagentesdia (nolock) where fecha between @from and @to group by user_id) tready
ON tready.user_id=acd.user_id
LEFT OUTER JOIN
	(select user_id, login, isnull(apellidopaterno,'''')+'' ''+isnull(apellidomaterno,'''')+'' ''+isnull(nombres,'''') agt_name
	from ccusers (nolock)) users
ON users.user_id=acd.user_id

END'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''callzilla_inbound'',
''declare @server varchar(200), @sql  varchar(8000), @from datetime, @to datetime
select @server = valor from ccsettings where setting_id = 22
set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)

set @sql = ''''declare @calInii as varchar(15), @calfini as varchar(15)
select @calInii = isnull(max(cal_id),1) from '''' + @server +''''.dbo.cccallsin  WITH(NOLOCK)
select @calfini = min(cal_id) from (select isnull(min(cal_id),0) cal_id from cccallsin with(index (IX_ccCallsIn),NOLOCK) where cal_inicio > '''' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '''' union all select max(cal_id) cal_id from ccCallsIn WITH(NOLOCK)) as a where cal_id <> 0
''''
set @sql = @sql + ''''select cal_id,dni_id, cal_ani, cal_puerto,inbound_id, user_id, cal_extension,cal_colgada,cal_key,statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_twait,cal_txfer,cal_tcall,cal_tring,cal_xfer,cal_inicio,cal_opciones,cal_origin_id, cal_tMoh, cal_whoHung from cccallsin WITH(NOLOCK) WHERE cal_id > @calInii and cal_id<= @calfini''''
--print @sql
exec(@sql)'',''LLamadasNuxiba_ent'',0,0,10,''01/01/1900 00:01'',''01/01/1900 23:59'',''1111111'',''10.208.88.203'',''CallZilla'',''90142f74ff4b825987c39d90b99f7957'',''a4ad6e11430b9b9f6109c6c05ad9a89e'','''',''10.208.88.204|ccreports|183f5bf17c2d2409157ead96ecfc25a7|370909b16ba952906b09a369fd49a8fd'',0,'''','''',0,0)
'
	EXEC(@Sql)

 	set @Sql='alter table ccoCallsOut add tConnTime datetime null
alter table ccoCallsOut add tBridgeTime datetime null
'
	EXEC(@Sql)

 	set @Sql='create table ccLogAgentesDia_Dialog (
	Log_DialId int not null,
	User_id smallint, 
	Cam_id smallint, 
	fecha_Calc_ms int, 
	tStatus_Dispo int, 
	fecha_Dispo datetime, 
	tStatus_Dialog int, 
	fecha_Dialog datetime)
'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE ccLogAgentesDia_Dialog ADD CONSTRAINT PK_ccLogAgentesDia_Dialog PRIMARY KEY CLUSTERED(Log_DialId)
'
	EXEC(@Sql)

 	set @Sql='insert into exp_jobs 
select ''ccLogAgentesDia_Dialog'', ''declare @server varchar(200)
declare @sql  varchar(8000)
declare @from datetime
declare @to datetime

select @server = valor from ccsettings where setting_id = 22

set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)

set @sql = ''''declare @DialIdIni as varchar(15)
declare @DialIdfin as varchar(15)
select @DialIdIni = isnull(max(Log_DialId),1) from '''' + @server +''''.dbo.ccLogAgentesDia_Dialog WITH(NOLOCK)
select @DialIdfin = min(Log_DialId) from 
	( select isnull(min(Log_DialId),0) Log_DialId from ccLogAgentesDia_Dialog 
	with(index (PK_ccLogAgentesDia_Dialog),NOLOCK) where fecha_Dialog > '''' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '''' 
union all select max(Log_DialId) Log_DialId from ccLogAgentesDia_Dialog WITH(NOLOCK)) as a where Log_DialId <> 0 '''' + nchar(13)

set @sql = @sql + ''''select Log_DialId, User_id, Cam_id, fecha_Calc_ms, tStatus_Dispo, fecha_Dispo, tStatus_Dialog, fecha_Dialog
from ccLogAgentesDia_Dialog WITH(NOLOCK) WHERE Log_DialId>@DialIdIni and Log_DialId<= @DialIdfin''''
--print @sql
exec(@sql)

exec ccsp_LogInfo @sql, -19'', ''ccLogAgentesDia_Dialog'', 1, 0, 5, ''1900-01-01 00:01:00'', ''1900-01-01 23:59:00'', ''1111111'',
'''', '''', '''', '''', '''', '''', 0, '''', '''', 1, 1'
	EXEC(@Sql)

 	set @Sql='alter FUNCTION [dbo].[fn_RIASplitDelimited](@List nvarchar(2000), @SplitOn nvarchar(1))
RETURNS @RtnValue table (Id int identity(1,1), Value nvarchar(100))
AS
BEGIN
While (Charindex(@SplitOn,@List)>0)
Begin 
	Insert Into @RtnValue (value)
	Select 
		Value = ltrim(rtrim(Substring(@List,1,Charindex(@SplitOn,@List)-1))) 
	Set @List = Substring(@List,Charindex(@SplitOn,@List)+len(@SplitOn),len(@List))
End 

Insert Into @RtnValue (Value)
Select Value = ltrim(rtrim(@List))
Return
END'
	EXEC(@Sql)

 	set @Sql='create procedure ccsp_GenKPIOutbound
@tipoGroup char(1),
@sCam_Id varchar(255), 
@fechaIni datetime, 
@fechaFin datetime
as
set nocount on
Declare @langU tinyint
select @langU = valor from ccSettings where setting_id = 23

CREATE TABLE #ccoCallsOut_Rep(
	cal_id int, cam_id smallint,
	statusCall_id tinyint, cal_tDialog smallint,
	tConnTime datetime, tBridgeTime datetime, cal_Inicio datetime,
 CONSTRAINT PK_ccoCallsOut_Temp PRIMARY KEY CLUSTERED (cal_id ASC))

insert into #ccoCallsOut_Rep
select cal_id, cam_id, statusCall_id, cal_tDialog, tConnTime, tBridgeTime, 
case @tipoGroup when ''H'' then convert(varchar(13), cal_Inicio, 121)+'':00''
when ''P'' then convert(varchar(6), cal_Inicio, 112)+''01 00:00''
else convert(varchar(8), cal_Inicio, 112)+'' 00:00'' end
from ccocallsout with(index(IX_ccoCallsOut_3))
where cal_Inicio between @fechaIni and @fechaFin and cam_id in (select value from dbo.fn_RIASplitDelimited(@sCam_Id, '',''))

declare @GenKPIOutbound as Table (a smalldatetime, b varchar(40), c int, d int, e int, f decimal(18,2), g int, h int, i int, j int, k int)

insert into @GenKPIOutbound select convert(varchar(16), Scnd.cal_Inicio, 121) cal_Inicio, Camp.cam_descripcion, Scnd.marcados, Scnd.Contactadas, 
Scnd.Abandonadas, Scnd.tAvgTrans, Scnd.ten, Scnd.twe, Scnd.tir,	isnull(Trd.avg_fCalc, 0) avg_fCalc, isnull(Dialog.avg_tDialog, 0) avg_tDialog from 
	(select cam_id, cal_Inicio, COUNT(marcados) marcados, SUM(Contactadas)*100/COUNT(marcados) Contactadas, SUM(Abandonadas)*100/COUNT(marcados) Abandonadas, 
	cast(CAST(SUM(tAvgTrans)/COUNT(marcados) as decimal(18,2)) as varchar(5)) tAvgTrans, SUM(ten) ten, SUM(twe) twe, SUM(tir) tir from 
		(select cal_Inicio, cam_id, cal_id Marcados, case statusCall_id when 13 then 1 else 0 end Contactadas,
		case statusCall_id when 6 then 1 else 0 end Abandonadas, isnull(cast(datediff(ms, 
		tConnTime, tBridgeTime) as decimal(18,3))/1000, ''0'') tAvgTrans,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<10 then 1 else 0 end ten,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<20 then 1 else 0 end twe,
		case when statusCall_id in (11,13,15,16,17) and cal_tDialog<30 then 1 else 0 end tir
		from #ccoCallsOut_Rep
		) as Frst group by cam_id, cal_Inicio
	) as Scnd
join ccCamps Camp on Scnd.cam_id = Camp.cam_id
left join 
	(select Cam_id, cast((AVG(fecha_Calc_ms))/1000.0 as decimal(10,0)) avg_fCalc 
	from ccLogAgentesDia_Dialog where fecha_Dialog between @fechaIni and @fechaFin 
		and Cam_id in (select value from dbo.fn_RIASplitDelimited(@sCam_Id, '','')) group by Cam_id
	) as Trd
on Scnd.cam_id=Trd.Cam_id
left join
	(select Dl.Cam_id, cast(AVG(Dl.tStatus_Dialog) as decimal(10,0)) avg_tDialog
	from ccLogAgentesDia Lg left join ccLogAgentesDia_Dialog Dl on 
	CAST(Lg.user_id as varchar(10))+''|''+CONVERT(varchar(25), Lg.fecha, 121) = 
	CAST(Dl.user_id as varchar(10))+''|''+CONVERT(varchar(25), Dl.fecha_Dialog, 121)
	where Lg.fecha between @fechaIni and @fechaFin and Dl.Cam_id in (select value from dbo.fn_RIASplitDelimited(@sCam_Id, '',''))
	group by Dl.cam_id
	) as Dialog
on Trd.cam_id=Dialog.Cam_id
order by Scnd.cal_inicio, Camp.cam_descripcion
drop table #ccoCallsOut_Rep

if @langU=0
 begin
 	select a Fecha, b [Campaña], c Marcados, d [Contactadas (%)], e [Abandonadas (%)], f [Tiempo Promedio Transferida (seg)], 
	g [Llamadas Cortadas (10s)], h [Llamadas Cortadas (20s)], i [Llamadas Cortadas (30s)], 
	j [Tiempo Promedio entre Llamadas (seg)], k [Tiempo Promedio en Dialogo (seg)] from @GenKPIOutbound	
 end

else
 begin
 	select a [Date], b Campaign, c Dialed, d [Contacted (%)], e [Abandoned (%)], f [Average time During Transference (seg)], 
	g [Finished Calls (10s)], h [Finished Calls (20s)], i [Finished Calls (30s)], 
	j [Average time Between Calls (seg)], k [Average time While Talking (seg)] from @GenKPIOutbound
 end	

return(0)
set nocount off
'
	EXEC(@Sql)

 	set @Sql='create procedure ccsp_GenKPIAgentes
@tipoGroup char(1),
@sUser_Id varchar(max), 
@fechaIni datetime, 
@fechaFin datetime
as
set nocount on
Declare @langU tinyint
select @langU = valor from ccSettings where setting_id = 23

create table #ccCalls_Temp (cal_id int, User_id smallint, statusCall_id tinyint, 
cal_tDialog smallint, cal_Inicio datetime, cal_whoHung smallint, tipoTabla tinyint)

CREATE NONCLUSTERED INDEX IX_ccCalls_Temp ON #ccCalls_Temp (cal_id ASC)

insert into #ccCalls_Temp select cal_id, User_id, statusCall_id, cal_tDialog, 
case @tipoGroup when ''H'' then convert(varchar(13), cal_Inicio, 121)+'':00''
when ''P'' then convert(varchar(6), cal_Inicio, 112)+''01 00:00''
else convert(varchar(8), cal_Inicio, 112)+'' 00:00'' end,
cal_whoHung, 0 from ccoCallsOut
where cal_inicio between @fechaIni and @fechaFin and User_id in (select value from dbo.fn_RIASplitDelimited(@sUser_Id, '',''))
	
insert into #ccCalls_Temp select cal_id, User_id, statusCall_id, cal_tDialog, 
case @tipoGroup when ''H'' then convert(varchar(13), cal_Inicio, 121)+'':00''
when ''P'' then convert(varchar(6), cal_Inicio, 112)+''01 00:00''
else convert(varchar(8), cal_Inicio, 112)+'' 00:00'' end,
cal_whoHung, 1 from ccCallsIn
where cal_inicio between @fechaIni and @fechaFin and User_id in (select value from dbo.fn_RIASplitDelimited(@sUser_Id, '',''))

declare @GenKPIAgentes as Table (a smalldatetime, b varchar(20), c varchar(115), d int, e int, f int, g int, h int, i int, j int, k int)

insert into @GenKPIAgentes
select convert(varchar(16), Snd.cal_Inicio, 121) cal_Inicio, Fst.Login, 
Nombres + isnull('' ''+ApellidoPaterno, '''') + isnull('' ''+ApellidoMaterno, '''') Nombre, 
Total, Cin, Cout, C10, C20, C30, cal_whoHung, isnull(avg_fCalc, 0) avg_fCalc
from 
(
	select User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno 
	from ccUsers where User_id in (select value from dbo.fn_RIASplitDelimited(@sUser_Id, '',''))
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
	select User_id, cast((AVG(fecha_Calc_ms))/1000.0 as decimal(10,0)) avg_fCalc 
	from ccLogAgentesDia_Dialog where fecha_Dialog between @fechaIni and @fechaFin 
	and User_id in (select value from dbo.fn_RIASplitDelimited(@sUser_id, '','')) group by User_id
) as Trd
on Snd.User_id = Trd.User_id
drop table #ccCalls_Temp

if @langU=0
 begin
	select a Fecha, b Usuario, c Nombre, d [Total Llamadas], e [Llamadas Entrada], f [Llamadas Salida],
	g [Llamadas Cortadas (10s)], h [Llamadas Cortadas (20s)], i [Llamadas Cortadas (30s)],
	j [Colgadas por el Agente], k [Tiempo Promedio entre Llamadas (seg)]
	from @GenKPIAgentes
 end

else
 begin
	select a [Date], b [User], c Name, d [Total Calls], e [Calls (Inbound)], f [Calls (Outbound)],
	g [Finished Calls (10s)], h [Finished Calls (20s)], i [Finished Calls (30s)],
	j [Finished by Agents], k [Average time between calls (seg)]
	from @GenKPIAgentes
 end

return(0)
set nocount off'
	EXEC(@Sql)

 	set @Sql=''
	EXEC(@Sql)

 	set @Sql=''
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


