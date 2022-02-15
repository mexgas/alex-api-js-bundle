CREATE PROCEDURE [dbo].[ccsp_GalateaCreateUpdateQuestions]
	@option INT,
	@idConcept INT = 0,
	@idFormat INT = 0,
	@indexPositionQuestion INT = 0,
	@type INT = 0,
	@title VARCHAR(250) = '',
	@pointsQuestion INT = 0,
	@answers XML = ''
AS
BEGIN TRANSACTION addQuestion
BEGIN TRY
	IF @option = 1
	BEGIN
		INSERT INTO RECORDERRIA_CONCEPTQUESTIONS(idConcept, idFormat, indexPositionQuestion, [type], title, pointsQuestion, answers)
		VALUES (@idConcept, @idFormat, @indexPositionQuestion, @type, @title, @pointsQuestion, @answers)
		COMMIT TRANSACTION addQuestion
		SELECT MAX(idQuestion) FROM RECORDERRIA_CONCEPTQUESTIONS
	END
	IF @option = 2
	BEGIN
		DELETE FROM RECORDERRIA_CONCEPTQUESTIONS WHERE idFormat = @idFormat
		COMMIT TRANSACTION addQuestion
		SELECT 0
	END
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION addQuestion
	SELECT -1
END CATCH