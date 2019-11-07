CREATE procedure [dbo].[ccsp_RIAAbandon_Config]
@Type smallint, -- 1:Muestra ACD | 2:Muestra Tiempos y Status (ACD) | 3:Actualiza Configuracion
@User_id smallint,
@Inbound_id smallint=null,
@minCallBackAbandon varchar(10)=null,
@minCallBackAbandonXpire varchar(10)=null,
@statuscall_id_Array varchar(1000)=null,
@telFormato TinyInt= null

as
set nocount on
declare @IDarea smallint
select @IDarea=IDarea from ccUsers where user_id=@user_id

if isnull(@IDarea,'')=''
 begin
  select -1, 'invalid user area'
  return(0)
 end

if @Type=1
 begin
  select distinct I.inbound_id, I.descripcion, A.frame, C.cam_procesando
  from ccinbound I join ccRIAinboundGraph G on I.inbound_id = G.inbound_id
  join ccRIAGraphics A on G.graphic_id = A.graphic_id
  join ccCamps C on I.cam_id=C.cam_id
  where A.type_id = 1 and I.cam_id is not null and I.IDArea=@IDarea
  order by descripcion
  return(0)
 end

if not exists(select inbound_id from ccInbound where cam_id is not null and inbound_id=@inbound_id and IDArea=@IDArea)
 begin
  select -2, 'invalid inbound_id'
  return(0)
 end

if @Type=2
 begin
  select @statuscall_id_Array = statuscall_id_Array from ccInbound where inbound_Id=@inbound_Id
  select 0 [type], (minCallBackAbandon/60) setHrs, (minCallBackAbandon-((minCallBackAbandon/60)*60)) setMin, 
  (minCallBackAbandonXpire/60) expHrs, (minCallBackAbandonXpire-((minCallBackAbandonXpire/60)*60)) expMin, 
  null statusCall_id,null descripcion,null chk
  from ccInbound where inbound_id=@Inbound_id
  union
  select 1, null, null, null, null, SL.statusCall_id, SL.descripcion, cast(cast(isnull(F.value,0) as bit)as tinyint) chk
  from ccStatusLLamada SL left join dbo.fn_RIASplitDelimited(@statuscall_id_Array, ',') 
  F on SL.statusCall_id = F.value where SL.inAbandonConfig=1 
  order by [type], descripcion
  return(0)
 end

if @Type=3
 begin
  update ccInbound set 
   minCallBackAbandon=case when @minCallBackAbandon is null then minCallBackAbandon else @minCallBackAbandon end,
   minCallBackAbandonXpire=case when @minCallBackAbandonXpire is null then minCallBackAbandonXpire else @minCallBackAbandonXpire end,
   statuscall_id_Array=case when @statuscall_id_Array is null then statuscall_id_Array else @statuscall_id_Array end,
   telFormato = case when @telFormato is null then telFormato else @telFormato end   
   where inbound_id=@Inbound_id
  return(0)
 end

set nocount off