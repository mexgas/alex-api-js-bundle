CREATE PROCEDURE [dbo].[trsp_AdmGetInfoFormatScored]
	-- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada int,
@id_formato int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

declare @version int,
@grab_id int


set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)

set @version = (select MAX(version) from CCRecorderRIA.dbo.RIA_FORMACALIF where id_grabacion = @grab_id and id_formato = @id_formato)
select id_forma, fecha_calif, id_calificador, id_supervisor, id_grabacion, id_formato,total_forma,age_id, version from CCRecorderRIA.dbo.RIA_FORMACALIF where version = @version and id_grabacion = @grab_id and id_formato = @id_formato

END