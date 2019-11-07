CREATE proc [dbo].[ccspOutDialerCsto]
as
set nocount on
declare @modePlian int 
declare @sql as varchar(max), @insert as varchar(max), @sql2 as varchar(max), @query as varchar(max), @country tinyint
set @modePlian=0
declare @RtnValue table (prov_Id int identity(1,1), costoloc decimal(15,3), costoLD decimal(15,3), costoCel decimal(15,3), costoCelLD decimal(15,3), costo01800 decimal(15,3), costoLDUsa decimal(15,3), costoLDInter decimal(15,3))
select @country = valor from ccsettings where setting_id = 104
set @query = 'declare @RtnValue table (provedor_id int '
set @sql = 'select provedor_id '
set @insert = ''
if @country>1 begin
  select @sql = @sql + ', sum(case when tipollamada_id = ' + convert(varchar(3),tipollamada_id) + ' then isnull(minutoUno,100) else 0 end) ['+ descrip +']', @insert = @insert + ', ['+ descrip +']', @query = @query + ', [' + descrip +'] decimal(15,3) ' 
  from cstotipollamada where country_id = @country
end
else begin
  select @sql = @sql + ', sum(case when tipollamada_id = ' + convert(varchar(3),tipollamada_id) + ' then isnull(minutoUno,100) else 0 end) ['+ descrip +']', @insert = @insert + ', ['+ descrip +']', @query = @query + ', [' + descrip +'] decimal(15,3) ' 
  from cstotipollamada 
  where country_id=@country and ( tipoLlamada_id not in(1,12)  or  (@modePlian=0 and tipoLlamada_id=1) or (@modePlian<>0 and tipoLlamada_id=12) ) 

end
set @sql = ' Insert Into @RtnValue (provedor_id' + @insert + ') ' + @sql + ' from cstotarifa group by provedor_id '
set @query = @query + ')'
set @sql2 = ' select dialer_id, Puerto, Extension, Status, Descripcion, d.provedor_id' + @insert + ' FROM ccoDialers d Left Join @RtnValue c on d.provedor_id = c.provedor_id ORDER BY Puerto'
--print (@query + @sql + @sql2)
exec (@query + @sql + @sql2)