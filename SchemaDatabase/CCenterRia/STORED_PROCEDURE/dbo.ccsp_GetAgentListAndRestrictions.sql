CREATE PROCEDURE [dbo].[ccsp_GetAgentListAndRestrictions] @areaId int = 0
AS

DECLARE @assistedTransfer int

select @assistedTransfer = valor
from ccsettings
where setting_id = 76

if @areaId = 0
	begin
		select user_id,login,nombres,apellidopaterno,apellidomaterno,sexo,password,
		cast(dialMask & 1 as int) as 'Restringe celular', cast( (dialMask & 2) /2 as int) as 'Restringe ld', 
		cast((dialMask & 4) / 4 as int) as 'Restringe local', cast( xfermask as int) as 'Recibe transferencia', 
		cast(XferAgents as tinyint) XferAgents, @assistedTransfer as assistedTransfer
		from ccusers 
		where status = 1 
		and tipoUser_id = 1
	end
else
	begin
		select user_id,login,nombres,apellidopaterno,apellidomaterno,sexo,password,
		cast(dialMask & 1 as int) as 'Restringe celular', cast( (dialMask & 2) /2 as int) as 'Restringe ld', 
		cast((dialMask & 4) / 4 as int) as 'Restringe local', cast( xfermask as int) as 'Recibe transferencia', 
		cast(XferAgents as tinyint) XferAgent, @assistedTransfer as assistedTransfer
		from ccusers 
		where status = 1 
		and tipoUser_id = 1
		and IDArea = @areaId
	end