CREATE PROCEDURE [dbo].[ccsp_CheckDATA]
AS
set nocount on
 
delete ccInboundAgentes with(rowlock) where user_id not in (select user_id from ccusers where  TipoUser_id=1 and Status=1 and (IDArea is not null or IDArea>0))
delete ccCampsAgente with(rowlock) where user_id not in (select user_id from ccusers where  TipoUser_id=1 and Status=1 and (IDArea is not null or IDArea>0))
update ccPosicion set user_id = 0

set nocount off