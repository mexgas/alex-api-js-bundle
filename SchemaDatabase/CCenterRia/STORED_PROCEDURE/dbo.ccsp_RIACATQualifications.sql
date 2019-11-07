CREATE PROCEDURE [dbo].[ccsp_RIACATQualifications]
@qualif_id varchar(max),
@Description varchar(60)=null,
@order varchar(3)=null,
@canReprogram varchar(1)=null,
@Type smallint,
@CamEspId smallint,
@keepDial bit=null,
@autoCB bit=null,
@contactOwner bit=null,
@endConversation varchar(1)=null,
@finishPreview bit = 0
AS
set nocount on
declare @sql nvarchar(1000)

if @Type=0
begin
  if @CamEspId=0
    begin
      SELECT calif_id, description FROM ccTipoCalif WITH(NOLOCK) WHERE Calif_Status=1 and description=@qualif_id
      return(0)
  end
  SELECT calif_id, description FROM ccTipoCalifOUT  WHERE CalifOut_Status=1 and description=@qualif_id
  return(0)
end

if @Type=1 -- Load cctipoCalif
begin
  Select C.calif_id, C.Description, C.orden, cast(C.canReprogram as int) as canReprogram, 0 as contactOwner, cast(count(R.califRel_id)as tinyint) hasSub
  ,isnull(C.EndConversation,0) conversationEnd
  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
  where C.Calif_Status=1
  group by C.calif_id, C.Description, C.orden, cast(C.canReprogram as int)  ,C.EndConversation--, cast(C.contactOwner as int)
  order by 2
  return(0)
end

If @Type=2 -- Load cctipoCalifOUT
begin
  Select C.calif_id, C.Description, cast(C.canReprogram as int) as canReprogram, C.orden,
  cast(C.keepDial as int) as keepDial, cast(C.autocallback as int) autocallback,  cast(count(R.califRel_id)as tinyint) hasSub,cast(isnull(C.contactOwner,0) as int) as contacOwner,cast(C.finishPreview as int) finishPreview
  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
  where C.CalifOut_Status=1
  group by C.calif_id, C.Description, cast(C.canReprogram as int), C.orden, cast(C.keepDial as int), cast(C.autocallback as int), cast(isnull(C.contactOwner,0) as int), cast(C.finishPreview as int)
  order by 2
  return(0)
end

If @Type=3 -- New cctipoCalif
begin
  If exists(select description from ccTipoCalif where Calif_Status=1 and description=@Description)
    begin
      select 2
      return(0)
    end
  If exists(select description from ccTipoCalif where Calif_Status=0 and description=@Description)
  begin
      update ccTipoCalif set orden=@order, CanReprogram=isnull(@canReprogram,0),EndConversation=isnull(@endConversation,0), Calif_Status=1--, contactOwner= isnull(@contactOwner,0)
      where description=@Description
      return(0)
  end
  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation)--, contactOwner
  select isnull(max(calif_id), 0) + 1,@Description, @order, isnull(@canReprogram,0), isnull(@endConversation,0) from ccTipoCalif --, isnull(@contactOwner,0)
  return(0)
 end

If @Type=4 -- Update cctipoCalif
  begin
    If exists(select description from ccTipoCalif where Calif_Status=1 and description=@Description)
      set @Description=null

    UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
    canReprogram=isnull(@canReprogram, canReprogram), EndConversation=isnull(@endConversation,EndConversation)--, contactOwner=isnull(@contactOwner,contactOwner)
    where calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, ','))

    delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

    return(0)
  end

If @Type=5 -- elimina calif
  begin
    delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, ','))
    delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, ','))
    update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, ','))
    return(0)
  end

If @Type=6 -- New cctipoCalifOUT
 begin
 If exists(select description from ccTipoCalifOut where CalifOut_Status=1 and description=@Description)
  begin
  select 2
  return(0)
  end

 If exists(select description from ccTipoCalifOut where CalifOut_Status=0 and description=@Description)
 begin
  update ccTipoCalifOut set orden=@order, CanReprogram=isnull(@canReprogram,0),
  Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), finishPreview=isnull(@finishPreview,0)
  where description=@Description
  return(0)
 end

 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram,keepDial, autocallback, contactOwner, finishPreview)
 select isnull(max(calif_id), 0) + 1, @Description, @order , 0, @canReprogram, isnull(@keepDial,0), isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), isnull(@finishPreview,0) from ccTipoCalifOut
 return(0)
 end

If @Type=7 -- Update cctipoCalifOUT
 begin
 If exists(select Description from ccTipoCalifOUT where CalifOut_Status=1 and Description=@Description)
  set @Description=null

 UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
 canReprogram=isnull(@canReprogram, canReprogram), keepDial=isnull(@keepDial,keepDial), autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner), finishPreview = isnull(@finishPreview,finishPreview)
 where calif_id=@qualif_id

 if @keepDial is not null
  begin
  update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
  end
 return(0)
 end

If @Type=8 -- elimina calif OUT
 begin
 delete from ccCalifCamp where tipo=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, ','))
 delete from cctipoSubCalifRel where tipoSubRel=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, ','))
 update ccTipoCalifOUT set CalifOut_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, ','))
 update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
 return(0)
 end

If @Type=9
 begin
 select o.cam_id, cam_descripcion , c.calif_id, co.description as Calificacion, canReprogram, orden, cast(autoCallback as tinyint) autoCallback
 from ccCamps o left join ccCalifCamp c on o.cam_id=c.cam_id and c.tipo=1
 inner join ccTipoCalifOUT co on c.calif_id=co.calif_id
 where co.CalifOut_Status=1 and o.cam_id=@CamEspId
 order by 4
 return(0)
 end

If @Type=10
 begin
 select i.inbound_id as cam_id, descripcion, c.calif_id, ci.description as Calificacion, orden, cast(ci.canreprogram as integer) canreprogram, cast(isnull(ci.EndConversation,0) as integer) EndConversation
 from ccInbound i left join ccCalifCamp c on i.inbound_id=c.cam_id and c.tipo=0
 inner join ccTipoCalif ci on c.calif_id=ci.calif_id
 where ci.Calif_Status=1 and inbound_id=@CamEspId
 order by 4
 return(0)
 end
set nocount off