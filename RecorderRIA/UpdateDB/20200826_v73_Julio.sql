set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 72
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try
	
    SET @process = 'CW-4233 Verificar si existe SP trsp_VideoRecCredential'
		SET @sql = '
		if exists (select * from sys.procedures where name = N''trsp_VideoRecCredential'')
		begin
			DROP PROCEDURE trsp_VideoRecCredential
		end
		'
	EXEC (@sql)
	SET @process = 'CW-4233 Crear SP trsp_VideoRecCredential'
		SET @sql = '
		CREATE PROC [dbo].[trsp_VideoRecCredential]
		@action tinyint =1
		AS

		if @action=1 begin
			SELECT
				id_repositorio,
				InIniPort, InFinPort,
				OutIniPort, OutFinPort,
				ruta_rep_video,
				ria.domain,
				ria.[user],
				ria.password
			FROM TREC_REPOSITORIOS trec
			JOIN TREC_REPO_NWCREDENTIALS cred
			ON cred.id_repository = trec.id_repositorio
			INNER JOIN RIA_NETWORKCREDENTIALS ria 
			on ria.id = cred.id_nwCredential
		end
		'
	EXEC (@sql)

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
