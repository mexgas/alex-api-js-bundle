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
