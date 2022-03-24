CREATE PROCEDURE [dbo].[ccsp_GalateaDeleteRecordingEvaluation] 
	@idRecordingEvaluation INT = 0
AS
BEGIN TRY
	UPDATE RECORDERRIA_RECORDINGEVALUATION SET deleted = 1 WHERE idRecordingEvaluation = @idRecordingEvaluation
	SELECT 0
END TRY
BEGIN CATCH
	SELECT -1
END CATCH