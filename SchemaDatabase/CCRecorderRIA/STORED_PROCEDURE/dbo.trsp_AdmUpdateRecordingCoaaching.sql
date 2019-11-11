CREATE PROCEDURE [dbo].[trsp_AdmUpdateRecordingCoaaching]
@coaching_Id int,
@call_Id int,
@call_Type int
AS
BEGIN
	
	IF EXISTS( SELECT 1 FROM RIA_GRABACION with (index(IX_RIA_GRABACION_1)) WHERE cal_id = @call_Id AND tipo_llamada = @call_Type )

		BEGIN

			UPDATE RIA_GRABACION
			SET calif_id = @coaching_Id
			WHERE cal_id = @call_Id AND tipo_llamada = @call_Type

		END

	ELSE

		BEGIN

			UPDATE RIA_GRABACIONCONSULTA
			SET calif_id = @coaching_Id
			WHERE cal_id = @call_Id AND tipo_llamada = @call_Type

		END
END