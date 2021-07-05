/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/04/06
Description:

Database: CCenterRia
Required version: 123.18
Tareas
CW-5111
CW-5367
CW-5163
CW-5341
CW-5343
CW-5296
CW-5348
CW-5337
CW-5373
CW-5047
CW-5357
CE-5470


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
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 19
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;



IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'CW-5111 insert setting 228 Series USA'
	set @sql = 'if not exists(select * from ccsettings where setting_id=228) begin
insert into ccsettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
values(228,''1|1|5|03:00|192.168.1.115|root|toor|21|/mnt/Utilidades/Utilidades/Reminder/slingshot-installer/Series/USASeries.zip''
,''Descarga automática de las series USA''
,1,''GLR'',''Activo(0:apagado,1:Mensual,2:semanal,3:diario)|# Semana Ejecucion|Dia Ejecucion(1:LU,2:Ma,3:Mi,4:Ju,5:Vi,6:Sa,0:Do)|Hora Inicio(00:00)|Servidor FTP|usuario FTP|contraseña FTP|Ruta de descarga FTP'',''USA number series automatic download'',1,''.*'')
end
else BEGIN
update ccsettings
set valor=''0|1|6|03:00|192.168.1.115|root|toor|22|/mnt/Utilidades/Utilidades/Reminder/slingshot-installer/Series/USASeries.zip''
where setting_id=228
end'
  EXEC(@sql)



  set @process = 'CW-5111 DROP PROCEDURE ccSpGalateaSeriesUSA'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccSpGalateaSeriesUSA'')
    begin
        DROP PROCEDURE ccSpGalateaSeriesUSA;
    end'
  EXEC(@sql)



  set @process = 'CW-5111 Create SP ccSpGalateaSeriesUSA'
	set @sql = 'CREATE PROCEDURE [dbo].[ccSpGalateaSeriesUSA]
    @actionId int
AS
BEGIN
    SET NOCOUNT ON;
    if @actionId= 1 begin
        if exists(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ''SeriesUSA'') begin
            truncate table SeriesUSA
        end
        else begin
            CREATE TABLE SeriesUSA(area varchar(5), prefix varchar(5), tz_standar float,
            tz_dayligth float, nxx_type varchar(5), city varchar(50),county varchar(50),state varchar(50));
        end

    end
    else if @actionId= 2 begin
        if exists(select * from SeriesUSA) begin
            truncate table ccTimeZoneAreaUsaDetail
            insert into ccTimeZoneAreaUsaDetail

            select distinct A.area, A.prefix,B.tz_id as tz_standar,C.tz_id as tz_dayligth,A.city+'', ''+A.county+'', ''+A.state
                            ,A.nxx_type
                            from SeriesUSA A
                            inner join ccTimeZones B on A.tz_standar=B.tz_offset
                            inner join ccTimeZones C on A.tz_dayligth=C.tz_offset
            where A.nxx_type !='''';
        end
    end
    else if @actionId=3 begin
        select valor from ccsettings where setting_id = 228
    end
END
'
  EXEC(@sql)

  set @process = 'CW-5367 Cortiza mejora DROP FUNCTION ChangePriorityCall'
	set @sql = 'if exists (select * from sys.objects where object_id = OBJECT_ID(N''ChangePriorityCall'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
    begin
        DROP FUNCTION ChangePriorityCall
    end
'
  EXEC(@sql)

  set @process = 'CW-5367 Cortiza mejora CREATE FUNCTION ChangePriorityCall'
	set @sql = 'CREATE FUNCTION [dbo].[ChangePriorityCall](@priorityCall VARCHAR(8))
RETURNS VARCHAR(8)
AS
BEGIN
    DECLARE @resultado VARCHAR(32);
    SET @resultado = CAST(CASE
        WHEN CAST(SUBSTRING(@priorityCall, 1, 1) AS TINYINT) < 5
        THEN CAST(SUBSTRING(@priorityCall, 1, 1) AS TINYINT) + 1
        ELSE 1
        END AS VARCHAR(1)) + REPLACE(''2345NNN'', CAST(CASE
        WHEN CAST(SUBSTRING(@priorityCall, 1, 1) AS TINYINT) < 5
        THEN CAST(SUBSTRING(@priorityCall, 1, 1) AS TINYINT) + 1
        ELSE 1
        END AS VARCHAR(1)), ''1'');
    RETURN @resultado;
END;'
  EXEC(@sql)

  set @process = 'CW-5367 Alter SP ccsp_OUTUpdateDialJob'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]
@callout_id     INT,
@CallResultDial TINYINT,
@isTCPA         BIT     = 0
AS
     SET NOCOUNT ON

/*1:Contesto | 2:Ocupada | 3:No contestada | 4:Fax/Modem | 5:No Dial Tone | 7:Colgado durante transferencia
++8:short call | ++9:Otro | 8:Other | 10:NoService | 11:Machine	*/

     DECLARE @nOcupado TINYINT, @nNoContesta TINYINT, @nFax TINYINT, @nContestadora TINYINT
     DECLARE @nShortCall TINYINT, @nOtro TINYINT, @cam_NoInt_ocupado TINYINT, @cam_NoInt_graba TINYINT
     DECLARE @cam_ocupado SMALLINT, @cam_inter_ocupado SMALLINT, @cam_nocontesto SMALLINT
     DECLARE @cam_graba SMALLINT, @cam_inter_graba SMALLINT, @cam_inter_nocontesto SMALLINT
     DECLARE @cam_fax SMALLINT, @cam_inter_fax SMALLINT
     DECLARE @DateNextDial SMALLDATETIME, @DateNewDial SMALLDATETIME, @cam_id SMALLINT
     DECLARE @ExisteWT TINYINT, @cam_NoInt_fax TINYINT, @cam_NoInt_nocontesto TINYINT, @cal_status TINYINT
     DECLARE @sSQL NVARCHAR(MAX), @Telefono VARCHAR(15), @prioridadLlamada CHAR(8)

	 SELECT @cam_id = cam_id,
            @nOcupado = ISNULL(nOcupado, 0),
            @nNoContesta = ISNULL(nNoContesta, 0),
            @nFax = ISNULL(nFax, 0),
            @nContestadora = ISNULL(nContestadora, 0),
            @nShortCall = ISNULL(nShortCall, 0),
            @nOtro = ISNULL(nOtro, 0),
            @DateNextDial = cal_fechaDial
     FROM ccoWorkingTable with(nolock)
     WHERE callout_id = @callout_id

	 SELECT @ExisteWT = CASE WHEN @cam_id IS NOT NULL THEN 1 ELSE 0 END
     SELECT @cal_status = CASE WHEN @isTCPA = 1 THEN 0 ELSE 1 END--si esta en modo TCPA no gene|rar callbacks

     IF @CallResultDial = 20 BEGIN-- CONTACTADO
        EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
        RETURN(0)
     END
     else IF @CallResultDial = 1 BEGIN-- CONTESTO
        IF @isTCPA = 1 BEGIN
                UPDATE ccoWorkingTable with(rowlock) SET cal_status = @cal_status WHERE callout_id = @callout_id
        END
        ELSE BEGIN
            IF (SELECT abandonCallback FROM ccCamps WHERE cam_id = @cam_id) = 1
                BEGIN
                    EXEC ccsp_OUTCancelDialJOB @callout_id,1,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
            END
            ELSE BEGIN
                EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
            END
        END
        RETURN(0)
     END
     ELSE IF @CallResultDial IN(2, 12) BEGIN -- OCUPADO
        SELECT @cam_ocupado = cam_ocupado,
			@cam_inter_ocupado = cam_inter_ocupado,
			@cam_NoInt_ocupado = cam_NoInt_ocupado,
			@nOcupado = @nOcupado + 1
        FROM ccCamps
        WHERE cam_id = @cam_id

            IF @cam_ocupado = 1 BEGIN -- Opcion Ocupado HABILITADA
                IF @nOcupado > @cam_NoInt_ocupado OR @nShortCall > 4 BEGIN
                    EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
                    RETURN(0)
                END


                SELECT @prioridadLlamada=priorityCall FROM ccoCallPriorityOrder with(nolock) WHERE callout_id = @callout_id
				IF @prioridadLlamada is null BEGIN
					SELECT @prioridadLlamada = Prioridad FROM ccCampsPrioridadTel with(nolock) WHERE cam_id = @cam_id
					INSERT INTO ccoCallPriorityOrder VALUES (@callout_id,@prioridadLlamada)
				END

                -- Change priority and obtain the next telephone
                UPDATE ccoCallsOutSource with(rowlock) SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1	ELSE nNoContesta END
                WHERE callout_id = @callout_id


				set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
				UPDATE ccoCallPriorityOrder with(rowlock) SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

				SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
				+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
				+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
				+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
				+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
				+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
				+ CAST(@callout_id AS VARCHAR(15))

                EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

                SELECT @DateNewDial = DATEADD(mi, @cam_inter_ocupado, GETDATE())

                -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
                IF @DateNewDial > @DateNextDial BEGIN	-- Nueva fecha de Call BACk
                    UPDATE ccoWorkingTable with(rowlock) SET nOcupado = @nOcupado, cal_fechaDial = @DateNewDial, cal_status = @cal_status
                    WHERE callout_id = @callout_id
                    RETURN(0)
                END
                -- Mantiene la fecha de Call BACK
                UPDATE ccoWorkingTable with(rowlock) SET nOcupado = @nOcupado, cal_status = @cal_status, cal_telefono = @Telefono
                WHERE callout_id = @callout_id
                RETURN(0)
            END

            -- ELSE: Opcion Ocupado DESHABILITADA
            EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
            RETURN(0)
         END
         ELSE IF @CallResultDial IN(3, 5, 8) BEGIN-- NO CONTESTA
            --select NO Contesta
            SELECT @cam_nocontesto = cam_nocontesto,
                @cam_inter_nocontesto = cam_inter_nocontesto,
                @cam_NoInt_nocontesto = cam_NoInt_nocontesto,
                @nNoContesta = @nNoContesta + 1
            FROM ccCamps
            WHERE cam_id = @cam_id

            IF @cam_nocontesto = 1 BEGIN-- Opcion NoContesta HABILITADA
                IF @nNoContesta > @cam_NoInt_nocontesto OR @nShortCall > 4 BEGIN --select No Contesta Habilitada
                    EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                    RETURN(0)
                END

                SELECT @prioridadLlamada=priorityCall FROM ccoCallPriorityOrder with(nolock) WHERE callout_id = @callout_id
				IF @prioridadLlamada is null BEGIN
					SELECT @prioridadLlamada = Prioridad FROM ccCampsPrioridadTel with(nolock) WHERE cam_id = @cam_id
					INSERT INTO ccoCallPriorityOrder VALUES (@callout_id,@prioridadLlamada)
				END

                -- Change priority and obtain the next telephone
                UPDATE ccoCallsOutSource with(rowlock) SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1
				ELSE nNoContesta END
                WHERE callout_id = @callout_id


				set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
				UPDATE ccoCallPriorityOrder with(rowlock) SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

				SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
				+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
				+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
				+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
				+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
				+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
				+ CAST(@callout_id AS VARCHAR(15))

                EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

                SELECT @DateNewDial = DATEADD(mi, @cam_inter_nocontesto, GETDATE())

                UPDATE ccoWorkingTable with(rowlock) SET nNoContesta = @nNoContesta, cal_status = @cal_status, cal_telefono = @Telefono,
					cal_fechaDial = CASE
                                        WHEN @DateNewDial > @DateNextDial
                                        THEN @DateNewDial
                                        ELSE cal_fechaDial
                                    END
                WHERE callout_id = @callout_id
                RETURN(0)
            END

            -- Opcion NoContesta DESHABILITADA
            EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
            RETURN(0)
        END
	ELSE IF @CallResultDial = 4 BEGIN-- Fax/Modem
		SELECT @cam_fax = cam_fax,
			@cam_inter_fax = cam_inter_fax,
			@cam_NoInt_fax = cam_NoInt_fax,
			@nFax = @nFax + 1
		FROM ccCamps
		WHERE cam_id = @cam_id

        IF @cam_fax = 1 BEGIN-- Opcion Fax/Modem HABILITADA
                IF @nFax > @cam_NoInt_fax OR @nShortCall > 4 BEGIN
                    EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                    RETURN(0)
                END

                SELECT @prioridadLlamada=priorityCall FROM ccoCallPriorityOrder with(nolock) WHERE callout_id = @callout_id
				IF @prioridadLlamada is null BEGIN
					SELECT @prioridadLlamada = Prioridad FROM ccCampsPrioridadTel with(nolock) WHERE cam_id = @cam_id
					INSERT INTO ccoCallPriorityOrder VALUES (@callout_id,@prioridadLlamada)
				END

                -- Change priority and obtain the next telephone
                UPDATE ccoCallsOutSource with(rowlock) SET nFax = CASE WHEN nFax < 255 THEN ISNULL(nFax, 0) + 1 ELSE nFax END
                WHERE callout_id = @callout_id

                set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
				UPDATE ccoCallPriorityOrder with(rowlock)  SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

				SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
				+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
				+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
				+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
				+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
				+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
				+ CAST(@callout_id AS VARCHAR(15))

                EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

                SELECT @DateNewDial = DATEADD(mi, @cam_inter_fax, GETDATE())

                -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
                UPDATE ccoWorkingTable with(rowlock) SET nFax = @nFax, cal_status = @cal_status, cal_telefono = @Telefono,
                    cal_fechaDial = CASE
                                        WHEN @DateNewDial > @DateNextDial
                                        THEN @DateNewDial
                                        ELSE cal_fechaDial
                                    END
                WHERE callout_id = @callout_id
                RETURN(0)
        END

        -- Opcion Fax/Modem DESHABILITADA
        EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
        RETURN(0)
    END
    ELSE IF @CallResultDial = 11 BEGIN-- Maquina Contestadora
        SELECT @cam_graba = cam_graba,
            @cam_inter_graba = cam_inter_graba,
            @cam_NoInt_graba = cam_NoInt_graba,
            @nContestadora = @nContestadora + 1
        FROM ccCamps
        WHERE cam_id = @cam_id

        IF @cam_graba = 1 BEGIN-- Opcion Maquina Contestadora HABILITADA
            IF @nContestadora > @cam_NoInt_graba OR @nShortCall > 4 BEGIN
                EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                RETURN(0)
            END

			SELECT @prioridadLlamada=priorityCall FROM ccoCallPriorityOrder with(nolock) WHERE callout_id = @callout_id
			IF @prioridadLlamada is null BEGIN
				SELECT @prioridadLlamada = Prioridad FROM ccCampsPrioridadTel with(nolock) WHERE cam_id = @cam_id
				INSERT INTO ccoCallPriorityOrder VALUES (@callout_id,@prioridadLlamada)
			END

            -- Change priority and obtain the next telephone
            UPDATE ccoCallsOutSource with(rowlock) SET nContestadora = CASE WHEN nContestadora < 255 THEN ISNULL(nContestadora, 0) + 1 ELSE nContestadora END
            WHERE callout_id = @callout_id

            set @prioridadLlamada=dbo.ChangePriorityCall(@prioridadLlamada)
			UPDATE ccoCallPriorityOrder with(rowlock) SET priorityCall = @prioridadLlamada WHERE callout_id = @callout_id

			SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
			+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
			+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
			+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
			+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
			+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id=''
			+ CAST(@callout_id AS VARCHAR(15))

            EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

            SELECT @DateNewDial = DATEADD(mi, @cam_inter_graba, GETDATE())

            -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
            UPDATE ccoWorkingTable with(rowlock) SET nContestadora = @nContestadora, cal_status = @cal_status, cal_telefono = @Telefono,
                cal_fechaDial = CASE
                                    WHEN @DateNewDial > @DateNextDial
                                    THEN @DateNewDial
                                    ELSE cal_fechaDial
                                END
            WHERE callout_id = @callout_id
            RETURN(0)
        END

        -- Opcion Maquina Contestadora DESHABILITADA
        EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
        RETURN(0)
    END
    ELSE IF @CallResultDial IN(10, 90) BEGIN--No Dial Tone, otros, NoService
        EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
        RETURN(0)
    END
    ELSE IF @CallResultDial > 13 AND @CallResultDial <> 51   BEGIN--Dial Result not register
       EXEC ccsp_OUTUpdateDialJob @callout_id = @callout_id, @CallResultDial = 8, @isTCPA = @isTCPA
    END

RETURN(0)
SET NOCOUNT OFF'
  EXEC(@sql)

  set @process = 'CW-5367 Alter SP ccsp_OUTCancelDialJOB'
  set @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTCancelDialJOB]
@callout_id    INT,
@IsAnswer      TINYINT,
@nOcupado      TINYINT,
@nNoContesta   TINYINT,
@nFax          TINYINT,
@nContestadora TINYINT,
@nShortCall    TINYINT,
@nOtro         TINYINT,
@ExisteWT      TINYINT = 1
AS
DECLARE @RecicleSIC TINYINT;

SELECT @RecicleSIC = valor FROM ccSettings WHERE setting_id = 60;
IF @RecicleSIC IS NULL
    SET @RecicleSIC = 0;

-- En workingtable
IF @ExisteWT > 0 BEGIN
	IF @IsAnswer = 1 BEGIN
			UPDATE ccoWorkingTable WITH(ROWLOCK)
			SET
				cal_fechaDial = DATEADD(hh, 1, GETDATE()),
				cal_status = 1,
				nOcupado = 1,
				nNoContesta = 1,
				nShortCall = nShortCall + 1
			WHERE callout_id = @callout_id;
	END;
		ELSE
		IF @RecicleSIC = 0 BEGIN
				DELETE ccoWorkingTable WITH(ROWLOCK) WHERE callout_id = @callout_id;
				DELETE ccoCallPriorityOrder WITH(ROWLOCK) WHERE callout_id = @callout_id;
		END;
END;'

    EXEC(@sql)

    set @process = 'CW-5163 Ordenamiento de campañas alfabeticamente y CW-5343 Filtro para solo traer campañas de tipo llamada'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminCampaigns'')
            begin
                DROP PROCEDURE ccsp_GalateaAdminCampaigns;
            end'
    EXEC(@sql)


    set @process = 'CW-5163 Ordenamiento de campañas alfabeticamente y CW-5343 Filtro para solo traer campañas de tipo llamada'
        set @sql = '
            CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS SMALLINT,
                                                        @CampType AS SMALLINT = 0,
                                                        @WorkgroupId AS INT = 0,
                                                        @Id AS INT = 0,
                                                        @AdminId AS SMALLINT = 0,
                                                        @PinUpdate AS SMALLINT = 0,
                                                        @LoadId AS INT = 0,
                                                        @Type AS SMALLINT = 0
            AS
            BEGIN
            set nocount on
            IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type
            BEGIN
                IF @CampType = 1 -- Campaigns Out
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                    BEGIN
                        SELECT CAST(IdCampEsp AS INT) AS Id
                        FROM ccRIACampEspWG
                        WHERE IDWG = @WorkgroupId AND Tipo=1
                        ORDER BY IdCampEsp ASC
                    END
                    ELSE
                    BEGIN
                        raiserror(''ERROR. No existe una lista de campa?as de salida con el id de grupo de trabajo especificado'', 18, 1)
                    END
                END
                IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                    BEGIN
                        SELECT CAST(IdCampEsp AS INT) AS Id
                        FROM ccRIACampEspWG
                        WHERE IDWG = @WorkgroupId AND Tipo=0
                        ORDER BY IdCampEsp ASC
                    END
                    ELSE
                    BEGIN
                        raiserror(''ERROR. No existe una lista de campa?as de entrada con el id de grupo de trabajo especificado'', 18, 1)
                    END
                END
            END

            IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id
                BEGIN
                    IF @CampType = 1 -- Campaigns Out
                        BEGIN
                            IF @Id IS NOT NULL
                                BEGIN
                                    SELECT DISTINCT
                                        camps.cam_id AS Id,
                                        camps.cam_descripcion AS Name,
                                        CAST(graph.graphic_id AS INT) AS Frame,
                                        CAST(1 AS SMALLINT) AS Type,
                                        camps.cam_procesando IsStarted,
                                        a.AreaName as Area
                                    FROM ccCamps camps
                                    LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                                    left join ccRIACat_Areas a on a.IDArea = camps.IDArea
                                    WHERE camps.cam_id = @Id
                                    ORDER BY camps.cam_descripcion ASC;
                                END
                            ELSE
                            BEGIN
                                raiserror(''ERROR. No existe campa?as de salida con el id especificado'', 18, 1)
                            END
                        END
                    IF @CampType = 0 -- Campaigns In (ACD)
                        BEGIN
                            IF @Id IS NOT NULL
                                BEGIN
                                    SELECT DISTINCT
                                        inb.Inbound_id AS Id,
                                        inb.descripcion AS Name,
                                        CAST(graph.graphic_id AS INT) AS Frame,
                                        CAST(0 AS SMALLINT) AS Type,
                                        CAST(inb.Status AS BIT) IsStarted,
                                        a.AreaName AS Area,
                                        inb.chat AS InboundType
                                    FROM ccInbound inb
                                    LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                                    left join ccRIACat_Areas a on a.IDArea = inb.IDArea
                                    WHERE inb.Inbound_id = @Id
                                    ORDER BY inb.descripcion ASC;
                                END
                            ELSE
                                BEGIN
                                    raiserror(''ERROR. No existe campa?as de entrada con el id especificado'', 18, 1)
                                END
                        END
                END

            IF @Option = 3   -- Update OverallTotalNew By Campaign
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            UPDATE ccCampsNvosCB SET OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id
                        END
                    ELSE
                        BEGIN
                            raiserror(''ERROR. No existe la campa?as de entrada con el id especificado'', 18, 1)
                        END
                END

            IF @Option = 4   -- Update Pin from Campaign per Admin
                BEGIN
                    IF @Id IS NOT NULL AND @AdminId IS NOT NULL
                        BEGIN
                            IF @PinUpdate = 1
                                BEGIN
                                    INSERT INTO PinedCampaigns (CampId, AdminId, Type)
                                            VALUES (@Id, @AdminId, @Type);
                                END;
                            IF @PinUpdate = 0
                                BEGIN
                                    DELETE FROM PinedCampaigns
                                    WHERE CampId = @Id AND AdminId = @AdminId AND Type = @Type;
                                END;
                        END
                    ELSE
                        BEGIN
                            raiserror(''ERROR. La campa?as o administrador no existen'', 18, 1)
                        END
                END

            IF @Option = 5   -- Get Pin from Campaign Ids per Admin
                BEGIN
                    IF @AdminId IS NOT NULL
                        BEGIN
                            SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
                            ORDER BY Id ASC
                        END
                    ELSE
                        BEGIN
                            raiserror(''ERROR. El administrador con el id seleccionado no existe'', 18, 1)
                        END
                END

            IF @Option = 6   -- Get Blacklist Ids by Campaign Id
            BEGIN
                IF @Id IS NOT NULL
                    BEGIN
                        DECLARE @BlackListIds VARCHAR(MAX);
                        SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
                        FROM Camplistanegra
                        WHERE cam_id = @Id AND STATUS = 1;
                        SELECT isnull(@BlackListIds,''0'') AS BlackListIds;
                    END
                ELSE
                    BEGIN
                        raiserror(''ERROR. La campa?as con el id seleccionado no existe'', 18, 1)
                    END
            END

            IF @Option = 7   -- Get RegistryListIds Ids by Campaign Id
            BEGIN
                IF (@Id IS NOT NULL AND EXISTS(SELECT * FROM cccamps WHERE cam_id = @Id))
                    BEGIN
                        SELECT TOP 1 list_id FROM ccRIARegistryLists WHERE cam_id = @Id AND status = 2 ORDER BY list_id DESC
                    END
                ELSE
                    BEGIN
                        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                        raiserror(''ERROR. No existe una campa?a con el id especificado'', 18, 1)
                    END
            END

            IF @Option = 8   -- Delete RegistryListIds Ids by LoadId
            BEGIN
                IF (@LoadId IS NOT NULL AND EXISTS(SELECT * FROM ccRIARegistryLists WHERE list_id = @loadID and status <> 0))
                    BEGIN
                        UPDATE ccoCallsOutSource SET cal_status = ''5'' WHERE list_id = @loadID
                        DELETE FROM ccoWorkingTable WHERE list_id = @LoadId
                        exec ccsp_RIARegistryLists @action=6, @list_id = @LoadId
                    END
                ELSE
                    BEGIN
                        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                        raiserror(''ERROR. No existe una carga el id especificado'', 18, 1)
                    END
            END

            IF @option = 9   -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
                    BEGIN
                        DECLARE @table TABLE
                        (camId    INT,
                        campType TINYINT,
                        PRIMARY KEY(camId, campType)
                        );
                        INSERT INTO @table
                            SELECT DISTINCT
                                    IdCampEsp,
                                    Tipo
                            FROM ccRIACampEspWG wg
                            WHERE wg.IDWG IN
                            (
                                SELECT IDWG
                                FROM ccRIAWorkGroupUsers
                                WHERE IDWG <> @WorkgroupId
                                AND User_id = @AdminId
                            );
                        SELECT CAST(B.IdCampEsp AS INT) AS Id,
                            B.Tipo AS Type
                        FROM @table A
                            RIGHT JOIN
                        (
                            SELECT wg.IdCampEsp,
                                wg.Tipo
                            FROM ccRIACampEspWG wg
                            WHERE wg.IDWG = @WorkgroupId
                        ) B ON A.camId = B.IdCampEsp
                            AND A.campType = B.Tipo
                        WHERE A.camId IS NULL
                        ORDER BY IdCampEsp;
                END;
            IF @option = 10  -- Get Agents States with totals per campaign by admin id and campaign type
                BEGIN
                    DECLARE @date datetime = CONVERT(DATE, DATEADD(hh, -3, GETDATE()))
                    DECLARE @Wg TABLE(id INT, PRIMARY KEY(id));
                    DECLARE @tmpAgent TABLE(id INT, PRIMARY KEY(id));
                    DECLARE @tmpCamAgent TABLE(camId INT, userId INT, PRIMARY KEY( camId, userId ));
                    DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT);
                    DECLARE @AgentStatusWithTotals TABLE(CampName VARCHAR(MAX), Total INT, Ready INT, NotReady INT, Dialog INT, Area VARCHAR(MAX));

                    INSERT INTO @Wg
                            SELECT DISTINCT IDWG FROM ccRIAWorkGroupUsers WHERE user_id = @AdminId;

                    INSERT INTO @tmpAgent
                            SELECT DISTINCT  A.User_id FROM ccRIAWorkGroupUsers A
                            INNER JOIN @Wg B ON A.IDWG=B.id
                            INNER JOIN ccUsers C ON A.User_id=C.User_id AND C.TipoUser_id=1
                            ORDER BY A.User_id;

                    INSERT INTO @tmpCamAgent
                            SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id FROM ccRIACampEspWG campPerWg
                            INNER JOIN @Wg wg ON wg.Id=campPerWg.IDWG
                            INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG=wg.id
                            INNER JOIN ccUsers C ON wgUser.User_id=C.User_id AND C.TipoUser_id=1
                            WHERE campPerWg.Tipo = @CampType;

                    WITH lastState
                            AS ( SELECT A.user_id,  MAX( A.fecha ) AS fecha
                                FROM ccLogAgentesDia A
                                INNER JOIN @tmpAgent B ON A.User_id=B.id
                                WHERE fecha>= @date
                                GROUP BY user_id )


                            INSERT INTO @AgentStatus
                                SELECT A.camId,  A.userId,
                                ISNULL( B.currentStatus, 0 ) currentStatus,
                                CASE WHEN B.IdCampEsp=A.camId AND B.Tipo = @CampType AND B.currentStatus IN( 4, 5, 6, 9 ) THEN 1 ELSE NULL END AS isCampDialog
                                FROM @tmpCamAgent A
                                LEFT JOIN
                                (
                                    SELECT B.User_id,
                                            B.currentStatus,
                                            B.IdCampEsp,
                                            B.Tipo
                                    FROM lastState A
                                    INNER JOIN
                                    ccLogAgentesDia B
                                    ON A.User_id=B.User_id
                                        AND A.fecha=B.fecha
                                ) B
                                ON A.userId=B.User_id;

                    IF @CampType = 1
                        BEGIN
                            IF @Id <> 0
                                INSERT INTO @AgentStatusWithTotals
                                SELECT  B.cam_descripcion,
                                        COUNT( CurrentState ) as total,
                                        COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ) as ready,
                                        COUNT( CASE WHEN CurrentState NOT IN( 3, 4, 5, 6, 9 )  THEN 1 ELSE NULL END)
                                        + count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)

                                        as notReady,
                                        COUNT( isCampDialog ) as dialog,
                                        C.AreaName
                                FROM @AgentStatus A
                                INNER JOIN ccCamps B on A.CampId=B.cam_id
                                INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                                WHERE A.CampId = @Id
                                GROUP BY B.cam_descripcion, CampId, C.AreaName
                            ELSE
                                INSERT INTO @AgentStatusWithTotals
                                SELECT  B.cam_descripcion,
                                        COUNT( CurrentState ) as total,
                                        COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ) as ready,
                                        COUNT( CASE WHEN CurrentState NOT IN( 3, 4, 5, 6, 9 )  THEN 1 ELSE NULL END)
                                        + count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)

                                        as notReady,
                                        COUNT( isCampDialog ) as dialog,
                                        C.AreaName
                                FROM @AgentStatus A
                                INNER JOIN ccCamps B on A.CampId=B.cam_id
                                INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                                GROUP BY B.cam_descripcion, CampId, C.AreaName
                        END
                    ELSE
                        BEGIN
                            IF @Id <> 0
                                INSERT INTO @AgentStatusWithTotals
                                SELECT  B.descripcion,
                                        COUNT( CurrentState ),
                                        COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ),
                                        COUNT( CASE WHEN CurrentState NOT IN(3, 4, 5, 6, 9 ) THEN 1 ELSE NULL END)
                                        + count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)
                                        ,
                                        COUNT( isCampDialog ),
                                        C.AreaName
                                FROM @AgentStatus A
                                INNER JOIN ccInbound B on A.CampId = B.Inbound_id
                                INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                                WHERE A.CampId = @Id
                                GROUP BY  B.descripcion, CampId , C.AreaName
                            ELSE
                                INSERT INTO @AgentStatusWithTotals
                                SELECT  B.descripcion,
                                        COUNT( CurrentState ),
                                        COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ),
                                        COUNT( CASE WHEN CurrentState NOT IN(3, 4, 5, 6, 9 ) THEN 1 ELSE NULL END)
                                        + count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)
                                        ,
                                        COUNT( isCampDialog ),
                                        C.AreaName
                                FROM @AgentStatus A
                                INNER JOIN ccInbound B on A.CampId = B.Inbound_id
                                INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                                    WHERE B.chat = 0
                                GROUP BY  B.descripcion, CampId , C.AreaName
                        END


                    SELECT * FROM @AgentStatusWithTotals
                    ORDER BY CampName
                END;

            END
    '
	EXEC(@sql)


	set @process = 'CW-5296 DROP SP ccsp_RIA_mnuReciclar'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIA_mnuReciclar'')
		begin
			DROP PROCEDURE ccsp_RIA_mnuReciclar;
		end'
	EXEC(@sql)



	set @process = 'CW-5296 CREATE SP ccsp_RIA_mnuReciclar'
	set @sql = 'Create proc [dbo].[ccsp_RIA_mnuReciclar]
@cam_id int,
@type tinyint, -- 0:recicla todo / 1:recicla no efectivos / 2:recicla los efectivos calificados /
--                3:recicla no efectivos y efectivos calificados (1 y 2) / 4:Recicla status "Finalizado"
@calif_id varchar(1500) = null,
@user_id as integer = null,
@list_id as integer = 0
as
set nocount on
declare @Valor int, @SQL varchar(4000)
select @Valor = valor from ccSettings with(nolock) where setting_id = 60

If @Valor = 1
 begin
    declare @ultimoReciclaje datetime, @siguienteReciclaje datetime, @difDateAdd datetime
    select @Valor = valor from ccSettings with(nolock) where setting_id = 59

    If @Valor = 0
     begin
        select -2, ''No hay un limite para volver a reciclar''
        return(0)
     end

    select top 1 @ultimoReciclaje = max(fecha) from ccLogReciclaje where cam_id = @cam_id

    -- Se crea log, ccsp_ADMlogReciclaje para que esta informacion la traiga, por que no se esta metiendo
    select @user_id = isnull(@user_id, ''0''), @calif_id = isnull(@calif_id, ''0'')

    exec dbo.ccsp_ADMlogReciclaje @cam_id, @user_id, @type, @calif_id

    If @ultimoReciclaje is not null and getdate() < DateAdd(n, @Valor, @ultimoReciclaje)
    begin
        select -3, ''No se puede realizar un reciclaje hasta que pase el tiempo limite''
        return(0)
    end

 end

if @type=0
 begin
    if @list_id = 0 begin
        create table #allReciycled(callout_id int not null primary key)

        insert into #allReciycled
        select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_8),nolock) where cam_id = @cam_id and cal_status = 1

        update ccoCallBacks
        set [status] = 3, schedulerStatus = 1
        from ccoCallBacks a with(index([IX_ccoCallBacks6])) join #allReciycled b on (a.callout_id = b.callout_id)
        where [status] = 0

        update ccoWorkingTable
        set cal_status = 0
        from ccoWorkingTable a join #allReciycled b on (a.callout_id = b.callout_id)

        drop table #allReciycled
    end
    else begin
        create table #allListReciycled(callout_id int not null primary key)

        insert into #allListReciycled
        select callout_id from ccoWorkingTable with(index(IX_ccoWorkingTable_10),nolock) where cam_id = @cam_id and cal_status = 1 and list_id = @list_id

        update ccoCallBacks
        set [status] = 3, schedulerStatus = 1
        from ccoCallBacks a with(index([IX_ccoCallBacks6])) join #allListReciycled b on (a.callout_id = b.callout_id)
        where [status] = 0

        update ccoWorkingTable
        set cal_status = 0
        from ccoWorkingTable a join #allListReciycled b on (a.callout_id = b.callout_id)

        drop table #allListReciycled
    end
	select 1
    return(0)
 end

if @type in(1,3)
 begin

    update ccoCallBacks
    set [status] = 3, schedulerStatus = 1
    where callout_id in (select distinct(callout_id)
                         from ccoWorkingTable with(index(IX_ccoWorkingTable_12),nolock)
                         where cam_id = @cam_id
                         and cal_status = 1
                         and tiporesdial_id <> 1
                         and callout_id in (select distinct(b.callout_id)
                                                from ccologdials a with (index (IX_ccoLogDials_4),nolock)
                                                left join ccocallsout b with(index(IX_ccoCallsOut12),nolock)
                                                on a.callout_id = b.callout_id
                                                and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
                                                where calif_id = 0
                                                and calif_id is not null))
    and [status] = 0

    update ccoWorkingTable
    set cal_status = 0, tiporesdial_id = 0
    where cam_id = @cam_id
    and cal_status = 1
    and tiporesdial_id <> 1
    and callout_id in (select distinct(b.callout_id)
                           from ccologdials a with (index (IX_ccoLogDials_4),nolock)
                           left join ccocallsout b with(index(IX_ccoCallsOut12),nolock)
                           on a.callout_id = b.callout_id
                           and convert(varchar(13), a.fecha, 121) = convert(varchar(13), b.cal_inicio, 121)
                           where calif_id = 0
                           and calif_id is not null)
 end

if @type in(2,3)
 begin

    Set @SQL = ''update ccoCallBacks with(rowlock) set [status] = 3, schedulerStatus = 1'' +
     ''where callout_id in ('' +
     ''select distinct(callout_id) from ccoWorkingTable with(index(IX_ccoWorkingTable_14),nolock) '' +
     ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 '' +
     ''and calif_id in ('' + @calif_id + ''))'' +
     ''and [status] = 0''

    exec(@SQL)

    Set @SQL = ''update ccoWorkingTable set cal_status = 0, tiporesdial_id = 0, calif_id = 0 '' +
     ''where cam_id = '' + cast(@cam_id as varchar(10)) + '' and cal_status = 1 ''
     + -- and tiporesdial_id = 1 '' +
     ''and calif_id in ('' + @calif_id + '')''

    exec(@SQL)
 end

if @type = 4
 begin

    update ccoCallBacks
    set [status] = 3, schedulerStatus = 1
    where callout_id in (select distinct(callout_id)
                         from ccoWorkingTable with(index(IX_ccoWorkingTable_9),nolock)
                         where cam_id = @cam_id and cal_status = 3)
    and [status] = 0

    update ccoWorkingTable
  set cal_status = 0, tiporesdial_id = 0
    where cam_id = @cam_id and cal_status = 3
 end

return(0)
set nocount off'

	EXEC(@sql)

	set @process = 'CW-5348 DROP PROCEDURE ccsp_GalateaAdminDispositions'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminDispositions'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminDispositions;
    end'
	EXEC(@sql)

	set @process = 'CW-5348 Create SP ccsp_GalateaAdminDispositions'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
@command int,
@calif_id smallint = null,
@califIdLst varchar(8000) = null,
@description varchar(60)=null,
@order tinyint=null,
@canReprogram bit = null,
@graphColor varchar(15) = null,
@endConversation bit=null,
@keepDial bit=null,
@autoCB bit=null,
@contactOwner bit=null,
@finishPreview bit = 0
AS
set nocount on
declare @inserted table (ID smallint)

if @command=1 -- Load Inbound Dispositions
begin
  Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner,
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd, graphColor
  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
  where C.Calif_Status=1
  group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation, graphColor
  order by 2
  return(0)
end

If @command=2 -- Load Outbound Dispositions
begin
  Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner,
  IsNull(C.finishPreview,0) as finishPreview, graphColor
  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
  where C.CalifOut_Status=1
  group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,
  C.contactOwner, C.finishPreview, graphColor
  order by 2
  return(0)
end

If @command=3 -- New ccTipoCalif
begin
  If exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@description)
    begin
      select cast(-1 as smallint) [result]	-- Disposition already exists
      return(0)
    end

  If exists(select calif_id from ccTipoCalif where Calif_Status=0 and description=@description)
  begin
	select top 1 @calif_id = calif_id from ccTipoCalif where Calif_Status=0 and description=@description order by calif_id desc
    update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0),
	graphColor=isnull(@graphColor, ''1DB4E2''), Calif_Status=1
	output inserted.calif_id into @inserted
    where calif_id=@calif_id
	select ID [result] from @inserted
    return(0)
  end

  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , graphColor)
  output inserted.calif_id into @inserted
  select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalif
  select ID [result] from @inserted
  return(0)
end

If @command=4 -- New ccTipoCalifOUT
begin
  If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
  begin
  select cast(-1 as smallint) [result]	-- Disposition already exists
  return(0)
  end

 If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
 begin
	select top 1 @calif_id = calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description order by calif_id desc
	update ccTipoCalifOut set autoTime=0, orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), idTipoLista=0,
	Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0),
	finishPreview=isnull(@finishPreview,0), graphColor=isnull(@graphColor, ''1DB4E2'')
	output inserted.calif_id into @inserted
	where calif_id=@calif_id
	select ID [result] from @inserted
	return(0)
 end

 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, graphColor)
 output inserted.calif_id into @inserted
 select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, isnull(@canReprogram,0), isnull(@keepDial,0),
 isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalifOut
 select ID [result] from @inserted
 return(0)
end
If @command=5 -- Delete Inbound Dispositions
begin
    delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    return(0)
end
if @command=6 -- Delete Outbound Disposition
begin
	delete from ccCalifCamp where tipo=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	delete from cctipoSubCalifRel where tipoSubRel=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	update ccTipoCalifOUT set CalifOut_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	return(0)
end
if @command=7 -- Update Inbound Disposition
begin
	if(exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@Description and calif_id<>@calif_id))
	begin
		select cast(-1 as smallint) [result]	-- Disposition already exists
		return(0)
	end

    UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
    canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),
	EndConversation=isnull(@endConversation,EndConversation)
	output inserted.calif_id into @inserted
    where calif_id=@calif_id

    delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

	select ID [result] from @inserted
    return(0)
end
if @command=8 -- Update Outbound Disposition
begin
	if(exists(select calif_id from ccTipoCalifOUT where CalifOut_Status=1 and Description=@description and calif_id<>@calif_id))
	begin
		select cast(-1 as smallint) [result]	-- Disposition already exists
		return(0)
	end

	UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
	canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  keepDial=isnull(@keepDial,keepDial),
	autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner),
	finishPreview = isnull(@finishPreview,finishPreview)
	output inserted.calif_id into @inserted
	where calif_id=@calif_id

	if @keepDial is not null
	begin
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	end

	select ID [result] from @inserted
	return(0)
end

set nocount off'
	EXEC(@sql)

	set @process = 'CW-5337 5370 5371 DROP PROCEDURE ccsp_GalateaAdminSubdispositions'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSubdispositions'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminSubdispositions;
    end'
	EXEC(@sql)

	set @process = 'CW-5337 5370 5371 Create SP ccsp_GalateaAdminSubdispositions'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSubdispositions]
@command int,
@califSub_id smallint = null,
@califSubIdLst varchar(max) = null,
@califSubDesc varchar(60) = null,
@order varchar(3) = null,
@canReprogram bit = null,
@endConversation bit=null,
@keepDial bit=null,
@autoCB bit=null,
@contactOwner bit=null
AS
set nocount on
declare @inserted table (ID smallint)

if @command=1 -- Load Inbound Subdispositions
begin
  select califSub_id, IsNull(califSubDesc,'''') [califSubDesc], orden, canReprogram,
  IsNull(EndConversation,0) EndConversation
  from ccTipoCalifSub
  where califSub_Status = 1
  order by 2
  return(0)
end

If @command=2 -- Load Outbound Subdispositions
begin
  select califSub_id, IsNull(califSubDesc,'''') [califSubDesc],
  IsNull(canReprogram, 0) [canReprogram],
  IsNull(orden, 0) [orden],
  IsNull(keepDial, 0) [keepDial],
  IsNull(autoCallback, 0) [autoCallback],
  IsNull(contactOwner, 0) [contactOwner]
  from ccTipoCalifSubOut
  where califSubOut_Status = 1
  order by 2
  return(0)
end

if @command=3	-- New Inbound Subdisposition
begin
	if(exists(select califSub_id from ccTipoCalifSub where califSub_Status = 1 and califSubDesc=@califSubDesc))
	begin
		select cast(-1 as smallint) [result]	-- Subdisposition already exists
		return(0)
	end

	if(exists(select califSub_id from ccTipoCalifSub where califSub_Status=0 and califSubDesc=@califSubDesc))
	begin
		select top 1 @califSub_id = califSub_id from ccTipoCalifSub where califSub_Status=0 and califSubDesc=@califSubDesc order by califSub_id desc
		update ccTipoCalifSub set orden=isnull(@order,0), canReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0),
		califSub_Status=1
		output inserted.califSub_id into @inserted
		where califSub_id=@califSub_id
		select ID [result] from @inserted
		return(0)
	end

	insert into ccTipoCalifSub (califSubDesc, orden, canReprogram, califSub_Status, EndConversation)
	select @califSubDesc, isnull(@order,0), isnull(@canReprogram,0), 1, isnull(@endConversation,0)
	select cast(SCOPE_IDENTITY() as smallint) [result]
	return(0)
end

if @command=4	-- New Outbound Subdisposition
begin
	if(exists(select califSub_id from ccTipoCalifSubOUT where califSubOut_Status = 1 and califSubDesc=@califSubDesc))
	begin
		select cast(-1 as smallint) [result]	-- Subdisposition already exists
		return(0)
	end

	if(exists(select califSub_id from ccTipoCalifSubOUT where califSubOut_Status=0 and califSubDesc=@califSubDesc))
	begin
		select top 1 @califSub_id = califSub_id from ccTipoCalifSubOUT where califSubOut_Status=0 and califSubDesc=@califSubDesc order by califSub_id desc
		update ccTipoCalifSubOUT set orden=isnull(@order,0), canReprogram=isnull(@canReprogram,0),idTipoLista=0,
		califSubOut_Status=1, keepDial=isnull(@keepDial,0), autoCallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0)
		output inserted.califSub_id into @inserted
		where califSubDesc=@califSubDesc
		select ID [result] from @inserted
		return(0)
	end

	insert into ccTipoCalifSubOUT (califSubDesc, orden, canReprogram, califSubOut_Status, keepDial, autoCallback, contactOwner)
	select @califSubDesc, isnull(@order,0), isnull(@canReprogram,0), 1, isnull(@keepDial,0), isnull(@autoCB,0), isnull(@contactOwner,0)
	select cast(SCOPE_IDENTITY() as smallint) [result]
	return(0)
end

if @command=5	-- Delete Inbound Subdisposition
begin
	delete cctipoSubCalifRel where tipoSubRel=1 and califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, '',''))
	update cctipocalifSub set califSub_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, '',''))
	return(0)
end

if @command=6	-- Delete Outbound Subdisposition
begin
	delete cctipoSubCalifRel where tipoSubRel=0 and califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, '',''))
	update cctipocalifSubOUT set califSubOut_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, '',''))
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	return(0)
end

if @command=7	-- Update Inbound Subdisposition
begin
	if(exists(select califSub_id from ccTipoCalifSub where califSub_Status=1 and califSubDesc=@califSubDesc and califSub_id<>@califSub_id))
	begin
		select cast(-1 as smallint) [result]	-- Subdisposition already exists
		return(0)
	end

	if @canReprogram=1
	begin
		declare @asignada bit, @can bit
		select @asignada=IB.inbound_id, @can=IB.cam_id
		from cctipoSubCalifRel CR join cctipoCalif TC on CR.calif_id = TC.calif_id and CR.tipoSubRel=1
		join ccCalifCamp CM on TC.calif_id = CM.calif_id and CM.tipo = 0 join ccInbound IB on CM.cam_id = IB.inbound_id
		where califSub_id = cast(@califSub_id as smallint)
		if @asignada is not null and @can is null
		begin
			select cast(-2 as smallint) [result]	-- Cant reprogram, there are not assigned campaign
			return(0)
		end
	end

	update ccTipoCalifSub set califSubDesc=isnull(@califSubDesc, califSubDesc), orden=isnull(@order, orden), canReprogram=isnull(@canReprogram, canReprogram),
	EndConversation=isnull(@endConversation, EndConversation)
	output inserted.califSub_id into @inserted
	where califSub_id=@califSub_id

	delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

	select ID [result] from @inserted
	return(0)
end

if @command=8	-- Update Outbound Subdisposition
begin

	if(exists(select califSub_id from ccTipoCalifSubOUT where califSubOut_Status=1 and califSubDesc=@califSubDesc and califSub_id<>@califSub_id))
	begin
		select cast(-1 as smallint) [result]	-- Subdisposition already exists
		return(0)
	end

	update ccTipoCalifSubOUT set califSubDesc=isnull(@califSubDesc, califSubDesc), canReprogram=isnull(@canReprogram, canReprogram),
	orden=isnull(@order, orden), keepDial=isnull(@keepDial, keepDial), autoCallback=isnull(@autoCB, autoCallback), contactOwner=isnull(@contactOwner,contactOwner)
	output inserted.califSub_id into @inserted
	where califSub_id=@califSub_id
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)

	select ID [result] from @inserted
	return(0)
end


set nocount off'
	EXEC(@sql)

	set @process = 'CW-5373 Agregar el setting que contendra el valor máximo de tiempo de previsualización de registros preview'
	set @sql = '
	if not exists( select * from ccSettings where setting_id = 229)
	begin
		insert into ccSettings (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate)
		values (229, 300, ''Tiempo máximo de previsualización de registros en campaña tipo preview'', 1, ''AGT'', ''Tiempo en segundos que tendrá como máximo un agente para poder previsualizar registros en campaña tipo preview'', ''Maximum time to preview records in a preview campaign'', 1, ''.*'')
	end
	'
	EXEC(@sql)

	set @process = 'CW-5047 Version BD 123.18 Creacion del menu Call Time Summary'
	set @sql = 'if not exists (select * from ccMenus where menu_id = 7190)
    begin
		insert into ccMenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
		values (7190,''Resumen de tiempos de llamada|Call Time Summary'',7000,''B'',10,3,'''',
		''9a09dd61a8306c14d173ebd20a05d6582c9135fa845e4ce3d38665dfd9c26b08c9355e330355896fb4261e4910250353217ed10db48284e30239867f040159b2'')
    end'
    EXEC(@sql)

    set @process = 'CW-5344 no se muestran Campañas de otras areas'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminCampaigns'')
            begin
                DROP PROCEDURE ccsp_GalateaAdminCampaigns;
            end'
    EXEC(@sql)


    set @process = 'CW-5344 no se muestran Campañas de otras areas'
        set @sql = '
            CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS SMALLINT,
                                                        @CampType AS SMALLINT = 0,
                                                        @WorkgroupId AS INT = 0,
                                                        @Id AS INT = 0,
                                                        @AdminId AS SMALLINT = 0,
                                                        @PinUpdate AS SMALLINT = 0,
                                                        @LoadId AS INT = 0,
                                                        @Type AS SMALLINT = 0
            AS
            BEGIN
            set nocount on
            IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type
            BEGIN
                IF @CampType = 1 -- Campaigns Out
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                    BEGIN
                        SELECT CAST(IdCampEsp AS INT) AS Id
                        FROM ccRIACampEspWG
                        WHERE IDWG = @WorkgroupId AND Tipo=1
                        ORDER BY IdCampEsp ASC
                    END
                    ELSE
                    BEGIN
                        raiserror(''ERROR. No existe una lista de campa?as de salida con el id de grupo de trabajo especificado'', 18, 1)
                    END
                END
                IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                    BEGIN
                        SELECT CAST(IdCampEsp AS INT) AS Id
                        FROM ccRIACampEspWG
                        WHERE IDWG = @WorkgroupId AND Tipo=0
                        ORDER BY IdCampEsp ASC
                    END
                    ELSE
                    BEGIN
                        raiserror(''ERROR. No existe una lista de campa?as de entrada con el id de grupo de trabajo especificado'', 18, 1)
                    END
                END
            END

            IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id
                BEGIN
                    IF @CampType = 1 -- Campaigns Out
                        BEGIN
                            IF @Id IS NOT NULL
                                BEGIN
                                    SELECT DISTINCT
                                        camps.cam_id AS Id,
                                        camps.cam_descripcion AS Name,
                                        CAST(graph.graphic_id AS INT) AS Frame,
                                        CAST(1 AS SMALLINT) AS Type,
                                        camps.cam_procesando IsStarted,
                                        a.AreaName as Area
                                    FROM ccCamps camps
                                    LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                                    left join ccRIACat_Areas a on a.IDArea = camps.IDArea
                                    WHERE camps.cam_id = @Id
                                    ORDER BY camps.cam_descripcion ASC;
                                END
                            ELSE
                            BEGIN
                                raiserror(''ERROR. No existe campa?as de salida con el id especificado'', 18, 1)
                            END
                        END
                    IF @CampType = 0 -- Campaigns In (ACD)
                        BEGIN
                            IF @Id IS NOT NULL
                                BEGIN
                                    SELECT DISTINCT
                                        inb.Inbound_id AS Id,
                                        inb.descripcion AS Name,
                                        CAST(graph.graphic_id AS INT) AS Frame,
                                        CAST(0 AS SMALLINT) AS Type,
                                        CAST(inb.Status AS BIT) IsStarted,
                                        a.AreaName AS Area,
                                        inb.chat AS InboundType
                                    FROM ccInbound inb
                                    LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                                    left join ccRIACat_Areas a on a.IDArea = inb.IDArea
                                    WHERE inb.Inbound_id = @Id
                                    ORDER BY inb.descripcion ASC;
                                END
                            ELSE
                                BEGIN
                                    raiserror(''ERROR. No existe campa?as de entrada con el id especificado'', 18, 1)
                                END
                        END
                END

            IF @Option = 3   -- Update OverallTotalNew By Campaign
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            UPDATE ccCampsNvosCB SET OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id
                        END
                    ELSE
                        BEGIN
                            raiserror(''ERROR. No existe la campa?as de entrada con el id especificado'', 18, 1)
                        END
                END

            IF @Option = 4   -- Update Pin from Campaign per Admin
                BEGIN
                    IF @Id IS NOT NULL AND @AdminId IS NOT NULL
                        BEGIN
                            IF @PinUpdate = 1
                                BEGIN
                                    INSERT INTO PinedCampaigns (CampId, AdminId, Type)
                                            VALUES (@Id, @AdminId, @Type);
                                END;
                            IF @PinUpdate = 0
                                BEGIN
                                    DELETE FROM PinedCampaigns
                                    WHERE CampId = @Id AND AdminId = @AdminId AND Type = @Type;
                                END;
                        END
                    ELSE
                        BEGIN
                            raiserror(''ERROR. La campa?as o administrador no existen'', 18, 1)
                        END
                END

            IF @Option = 5   -- Get Pin from Campaign Ids per Admin
                BEGIN
                    IF @AdminId IS NOT NULL
                        BEGIN
                            SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
                            ORDER BY Id ASC
                        END
                    ELSE
                        BEGIN
                            raiserror(''ERROR. El administrador con el id seleccionado no existe'', 18, 1)
                        END
                END

            IF @Option = 6   -- Get Blacklist Ids by Campaign Id
            BEGIN
                IF @Id IS NOT NULL
                    BEGIN
                        DECLARE @BlackListIds VARCHAR(MAX);
                        SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
                        FROM Camplistanegra
                        WHERE cam_id = @Id AND STATUS = 1;
                        SELECT isnull(@BlackListIds,''0'') AS BlackListIds;
                    END
                ELSE
                    BEGIN
                        raiserror(''ERROR. La campa?as con el id seleccionado no existe'', 18, 1)
                    END
            END

            IF @Option = 7   -- Get RegistryListIds Ids by Campaign Id
            BEGIN
                IF (@Id IS NOT NULL AND EXISTS(SELECT * FROM cccamps WHERE cam_id = @Id))
                    BEGIN
                        SELECT TOP 1 list_id FROM ccRIARegistryLists WHERE cam_id = @Id AND status = 2 ORDER BY list_id DESC
                    END
                ELSE
                    BEGIN
                        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                        raiserror(''ERROR. No existe una campa?a con el id especificado'', 18, 1)
                    END
            END

            IF @Option = 8   -- Delete RegistryListIds Ids by LoadId
            BEGIN
                IF (@LoadId IS NOT NULL AND EXISTS(SELECT * FROM ccRIARegistryLists WHERE list_id = @loadID and status <> 0))
                    BEGIN
                        UPDATE ccoCallsOutSource SET cal_status = ''5'' WHERE list_id = @loadID
                        DELETE FROM ccoWorkingTable WHERE list_id = @LoadId
                        exec ccsp_RIARegistryLists @action=6, @list_id = @LoadId
                    END
                ELSE
                    BEGIN
                        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                        raiserror(''ERROR. No existe una carga el id especificado'', 18, 1)
                    END
            END

            IF @option = 9   -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
                    BEGIN
                        DECLARE @table TABLE
                        (camId    INT,
                        campType TINYINT,
                        PRIMARY KEY(camId, campType)
                        );
                        INSERT INTO @table
                            SELECT DISTINCT
                                    IdCampEsp,
                                    Tipo
                            FROM ccRIACampEspWG wg
                            WHERE wg.IDWG IN
                            (
                                SELECT IDWG
                                FROM ccRIAWorkGroupUsers
                                WHERE IDWG <> @WorkgroupId
                                AND User_id = @AdminId
                            );
                        SELECT CAST(B.IdCampEsp AS INT) AS Id,
                            B.Tipo AS Type
                        FROM @table A
                            RIGHT JOIN
                        (
                            SELECT wg.IdCampEsp,
                                wg.Tipo
                            FROM ccRIACampEspWG wg
                            WHERE wg.IDWG = @WorkgroupId
                        ) B ON A.camId = B.IdCampEsp
                            AND A.campType = B.Tipo
                        WHERE A.camId IS NULL
                        ORDER BY IdCampEsp;
                END;
            IF @option = 10  -- Get Agents States with totals per campaign by admin id and campaign type
                BEGIN
                    DECLARE @date datetime = CONVERT(DATE, DATEADD(hh, -3, GETDATE()))
                    DECLARE @Wg TABLE(id INT, PRIMARY KEY(id));
                    DECLARE @tmpAgent TABLE(id INT, PRIMARY KEY(id));
                    DECLARE @tmpCamAgent TABLE(camId INT, userId INT, PRIMARY KEY( camId, userId ));
                    DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT);
                    DECLARE @AgentStatusWithTotals TABLE(CampName VARCHAR(MAX), Total INT, Ready INT, NotReady INT, Dialog INT, Area VARCHAR(MAX));

                    INSERT INTO @Wg
                            SELECT DISTINCT IDWG FROM ccRIAWorkGroupUsers WG, ccUsers_Roles R
                             WHERE WG.User_id = @AdminId OR
                                  (R.User_id = @AdminId
                                    AND R.Rol_id = 7);

                    INSERT INTO @tmpAgent
                            SELECT DISTINCT  A.User_id FROM ccRIAWorkGroupUsers A
                            INNER JOIN @Wg B ON A.IDWG=B.id
                            INNER JOIN ccUsers C ON A.User_id=C.User_id AND C.TipoUser_id=1
                            ORDER BY A.User_id;

                    INSERT INTO @tmpCamAgent
                            SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id FROM ccRIACampEspWG campPerWg
                            INNER JOIN @Wg wg ON wg.Id=campPerWg.IDWG
                            INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG=wg.id
                            INNER JOIN ccUsers C ON wgUser.User_id=C.User_id AND C.TipoUser_id=1
                            WHERE campPerWg.Tipo = @CampType;

                    WITH lastState
                            AS ( SELECT A.user_id,  MAX( A.fecha ) AS fecha
                                FROM ccLogAgentesDia A
                                INNER JOIN @tmpAgent B ON A.User_id=B.id
                                WHERE fecha>= @date
                                GROUP BY user_id )


                            INSERT INTO @AgentStatus
                                SELECT A.camId,  A.userId,
                                ISNULL( B.currentStatus, 0 ) currentStatus,
                                CASE WHEN B.IdCampEsp=A.camId AND B.Tipo = @CampType AND B.currentStatus IN( 4, 5, 6, 9 ) THEN 1 ELSE NULL END AS isCampDialog
                                FROM @tmpCamAgent A
                                LEFT JOIN
                                (
                                    SELECT B.User_id,
                                            B.currentStatus,
                                            B.IdCampEsp,
                                            B.Tipo
                                    FROM lastState A
                                    INNER JOIN
                                    ccLogAgentesDia B
                                    ON A.User_id=B.User_id
                                        AND A.fecha=B.fecha
                                ) B
                                ON A.userId=B.User_id;

                    IF @CampType = 1
                        BEGIN
                            IF @Id <> 0
                                INSERT INTO @AgentStatusWithTotals
                                SELECT  B.cam_descripcion,
                                        COUNT( CurrentState ) as total,
                                        COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ) as ready,
                                        COUNT( CASE WHEN CurrentState NOT IN( 3, 4, 5, 6, 9 )  THEN 1 ELSE NULL END)
                                        + count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)

                                        as notReady,
                                        COUNT( isCampDialog ) as dialog,
                                        C.AreaName
                                FROM @AgentStatus A
                                INNER JOIN ccCamps B on A.CampId=B.cam_id
                                INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                                WHERE A.CampId = @Id
                                GROUP BY B.cam_descripcion, CampId, C.AreaName
                            ELSE
                                INSERT INTO @AgentStatusWithTotals
                                SELECT  B.cam_descripcion,
                                        COUNT( CurrentState ) as total,
                                        COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ) as ready,
                                        COUNT( CASE WHEN CurrentState NOT IN( 3, 4, 5, 6, 9 )  THEN 1 ELSE NULL END)
                                        + count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)

                                        as notReady,
                                        COUNT( isCampDialog ) as dialog,
                                        C.AreaName
                                FROM @AgentStatus A
                                INNER JOIN ccCamps B on A.CampId=B.cam_id
                                INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                                GROUP BY B.cam_descripcion, CampId, C.AreaName
                        END
                    ELSE
                        BEGIN
                            IF @Id <> 0
                                INSERT INTO @AgentStatusWithTotals
                                SELECT  B.descripcion,
                                        COUNT( CurrentState ),
                                        COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ),
                                        COUNT( CASE WHEN CurrentState NOT IN(3, 4, 5, 6, 9 ) THEN 1 ELSE NULL END)
                                        + count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)
                                        ,
                                        COUNT( isCampDialog ),
                                        C.AreaName
                                FROM @AgentStatus A
                                INNER JOIN ccInbound B on A.CampId = B.Inbound_id
                                INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                                WHERE A.CampId = @Id
                                GROUP BY  B.descripcion, CampId , C.AreaName
                            ELSE
                                INSERT INTO @AgentStatusWithTotals
                                SELECT  B.descripcion,
                                        COUNT( CurrentState ),
                                        COUNT( CASE WHEN CurrentState=3 THEN 1 ELSE NULL END ),
                                        COUNT( CASE WHEN CurrentState NOT IN(3, 4, 5, 6, 9 ) THEN 1 ELSE NULL END)
                                        + count (case when isCampDialog is null and  CurrentState IN( 4, 5, 6, 9 ) then 1 else null end)
                                        ,
                                        COUNT( isCampDialog ),
                                        C.AreaName
                                FROM @AgentStatus A
                                INNER JOIN ccInbound B on A.CampId = B.Inbound_id
                                INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                                    WHERE B.chat = 0
                                GROUP BY  B.descripcion, CampId , C.AreaName
                        END


                    SELECT * FROM @AgentStatusWithTotals
                    ORDER BY CampName
                END;

            END'


    EXEC(@sql)


	set @process = 'CW-5376 5419 DROP PROCEDURE ccsp_GalateaAdminSubdispositionRelations'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSubdispositionRelations'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminSubdispositionRelations;
    end'
    EXEC(@sql)


    set @process = 'CW-5376 5419 CREATE PROCEDURE ccsp_GalateaAdminSubdispositionRelations'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSubdispositionRelations]
@command int,
@type tinyint = null, --0=Outbound, 1=Inbound
@califSub_id varchar(max) = null,
@calif_id smallint = null
AS
set nocount on

If @command = 1
begin
	select cast(0 as int) [type],
		r.calif_id,
		r.califSub_id
	from cctipoSubCalifRel r inner join ccTipoCalifSub t on r.califSub_id = t.califSub_id and r.tipoSubRel = 1
	where t.califSub_Status = 1
	UNION
	select cast(1 as int) [type],
		r.calif_id,
		r.califSub_id
	from cctipoSubCalifRel r inner join ccTipoCalifSubOUT t on r.califSub_id = t.califSub_id and r.tipoSubRel = 0
	where t.califSubOut_Status = 1
	order by [type], calif_id, califSub_id
end
if @command=2  --Asignar subcalificacion a una calificacion
begin
	if @type=1 and (select cast(sum(isnull(cast(canReprogram as tinyint),0)) as bit) FROM cctipocalifSub where califSub_id in
	(select value from dbo.fn_RIASplitDelimited (@califSub_id, '','')))>0
	and not exists (select IB.cam_id from cctipocalif CO join ccCalifCamp CF on  CF.calif_id = CO.calif_id and CF.tipo = 0
	join ccInbound IB on IB.Inbound_id = CF.cam_id where IB.cam_id is not null and CO.calif_id = @calif_id)
	begin
		select cast(-2 as smallint) [result]	-- Cant reprogram, there are not assigned campaign
		return(0)
	end

	insert cctipoSubCalifRel (calif_id, califSub_id, tipoSubRel)
	select @calif_id [calif_id], S.value [califSub_id], @type [Tipo]
	from dbo.fn_RIASplitDelimited (@califSub_id, '','') S
	where cast(@calif_id as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@type as varchar(10)) not in
   (select cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) from cctipoSubCalifRel)
	and S.value is not null

	if @type=0
	begin
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	end

	select cast(1 as smallint) [result]	 -- Done!
	return(0)
end
if @command=3	--Desasignacion de subcalificacion
begin
	delete cctipoSubCalifRel
    where cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) in
    (select cast(@calif_id as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@type as varchar(10))
    from dbo.fn_RIASplitDelimited (@califSub_id, '','') S)

    if @type=0
	begin
      update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	end
end

set nocount off'
    EXEC(@sql)


  set @process = 'Actualizacion de configuracion de campañas Galatea'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetOutboundConfiguration'')
    begin
        DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration;
    end'
  EXEC(@sql)



set @process = 'Actualizacion de configuracion de campañas Galatea'
	set @sql = 'CREATE PROCEDURE ccsp_GalateaGetOutboundConfiguration
@adminID int,
@campID int
AS
BEGIN

	declare @AllCampaigns table
	(cam_id smallint, cam_Descripcion varchar(40), cam_tNotas smallint, cam_ocupado smallint,cam_noInt_ocupado smallint, cam_inter_ocupado smallint,
	cam_nocontesto smallint, cam_noInt_nocontesto smallint, cam_inter_nocontesto smallint, cam_fax smallint, cam_noInt_fax smallint, cam_inter_fax smallint,
	cam_modomanual smallint, ANI varchar(15), cam_ShowCalifWnd bit, cam_StartTimerOnHangUp bit, editableCallKey bit, cam_tNoContesta smallint, iTipoDial smallint,
	detectAnswerMachine smallint,detectVoiceMail smallint, compliance smallint, cam_inter_graba smallint, cam_noint_graba smallint, progDial smallint, excCallBack smallint, dialOrder smallint,
	dialPrefix varchar(10),dialPrefixMan varchar(10), dialPrefixXfe varchar(10),listenManualCall bit,  stopRecording bit,abandonCallback bit, frame smallint,
	t_autoCB smallint, id_anilist int, tDialonWrapUp smallint, viewMode tinyint, queSize smallint, DNCScrub int, callerIdDesc varchar (15), timeZoneRule int,
	callsBySurvey int, ivrScript int, surveyPctg int,call_record smallint,startStopRecording bit,  leaveRecMessage  bit, manualCallOnChat bit,
	callBackSurveyAgent bit, callBackSurveyClient bit, isRelationSurvey bit, funcEspDtmf int,  sipHdrFormat varchar(255), cam_inter_cancelled smallint,
	prefijo varchar(40),enbleprefix bit )

	 INSERT INTO @AllCampaigns EXEC ccsp_RIAConfCamp @adminID

	 SELECT dialPrefixMan DialPrefixMan, dialPrefixXfe DialPrefixXfe, listenManualCall  ListenManualCall, stopRecording StopRecording, abandonCallback AbandonCallBack,
	 t_autoCB AutoCB,id_anilist IdIstANI,tDialonWrapUp TDialOnWrapup, queSize Quesize, DNCScrub, callerIdDesc CallerIdDesc, timeZoneRule TimeZoneRule,callsBySurvey CallsBySurvey,
	 ivrScript IvrScript, surveyPctg SurveyPctg, call_record CallRecord,startStopRecording StartStopRecording, leaveRecMessage LeaveRecMessage,manualCallOnChat ManualCallOnChat,
	 callBackSurveyClient CallBackSurveyClient, callBackSurveyAgent CallBackSurveyAgent, funcEspDtmf FuncEspDtmf,sipHdrFormat SipHdrsCfg, dialPrefix DialPrefix,
	 prefijo Prefix, dialOrder DialOrder, progDial ProgDial, cam_Descripcion CamDescription, cam_tNotas CamTnotas, cam_ocupado CamBusy, cam_noInt_ocupado CamNoIntBusy,
	 cam_inter_ocupado CamInterBusy,cam_nocontesto CamNoAnswer, cam_noInt_nocontesto CamNoIntNoAnswer,cam_inter_nocontesto CamInterNoAnswer, (cam_inter_cancelled/60) CamInterCancelled,
	 cam_fax CamFax, cam_noInt_fax CamNoIntFax,cam_inter_fax CamInterFax, cam_modomanual CamModoManual,ANI ,cam_StartTimerOnHangUp CamStartTimerOnHangUp,
	 editableCallKey EditableCallKey, cam_tNoContesta CamTNoAnswer, iTipoDial  CamIntensiveDialing, detectAnswerMachine DetectAnswerMachine, detectVoiceMail DetectVoiceMail,
	 compliance Compliance, cam_inter_graba CamInterRecord,cam_noint_graba CamNoIntRecord,excCallBack ExcCallBack, cam_ShowCalifWnd CamShowCalifWnd
	 from @AllCampaigns WHERE cam_id = @campID
END'
  EXEC(@sql)

 
 set @process = 'Create index IX_messageEmail_I'
 set @sql =  'if not exists (select * from sys.indexes where name = N''IX_messageEmail_I'' and object_id = OBJECT_ID(N''message''))

	
CREATE NONCLUSTERED INDEX IX_messageEmail_I
ON [dbo].[message] ([conversationId])
include ([messageId], [messageStatusId], [date], [tQueue], [tsend])
'
 EXEC(@sql)

 set @process = 'ALTER SP ccsp_MailInitialStatistics'
  set @sql = 'ALTER PROCEDURE [dbo].[ccsp_MailInitialStatistics]
@inboundId int=0,
@Option AS SMALLINT=0,
@User_id AS SMALLINT=0
AS
BEGIN

SET NOCOUNT ON;
declare @from datetime,@to datetime
  set @from =CONVERT(datetime, convert(varchar(10),getdate(),121))
  set @to =dateadd(dd,1,@from)

  

if(@Option=0)
begin
  select
  count(*) received,
  count(case when messageStatusId = 1 then 1 else null end) pending,
  count(case when messageStatusId in (2,3) then 1 else null end) assigned,
  count(case when messageStatusId = 4 then 1 else null end) unassigned,
  count(case when messageStatusId in (5,6) then 1 else null end) sent,
  count(case when messageStatusId = 7 then 1 else null end) rejected,
  count(case when messageStatusId = 8 then 1 else null end) programFwd,
  count(case when messageStatusId = 9 then 1 else null end) forwarding,
  count(case when messageStatusId in (10,11) then 1 else null end) closed,
  count(case when messageStatusId = 3 then 1 else null end) active,
  isnull(AVG(B.twait + B.tretention + B.tresponse),0) avgtAtention,
  isnull(AVG(B.twait),0) avgtWait,
  isnull(MAX(B.twait),0) maxtWait
  from conversation A with (nolock, index(PK__conversation__31190FD5))
  inner join message B with(nolock, index (IX_messageEmail_I)) on A.conversationId=b.conversationId
  where inboundId= @inboundId
  and (
    (
     messageStatusId in (1,4) 
	 or tQueue   between @from and @to 
	or tSend   between @from and @to    
 
    )
    or [date] between @from and @to
   )
end
if @Option = 1
BEGIN

  select
  count(*) received,
  count(case when messageStatusId = 1 then 1 else null end) pending,
  count(case when messageStatusId in (2,3) then 1 else null end) assigned,
  count(case when messageStatusId = 4 then 1 else null end) unassigned,
  count(case when messageStatusId in (5,6) then 1 else null end) sent,
  count(case when messageStatusId = 7 then 1 else null end) rejected,
  count(case when messageStatusId = 8 then 1 else null end) programFwd,
  count(case when messageStatusId = 9 then 1 else null end) forwarding,
  count(case when messageStatusId in (10,11) then 1 else null end) closed,
  count(case when messageStatusId = 3 then 1 else null end) active ,
  isnull(AVG(msg.twait + msg.tretention + msg.tresponse),0) avgtAtention,
  isnull(AVG(msg.twait),0) avgtWait,
  isnull(MAX(msg.twait),0) maxtWait,
  InboundId inboundId
  from message msg with (nolock, index(PK__message__320D340E)) 
  join conversation con with (nolock, index(PK__conversation__31190FD5)) on con.conversationId =msg.conversationId
  where inboundId in (select inbound_id from ccInbound where inbound_id in (SELECT cam_id FROM ccSupervisorCam WHERE user_id = @User_id AND tipo = 0) and chat = 3)
  and (
    (
     messageStatusId in (1,4) 
     or tQueue between @from and @to 
	or tSend  between @from and @to      
)
    or [date] between @from and @to
   )
  GROUP BY InboundId
  END
END'
   EXEC(@sql)


set @process = 'CW-5369 ALTER table ccRiachats'
set @sql = 'ALTER TABLE ccRiachats ALTER COLUMN clientName VARCHAR (100)'
EXEC(@sql)

  set @process = 'CW-5430 Mostrar el frame guardado anteriormente'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetOutboundConfiguration'')
    begin
        DROP PROCEDURE ccsp_GalateaGetOutboundConfiguration;
    end'
  EXEC(@sql)

    set @process = 'CW-5430 Mostrar el frame guardado anteriormente'
	set @sql = ' CREATE PROCEDURE ccsp_GalateaGetOutboundConfiguration
@adminID int,
@campID int
AS
BEGIN

	declare @AllCampaigns table 
	(cam_id smallint, cam_Descripcion varchar(40), cam_tNotas smallint, cam_ocupado smallint,cam_noInt_ocupado smallint, cam_inter_ocupado smallint,
	cam_nocontesto smallint, cam_noInt_nocontesto smallint, cam_inter_nocontesto smallint, cam_fax smallint, cam_noInt_fax smallint, cam_inter_fax smallint,
	cam_modomanual smallint, ANI varchar(15), cam_ShowCalifWnd bit, cam_StartTimerOnHangUp bit, editableCallKey bit, cam_tNoContesta smallint, iTipoDial smallint,
	detectAnswerMachine smallint,detectVoiceMail smallint, compliance smallint, cam_inter_graba smallint, cam_noint_graba smallint, progDial smallint, excCallBack smallint, dialOrder smallint,
	dialPrefix varchar(10),dialPrefixMan varchar(10), dialPrefixXfe varchar(10),listenManualCall bit,  stopRecording bit,abandonCallback bit, frame smallint,
	t_autoCB smallint, id_anilist int, tDialonWrapUp smallint, viewMode tinyint, queSize smallint, DNCScrub int, callerIdDesc varchar (15), timeZoneRule int,
	callsBySurvey int, ivrScript int, surveyPctg int,call_record smallint,startStopRecording bit,  leaveRecMessage  bit, manualCallOnChat bit, 
	callBackSurveyAgent bit, callBackSurveyClient bit, isRelationSurvey bit, funcEspDtmf int,  sipHdrFormat varchar(255), cam_inter_cancelled smallint, 
	prefijo varchar(40),enbleprefix bit )
	 
	 INSERT INTO @AllCampaigns EXEC ccsp_RIAConfCamp @adminID

	 SELECT dialPrefixMan DialPrefixMan, dialPrefixXfe DialPrefixXfe, listenManualCall  ListenManualCall, stopRecording StopRecording, abandonCallback AbandonCallBack,
	 t_autoCB AutoCB,id_anilist IdIstANI,tDialonWrapUp TDialOnWrapup, queSize Quesize, DNCScrub, callerIdDesc CallerIdDesc, timeZoneRule TimeZoneRule,callsBySurvey CallsBySurvey,
	 ivrScript IvrScript, surveyPctg SurveyPctg, call_record CallRecord,startStopRecording StartStopRecording, leaveRecMessage LeaveRecMessage,manualCallOnChat ManualCallOnChat,
	 callBackSurveyClient CallBackSurveyClient, callBackSurveyAgent CallBackSurveyAgent, funcEspDtmf FuncEspDtmf,sipHdrFormat SipHdrsCfg, dialPrefix DialPrefix,
	 prefijo Prefix, dialOrder DialOrder, progDial ProgDial, cam_Descripcion CamDescription, cam_tNotas CamTnotas, cam_ocupado CamBusy, cam_noInt_ocupado CamNoIntBusy,
	 cam_inter_ocupado CamInterBusy,cam_nocontesto CamNoAnswer, cam_noInt_nocontesto CamNoIntNoAnswer,cam_inter_nocontesto CamInterNoAnswer, (cam_inter_cancelled/60) CamInterCancelled,
	 cam_fax CamFax, cam_noInt_fax CamNoIntFax,cam_inter_fax CamInterFax, cam_modomanual CamModoManual,ANI ,cam_StartTimerOnHangUp CamStartTimerOnHangUp,
	 editableCallKey EditableCallKey, cam_tNoContesta CamTNoAnswer, iTipoDial  CamIntensiveDialing, detectAnswerMachine DetectAnswerMachine, detectVoiceMail DetectVoiceMail, 
	 compliance Compliance, cam_inter_graba CamInterRecord,cam_noint_graba CamNoIntRecord,excCallBack ExcCallBack, cam_ShowCalifWnd CamShowCalifWnd, frame Frame
	 from @AllCampaigns WHERE cam_id = @campID
END
'
  EXEC(@sql)

  set @process = 'CW-470 se modifica sp ccsp_RIAABCChat'
    set @sql = 'ALTER Procedure [dbo].[ccsp_RIAABCChat]
@OperationType tinyint = 0, -- 0:Select | 1:Insert | 2:Select Excel | 3:DateRange | 4:Admins | 5:Agents | 6:GalateaAdmin
@TipoMsgChat tinyint = null,
@User_id_Adm varchar(8000) = null,
@User_id_Agt varchar(8000) = null,
@ChatMsg varchar(1500) = null,
@Fecha_Chat_ini datetime = null,
@Fecha_Chat_fin datetime = null,
@IDArea int = null
AS
set nocount on

if @OperationType not in (0,1,2,3,4,5,6,7)
    raiserror(''Invalid Operation Type'', 18, 1)

if @OperationType=0
 begin
    Declare @User_id_Adm2 smallint, @User_id_Agt2 smallint, @Fecha2 varchar(10), @Fecha3 varchar(10), @Fecha4 varchar(10)
    CREATE TABLE #CHAT (id int identity, xmlType tinyint, User_id_Adm smallint, User_id_Agt smallint, date varchar(10),
     iniTime varchar(10), endTime varchar(10), TipoMsgChat tinyint, text varchar(1500), time varchar(10))

    Declare CursorChat Cursor For
    -- Realizamos la Select para extraer las tablas
    select distinct User_id_Adm, User_id_Agt, convert(varchar(25), Fecha_Chat, 103) date
     , min(convert(varchar(8), Fecha_Chat, 108)) iniTime
     , max(convert(varchar(8), Fecha_Chat, 108)) endTime
    from ccRIAChat_Log --with (nolock, index(PK_ccRIAChat_Log))
    where TipoMsgChat = case when isnull(@TipoMsgChat,0)=0 then TipoMsgChat else @TipoMsgChat end
     and User_id_Adm in (select case when isnull(@User_id_Adm,''0'') in (''0'','''') then User_id_Adm else value end from dbo.fn_RIASplitDelimited (@User_id_Adm, '',''))
     and User_id_Agt in (select case when isnull(@User_id_Agt,''0'') in (''0'','''') then User_id_Agt else value end from dbo.fn_RIASplitDelimited (@User_id_Agt, '',''))
     and Fecha_Chat between isnull(@Fecha_Chat_ini, ''19000101 00:00'')
     and isnull(@Fecha_Chat_fin, DATEADD(hh, 1, getdate()))
    group by User_id_Adm, User_id_Agt, convert(varchar(25), Fecha_Chat, 103)
    Order by date desc, iniTime desc

    Open CursorChat
    Fetch Next From CursorChat
    Into @User_id_Adm2, @User_id_Agt2, @Fecha2, @Fecha3, @Fecha4

    if @@FETCH_STATUS = 0
     Begin

    -- Mientras hay resultados para procesar
        While @@FETCH_STATUS = 0
         Begin
            insert into #CHAT select ''1'' xmlType, @User_id_Adm2 User_id_Adm, @User_id_Agt2 User_id_Agt,
             @Fecha2 date, @Fecha3 iniTime, @Fecha4 endTime, 0 TipoMsgChat, '''' text, '''' time

            -- Iniciamos el proceso
            insert into #CHAT select ''0'' xmlType, @User_id_Adm2 User_id_Adm, @User_id_Agt2 User_id_Agt, @Fecha2 date, '''' iniTime,
            '''' endTime, TipoMsgChat, ChatMsg text, convert(varchar(25), Fecha_Chat, 108) time
            from ccRIAChat_Log where User_id_Adm = @User_id_Adm2 and User_id_Agt = @User_id_Agt2 and convert(varchar(25), Fecha_Chat, 103) = @Fecha2
            order by time desc

            -- Recuperamos la siguiente fila
            Fetch Next From CursorChat
                Into @User_id_Adm2, @User_id_Agt2, @Fecha2, @Fecha3, @Fecha4
         End
     End


    Close CursorChat
    Deallocate CursorChat
    select C.xmlType, U2.Nombres + isnull('' '' + U2.ApellidoPaterno, '''') + isnull('' '' + U2.ApellidoMaterno, '''') Nombre_Adm,
     U1.Nombres + isnull('' '' + U1.ApellidoPaterno, '''') + isnull('' '' + U1.ApellidoMaterno, '''') Nombre_Agt,
    C.date, C.iniTime, C.endTime, C.TipoMsgChat, C.text, C.time
    from #CHAT C join ccUsers U1 on U1.user_id = C.User_id_Agt
     join ccUsers U2 on U2.user_id = C.User_id_Adm
    order by C.id
    return(0)
 end

if @OperationType=1
 begin
    if  @TipoMsgChat is NULL or @User_id_Adm is NULL or @User_id_Agt is NULL or @ChatMsg is NULL
        raiserror(''Invalid Data 3'', 18, 3)

    insert ccRIAChat_Log (TipoMsgChat, User_id_Adm, User_id_Agt, ChatMsg)
    select @TipoMsgChat, @User_id_Adm, @User_id_Agt, @ChatMsg
    select SCOPE_IDENTITY() ChatID
    return(0)
 end

if @OperationType=2
 begin
    -- Realizamos la Select para extraer las tablas
    if isnull(@User_id_Adm,''0'')=''0'' and isnull(@User_id_Agt,''0'')=''0'' and isnull(@TipoMsgChat,0)=0 and (@Fecha_Chat_ini is null and @Fecha_Chat_fin is null)
        raiserror(''Invalid Data 2'', 18, 2)

    create table #ExcelChat (Fecha_Chat datetime, TipoMsgChat varchar(30), Nombre_Adm varchar(100), Nombre_Agt varchar(100), ChatMsg varchar(2000))

    insert into #ExcelChat
    select Fecha_Chat,
    case C.TipoMsgChat when 1 then ''Admin -> Agent'' when 2 then ''Admin <- Agent'' else ''Admin -> Global'' end TipoMsgChat,
    U2.Nombres + isnull('' '' + U2.ApellidoPaterno, '''') + isnull('' '' + U2.ApellidoMaterno, '''') Nombre_Adm,
    U1.Nombres + isnull('' '' + U1.ApellidoPaterno, '''') + isnull('' '' + U1.ApellidoMaterno, '''') Nombre_Agt,
    ''"''+ REPLACE(C.ChatMsg,''"'',''""'') + ''"'' as ChatMsg
    from ccRIAChat_Log C join ccUsers U1 on U1.user_id = C.User_id_Agt
     join ccUsers U2 on U2.user_id = C.User_id_Adm
    where TipoMsgChat = case when isnull(@TipoMsgChat,0)=0 then TipoMsgChat else @TipoMsgChat end
     and User_id_Adm in (select case when isnull(@User_id_Adm,''0'')=''0'' then User_id_Adm else value end from dbo.fn_RIASplitDelimited (@User_id_Adm, '',''))
     and User_id_Agt in (select case when isnull(@User_id_Agt,''0'')=''0'' then User_id_Agt else value end from dbo.fn_RIASplitDelimited (@User_id_Agt, '',''))
     and Fecha_Chat between isnull(@Fecha_Chat_ini, ''19000101 00:00'')
     and isnull(@Fecha_Chat_fin, DATEADD(hh, 1, getdate()))

    if (select valor from ccsettings where setting_id=27) = 0
     begin
        select convert(varchar(10), Fecha_Chat, 103)+'' ''+convert(varchar(8), Fecha_Chat, 108) Fecha_Chat, TipoMsgChat, Nombre_Adm, Nombre_Agt, ChatMsg from #ExcelChat Order by 1 desc
     end

    else
     begin
        select convert(varchar(10), Fecha_Chat, 101)+'' ''+convert(varchar(8), Fecha_Chat, 108) timestamp, TipoMsgChat MsgChatType, Nombre_Adm Adm_Name, Nombre_Agt Agt_Name, ChatMsg ChatMsg from #ExcelChat Order by 1 desc
     end

    return(0)
 end

if @OperationType=3
 begin
    set @Fecha_Chat_fin=getdate()
    select @Fecha_Chat_ini=dateadd(year,-1,@Fecha_Chat_fin)
    from ccRIAChat_Log
    select  convert(varchar(11),@Fecha_Chat_ini ,103) Fecha_Chat_MIN, convert(varchar(11),@Fecha_Chat_fin,103)Fecha_Chat_MAX
    return(0)
 end

if @OperationType=4
 begin
    if not exists(select IDArea from ccRIACat_Areas where IDArea = @IDArea) or not exists(select user_id from ccusers where TipoUser_id in(2,6) and IDArea=@IDArea)
        raiserror(''Invalid Area'', 18, 4)

    select User_id, Login, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') Nombre
    from ccusers where TipoUser_id in(2,6) and IDArea=@IDArea
    order by login, Nombre
    return(0)
 end

if @OperationType=5
 begin
    if not exists(select IDArea from ccRIACat_Areas where IDArea = @IDArea) or not exists(select user_id from ccusers where TipoUser_id in(1) and IDArea=@IDArea)
        raiserror(''Invalid Area'', 18, 4)

    select User_id, Login, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') Nombre, Sexo gender
    from ccusers where TipoUser_id in(1) and IDArea=@IDArea
    order by login, Nombre
    return(0)
 end

 if @OperationType=6
 begin
    --This action was created for Galatea''s Agent Chat Log
    SELECT  convert(varchar(10),Fecha_Chat,108) HourChat,
    C.TipoMsgChat , u2.Login AdminLogin,
    U1.Login AgentLogin,
    ''"''+ REPLACE(C.ChatMsg,''"'',''""'') + ''"'' AS ChatMsg
    FROM ccRIAChat_Log C join ccUsers U1 on U1.user_id = C.User_id_Agt
     JOIN ccUsers U2 on U2.user_id = C.User_id_Adm
    WHERE 
      User_id_Agt in (select case when isnull(@User_id_Agt,''0'')=''0'' then User_id_Agt else value end from dbo.fn_RIASplitDelimited (@User_id_Agt, '',''))
     AND Fecha_Chat BETWEEN ISNULL(@Fecha_Chat_ini, ''19000101 00:00'')
     AND ISNULL(@Fecha_Chat_fin, DATEADD(hh, 1, getdate()))

 end

 if @OperationType=7
  begin
    --This action was created for Galatea''s Admin Chat (Last Message)
    select @Fecha_Chat_ini = convert(datetime,convert(varchar(11),getdate()))
    select @Fecha_Chat_fin = GETDATE()
    ;with Chat as (
    select user_id_Agt, max(chatId) as ChatId
    from ccRiaChat_Log
    where Fecha_Chat between @Fecha_Chat_ini and @Fecha_Chat_fin
    group by user_id_Agt)
    select B.ChatID, B.TipoMsgChat, B.User_id_Agt, B.ChatMsg, B.Fecha_Chat from Chat A
    inner join ccRIAChat_Log B on A.ChatId=B.ChatID
    where User_id_Adm=@User_id_Adm
    return(0)
  end

select 0
set nocount off'
  EXEC(@sql)

  set @process = 'CW-5292 DROP índice duplicado para tabla ccoCallsOutSource'  
  set @sql = 'if exists (select name from sysindexes
  where name = ''IX_ccoCallsOutSource_18'')
   DROP INDEX IX_ccoCallsOutSource_18 ON  ccoCallsOutSource;'
  EXEC(@sql)

  set @process = 'CW-5292 Creación de índice agrupado para tabla Camplistanegra'  
  set @sql = 'if not exists (select name from sysindexes where name = ''IX_list'')
  CREATE CLUSTERED INDEX IX_list ON Camplistanegra(idtipolista)'
  EXEC(@sql)

  set @process = 'CW-5292 Creación de índice agrupado para tabla cclistanegra' 
  set @sql = 'if not exists (select name from sysindexes where name = ''IX_list_Hashtel'')
  CREATE CLUSTERED INDEX [IX_list_Hashtel] ON cclistanegra(Hashtel)'
  EXEC(@sql)

  set @process = 'CW-5292 Drop report ListaNegra' 
  set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_InsertDNCList'')
    begin
      DROP PROCEDURE ccsp_InsertDNCList;
    end'
  EXEC(@sql)

  set @process = 'CW-5292 CREATE SP ccsp_InsertDNCList' 
  set @sql = 'CREATE PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey bigint=null
WITH RECOMPILE
AS

declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)

insert into cclistanegra(telefono,idtipolista,HashKey) values(@telephone, @ln_id,@hashCalKey)

CREATE TABLE [dbo].[#mycamps] (
  [campsid] [int] NULL
  )

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

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

CREATE CLUSTERED INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltemp]([callout_id]) 
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

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) 

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @tel = dbo.completa(@telephone, @pais, @ld)

--declare @Sql nvarchar(max)
--declare @fecha datetime = dateadd(dd,-30,getdate())
declare @fech datetime = getdate()-30
if @hashCalKey is not null or @hashCalKey > 0
begin

  insert into [#myprincipaltemp] 
  SELECT a.callout_id as callout_id, a.cam_id,''3'',cast(@ln_id as nvarchar) as idtipolista , a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
  FROM [ccoCallsOutSource] as a, #mycamps as b with(nolock) WHERE a.cam_id = b.campsid 
  AND dbo.hashList(cal_Key) = @hashCalKey and  cal_fechadial > @fech
  
end
else begin
  insert into [#myprincipaltemp]
  SELECT a.callout_id as callout_id, a.cam_id,''3'',cast(@ln_id as nvarchar) as idtipolista , a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
  FROM [ccoCallsOutSource] as a, #mycamps as b with(nolock) WHERE a.cam_id = b.campsid
  and (@tel  IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) 
  or right(@tel,10) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) 
  or right(@tel,11) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5])) 
  and  cal_fechadial > @fech
  
end

--EXEC(@Sql)

if EXISTS (select * from #myprincipaltemp)
  begin
    /******************/
    /*** Telefono 1 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono = @tel or cal_telefono = right(@tel, 10) or cal_telefono = right(@tel, 11))

    if EXISTS (select * from #mytemp)
    begin
      -- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable with(rowlock)
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and
      cs.cal_telefono = wt.cal_telefono
      and rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
                 + cs.cal_telefono3 + ''         ''
                 + cs.cal_telefono4 + ''         ''
                 + cs.cal_telefono5 + ''         ''),13)) = ''''

      -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
      update ccoWOrkingTable 
      set cal_telefono = rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
                        + cs.cal_telefono3 + ''         ''
                        + cs.cal_telefono4 + ''         ''
                        + cs.cal_telefono5 + ''         ''),13))
      from ccoCallsOutSource cs 
      inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
      inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono1 de CS
      update ccoCallsOutSource 
      set cal_telefono = ''''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech

      truncate table #mytemp
    end

    /******************/
    /*** Telefono 2 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono2,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono2 = @tel or cal_telefono2 = right(@tel, 10) or cal_telefono2 = right(@tel, 11))

    if EXISTS (select * from #mytemp)
    begin
      -- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable 
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono2= wt.cal_telefono 
      and rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
                 + cs.cal_telefono4 + ''         ''
                 + cs.cal_telefono5 + ''         ''),13)) = ''''

      -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
      update ccoWOrkingTable 
      set cal_telefono = rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
                        + cs.cal_telefono4 + ''         ''
                        + cs.cal_telefono5 + ''         ''),13))
      from ccoCallsOutSource cs 
      inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
      inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono2= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono2 de CS
      update ccoCallsOutSource 
      set cal_telefono2 = ''''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech

      truncate table #mytemp
    end

    /******************/
    /*** Telefono 3 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono3,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono3 = @tel or cal_telefono3 = right(@tel, 10) or cal_telefono3 = right(@tel, 11))

    if EXISTS (select * from #mytemp)
    begin
      -- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable 
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono3= wt.cal_telefono  
      and  rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
                  + cs.cal_telefono5 + ''         ''),13)) = ''''

      -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
      update ccoWOrkingTable 
      set cal_telefono = rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
                        + cs.cal_telefono5 + ''         ''),13))
      from ccoCallsOutSource cs 
      inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
      inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono3= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono3 de CS
      update ccoCallsOutSource 
      set cal_telefono3 = ''''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech

      truncate table #mytemp
    end

    /******************/
    /*** Telefono 4 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono4,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono4 = @tel or cal_telefono4 = right(@tel, 10) or cal_telefono4 = right(@tel, 11))

    if EXISTS (select * from #mytemp)
    begin
      -- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable 
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono4= wt.cal_telefono 
      and rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13)) = ''''

      -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
      update ccoWOrkingTable 
      set cal_telefono = rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13))
      from ccoCallsOutSource cs 
      inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
      inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono4= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono4 de CS
      update ccoCallsOutSource 
      set cal_telefono4 = ''''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech

      truncate table #mytemp
    end

    /******************/
    /*** Telefono 5 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono5,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono5 = @tel or cal_telefono5 = right(@tel, 10) or cal_telefono5 = right(@tel, 11))

    if EXISTS (select * from #mytemp)
    begin
      -- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable 
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > @fech and cs.cal_telefono5= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono5 de CS
      update ccoCallsOutSource 
      set cal_telefono5 = ''''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > @fech
    end
  end

drop table [#myprincipaltemp]
drop table [#mytemp]
drop table [#mycamps]   
'
  EXEC(@sql)

  set @process = 'CW-5292 Drop Upload ListaNegra' 
  set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAUploadBLst'')
    begin
      DROP PROCEDURE ccsp_RIAUploadBLst;
    end'
  EXEC(@sql)

  set @process = 'CW-5292 CREATE SP SP_ccsp_RIAUploadBLst' 
  set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAUploadBLst] @command TINYINT, @telephone VARCHAR(20) = 0, @idtipolista INT, @calKey AS VARCHAR(20) = NULL
AS
SET NOCOUNT ON

DECLARE @hashCalKey BIGINT, @hashPhone BIGINT

SELECT @hashPhone = dbo.hashPhone(@telephone)

IF @calKey IS NOT NULL
BEGIN
  SELECT @hashCalKey = dbo.hashList(@calKey)
END

IF @hashCalKey IS NULL
BEGIN
  IF @command IN (1, 4) --LookForNumber 
    AND EXISTS (
      SELECT idtipolista
      FROM cclistanegra
      WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idtipolista
      )
  BEGIN
    SELECT 1

    RETURN (0)
  END
END
ELSE
BEGIN
  IF @command IN (1, 4) --LookForNumber 
    AND EXISTS (
      SELECT idtipolista
      FROM cclistanegra
      WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
      )
  BEGIN
    SELECT 1

    RETURN (0)
  END
END

IF @command = 1 --Insert Number
BEGIN
  EXEC ccsp_InsertDNCList @telephone, @idtipolista, @hashCalKey

  INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
  VALUES (@telephone, 1, @idtipolista)

  RETURN (0)
END

IF @command = 2 --Delete Number
BEGIN
  INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
  VALUES (@telephone, 5, @idtipolista)

  IF @hashCalKey IS NULL
  BEGIN
    DELETE
    FROM cclistanegra
    WHERE Hashtel = @hashPhone AND HashKey IS NULL
  END
  ELSE
  BEGIN
    DELETE
    FROM cclistanegra
    WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey
  END

  RETURN (0)
END

IF @command = 3 --Reemplaza
BEGIN
  INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
  SELECT telefono, 4, @idtipolista
  FROM cclistanegra
  WHERE idtipolista = @idtipolista

  DELETE
  FROM cclistanegra
  WHERE idtipolista = @idtipolista

  RETURN (0)
END

IF @command = 5 --Delete by idtipolista
BEGIN
  UPDATE ccTiposListaNegra
  SET STATUS = 0
  WHERE idtipolista = @idtipolista

  DELETE ccAgendaListaNegra
  WHERE idagenda IN (
      SELECT idagenda
      FROM ccAgenda_TipolistaNegra
      WHERE idtipolista = @idtipolista
      )

  DELETE ccAgenda_TipolistaNegra
  WHERE idtipolista = @idtipolista

  DELETE cccalifblacklist
  WHERE idtipolista = @idtipolista

  DELETE Camplistanegra
  WHERE idtipolista = @idtipolista

  DECLARE @telefono VARCHAR(10)

  WHILE EXISTS (
      SELECT telefono
      FROM ccListaNegra
      WHERE idtipolista = @idtipolista
      )
  BEGIN
    SELECT TOP 1 @hashPhone = Hashtel, @telefono = telefono
    FROM ccListaNegra
    WHERE idtipolista = @idtipolista

    INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
    VALUES (@telefono, 5, @idtipolista)

    DELETE
    FROM cclistanegra
    WHERE Hashtel = @hashPhone AND idtipolista = @idtipolista
  END

  RETURN (0)
END'
  EXEC(@sql)
		

 set @process = 'CW-5472_No_se_habilita_la_sección_de_encuestas'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIA_ABCCamps'')
    begin
        DROP PROCEDURE ccsp_RIA_ABCCamps;
    end'
  EXEC(@sql)

 set @process = 'CW-5472_No_se_habilita_la_sección_de_encuestas'
	set @sql = '
CREATE PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
@option smallint,
@UserId int = null,
@Descripcion varchar(40) = null,
@Cam_id varchar(1000),
@Activa tinyint = null,
@IDArea smallint = null,
@frame tinyint = null, 
@MirrorInbound_Id smallint = null,
@Prefijo varchar(40) = null
as
set nocount on

if @option = 0
	begin
		select cam_id,ISNULL(cam_descripcion,'''''''') as cam_descripcion,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'''') as AreaName
		from ccCamps as CAMP with(nolock) 
		left join ccRIACat_Areas as AREas with(nolock) on CAMP.IDArea = AREas.IDArea
		return(0)
	end

if @option = 1 -- select Camp
	begin
		select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0) as Area_Id,
		prefijo as Prefijo
		from ccCamps a1 with(nolock) 
		inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
		return(0)
	end

if @option = 4 --Delete
	begin
		if exists (select inbound_id from ccInbound with(nolock) where cam_id = @Cam_id)
		begin
		declare @error varchar(70)
		Select @error=case valor when 0 then ''No es posible eliminar la campaña, esta asociada a una especialidad''
			else ''Campaign can not be deleted, it has an association with an ACD'' end
		from ccsettings with(nolock) where setting_id = 27
		raiserror (@error,18,1)		
		return(0)
		end

		delete ccCampsHorarios with(rowlock) where cam_id = @Cam_id
		insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id) Values(@Cam_id, 5, 0, 0, @UserId)
		Delete ccCalifCamp with(rowlock) where cam_id = @Cam_id and tipo = 1
		Delete ccRIACampsGraph with(rowlock) where cam_id = @Cam_id
		delete ccHistorialListaNegra with(rowlock) where cam_id = @Cam_id
		delete ccRIARegistryLists with(rowlock) where cam_id = @Cam_id	
		return(0)
	end

if @option = 2 --Insert
	begin
	declare @new_cam_id smallint

	if exists(select cam_descripcion from ccCamps with(nolock) where cam_descripcion = @Descripcion)
		begin
		select -1 --, ''Nombre en Uso''
		return(0)  
		end

	-- ODC: la campaña siempre esta activa
	set @Activa = 1
	declare @pref int
	select  @pref = valor from ccSettings where setting_id = 201
	if (@pref = 0)
		set @Prefijo = ''''


	Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd,prefijo)
	select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
	case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end,@Prefijo

	if @@rowcount = 1
	select @new_cam_id = scope_identity()

	else
		begin
		select -2 --, ''Error al crear campaña''
		return(0)
		end

	if isnull(@MirrorInbound_Id, 0)<>0
		begin
		if not exists(select inbound_id from ccInbound with(nolock) where inbound_id=@MirrorInbound_Id)
			begin
			select -3 -- Error al asignar campaña a ACD, el ACD no existe o no pertenece a la misma area
			return(0)
			end

		update ccinbound with(rowlock) set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
		update cccamps with(rowlock) set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
		end

	insert into ccoDialerCamp (dialer_id, cam_id) 
	select dialer_id, @new_cam_id from ccoDialers with(nolock) where status = 1

	insert into ccCalifCamp (calif_id, cam_id, tipo) 
	select calif_id, @new_cam_id, 1 from ccTipoCalifOUT with(nolock) where CalifOut_Status = 1

	update ccCamps set keepDial=dbo.fn_keepDial_Camps(@new_cam_id) where cam_id=@new_cam_id

	If not exists (select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
		begin
		insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
		end

	insert into ccRIACampsGraph (cam_id, graphic_id)
	select @new_cam_id, graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock)  where frame = @frame and type_id = 1

	--inserta la lista negra por default
	if (select valor from ccsettings with(nolock) where setting_id=152)=''1''
	begin
		declare @tempId as int
		DECLARE @dnclId TABLE 
		(
			id int 
		);
		insert into @dnclId
		exec dbo.ccsp_RIACATBList null, null, 5
		select @tempId=id from @dnclId;
		exec ccsp_RIABlackListCamp 4, @IDArea, @new_cam_id, @tempId, null
	end

	select @new_cam_id
	return(0)
	end

if @option = 3 -- Update
	begin
		if not exists(select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
		insert into ccRIAGraphics (frame,type_id) values (@frame,1)

		Update ccCamps with(rowlock) set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id

		update ccRIACampsGraph with(rowlock)
		set graphic_id = (select graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
		where cam_id = @Cam_id

		return(0)
	end

	if @option = 5 --Obtener relaciones de campañas - campañas
	begin
		if not exists (select cam_id from ccCamps with(nolock) where cam_id = @Cam_id) or
		(@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
		not exists (select cam_id from ccCamps with(nolock) where cam_id=@descripcion))
		begin
		select -3 -- Campaña invalida
		return(0)
		end
				
	if @descripcion=0
		set @descripcion = null

	update ccCamps with(rowlock) set surveyCamId = @descripcion where cam_id = @Cam_id
	if @@rowcount=0
		select -4 -- Error al actualizar
					
	else
		begin
		delete cccalifcamp with(rowlock) where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

		end

	return(0)
	end

if @option = 6
	begin
		select cam_id, isnull(surveycamid,0)
		from cccamps with(index(PK_ccCamps),nolock)
		where cam_id = @Cam_id
		return(0)
	end

if @option = 7 -- Checa si la campaña no tiene grabaciones y se puede modificar el prefijo
	begin	
		select count(*) as Grabaciones from ccoCallsOut where cam_id = @Cam_id
		--select 0 as Grabaciones	
	end

if @option = 8 -- Checa si la campaña tiene asignada una campaña tipo encuesta
	begin	
		SELECT CAST(CASE WHEN  isnull(surveycamid,0) != 0 THEN 1 ELSE 0 END AS bit)
		from cccamps with(index(PK_ccCamps),nolock)
		where cam_id = @Cam_id
		return(0)
	end

return(0)
set nocount off'
    EXEC(@sql)
  
	set @process = 'CW-5464 DROP PROCEDURE ccsp_GalateaAdminDispositions'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminDispositions'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminDispositions;
    end'
	EXEC(@sql)

  set @process = 'CW-5464 Create SP ccsp_GalateaAdminDispositions'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
@command int,
@calif_id smallint = null,
@califIdLst varchar(8000) = null,
@description varchar(60)=null,
@order tinyint=null,
@canReprogram bit = null,
@graphColor varchar(15) = null,
@endConversation bit=null,
@keepDial bit=null,
@autoCB bit=null,
@contactOwner bit=null,
@finishPreview bit = 0
AS
set nocount on
declare @inserted table (ID smallint)

if @command=1 -- Load Inbound Dispositions
begin
  Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner, 
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd, graphColor
  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
  where C.Calif_Status=1
  group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation, graphColor
  order by 2
  return(0)
end

If @command=2 -- Load Outbound Dispositions
begin
  Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,  
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner, 
  IsNull(C.finishPreview,0) as finishPreview, graphColor
  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
  where C.CalifOut_Status=1
  group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
  C.contactOwner, C.finishPreview, graphColor
  order by 2
  return(0)
end

If @command=3 -- New ccTipoCalif
begin
  If exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@description)
    begin
      select cast(-1 as smallint) [result]	-- Disposition already exists
      return(0)
    end

  If exists(select calif_id from ccTipoCalif where Calif_Status=0 and description=@description)
  begin
	select top 1 @calif_id = calif_id from ccTipoCalif where Calif_Status=0 and description=@description order by calif_id desc
    update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0), 
	graphColor=isnull(@graphColor, ''1DB4E2''), Calif_Status=1
	output inserted.calif_id into @inserted
    where calif_id=@calif_id
	select ID [result] from @inserted 
    return(0)
  end

  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , graphColor)
  output inserted.calif_id into @inserted
  select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalif
  select ID [result] from @inserted
  return(0)
end

If @command=4 -- New ccTipoCalifOUT
begin
  If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
  begin
  select cast(-1 as smallint) [result]	-- Disposition already exists
  return(0)
  end

 If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
 begin
	select top 1 @calif_id = calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description order by calif_id desc
	update ccTipoCalifOut set autoTime=0, orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), idTipoLista=0,
	Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), 
	finishPreview=isnull(@finishPreview,0), graphColor=isnull(@graphColor, ''1DB4E2'')
	output inserted.calif_id into @inserted
	where calif_id=@calif_id
	select ID [result] from @inserted 
	return(0)
 end

 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, graphColor)
 output inserted.calif_id into @inserted
 select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, isnull(@canReprogram,0), isnull(@keepDial,0), 
 isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalifOut
 select ID [result] from @inserted 
 return(0)
end
If @command=5 -- Delete Inbound Dispositions
begin
    delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    return(0)
end
if @command=6 -- Delete Outbound Disposition
begin
	delete from ccCalifCamp where tipo=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	delete from cctipoSubCalifRel where tipoSubRel=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	update ccTipoCalifOUT set CalifOut_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	return(0)
end
if @command=7 -- Update Inbound Disposition
begin
	if(exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@Description and calif_id<>@calif_id))
	begin
		select cast(-1 as smallint) [result]	-- Disposition already exists
		return(0)
	end

	if @canReprogram=1
	begin
		if exists(select i.Inbound_id from ccCalifCamp cc inner join ccTipoCalif t on cc.calif_id=t.calif_id and tipo=0
		inner join ccInbound i on cc.cam_id=i.Inbound_id where cc.calif_id=@calif_id and i.cam_id is null)
		begin
			select cast(-2 as smallint) [result]	-- Cant reprogram, there is not assigned campaign
			return(0)
		end
	end

    UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
    canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  
	EndConversation=isnull(@endConversation,EndConversation)
	output inserted.calif_id into @inserted
    where calif_id=@calif_id

    delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

	select ID [result] from @inserted
    return(0)
end
if @command=8 -- Update Outbound Disposition
begin
	if(exists(select calif_id from ccTipoCalifOUT where CalifOut_Status=1 and Description=@description and calif_id<>@calif_id))
	begin
		select cast(-1 as smallint) [result]	-- Disposition already exists
		return(0)
	end

	UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
	canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  keepDial=isnull(@keepDial,keepDial), 
	autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner), 
	finishPreview = isnull(@finishPreview,finishPreview)
	output inserted.calif_id into @inserted
	where calif_id=@calif_id

	if @keepDial is not null
	begin
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	end

	select ID [result] from @inserted
	return(0) 
end

set nocount off'
	EXEC(@sql)
  
    set @process = 'CW-5464 DROP PROCEDURE ccsp_GalateaAdminSubdispositionRelations'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSubdispositionRelations'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminSubdispositionRelations;
    end'
	EXEC(@sql)

	set @process = 'CW-5464 Create SP ccsp_GalateaAdminSubdispositionRelations'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSubdispositionRelations]
@command int,
@type tinyint = null, --0=Outbound, 1=Inbound
@califSub_id varchar(max) = null,
@calif_id smallint = null
AS
set nocount on

If @command = 1
begin
	select cast(0 as int) [type],
		r.calif_id,
		r.califSub_id
	from cctipoSubCalifRel r inner join ccTipoCalifSub t on r.califSub_id = t.califSub_id and r.tipoSubRel = 1
	where t.califSub_Status = 1
	UNION
	select cast(1 as int) [type],
		r.calif_id,
		r.califSub_id
	from cctipoSubCalifRel r inner join ccTipoCalifSubOUT t on r.califSub_id = t.califSub_id and r.tipoSubRel = 0
	where t.califSubOut_Status = 1
	order by [type], calif_id, califSub_id
end
if @command=2  --Asignar subcalificacion a una calificacion
begin
	if @type=1 and (select cast(sum(isnull(cast(canReprogram as tinyint),0)) as bit) FROM cctipocalifSub where califSub_id in
	(select value from dbo.fn_RIASplitDelimited (@califSub_id, '','')))>0 
	and exists (select IB.Inbound_id from cctipocalif CO join ccCalifCamp CF on  CF.calif_id = CO.calif_id and CF.tipo = 0 
	join ccInbound IB on IB.Inbound_id = CF.cam_id where IB.cam_id is null and CO.calif_id = @calif_id)
	begin
		select cast(-2 as smallint) [result]	-- Cant reprogram, there is not assigned campaign
		return(0)
	end

	insert cctipoSubCalifRel (calif_id, califSub_id, tipoSubRel)
	select @calif_id [calif_id], S.value [califSub_id], @type [Tipo]
	from dbo.fn_RIASplitDelimited (@califSub_id, '','') S
	where cast(@calif_id as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@type as varchar(10)) not in
   (select cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) from cctipoSubCalifRel)
	and S.value is not null

	if @type=0
	begin
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	end
	
	select cast(1 as smallint) [result]	 -- Done! 
	return(0)
end
if @command=3	--Desasignacion de subcalificacion
begin
	delete cctipoSubCalifRel
    where cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) in
    (select cast(@calif_id as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@type as varchar(10))
    from dbo.fn_RIASplitDelimited (@califSub_id, '','') S)

    if @type=0
	begin
      update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	end
end

set nocount off'
	EXEC(@sql)
  
    set @process = 'CW-5464 DROP PROCEDURE ccsp_GalateaAdminSubdispositions'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSubdispositions'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminSubdispositions;
    end'
	EXEC(@sql)

	set @process = 'CW-5464 Create SP ccsp_GalateaAdminSubdispositions'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSubdispositions]
@command int,
@califSub_id smallint = null,
@califSubIdLst varchar(max) = null,
@califSubDesc varchar(60) = null,
@order varchar(3) = null,
@canReprogram bit = null,
@endConversation bit=null,
@keepDial bit=null,
@autoCB bit=null,
@contactOwner bit=null
AS
set nocount on
declare @inserted table (ID smallint)

if @command=1 -- Load Inbound Subdispositions
begin
  select califSub_id, IsNull(califSubDesc,'''') [califSubDesc], orden, canReprogram, 
  IsNull(EndConversation,0) EndConversation
  from ccTipoCalifSub
  where califSub_Status = 1
  order by 2
  return(0)
end

If @command=2 -- Load Outbound Subdispositions
begin
  select califSub_id, IsNull(califSubDesc,'''') [califSubDesc],
  IsNull(canReprogram, 0) [canReprogram],
  IsNull(orden, 0) [orden],
  IsNull(keepDial, 0) [keepDial],
  IsNull(autoCallback, 0) [autoCallback],
  IsNull(contactOwner, 0) [contactOwner]
  from ccTipoCalifSubOut
  where califSubOut_Status = 1
  order by 2
  return(0)
end

if @command=3	-- New Inbound Subdisposition
begin
	if(exists(select califSub_id from ccTipoCalifSub where califSub_Status = 1 and califSubDesc=@califSubDesc))
	begin
		select cast(-1 as smallint) [result]	-- Subdisposition already exists
		return(0)
	end

	if(exists(select califSub_id from ccTipoCalifSub where califSub_Status=0 and califSubDesc=@califSubDesc))
	begin
		select top 1 @califSub_id = califSub_id from ccTipoCalifSub where califSub_Status=0 and califSubDesc=@califSubDesc order by califSub_id desc
		update ccTipoCalifSub set orden=isnull(@order,0), canReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0),
		califSub_Status=1
		output inserted.califSub_id into @inserted
		where califSub_id=@califSub_id
		select ID [result] from @inserted 
		return(0)
	end

	insert into ccTipoCalifSub (califSubDesc, orden, canReprogram, califSub_Status, EndConversation)
	select @califSubDesc, isnull(@order,0), isnull(@canReprogram,0), 1, isnull(@endConversation,0)
	select cast(SCOPE_IDENTITY() as smallint) [result]
	return(0)
end

if @command=4	-- New Outbound Subdisposition
begin
	if(exists(select califSub_id from ccTipoCalifSubOUT where califSubOut_Status = 1 and califSubDesc=@califSubDesc))
	begin
		select cast(-1 as smallint) [result]	-- Subdisposition already exists
		return(0)
	end

	if(exists(select califSub_id from ccTipoCalifSubOUT where califSubOut_Status=0 and califSubDesc=@califSubDesc))
	begin
		select top 1 @califSub_id = califSub_id from ccTipoCalifSubOUT where califSubOut_Status=0 and califSubDesc=@califSubDesc order by califSub_id desc
		update ccTipoCalifSubOUT set orden=isnull(@order,0), canReprogram=isnull(@canReprogram,0),idTipoLista=0,
		califSubOut_Status=1, keepDial=isnull(@keepDial,0), autoCallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0)
		output inserted.califSub_id into @inserted
		where califSubDesc=@califSubDesc
		select ID [result] from @inserted 
		return(0)
	end

	insert into ccTipoCalifSubOUT (califSubDesc, orden, canReprogram, califSubOut_Status, keepDial, autoCallback, contactOwner)
	select @califSubDesc, isnull(@order,0), isnull(@canReprogram,0), 1, isnull(@keepDial,0), isnull(@autoCB,0), isnull(@contactOwner,0)
	select cast(SCOPE_IDENTITY() as smallint) [result]
	return(0)
end

if @command=5	-- Delete Inbound Subdisposition
begin
	delete cctipoSubCalifRel where tipoSubRel=1 and califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, '',''))
	update cctipocalifSub set califSub_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, '',''))
	return(0)
end

if @command=6	-- Delete Outbound Subdisposition
begin
	delete cctipoSubCalifRel where tipoSubRel=0 and califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, '',''))
	update cctipocalifSubOUT set califSubOut_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSubIdLst, '',''))
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	return(0)
end

if @command=7	-- Update Inbound Subdisposition
begin
	if(exists(select califSub_id from ccTipoCalifSub where califSub_Status=1 and califSubDesc=@califSubDesc and califSub_id<>@califSub_id))
	begin
		select cast(-1 as smallint) [result]	-- Subdisposition already exists
		return(0)
	end

	if @canReprogram=1
	begin
		if exists (select IB.Inbound_id from cctipoSubCalifRel CR join cctipoCalif TC on CR.calif_id = TC.calif_id and CR.tipoSubRel=1
		join ccCalifCamp CM on TC.calif_id = CM.calif_id and CM.tipo = 0 join ccInbound IB on CM.cam_id = IB.inbound_id 
		where califSub_id = @califSub_id and IB.cam_id is null)
		begin
			select cast(-2 as smallint) [result]	-- Cant reprogram, there is not assigned campaign
			return(0)
		end
	end

	update ccTipoCalifSub set califSubDesc=isnull(@califSubDesc, califSubDesc), orden=isnull(@order, orden), canReprogram=isnull(@canReprogram, canReprogram),
	EndConversation=isnull(@endConversation, EndConversation)
	output inserted.califSub_id into @inserted
	where califSub_id=@califSub_id

	delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

	select ID [result] from @inserted
	return(0) 
end

if @command=8	-- Update Outbound Subdisposition
begin
	
	if(exists(select califSub_id from ccTipoCalifSubOUT where califSubOut_Status=1 and califSubDesc=@califSubDesc and califSub_id<>@califSub_id))
	begin
		select cast(-1 as smallint) [result]	-- Subdisposition already exists
		return(0)
	end

	update ccTipoCalifSubOUT set califSubDesc=isnull(@califSubDesc, califSubDesc), canReprogram=isnull(@canReprogram, canReprogram),
	orden=isnull(@order, orden), keepDial=isnull(@keepDial, keepDial), autoCallback=isnull(@autoCB, autoCallback), contactOwner=isnull(@contactOwner,contactOwner)
	output inserted.califSub_id into @inserted
	where califSub_id=@califSub_id
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)

	select ID [result] from @inserted
	return(0) 
end


set nocount off'
	EXEC(@sql)
	
	set @process = 'CW-5454 Insert new Agent Status'	
	set @sql = 'if not exists (select * from ccTipoStatusAgente where TipoStatusAge_id =32)
begin
	insert into ccTipoStatusAgente values (32,''Preview'')
end'
    EXEC(@sql)
	
			set @process = 'CW-5454 Check if exists configuraIdiomaCatalogosEnglish'	
	set @sql = 'if exists (select * from sys.procedures where name = N''configuraIdiomaCatalogosEnglish'')
            begin
          DROP PROCEDURE configuraIdiomaCatalogosEnglish;
            end'
    EXEC(@sql)


	set @process = 'CW-5454 Se crea sp configuraIdiomaCatalogosEnglish'
	set @sql = 'Create PROCEDURE [dbo].[configuraIdiomaCatalogosEnglish]
	AS
Print ''Iniciando proceso de configuracion en Ingles''

Print ''Estableciendo Horarios''
Delete [ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Week'', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Night shift'', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Saturday'', 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Sunday'', 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [ccTipoNotReady]
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Not Clasified'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Break'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Bathroom'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''With client'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Supervisor'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Clarification'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Meeting'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Lunch'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Systems'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Other'')


DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
delete from [ccStatusLLamada]

INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, ''Initial'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Out of Schedule'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Out of Service'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''No Agents Logged in'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''On Hold'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandoned'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Time overflow'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Queue size overflow'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''With Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, ''Assigned Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, ''Assigned'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, ''Attended Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, ''Answered'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, ''Canceled Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, ''Assigned and Not Answered'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, ''Assigned and took line'')
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [ccTipoDias]
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, ''Monday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, ''Tuesday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, ''Wednesday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, ''Thursday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, ''Friday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, ''Saturday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, ''Sunday'')

Print ''Estableciendo resultados de marcacion''
delete from [ccTipoResultadoDial]

INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Answer'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Busy'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Not Answer'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax/Modem'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Other'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, ''NoService'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, ''VoiceMail/Machine'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, ''Circuit busy'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, ''Cancelled'')

Print ''Estableciendo los tipos de estado de los agentes''
DELETE [ccTipoStatusAgente]

INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, ''LogOut'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, ''Unknown'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, ''Not Ready'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, ''Ready'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, ''Talking'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, ''Transfer'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, ''Wrapup'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, ''Other'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, ''Client'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, ''Ringing'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, ''Problem'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, ''Wait for manual call'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N''ChatReq'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N''Chatting'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, ''Xfer Fail'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, ''Ringing Fail'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (30, ''ReconnectKolob'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, ''Ready PreviewPro'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (32, ''Preview'')



Print ''Estableciendo los tipos de usuario''
Delete [ccTipoUsers]
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, ''Agent'')
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, ''Supervisor'')
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, ''AVRS Access'')

Print ''Estableciendo los dias''
Delete [ccDias]
DBCC CHECKIDENT (''[ccDias]'', RESEED, 0)
SET IDENTITY_INSERT [ccDias] ON
INSERT [ccDias] ([dia_id], [Name]) VALUES (1, ''Sunday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (2, ''Monday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (3, ''Tuesday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (4, ''Wednesday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (5, ''Thursday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (6, ''Friday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (7, ''Saturday'')
SET IDENTITY_INSERT [ccDias] OFF

Print ''Estableciendo los tipos de llamada''
delete from cstoTarifa
delete cstoTipoLlamada

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''National LD'',''12'',''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Mobile'',''13'',''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''LD Mobile'',''13'',''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''USA LD'',''13'',''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''Inter LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''2-digit Local Area Code'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''3-digit Local Area Code'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''4-digit Local Area Code'',''6'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''2-digit Local Mobile Area Code'',''10'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''3-digit Local Mobile Area Code'',''9'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''4-digit Local Mobile Area Code'',''8'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Long Distance'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Long Distance Mobile'',''13'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Mobile'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''National LD'',''11'',''1%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''National LD'',''10'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Mobile'',''11'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Mobile'',''11'',''07%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''Inter LD'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''Old LD'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Mobile'',''10'',''05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''New LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''Inter LD'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''Inter LD'',''0'',''0011%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Mobile'',''10'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Mobile '',''8'',''6%|7%|8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''9-digit Mobile'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''National LD'',''10'',''02%|03%|04%|05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''National Mobile LD'',''10'',''06%|07%|08%|09%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''9-digit National Mobile LD'',''11'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''International LD'',''19'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Mobile'',''8'',''3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''National LD'',''8'',''7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''International LD'',''8'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''SIP Telephony'',''8'',''4%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Mobile Telephony'',''8'',''5%|6%|7%|8%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Reverse Charge'',''10'',''800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Premium Rate'',''10'',''90%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Internet Access'',''10'',''900%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Special'',''0'',''08%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Landline'',''8'',''2%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Mobile'',''8'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Mobile'',''9'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Webservices'',''9'',''5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''National LD'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Mobile'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''Inter LD'',''0'',''00%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [ccTipoMovsListaNegra]
SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Added to black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Blocked on loading'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Removed from campaign'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Replaced from black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Deleted from black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Added by Disposition'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, ''Load black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, ''Load customer black list'')
SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [ccTipoCalif]
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, ''Wrong area'', 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, ''Disconnected call'', 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, ''Wrong number'', 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [ccTipoCalifOUT]
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, ''Effective call'', 0, 0, 1)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, ''Leave a message'', 0, 1, 2)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, ''Wrong number'', 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [cstoProvedor] ([descrip]) VALUES (''Carrier 1'')

Print ''Tipo Msg ChatLog'' -- No se hace delete ni truncate ya que se perderia la integridad si ya hay registros, los id ya deberian estar creados por lo cual se genera el update
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes an individual message to agent'' where TipoMsgChat=1
Update ccRIAChat_TipoMsg set MsgDetalle=''Agent writes a message to Administrator'' where TipoMsgChat=2
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes a global message'' where TipoMsgChat=3

Print ''Mensajes defualt''
DELETE [ccMsgFiles]
DBCC CHECKIDENT (''[ccMsgFiles]'', RESEED, 0)
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default5'', ''Welcome message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default4'', ''Transfer message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default3'', ''Out of service message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default2'', ''After hours message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default1'', ''In queue message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default7'', ''No agents signed in message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default9'', ''VoiceMail message'')
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default10'', ''Overflow message'')
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default11'', ''DNC list'')

Print ''Mensajes default chat''
DELETE [ccRIAChatInboundMsgs]
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default5'', ''Welcome!'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default3'', ''Service currently unavailable'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default2'', ''Our schedule service has finished'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default1'', ''Please hold while one of our agents is available'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default7'', ''There are not available agents'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default10'', ''Your request can not be processed'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default12'', ''Chat session has been inactive for too long'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default13'', ''Chat session has finished'')
	'
    EXEC(@sql)
	
				set @process = 'CW-5454 Check if exists configuraIdiomaCatalogosEspañol'	
	set @sql = 'if exists (select * from sys.procedures where name = N''configuraIdiomaCatalogosEspañol'')
            begin
          DROP PROCEDURE configuraIdiomaCatalogosEspañol;
            end'
    EXEC(@sql)


	set @process = 'CW-5454 Se crea sp configuraIdiomaCatalogosEspañol'
	set @sql = 'Create PROCEDURE [dbo].[configuraIdiomaCatalogosEspañol]
	AS

Print ''Iniciando proceso de configuracion en Español''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Semana'' collate SQL_Latin1_General_CP1_CI_AS), 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Nocturno'' collate SQL_Latin1_General_CP1_CI_AS), 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady]
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''No Clasificado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Break'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Tocador'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Con Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Aclaracion'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Junta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Comida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Sistemas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))

DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
delete from [dbo].[ccStatusLLamada]

INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, convert(text, N''Inicial'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, convert(text, N''Fuera de Horario'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, convert(text, N''Fuera de Servicio'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, convert(text, N''Sin Agentes Firmados'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, convert(text, N''En espera'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, convert(text, N''Colgada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, convert(text, N''Desborde por Tiempo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, convert(text, N''Desborde por Cantidad'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, convert(text, N''Con Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, convert(text, N''Asignada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, convert(text, N''Asignada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, convert(text, N''Atendida Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, convert(text, N''Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, convert(text, N''Cancelada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, convert(text, N''Asignada y No Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, convert(text, N''Asignada y Toma Linea'' collate SQL_Latin1_General_CP1_CI_AS))
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
truncate table [dbo].[ccTipoDias]
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo resultados de marcacion''
delete from [dbo].[ccTipoResultadoDial]

INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, convert(text, N''Contestan'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, convert(text, N''Ocupado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, convert(text, N''No Contesta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, convert(text, N''Fax/Modem'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, convert(text, N''NoDialTone'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, convert(text, N''NoService'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, convert(text, N''Buzon/Maquina'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, convert(text, N''Congestion'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de estado de los agentes''
Delete [dbo].[ccTipoStatusAgente]

INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, convert(text, N''LogOut'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, convert(text, N''Desconocido'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, convert(text, N''No Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, convert(text, N''Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, convert(text, N''Dialogo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, convert(text, N''Transferencia'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, convert(text, N''Notas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, convert(text, N''Otra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, convert(text, N''Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, convert(text, N''Ringing'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, convert(text, N''Problema'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, convert(text, N''Espera llamada manual'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N''ChatReq'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N''Chatting'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, convert(text, N''Transferencia Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, convert(text, N''Ringing Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (30, convert(text, N''ReconnectKolob'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, convert(text, N''Ready PreviewPro'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, convert(text, N''Preview'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, convert(text, N''Agente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, convert(text, N''AVRS Calidad'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
DBCC CHECKIDENT (''[ccDias]'', RESEED, 0)
SET IDENTITY_INSERT [ccDias] ON
INSERT [ccDias] ([dia_id], [Name]) VALUES (1, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (2, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (3, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (4, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (5, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (6, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (7, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccDias] OFF

Print ''Estableciendo los tipos de llamada''
delete from [dbo].cstoTarifa
delete cstoTipoLlamada

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''LD nacional'',''12'',''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Cel'',''13'',''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''Cel LD'',''13'',''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''LD USA'',''13'',''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''LD inter'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''LADA local 2 dígitos'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''Local lada 3 digitos'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''Local lada 4 digitos'',''6'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''Cel LADA local 2 dígitos'',''10'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''Cel LADA local 3 dígitos'',''9'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''Cel LADA local 4 dígitos'',''8'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Larga distancia'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Cel larga distancia'',''13'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Celular'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''LD Nacional'',''11'',''1%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''LD Nacional'',''10'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Celular'',''11'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Cel'',''11'',''07%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''LD inter'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''LD anterior'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Cel'',''10'',''05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''LD actual'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''LD inter'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''LD inter'',''0'',''0011%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Cel'',''10'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Movil '',''8'',''6%|7%|8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''Celular 9 dígitos '',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''LD Nacional'',''10'',''02%|03%|04%|05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''Cel LD nacional'',''10'',''06%|07%|08%|09%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''Cel LD nacional 9 dígitos'',''11'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''LD internacional'',''19'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Movil'',''8'',''3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''LD Nacional'',''8'',''7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''LD internacional'',''8'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''Telefonía SIP'',''8'',''4%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Telefonía móvil'',''8'',''5%|6%|7%|8%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Cobro Revertido'',''10'',''800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Tarifa Prima'',''10'',''90%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Acceso Internet'',''10'',''900%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Especial'',''0'',''08%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Fijo'',''8'',''2%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Movil'',''8'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Celular'',''9'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Servicios web'',''9'',''5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''LD nacional'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Cel'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''LD inter'',''0'',''00%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, convert(text, N''Carga Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, convert(text, N''Lista Negra en Carga de Registros'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, convert(text, N''Eliminado por Aplicar Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, convert(text, N''Eliminado de Lista Negra por Remplazo '' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, convert(text, N''Borrado de Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, convert(text, N''Solicita información general'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, convert(text, N''Se cortó la llamada'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, convert(text, N''Número equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, convert(text, N''Gestión Efectiva'' collate SQL_Latin1_General_CP1_CI_AS), 0, 0, 1)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, convert(text, N''Se deja recado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 2)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, convert(text, N''Numero Equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [dbo].[cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telmex'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Maxcom'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Avantel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''AT&T'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telnor'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Axtel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telular'')

Print ''Mensajes voz defualt''
DELETE [dbo].[ccMsgFiles]
DBCC CHECKIDENT (''[ccMsgFiles]'', RESEED, 0)
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default5'', ''Mensaje Bienvenida'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default4'', ''Mensaje Transferencia'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default3'', ''Mensaje Fuera de servicio'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default2'', ''Mensaje Fuera de horario'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default1'', ''Mensaje En espera'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default7'', ''Mensaje Sin agentes firmados'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default9'', ''Mensaje VoiceMail'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default10'', ''Mensaje Desborde'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default11'', ''Lista Negra'')


Print ''Mensajes default chat''
DELETE [dbo].[ccRIAChatInboundMsgs]
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default5'', ''!Bienvenido!'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default3'', ''El servicio no se encuentra disponible'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default2'', ''Nuestro horario de atención ha terminado'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default1'', ''Por favor espere mientras uno de nuestros agentes se encuentra disponible'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default7'', ''No hay agentes disponibles'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default10'', ''No podemos tomar su solicitud'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default12'', ''La sesión de chat ha estado inactiva mucho tiempo'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default13'', ''La sesión de chat ha concluido'')
'
    EXEC(@sql)	
  

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
