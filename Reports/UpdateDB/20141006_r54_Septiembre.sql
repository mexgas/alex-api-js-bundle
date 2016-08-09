/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/* 
Author: Jesus Gallardo
Date: 2014/08/08
Description:
	Se crea el indice ccLogAgentesDia_fecStatus en la tabla ccLogAgentesDia
	Se crea el indice IX_ccoDialers en la tabla ccoDialers
	Se crea el indice IX_ccoCallsOut_8 en la tabla ccoCallsOut
	Se crea el indice IX_ccoLogDials_9 en la tabla ccoLogDials
	Se modifica el SP ccspGenAgent

Database: ccReportsRia
Required version: 53

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 54

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

			/* Start script release */
			set @process = 'Create index ccLogAgentesDia_fecStatus - ccLogAgentesDia'
			set @sql='IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name=''ccLogAgentesDia_fecStatus'' AND object_id = OBJECT_ID(''ccLogAgentesDia''))
				CREATE NONCLUSTERED INDEX [ccLogAgentesDia_fecStatus] ON [dbo].[ccLogAgentesDia]
				(
					[fecha] ASC,[tStatus] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
			EXEC(@sql)
	
			set @process = 'Create index IX_ccoDialers - ccoDialers'
			set @sql='IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name=''IX_ccoDialers'' AND object_id = OBJECT_ID(''ccoDialers''))
				CREATE NONCLUSTERED INDEX [IX_ccoDialers] ON [dbo].[ccoDialers]
				(
					[Puerto] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
			EXEC(@sql)
	
			set @process = 'Create index IX_ccoCallsOut_8 - ccoCallsOut'
			set @sql='IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name=''IX_ccoCallsOut_8'' AND object_id = OBJECT_ID(''ccoCallsOut''))
				CREATE NONCLUSTERED INDEX [IX_ccoCallsOut_8] ON [dbo].[ccoCallsOut] 
				(
					[cal_extension] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'
			EXEC(@sql)
	
			set @process = 'Create index IX_ccoLogDials_9 - ccoLogDials'
			set @sql='IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name=''IX_ccoLogDials_9'' AND object_id = OBJECT_ID(''ccoLogDials''))
				CREATE NONCLUSTERED INDEX [IX_ccoLogDials_9] ON [dbo].[ccoLogDials](
					[fecha] ASC,
					[puerto] ASC,
					[callout_id] ASC,
					[Telefono] ASC,
					[cal_id] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'
			EXEC(@sql)
	
			set @process = 'Alter SP - ccspGenAgent'
			if exists (select * from sys.procedures where name = N'ccspGenAgent')
				set @sql='ALTER PROCEDURE [dbo].[ccspGenAgent]
					@from AS smalldatetime,
					@to AS smalldatetime
					AS

					DELETE ccGenAgent with(rowlock) WHERE timegroup>=@from AND timegroup<@to

					INSERT INTO ccGenAgent(timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl,tmanualCall)
					SELECT timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl,tmanualCall
					FROM(
						SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
							,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring + tmanualCall) AS ttot,nMoh,nWHag,nWHcl,tmanualCall
						 FROM(
							SELECT 
								xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
								,ISNULL(SUM(ccGenViewInCall.txfer),0)+ ISNULL(SUM(ccGenViewOutCall.txfer),0)as txfer
								,ISNULL(SUM(ccGenViewInCall.tdialog),0)+ ISNULL(SUM(ccGenViewOutCall.tdialog),0)as tdialog
								,ISNULL(SUM(ccGenViewInCall.tnotes),0)+ ISNULL(SUM(ccGenViewOutCall.tnotes),0)as tnotes
								,ISNULL(SUM(ccGenViewInCall.tring),0)+ ISNULL(SUM(ccGenViewOutCall.tring),0)as tring
								,ISNULL(SUM(ccGenViewInCall.nMoh),0)+ ISNULL(SUM(ccGenViewOutCall.nMoh),0)as nMoh
								,ISNULL(SUM(ccGenViewInCall.nWHag),0)+ ISNULL(SUM(ccGenViewOutCall.nWHag),0)as nWHag
								,ISNULL(SUM(ccGenViewInCall.nWHcl),0)+ ISNULL(SUM(ccGenViewOutCall.nWHcl),0)as nWHcl
								,tmanualCall
						
								,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
											 FROM ccGenSession with(nolock, index(IX_ccGenSession))
											 WHERE [user_id]=xTimeDetail.[user_id]
												AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
									),0)AS t1
								,ISNULL((SELECT top 1 3600
											 FROM ccGenSession with(nolock, index(IX_ccGenSession))
											 WHERE [user_id]=xTimeDetail.[user_id]
												AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
									),0)AS t2
								,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
											 FROM ccGenSession with(nolock, index(IX_ccGenSession))
											 WHERE [user_id]=xTimeDetail.[user_id]
												AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
									),0)AS t3
								,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
											 FROM ccGenSession with(nolock, index(IX_ccGenSession))
											 WHERE [user_id]=xTimeDetail.[user_id]
												AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
									),0)AS t4
							
							 FROM(
									SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup
										,ccLogAgentesDia.[user_id]
										,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown
										,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av
										,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav
										,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob
										,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother
										,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
										,ISNULL(SUM(CASE WHEN(tipostatusage_id=21)THEN tStatus ELSE NULL END),0)AS tmanualcall
									 FROM ccLogAgentesDia with(nolock, index(ccLogAgentesDia_fecStatus))
									 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
									 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
								)xTimeDetail
									LEFT OUTER JOIN ccGenViewInCall ON(xTimeDetail.timegroup=ccGenViewInCall.timegroup AND xTimeDetail.[user_id]=ccGenViewInCall.[user_id])
									LEFT OUTER JOIN ccGenViewOutCall ON(xTimeDetail.timegroup=ccGenViewOutCall.timegroup AND xTimeDetail.[user_id]=ccGenViewOutCall.[user_id])
								GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown, tmanualcall
					 		)xDetail
					)xAllTimes
					WHERE tlog>0
					ORDER BY timegroup,[user_id]'
			else
				set @sql = ''
			EXEC(@sql)
			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			exec ccsp_getVersion 'BD', @version

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