/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2024/07/04
Description: KR140000
Database: CCenterRia
Required version: 126.6
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 7
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end
IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END
IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN
    BEGIN TRY
    	
	--------------------------------------------------BEGIN MACL--------------------------------------------------------
	SET @process = 'KR140003 - Tabla nueva en BD de Reporte de Detalle de Marcación'
	SET @sql = '
IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = ''ccoLogDialsData'')
BEGIN
	CREATE TABLE ccoLogDialsData(
		logDial_id INT NOT NULL PRIMARY KEY,
		callout_id INT NOT NULL,
		Data1 VARCHAR(255) NOT NULL,
		Data2 VARCHAR(255) NOT NULL,
		Data3 VARCHAR(255) NOT NULL,
		Data4 VARCHAR(255) NOT NULL,
		Data5 VARCHAR(255) NOT NULL,
		callDate DATETIME NOT NULL
	)

	CREATE INDEX IX_ccoLogDialsData_logDial_id ON ccoLogDialsData (logDial_id)
	CREATE INDEX IX_ccoLogDialsData_callout_id ON ccoLogDialsData (callout_id)
	CREATE INDEX IX_ccoLogDialsData_callDate ON ccoLogDialsData (callDate)
END'
	EXEC(@sql)

	SET @process = 'KR140004 - Tabla nueva en BD de Reporte de Detalle de llamadas contestadas'
	SET @sql = '
IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = ''ccoCallsOutData'')
BEGIN
	CREATE TABLE ccoCallsOutData(
		cal_id INT NOT NULL PRIMARY KEY,
		callout_id INT NOT NULL,
		Data1 VARCHAR(255) NOT NULL,
		Data2 VARCHAR(255) NOT NULL,
		Data3 VARCHAR(255) NOT NULL,
		Data4 VARCHAR(255) NOT NULL,
		Data5 VARCHAR(255) NOT NULL,
		callDate DATETIME NOT NULL
	)

	CREATE INDEX IX_ccoCallsOutData_cal_id ON ccoCallsOutData (cal_id)
	CREATE INDEX IX_ccoCallsOutData_callout_id ON ccoCallsOutData (callout_id)
	CREATE INDEX IX_ccoCallsOutData_callDate ON ccoCallsOutData (callDate)
END'
	EXEC(@sql)

	SET @process = 'KR140000 - Se crea SP ccsp_UpdateDataCall para actualizar datos de la llamada en ccoCallsOutSource, ccoCallsOutData y ccoLogDialsData'
	SET @sql = '
CREATE OR ALTER PROCEDURE [dbo].[ccsp_UpdateDataCall]
@option int,
@data1 varchar(255) = '''',
@data2 varchar(255) = '''',
@data3 varchar(255) = '''',
@data4 varchar(255) = '''',
@data5 varchar(255) = '''',
@calloutId int,
@callId int
AS
BEGIN

	IF @option = 1
	BEGIN
		DECLARE @logDial_id int;
		--Update ccoCallsOutSource
		UPDATE ccoCallsOutSource SET 
		Dato1 = @data1,
		Dato2 = @data2,
		Dato3 = @data3,
		Dato4 = @data4,
		Dato5 = @data5
		WHERE callout_id = @calloutId

		--Insert if not exists or update on ccoCallsOutData
		IF NOT EXISTS(SELECT 1 FROM ccoCallsOutData WHERE cal_id = @callId)
		BEGIN
			INSERT INTO ccoCallsOutData(cal_id, callout_id, Data1, Data2, Data3, Data4, Data5, callDate) VALUES(@callId, @calloutid, @data1, @data2, @data3, @data4, @data5, GETDATE())
		END
		ELSE BEGIN
			UPDATE ccoCallsOutData SET 
			Data1 = @data1,
			Data2 = @data2,
			Data3 = @data3,
			Data4 = @data4,
			Data5 = @data5
			WHERE cal_id = @callId
		END


		SELECT @logDial_id = logDial_id FROM ccoLogDials where cal_id = @callId
		PRINT @logDial_id
		IF(@logDial_id IS NOT NULL)
		BEGIN
			UPDATE ccoLogDialsData SET 
			Data1 = @data1,
			Data2 = @data2,
			Data3 = @data3,
			Data4 = @data4,
			Data5 = @data5
			WHERE logDial_id = @logDial_id
		END
		
	END
END'
	EXEC(@sql)

	SET @process = 'KR140002 - se actualiza sp ccsp_DLRInsertCall para insertar datos a la tabla ccoCallsOutData cuando el sistema hace una llamada'
	SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_DLRInsertCall]
@callout_id int,
@cam_id smallint,
@cal_Key varchar(20),
@cal_Telefono varchar(14),
@Puerto smallint,
@logDial_id int=0
AS
declare @fecha as datetime
declare @cal_id as int

select @fecha=getdate()
INSERT ccoCallsOUT ( callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id ) --''Status 6=Pide Agente
  VALUES ( @callout_id, @cam_id, @cal_Key, @cal_Telefono, @Puerto,  @fecha, 6 )

select @cal_id = scope_identity()

INSERT INTO ccoCallsOutData(cal_id, callout_id, Data1, Data2, Data3, Data4, Data5, callDate)  
SELECT @cal_id, @callout_id, ISNULL(Dato1, ''''), ISNULL(Dato2, ''''), ISNULL(Dato3, ''''), ISNULL(Dato4, ''''), ISNULL(Dato5, ''''), @fecha
FROM ccoCallsOutSource where callout_id = @callout_id

insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo from ccRIACampEspWG wg with(nolock)
where wg.Tipo=1 and wg.idcampesp=@cam_id


exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=6


select @cal_id as cal_id'
	EXEC(@sql)

	SET @process = 'KR140002 - se guarda información a la tabla ccoCallsOutData'
	SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_AGENTInsertCallOut]
    @cam_id smallint,
    @cal_Key varchar(40),
    @cal_Telefono varchar(30),
    @user_id int,
    @cal_extension varchar(7),
    @sData varchar(255) = '''', --HLAS para guardar notas de la llamada
    @existCallOut as int = 0,
    @callmode as smallint = 0,
    @odbc AS BIT = 0
    AS
    set 
    nocount on
    declare @fecha as datetime, @callout_id as int, @cal_id as int, @calloutMaxTime as int
    select @fecha=getdate()
    declare @dialPrefix integer
    select @dialPrefix = valor from ccSettings where setting_id = 202

    if @callmode = 1 begin
        INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
        select @existCallOut, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 0, @cal_extension, @odbc
        select @cal_id = scope_identity()

		INSERT INTO ccoCallsOutData(cal_id, callout_id, Data1, Data2, Data3, Data4, Data5, callDate)  
		SELECT @cal_id, @existCallOut, ISNULL(Dato1, ''''), ISNULL(Dato2, ''''), ISNULL(Dato3, ''''), ISNULL(Dato4, ''''), ISNULL(Dato5, ''''), @fecha
		FROM ccoCallsOutSource where callout_id = @existCallOut

exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=11

        insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
        select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
        from ccRIACampEspWG wg 
        where wg.tipo = 1 and wg.idcampesp =@cam_id

        select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
        select @existCallOut as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
      return(0)
    end

    if @existCallOut=0  begin
        declare @prefijoMarcacion varchar(100) 
        set @prefijoMarcacion = ''''
        declare @LasCallKey varchar(20)
        set @LasCallKey = @cal_Key
        declare @settingCallKey as int
        select @settingCallKey = valor from ccSettings where setting_id = 194
  
        if(@settingCallKey = 1) begin
            if (@cal_Key='''' or @cal_Key is null) begin   
                select top 1 @LasCallKey=cal_Key from ccoCallsOut where cam_id=@cam_id and cal_Inicio>=convert(datetime,getdate()) and cal_manual=0 order by cal_id desc
                set @cal_Key= @LasCallKey
            end
        end

        if @dialPrefix = 1 and len(@cal_telefono)>20
            begin
                set @prefijoMarcacion = LEFT(@cal_telefono ,len(@cal_telefono)-10)
                set @cal_telefono = RIGHT(@cal_telefono,10)     
            end
        else 
            begin
                set @prefijoMarcacion =''''          
            end
    
        INSERT ccocallsoutsource (cal_key, cam_id, cal_telefono, cal_status, user_id, cal_fechaDial, dato1,dialPrefix)
        select @cal_Key, @cam_id, substring(@cal_Telefono, 1, 19), 6, @user_id, @fecha, @sData,@prefijoMarcacion
        select @callout_id = scope_identity()

        INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
        select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension, @odbc
        select @cal_id = scope_identity()

		INSERT INTO ccoCallsOutData(cal_id, callout_id, Data1, Data2, Data3, Data4, Data5, callDate)  
		SELECT @cal_id, @callout_id, ISNULL(Dato1, ''''), ISNULL(Dato2, ''''), ISNULL(Dato3, ''''), ISNULL(Dato4, ''''), ISNULL(Dato5, ''''), @fecha
		FROM ccoCallsOutSource where callout_id = @callout_id

    exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=11
     end

    else begin --@existCallOut<>0
        Update ccocallsoutsource set cam_id=@cam_id, cal_telefono=substring(@cal_Telefono, 1, 19), dato1=@sData where callout_id = @existCallOut    
        Update ccocallsout set cam_id=@cam_id, cal_telefono=@cal_Telefono where callout_id = @existCallOut
    
        set @callout_id = @existCallOut

        select top 1 @cal_id=cal_id from ccocallsout where callout_id = @callout_id order by cal_id desc
    
        if exists(select * from ccoLogDials where cal_id=@cal_id) begin
            INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension, cal_odbc) --''''Status 11=Iniciada
            select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension, @odbc
            select @cal_id = scope_identity()

			INSERT INTO ccoCallsOutData(cal_id, callout_id, Data1, Data2, Data3, Data4, Data5, callDate)  
			SELECT @cal_id, @callout_id, ISNULL(Dato1, ''''), ISNULL(Dato2, ''''), ISNULL(Dato3, ''''), ISNULL(Dato4, ''''), ISNULL(Dato5, ''''), @fecha
			FROM ccoCallsOutSource where callout_id = @callout_id

        exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=11
        end
     
     end
    
    insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
    select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
    from dbo.ccRIACampEspWG wg 
    where wg.tipo = 1 and wg.idcampesp =@cam_id


    select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
    select @callout_id as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
    return(0)
set nocount off'
	EXEC(@sql)

	SET @process = 'KR140001 - se actualiza sp ccsp_DLRSaveDialResult para insertar los datos a la tabla ccoLogDialsData'
	SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_DLRSaveDialResult] 
                @callout_id INT, @cam_id SMALLINT, @tipoResDial_id TINYINT, @Telefono VARCHAR(30), @Puerto SMALLINT,
                @tDialing TINYINT= 0, @tBusy SMALLINT= 0, @call_id INT= 0, @answerbit BIT= NULL, @tAnswerBit SMALLINT= 0,
                @canceledNoAgents BIT= 0, @disconnectCause VARCHAR(250)= '''', @cal_key VARCHAR(40)= '''', @call_TS VARCHAR(15)='''',
                @ani varchar(32)=''''
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tNow AS DATETIME, @RecicleSIC TINYINT;
    DECLARE @logDial_id INT;
    DECLARE @tAnswerBitFinal AS DATETIME;
	DECLARE @MaxCal_id INT;
    DECLARE @tTotal SMALLINT;

    SELECT @RecicleSIC = ISNULL(valor, 0)
    FROM ccSettings
    WHERE setting_id = 60;

    SELECT @tTotal = @tDialing + @tAnswerBit;

    SELECT @tNow = GETDATE();

    SELECT @tAnswerBitFinal = DATEADD(ss, -@tAnswerBit, @tNow);


-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
IF @call_id > 0 AND @tipoResDial_id = 1 and @cal_key = ''''
    BEGIN
    SELECT @cal_key = cal_key
    FROM ccoCallsOutSource WITH(NOLOCK)
    WHERE @callout_id = callout_id;         
END;

IF @call_id > 0 AND @tipoResDial_id = 1
BEGIN
        INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
        TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id, ani )
               SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
               ''000000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.
               fnGetTipoLlamada( @Telefono ), @ani;
    END;
         ELSE
    BEGIN
        INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
        TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id, ani )
               SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
               ''000000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(
               @Telefono ), @ani;
    END;

    SELECT @logDial_id = SCOPE_IDENTITY();
	IF NOT EXISTS(SELECT 1 FROM ccoLogDialsData where logDial_id = @logDial_id)
	BEGIN
		INSERT INTO ccoLogDialsData(logDial_id, callout_id, Data1, Data2, Data3, Data4, Data5, callDate)  
		SELECT @logDial_id, @callout_id, ISNULL(Dato1, ''''), ISNULL(Dato2, ''''), ISNULL(Dato3, ''''), ISNULL(Dato4, ''''), ISNULL(Dato5, ''''), @tNow
		FROM ccoCallsOutSource where callout_id = @callout_id
	END

    IF @RecicleSIC = 1
    BEGIN
        UPDATE ccoWorkingTable WITH(ROWLOCK)
          SET tipoResDial_id = @tipoResDial_id
        WHERE callout_id = @callout_id;
    END;

    -- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
IF @call_id > 0 AND @tipoResDial_id = 1
    BEGIN
        UPDATE ccoCallsOut WITH(ROWLOCK)
    SET cal_puerto = @Puerto, cal_manual = CASE WHEN cal_manual = 1 THEN 2 ELSE cal_manual END
    WHERE cal_id = @call_id AND cal_puerto = 0;

        EXEC ccsp_CstoCalculaCosto @call_id;
    END;

    -- inserta informacion para reportes de workgroup
    INSERT INTO ccRIAWorkGroup_logDial_id( IDWG, logDial_id, cam_id, TIMESTAMP )
           SELECT IDWG, @logDial_id, IdCampEsp, GETDATE()
           FROM ccRIACampEspWG
WHERE tipo = 1 AND IdCampEsp = @cam_id;

    -- Guarda configuracion de TipoDialingMode
    UPDATE ccoLogDials WITH(ROWLOCK)
      SET TipoDialingMode = dbo.fn_getDialingMode( @call_id, 0, @logDial_id, @cam_id )
    WHERE logDial_id = @logDial_id;
    SET NOCOUNT OFF;
END;

    SELECT @logDial_id as LogDialId'
	EXEC(@sql)

	SET @process = 'KR140000 - se actualiza el job CW Delete old records para eliminar los datos de ccoLogDialsData y ccoCallsOutData'
	SET @sql = '
USE [msdb]
if exists(select * from  [msdb].[dbo].[sysjobs] AS [sJOB] where [name]=N''CW Delete old records'') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N''CW Delete old records'', @delete_unused_schedule=1
end
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''Nuxiba'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''Nuxiba''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Delete old records'', 
		@enabled=1, 
		@notify_level_eventlog=2,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''No description available.'', 
		@category_name=N''Nuxiba'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run sp'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0,  @subsystem=N''TSQL'', 
		@command=N''/***********************************************/
-- Delete Old Records New Version Febrero 2016 --
/***********************************************/
set nocount on

declare @idSqlCmd int
declare @sqlCmd nvarchar(max)
declare @days int

set @idSqlCmd = 0
set @sqlCmd  =''''''''
set @days = 30

create table #sqlCmdDeleteOldRecords(
idSqlCmd int identity primary key,
sqlCmd nvarchar(max) not null,
[status] int not null,
isReplicated bit not null
)

create table #ccoCallsOutSourceIds(
callout_id int not null primary key
)

insert into #ccoCallsOutSourceIds (callout_id)
select callout_id
from ccoCallsOutSource
where cal_fechadial < dateadd(dd, -@days, getdate())

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccBorrardasReciclaje'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccLogCampsAgentesDia'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table cclogInfo'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''truncate table ccUploadTemporal'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogReciclaje where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccPosicionCamps where Fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccPosicionEspecialidad where Fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAlog where operationDate < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRiaChat_log where fecha_chat < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIALogAgentesNotReady where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAWorkGroup_logDial_id where timestamp < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete xxclientehistorial where fechaAct < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccCallsIn where cal_Inicio < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete cccallsreject where cal_inicio < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesDia where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesDia_Dialog where fecha_Dialog < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogAgentesNotReady where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogLogin where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccLogtransfers where fechaFin < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccriachats where chatDate < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccRIAWorkGroup_Calid where timestamp < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ivrcallsin where date < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ivroptions where date < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

/******************************************************************/
/* Delete by date because rows in ccoLogDials > ccoCallsOutSource */
/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoLogDials where fecha < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoLogDialsData where callDate < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoCallsOutData where callDate < dateadd(dd, -'''' + cast(@days as nvarchar(max)) + '''', getdate())'''', 0, 1)

/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete cchistoriallistanegra from cchistoriallistanegra as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoWorkingTable from ccoWorkingTable as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccocallbacks from ccocallbacks as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoCallsOut from ccoCallsOut as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoLogDials from ccoLogDials as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (''''delete ccoCallsOutSource from ccoCallsOutSource as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id'''', 0, 1)

while (select count(*) from #sqlCmdDeleteOldRecords where [status] = 0 ) > 0
	begin
		set rowcount 1
			select @idSqlCmd = idSqlCmd, @sqlCmd = SqlCmd from #sqlCmdDeleteOldRecords where [status] = 0 order by idSqlCmd
		set rowcount 0

		exec(@sqlCmd)

		WAITFOR DELAY ''''00:00:01''''

		while(SELECT count(*)
				FROM sys.dm_exec_requests a
				INNER JOIN sys.dm_exec_connections b
				ON a.session_id = b.session_id
				INNER JOIN sys.dm_exec_sessions c
				ON c.session_id = a.session_id
				CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d
				WHERE a.session_id > 50
				AND a.session_id = @@SPID
				and d.text = @sqlCmd) > 0
			begin
				WAITFOR DELAY ''''00:00:01''''
			end

		update #sqlCmdDeleteOldRecords
		set [status] = 1
		where idSqlCmd = @idSqlCmd
	end

drop table #sqlCmdDeleteOldRecords
drop table #ccoCallsOutSourceIds'',
		@database_name=N''CCenterRia'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Tuesday, Thursday and Saturday at 3:00 am'', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=84, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
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
	EXEC(@sql)
	-------------------------------------------------- End MACL -----------------------------------------------------------------------------------
 	
        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)
        COMMIT TRAN
    END TRY
    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()
        RAISERROR (@errorGenerated, 11, 1)
        ROLLBACK TRAN
    END CATCH
END 
