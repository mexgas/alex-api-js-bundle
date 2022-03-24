CREATE PROCEDURE [dbo].[ccsp_GalateaRecordingEvaluation]
		@option SMALLINT,
		@idRecordingEvaluation INT = 0,
		@user VARCHAR(50) = '',
		@idFormat INT = 0,
		@userSupervisor VARCHAR(50) = '',
		@nameCamp varchar(40) = ''
	AS
	BEGIN
		IF @option = 1 --search recording evaluation owner
		BEGIN
			SELECT userAdmin FROM RECORDERRIA_RECORDINGEVALUATION WHERE deleted = 0 AND idRecordingEvaluation = @idRecordingEvaluation
		END
		IF @option = 2 --get all answers
		BEGIN
			SELECT * FROM RECORDERRIA_ANSWERSOFQUESTIONSEVALUATION WHERE idRecordingEvaluation in (
				SELECT idRecordingEvaluation FROM RECORDERRIA_RECORDINGEVALUATION WHERE grab_id = @idRecordingEvaluation AND userAdmin = @user AND userSupervisor = @userSupervisor AND idFormat = @idFormat AND deleted = 0)
		END
		IF @option = 3 --get all recording evaluations
		BEGIN
			SELECT * FROM RECORDERRIA_RECORDINGEVALUATION WHERE grab_id = @idRecordingEvaluation AND userAdmin = @user AND userSupervisor = @userSupervisor AND idFormat = @idFormat AND deleted = 0
		END
		IF @option = 4 --get all supervisors
		BEGIN
			SELECT us.[User_id], us.[Login] as 'Username' FROM [CCenterRia].[dbo].[ccUsers] AS us INNER JOIN [CCenterRia].[dbo].[ccCamps] AS ca ON us.IDArea = ca.IDArea WHERE ca.cam_descripcion = @nameCamp AND us.TipoUser_id = 2
		END
	END