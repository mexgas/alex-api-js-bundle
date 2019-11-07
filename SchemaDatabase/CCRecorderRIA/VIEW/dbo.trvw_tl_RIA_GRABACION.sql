CREATE VIEW [dbo].[trvw_tl_RIA_GRABACION]
AS
SELECT     grab_id, age_id, finicio, duracion, id_repositorio, tipo_llamada, cam_id, calif_id, cal_id, ffin, ani, dni, id_nivel_grito, cal_key, cal_manual, cal_extension
FROM       dbo.RIA_GRABACION