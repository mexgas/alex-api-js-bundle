/*

Fecha: 2013/06/26
Descripcion: 	

Version requerida: 3
*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 4
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)

	---------------- inicio SCRIPT @Sql ----------------


-- Se modifican permisos para Link Server

set @Sql = '
use [master]
grant alter any linked server to ccuser
grant alter any linked server to cwrecadmin
'

EXEC(@Sql)
 

-- Se modifica store procedure para link server
set @Sql = '
ALTER PROCEDURE [dbo].[trsp_AdmGetIpCW]
@ipInt varchar(17)

AS
declare @ipx varchar(15)
BEGIN
	 SET NOCOUNT ON;
	DECLARE @ipOut varchar(17)
	if not exists(select * from sys.servers where name = ''CWIP'')
     BEGIN
        exec sp_addlinkedserver ''CWIP'','''', ''SQLOLEDB'', @ipInt, '''','''',''''
	 END
    else
	 BEGIN
	    set @ipx= (select data_source from sys.servers where name = ''CWIP'')
       if @ipx != @ipInt
        begin
         exec sp_dropserver ''CWIP''
		 exec sp_addlinkedserver ''CWIP'','''', ''SQLOLEDB'', @ipInt, '''','''',''''
        end
	 END
END

'

 IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'trsp_AdmGetIpCW') AND type in (N'P', N'PC'))
 EXEC(@Sql)



--- Agregamos columna a tabla TREC_NUXIBAEXPORTSERVICE

set @Sql = '
ALTER TABLE TREC_NUXIBAEXPORTSERVICE
ADD exportada nvarchar(max) NULL
'
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='TREC_NUXIBAEXPORTSERVICE')
EXEC(@Sql)


	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			--exec dbo.ccsp_getVersion 'BD', @Version

	-- Updating DB Version
	
update trec_parametros set par_valor = '4' where par_id = 30 

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC], ERROR_PROCEDURE()
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