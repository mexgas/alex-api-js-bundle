/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Angel Buzany
Date: 2015/10/07
Description: AVRS

	Alter SP trsp_AdmGetAllRepositories
	Alter SP trsp_GetParametersExportService
	Alter SP trsp_GetAppParameters
	Alter SP trsp_SaveAVRSBackupParameters
	Alter SP trsp_SaveAVRSExportParameters


Database: CCRecorderRia
Required version: 27

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @process nvarchar(max)
declare @sql nvarchar(max)
declare @errorGenerated nvarchar(max)
/* Version to release (use the version o
	f your own databse)*/
set @version = 28

/* Actual version (use your own script to do it) */
set @actualVersion =  (select par_valor from trec_parametros where par_id = 30)

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

	set @process = 'alter SP  - trsp_AdmGetAllRepositories'	
	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmGetAllRepositories]
		-- Add the parameters for the stored procedure here
		@Mode int
		-- Mode 1 para busqueda de grabaciones
		-- Mode 2 para configuracion de repositorios

	AS
	BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;

	    -- Insert statements for procedure here
	IF @Mode = 1
	Begin

	select id_repositorio, dirvirtual_audio, ruta_local, dirvirtual_video, ruta_local_video, ruta_imagenes, ruta_repositorio, ruta_rep_video  from TREC_REPOSITORIOS where id_repositorio = (select id_repository from TREC_REPO_NWCREDENTIALS where TREC_REPO_NWCREDENTIALS.id_nwCredential = (select id from RIA_NETWORKCREDENTIALS where RIA_NETWORKCREDENTIALS.type = 1)) order by id_repositorio
		End
	Else IF @Mode =2
		Begin
		
	select id_repositorio, ruta_repositorio, dirvirtual_audio, ruta_local, ruta_rep_video, dirvirtual_video, ruta_local_video, ruta_imagenes, ruta_rep_video  from TREC_REPOSITORIOS where id_repositorio = (select id_repository from TREC_REPO_NWCREDENTIALS where TREC_REPO_NWCREDENTIALS.id_nwCredential = (select id from RIA_NETWORKCREDENTIALS where RIA_NETWORKCREDENTIALS.type = 1)) order by id_repositorio

	End


	END'	 
	EXEC(@sql)

	set @process = 'alter SP  - trsp_GetParametersExportService'
	set @sql='ALTER PROCEDURE [dbo].[trsp_GetParametersExportService]
AS
BEGIN

DECLARE  @avrs_enviroment AS INT
DECLARE @SQL AS NVARCHAR(MAX)

		SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

		IF @avrs_enviroment = 2
			BEGIN
			
				SET @SQL = ''SELECT * FROM
							(SELECT par_valor,par_id,par_descripcion FROM TREC_PARAMETROS 
							WHERE par_id in (33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,61,62,63,29,2,65,67)
							UNION
							SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66,''''
							FROM RIA_GRABACION)x
							ORDER BY x.par_id''
				
			END 
		ELSE
			BEGIN

				SET @SQL = ''SELECT * FROM
							(SELECT par_valor,par_id FROM TREC_PARAMETROS 
							WHERE par_id in (33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,61,62,63,29,2,65,67)
							UNION
							SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
							FROM TREC_GRABACION)x
							ORDER BY x.par_id''
			END

	EXEC sp_executesql @SQL

END'
	EXEC(@Sql)

	set @process = 'alter SP  - trsp_GetAppParameters'
	set @sql='ALTER PROCEDURE [dbo].[trsp_GetAppParameters]
  @app_id AS INT
    AS
    BEGIN
    DECLARE  @avrs_enviroment AS INT
    DECLARE @SQL AS NVARCHAR(MAX)

    --AVRS Recordings Manager
    IF @app_id = 1
    BEGIN
      SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

        IF @avrs_enviroment = 2
          BEGIN
        
            SET @SQL = ''SELECT par_valor,par_id 
                  FROM TREC_PARAMETROS 
                  WHERE par_id 
                  IN (67,68,69,70)
                  ORDER BY par_id''                      
          END 
        ELSE
          BEGIN

            SET @SQL = ''SELECT par_valor,par_id 
                  FROM TREC_PARAMETROS 
                  WHERE par_id 
                  IN (82,83,84,85)
                  ORDER BY par_id''  
          END
    END

    EXEC sp_executesql @SQL

    END'
	EXEC(@Sql)

	set @process = 'alter SP  - trsp_SaveAVRSBackupParameters'
	set @sql='ALTER PROCEDURE [dbo].[trsp_SaveAVRSBackupParameters]
	@settings AS VARCHAR(MAX),
	@NetBiosSettings AS VARCHAR(MAX) = '''',
	@FTPSettings AS VARCHAR(MAX) = '''',
	@ExtDriveSettings AS VARCHAR(MAX) = ''''
	AS
	BEGIN
		
		UPDATE TREC_PARAMETROS
		SET par_valor = @settings
		WHERE par_id = 82

		--NetBios
		IF LEN(@NetBiosSettings) > 0
			BEGIN
		
				UPDATE TREC_PARAMETROS
				SET par_valor = @NetBiosSettings
				WHERE par_id = 83
				
			END

		--FTP	
		IF LEN(@FTPSettings) > 0
			BEGIN
		
				UPDATE TREC_PARAMETROS
				SET par_valor = @FTPSettings
				WHERE par_id = 84
				
			END

		--ExtDrive	
		IF LEN(@ExtDriveSettings) > 0
			BEGIN
		
				UPDATE TREC_PARAMETROS
				SET par_valor = @ExtDriveSettings
				WHERE par_id = 85
				
			END
			
	END'
	EXEC(@Sql)

	set @process = 'alter SP  - trsp_SaveAVRSExportParameters'
	set @sql='ALTER PROCEDURE [dbo].[trsp_SaveAVRSExportParameters]
	@export_mode AS INT,
	@netcred_id AS INT = -1,
	@net_user AS VARCHAR(100) = '''',
	@net_password AS VARCHAR(100) = '''',
	@net_sever AS VARCHAR(max) = '''',
	@net_path AS VARCHAR(max) = '''',
	@ftp_user AS VARCHAR(100) = '''',
	@ftp_password AS VARCHAR(100) = '''',
	@ftp_sever AS VARCHAR(max) = '''',
	@ftp_path AS VARCHAR(max) = '''',
	@ftp_port AS INT = -1,
	@ftp_protocol AS INT = -1,
	@time_export AS VARCHAR(20) = '''',
	@grabid_start AS INT = -1,
	@csv_log AS INT = -1,
	@delete_rec AS INT = -1,
	@export_format AS INT = 1
	AS
	BEGIN

	DECLARE @repo_Id AS INT

		-- Update FTP Parameters	

		IF @export_mode = 1
			BEGIN

				UPDATE TREC_PARAMETROS
				SET par_valor = @export_format
				WHERE
				par_id = 35

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_path
				WHERE
				par_id = 41

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_protocol
				WHERE
				par_id = 42

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_sever
				WHERE
				par_id = 43

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_user
				WHERE
				par_id = 44

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_password
				WHERE
				par_id = 45

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_port
				WHERE
				par_id = 46

				UPDATE TREC_PARAMETROS
				SET par_valor = @csv_log
				WHERE
				par_id = 50	

				UPDATE TREC_PARAMETROS
				SET par_valor = @export_mode
				WHERE
				par_id = 51

				UPDATE TREC_PARAMETROS
				SET par_valor = @delete_rec
				WHERE
				par_id = 57

				IF LEN( @time_export) > 0
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @time_export
						WHERE
						par_id = 33
					END
					
				IF @grabid_start <> -1
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @grabid_start
						WHERE
						par_id = 40
					
					END
			END
		ELSE
			BEGIN

				-- Update NetBios parameters

				UPDATE TREC_NETWORKCREDENTIALS
				SET
				[domain] = @net_sever,
				[user] = @net_user,
				[password] = @net_password
				WHERE
				id = @netcred_id

				UPDATE TREC_PARAMETROS
				SET par_valor = @export_format
				WHERE
				par_id = 35
					
				UPDATE TREC_PARAMETROS
				SET par_valor = @net_path
				WHERE 
				par_id = 36
					
				IF LEN( @time_export) > 0
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @time_export
						WHERE
						par_id = 33
					END
					
				IF @grabid_start <> -1
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @grabid_start
						WHERE
						par_id = 40
					END

				UPDATE TREC_PARAMETROS
				SET par_valor = @csv_log
				WHERE
				par_id = 50

				UPDATE TREC_PARAMETROS
				SET par_valor = @export_mode
				WHERE
				par_id = 51

				UPDATE TREC_PARAMETROS
				SET par_valor = @delete_rec
				WHERE
				par_id = 57

			END
	END'
	EXEC(@Sql)

		set @process = 'INSert TREC_PARAMETROS  - Stop Video'
	set @sql='if not exists(select * from TREC_PARAMETROS where par_id=72)
		INSERT INTO TREC_PARAMETROS VALUES (72,''Stop Video onDispositionApplied event'', ''0'', ''0 = Stop video onCallEnd event; 1 = Stop video onDispositionApplied event'' )
	'
	EXEC(@Sql)

	set @process = 'alter SP  - trsp_SaveAVRSExportParameters'
	set @sql='ALTER procedure [dbo].[ReportsMasterProcessAVRS] as

declare @dateStart datetime
declare @replicationName nvarchar(100)
declare @numOfReplications int
declare @repDelay int
declare @repStrDelay nvarchar(8)
declare @minReplication int

set nocount on

set @dateStart = getdate()
set @replicationName = ''''
set @numOfReplications = 0
set @repDelay = 0
set @repStrDelay = ''''
set @minReplication = 600

create table #replications ([name] nvarchar(100), flag bit)

insert into #replications
select [name], 0 as flag
from msdb.dbo.sysjobs
where [name] like ''%CCRecorderRIA- 0%''
and [name] like ''%CCenterRia%''
order by [name]

select @numOfReplications = count(*)
from #replications with(nolock)

set @repDelay = floor(cast(@minReplication as decimal) / cast(@numOfReplications as decimal))

set @repStrDelay =CONVERT(char(8), DATEADD(second, @repDelay, ''0:00:00''), 108) 

while(select count(*) from #replications with(nolock) where flag = 0) > 0
begin
	set rowcount 1
		select @replicationName = [name]
		from #replications with(nolock)
		where flag = 0
	set rowcount 0

	exec msdb.dbo.sp_start_job @job_name = @replicationName

	update #replications with(rowlock)
	set flag = 1
	where [name] = @replicationName

	waitfor delay @repStrDelay
end

drop table #replications

declare @lastTenMinuteFirst datetime
declare @lastTenMinuteSecond datetime
declare @id int
declare @publisher_reinit nvarchar(max)
declare @publisher_db_reinit nvarchar(max)
declare @publication_reinit nvarchar(max)
declare @upload_first_reinit nvarchar(max)

set @lastTenMinuteFirst = dateadd(minute,-10,dateadd(minute, datepart(minute, getdate()) / 10 * 10, dateadd(hour, datediff(hour, 0,getdate()), 0)))
set @lastTenMinuteSecond = dateadd(minute,10,@lastTenMinuteFirst)

create table #reinitmergepullsubscription(
id int not null identity,
publisher nvarchar(max) not null,
publisher_db nvarchar(max)not null,
publication nvarchar(max) not null,
upload_first nvarchar(max) not null,
[status] bit not null
)

insert into #reinitmergepullsubscription
select s.name, ma.publisher_db, ma.publication, ''false'', 0
from distribution.dbo.MSmerge_history mh
left outer join distribution.dbo.MSrepl_errors me
on (mh.error_id = me.id)
left outer join distribution.dbo.MSmerge_agents ma
on (mh.agent_id = ma.id)
left outer join master.sys.servers s
on (ma.publisher_id = s.server_id)
where mh.comments like ''%You must reinitialize the subscription (without upload)%''
and me.error_code = -2147199402
and mh.time >= @lastTenMinuteFirst
and mh.time < @lastTenMinuteSecond
and ma.subscriber_db = ''CCRecorderRIA''
order by mh.time desc

while (select count(*) from #reinitmergepullsubscription where [status] = 0) > 0
	begin
		set rowcount 1
		select @id = id, @publisher_reinit = publisher, @publisher_db_reinit = publisher_db, @publication_reinit = publication, @upload_first_reinit = upload_first 
		from #reinitmergepullsubscription
		where [status] = 0
		set rowcount 0

		EXEC sp_reinitmergepullsubscription @publisher = @publisher_reinit, @publisher_db = @publisher_db_reinit, @publication = @publication_reinit, @upload_first = @upload_first_reinit

		update #reinitmergepullsubscription
		set [status] = 1
		where id = @id
	end

drop table #reinitmergepullsubscription'
	EXEC(@Sql)



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