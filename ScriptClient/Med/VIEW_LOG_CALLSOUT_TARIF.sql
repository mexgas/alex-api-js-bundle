USE [CCReportsRIA]
GO

/****** Object:  View [dbo].[VIEW_LOG_CALLSOUT_TARIF]    Script Date: 08/07/2025 02:13:12 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [dbo].[VIEW_LOG_CALLSOUT_TARIF]
AS
SELECT        fecha, cam_id, CAMPANA, PrefijoCamp, Cuenta, Telefono, ID_Resultado_MARCACION, DESC_RESULTADO_MARCACION, Login, NombreAgente, EXTENSION, ID_STATUS, DESC_STATUS, DIALOGO, NOTAS, TRANSFERENCIA, 
                         RING, Dato1, Dato2, Dato3, Dato4, Dato5, LogDial_id, callout_id, cal_id, User_id, DURACION_MENSAJE, TipoDialingMode, canceledNoAgents, disconnectCause, AnswerBit, Puerto, Carrier, Duracion_Answerbit, 
                         Duracion_Llamada, Id_Calificacion, Desc_Calificacion, califSub_id, subcalificacion, '' AS Estado, '' AS Municipio, '' AS Poblacion, '' AS Tipo_Red, '' AS Modalidad, '' AS Razon_Social, DialPrefix, PrefijoCamp AS Expr1, 
                         CUELGA, tDialing
FROM            (SELECT        DATEADD(ss, - t.tAntesXfer - t.tDespuesXfer, t.fechaFin) AS fecha, c.cam_descripcion AS CAMPANA, co.cal_Key AS Cuenta, t.destino AS Telefono, 1 AS ID_Resultado_MARCACION, 
                                                    'Transferencia' AS DESC_RESULTADO_MARCACION, u.Login, u.Nombres + ' ' + u.ApellidoPaterno + ' ' + u.ApellidoMaterno AS NombreAgente, co.cal_extension AS EXTENSION, 0 AS ID_STATUS, 
                                                    'Transferencia' AS DESC_STATUS, t.tAntesXfer + t.tDespuesXfer AS DIALOGO, 0 AS NOTAS, 0 AS TRANSFERENCIA, 0 AS RING, 'Outbound' AS Dato1, 
                                                    CASE modo WHEN 0 THEN 'Externa ciega' WHEN 1 THEN 'Agente' WHEN 2 THEN 'ACD' WHEN 3 THEN 'Confer' WHEN 4 THEN 'Externa Supervisada' WHEN 5 THEN 'Desborde' END AS Dato2, '' AS Dato3, 
                                                    '' AS Dato4, '' AS Dato5, co.cam_id, 0 AS LogDial_id, co.callout_id, t.cal_id, co.User_id, 0 AS DURACION_MENSAJE, '0' AS TipoDialingMode, '' AS canceledNoAgents, '' AS disconnectCause, 1 AS AnswerBit, 
                                                    0 AS Puerto, '' AS Carrier, 0 AS Duracion_Answerbit, t.tAntesXfer + t.tDespuesXfer AS Duracion_Llamada, NULL AS Id_Calificacion, NULL AS Desc_Calificacion, NULL AS califSub_id, NULL AS subcalificacion, 
                                                    '' AS DialPrefix, '' AS PrefijoCamp, co.cal_whoHung AS CUELGA,0 tDialing
                          FROM            dbo.ccLogTransfers AS t WITH (nolock) LEFT OUTER JOIN
                                                    dbo.ccoCallsOut AS co WITH (nolock) ON t.cal_id = co.cal_id AND t.tipo = 2 LEFT OUTER JOIN
                                                    dbo.ccUsers AS u WITH (nolock) ON u.User_id = co.User_id LEFT OUTER JOIN
                                                    dbo.ccCamps AS c WITH (nolock) ON c.cam_id = co.cam_id
                          WHERE        (t.fechaFin >= DATEADD(dd, -3, GETDATE())) AND (t.tipo = 2) AND (t.modo NOT IN (1, 2)) AND (LEN(t.destino) > 4)
                          UNION ALL
                          SELECT        DATEADD(ss, - t.tAntesXfer - t.tDespuesXfer, t.fechaFin) AS fecha, CASE WHEN modo = 5 AND t .cal_id = 0 THEN 'transferencia IVR' ELSE c.descripcion END AS CAMPANA, CASE WHEN modo = 5 AND 
                                                   t .cal_id = 0 THEN '' ELSE cal_Key END AS Cuenta, t.destino AS Telefono, 1 AS ID_Resultado_MARCACION, 'Transferencia' AS DESC_RESULTADO_MARCACION, u.Login, 
                                                   u.Nombres + ' ' + u.ApellidoPaterno + ' ' + u.ApellidoMaterno AS NombreAgente, ci.cal_extension AS EXTENSION, 0 AS ID_STATUS, 'Transferencia' AS DESC_STATUS, t.tAntesXfer + t.tDespuesXfer AS DIALOGO, 
                                                   0 AS NOTAS, 0 AS TRANSFERENCIA, 0 AS RING, 'Inbound' AS Dato1, 
                                                   CASE modo WHEN 0 THEN 'Externa ciega' WHEN 1 THEN 'Agente' WHEN 2 THEN 'ACD' WHEN 3 THEN 'Confer' WHEN 4 THEN 'Externa Supervisada' WHEN 5 THEN 'Desborde' END AS Dato2, '' AS Dato3, 
                                                   '' AS Dato4, '' AS Dato5, ci.Inbound_id AS cam_id, 0 AS LogDial_id, 0 AS callout_id, t.cal_id, ci.User_id, 0 AS DURACION_MENSAJE, '0' AS TipoDialingMode, '' AS canceledNoAgents, '' AS disconnectCause, 
                                                   1 AS AnswerBit, 0 AS Puerto, '' AS Carrier, 0 AS Duracion_Answerbit, t.tAntesXfer + t.tDespuesXfer AS Duracion_Llamada, NULL AS Id_Calificacion, NULL AS Desc_Calificacion, NULL AS califSub_id, NULL 
                                                   AS subcalificacion, '' AS DialPrefix, '' AS PrefijoCamp, NULL AS CUELGA,0 tDialing
                          FROM            dbo.ccLogTransfers AS t LEFT OUTER JOIN
                                                   dbo.ccCallsIn AS ci WITH (nolock) ON t.cal_id = ci.cal_id AND t.tipo = 1 LEFT OUTER JOIN
                                                   dbo.ccUsers AS u WITH (nolock) ON u.User_id = ci.User_id LEFT OUTER JOIN
                                                   dbo.ccInbound AS c WITH (nolock) ON c.Inbound_id = ci.Inbound_id
                          WHERE        (t.fechaFin >= DATEADD(dd, -3, GETDATE())) AND (t.tipo = 1) AND (t.modo NOT IN (1, 2)) AND (LEN(t.destino) > 4)
                          UNION ALL
                          SELECT        l.fecha, c.cam_descripcion AS CAMPANA, s.cal_Key AS CUENTA, l.Telefono, l.tipoResDial_id AS ID_RESULTADO_MARCACION, tr.descripcion AS DESC_RESULTADO_MARCACION, u.Login, 
                                                   u.Nombres + ' ' + u.ApellidoPaterno + ' ' + u.ApellidoMaterno AS NombreAgente, cc.cal_extension AS EXTENSION, cc.statusCall_id AS ID_STATUS, cs.descripcion AS DESC_STATUS, cc.cal_tDialog AS DIALOGO, 
                                                   cc.cal_tNotas AS NOTAS, cc.cal_tXfer AS TRANSFERENCIA, cc.cal_tRing AS RING, s.Dato1, s.Dato2, s.Dato3, s.Dato4, s.Dato5, c.cam_id, l.logDial_id, l.callout_id, cc.cal_id, cc.User_id, 
                                                   l.tBusy AS DURACION_MENSAJE, l.TipoDialingMode, l.canceledNoAgents, l.disconnectCause, l.answerbit, l.Puerto, '' AS Carrier, DATEDIFF(SS, l.tAnswerBit, l.fecha) AS Duracion_Answerbit, ISNULL(DATEDIFF(SS, 
                                                   l.tAnswerBit, l.fecha), 0) + ISNULL(cc.cal_tRing, 0) + ISNULL(cc.cal_tXfer, 0) + ISNULL(cc.cal_tDialog, 0) AS Duracion_Llamada, cc.calif_id AS Id_Calificacion, co.Description AS Desc_Calificacion, sub.califSub_id, 
                                                   sub.califSubDesc, s.dialPrefix, c.dialPrefix AS PrefijoCamp, cc.cal_whoHung AS CUELGA,l.tDialing
                          FROM            dbo.ccoLogDials AS l WITH (nolock) INNER JOIN
                                                   dbo.ccCamps AS c ON l.cam_id = c.cam_id INNER JOIN
                                                   dbo.ccoCallsOutSource AS s WITH (nolock) ON l.callout_id = s.callout_id LEFT OUTER JOIN
                                                   dbo.ccTipoResultadoDial AS tr WITH (nolock) ON l.tipoResDial_id = tr.tipoResDial_id LEFT OUTER JOIN
                                                   dbo.ccoCallsOut AS cc WITH (nolock) ON l.cal_id = cc.cal_id LEFT OUTER JOIN
                                                   dbo.ccUsers AS u WITH (nolock) ON cc.User_id = u.User_id LEFT OUTER JOIN
                                                   dbo.ccStatusLLamada AS cs WITH (nolock) ON cc.statusCall_id = cs.statusCall_id LEFT OUTER JOIN
                                                   dbo.ccTipoCalifOUT AS co WITH (nolock) ON cc.calif_id = co.calif_id LEFT OUTER JOIN
                                                   dbo.ccTipoCalifSubOUT AS sub WITH (nolock) ON cc.califSub_id = sub.califSub_id
                          WHERE        (l.fecha >= DATEADD(dd, -3, GETDATE()))
						  
						  ) AS TABLA
			


GO


