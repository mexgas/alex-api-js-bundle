CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSubdispositions]
@command int
AS
set nocount on

if @command=1 -- Load ccTipoCalifSub
begin
  select califSub_id, IsNull(califSubDesc,'') [califSubDesc], orden, canReprogram, 
  IsNull(EndConversation,0) EndConversation
  from ccTipoCalifSub
  where califSub_Status = 1
  order by 2
  return(0)
end

If @command=2 -- Load ccTipoCalifSubOut
begin
  select califSub_id, IsNull(califSubDesc,'') [califSubDesc],
  IsNull(canReprogram, 0) [canReprogram],
  IsNull(orden, 0) [orden],
  IsNull(keepDial, 0) [keepDial],
  IsNull(autoCallback, 0) [autoCallback],
  IsNull(contactOwner, 0) [contactOwner]
  from ccTipoCalifSubOut
  where califSubOut_Status = 1
  order by 2
  return(0)
end

set nocount off