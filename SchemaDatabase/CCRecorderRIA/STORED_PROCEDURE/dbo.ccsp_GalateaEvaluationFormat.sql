CREATE PROCEDURE [dbo].[ccsp_GalateaEvaluationFormat]
	@option SMALLINT,
	@id INT = 0,
	@name VARCHAR(250) = ''
AS
BEGIN
	IF @option = 1 --get all evaluation formats
	BEGIN
		SELECT * FROM RECORDERRIA_EVALUATIONFORMATS WHERE deleted != 1
	END
	IF @option = 2 --get concepts
	BEGIN
		SELECT * FROM RECORDERRIA_FORMATCONCEPTS WHERE idFormat = @id
	END
	IF @option = 3 --get questions
	BEGIN
		SELECT * FROM RECORDERRIA_CONCEPTQUESTIONS WHERE idFormat = @id
	END
	IF @option = 4 --verify same name
	BEGIN
		SELECT COUNT(idFormat) FROM RECORDERRIA_EVALUATIONFORMATS WHERE deleted = 0 AND nameFormat = @name
	END
	IF @option = 5 --get evaluation format by id
	BEGIN
		SELECT * FROM RECORDERRIA_EVALUATIONFORMATS WHERE idFormat = @id
	END
	IF @option = 6 --get count evaluation format like name
	BEGIN
		SELECT nameFormat FROM RECORDERRIA_EVALUATIONFORMATS WHERE deleted = 0 AND nameFormat LIKE @name+'%'
	END
END