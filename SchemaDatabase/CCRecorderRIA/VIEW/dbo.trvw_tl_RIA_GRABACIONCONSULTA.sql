CREATE VIEW [dbo].[trvw_tl_RIA_GRABACIONCONSULTA]
AS
SELECT     grab_id, age_id, ffin, finicio, ani, dni, duracion, id_repositorio, id_nivel_grito, tipo_llamada, cam_id, calif_id, cal_id, cal_key, cal_manual, cal_extension
FROM         dbo.RIA_GRABACIONCONSULTA