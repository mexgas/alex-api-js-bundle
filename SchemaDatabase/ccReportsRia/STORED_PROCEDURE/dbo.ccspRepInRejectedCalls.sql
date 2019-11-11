CREATE PROCEDURE [dbo].[ccspRepInRejectedCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepInRejectedCalls with(rowlock)
	where date >= @from AND date < @to
	
	insert into RepInRejectedCalls
		select 			
		D.dni_id,		
		reject.dnis,
		D.dni_Descripcion,
		reject.InBound_id,
		inBound.descripcion,
		reject.cal_inicio,
		reject.ani,
		reject.puerto,
		datepart(yyyy,reject.cal_inicio), datepart(mm,reject.cal_inicio), datepart(dd,reject.cal_inicio), 
		datepart(hh,reject.cal_inicio), datepart(mi,reject.cal_inicio) 		
	from ccCallsReject reject
	INNER JOIN ccDNIS D ON D.dni_numero = reject.dnis and D.dni_Status=1
	INNER JOIN ccInbound inBound ON reject.Inbound_id = inBound.Inbound_id
	where cal_inicio >= @from AND cal_inicio < @to

end