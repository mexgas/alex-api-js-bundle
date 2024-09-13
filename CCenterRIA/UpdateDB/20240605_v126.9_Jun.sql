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
SET @versionfix = 9
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

	CREATE INDEX IX_ccoLogDialsData ON ccoLogDialsData (callout_id, callDate)
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

	CREATE INDEX IX_ccoCallsOutData ON ccoCallsOutData (callout_id, callDate)
END '
	EXEC(@sql)

	SET @process = 'KR140000 - Se crea SP ccsp_UpdateDataCall para actualizar datos de la llamada en ccoCallsOutSource, ccoCallsOutData y ccoLogDialsData'
	SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_UpdateDataCall'') 
	BEGIN
		DROP PROCEDURE dbo.ccsp_UpdateDataCall
	END
	'
	EXEC(@sql)

	SET @process = 'KR140000 - Se crea SP ccsp_UpdateDataCall para actualizar datos de la llamada en ccoCallsOutSource, ccoCallsOutData y ccoLogDialsData'
	SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_UpdateDataCall]
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
		IF NOT EXISTS(SELECT 1 FROM ccoCallsOutData WITH (NOLOCK) WHERE cal_id = @callId)
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


		SELECT @logDial_id = logDial_id FROM ccoLogDials WITH (NOLOCK) where cal_id = @callId
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
END
'
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
FROM ccoCallsOutSource WITH (NOLOCK) where callout_id = @callout_id

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
		FROM ccoCallsOutSource WITH (NOLOCK) where callout_id = @existCallOut

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
                select top 1 @LasCallKey=cal_Key from ccoCallsOut WITH (NOLOCK) where cam_id=@cam_id and cal_Inicio>=convert(datetime,getdate()) and cal_manual=0 order by cal_id desc
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
		FROM ccoCallsOutSource WITH (NOLOCK) where callout_id = @callout_id

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
			FROM ccoCallsOutSource WITH (NOLOCK) where callout_id = @callout_id

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
		FROM ccoCallsOutSource WITH (NOLOCK) where callout_id = @callout_id
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
