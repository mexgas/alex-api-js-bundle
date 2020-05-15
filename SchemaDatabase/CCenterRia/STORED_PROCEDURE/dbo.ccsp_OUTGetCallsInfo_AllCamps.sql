CREATE PROCEDURE [dbo].[ccsp_OUTGetCallsInfo_AllCamps]
		@Tipo as tinyint=0,
		@cam_id as smallint = 0,
		@sup_id as smallint=0
		AS

		declare @mToday as smalldatetime

		select @mToday = convert(smalldatetime, convert(varchar(11), getdate() ), 101)
		if @Tipo = 0
		begin
		  SELECT cam_id, cam_descripcion,
		    0 as pContesta,
		    0 as pOcupado,
		    0 as pNoContesta,
		    0 as pFaxModem,
		    0 as pNoService,
		    0 as Marcaciones, 0 as Contestan,  0 as Ocupado, 0 as NoContesta, 0 as FaxModem, 0 as NoService
		  FROM ccCamps
		  order by cam_id
		end

		else if @Tipo = 1
		begin
		  select cam_id, L.Campana,
		    ((L.Contestan*100)/ L.Marcaciones) as pContesta,
		    ((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
		    ((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
		    ((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
		    ((L.NoService*100)/ L.Marcaciones) as pNoService,
		    L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
		    ,L.Otro,L.Cancelado,L.buzon,L.NoDialTone,L.congestion
		  from (
		  select cam_id, '' as Campana,
		    count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
		    count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
		    count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
		    count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
		    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		    count(*) as Marcaciones
		    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Otro
		    ,count(case tipoResDial_id when 13 then 1 else null end) as Cancelado
		    ,count(case tipoResDial_id when 11 then 1 else null end) as buzon
		    ,count(case tipoResDial_id when 5 then 1 else null end) as NoDialTone
		    ,count(case tipoResDial_id when 12 then 1 else null end) as congestion

		  from ccoLogDials with(nolock)
		  Where fecha >  @mToday
		  group by cam_id
		  ) L order by Campana

		end

		else if @Tipo = 2
		begin
		  select cam_id, L.Campana,
		    ((L.Contestan*100)/ L.Marcaciones) as pContesta,
		    ((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
		    ((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
		    ((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
		    ((L.NoService*100)/ L.Marcaciones) as pNoService,
		    L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
		  from (
		  select C.cam_id as cam_id, cam_descripcion as Campana,
		    count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
		    count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
		    count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
		    count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
		    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		    count(*) as Marcaciones
		  from ccoLogDials L with(nolock)
		  inner join ccCamps C on L.cam_id=C.cam_id
		  Where fecha >  @mToday
		  group by C.cam_id, cam_descripcion
		  ) L order by Campana
		end

		else if @Tipo = 3 --Busqueda por campaña
		begin
		  select L.cam_id,
		    L.Calls, L.Answer, L.Busy, L.NoAnswer, L.Fax, L.NoService
		    ,L.Other,L.Canceled,L.Machine,L.NoTone,L.Congestion, isnull(callsOut.Abandon,0) as Abandon
		  from (
		  select cam_id,
		    count(case tipoResDial_id when 1 then 1 else null end) as Answer,
		    count(case tipoResDial_id when 2 then 1 else null end) as Busy,
		    count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer,
		    count(case tipoResDial_id when 4 then 1 else null end) as Fax,
		    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		    count(*) as Calls
		    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
		    ,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
		    ,count(case tipoResDial_id when 11 then 1 else null end) as Machine
		    ,count(case tipoResDial_id when 5 then 1 else null end) as NoTone
		    ,count(case tipoResDial_id when 12 then 1 else null end) as Congestion

		  from ccoLogDials with(nolock)
		  Where cam_id = @cam_id
		  and fecha >  @mToday
		  group by cam_id
		  ) L 
		  left join (select 
		    cam_id,
		    count(case statuscall_id when 6 then 1 else null end) as Abandon,
		    count(*) as Contesta    
		  from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
		  where cal_Inicio > @mToday
		  group by cam_id) callsOut on L.cam_id = callsOut.cam_id

		end

		else if @Tipo = 4-- Busqueda por campañas asociadas a admin
		begin
		  select L.cam_id,
		    L.Calls, L.Answer, L.Busy, L.NoAnswer, L.Fax, L.NoService
		    ,L.Other,L.Canceled,L.Machine,L.NoTone,L.Congestion, isnull(callsOut.Abandon,0) as Abandon
		  from (
		  select logDials.cam_id,
		    count(case tipoResDial_id when 1 then 1 else null end) as Answer,
		    count(case tipoResDial_id when 2 then 1 else null end) as Busy,
		    count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer,
		    count(case tipoResDial_id when 4 then 1 else null end) as Fax,
		    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		    count(*) as Calls
		    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
		    ,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
		    ,count(case tipoResDial_id when 11 then 1 else null end) as Machine
		    ,count(case tipoResDial_id when 5 then 1 else null end) as NoTone
		    ,count(case tipoResDial_id when 12 then 1 else null end) as Congestion
		  from ccoLogDials logDials with(nolock)
		  right join (select distinct cam_id from ccSupervisorCam supCam where user_id=@sup_id) B ON logDials.cam_id = B.cam_id
		  Where fecha >  @mToday
		  group by logDials.cam_id
		  ) L 
		  left join (select 
		    cam_id,
		    count(case statuscall_id when 6 then 1 else null end) as Abandon,
		    count(*) as Contesta    
		  from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
		  where cal_Inicio > @mToday
		  group by cam_id) callsOut on L.cam_id = callsOut.cam_id
		  order by L.cam_id
		end