/*
Autor: Raymundo Gonzalez
Fecha: 2013/03/31
Descripcion: 
	Se agregan las columnas IdCampEsp y Tipo en las tablas ccLogAgentesDia y ccLogAgentesNotReady para guardar tiempos de reporte de tiempos especiales (Boan)
	Se actualiza la tabla exportReports para paso de información de tiempos especiales (reporte Boan)
	Se crea el SP cc_InboundMetricsB para reporte de tiempos especiales (Boan)
	
Version requerida: 42
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '43'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @process = 'ccLogAgentesDia - Alter Table(1)'
		set @Sql='alter table ccLogAgentesDia
add IdCampEsp smallint null'
					
	EXEC(@Sql)
	
		set @process = 'ccLogAgentesDia - Alter Table(2)'
		set @Sql='alter table ccLogAgentesDia
add Tipo smallint null'
					
	EXEC(@Sql)
	
		set @process = 'ccLogAgentesNotReady - Alter Table(1)'
		set @Sql='alter table ccLogAgentesNotReady
add IdCampEsp smallint null'
						
	EXEC(@Sql)
	
		set @process = 'ccLogAgentesNotReady - Alter Table(2)'
		set @Sql='alter table ccLogAgentesNotReady
add Tipo smallint null'
						
	EXEC(@Sql)
	
		set @process = 'exportReports - Update'
		set @Sql='update exportReports
set cols = cols + '', IdCampEsp, Tipo''
where jobId in (8,9)'

	EXEC(@Sql)

		set @process = 'cc_InboundMetricsB - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[cc_InboundMetricsB]
@from as datetime,
@to as datetime,
@acds as varchar(2000)='''',
@camps as varchar(2000)=''''
as

declare @campsT as table(cam_id int)
declare @acdsT as table(inbound_id int)

if @camps = ''''
	begin
		insert into @campsT
			select cam_id from cccamps
	end
else
	begin
		insert into @campsT
			select value from dbo.fn_RIASplitDelimited(@camps,'','')	
	end

if @acds = ''''
	begin
		insert into @acdsT
			select inbound_id from ccinbound
	end
else
	begin
		insert into @acdsT
			select value from dbo.fn_RIASplitDelimited(@acds,'','')	
	end

select [Espec/Camp], Periodo, 
isnull([Tiempo Disponible],0) + isnull([Tiempo Dialogo],0) + isnull([Tiempo No Disponible],0) + isnull([Otro],0) as [Tiempo Sesion],
isnull([Tiempo Disponible],0) as [Tiempo Disponible], 
isnull([Tiempo Dialogo],0) as [Tiempo Dialogo], 
isnull([Tiempo No Disponible],0) as [Tiempo No Disponible], 
isnull([Otro],0) as [Otro]
into #Report1
from(
	select ''Camp - '' + b.cam_descripcion as [Espec/Camp], 
		case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) 
			 else convert(varchar(13), fecha,121) + '':30:00'' end as Periodo,
		case when tipostatusage_id = 3 then ''Tiempo Disponible'' when tipostatusage_id = 4 then ''Tiempo Dialogo'' 
			when tipostatusage_id = 2 then ''Tiempo No Disponible'' else ''Otro'' end as tDescripcion,
		sum(tstatus) as tstatus
	from ccLogAgentesDia a
	left outer join cccamps b on (cam_id = idcampesp and tipo = 1)
	where (idCampEsp is not null)
	and (tipo is not null)
	and tipo = 1
	and fecha between @from and @to
	and cam_id in (select * from @campsT)
	group by cam_descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) else convert(varchar(13), fecha,121) + '':30:00'' end,
		case when tipostatusage_id = 3 then ''Tiempo Disponible'' when tipostatusage_id = 4 then ''Tiempo Dialogo'' when tipostatusage_id = 2 then ''Tiempo No Disponible'' else ''Otro'' end 
	union
	select ''Esp - '' + b.descripcion as [Espec/Ca.
	mp], 
		case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) 
			else convert(varchar(13), fecha,121) + '':30:00'' end as Periodo, 
		case when tipostatusage_id = 3 then ''Tiempo Disponible'' when tipostatusage_id = 4 then ''Tiempo Dialogo'' 
			when tipostatusage_id = 2 then ''Tiempo No Disponible'' else ''Otro'' end as tDescripcion,
		sum(tstatus) as tstatus
	from ccLogAgentesDia a
	left outer join ccinbound b on (inbound_id = idcampesp and tipo = 0)
	where (idCampEsp is not null)
	and (tipo is not null)
	and tipo = 0
	and fecha between @from and @to
	and inbound_id in (select * from @acdsT)
	group by descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) else convert(varchar(13), fecha,121) + '':30:00'' end,
		case when tipostatusage_id = 3 then ''Tiempo Disponible'' when tipostatusage_id = 4 then ''Tiempo Dialogo'' when tipostatusage_id = 2 then ''Tiempo No Disponible'' else ''Otro'' end 
) times
pivot (max(tstatus) for [tdescripcion] in ([Tiempo Disponible], [Tiempo Dialogo], [Tiempo No Disponible], [Otro])) as pvtTimes
order by [Espec/Camp], Periodo

select * into #notready from(
select ''Camp - '' + cam_descripcion as [Espec/Camp],  
	case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) 
			else convert(varchar(13), fecha,121) + '':30:00'' end as Periodo,
	c.descripcion + ''T'' as [descriptionT], sum(tstatus) as T, c.descripcion + ''N'' as [descriptionN], count(*) as N
from ccLogAgentesNotReady a
left outer join cccamps b on (idcampesp = cam_id and tipo = 1)
left outer join ccTipoNotReady c on (a.tiponotready_id = c.tiponotready_id)
where (idCampEsp is not null)
and (tipo is not null)
and tipo = 1
and fecha between @from and @to
and cam_id in (select * from @campsT)
group by cam_descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) else convert(varchar(13), fecha,121) + '':30:00'' end, c.descripcion
union
select ''Esp - '' + b.descripcion as [Espec/Camp], 
	case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) 
			else convert(varchar(13), fecha,121) + '':30:00'' end as Periodo,
	c.descripcion + ''T'' as [descriptionT], sum(tstatus) as T, c.descripcion + ''N'' as [descriptionN], count(*) as N
from ccLogAgentesNotReady a
left outer join ccinbound b on (idcampesp = inbound_id and tipo = 0)
left outer join ccTipoNotReady c on (a.tiponotready_id = c.tiponotready_id)
where (idCampEsp is not null)
and (tipo is not null)
and tipo = 0
and fecha between @from and @to
and inbound_id in (select * from @acdsT)
group by b.descripcion, case when datepart(mi,fecha)>30 then dateadd(mi,30,convert(datetime,convert(varchar(13), fecha,121) + '':30:00'',121)) else convert(varchar(13), fecha,121) + '':30:00'' end, c.descripcion
) as tmp

declare @pivot1_descriptionT nvarchar(max) 
declare @pivot2_descriptionT nvarchar(max) 
declare @pivot3_descriptionT nvarchar(max) 
declare @pivot4_descriptionT nvarchar(max)



select @pivot1_descriptionT = coalesce(@pivot1_descriptionT + '','','''','''''''') + QuoteName(descriptionT) from 
(select distinct descriptionT from #notReady) T1_descriptionT 
select @pivot2_descriptionT = coalesce(@pivot2_descriptionT + '','','''', '''''''') + ''isnull(MAX('' + QuoteName(descriptionT) + ''),0) AS '' + QuoteName(descriptionT) 
from (select distinct descriptionT from #notReady) T2_descriptionT
select @pivot3_descriptionT = coalesce(@pivot3_descriptionT + '','','''','''''''') + ''isnull('' + QuoteName(descriptionT) + '',0) AS '' + QuoteName(descriptionT) from 
(select distinct descriptionT from #notReady) T3_descriptionT 
select @pivot4_descriptionT = coalesce(@pivot4_descriptionT + '','','''','''''''') 
+ QuoteName(descriptionT) 
+ '' = right(''''0'''' + rtrim(convert(char(2), '' + QuoteName(descriptionT) + '' / (60 * 60))), 2) + '''':'''' + 
right(''''0'''' + rtrim(convert(char(2), ('' + QuoteName(descriptionT) + '' / 60) % 60)), 2) + '''':'''' + 
right(''''0'''' + rtrim(convert(char(2), '' + QuoteName(descriptionT) + '' % 60)),2)'' from
(select distinct descriptionT from #notReady) T1_descriptionT 


declare @pivot1_descriptionN nvarchar(max) 
declare @pivot2_descriptionN nvarchar(max) 
declare @pivot3_descriptionN nvarchar(max) 

select @pivot1_descriptionN = coalesce(@pivot1_descriptionN + '','','''','''''''') + QuoteName(descriptionN) from 
(select distinct descriptionN from #notReady) T1_descriptionN 
select @pivot2_descriptionN = coalesce(@pivot2_descriptionN + '','','''', '''''''') + ''isnull(MAX('' + QuoteName(descriptionN) + ''),0) AS '' + QuoteName(descriptionN) 
from (select distinct descriptionN from #notReady) T2_descriptionN
select @pivot3_descriptionN = coalesce(@pivot3_descriptionN + '','','''','''''''') + ''isnull('' + QuoteName(descriptionN) + '',0) AS '' + QuoteName(descriptionN) from 
(select distinct descriptionN from #notReady) T3_descriptionN 


declare @query nvarchar(max)

set @query = ''
select [Espec/Camp], [Periodo],'' + @pivot2_descriptionT + '', '' + @pivot2_descriptionN + ''
into #Report2
from (select [Espec/Camp], [Periodo], [descriptionT], convert(varchar(max),[T]) as [T], [descriptionN], [N] from #notReady) as P
pivot (max(T) for descriptionT in ('' + @pivot1_descriptionT + '')) as PV_descriptionT
pivot (max(N) for descriptionN in ('' + @pivot1_descriptionN + '')) as PV_descriptionN
group by [Espec/Camp], [Periodo]

update #Report2 set '' + @pivot4_descriptionT + ''

select a.[Espec/Camp], a.Periodo, 
right(''''0'''' + rtrim(convert(char(2), [Tiempo Sesion] / (60 * 60))), 2) + '''':'''' + 
right(''''0'''' + rtrim(convert(char(2), ([Tiempo Sesion] / 60) % 60)), 2) + '''':'''' + 
right(''''0'''' + rtrim(convert(char(2), [Tiempo Sesion] % 60)),2) as [Tiempo Sesion], 

right(''''0'''' + rtrim(convert(char(2), [Tiempo Disponible] / (60 * 60))), 2) + '''':'''' + 
right(''''0'''' + rtrim(convert(char(2), ([Tiempo Disponible] / 60) % 60)), 2) + '''':'''' + 
right(''''0'''' + rtrim(convert(char(2), [Tiempo Disponible] % 60)),2) as [Tiempo Disponible], 

right(''''0'''' + rtrim(convert(char(2), [Tiempo Dialogo] / (60 * 60))), 2) + '''':'''' + 
right(''''0'''' + rtrim(convert(char(2), ([Tiempo Dialogo] / 60) % 60)), 2) + '''':'''' + 
right(''''0'''' + rtrim(convert(char(2), [Tiempo Dialogo] % 60)),2) as [Tiempo Dialogo], 

right(''''0'''' + rtrim(convert(char(2), [Tiempo No Disponible] / (60 * 60))), 2) + '''':'''' + 
right(''''0'''' + rtrim(convert(char(2), ([Tiempo No Disponible] / 60) % 60)), 2) + '''':'''' + 
right(''''0'''' + rtrim(convert(char(2), [Tiempo No Disponible] % 60)),2) as [Tiempo No Disponible], 

right(''''0'''' + rtrim(convert(char(2), [Otro] / (60 * 60))), 2) + '''':'''' + 
right(''''0'''' + rtrim(convert(char(2), ([Otro] / 60) % 60)), 2) + '''':'''' + 
right(''''0'''' + rtrim(convert(char(2), [Otro] % 60)),2) as [Otro], '' 
+ @pivot3_descriptionT + '', '' + @pivot3_descriptionN + ''
into #temp
from #Report1 a 
full outer join #Report2 b on (a.[Espec/Camp] = b.[Espec/Camp] and a.Periodo = b.periodo)
where a.[Espec/Camp] is not null



if (select valor from ccsettings where setting_id = 23) = ''''1''''
	begin
		update #temp set [Espec/Camp] = replace ([Espec/Camp], ''''Esp'''',''''ACD'''')
		exec tempdb..sp_rename ''''#temp.[Espec/Camp]'''', ''''ACD/Camp'''', ''''COLUMN''''
		exec tempdb..sp_rename ''''#temp.[Periodo]'''', ''''Period'''', ''''COLUMN''''
		exec tempdb..sp_rename ''''#temp.[Tiempo Sesion]'''', ''''Session Time'''', ''''COLUMN''''
		exec tempdb..sp_rename ''''#temp.[Tiempo Disponible]'''', ''''Available Time'''', ''''COLUMN''''
		exec tempdb..sp_rename ''''#temp.[Tiempo Dialogo]'''', ''''Dialog'''', ''''COLUMN''''
		exec tempdb..sp_rename ''''#temp.[Tiempo No Disponible]'''', ''''Unavailable Time'''', ''''COLUMN''''
		exec tempdb..sp_rename ''''#temp.[Otro]'''', ''''Other'''', ''''COLUMN''''
	end

select * from #temp



drop table #Report1
drop table #Report2
drop table #notReady


''

exec(@query)'

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
