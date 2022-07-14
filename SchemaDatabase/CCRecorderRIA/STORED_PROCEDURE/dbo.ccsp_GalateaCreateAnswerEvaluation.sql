CREATE PROCEDURE [dbo].[ccsp_GalateaCreateAnswerEvaluation] 
	@idRecordingEvaluation INT,
	@idQuestion INT,
	@answerType123 XML = '',
	@answerType4 INT,
	@answerType5 VARCHAR(MAX),
	@points INT = 0
AS
BEGIN TRY
	INSERT INTO RECORDERRIA_ANSWERSOFQUESTIONSEVALUATION(idRecordingEvaluation, idQuestion, answerType123, answerType4, answerType5, points)
	VALUES (@idRecordingEvaluation, @idQuestion, @answerType123, @answerType4, @answerType5, @points)
	select CAST(scope_identity() AS int) --RECORDERRIA_ANSWERSOFQUESTIONSEVALUATION
END TRY
BEGIN CATCH
	SELECT -1
END CATCH