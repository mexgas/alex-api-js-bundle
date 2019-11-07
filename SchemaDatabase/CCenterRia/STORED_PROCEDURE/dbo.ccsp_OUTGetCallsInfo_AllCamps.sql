CREATE PROCEDURE [dbo].[ccsp_OUTGetCallsInfo_AllCamps]
@Tipo as tinyint=0
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