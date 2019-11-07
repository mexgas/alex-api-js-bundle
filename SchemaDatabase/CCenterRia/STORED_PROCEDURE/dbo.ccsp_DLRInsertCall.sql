CREATE PROCEDURE [dbo].[ccsp_DLRInsertCall]
@callout_id int,
@cam_id smallint,
@cal_Key varchar(20),
@cal_Telefono varchar(14),
@Puerto smallint,
@logDial_id int=0
AS
declare @fecha as datetime
declare @cal_id as int

  select @fecha=getdate()
  INSERT ccoCallsOUT ( callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id ) --'Status 6=Pide Agente
    VALUES ( @callout_id, @cam_id, @cal_Key, @cal_Telefono, @Puerto,  @fecha, 6 )

  select @cal_id = scope_identity()

  insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
  select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo from ccRIACampEspWG wg with(nolock)
  where wg.Tipo=1 and wg.idcampesp=@cam_id


  -- calcula el costo de la llamada
  exec ccsp_CstoCalculaCosto @cal_id

  select @cal_id as cal_id