CREATE PROCEDURE [dbo].[ccsp_RIACatRatesCarriers]
@type tinyint,
@tipoLlamada_id smallint = 0,
@estado varchar(max) = '',
@lada varchar(max) = ''
AS

set nocount on

--- Obtiene Tarifas 
if @type = 1 begin	
	select tipoLlamada_id, descrip from cstoTipoLlamada where country_id = 1 and tipoLlamada_id in(8,9,10,11)
end
-- Obtine la lista de ladas y los estados
if @type = 2 begin
	select distinct(series.estado) as estado, series.cld as lada 
	from series 
	left join ccRateByCarrier rate on series.cld=rate.lada
	where rate.lada is null

end
--Regresa la relacion de tipos de llamadas y las ladas
if @type = 3 begin
	select estado,lada from ccRateByCarrier where tipoLlamada_id = @tipoLlamada_id
end
--Inserta la relacion tarifas y ladas y estados
if @type = 4 begin
	delete ccRateByCarrier where [tipoLlamada_id] = @tipoLlamada_id

	insert into ccRateByCarrier
			select @tipoLlamada_id,estado.value,lada.value
				from fn_RIASplitDelimited (@estado, '|')  as estado
				inner join fn_RIASplitDelimited (@lada, '|')  as lada
				on estado.id = lada.id
end
-- Borra la relacion estados y lada con el tipo de llamada
if @type = 5 begin	
	delete ccRateByCarrier
		from ccRateByCarrier as rate
		inner join fn_RIASplitDelimited (@estado, '|')  as tEstado on tEstado.value =  rate.estado
		inner join fn_RIASplitDelimited (@lada, '|')  as tLada on tLada.value =  rate.lada
		where [tipoLlamada_id] = @tipoLlamada_id
	 
end