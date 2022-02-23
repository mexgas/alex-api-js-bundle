CREATE PROCEDURE [dbo].[ccsp_GalateaCreateUpdateConcept]
	@idFormat INT = 0,
	@nameFormatConcept VARCHAR(250) = '',
	@indexPosition INT = 0,
	@option SMALLINT
AS
BEGIN tRANSACTION addConcept
BEGIN TRY
	IF @option = 1
	BEGIN
		INSERT INTO RECORDERRIA_FORMATCONCEPTS(idFormat, nameFormatConcept, indexPosition)
		VALUES (@idFormat, @nameFormatConcept, @indexPosition)
		COMMIT TRANSACTION addConcept
		SELECT MAX(idConcept) from RECORDERRIA_FORMATCONCEPTS
	END
	IF @option = 2
	BEGIN
		DELETE FROM RECORDERRIA_FORMATCONCEPTS WHERE idFormat = @idFormat
		COMMIT TRANSACTION addConcept
		SELECT 0
	END
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION addConcept;
	SELECT -1
END CATCH