-- =============================================
-- Author:		Javier Ruelas Rossier
-- Create date: June 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmChangeQualityFormats]
	-- Add the parameters for the stored procedure here

@type int,
@id int,
@texto varchar(256)


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
    IF @type = 0
BEGIN

Update ccRecorderRIA.dbo.RIA_CONCEPTOS set con_descripcion = @texto  where id_concepto = @id


END

ELSE IF @type = 1
BEGIN

Update ccRecorderRIA.dbo.RIA_PREGUNTAS set enunciado_pregunta = @texto  where id_pregunta = @id

END

ELSE IF @type = 2
BEGIN

Update ccREcorderRIA.dbo.RIA_RESPUESTAS set etiqueta = @texto  where id_respuesta = @id

END


END