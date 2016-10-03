/*
Autor: Jose Velasco
Fecha: 2016/09/30
Descripcion:

	SP trsp_GetParametersMailById se agrega 
Version requerida: 35
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 36
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

---------------- inicio SCRIPT @Sql ----------------

	--Index

	--Tables

	--Functions

  	--SP

  	set @process = 'trsp_GetParametersMailById - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_GetParametersMailById'') DROP PROCEDURE trsp_GetParametersMailById'
  	EXEC(@sql)


	set @process = 'Create PROCEDURE trsp_GetParametersMailByType '
  	set @sql='Create PROCEDURE [dbo].[trsp_GetParametersMailByType]
				@mailType int
				AS
				BEGIN
					SELECT [server],[port],[user],[pass],isnull([ssl],0)
					FROM TREC_PARAMMAIL
					where MailType = @mailType
				END'
  	EXEC(@sql)

------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	update trec_parametros set par_valor = @Version where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

	if @Version_Actual = @Version begin
	begin tran
		begin try

	commit tran

		end try
		begin catch
			select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)
		rollback tran
		end catch
	 end
else
 begin
	select 'Version incorrecta de base de datos, version actual: '
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off