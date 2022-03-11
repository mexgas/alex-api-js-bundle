set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 88
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
	begin tran
	begin try

	set @process = 'Delete if exist sp ccsp_GalateaCreateAnswerEvaluation'
	set @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaCreateAnswerEvaluation'')
            begin
          DROP PROCEDURE ccsp_GalateaCreateAnswerEvaluation;
            end'
	EXEC(@Sql)

	set @process = 'Create sp ccsp_GalateaEvaluationFormat'
	set @Sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaCreateAnswerEvaluation] 
	@idRecordingEvaluation INT,
	@idQuestion INT,
	@answerType123 XML = '',
	@answerType4 INT,
	@answerType5 VARCHAR(MAX),
	@points INT = 0
AS
BEGIN TRANSACTION addAnswerEvaluation
BEGIN TRY
	INSERT INTO RECORDERRIA_ANSWERSOFQUESTIONSEVALUATION(idRecordingEvaluation, idQuestion, answerType123, answerType4, answerType5, points)
	VALUES (@idRecordingEvaluation, @idQuestion, @answerType123, @answerType4, @answerType5, @points)
	COMMIT TRANSACTION addAnswerEvaluation
	SELECT MAX(idAnswerQuestions) from RECORDERRIA_ANSWERSOFQUESTIONSEVALUATION
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION addAnswerEvaluation;
	SELECT -1
END CATCH'
	EXEC(@Sql)

	set @process = 'Delete if exist sp ccsp_GalateaDeleteRecordingEvaluation'
	set @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaDeleteRecordingEvaluation'')
            begin
          DROP PROCEDURE ccsp_GalateaDeleteRecordingEvaluation;
            end'
	EXEC(@Sql)

	set @process = 'Create sp ccsp_GalateaDeleteRecordingEvaluation'
	set @Sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaDeleteRecordingEvaluation] 
	@idRecordingEvaluation INT = 0
AS
BEGIN TRANSACTION deleteRecordingEvaluation
BEGIN TRY
	UPDATE RECORDERRIA_RECORDINGEVALUATION SET deleted = 1 WHERE idRecordingEvaluation = @idRecordingEvaluation
	COMMIT TRANSACTION deleteRecordingEvaluation
	SELECT 0
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION deleteRecordingEvaluation;
	SELECT -1
END CATCH'
	EXEC(@Sql)

	set @process = 'Delete if exist sp ccsp_GalateaCreateRecordingEvaluation'
	set @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaCreateRecordingEvaluation'')
            begin
          DROP PROCEDURE ccsp_GalateaCreateRecordingEvaluation;
            end'
	EXEC(@Sql)

	set @process = 'Create sp ccsp_GalateaCreateRecordingEvaluation'
	set @Sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaCreateRecordingEvaluation] 
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
BEGIN TRANSACTION addRecordingEvaluation
BEGIN TRY
	INSERT INTO RECORDERRIA_RECORDINGEVALUATION(grab_id, userAdmin, idFormat, totalPoints, generalQualification, nameAdmin, nameSupervisor, userSupervisor, createAt, deleted)
	VALUES (@grab_id, @userAdmin, @idFormat, @totalPoints, @generalQualification, @nameAdmin, @nameSupervisor, @userSupervisor, @createAt, 0)
	COMMIT TRANSACTION addRecordingEvaluation
	SELECT MAX(idRecordingEvaluation) from RECORDERRIA_RECORDINGEVALUATION
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION addRecordingEvaluation;
	SELECT -1
END CATCH'
	EXEC(@Sql)

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	select par_valor from trec_parametros where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end
 else begin
	select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end