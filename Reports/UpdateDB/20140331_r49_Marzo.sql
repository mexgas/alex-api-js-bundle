/*
Autor: Raymundo Gonzalez
Fecha: 2014/03/31
Descripcion:
	Se modifica la tabla ccGenInCalifWG para cambiar el tipo de dato de la columna calif_id
	
Version requerida: 48
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '49'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

		set @process = 'ccGenInCalifWG - Drop Constraint'
		set @Sql='ALTER TABLE ccGenInCalifWG DROP CONSTRAINT PK_ccGenInCalifWG'
		
	EXEC(@Sql)
 
 		set @process = 'ccGenInCalifWG - Alter Table'
 		set @Sql='alter table ccGenInCalifWG alter column calif_id smallint not null'
 		
	EXEC(@Sql)
	
		set @process = 'ccGenInCalifWG - Add Constraint'
		set @Sql='ALTER TABLE ccGenInCalifWG ADD CONSTRAINT PK_ccGenInCalifWG PRIMARY KEY (timegroup,idwg,calif_id)'
		
	EXEC(@Sql)
 
------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

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
