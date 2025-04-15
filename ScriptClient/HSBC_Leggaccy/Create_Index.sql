CREATE INDEX IX_HSBC_Outbound_Dials_Attempted_FechaON HSBC_Outbound_Dials_Attempted (fecha);
CREATE NONCLUSTERED INDEX [IX_ccoCallsOutSource_backup_callout_id]ON [dbo].[ccoCallsOutSource_backup] ([callout_id])
INCLUDE ([Dato4],[Dato5])