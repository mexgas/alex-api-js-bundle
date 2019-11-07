CREATE PROCEDURE [dbo].[trsp_AdmGetNumericAnswer]
	-- Add the parameters for the stored procedure here

@id_formato int,
@version int,
@id_pregunta int,
@cal_id int,
@tipo_llamada int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
declare @id_forma as int,
@grab_id as int


set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)

set @id_forma = (select id_forma from CCRecorderRIA.dbo.RIA_FORMACALIF where version = @version and id_grabacion = @grab_id and id_formato = @id_formato)

select ISNULL(peso,0) from CCRecorderRIA.dbo.RIA_RESULTADOSFORMA where id_forma = @id_forma and id_pregunta = @id_pregunta


END