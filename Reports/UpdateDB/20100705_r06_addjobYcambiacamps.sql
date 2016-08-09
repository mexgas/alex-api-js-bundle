/*
Autor: Armando Rodriguez
Fecha: 2010/06/09
Descripcion: agrega job para borrar la informacion de las tablas ccgen en ccenter,
Version requerida: 5
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '6'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''Borra guardados'',
''TRUNCATE TABLE ccGenSession
--TRUNCATE TABLE ccGenInCall
--TRUNCATE TABLE ccGenInCallDNI
--TRUNCATE TABLE ccGenOutCall

TRUNCATE TABLE ccGenAgent
TRUNCATE TABLE ccGenAgentNotReady

TRUNCATE TABLE ccGenInSpec
TRUNCATE TABLE ccGenInAbnd
TRUNCATE TABLE ccGenInAnsw
TRUNCATE TABLE ccGenInCalif

TRUNCATE TABLE ccGenOutCamp
TRUNCATE TABLE ccGenOutCallCalif
TRUNCATE TABLE ccGenOutCallDials

TRUNCATE TABLE ccGenOutCstoResumen'',''*N/A*'',1,0,10,''01/01/1900 05:30'',''01/01/1900 05:35'',''1111111'','''','''','''','''','''','''',0,'''','''',1,0)
'
	EXEC(@Sql)

	set @Sql='update exp_jobs set dserver= '''', ddatabase = '''', dlogin = '''', dpass = '''' where useccrepindes = 1'
	EXEC(@Sql)

------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC]
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
go

if @@version not like 'Microsoft SQL Server 2000%'
begin
	EXEC dbo.sp_dbcmptlevel @dbname=N'ccreports', @new_cmptlevel=90
end