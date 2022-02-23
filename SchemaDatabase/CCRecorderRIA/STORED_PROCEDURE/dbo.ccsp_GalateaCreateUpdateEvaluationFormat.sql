CREATE PROCEDURE [dbo].[ccsp_GalateaCreateUpdateEvaluationFormat] 
	@nameFormat VARCHAR(250) = '',
	@descriptionFormat VARCHAR(1000) = '',
	@points INT = 0,
	@createdBy VARCHAR(50) = '',
	@updatedBy VARCHAR(50) = '',
	@option SMALLINT = 0,
	@idFormat INT = 0,
	@createAt DATETIME = NULL,
	@updateAt DATETIME = NULL
AS
BEGIN TRANSACTION addFormat
BEGIN TRY
	IF @option = 1
	BEGIN
		INSERT INTO RECORDERRIA_EVALUATIONFORMATS(nameFormat, descriptionFormat, points, createAt, updateAt, createdBy, updatedBy, deleted)
		VALUES (@nameFormat, @descriptionFormat, @points, @createAt, @updateAt, @createdBy, @updatedBy ,0)
		COMMIT TRANSACTION addFormat
		SELECT MAX(idFormat) from RECORDERRIA_EVALUATIONFORMATS
	END
	IF @option = 2
	BEGIN
		UPDATE RECORDERRIA_EVALUATIONFORMATS SET nameFormat = @nameFormat, descriptionFormat = @descriptionFormat, points = @points,
		updateAt = @updateAt, updatedBy = @updatedBy WHERE idFormat = @idFormat
		COMMIT TRANSACTION addFormat
		SELECT 0
	END
	IF @option = 3
	BEGIN
		UPDATE RECORDERRIA_EVALUATIONFORMATS SET deleted = 1 WHERE idFormat = @idFormat
		COMMIT TRANSACTION addFormat
		SELECT 0
	END
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION addFormat;
	SELECT -1
END CATCH;