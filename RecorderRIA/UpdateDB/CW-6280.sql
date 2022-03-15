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
	
	
	
	
	set @process = 'CW-6280 Add column ruta_repositorio_secundario'
	set @Sql = 'IF NOT EXISTS (SELECT * FROM sys.columns WHERE NAME = N''ruta_repositorio_secundario'' AND Object_ID = Object_ID(N''TREC_REPOSITORIOS''))
BEGIN
	ALTER TABLE TREC_REPOSITORIOS ADD ruta_repositorio_secundario nvarchar(250) NOT NULL CONSTRAINT DF_TREC_REPO_secundario DEFAULT '''';
END'
	EXEC(@Sql)
	
	set @process = 'CW-6280 Add column dirvirtual_audio_secundario'
	set @Sql = 'IF NOT EXISTS (SELECT * FROM sys.columns WHERE NAME = N''dirvirtual_audio_secundario'' AND Object_ID = Object_ID(N''TREC_REPOSITORIOS''))
BEGIN
	ALTER TABLE TREC_REPOSITORIOS ADD dirvirtual_audio_secundario nvarchar(250) NOT NULL CONSTRAINT DF_TREC_REPO_audio_secundario DEFAULT '''';
END'
	EXEC(@Sql)
	
	set @process = 'CW-6280 Add column id_nwCredential_secondary'
	set @Sql = 'IF NOT EXISTS (SELECT * FROM sys.columns WHERE NAME = N''id_nwCredential_secondary'' AND Object_ID = Object_ID(N''TREC_REPO_NWCREDENTIALS''))
BEGIN
	ALTER TABLE TREC_REPO_NWCREDENTIALS ADD id_nwCredential_secondary int;
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
