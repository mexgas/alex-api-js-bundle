CREATE PROCEDURE [dbo].[ccsp_ADMAutoInicio]
	@cam_id int,
	@AutoInicio	bit,
	@tipoRegistros	tinyint,
	@delaCampana	int,
	@condicion	tinyint,
	@numero	int,
	@AutoInicioHora bit,
	@hora	smalldatetime,
	@tipoRegistros2	tinyint = NULL,
	@condicion2	tinyint = NULL,
	@numero2 int = NULL
AS

UPDATE ccCampsAutoInicio SET AutoInicio= @AutoInicio, AutoInicioHora = @AutoInicioHora
WHERE cam_id=@cam_id

IF @AutoInicio = 1
begin
	UPDATE ccCampsAutoInicio SET tipoRegistros = @tipoRegistros, delaCampana = @delaCampana, condicion = @condicion, numero = @numero, tipoRegistros2 = @tipoRegistros2, condicion2 = @condicion2, numero2 = @numero2
	WHERE cam_id=@cam_id
end

IF @AutoInicioHora = 1
begin
	UPDATE ccCampsAutoInicio SET hora = @hora
	WHERE cam_id=@cam_id
end