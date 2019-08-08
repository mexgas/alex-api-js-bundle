/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.38

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 39
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 38
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'CW-2703 Creacion de la tabla ccCallCost_Ria '
	set @sql = 'if not exists (select * from sys.tables where name = N''ccCallCost_RIA'')
		    begin
		        CREATE TABLE [dbo].[ccCallCost_RIA](
					[country_id] [smallint] NOT NULL,
					[tipoLlamada_id] [smallint] NULL,
					[cost_per_min] [float] NULL,
					[additional_min] [float] NULL
				) ON [PRIMARY]
		    end'

	exec (@sql)

	set @process = 'CW-2703 Creacion del indice de la tabla ccCallCost_Ria '
	set @sql = 'if not exists (select * from sys.indexes where name = N''PK_ccCallCost'' and object_id = OBJECT_ID(N''ccCallCost_RIA''))
			    begin
			        CREATE UNIQUE INDEX PK_ccCallCost ON ccCallCost_RIA (country_id,tipoLlamada_id)
			    end'

	exec (@sql)

		set @process = 'CW-2703 Llenado de la tabla ccCallCost_RIA'
		set @sql = 'if not exists (select * from ccCallCost_RIA)
begin
	insert into ccCallCost_RIA (country_id,tipoLlamada_id,cost_per_min,additional_min)
	select country_id,tipoLlamada_id,1,1 from cstoTipoLlamada
end'

		exec (@sql)

		set @process = 'CW-3226 update ccListaNegra set Hashtel=null'
		set @sql = 'update ccListaNegra set Hashtel=null where Hashtel is not null'
		exec (@sql)

		set @process = 'cw-3226 Drop index IX_ccListaNegra_I on ccListaNegra'
		set @sql = 'if exists (select * from sys.indexes where name = N''IX_ccListaNegra_I'' and object_id = OBJECT_ID(N''ccListaNegra''))
begin
    Drop index IX_ccListaNegra_I on ccListaNegra
end'
		exec (@sql)

		set @process = 'cw-3226 Drop index IX_ccListaNegra_II on ccListaNegra'
		set @sql = 'if exists (select * from sys.indexes where name = N''IX_ccListaNegra_II'' and object_id = OBJECT_ID(N''ccListaNegra''))
begin
    Drop index IX_ccListaNegra_II on ccListaNegra
end'
		exec (@sql)

		set @process = 'cw-3226 Alter COLUMN ccListaNegra.Hashtel'
		set @sql = 'if exists(select A.name,B.name from sys.columns A inner join  sys.types B on A.system_type_id=B.system_type_id
where A.name = N''Hashtel'' and Object_ID = Object_ID(N''ccListaNegra'') and B.name=''int'') begin
ALTER TABLE ccListaNegra ALTER COLUMN Hashtel bigint
select ''change''
end'
		exec (@sql)

		set @process = 'cw-3226 Alter COLUMN ccListaNegra.HashKey'
		set @sql = 'if exists(select A.name,B.name from sys.columns A inner join  sys.types B on A.system_type_id=B.system_type_id
where A.name = N''HashKey'' and Object_ID = Object_ID(N''ccListaNegra'') and B.name=''int'') begin
ALTER TABLE ccListaNegra ALTER COLUMN HashKey bigint
select ''change''
end'
		exec (@sql)

		set @process = 'cw-3226 CREATE index IX_ccListaNegra_I on ccListaNegra'
		set @sql = 'if not exists (select * from sys.indexes where name = N''IX_ccListaNegra_I'' and object_id = OBJECT_ID(N''ccListaNegra''))
begin
    CREATE index IX_ccListaNegra_I on ccListaNegra(idtipolista, Hashtel)
end
'
		exec (@sql)

		set @process = 'cw-3226 CREATE index IX_ccListaNegra_II on ccListaNegra'
		set @sql = 'if not exists (select * from sys.indexes where name = N''IX_ccListaNegra_II'' and object_id = OBJECT_ID(N''ccListaNegra''))
begin
    CREATE index IX_ccListaNegra_II on ccListaNegra([idtipolista], Hashtel, HashKey)
end'
		exec (@sql)

		set @process = 'cw-3226 Alter dbo.hashPhone '
		set @sql = 'ALTER FUNCTION [dbo].[hashPhone] (@phoneNumber varchar(30)) 
RETURNS bigint AS
BEGIN
  return convert(bigint,@phoneNumber) % 99999999999973
END
'
		exec (@sql)

		set @process = 'cw-3226 Alter dbo.hashList'
		set @sql = '
ALTER FUNCTION [dbo].[hashList] (@calKey varchar(255)) 
RETURNS bigint AS
BEGIN
declare @codigo varchar(max)
declare @hash bigint

set @codigo=''''
set @hash=0
declare @i int,@len int
select @i=1,@len=len(@calKey)
while @i<=@len begin
	select @codigo=@codigo+convert(varchar(max), ASCII(SUBSTRING(@calKey,@i,1)))
	
	if @i%5=0 begin
		set @hash=@hash+cast(@codigo as bigint)
		set @codigo=''''
	end	
	set @i=@i+1
end
if @codigo<>''''
set @hash=@hash+cast(@codigo as bigint)
return @hash % 99999999999973
END'
		exec (@sql)

		set @process = 'CW-3226 Cambia el tipo bigint  @hashCalKey bigint, @hashPhone BIGINT'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIADNCList] @phoneNumber AS VARCHAR(30), @idDNCList AS INTEGER, @tipoMov AS TINYINT, @calKey AS VARCHAR(20) = NULL
AS
DECLARE @hashCalKey bigint, @hashPhone BIGINT

IF @calKey IS NOT NULL
BEGIN
	SELECT @hashCalKey = dbo.hashList(@calKey)
END

IF @tipoMov = 1
BEGIN -- Inserta Lista Negra	
	EXEC ccsp_InsertDNCList @telephone = @phoneNumber, @ln_id = @idDNCList, @hashCalKey = @hashCalKey

	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	VALUES (@phoneNumber, 7, @idDNCList)
END

IF @tipoMov = 2
BEGIN -- Borra Lista Negra	
	SELECT @hashPhone = dbo.hashPhone(@phoneNumber)

	IF @hashCalKey IS NULL
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idDNCList
	END
	ELSE
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idDNCList
	END

	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	VALUES (@phoneNumber, 5, @idDNCList)
END

IF @tipoMov = 3
BEGIN -- Reemplaza Lista Negra
	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	SELECT telefono, ''4'', @idDNCList
	FROM cclistanegra
	WHERE idtipolista = @idDNCList

	DELETE
	FROM cclistanegra
	WHERE idtipolista = @idDNCList
END
'
	exec (@sql)

set @process = 'CW-3226 Cambia el tipo bigint  @hashCalKey bigint, @hashPhone BIGINT'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey bigint=null
AS

declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)

insert into cclistanegra(telefono,idtipolista,HashKey) values(@telephone, @ln_id,@hashCalKey)

CREATE TABLE [dbo].[#mycamps] (
	[campsid] [int] NULL
	)

CREATE UNIQUE INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select cam_id from Camplistanegra where idtipolista = @ln_id

CREATE TABLE [dbo].[#myprincipaltemp](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE UNIQUE INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltemp]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltemp]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltemp]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltemp]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltemp]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltemp]([cal_telefono5]) 

CREATE TABLE [dbo].[#mytemp](
	[callout_id] [int] NULL, 
	[telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL
	)

CREATE UNIQUE INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) 

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @tel = dbo.completa(@telephone, @pais, @ld)

declare @Sql nvarchar(max)

if @hashCalKey is not null or @hashCalKey > 0
begin
	set @Sql = ''insert into [#myprincipaltemp] '' +
	''SELECT callout_id as callout_id, cam_id,''''3'''','' + cast(@ln_id as nvarchar) + '' as idtipolista , [cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5] '' +
	''FROM [ccoCallsOutSource] a with(nolock) inner join #mycamps b on (a.cam_id = b.campsid) '' +
	''WHERE dbo.hashList(cal_Key) = '' + cast(@hashCalKey as nvarchar) +
	'' and  cal_fechadial > dateadd(dd,-30,getdate())''
end
else begin
	set @Sql = ''insert into [#myprincipaltemp] '' +
	''SELECT callout_id as callout_id, cam_id,''''3'''','' + cast(@ln_id as nvarchar) + '' as idtipolista , [cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5] '' +
	''FROM [ccoCallsOutSource] a with(nolock) inner join #mycamps b on (a.cam_id = b.campsid) '' +
	''WHERE ('''''' + @tel + '''''' IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) '' +
	''or right('''''' + @tel + '''''',10) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) '' +
	''or right('''''' + @tel + '''''',11) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5])) '' +
	''and  cal_fechadial > dateadd(dd,-30,getdate())''
end

EXEC(@Sql)

if (select count(*) from #myprincipaltemp with(nolock)) > 0
	begin
		/******************/
		/*** Telefono 1 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where (cal_telefono = @tel or cal_telefono = right(@tel, 10) or cal_telefono = right(@tel, 11))

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono = wt.cal_telefono
			and rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
								 + cs.cal_telefono3 + ''         ''
								 + cs.cal_telefono4 + ''         ''
								 + cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
												+ cs.cal_telefono3 + ''         ''
												+ cs.cal_telefono4 + ''         ''
												+ cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono1 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 2 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono2,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where (cal_telefono2 = @tel or cal_telefono2 = right(@tel, 10) or cal_telefono2 = right(@tel, 11))

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono2= wt.cal_telefono 
			and rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
								 + cs.cal_telefono4 + ''         ''
								 + cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
												+ cs.cal_telefono4 + ''         ''
												+ cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono2= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono2 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono2 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 3 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono3,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where (cal_telefono3 = @tel or cal_telefono3 = right(@tel, 10) or cal_telefono3 = right(@tel, 11))

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono3= wt.cal_telefono  
			and  rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
								  + cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
												+ cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono3= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono3 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono3 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 4 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono4,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where (cal_telefono4 = @tel or cal_telefono4 = right(@tel, 10) or cal_telefono4 = right(@tel, 11))

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono4= wt.cal_telefono 
			and rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono4= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono4 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono4 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 5 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono5,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where (cal_telefono5 = @tel or cal_telefono5 = right(@tel, 10) or cal_telefono5 = right(@tel, 11))

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono5= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono5 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono5 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
		end
	end

drop table [#myprincipaltemp]
drop table [#mytemp]
drop table [#mycamps]		
'
	exec (@sql)	

		set @process = 'cw-3226 CW Update ccListaNegra Hashtel JOb'
		set @sql = 'USE [msdb]


if exists(select * from msdb.dbo.sysjobs_view where name=N''CW Update ccListaNegra Hashtel'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW Update ccListaNegra Hashtel'', @delete_unused_schedule=1

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Update ccListaNegra Hashtel'', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp]    Script Date: 05/06/2019 10:12:59 a. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run sp'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''if exists(select * from ccListaNegra where Hashtel is null) begin
    update top (20000) ccListaNegra set  Hashtel=dbo.hashPhone(telefono) where Hashtel is null
end
else begin 
    EXEC msdb.dbo.sp_delete_job @job_name=N''''CW Update ccListaNegra Hashtel'''', @delete_unused_schedule=1
end'', 
		@database_name=N''CCenterRia'', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''CW Update ccListaNegra Hashtel schedule'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20041022, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		exec (@sql)
		

		

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
