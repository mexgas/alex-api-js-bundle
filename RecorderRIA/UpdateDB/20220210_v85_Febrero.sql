set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 85
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
	begin tran
	begin try

    set @process = 'Create table RECORDERRIA_EVALUATIONFORMATS'
		set @Sql = '
			IF not exists
			(
			SELECT *
			FROM INFORMATION_SCHEMA.TABLES
			WHERE TABLE_SCHEMA = ''dbo'' AND TABLE_NAME = ''RECORDERRIA_EVALUATIONFORMATS''
			)
			BEGIN
				CREATE TABLE RECORDERRIA_EVALUATIONFORMATS(
				idFormat INT NOT NULL IDENTITY PRIMARY KEY,
				nameFormat VARCHAR(250) NOT NULL,
				descriptionFormat VARCHAR(1000),
				points INT NOT NULL,
				createAt DATETIME NOT NULL,
				updateAt DATETIME,
				createdBy VARCHAR(250)  NOT NULL,
				updatedBy VARCHAR(250) NOT NULL,
				deleted BIT );
			END
		'
		EXEC(@Sql)

	set @process = 'Create table RECORDERRIA_FORMATCONCEPTS'
		set @Sql = '
			IF not exists
			(
			SELECT *
			FROM INFORMATION_SCHEMA.TABLES
			WHERE TABLE_SCHEMA = ''dbo'' AND TABLE_NAME = ''RECORDERRIA_FORMATCONCEPTS''
			)
			BEGIN
				CREATE TABLE RECORDERRIA_FORMATCONCEPTS(
				idConcept INT NOT NULL IDENTITY PRIMARY KEY,
				idFormat INT NOT NULL,
				nameFormatConcept VARCHAR(250) NOT NULL,
				indexPosition INT NOT NULL);
			END
		'
		EXEC(@Sql)

	set @process = 'Create table RECORDERRIA_CONCEPTQUESTIONS'
		set @Sql = '
			IF not exists
			(
			SELECT *
			FROM INFORMATION_SCHEMA.TABLES
			WHERE TABLE_SCHEMA = ''dbo'' AND TABLE_NAME = ''RECORDERRIA_CONCEPTQUESTIONS''
			)
			BEGIN
				CREATE TABLE RECORDERRIA_CONCEPTQUESTIONS(
				idQuestion INT NOT NULL IDENTITY PRIMARY KEY,
				idConcept INT NOT NULL,
				idFormat INT NOT NULL,
				indexPositionQuestion INT NOT NULL,
				type INT NOT NULL,
				title VARCHAR(250) NOT NULL,
				pointsQuestion INT NOT NULL,
				answers XML);
			END
		'
		EXEC(@Sql)
	set @process = 'Delete if exist sp ccsp_GalateaCreateUpdateConcept'
	set @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaCreateUpdateConcept'')
            begin
          DROP PROCEDURE ccsp_GalateaCreateUpdateConcept;
            end'
	set @process = 'Create sp ccsp_GalateaCreateUpdateConcept'
	set @Sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaCreateUpdateConcept]
	@idFormat INT = 0,
	@nameFormatConcept VARCHAR(250) = '''',
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
END CATCH'
	set @process = 'Delete if sp ccsp_GalateaCreateUpdateEvaluationFormat'
	set @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaCreateUpdateEvaluationFormat'')
            begin
          DROP PROCEDURE ccsp_GalateaCreateUpdateEvaluationFormat;
            end'
	set @process = 'Create sp ccsp_GalateaCreateUpdateEvaluationFormat'
	set @Sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaCreateUpdateEvaluationFormat] 
	@nameFormat VARCHAR(250) = '''',
	@descriptionFormat VARCHAR(1000) = '''',
	@points INT = 0,
	@createdBy VARCHAR(50) = '''',
	@updatedBy VARCHAR(50) = '''',
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
END CATCH;'
	set @process = 'Delete if exist sp ccsp_GalateaCreateUpdateQuestions'
	set @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaCreateUpdateQuestions'')
            begin
          DROP PROCEDURE ccsp_GalateaCreateUpdateQuestions;
            end'
	set @process = 'Create sp ccsp_GalateaCreateUpdateQuestions'
	set @Sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaCreateUpdateQuestions]
	@option INT,
	@idConcept INT = 0,
	@idFormat INT = 0,
	@indexPositionQuestion INT = 0,
	@type INT = 0,
	@title VARCHAR(250) = '''',
	@pointsQuestion INT = 0,
	@answers XML = ''''
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
END CATCH'
	set @process = 'Delete if exist sp ccsp_GalateaEvaluationFormat'
	set @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaEvaluationFormat'')
            begin
          DROP PROCEDURE ccsp_GalateaEvaluationFormat;
            end'
	set @process = 'Create sp ccsp_GalateaEvaluationFormat'
	set @Sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaEvaluationFormat]
	@option SMALLINT,
	@id INT = 0,
	@name VARCHAR(250) = ''''
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
		SELECT nameFormat FROM RECORDERRIA_EVALUATIONFORMATS WHERE deleted = 0 AND nameFormat LIKE @name+''%''
	END
END'

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
