set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 87
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
	begin tran
	begin try
	set @process = 'Delete if exist sp ccsp_GalateaEvaluationFormat'
	set @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaEvaluationFormat'')
            begin
          DROP PROCEDURE ccsp_GalateaEvaluationFormat;
            end'
	EXEC(@Sql)
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
		SELECT COUNT(idFormat) FROM RECORDERRIA_EVALUATIONFORMATS WHERE deleted = 0 AND nameFormat = @name COLLATE SQL_Latin1_General_CP1_CS_AS
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
