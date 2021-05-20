CREATE PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
@command int,
@califIdLst varchar(8000) = null,
@description varchar(60)=null,
@order tinyint=null,
@canReprogram bit = null,
@graphColor varchar(15) = null,
@endConversation bit=null,
@keepDial bit=null,
@autoCB bit=null,
@contactOwner bit=null,
@finishPreview bit = 0
AS
set nocount on
declare @inserted table (ID smallint)

if @command=1 -- Load Inbound Dispositions
begin
  Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner, 
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd, graphColor
  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
  where C.Calif_Status=1
  group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation, graphColor
  order by 2
  return(0)
end

If @command=2 -- Load Outbound Dispositions
begin
  Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,  
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner, 
  IsNull(C.finishPreview,0) as finishPreview, graphColor
  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
  where C.CalifOut_Status=1
  group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
  C.contactOwner, C.finishPreview, graphColor
  order by 2
  return(0)
end

If @command=3 -- New ccTipoCalif
begin
  If exists(select description from ccTipoCalif where Calif_Status=1 and description=@description)
    begin
      select cast(-1 as smallint) [result]
      return(0)
    end

  If exists(select description from ccTipoCalif where Calif_Status=0 and description=@description)
  begin
      update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0), 
	  graphColor=isnull(@graphColor, '1DB4E2'), Calif_Status=1
	  output inserted.calif_id into @inserted
      where description=@description
	  select ID [result] from @inserted 
      return(0)
  end

  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , graphColor)
  output inserted.calif_id into @inserted
  select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, '1DB4E2') from ccTipoCalif
  select ID [result] from @inserted
  return(0)
end

If @command=4 -- New ccTipoCalifOUT
begin
  If exists(select description from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
  begin
  select cast(-1 as smallint) [result]
  return(0)
  end

 If exists(select description from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
 begin
  update ccTipoCalifOut set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0),
  Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), 
  finishPreview=isnull(@finishPreview,0), graphColor=isnull(@graphColor, '1DB4E2')
  output inserted.calif_id into @inserted
  where description=@description
  select ID [result] from @inserted 
  return(0)
 end

 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, graphColor)
 output inserted.calif_id into @inserted
 select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, isnull(@canReprogram,0), isnull(@keepDial,0), 
 isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, '1DB4E2') from ccTipoCalifOut
 select ID [result] from @inserted 
 return(0)
end
If @command=5 -- Delete Inbound Dispositions
begin
    delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
    delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
    update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
    return(0)
end
if @command=6 -- Delete Outbound Disposition
begin
	delete from ccCalifCamp where tipo=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
	delete from cctipoSubCalifRel where tipoSubRel=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
	update ccTipoCalifOUT set CalifOut_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	return(0)
end
if @command=7 -- Update Inbound Disposition
begin
	If exists(select description from ccTipoCalif where Calif_Status=1 and description=@Description)
      set @Description=null

    UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
    canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  
	EndConversation=isnull(@endConversation,EndConversation)
    where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))

    delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

    return(0)
end
if @command=8 -- Update Outbound Disposition
begin
	If exists(select Description from ccTipoCalifOUT where CalifOut_Status=1 and Description=@Description)
		set @Description=null

	 UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
	 canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  keepDial=isnull(@keepDial,keepDial), 
	 autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner), 
	 finishPreview = isnull(@finishPreview,finishPreview)
	 where calif_id=@califIdLst

	 if @keepDial is not null
	  begin
	  update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	  end
	 return(0) 
end

set nocount off