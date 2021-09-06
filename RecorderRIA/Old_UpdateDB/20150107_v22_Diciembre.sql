/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/* 
Author: José Velasco
Date:07/01/2015
Description:
	
	Create Table TEC_AVRSRECMGR_DELETE_LOG
	update stored trsp_AdmRecSearchOneDay
	insert de nuevo valor en Trec_parametros para memoria para Applet de AVRS

	
Database:
Required version:

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 22

/* Actual version (use your own script to do it) */
set @actualVersion =  (select par_valor from trec_parametros where par_id = 30)

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

			/* Start script release */
			set @process = 'create table TEC_AVRSRECMGR_DELETE_LOG'
			set @sql='
			if not exists (select * from sys.tables where name = N''TEC_AVRSRECMGR_DELETE_LOG'')
				begin
					CREATE TABLE TEC_AVRSRECMGR_DELETE_LOG(
					id int identity(1,1),
					admin_id int,
					delete_date datetime
					)
			end'
			EXEC(@sql)

			set @process = 'update stored trsp_AdmRecSearchOneDay'
			if exists (select * from sys.procedures where name = N'trsp_AdmRecSearchOneDay')			
			set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchOneDay]
				@Sup_id int
				AS
				BEGIN

						select r.id_grabacion, avg(r.total_forma) as total_forma
						into #tempRiaFormaCalif from ria_formacalif r 
						inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t 
						on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
						group by r.id_grabacion		
						
						select distinct a.IdCampEsp, a.Tipo as Tipo_llamada
						into #tempCampEspWG from ccRIACampEspWGConsulta a 
						inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG
						
						select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
						finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
						isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
						isnull (z.total_forma,0) as total_forma,a.id_repositorio,
						CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
						CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
						a.grab_id as grabID, isnull(g.IDWG,0)as IDWG
						from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))		
						left join ccPosicion b on b.pos_id = a.cal_extension * -1
						--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
						left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
						left join ccTipoCalif AS f ON a.calif_id = f.calif_id
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
						left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
						inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
						where a.finicio >= Convert(nvarchar(11),Getdate(),120)

						drop table #tempRiaFormaCalif
						drop table #tempCampEspWG
				END			
			'
			else
				set @sql = ''
			EXEC(@sql)


			set @process = 'Insert into TREC_PARAMETROS'
			set @sql='
				if not exists (select * from TREC_PARAMETROS where par_id =71)
					begin
						INSERT INTO TREC_PARAMETROS VALUES (''71'',''AVRS Applet Max Memory Size'',''16'',''Max number of memory for AVRS Applet (MB)'')
					end
			'
			EXEC(@sql)

			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			update trec_parametros set par_valor = @Version where par_id = 30 

		commit tran
		end try

		begin catch	

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)
		
		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off

/**************************/
/***** GUIDE AND HELP *****/
/**************************/

/* IMPORTANT: Consider objects manipulation in the sequence exposed in order to get consistency in the script, uncommon objects are prior to common ones in case of exist except replication */

/***** Language Reference *****/
/*
DDL (Data Definition Language)
	* Create
	* Drop
	* Alter

DML (Data Manipulation Language)
	* Select
	* Update
	* Delete
	* Insert

Contraint Object Types
	* C = CHECK constraint
	* D = DEFAULT (constraint or stand-alone)
	* F = FOREIGN KEY constraint
	* PK = PRIMARY KEY constraint
	* R = Rule (old-style, stand-alone)
	* UQ = UNIQUE constraint

Function Object Types
	* FN Scalar function
	* IF Inline table-valued function
	* TF Table-valued-function
	* FS Assembly (CLR) scalar-function
	* FT Assembly (CLR) table-valued function
*/

/***** Most common objects *****/
/* 
TABLES
-- When table exists
if exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

-- When table does not exists
if not exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

COLUMNS
-- When column exists
if exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When column does not exists
if not exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

CONSTRAINTS
-- When constraint exists
if exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

-- When constraint does not exists
if not exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

INDEXES
-- When index exists
if exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When index does not exists
if not exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

TRIGGERS
-- When trigger exists
if exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When trigger does not exists
if not exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

FUNCTIONS
-- When function exists
if exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

-- When function does not exists
if not exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

STORED PROCEDURES
-- When stored procedure exists
if exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

-- When stored procedure does not exists
if not exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

VIEWS
-- When view exists
if exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

-- When view does not exists
if not exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

JOBS (In this case be careful about what to do)
-- if you want to create, modify or delete use the script below
if exists (select * from msdb.dbo.sysjobs_view where name = N'yourJobName')
	begin
		exec msdb.dbo.sp_delete_job @job_name = N'yourJobName', @delete_unused_schedule=1
	end

-- After that, you could run the script to create the Job despite of being new or being modified
*/

/***** Uncommon objects *****/
/*
DATABASES
-- When database exists
if exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

-- When database does not exists
if not exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

LOGINS
-- When login exists
if exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

-- When login does not exists
if not exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

SERVER ROLES
-- When server role exists
if exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

-- When server role does not exists
if not exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

SCHEMAS
-- When schema exists
if exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

-- When schema does not exists
if not exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

Replication
-- Replication scripts are generated apart so you have to check them and consider the validations implemented on those scripts
	* Publications
	* Subscriptions on publisher
	* Subscriptions
	* Snapshots
*/