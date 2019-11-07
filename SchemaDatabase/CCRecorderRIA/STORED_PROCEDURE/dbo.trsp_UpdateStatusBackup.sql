CREATE PROCEDURE [dbo].[trsp_UpdateStatusBackup]
@status as int,
@statusVideo as int,
@grabId as int
AS
BEGIN
	UPDATE TREC_BACKUPS set status_audio = @status, status_video = @statusVideo where grab_id = @grabId;
END