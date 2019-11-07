CREATE PROCEDURE dbo.ccsp_RIAAgentACDs
@UserID int
AS
set nocount on
select distinct t1.inbound_id, t1.descripcion 
from ccinbound t1 with(index(PK_ccInbound)) join ccinboundagentes t2 on t1.inbound_id=t2.inbound_id
where t2.user_id = @UserID
order by descripcion
set nocount off