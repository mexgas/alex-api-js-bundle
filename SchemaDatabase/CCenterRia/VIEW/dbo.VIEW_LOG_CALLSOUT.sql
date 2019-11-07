CREATE VIEW dbo.VIEW_LOG_CALLSOUT
AS
SELECT     l.fecha, c.cam_descripcion AS CAMPANA, s.cal_Key AS CUENTA, l.Telefono, ISNULL(10 + cc.calif_id, l.tipoResDial_id) AS ID_RESULTADO_MARCACION, 
                      ISNULL(co.Description, tr.descripcion) AS DESC_RESULTADO_MARCACION, u.Login, cc.cal_extension AS EXTENSION, cc.statusCall_id AS ID_STATUS, 
                      cs.descripcion AS DESC_STATUS, cc.cal_tDialog AS DURACION, cc.cal_tNotas AS NOTAS, cc.cal_tXfer AS TRANSFERENCIA, s.Dato1, s.Dato2, s.Dato3, 
                      s.Dato4, s.Dato5, c.cam_id as cam_id
FROM         dbo.ccoLogDials l INNER JOIN
                      dbo.ccCamps c ON l.cam_id = c.cam_id INNER JOIN
                      dbo.ccoCallsOutSource s ON l.callout_id = s.callout_id INNER JOIN
                      dbo.ccTipoResultadoDial tr ON l.tipoResDial_id = tr.tipoResDial_id LEFT OUTER JOIN
                      dbo.ccoCallsOut cc ON l.callout_id = cc.callout_id AND l.Telefono = cc.cal_telefono
	         AND l.fecha BETWEEN DATEADD(mi, -2, cc.cal_Inicio) AND DATEADD(mi, +1, cc.cal_Inicio) LEFT OUTER JOIN
                      dbo.ccUsers u ON cc.User_id = u.User_id LEFT OUTER JOIN
                      dbo.ccStatusLLamada cs ON cc.statusCall_id = cs.statusCall_id LEFT OUTER JOIN
                      dbo.ccTipoCalifOUT co ON cc.calif_id = co.calif_id
Where l.fecha>='11/01/2004'