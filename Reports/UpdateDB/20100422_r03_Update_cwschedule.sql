/*
Autor: Armando Rodriguez
Fecha: 2010/00/00
Descripcion: Actualizacion de querys para correr todo desde los registros
Version requerida: 2
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '3'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 		set @Sql='
update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccspGenOutCallCalif''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccspGenOutCallDials''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccspGenOutCstoResumen''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccspGenOutCamp''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccspGenInCalif''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccspGenInAnsw''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccspGenInAbnd''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccspGenInSpec''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccspGenAgentStatusNotReady''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccspGenAgent''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccspGenOutCall''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccspGenInCallDNI''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccspGenInCall''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccspGenSession''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccocallsout''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''cccallsin''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccLogAgentesNotReady''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccoLogDials''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1, useCCRepInDes = 1 where description = ''ccocallsoutsource''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1 where description = ''ccspGenAgentStatusSepHour''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1 where description = ''ccspGenAgentStatusSepHourNotReady''

update exp_jobs set CnxOrigen = '''', useCCenInCNX = 1 where description = ''ccspGenCatalogos'''
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


