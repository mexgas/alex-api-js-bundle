-- Permite cambiar el tipo de conexión (lifeconnect o no) de un rango de extensiones

CREATE PROCEDURE dbo.ccsp_ADMSetLifeConnectRange
@pos_idLow integer,
@pos_idHigh integer,
@newValue tinyint -- 0 = no lifeconnect, 1 = lifeconnect
AS

   Update ccPosicion set tipoConexion = @newValue where pos_id >= @pos_idLow and pos_id <= @pos_idHigh