CREATE PROCEDURE [dbo].[trsp_AdmSaveScoresFormaCalif]
-- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada int,
@id_calificador int,
@id_supervisor int,
@id_formato int,
@total_forma int,
@version int


AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

       -- Insert statements for procedure here

declare @grab_id bigint,@cam_id int, @age_id int


set @grab_id = (select grab_id from (select grab_id from RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)
set @cam_id = (select cam_id from (select cam_id from CCRecorderRIA.dbo.RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select cam_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)
set @age_id = (select age_id from (select age_id from CCRecorderRIA.dbo.RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select age_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)


Insert RIA_FORMACALIF (fecha_calif,id_calificador,id_supervisor,id_grabacion,id_formato,total_forma,age_id,version,tipo,tipo_llamada,cam_id)
values (GetDate(),@id_calificador,@id_supervisor,@grab_id,@id_formato,@total_forma,@age_id,@version, 1,@tipo_llamada,@cam_id)

select Scope_Identity()

exec trsp_InsertRecNode @grab_id,1


END