/*******************************/
/*******************************/
/*
Author: Marco Antonio García
Date: 2025/06/23
Description: Demo/Sprint2
Database: CCenterRia
Required version: 127.2
IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
USE CCenterRIA;

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
    SET @version = 127 --**********actualizar a 124 sin fix
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

    SET @process = 'DROP ccsp_GetNotReadyTimesxTipo'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GetNotReadyTimesxTipo'')
    begin
            DROP PROCEDURE ccsp_GetNotReadyTimesxTipo;
    end'
    exec (@sql)


    SET @process = 'DROP ccsp_GetNotReadyTimes'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GetNotReadyTimes'')
    begin
            DROP PROCEDURE ccsp_GetNotReadyTimes;
    end'
    exec (@sql)

    
    SET @process = 'CREATE procedure [dbo].[ccsp_GetNotReadyTimes]'
    SET @sql = 'CREATE procedure [dbo].[ccsp_GetNotReadyTimes]
@user_id int = 0
AS
-- Para horarios depues de las 12 de la noche
declare @inicioTurno integer
declare @fecha smalldatetime
declare @fStart datetime
declare @fEnd datetime

set @inicioTurno = 2 --Cambio de dia a las 2 de la mañana
set @fecha = getdate()
if datepart( hh,  @fecha ) > @inicioTurno - 1
begin   
    set @fStart = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
    set  @fEnd = dateadd( d,1, @fstart )
end
else
begin
    set @fEnd = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
    set  @fStart = dateadd( d,-1, @fEnd )
end

;WITH Tiempos AS
(
    SELECT 
        t.Descripcion,
        CAST(SUM(l.tStatus) AS BIGINT) AS TotalSegundos
    FROM ccLogAgentesNotReady l
    INNER JOIN ccTipoNotReady t
        ON l.tiponotready_id = t.tiponotready_id    
    WHERE l.fecha BETWEEN @fStart AND @fEnd
      AND (l.user_id = @user_id OR @user_id = 0)
    GROUP BY t.Descripcion
)
SELECT
    Descripcion,
    CAST(TotalSegundos / 3600 AS varchar(10)) + '':'' +
    RIGHT(''0'' + CAST((TotalSegundos % 3600) / 60 AS varchar(2)), 2) + '':'' +
    RIGHT(''0'' + CAST(TotalSegundos % 60 AS varchar(2)), 2) AS Tiempo,
    TotalSegundos AS total
FROM Tiempos;'
    exec (@sql)

    
    SET @process = 'CREATE procedure [dbo].[ccsp_GetNotReadyTimesxTipo]'
    SET @sql = 'CREATE procedure [dbo].[ccsp_GetNotReadyTimesxTipo]
@user_id int = 0,
@idTipo int
AS
-- Para horarios depues de las 12 de la noche
declare @inicioTurno integer

declare @fecha smalldatetime
declare @fStart datetime
declare @fEnd datetime

set @inicioTurno = 2 --Cambio de dia a las 2 de la mañana
set @fecha = getdate()
if datepart( hh,  @fecha ) > @inicioTurno - 1
begin   
    set @fStart = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
    set  @fEnd = dateadd( d,1, @fstart )
end
else
begin
    set @fEnd = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
    set  @fStart = dateadd( d,-1, @fEnd )
end

;WITH Tiempos AS
(
    SELECT 
        t.Descripcion,
        l.tiponotready_id,
        CAST(SUM(l.tStatus) AS BIGINT) AS TotalSegundos
    FROM ccLogAgentesNotReady l
    INNER JOIN ccTipoNotReady t
        ON l.tiponotready_id = t.tiponotready_id
    WHERE l.tiponotready_id = @idTipo
      AND l.fecha BETWEEN @fStart AND @fEnd
      AND (l.user_id = @user_id OR @user_id = 0)
    GROUP BY 
        t.Descripcion, 
        l.tiponotready_id
)
SELECT
    Descripcion,
    CAST(TotalSegundos / 3600 AS varchar(10)) + '':'' +
    RIGHT(''0'' + CAST((TotalSegundos % 3600) / 60 AS varchar(2)), 2) + '':'' +
    RIGHT(''0'' + CAST(TotalSegundos % 60 AS varchar(2)), 2) AS Tiempo,
    TotalSegundos AS total,
    tiponotready_id
FROM Tiempos;'
    exec (@sql)
    
    SET @process = 'DROP ccsp_GetPreviewHistory'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GetPreviewHistory'')
    begin
            DROP PROCEDURE ccsp_GetPreviewHistory;
    end'
    exec (@sql)


    SET @process = 'CREATE ccsp_GetPreviewHistory'
    SET @sql = '	CREATE Proc [dbo].[ccsp_GetPreviewHistory]( @callOut_Id int ,@initialRow smallint,@finalRow smallint)
		AS
		declare @initialDate datetime, @finalDate datetime
		set @finalDate= GETDATE()
		set @initialDate = (select DATEDIFF(day,30,@finalDate))

		declare @temTable table (callOut_id int, dialResult varchar(50),disposition varchar(100),date datetime)
		insert into @temTable 
					select co.callout_id as callOut_id, 
					trd.descTranslate dialResult,
					ISNULL( tco.Description,'''') as calificacion,
					ld.fecha as fecha
					from ccoCallsOut co 
					left join ccoLogDials ld on co.callout_id = ld.callout_id
					left join cctipoResultadoDial trd ON ld.tipoResDial_id = trd.tiporesdial_id
					LEFT JOIN cctipocalifout tco ON tco.calif_id = co.calif_id
					where co.callout_id = @callOut_Id and co.cal_id = ld.cal_id  and ld.fecha >= @initialDate and ld.fecha <=@finalDate and ld.tipoResDial_id != 13

					union 
					select rppr.callout_id,
					tpp.descripcion,
					'''',
					rppr.reg_date
					from RegProcessPreviewRecord rppr
					join ccTypeProcessPreview tpp on rppr.process= tpp.typeProcess_id
					where rppr.process NOT IN (1,5,7,14,15) and rppr.callout_id = @callOut_Id and rppr.reg_date >= @initialDate and rppr.reg_date <=@finalDate
			

		SELECT  * FROM    
				( SELECT    ROW_NUMBER() OVER ( ORDER BY date ) AS RowNum, *
				  FROM      @temTable 
				) AS RowConstrainedResult
		WHERE   RowNum >= @initialRow
			AND RowNum <= @finalRow 
		ORDER BY RowNum	'
    exec (@sql)
    

    SET @process = 'ALTER ccsp_DLRgetXferInfo'
    SET @sql = '
        ALTER procedure [dbo].[ccsp_DLRgetXferInfo]
        @camEspecId smallint=0,
        @iPortNumber smallint = 0,
        @type smallint,
        @typeTransfer smallint = 0,
        @phone varchar(50) = '''',
        @trunkId int=0
        as
        -- @type: 1 transferencia entrada, 2 transferencia salida, 3 desborde (siempre es entrada, con o sin especialidad)
        declare @prefix as varchar(15), @trunk varchar(200)
        declare @timeout int
        declare @ani as varchar(32)
        declare @stop int
        declare @ivr_script smallint, @surveycamid int

        set @prefix =''''
        set @timeout = 20
        set @ani = ''''
        set @stop = 0

        -- Prefijo por puerto
        select @prefix = prefix, @trunk=isnull(trunk,'''') from cstoProvedor nolock where provedor_id = (
            select provedor_id from ccodialers nolock where puerto = @iPortNumber )
        -- Prefijo por campaña o especialidad
        if @prefix =''''
            if @type = 2
                select @prefix = dialPrefixXfe from ccCamps where cam_id = @camEspecId
            else
                select @prefix = dialPrefixOverflow from ccInbound where inbound_id= @camEspecId
        -- Prefijo general
        if @prefix ='''' and (@type =1 or @type=2) and ((select cast(valor as int) from ccsettings where setting_id =102) & 4 = 4)
            select @prefix = valor from ccsettings where setting_id =101
        if @prefix ='''' and (@type =3) and ((select cast(valor as int) from ccsettings where setting_id =102) & 8 = 8)
            select @prefix = valor from ccsettings where setting_id =101

        -- Tiempo de marcado
        select @timeout = cast(valor as int) from ccSettings where setting_id = 109

        -- Ani y stopRecord
        if @type = 2
            select @ani = callerIdDesc, @stop = isnull(stopRecording, 0) from ccCamps nolock where cam_id = @camEspecId
        else
        begin
            select @ani = callerIdDesc, @stop = stopRecording, @surveycamid = isnull(extend.SurveyCamId,0)
            from ccInbound i (nolock)
            left join ccInboundExtend extend on extend.Inbound_id = i.Inbound_id
            where i.inbound_id= @camEspecId

            if @surveycamid > 0
                select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid
        end

        if (@typeTransfer in (0,4) and @type = 2 and @phone is not null and @phone <> '''')
        begin
            if @stop = 0
                begin
                    select @stop = case when @typeTransfer = 0 then isnull(stopRecording, 1) else ISNULL(stopRecordingAssisted, 1) end from telefonosTransferencia where tel = @phone
                end
        end

        select @prefix as sDialPrefix, @timeout as tNoContesta, @ani as ani, @stop as stopRecording, @ivr_script as ivrScript,
        dbo.GetRoute(@phone,'''',@trunkId) destination, @trunk trunk
    '
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)


    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)    


     
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    
    SET @process = ''
    SET @sql = ''
    exec (@sql)

    
    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)


    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)


    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
    

    SET @process = ''
    SET @sql = ''
    exec (@sql)    
    --- END  ----

	
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
