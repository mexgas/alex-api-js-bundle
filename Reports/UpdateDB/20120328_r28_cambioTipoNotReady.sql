/*
Autor: Mauricio Perez
Fecha: 2011/03/28
Se cambia tipo de dato de TipoNotReady_id:  tinyint to smallint 
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '28'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	-- Se cambia tipo de dato de TipoNotReady_id:  tinyint to smallint 
 			set @Sql='ALTER TABLE dbo.ccLogAgentesNotReady DROP CONSTRAINT DF__ccLogAgen__separ__61F08603
CREATE TABLE dbo.Tmp_ccLogAgentesNotReady(User_id smallint NOT NULL,TipoNotReady_id smallint NOT NULL,tStatus int NOT NULL,fecha datetime NULL,separado tinyint NOT NULL)
ALTER TABLE dbo.Tmp_ccLogAgentesNotReady ADD CONSTRAINT DF__ccLogAgen__separ__61F08603 DEFAULT (0) FOR separado
IF EXISTS(SELECT * FROM dbo.ccLogAgentesNotReady)
	 EXEC(''INSERT INTO dbo.Tmp_ccLogAgentesNotReady (User_id, TipoNotReady_id, tStatus, fecha, separado)
		SELECT User_id, CONVERT(smallint, TipoNotReady_id), tStatus, fecha, separado FROM dbo.ccLogAgentesNotReady WITH (HOLDLOCK TABLOCKX)'')
DROP TABLE dbo.ccLogAgentesNotReady
EXECUTE sp_rename N''dbo.Tmp_ccLogAgentesNotReady'', N''ccLogAgentesNotReady'', ''OBJECT'' 
CREATE NONCLUSTERED INDEX IX_ccLogAgentesNR_userId ON dbo.ccLogAgentesNotReady (User_id)
CREATE NONCLUSTERED INDEX IX_ccLogAgentesNR_fecha ON dbo.ccLogAgentesNotReady (fecha)

CREATE TABLE dbo.Tmp_ccTipoNotReady(TipoNotReady_id smallint NOT NULL,Descripcion varchar(255) NOT NULL)
IF EXISTS(SELECT * FROM dbo.ccTipoNotReady)
	 EXEC(''INSERT INTO dbo.Tmp_ccTipoNotReady (TipoNotReady_id, Descripcion)
		SELECT CONVERT(smallint, TipoNotReady_id), Descripcion FROM dbo.ccTipoNotReady WITH (HOLDLOCK TABLOCKX)'')
DROP TABLE dbo.ccTipoNotReady
EXECUTE sp_rename N''dbo.Tmp_ccTipoNotReady'', N''ccTipoNotReady'', ''OBJECT'' 
ALTER TABLE dbo.ccTipoNotReady ADD CONSTRAINT PK_ccTipoNotReady PRIMARY KEY CLUSTERED (TipoNotReady_id)

CREATE TABLE dbo.Tmp_ccGenSessionNotReady(login datetime NOT NULL,user_id smallint NOT NULL,tiponotready_id smallint NOT NULL,amount smallint NOT NULL,time smallint NOT NULL)
IF EXISTS(SELECT * FROM dbo.ccGenSessionNotReady)
	 EXEC(''INSERT INTO dbo.Tmp_ccGenSessionNotReady (login, user_id, tiponotready_id, amount, time)
		SELECT login, user_id, CONVERT(smallint, tiponotready_id), amount, time FROM dbo.ccGenSessionNotReady WITH (HOLDLOCK TABLOCKX)'')
DROP TABLE dbo.ccGenSessionNotReady
EXECUTE sp_rename N''dbo.Tmp_ccGenSessionNotReady'', N''ccGenSessionNotReady'', ''OBJECT'' 
ALTER TABLE dbo.ccGenSessionNotReady ADD CONSTRAINT PK_ccGenSessionNotReady PRIMARY KEY CLUSTERED (login,user_id,tiponotready_id)

CREATE TABLE dbo.Tmp_ccGenAgentNotReady(timegroup smalldatetime NOT NULL,user_id smallint NOT NULL,tiponotready_id smallint NOT NULL,amount smallint NOT NULL,time smallint NOT NULL,amountReal smallint NULL)
IF EXISTS(SELECT * FROM dbo.ccGenAgentNotReady)
	 EXEC(''INSERT INTO dbo.Tmp_ccGenAgentNotReady (timegroup, user_id, tiponotready_id, amount, time, amountReal)
		SELECT timegroup, user_id, CONVERT(smallint, tiponotready_id), amount, time, amountReal FROM dbo.ccGenAgentNotReady WITH (HOLDLOCK TABLOCKX)'')
DROP TABLE dbo.ccGenAgentNotReady
EXECUTE sp_rename N''dbo.Tmp_ccGenAgentNotReady'', N''ccGenAgentNotReady'', ''OBJECT'' 
ALTER TABLE dbo.ccGenAgentNotReady ADD CONSTRAINT PK_ccGenAgentNotReady PRIMARY KEY CLUSTERED (timegroup,user_id,tiponotready_id)'
		EXEC(@Sql)

--- Exporta nulos como vacio
 			set @Sql='update exportReports 
set cols =''cal_id,dni_id, cal_ANI, cal_puerto,Inbound_id, User_id, cal_extension,cal_colgada,cal_Key,statusCall_id,calif_id,cal_que,cal_tDialog,cal_tNotas,cal_tWait,cal_tXfer,cal_tCall,cal_tRing,isNull(cal_Xfer,'''') as cal_Xfer,cal_Inicio,cal_Opciones,cal_origin_id, cal_tMoh, cal_whoHung, isNull(califSub_id,0) as califSub_id'' where jobid =2'
		EXEC(@Sql)

-- tamaño en ccGenTelMarcados
			set @Sql='CREATE TABLE dbo.Tmp_ccgenTelMarcados (telefono varchar(30) NOT NULL,fecha smalldatetime NOT NULL,cal_key varchar(20) NOT NULL,cam_id int NOT NULL,cantidad int NOT NULL,semana smallint NOT NULL	)  ON [PRIMARY]
INSERT INTO dbo.Tmp_ccgenTelMarcados (telefono, fecha, cal_key, cam_id, cantidad, semana)
SELECT telefono, fecha, cal_key, cam_id, cantidad, semana FROM dbo.ccgenTelMarcados WITH (HOLDLOCK TABLOCKX)
DROP TABLE dbo.ccgenTelMarcados
EXECUTE sp_rename N''dbo.Tmp_ccgenTelMarcados'', N''ccgenTelMarcados'', ''OBJECT'' 
ALTER TABLE dbo.ccgenTelMarcados ADD CONSTRAINT PK_ccgenTelMarcados PRIMARY KEY CLUSTERED (	telefono,fecha,cam_id,cal_key) WITH( PAD_INDEX = OFF, FILLFACTOR = 90, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
CREATE NONCLUSTERED INDEX IX_ccgenTelMarcados ON dbo.ccgenTelMarcados(cam_id) WITH( PAD_INDEX = OFF, FILLFACTOR = 90, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
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


