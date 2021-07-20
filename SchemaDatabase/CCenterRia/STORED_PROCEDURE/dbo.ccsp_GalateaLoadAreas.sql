CREATE PROCEDURE [dbo].[ccsp_GalateaLoadAreas]
as
SET NOCOUNT ON; 
select u.IDArea, ca.AreaName, User_id, TipoUser_id 
from ccUsers u
join ccRIACat_Areas ca on u.IDArea=ca.IDArea
where TipoUser_id=1
order by IDArea, User_id
SET NOCOUNT OFF