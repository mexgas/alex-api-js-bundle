USE [CCReportsRIA]
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes i
    WHERE i.name = 'IX_ccoLogDials_cal_id_logDial'
      AND i.object_id = OBJECT_ID('dbo.ccoLogDials')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ccoLogDials_cal_id_logDial]
    ON [dbo].[ccoLogDials] ([cal_id] desc)
    INCLUDE ([logDial_id])
END