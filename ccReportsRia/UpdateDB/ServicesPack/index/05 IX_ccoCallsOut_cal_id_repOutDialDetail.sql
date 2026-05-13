USE [CCReportsRIA]
GO



IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    WHERE i.name = 'IX_ccoCallsOut_cal_id_repOutDialDetail'
      AND i.object_id = OBJECT_ID('dbo.ccoCallsOut')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_ccoCallsOut_cal_id_repOutDialDetail
    ON dbo.ccoCallsOut
    (
        cal_id
    )
    INCLUDE
    (
        callout_id,
        User_id,
        cal_key,
        calif_id,
        califSub_id,
        cal_manual,
        file_moved
    );
END