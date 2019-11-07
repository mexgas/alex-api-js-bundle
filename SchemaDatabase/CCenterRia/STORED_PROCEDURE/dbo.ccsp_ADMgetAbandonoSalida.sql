CREATE procedure ccsp_ADMgetAbandonoSalida as 

declare @inicioTurno integer

declare @fecha smalldatetime
declare @fStart datetime
declare @fEnd datetime
declare @ultimo smalldatetime

select @ultimo = valor from ccSettings where setting_id = 25
if datediff(mi, @ultimo, getdate()) > 5 begin
	update ccsettings set valor = convert(varchar(19), getdate(), 121) where setting_id = 25
	set @inicioTurno = 2 --Cambio de dia a las 2 de la mañana
	set @fecha = getdate()
	if datepart( hh,  @fecha ) > @inicioTurno - 1
	begin	
		set @fStart = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +':00', 121)
		set  @fEnd = dateadd( d,1, @fstart )
	end
	else
	begin
		set @fEnd = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +':00', 121)
		set  @fStart = dateadd( d,-1, @fEnd )
	end
	
	insert ccAbandonoSalida
	select cam_id, 0
	from ccCamps where cam_id not in (select cam_id from ccAbandonoSalida)

	delete ccAbandonoSalida where cam_id not in ( select cam_id from ccCamps)
	
	update ccAbandonoSalida set AbndPctg = a.AbndPctg from
	(select cam_id, round( count( case statuscall_id when 6 then 1 else null end ) *100.0 / count(*) , 2 ) as AbndPctg 
	from ccoCallsOut with( index( IX_ccoCallsOut_2) )
	where cal_inicio > @fStart 
	--where cal_inicio > convert(varchar(11), getdate(), 101)
	and cal_manual in (0,2 )
	group by cam_id
	) a inner join ccAbandonoSalida ab on a.cam_id = ab.cam_id
end

select cam_id, AbndPctg from ccAbandonoSalida