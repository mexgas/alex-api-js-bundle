CREATE PROCEDURE [dbo].[trsp_AdmGetFormatsScored]
@cal_id int,
@tipo_llamada int
AS
BEGIN
	SET NOCOUNT ON;

declare @grab_id int

set @grab_id = (select min(grab_id) from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada 
UNION select min(grab_id) from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)
 
select distinct id_formato from CCRecorderRIa.dbo.RIA_FORMACALIF where id_grabacion = @grab_id

END