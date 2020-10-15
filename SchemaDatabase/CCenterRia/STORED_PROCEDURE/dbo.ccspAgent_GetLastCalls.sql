CREATE PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
AS
     SET NOCOUNT ON
     DECLARE @lastCallAgt TABLE
     (id           INT NOT NULL, 
      tipo         VARCHAR(10) NOT NULL, 
      Hora         VARCHAR(10) NOT NULL, 
      Telefono     VARCHAR(55) NOT NULL, 
      EspCamp      VARCHAR(55) NOT NULL, 
      Calificacion VARCHAR(60), 
      Duracion     VARCHAR(10) NOT NULL, 
      CallBack     VARCHAR(60), 
      cal_key      VARCHAR(20), 
      IDCampEsp    SMALLINT NOT NULL, 
      prefijo      VARCHAR(MAX) NULL, 
      GraphicID    INT,
	  HidePhone	   bit
     )
     INSERT INTO @lastCallAgt
            SELECT TOP 10 c.cal_id AS id, 
                          'IN' AS Tipo, 
                          CONVERT(VARCHAR(10), cal_inicio, 108) AS Hora, 
                          cal_ani AS Telefono, 
                          descripcion AS EspCamp, 
                          ISNULL(cal.Description, '') AS Calificacion, 
                          CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - cal_tMoh + CASE
                                                                                            WHEN stopRecording = 0
                                                                                            THEN ISNULL(t.tDespuesXfer, 0)
                                                                                            ELSE 0
                                                                                        END, 0), 108) Duracion, 
                          '' AS CallBack, 
                          cal_key, 
                          c.inbound_id AS IDCampEsp, 
                          ISNULL(ccInbound.prefijo, '') Prefijo, 
                          graph.graphic_id GraphicID,
						  case when (select valor from ccSettings where setting_id = 223) = '0' then 0 else 1 end as HidePhone
            FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
                 JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
                 INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
                 LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
                 LEFT JOIN
            (
                SELECT cal_id, 
                       tipo, 
                       SUM(tAntesXfer) AS tAntesXfer, 
                       SUM(tDespuesXfer) AS tDespuesXfer
                FROM ccLogTransfers
                WHERE tipo = 1
                GROUP BY cal_id, 
                         tipo
            ) AS t ON c.cal_id = t.cal_id
            WHERE user_id = @user_id
                  AND cal_inicio > DATEADD(hh, -3, GETDATE())
            ORDER BY c.cal_inicio DESC
     INSERT INTO @lastCallAgt
            SELECT TOP 10 c.cal_id AS id, 
                          'OUT' AS Tipo, 
                          CONVERT(VARCHAR(10), cal_inicio, 108) AS Hora, 
                          cal_telefono AS Telefono, 
                          cam_descripcion AS EspCamp, 
                          ISNULL(cal.Description, '') AS Calificacion, 
                          CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - cal_tMoh + CASE
                                                                                       WHEN stopRecording = 0
                                                                                       THEN ISNULL(t.tDespuesXfer, 0)
                                                                                       ELSE 0
                                                                                   END, 0), 114) AS Duracion, 
                          ISNULL(CONVERT(VARCHAR(16), cal_fcallback, 121), '') AS CallBack, 
                          cal_key, 
                          c.cam_id AS IDCampEsp, 
                          ISNULL(ccCamps.prefijo, '') Prefijo, 
                          graph.graphic_id GraphicID,
						  case when (select valor from ccSettings where setting_id = 223) = '0' then 0 else 1 end as HidePhone
            FROM ccoCallsOut c
                 INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
                 LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
                 LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
                 LEFT JOIN
            (
                SELECT cal_id, 
                       tipo, 
                       SUM(tAntesXfer) AS tAntesXfer, 
                       SUM(tDespuesXfer) AS tDespuesXfer
                FROM ccLogTransfers
                WHERE tipo = 2
                GROUP BY cal_id, 
                         tipo
            ) AS t ON c.cal_id = t.cal_id
            WHERE user_id = @user_id
                  AND cal_inicio > DATEADD(hh, -3, GETDATE())
            ORDER BY c.cal_inicio DESC
     SELECT *
     FROM @lastCallAgt
     ORDER BY hora DESC
     SET NOCOUNT OFF