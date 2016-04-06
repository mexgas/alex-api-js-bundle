/*

Fecha: 2013/07/12
Descripcion: 	

Version requerida: 4
*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 5
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)

	---------------- inicio SCRIPT @Sql ----------------


-- Se agrega tabla para conservar historial de la migración AVRS 

set @Sql = '
CREATE TABLE [dbo].[RIA_HISTORIAL_CONVERSION] (
	[id] [int] IDENTITY (1,1) NOT NULL,
	[fecha_inicial] [datetime] NULL,
	[fecha_final] [datetime] NULL,
	[grabid_inicial] [int] NULL,
	[grabid_final] [int] NULL
) ON [PRIMARY]

/*-- -Object: primary key [dbo].[RIA_HISTORIAL_CONVERSION].[PK_RIA_HISTORIAL_CONVERSION]    -------*/
if not exists (select * from sys.objects where [name] = N''PK_RIA_HISTORIAL_CONVERSION'' and [type] = ''PK'')
ALTER TABLE [dbo].[RIA_HISTORIAL_CONVERSION] ADD 
	CONSTRAINT [PK_RIA_HISTORIAL_CONVERSION] PRIMARY KEY CLUSTERED 
	(
		[id]
	) ON [PRIMARY];
'


IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_NAME='RIA_HISTORIAL_CONVERSION')
EXEC(@Sql)


	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			--exec dbo.ccsp_getVersion 'BD', @Version

	-- Updating DB Version
	
update trec_parametros set par_valor = '5' where par_id = 30 

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