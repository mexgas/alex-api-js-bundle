CREATE PROCEDURE [dbo].[ccsp_RIACATRates]
@carrier_id smallint,
@CallType_id varchar(2),
@firstMinute varchar(20) = null,
@extraMinute varchar(20) = null,
@Type tinyint 
AS

DECLARE @sql nvarchar(1000),@country as tinyInt
select @country = valor from ccSettings where setting_id = 104

	if( @Type=1)
		begin
			--select cstoProvedor.provedor_id, cstoProvedor.descrip, cstoTarifa.tipollamada_id, cstoTipoLlamada.descrip, cstoTarifa.minutoUno, cstoTarifa.minutoAdicional from cstoTarifa, cstoProvedor, cstoTipoLlamada where cstoProvedor.provedor_id = cstoTarifa.provedor_id And cstoTarifa.tipollamada_id = cstoTipoLlamada.tipollamada_id order by cstoProvedor.provedor_id asc
			select a.provedor_id, a.descrip,c.tipoLlamada_id,c.descrip, b.minutoUno,b.minutoAdicional from cstoProvedor a 
			left outer join cstoTarifa b on a.provedor_id = b.provedor_id
			left outer join cstoTipoLlamada c on (b.tipoLlamada_id = c.tipoLlamada_id and c.country_id = @country)
		end
	If( @Type=2)
		begin
			insert into cstoTarifa (provedor_id, tipollamada_id, minutoUno, minutoAdicional) values (@carrier_id,@CallType_id,@firstMinute,@extraMinute)
		end
	If( @Type=3)
		begin
			delete cstoTarifa where tipollamada_id = @CallType_id and provedor_id = @carrier_id
			select 3
		end
	if( @Type=4)
		begin
			/*set @sql = 'update cstoTarifa set '
			IF @firstMinute not in('',null)
				BEGIN
					set @sql = @sql + 'minutoUno = ''' +@firstMinute + ''','
				END
			IF @extraMinute not in('',null)
				BEGIN
					set @sql = @sql + 'minutoAdicional = ''' + @extraMinute + ''','
				END
			
			set @sql = left( @sql, len( @sql)-1 )
			set @sql = @sql + ' where tipollamada_id = ' + @CallType_id + ' and provedor_id = ' + @carrier_id
		
			print @sql
			execute sp_executesql @sql
		*/
			update cstoTarifa set
			minutoUno = (case @firstMinute when null then minutoUno else @firstMinute end),  
			minutoAdicional = (case @extraMinute when null then minutoAdicional else @extraMinute end) 
			where tipollamada_id = @CallType_id and provedor_id = @carrier_id
		end
	If( @Type=5)
		begin
			select tipoLlamada_id, descrip from cstoTipoLlamada where country_id = @country --where tipoLlamada_id not in (
			--select tipoLlamada_id from cstoTarifa where provedor_id = @carrier_id)
		end