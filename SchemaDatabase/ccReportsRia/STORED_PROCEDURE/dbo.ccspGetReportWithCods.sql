CREATE PROCEDURE [dbo].[ccspGetReportWithCods]
AS
declare @fechaInicio datetime,@fechaFin datetime
select  @fechaFin=convert(varchar(10),getdate(),121)+' 22:00:00'

select  @fechaInicio= convert(varchar(10),getdate(),121)+' 06:00:00'
print(@fechaInicio)
print(@fechaFin)

declare @fileName varchar(200)
select @fileName='gets_'+replace(convert(varchar, getdate(),3),'/','')
--select @fileName,@fechaInicio,@fechaFin 


/***RUTA DONDE SE GUARDARA EL REPORTE***/
declare @pathFile varchar(100)
set @pathFile='C:\ReporteEspecial'

select 
NULLIF(cals.cal_Key,'') [PLAN_PAGOS],
NULLIF(convert(varchar, cals.fecha, 112),'') [Fecha_Gestion],
NULLIF(replace(convert(varchar,cals.fecha,8),':',''),'') [Hora_Gestion], 
NULLIF(COALESCE(tipo_cod.cod,cali_cod.cod),'') [COD],
NULLIF(calssource.Dato3,'') [Fecha_Promesa], 
NULLIF(calssource.Dato4,'') [Monto_Promesa],
NULLIF(calssource.Dato5,'') [Comentario], 
NULLIF(COALESCE(tipo_cod.cod_description,cali_cod.cod_description,calif_out.califSubDesc),'') [Cod_descripcion]

into SLR_out
from ccoLogDials cals with(nolock) 
left join ccoCallsOut calsout on calsout.cal_id=cals.cal_id 
left join ccoCallsOutSource calssource on calssource.callout_id=calsout.callout_id 
left join ccCodsSLR tipo_cod on tipo_cod.tipoResDial_id=cals.tipoResDial_id
left join ccCodsSLR cali_cod on cali_cod.califSub_id=calsout.califSub_id
left join cctipocalifsubout calif_out on calif_out.califSub_id=calsout.califSub_id 
where cals.fecha>=@fechaInicio and cals.fecha<=@fechaFin 
order by cals.fecha


declare 
	@db_name	varchar(100),
	@table_name	varchar(100),	
	@file_name	varchar(100)


select @db_name='CCReportsRIA', @table_name='SLR_out',@file_name=@pathFile+'\'+@fileName+'.txt'

declare @columns varchar(8000), @sql varchar(8000), @data_file varchar(100)
select 
	@columns=coalesce(@columns+',','')+column_name+' as '+column_name 
from 
	information_schema.columns
where 
	table_name=@table_name
order by ORDINAL_POSITION



select @columns=''''''+replace(replace(@columns,' as ',''''' as '),',',',''''')

select @data_file=substring(@file_name,1,len(@file_name)-charindex('\',reverse(@file_name)))+'\data_file.txt'
set @sql='exec master..xp_cmdshell ''bcp " select * from (select '+@columns+') as t" queryout "'+@file_name+'" -c -t "|" -T -U sa -P nuxiba'''
print @sql
exec(@sql)
set @sql='exec master..xp_cmdshell ''bcp "select * from '+@db_name+'..'+@table_name+'" queryout "'+@data_file+'" -c -t "|" -T -U sa -P nuxiba '''
print @sql
exec(@sql)
set @sql= 'exec master..xp_cmdshell ''type '+@data_file+' >> "'+@file_name+'"'''
exec(@sql)
set @sql= 'exec master..xp_cmdshell ''del '+@data_file+''''
exec(@sql)

drop table SLR_out