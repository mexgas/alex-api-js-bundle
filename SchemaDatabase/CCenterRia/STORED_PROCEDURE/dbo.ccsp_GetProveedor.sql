CREATE procedure [dbo].[ccsp_GetProveedor]
@tel as varchar(32),
@cam_id as varchar(5)
as
declare @sql varchar(4000), @country varchar(2), @tabla varchar(100)
select @country = valor from ccSettings where setting_id = 104

select @tabla = 'cstoTipoLlamada'

set @sql = 'declare @bestprov as varchar(10), @typeCall as varchar(2), @Cost as varchar(10)
set @bestprov = ''''
select top 1 @typeCall = tipollamada_id from ' + @tabla + ' where country_id = ' + convert(varchar(3),@country) + ' and len(''' + @tel + ''') = longitud and ''' + @tel + ''' like prefijo order by len(prefijo) desc

select top 1 @Cost = minutouno, @typeCall = tipoLlamada_id from cstotarifa where tipoLlamada_id = @typeCall
and provedor_id in (select distinct provedor_id from ccodialers where dialer_id in (select dialer_id from ccodialercamp where cam_id = '+@cam_id+'))
order by minutoUno, minutoAdicional

select top 3 @bestprov = @bestprov + case when @bestprov = '''' then '''' else ''&'' end + convert(varchar(2),provedor_id), @typeCall = tipoLlamada_id  from cstotarifa 
where tipoLlamada_id = @typeCall and minutouno = @Cost and provedor_id in (select distinct provedor_id from ccodialers where dialer_id in (select dialer_id from ccodialercamp where cam_id = '+@cam_id+'))

if @bestProv is null or @bestProv = ''''
begin
	select top 1 @bestProv = provedor_id, @typeCall = tipoLlamada_id from cstotarifa where provedor_id in (select distinct provedor_id from ccodialers where dialer_id in (select dialer_id from ccodialercamp where cam_id = '+@cam_id+')) order by minutoUno desc, minutoAdicional desc
end

select @bestprov + ''|'' + @typeCall'

--print @sql
exec (@sql)