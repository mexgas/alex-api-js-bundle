CREATE PROCEDURE [dbo].[ccsp_AgentChangePass]
@User_id smallint,		--ID del agente 
@NewPass varchar(33)   --Nuevo Password
as
set nocount on
-- Cambia el password del agente especificado
	UPDATE ccUsers SET Password = @NewPass, LastPasswordChange = getdate() WHERE User_Id = @User_id
return(0)
set nocount off