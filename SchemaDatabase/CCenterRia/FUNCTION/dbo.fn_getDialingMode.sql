CREATE function [dbo].[fn_getDialingMode](@call_id int, @TipoDialingMode tinyint, @logDial_id int, @cam_id int)
returns nvarchar(8)
as
begin
	declare @valor nvarchar(8), @calif_id smallint, @califSub_id smallint, @cal_manual tinyint, @keepDial char(1)
	set @keepDial='0'

	-- En el caso de que no cuente con cal_id, se debe contar con logDial_id, por lo cual se busca el registro
	if @call_id is null
	 begin
		select top 1 @call_id=o.cal_id from ccoLogDials l with(nolock,index(PK_ccoLogDials)) join ccocallsout o with(nolock,index(IX_ccoCallsOut_2))
			on l.callout_id = o.callout_id and l.Puerto = o.cal_puerto
		where l.logDial_id = @logDial_id and l.fecha between convert(varchar(19), dateadd(minute, -5, o.cal_inicio), 121)
		and convert(varchar(19), dateadd(minute, 5, o.cal_inicio), 121)
		order by datediff(ss, l.fecha, o.cal_inicio) asc -- en caso de tener mas de uno, toma el que tenga menor diferencia en tiempo
	 end

	if @cam_id is null
	 begin
		select @calif_id=calif_id, @califSub_id=califSub_id, @cal_manual=cal_manual, @cam_id=cam_id
		from ccocallsout O with(nolock,index(PK_ccoCallsOut))
		where O.cal_id = @call_id
	 end
	else
	 begin
		select @calif_id=calif_id, @califSub_id=califSub_id, @cal_manual=cal_manual
		from ccocallsout O with(nolock,index(PK_ccoCallsOut))
		where O.cal_id = @call_id
	 end

	select @valor=isnull((select case when progDial=2 then '10' when progDial=1 then '01' else '00' end + cast(iTipoDial as char(1)) + cast(abandonCallback as char(1))
	 + cast(excCallback as char(1)) from cccamps where cam_id=@cam_id), '00000')

	if ((select keepDial from ccTipoCalifOUT where calif_id = @calif_id)=1
	or (select keepDial from ccTipoCalifSubOUT where califSub_id = @califSub_id)=1)
		set @keepDial='1'

	select @valor = @valor + @keepDial + case @cal_manual when 1 then '10' when 2 then '01' else '00' end

	 select @valor=substring(@valor, 1, 2) +
	  case @TipoDialingMode when 6 then '1' else substring(@valor, 3, 1) end + substring(@valor, 4, 2) +
	  case @TipoDialingMode when 3 then '1' else substring(@valor, 6, 1) end + substring(@valor, 7, 2)

 return @valor
end