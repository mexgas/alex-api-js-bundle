CREATE PROCEDURE [dbo].[ccsp_RIAADMAutoInicio]
	@cam_id smallint,
	@AutoInicio	bit = 0,
	@tipoRegistros	tinyint = 0,
	@delaCampana	int = 0,
	@condicion	tinyint = 0,
	@numero	int = 0,
	@AutoInicioHora bit = 0,
	@hora	smalldatetime = '01/01/1900',
	@type tinyint,
	@tipoRegistros2	tinyint = NULL,
	@condicion2	tinyint = NULL,
	@numero2 int = NULL
AS

IF @Type = 1
begin
	select AutoInicio, tipoRegistros, delaCampana, condicion, numero, AutoInicioHora, hora, tipoRegistros2, condicion2, numero2 from ccCampsAutoInicio where cam_id = @cam_id
end

IF @Type = 2
Begin
	UPDATE ccCampsAutoInicio SET AutoInicio= @AutoInicio, AutoInicioHora = @AutoInicioHora
	WHERE cam_id=@cam_id

	IF @AutoInicio = 1
	begin
		UPDATE ccCampsAutoInicio SET tipoRegistros = @tipoRegistros, delaCampana = @delaCampana, condicion = @condicion, numero = @numero,  tipoRegistros2 = @tipoRegistros2, condicion2 = @condicion2, numero2 = @numero2
		WHERE cam_id=@cam_id
	end

	IF @AutoInicioHora = 1
	begin
		UPDATE ccCampsAutoInicio SET hora = @hora
		WHERE cam_id=@cam_id
	end
end

IF @Type = 3
Begin
	Insert into ccCampsAutoInicio (cam_id, hora) values(@cam_id, getdate())
End