CREATE PROCEDURE [dbo].[ccsp_ResetAgents] AS

SET NOCOUNT ON

Update ccPosicion Set User_id= 0
update ccUsers set TipoStatusAge_id=0 where TipoUser_id=1 and (IDArea is not null or IDArea>0)