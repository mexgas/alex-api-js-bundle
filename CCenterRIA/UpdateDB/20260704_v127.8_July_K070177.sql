USE CCenterRIA
GO

DECLARE @process VARCHAR(100)

BEGIN TRAN
BEGIN TRY

    -- =====================================================================
    -- K070177 - Calificaciones de campana de llamadas de entrada (IA) en Dashboard
    -- BD: CCenterRIA
    -- Cambios:
    --   1. SP ccsp_GalateaGetCalifDayIA: conteo del dia de calificaciones
    --      puestas por agentes virtuales en campanas IA de entrada, para la
    --      card "Calificaciones" del Dashboard (grafica de pastel + desglose).
    -- Notas:
    --   - Devuelve TODAS las calificaciones configuradas en la campana
    --     (ccCalifCampIA) aunque tengan 0 usos, para que la card muestre el
    --     catalogo completo.
    --   - Fila con CalificationId = 0 representa "Sin calificacion":
    --     llamadas atendidas (statusCall_id = 13) del dia sin calificacion.
    --     El front traduce la etiqueta (ES/EN/PT).
    --   - Registros con calificacion cuentan sin filtrar status (una llamada
    --     reencolada/abandonada puede conservar la calif del agente virtual).
    --   - Porcentajes se calculan en el front.
    -- =====================================================================

    SET @process = 'K070177 - SP ccsp_GalateaGetCalifDayIA'

    IF OBJECT_ID('ccsp_GalateaGetCalifDayIA') IS NOT NULL
        DROP PROCEDURE ccsp_GalateaGetCalifDayIA

    EXEC('
CREATE PROCEDURE [dbo].[ccsp_GalateaGetCalifDayIA]
    @InboundId SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @today DATETIME = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 101));

    SELECT
        cat.calif_id                       AS CalificationId,
        cat.Name_cal                       AS Calification,
        ISNULL(cat.Color, '''')            AS GraphColor,
        ISNULL(cnt.Total, 0)               AS Total
    FROM ccCalifCampIA rel WITH (NOLOCK)
    INNER JOIN cctipoCalif_IA cat WITH (NOLOCK)
        ON cat.calif_id = rel.calif_id
    LEFT JOIN (
        SELECT calif_id, COUNT(*) AS Total
        FROM ccCallsIn WITH (NOLOCK)
        WHERE cal_Inicio > @today
          AND Inbound_id = @InboundId
          AND ISNULL(calif_id, 0) > 0
        GROUP BY calif_id
    ) cnt ON cnt.calif_id = cat.calif_id
    WHERE rel.cam_id = @InboundId
      AND rel.tipo = 0

    UNION ALL

    SELECT
        0                                  AS CalificationId,
        ''systemTranslated_NoDisposition'' AS Calification,
        ''''                               AS GraphColor,
        COUNT(*)                           AS Total
    FROM ccCallsIn WITH (NOLOCK)
    WHERE cal_Inicio > @today
      AND Inbound_id = @InboundId
      AND statusCall_id = 13
      AND ISNULL(calif_id, 0) = 0
END
')

    COMMIT TRAN
    PRINT 'K070177 aplicado correctamente.'

END TRY
BEGIN CATCH
    ROLLBACK TRAN
    DECLARE @errMsg NVARCHAR(4000) = ERROR_MESSAGE()
    DECLARE @errLine INT = ERROR_LINE()
    PRINT 'ERROR en proceso [' + ISNULL(@process,'') + '] linea ' + CAST(@errLine AS VARCHAR) + ': ' + @errMsg
END CATCH
GO
