CREATE PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
AS
     SET NOCOUNT ON;
     DECLARE @lastCallAgt TABLE(id           INT NOT NULL
                              , tipo         VARCHAR(10) NOT NULL
                              , Hora         DATETIME NOT NULL --VARCHAR(19) NOT NULL, 
                              , Telefono     VARCHAR(55) NOT NULL
                              , EspCamp      VARCHAR(55) NOT NULL
                              , Calificacion VARCHAR(60)
                              , Duracion     VARCHAR(10) NOT NULL
                              , CallBack     DATETIME
                              , cal_key      VARCHAR(40)
                              , IDCampEsp    SMALLINT NOT NULL
                              , prefijo      VARCHAR(255) NULL
                              , GraphicID    INT
                              , PRIMARY KEY(id)
     );

     DECLARE @pais TINYINT;
     DECLARE @maxHours SMALLINT;
     DECLARE @topRows INT;
     DECLARE @setting VARCHAR(6);
     DECLARE @hidePhone BIT;
     DECLARE @dateStart DATETIME;

     SET @hidePhone = 1;

     SELECT @setting = valor FROM ccSettings WHERE setting_id = 255;

     SET @maxHours = CAST(SUBSTRING(@setting, 1, (SELECT PATINDEX('%|%', @setting)) - 1) AS SMALLINT);
     SET @topRows = CAST(SUBSTRING(@setting, (SELECT PATINDEX('%|%', @setting)) + 1, LEN(@setting)) AS INT);

     IF @maxHours = 0
     BEGIN
         SELECT Id
              , tipo
              , (CONVERT(VARCHAR(10), Hora, 101) + ' ' + CONVERT(VARCHAR(8), Hora, 108)) AS Hora
              , Telefono
              , EspCamp
              , Calificacion
              , CallBack
              , Duracion
              , '' AS CallBack
              , cal_key
              , IDCampEsp
              , prefijo
              , GraphicID
              , @hidePhone AS HidePhone FROM @lastCallAgt;

         RETURN 0;
     END;

     SELECT @pais = valor FROM ccSettings WHERE setting_id = 104;

     SELECT @hidePhone = CASE WHEN valor = '0'
                         THEN 0 ELSE 1
                         END FROM ccSettings WHERE setting_id = 223;

     IF @topRows = 0
     BEGIN
         SET @topRows = 10000;
     END;

     SET @dateStart = DATEADD(hh, -@maxHours, GETDATE());

     WITH timeTransfer
          AS (SELECT cal_id
                   , tipo
                   , SUM(tAntesXfer) AS tAntesXfer
                   , SUM(tDespuesXfer) AS tDespuesXfer FROM ccLogTransfers
              WHERE fechaFin > @dateStart
              GROUP BY cal_id
                     , tipo)

          INSERT INTO @lastCallAgt
                 ---Insert OUT
                 SELECT TOP (@topRows) c.cal_id AS id
                                     , 'OUT' AS Tipo
                                     , cal_inicio
                                     , cal_telefono AS Telefono
                                     , cam_descripcion AS EspCamp
                                     , ISNULL(cal.Description, '') AS Calificacion
                                     , CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
                                                                                                THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
                                                                                                END, 0), 114) AS Duracion
                                     , cal_fcallback AS CallBack
                                     , cal_key
                                     , c.cam_id AS IDCampEsp
                                     , ISNULL(ccCamps.prefijo, '') Prefijo
                                     , graph.graphic_id GraphicID FROM ccoCallsOut c
                                                                       INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
                                                                       LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
                                                                       LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
                                                                       LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
                                                                                                   AND t.tipo = 2
                 WHERE user_id = @user_id
                       AND cal_inicio > @dateStart
                 UNION
                 --- IN
                 SELECT TOP (@topRows) c.cal_id AS id
                                     , 'IN' AS Tipo
                                     , cal_inicio
                                     , cal_ani AS Telefono
                                     , descripcion AS EspCamp
                                     , ISNULL(cal.Description, '') AS Calificacion
                                     , CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
                                                                                                     THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
                                                                                                     END, 0), 108) Duracion
                                     , NULL AS CallBack
                                     , cal_key
                                     , c.inbound_id AS IDCampEsp
                                     , ISNULL(ccInbound.prefijo, '') Prefijo
                                     , graph.graphic_id GraphicID FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
                                                                       JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
                                                                       INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
                                                                       LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
                                                                       LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
                                                                                                   AND t.tipo = 1
                 WHERE user_id = @user_id
                       AND cal_inicio > @dateStart;

     SELECT Id
          , tipo
          , CASE WHEN @pais = 4
            THEN(CONVERT(VARCHAR(10), Hora, 101) + ' ' + CONVERT(VARCHAR(8), Hora, 108)) ELSE(CONVERT(VARCHAR(10), Hora, 103) + ' ' + CONVERT(VARCHAR(8), Hora, 14))
            END AS Hora
          , Telefono
          , EspCamp
          , Calificacion
          , ISNULL(CONVERT(VARCHAR(16), CallBack, 121), '') AS CallBack
          , Duracion
          , CallBack
          , cal_key
          , IDCampEsp
          , prefijo
          , GraphicID
          , @hidePhone AS HidePhone FROM @lastCallAgt
     ORDER BY hora DESC;
     SET NOCOUNT OFF;