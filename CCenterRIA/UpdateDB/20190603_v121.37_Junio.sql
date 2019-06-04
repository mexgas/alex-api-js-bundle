/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.35

Se agrega la tarea
cw-2915
cw-3001

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
SET @versionfix = 37
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 36
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'Galatea Admin CW CW-2976 check exist ccspGalateaGetAgentCounters '
		SET @Sql = '   
			if exists (select * from sys.procedures where name = N''ccspGalateaGetAgentCounters'')
			begin
				drop procedure ccspGalateaGetAgentCounters
			end
		 '

		EXEC (@Sql)




		SET @process = 'Galatea Admi CW-2976 add ccspGalateaGetAgentCounters '
		SET @Sql = '   
		create procedure ccspGalateaGetAgentCounters
		@type as int, @sup_id as int = 0 as
		set nocount on
		if @type = 1
		    begin
		        ;
		    WITH TableUserAgent (userId)
		    AS
		    (
		        select distinct wgAgt.User_id as userId --,usr.login 
		        from ccriaworkgroupusers wgAdmin
		        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
		        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
		        where 
		        wgAdmin.User_id=@sup_id
		    )


		        select a.user_id, a.login as UserName, CONCAT(a.Nombres, '' '', a.ApellidoPaterno, '' '',a.ApellidoMaterno) as Name
		        from ccusers a (nolock)--, ccGenViewRelsSupsAgent b
		        inner join TableUserAgent b on a.User_id=b.userId       
		    end

		set nocount on
		 '

		EXEC (@Sql)

	
		SET @process = 'cw-2915 add kill list setting'
		SET @Sql = 'IF NOT EXISTS (
		SELECT setting_id
		FROM ccSettings
		WHERE setting_id = 215
		) 
BEGIN
	INSERT INTO ccSettings (
		setting_id
		,valor
		,descripcion
		,STATUS
		,Tipo
		,detalle
		,description
		,bLoadSettings
		,validate
		)
	VALUES (
		215
		,''48''
		,''Tiempo (horas) que un teléfono permanecerá en la lista negra predeterminada''
		,0
		,''ADM''
		,''Tiempo en horas que estara un numero en DNC default/KillList''
		,''Time (hours) that a phone number will remain in the default DNC/kill list''
		,0
		,''.*''
	)
END'
		EXEC (@Sql)

		set @process = 'cw-2915 create dnc kill list'
		set @sql = 'if not exists(select Tipolista from ccTiposListaNegra where Tipolista = ''default/KillList'') 
begin
	insert into ccTiposListaNegra (Tipolista, Status) values(''default/KillList'', 1)
end'
		exec (@sql)

		set @process = 'cw-2915 create table cc_killList table'
		set @sql = 'if exists (select * from sys.tables where name = N''cc_KillList'')
    begin
       CREATE TABLE [dbo].[cc_KillList](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[hashTel] [int] NOT NULL,
	[hashkey] [int] NULL,
	[id_tipoLista] [int] NOT NULL,
	[date] [datetime] NOT NULL
) ON [PRIMARY]
    end'
		exec (@sql)
		
		set @process = 'cw-2915 drop sp'
		set @sql = 'if exists (select * from sys.procedures where name = N''cc_DNCKillList'')
    begin
        DROP PROCEDURE cc_DNCKillList;
    end'

		exec (@sql)

		set @process = 'cw-2915 create sp'
		set @sql = 'CREATE PROCEDURE [dbo].[cc_DNCKillList]
	
AS
BEGIN
	DECLARE @minTime AS INT 
	declare @killListID int = (SELECT idtipolista FROM ccTiposListaNegra WHERE Tipolista = ''default/KillList'')
	declare @killListSetting int = (select status from ccSettings where setting_id = 215)

	if(@killListSetting = 1)
	begin
		select @minTime = valor from ccSettings where setting_id = 215

	create table #temp(
		hashtel int not null
	)
	insert into #temp
	select a.hashtel from cc_killlist a inner join ccListaNegra b 
	on a.Hashtel = b.hashTel 
	WHERE datediff(HH, [date],getdate()) > @minTime

	delete from cc_KillList where hashTel in (select hashtel from #temp)
	delete from ccListaNegra where Hashtel in (select hashtel from #temp) and idtipolista = @killListID

	drop table #temp
	end
END'
		exec (@sql)

		set @process = 'cw-2915 modify sp ccsp_AgentUpdateCallCALIF'
		set @sql = 'ALTER procedure [dbo].[ccsp_AgentUpdateCallCALIF]
@IDCall int,
@calif_id smallint,
@TipoCall smallint,
@Origin int=0,
@cal_key varchar(20)=null,
@callOutId int=0,
@subId smallint=0

as
set nocount on
declare @RecicleSIC tinyint, @Reprogram tinyint, @DateNewDial smalldatetime, @idTipoLista int, @autoCB tinyint, @tel varchar(30), @camp int, @iddncList as int
declare @userid int
select @RecicleSIC=valor FROM ccSettings WHERE setting_id=60
select @RecicleSIC=IsNull(@RecicleSIC, 0)

 declare @hashTel int
 declare @killListID int = (SELECT idtipolista FROM ccTiposListaNegra WHERE Tipolista = ''default/KillList'')
 declare @killListSetting int = (select status from ccSettings where setting_id = 215)

if @TipoCall=1
 begin
	Update ccCallsIN Set calif_id=@calif_id, cal_origin_id=@Origin, cal_key=isnull(@cal_key, cal_key),
	califSub_id=case @subId when 0 then null else @subId end Where cal_id=@IDCall

	if exists(select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 0 and calif_id=@calif_id)
	 begin
		select @tel=dbo.Completa_ListaNegra(ci.cal_ANI), @iddncList = cbl.idTipoLista

		from ccCallsIN ci with (index (PK_ccCallsIn))
		 join cccalifblacklist as cbl on ci.calif_id=cbl.calif_id
		where ci.cal_id=@idCall and left(dbo.Completa_ListaNegra(ci.cal_ANI),1)<>''E'' and cbl.tipo=0

		if @tel is not null and @iddncList is not null begin
			--insert ccListaNegra
			insert into cclistanegra (telefono, idtipolista) values(@tel,@iddncList)
			--insert cc_killlist
			if(@killListSetting = 1 and @iddncList = @killListID) -- verifies if kill list setting is active and if the list_id matches killList id
			begin
			    set @hashTel = convert(bigint,@tel) % 127499997
				if not exists (select hashtel from cc_KillList where hashTel = @hashTel)
				begin
				 insert into cc_KillList (hashTel,id_tipoLista, date) values(@hashTel, @iddncList, GETDATE())
				end
			end

			insert ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
			select dbo.Completa_ListaNegra(ci.cal_ANI), cbl.idTipoLista, ci.Inbound_id, getdate(), ci.dni_id, 6
			from ccCallsIN ci with (index (PK_ccCallsIn)) join cccalifblacklist cbl on ci.calif_id=cbl.calif_id
			where ci.cal_id=@idCall and left(dbo.Completa_ListaNegra(ci.cal_ANI),1)<>''E'' and cbl.tipo=0
		end
	 end

	return(0)
 end

if @TipoCall=2
 begin
 	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	select @autoCB=autocallback from ccTipoCalifSubout where califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	if @autoCB is null
	 begin
		select @autoCB = autocallback from cctipocalifout where calif_id = @calif_id
	 end

	if @autoCB = 1
	begin
		select @callOutId=callout_id, @camp=cam_id,@userid=user_id from ccocallsout where Cal_id=@IDCall
		select @DateNewDial=dateadd(mi,t_autoCB,getdate()) from cccamps cam where cam.cam_id = @camp

		exec ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
	end

	Update ccoCallsOUT Set calif_id=@calif_id, califSub_id=case @subId when 0 then null else @subId end Where cal_id=@IDCall

	if exists(select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 1 and calif_id=@calif_id)
	and not exists (select co.cal_telefono from ccoCallsOut co with (index (PK_ccoCallsOut))
	join ccListaNegra bl on dbo.Completa_ListaNegra(co.cal_telefono)=bl.telefono or co.cal_telefono=bl.telefono where co.cal_id=@idCall
	and bl.idtipolista in (select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 1 and calif_id=@calif_id))
	 begin
		select @tel=dbo.Completa_ListaNegra(co.cal_telefono), @iddncList = cbl.idTipoLista
		from ccoCallsOut co with (index (PK_ccoCallsOut)) join cccalifblacklist cbl on co.calif_id=cbl.calif_id
		where co.cal_id=@idCall and left(dbo.Completa_ListaNegra(co.cal_telefono),1)<>''E'' and cbl.tipo=1


		if @tel is not null and @iddncList is not null begin
			exec ccsp_InsertDNCList @tel, @iddncList

			if(@killListSetting = 1 and @iddncList = @killListID)
			begin
			    set @hashTel = convert(bigint,@tel) % 127499997
				if not exists (select hashtel from cc_KillList where hashTel = @hashTel)
				begin
				 insert into cc_KillList (hashTel,id_tipoLista, date) values(@hashTel, @iddncList, GETDATE())
				end
			end

			insert ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
			select dbo.Completa_ListaNegra(co.cal_telefono), cbl.idTipoLista, co.cam_id, getdate(), co.callout_id, 6
			from ccoCallsOut co with (index (PK_ccoCallsOut)) join cccalifblacklist cbl on co.calif_id=cbl.calif_id
			where co.cal_id=@idCall and left(dbo.Completa_ListaNegra(co.cal_telefono),1)<>''E'' and cbl.tipo=1
		end
	 end

	if @RecicleSIC=1
	 begin
	 	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
		select @Reprogram=CanReprogram from ccTipoCalifSubout where califSub_Id = @subId

		-- Si no tiene subcalificacion toma la de la calificacion
		if @Reprogram is null
		 begin
			select @Reprogram=CanReprogram from ccTipoCalifOUT where calif_id=@calif_id
		 end

		if @callOutId=0
			select @callOutId=callout_id from ccocallsout where Cal_id=@IDCall

		Update ccoWorkingTable Set calif_id=@calif_id,
		 cal_status=case @Reprogram when 0 then 3 else cal_status end
		Where callout_id=@callOutId

	 end
	declare @keepDial bit
	declare @finishPreview smallint
	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	select @keepDial=keepDial from ccTipoCalifSubout where califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	if @keepDial is null
	 begin
		select @keepDial=keepDial from ccTipoCalifout where calif_id = @calif_id
	 end

	select @finishPreview=isnull(finishPreview,0) from ccTipoCalifout where calif_id = @calif_id

	if @keepDial=1
	 begin
		update ccologdials set TipoDialingMode=dbo.fn_getDialingMode(@IDCall, 3, 0, @camp)
		where logDial_id in (select top 1 L.logDial_id from
			ccoLogDials L with(index(IX_ccoLogDials_2), nolock)
			 join ccoCallsOut O with(index(PK_ccoCallsOut), nolock)
			 on L.callout_id = O.callout_id where O.cal_id=@IDCall
			order by L.logDial_id desc)
	 end

	select @keepDial, @finishPreview
	return(0)
 end

set nocount off'

		exec (@sql)


		set @process = 'cw-2915 delete  job dnckillList'
		set @sql= 'USE [msdb]
if exists (select * from msdb.dbo.sysjobs_view where name = N''DNCKillList'')
    begin
        exec msdb.dbo.sp_delete_job @job_name = N''DNCKillList'', @delete_unused_schedule=1
    end
/****** Object:  Job [DNCKillList]    Script Date: 03/06/2019 12:35:07 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 03/06/2019 12:35:07 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''DNCKillList'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Deletes from cc_KillList table according to an specific time (setting 215)'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ccKillList]    Script Date: 03/06/2019 12:35:07 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''ccKillList'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec cc_DNCKillList'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''ccKillList'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20190531, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
'

		exec (@sql)

		set @process = 'cw-3001 alter procedure getUnavailableTimes'
		set @sql = '
ALTER PROCEDURE [dbo].[ccsp_GetUnavailableTypes] @action INT
	,@startDate DATETIME =  null
	,@endDate DATETIME = null
	,@unavailable_id VARCHAR(300) = null
AS
IF (@action = 0)
BEGIN
	SELECT TipoNotReady_id AS [unavailable_id]
		,Descripcion AS [description]
		,Time_Acum AS [MaxTime]
		,Time_xEv AS [MaxTimePerEvent]
		,Pas_Sup AS [AdminPw]
		,NextStatus AS [NextStatus]
		,IsSup AS [AdminOnly]
		,StatusTipoNotReady AS [UnavailableStatus]
	FROM ccTipoNotReady
END

IF (@action = 1)
BEGIN
	DECLARE @tabla TABLE (notReadyId INT PRIMARY KEY)

	INSERT INTO @tabla
	SELECT value
	FROM dbo.fn_RIASplitDelimited(@unavailable_id, '','')
	
	SELECT user_id, sum(tstatus)
	FROM ccLogAgentesNotReady A WITH (NOLOCK)
	INNER JOIN @tabla B ON A.TipoNotReady_id = B.notReadyId
	WHERE fecha >= @startDate
		AND fecha <= @enddate
	GROUP BY user_id
END'

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
