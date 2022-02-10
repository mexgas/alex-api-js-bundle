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
