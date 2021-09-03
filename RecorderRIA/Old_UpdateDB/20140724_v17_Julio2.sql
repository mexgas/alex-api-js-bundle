
/*
Fecha: 2014/05/12
Descripcion: 	
	Se agrega cambio en stored trsp_AdmRecSearchNodeAgent para validar Agentes en Finder

Version requerida: 16
*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 17
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

	set @process = 'ALter Table- [trsp_AdmRecSearchNodeAgent]'
	set @Sql='
		ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeAgent] 

		@Workgroup int

		AS
		BEGIN

			SET NOCOUNT ON;

		select a.User_id, a.Nombres, b.IDWG from ccUsers a
		inner join ccRIAWorkGroupUsersConsulta b
		on b.IDWG = @Workgroup
		where a.User_id = b.User_id and a.TipoUser_id = 1
		union 
		select a.User_id, a.Nombres, b.IDWG from ccUsers a
		inner join ccRIAWorkGroupUsers b
		on b.IDWG = @Workgroup
		where a.User_id = b.User_id and a.TipoUser_id = 1

		END
	'
	EXEC(@Sql)



------------------ fin SCRIPT @Sql ------------------
	--Generamos nueva version
	--exec dbo.ccsp_getVersion 'BD', @Version

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

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off


