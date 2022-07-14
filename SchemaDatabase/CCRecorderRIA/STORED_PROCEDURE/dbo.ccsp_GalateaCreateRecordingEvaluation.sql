CREATE PROCEDURE [dbo].[ccsp_GalateaCreateRecordingEvaluation] 
	@grab_id INT,
	@userAdmin VARCHAR(50) = '',
	@idFormat INT,
	@totalPoints INT = 0,
	@generalQualification INT = 0,
	@nameAdmin VARCHAR(50) = '',
	@nameSupervisor VARCHAR(50) = '',
	@userSupervisor VARCHAR(50) = '',
	@createAt DATETIME = NULL
AS
BEGIN TRY
	INSERT INTO RECORDERRIA_RECORDINGEVALUATION(grab_id, userAdmin, idFormat, totalPoints, generalQualification, nameAdmin, nameSupervisor, userSupervisor, createAt, deleted)
	VALUES (@grab_id, @userAdmin, @idFormat, @totalPoints, @generalQualification, @nameAdmin, @nameSupervisor, @userSupervisor, @createAt, 0)
	select CAST(scope_identity() AS int) --RECORDERRIA_RECORDINGEVALUATION 
END TRY
BEGIN CATCH
	SELECT -1
END CATCH