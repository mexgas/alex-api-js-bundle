CREATE PROCEDURE [dbo].[trsp_AdmGetQualityTemplateScored]
@id_chat int,
@id_formato int=2
AS
BEGIN

	SET NOCOUNT ON;
	select total_forma from RIA_FORMACALIF where id_grabacion = @id_chat and tipo=2 AND id_formato=@id_formato
END