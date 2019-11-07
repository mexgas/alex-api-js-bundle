CREATE PROCEDURE dbo.ccsp_RIAGetLada
AS

declare @pais as varchar(3)
declare @lada as varchar(3)

	Select @lada = valor from ccSettings where setting_id = 17
	Select @pais = valor from ccSettings where setting_id = 104

select @lada as valor,@pais as valor