/*
Autor: Raymundo Gonzalez
Fecha: 2014/07/09
Descripcion:
	Se inserta registro en la tabla exportReports para paso de informacion de puertos de marcacion
	Se modifica el SP ccsp_GenKPIAgentes para fix en reporte de KPI de Agentes
	
Version requerida: 50
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '51'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @process = 'exportReports - Insert'
		set @Sql='insert into [exportReports]  (jobId,jobType,intervalMinutes,tableN,idN,dateN,cols,skipMinutes)
values(130,3,60,''ccspGenOutPortStats'',4,1,'''',0)'
		
	EXEC(@Sql)

		set @process = 'ccsp_GenKPIAgentes - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_GenKPIAgentes]
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
Total, Cin, Cout, C10, C20, C30, cal_whoHung, convert(decimal(20,0),isnull(avg_fCalc, 0.00)) avg_fCalc
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
	select User_id, AVG(convert(decimal(20,2),fecha_Calc_ms))/1000.00 avg_fCalc 
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
