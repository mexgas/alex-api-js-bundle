USE [CCReportsRIA]
GO



IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    WHERE i.name = 'IX_ccoLogDials_fecha_repOutDialDetail'
      AND i.object_id = OBJECT_ID('dbo.ccoLogDials')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_ccoLogDials_fecha_repOutDialDetail
    ON dbo.ccoLogDials
    (
        fecha ASC
    )
    INCLUDE
    (
        logDial_id,
        callout_id,
        cam_id,
        tipoResDial_id,
        Telefono,
        Puerto,
        tDialing,
        tBusy,
        answerbit,
        TipoDialingMode,
        cal_id,
        canceledNoAgents,
        disconnectCause,
        tipoLlamada_id,
        manualCRM
    );
END