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

if @command=1 -- Load Inbound Dispositions
begin
  Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner, 
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd
  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
  where C.Calif_Status=1
  group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation
  order by 2
  return(0)
end

If @command=2 -- Load Outbound Dispositions
begin
  Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,  
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner, 
  IsNull(C.finishPreview,0) as finishPreview
  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
  where C.CalifOut_Status=1
  group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
  C.contactOwner, C.finishPreview
  order by 2
  return(0)
end

If @command=3 -- New ccTipoCalif
begin
  If exists(select description from ccTipoCalif where Calif_Status=1 and description=@description)
    begin
      select cast(3 as int) [result]
      return(0)
    end

  If exists(select description from ccTipoCalif where Calif_Status=0 and description=@description)
  begin
      update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0), 
	  GraphColor=isnull(@graphColor, '1DB4E2'), Calif_Status=1
      where description=@description
	  select cast(2 as int) [result]
      return(0)
  end

  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , GraphColor)
  select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, '1DB4E2') from ccTipoCalif
  select cast(1 as int) [result]
  return(0)
end

If @command=4 -- New ccTipoCalifOUT
begin
  If exists(select description from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
  begin
  select cast(3 as int) [result]
  return(0)
  end

 If exists(select description from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
 begin
  update ccTipoCalifOut set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0),
  Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), 
  finishPreview=isnull(@finishPreview,0), GraphColor=isnull(@graphColor, '1DB4E2')
  where description=@description
  select cast(2 as int) [result]
  return(0)
 end

 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, GraphColor)
 select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, @canReprogram, isnull(@keepDial,0), 
 isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, '1DB4E2') from ccTipoCalifOut
 select cast(1 as int) [result]
 return(0)
end


set nocount off