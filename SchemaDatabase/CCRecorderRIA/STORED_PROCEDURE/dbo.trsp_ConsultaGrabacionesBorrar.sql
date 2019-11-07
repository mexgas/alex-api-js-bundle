CREATE PROCEDURE [dbo].[trsp_ConsultaGrabacionesBorrar]
@ini_grab_id INT,
@end_grab_id INT
AS

select grab_id, cal_id, Tipo_Llamada from RIA_GRABACION where grab_id between @ini_grab_id and @end_grab_id union select grab_id, cal_id, Tipo_Llamada from RIA_GRABACIONCONSULTA where grab_id between @ini_grab_id and @end_grab_id