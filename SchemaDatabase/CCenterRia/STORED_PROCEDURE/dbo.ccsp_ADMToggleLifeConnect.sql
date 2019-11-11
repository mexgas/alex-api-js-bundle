-- Permite cambiar el tipo de conexión (lifeconnect o no) de una determinada extensión

CREATE PROCEDURE dbo.ccsp_ADMToggleLifeConnect
@pos_id integer,
@newValue tinyint -- 0 = no lifeconnect, 1 = lifeconnect
AS

declare @existe as tinyint

	select @existe = count(*) from ccPosicion 
	where pos_id = @pos_id

	if ( @existe = 1 )		
	begin
		Update ccPosicion set tipoConexion = @newValue where pos_id = @pos_id
		Select 1
	end
	else

		Select 0