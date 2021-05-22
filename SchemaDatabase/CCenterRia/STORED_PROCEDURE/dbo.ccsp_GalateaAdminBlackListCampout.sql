CREATE PROCEDURE [dbo].[ccsp_GalateaAdminBlackListCampout]-- basandose del sp ccsp_RIABlackListCamp
@Option smallint,
@IDArea smallint = 0,
@CamID SmallInt = 0,
@InsertSchedule_id varchar(max) = '0',
@DeleteSchedule_id varchar(max) = '0',
@ManyOutboundIDs varchar(max)=''
as

if @Option = 1 -- Asignar listas negras a una campaña de salida
 begin

  if @CamID = 0
   begin
    update Camplistanegra set status = 1 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ','))

    insert into Camplistanegra (idtipolista, cam_id, status)
    select FN.value, C.cam_id, 1 from ccCamps C, dbo.fn_RIASplitDelimited(@InsertSchedule_id, ',') FN where C.IDArea = @IDArea
    and C.cam_id not in (select CL.cam_id from Camplistanegra CL join dbo.fn_RIASplitDelimited(@InsertSchedule_id, ',') FN
    on CL.idtipolista = FN.value where CL.status = 1)
    return(0)
   end

  update Camplistanegra set status = 1 where cam_id = @CamID
  and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ','))

  insert into Camplistanegra (idtipolista, cam_id, status)
  select value, @CamID, 1 from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ',')
    where value not in (select idtipolista from Camplistanegra where cam_id = @CamID and status = 1
    and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ',')))

  Insert Into ccAgendaListaNegra (campsid,fecharegs,fechaaplicar) values (@CamID,'20100101',getDate()) -- El 2010 es para que quite registros viejos con base en el cal fecha dial de ccocallsoutsource, principalmente para quitar callbacks de numeros cargados hace mucho tiempo

  declare @idAgenda as int
  select @idAgenda = SCOPE_IDENTITY()

  insert into ccAgenda_TipoListaNegra(idAgenda,idtipolista)
  select @idAgenda, value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ',')

  select DISTINCT idtipolista as BlacklistIdAssigned from Camplistanegra 
  where cam_id=@CamID and status=1 and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, ','))
 end

if @Option = 2 -- Desasignar listas negras de la campaña de salida @CamID
 begin
  update Camplistanegra set status = 0 where cam_id = @CamID  and idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, ','))
  return(0)
 end

if @Option = 3 -- Desasignar listas negras de todas las campañas de salida a las que esten asignadas
 begin
 update Camplistanegra set status = 0 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, ','))
  return(0)
 end

 if @Option = 4 -- trae las listas negras de la campaña de salida indicada en @CamID
 begin
  select cl.cam_id as CampId, ca.cam_descripcion as CampName, cl.idtipolista as BlacklistId, tl.Tipolista as BlacklistName
  from Camplistanegra cl join ccCamps ca on cl.cam_id = ca.cam_id
   join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
  where cl.status = 1 and cl.cam_id = @CamID
  order by 1, 3
  return(0)
 end

  if @Option = 5 -- trae las relaciones entre listas negras y las campaña de salida indicadas en @ManyOutboundIDs
 begin
  select cl.cam_id as CampId, ca.cam_descripcion as CampName, cl.idtipolista as BlacklistId, tl.Tipolista as BlacklistName
  from Camplistanegra cl join ccCamps ca on cl.cam_id = ca.cam_id
   join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
  where cl.status = 1 and cl.cam_id in(select value from dbo.fn_RIASplitDelimited(@ManyOutboundIDs, ','))
  order by 1, 3
  return(0)
 end