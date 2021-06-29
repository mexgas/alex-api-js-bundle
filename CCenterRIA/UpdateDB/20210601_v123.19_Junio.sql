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

  set @process = 'CW-5437 Drop Report RepAgentGI'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepAgentGI'')
		begin
			DROP PROCEDURE ccspRepAgentGI;
		end'
		EXEC(@sql)

		set @process = 'CW-5437 Create Report RepAgentGI'
		set @sql = 'CREATE PROCEDURE [dbo].[ccspRepAgentGI]
@action AS TINYINT,
@from AS DATETIME,
@to AS DATETIME
AS

SET ANSI_WARNINGS OFF;
SET NOCOUNT ON;
IF @from IS NULL
    SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));
IF @to IS NULL
    SELECT @to = GETDATE();
IF @action = 1
    BEGIN
        IF OBJECT_ID(''tempdb..#inboundData'') IS NOT NULL
            DROP TABLE #inboundData;
        IF OBJECT_ID(''tempdb..#inboundData2'') IS NOT NULL
            DROP TABLE #inboundData2;
        IF OBJECT_ID(''tempdb..#outboundData'') IS NOT NULL
            DROP TABLE #outboundData;
        IF OBJECT_ID(''tempdb..#outboundData2'') IS NOT NULL
            DROP TABLE #outboundData2;
        IF OBJECT_ID(''tempdb..#timeDetailAgent'') IS NOT NULL
            DROP TABLE #timeDetailAgent;
        IF OBJECT_ID(''tempdb..#timeDetailAgent2'') IS NOT NULL
            DROP TABLE #timeDetailAgent2;
        IF OBJECT_ID(''tempdb..#agentInformation'') IS NOT NULL
            DROP TABLE #agentInformation;
        IF OBJECT_ID(''tempdb..#tempRepAgentGI'') IS NOT NULL
            DROP TABLE #tempRepAgentGI;
        IF OBJECT_ID(''tempdb..#tempAgentLastStatus'') IS NOT NULL
            DROP TABLE #tempAgentLastStatus;
        IF OBJECT_ID(''tempdb..#tempccLogAgentesDia'') IS NOT NULL
            DROP TABLE #tempccLogAgentesDia;
        IF OBJECT_ID(''tempdb..#tempccLogAgentesDia2'') IS NOT NULL
            DROP TABLE #tempccLogAgentesDia2;
        IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL
            DROP TABLE #sessionTimeGroup;

        DECLARE @interval INT;
        DECLARE @dateNow DATETIME, @maxLogout DATETIME;
        DECLARE @HourExtend AS SMALLINT, @fromExtended AS SMALLDATETIME;

        SELECT @HourExtend = 2, 
               @fromExtended = DATEADD(hh, -@HourExtend, @from);
        DECLARE @tresRing AS SMALLINT, @tresDialog AS SMALLINT, @tresDelayIn AS SMALLINT;

        EXEC @tresRing = ccspConfigTresRing;
        EXEC @tresDialog = ccspConfigTresDialog;
        EXEC @tresDelayIn = ccspConfigtresDelayIn;

        SET @dateNow = GETDATE();
        SET @interval = 15;

        CREATE TABLE #inboundData
        ([row]           INT IDENTITY PRIMARY KEY, 
         Inbound_id      INT, 
         [User_id]       INT, 
         phone_in        VARCHAR(30), 
         cal_id          INT, 
         dni_id          INT, 
         dateStartDetail DATETIME, 
         dateEndDetail   DATETIME, 
         timegroup       DATETIME, 
         timegroup_next  DATETIME, 
         time_endque     DATETIME, 
         time_ring       DATETIME, 
         time_dialog     DATETIME, 
         time_notes      DATETIME, 
         time_end_call   DATETIME, 
         ntotal          INT, 
         ninitial        INT, 
         nout_hour       INT, 
         nout_service    INT, 
         nabnd           INT, 
         nno_agent       INT, 
         nque            INT, 
         ntimeout        INT, 
         noverflow       INT, 
         nxfer           INT, 
         nxfer_que       INT, 
         nabnd_xfer      INT, 
         nabnd_ring      INT, 
         nno_answer      INT, 
         nabnd_dialog    INT, 
         nanswer         INT, 
         nlost           INT, 
         nmsg            INT, 
         nabnd_tres      INT, 
         nansw_tres      INT, 
         tque_max        INT, 
         tque            INT, 
         txfer           INT, 
         tdialog         INT, 
         tnotes          INT, 
         tring           INT, 
         tresp           INT, 
         nMoh            INT, 
         nWHag           INT, 
         nWHcl           INT
        );

        CREATE NONCLUSTERED INDEX iX_InboundUserId ON #inboundData([Inbound_id] DESC, [User_id] DESC);

        CREATE TABLE #outboundData
        (row             INT IDENTITY, 
         cam_id          INT, 
         [User_id]       INT, 
         cal_id          INT, 
         cal_puerto      INT, 
         phone_out       VARCHAR(30), 
         dateStartDetail DATETIME, 
         dateEndDetail   DATETIME, 
         timegroup       DATETIME, 
         timegroup_next  DATETIME, 
         ntotal          INT, 
         nno_agent       INT, 
         nxfer           INT, 
         nabnd_xfer      INT, 
         nabnd_ring      INT, 
         nno_answer      INT, 
         nabnd_dialog    INT, 
         nanswer         INT, 
         nlost           INT, 
         tque            INT, 
         txfer           INT, 
         tring           INT, 
         tdialog         INT, 
         tnotes          INT, 
         tresp           INT, 
         nhangup         INT, 
         nMoh            INT, 
         nWHag           INT, 
         nWHcl           INT, 
         time_endque     DATETIME, 
         time_ring       DATETIME, 
         time_dialog     DATETIME, 
         time_notes      DATETIME, 
         time_end_call   DATETIME
        );

        CREATE NONCLUSTERED INDEX iX_CamUserId ON #outboundData([cam_id] DESC, [User_id] DESC);

        CREATE TABLE #timeDetailAgent
        ([User_id]       INT NULL, 
         dateStartDetail DATETIME NULL, 
         dateEndDetail   DATETIME NULL, 
         timegroup       DATETIME NULL, 
         timegroup_next  DATETIME NULL, 
         tunknown        INT NULL, 
         tnot_av         INT NULL, 
         tav             INT NULL, 
         tprob           INT NULL, 
         tother          INT NULL, 
         nother          INT NULL, 
         tmanualcall     INT NULL, 
         tunknown2       DECIMAL(10, 3), 
         tchatting       INT NULL
        );

        --Tiempo ultimo Status del agente
        CREATE TABLE #tempAgentLastStatus
        (id     INT, 
         fecha  DATETIME, 
         tiempo INT
        );

        CREATE TABLE #sessionTimeGroup
        ([user_id]        [SMALLINT] NOT NULL, 
         [login]          [DATETIME] NOT NULL, 
         [logout]         [DATETIME] NULL, 
         [extension]      [VARCHAR](7) NOT NULL, 
         [timegroup]      [DATETIME] NOT NULL, 
         [timegroup_next] [DATETIME] NOT NULL, 
         [tlog]           [INT] NULL
        );

        --TIempos del agente
        CREATE TABLE #tempccLogAgentesDia
        (row              INT NOT NULL, 
         user_id          INT NOT NULL, 
         TipoStatusAge_id TINYINT NOT NULL, 
         tStatus          INT NOT NULL, 
         dateIni          DATETIME NOT NULL, 
         dateEnd          DATETIME NOT NULL, 
         currentStatus    INT
        );

        SELECT @maxLogout = MAX(logout)
        FROM TmpSessionTimeGroup;

        IF CONVERT(VARCHAR(11), @maxLogout, 121) = CONVERT(VARCHAR(11), @dateNow, 121)
           AND @dateNow > @maxLogout
            SET @dateNow = @maxLogout;

        INSERT INTO #sessionTimeGroup
               SELECT user_id, 
                      login, 
                      logout, 
                      extension, 
                      timegroup, 
                      timegroup_next, 
                      tlog
               FROM TmpSessionTimeGroup;

        --inserto ultimo tiempo del agente del dia
        INSERT INTO #tempAgentLastStatus
               SELECT User_id, 
                      MAX(fecha) AS maxfecha, 
                      DATEDIFF(ss, MAX(fecha), @dateNow)
               FROM ccLogAgentesDia
               WHERE CONVERT(VARCHAR(11), fecha, 121) = CONVERT(VARCHAR(11), @dateNow, 121)
               GROUP BY User_id;

        INSERT INTO #inboundData
        (dateStartDetail, 
         dateEndDetail, 
         timegroup, 
         timegroup_next, 
         time_endque, 
         time_ring, 
         time_dialog, 
         time_notes, 
         time_end_call, 
         phone_in, 
         cal_id, 
         dni_id, 
         Inbound_id, 
         User_id, 
         ntotal, 
         ninitial, 
         nout_hour, 
         nout_service, 
         nabnd, 
         nno_agent, 
         nque, 
         ntimeout, 
         noverflow, 
         nxfer, 
         nxfer_que, 
         nabnd_xfer, 
         nabnd_ring, 
         nno_answer, 
         nabnd_dialog, 
         nanswer, 
         nlost, 
         nmsg, 
         nabnd_tres, 
         nansw_tres, 
         tque_max, 
         tque, 
         txfer, 
         tdialog, 
         tnotes, 
         tring, 
         tresp, 
         nMoh, 
         nWHag, 
         nWHcl
        )
               SELECT *
               FROM
               (
                   SELECT CASE
                              WHEN cal_Xfer IS NULL
                                   OR cal_Xfer = ''1900-01-01 00:00:00''
                              THEN cal_inicio
                              ELSE cal_Xfer
                          END AS dateStartDetail, 
                          DATEADD(ss, 0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,
                                                                                CASE
                                                                                    WHEN cal_Xfer IS NULL
                                                                                         OR cal_Xfer = ''1900-01-01 00:00:00''
                                                                                    THEN cal_inicio
                                                                                    ELSE cal_Xfer
                                                                                END) dateEndDetail, 
                          dbo.GetTimeGroup
                   (CASE
                        WHEN cal_Xfer IS NULL
                             OR cal_Xfer = ''1900-01-01 00:00:00''
                        THEN cal_inicio
                        ELSE cal_Xfer
                    END, 0
                   ) AS timegroup, 
                          dbo.GetTimeGroup
                   (DATEADD(ss, ISNULL((0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas), 0),
                                                                                                CASE
                                                                                                    WHEN cal_Xfer IS NULL
                                                                                                         OR cal_Xfer = ''1900-01-01 00:00:00''
                                                                                                    THEN cal_inicio
                                                                                                    ELSE cal_Xfer
                                                                                                END), 1
                   ) AS timegroup_next,
                          CASE
                              WHEN cal_Xfer IS NULL
                                   OR cal_Xfer = ''1900-01-01 00:00:00''
                              THEN cal_inicio
                              ELSE cal_Xfer
                          END AS time_endque, 
                          DATEADD(ss, ISNULL(cal_txfer, 0),
                                                         CASE
                                                             WHEN cal_Xfer IS NULL
                                                                  OR cal_Xfer = ''1900-01-01 00:00:00''
                                                             THEN cal_inicio
                                                             ELSE cal_Xfer
                                                         END) AS time_ring, 
                          DATEADD(ss, ISNULL(cal_txfer + cal_tring, 0),
                                                                     CASE
                                                                         WHEN cal_Xfer IS NULL
                                                                              OR cal_Xfer = ''1900-01-01 00:00:00''
                                                                         THEN cal_inicio
                                                                         ELSE cal_Xfer
                                                                     END) AS time_dialog, 
                          DATEADD(ss, ISNULL(cal_txfer + cal_tring + cal_tdialog, 0),
                                                                                   CASE
                                                                                       WHEN cal_Xfer IS NULL
                                                                                            OR cal_Xfer = ''1900-01-01 00:00:00''
                                                                                       THEN cal_inicio
                                                                                       ELSE cal_Xfer
                                                                                   END) AS time_notes, 
                          DATEADD(ss, ISNULL(cal_txfer + cal_tring + cal_tdialog + cal_tnotas, 0),
                                                                                                CASE
                                                                                                    WHEN cal_Xfer IS NULL
                                                                                                         OR cal_Xfer = ''1900-01-01 00:00:00''
                                                                                                    THEN cal_inicio
                                                                                                    ELSE cal_Xfer
                                                                                                END) AS time_end_call, 
                          cal_Ani AS phone_in, 
                          cal_id, 
                          dni_id, 
                          Inbound_id, 
                          [User_id], 
                          1 AS ntotal, 
                          ISNULL((CASE
                                      WHEN statuscall_id = 1
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS ninitial, 
                          ISNULL((CASE
                                      WHEN statuscall_id = 2
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nout_hour, 
                          ISNULL((CASE
                                      WHEN statuscall_id = 3
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nout_service, 
                          ISNULL((CASE
                                      WHEN(statuscall_id IN(5, 6)
                                           AND (cal_que > 0)
                                           AND (cal_xfer = ''1900-01-01 00:00:00''))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nabnd, 
                          ISNULL((CASE
                                      WHEN(statuscall_id = 4)
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nno_agent, 
                          ISNULL((CASE
                                      WHEN(cal_que > 0)
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nque, 
                          ISNULL((CASE
                                      WHEN(statuscall_id = 7)
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS ntimeout, 
                          ISNULL((CASE
                                      WHEN(statuscall_id = 8)
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS noverflow, 
                          ISNULL((CASE
                                      WHEN((statuscall_id IN(11, 15, 13, 16))
                                           OR (statuscall_id = 6
                                               AND cal_xfer <> ''1900-01-01 00:00:00''))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nxfer, 
                          ISNULL((CASE
                                      WHEN((cal_que > 0)
                                           AND (statuscall_id IN(11, 15, 13, 16)
                                                OR (statuscall_id = 6
                                                    AND cal_xfer <> ''1900-01-01 00:00:00'')))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nxfer_que, 
                          ISNULL((CASE
                                      WHEN((statuscall_id = 11)
                                           OR (statuscall_id = 6
                                               AND cal_xfer <> ''1900-01-01 00:00:00''))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nabnd_xfer, 
                          ISNULL((CASE
                                      WHEN((statuscall_id = 15)
                                           AND (cal_tring <= @tresRing))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nabnd_ring, 
                          ISNULL((CASE
                                      WHEN((statuscall_id = 15)
                                           AND (cal_tring > @tresRing))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nno_answer, 
                          ISNULL((CASE
                                      WHEN((statuscall_id = 13)
                                           AND (cal_tdialog <= @tresDialog))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nabnd_dialog, 
                          ISNULL((CASE
                                      WHEN((statuscall_id = 13)
                                           AND (cal_tdialog > @tresDialog))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nanswer, 
                          ISNULL((CASE
                                      WHEN(statuscall_id = 16)
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nlost, 
                          ISNULL((CASE
                                      WHEN(statuscall_id IN(9, 10, 12, 14))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nmsg, 
                          ISNULL((CASE
                                      WHEN((statuscall_id IN(5, 6)
                                            AND cal_que > 0
                                            AND cal_xfer = ''1900-01-01 00:00:00'')
                                           AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nabnd_tres, 
                          ISNULL((CASE
                                      WHEN((statuscall_id = 13
                                            AND cal_tdialog > @tresDialog)
                                           AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn))
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nansw_tres, 
                          cal_twait AS tque_max, 
                          cal_twait AS tque, 
                          cal_txfer AS txfer, 
                          ISNULL((cal_tdialog), 0) AS tdialog, 
                          ISNULL((cal_tnotas), 0) AS tnotes, 
                          ISNULL((cal_tring), 0) AS tring, 
                          ISNULL((CASE
                                      WHEN((statuscall_id = 13)
                                           AND (cal_tdialog > @tresDialog))
                                      THEN(cal_twait + cal_txfer + cal_tring)
                                      ELSE 0
                                  END), 0) AS tresp, 
                          ISNULL((CASE
                                      WHEN cal_tMoh > 0
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nMoh, 
                          ISNULL((CASE
                                      WHEN cal_whoHung > 0
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nWHag, 
                          ISNULL((CASE
                                      WHEN cal_whoHung = 0
                                      THEN 1
                                      ELSE 0
                                  END), 0) AS nWHcl
                   FROM ccCallsIn WITH (NOLOCK, INDEX(IX_ccCallsIn))
                   WHERE cal_inicio >= @fromExtended
                         AND cal_inicio < @to
                         AND INBOUND_ID > 0
               ) inboundData
               WHERE NOT(ntotal = 0
                         AND nout_hour = 0
                         AND nout_service = 0
                         AND nabnd = 0
                         AND nno_agent = 0
                         AND nque = 0
                         AND ntimeout = 0
                         AND noverflow = 0
                         AND nxfer = 0
                         AND nxfer_que = 0
                         AND nabnd_xfer = 0
                         AND nabnd_ring = 0
                         AND nno_answer = 0
                         AND nabnd_dialog = 0
                         AND nanswer = 0
                         AND nlost = 0
                         AND nmsg = 0
                         AND nabnd_tres = 0
                         AND nansw_tres = 0
                         AND tque_max = 0
                         AND tque = 0
                         AND txfer = 0
                         AND tring = 0
                         AND tdialog = 0
                         AND tnotes = 0
                         AND tresp = 0);


        UPDATE C
          SET 
              C.dateEndDetail = @dateNow, 
              C.timegroup_next = dbo.GetTimeGroup(DATEADD(ss, tiempo, B.fecha), 1), 
              C.time_dialog = CASE
                                  WHEN A.currentStatus IN(4, 5, 9)
                                  THEN @dateNow
                                  WHEN A.TipoStatusAge_id = 4
                                  THEN B.fecha
                                  ELSE C.dateStartDetail
                              END, 
              C.time_notes = @dateNow, 
              C.time_end_call = @dateNow, 
              C.tdialog = CASE
                              WHEN A.currentStatus IN(4, 5, 9)
                              THEN B.tiempo
                              WHEN A.TipoStatusAge_id = 4
                              THEN DATEDIFF(ss, C.dateStartDetail, B.fecha)
                              ELSE 0
                          END, 
              C.tnotes = CASE
                             WHEN A.currentStatus = 6
                             THEN B.tiempo
                             ELSE 0
                         END
        FROM ccLogAgentesDia A
             INNER JOIN #tempAgentLastStatus B ON A.fecha = B.fecha
                                                  AND A.User_id = B.id
             INNER JOIN #inboundData C ON A.callID = C.cal_id
        WHERE currentStatus IN(4, 5, 6, 9)
        AND A.Tipo = 0;


        SELECT *
        INTO #inboundData2
        FROM #inboundData
        WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

        DELETE #inboundData
        WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

        INSERT INTO #inboundData
        (dateStartDetail, 
         dateEndDetail, 
         timegroup, 
         timegroup_next, 
         time_endque, 
         time_ring, 
         time_dialog, 
         time_notes, 
         time_end_call, 
         phone_in, 
         cal_id, 
         dni_id, 
         Inbound_id, 
         [User_id], 
         ntotal, 
         ninitial, 
         nout_hour, 
         nout_service, 
         nabnd, 
         nno_agent, 
         nque, 
         ntimeout, 
         noverflow, 
         nxfer, 
         nxfer_que, 
         nabnd_xfer, 
         nabnd_ring, 
         nno_answer, 
         nabnd_dialog, 
         nanswer, 
         nlost, 
         nmsg, 
         nabnd_tres, 
         nansw_tres, 
         tque_max, 
         tque, 
         txfer, 
         tdialog, 
         tnotes, 
         tring, 
         tresp, 
         nMoh, 
         nWHag, 
         nWHcl
        )
               SELECT dateStartDetail, 
                      dateEndDetail, 
                      CONVERT(VARCHAR, th.start, 121) AS timegroup, 
                      CONVERT(VARCHAR, th.stop, 121) AS timegroup_next, 
                      time_endque, 
                      time_ring, 
                      time_dialog, 
                      time_notes, 
                      time_end_call, 
                      phone_in, 
                      cal_id, 
                      dni_id, 
                      Inbound_id, 
                      [User_id],
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN ntotal
                          ELSE 0
                      END AS ntotal,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN ninitial
                          ELSE 0
                      END AS ninitial,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nout_hour
                          ELSE 0
                      END AS nout_hour,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nout_service
                          ELSE 0
                      END AS nout_service,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd
                          ELSE 0
                      END AS nabnd,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nno_agent
                          ELSE 0
                      END AS nno_agent,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nque
                          ELSE 0
                      END AS nque,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN ntimeout
                          ELSE 0
                      END AS ntimeout,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN noverflow
                          ELSE 0
                      END AS noverflow,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nxfer
                          ELSE 0
                      END AS nxfer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nxfer_que
                          ELSE 0
                      END AS nxfer_que,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd_xfer
                          ELSE 0
                      END AS nabnd_xfer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd_ring
                          ELSE 0
                      END AS nabnd_ring,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nno_answer
                          ELSE 0
                      END AS nno_answer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd_dialog
                          ELSE 0
                      END AS nabnd_dialog,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nanswer
                          ELSE 0
                      END AS nanswer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nlost
                          ELSE 0
                      END AS nlost,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nmsg
                          ELSE 0
                      END AS nmsg,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd_tres
                          ELSE 0
                      END AS nabnd_tres,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nansw_tres
                          ELSE 0
                      END AS nansw_tres,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN tque_max
                          ELSE 0
                      END AS tque_max, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, time_endque) AS tque, 
                      dbo.TimeInterval(th.start, th.stop, time_endque, time_ring) AS txfer, 
                      dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog, 
                      dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes, 
                      dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tresp, dateStartDetail)) AS tresp,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nMoh
                          ELSE 0
                      END AS nMoh,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nWHag
                          ELSE 0
                      END AS nWHag,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nWHcl
                          ELSE 0
                      END AS nWHcl
               FROM #inboundData2 t
                    JOIN TmpTimesInterval th ON(t.timegroup > th.Start
                                                AND t.timegroup < th.stop)
                                               OR th.Start BETWEEN t.timegroup AND t.timegroup_next
               WHERE DATEDIFF(ss, th.start, timegroup_next) > 0
                     AND th.Start BETWEEN @from AND @to
               ORDER BY cal_id;


        INSERT INTO #outboundData
        (dateStartDetail, 
         dateEndDetail, 
         timegroup, 
         timegroup_next, 
         cam_id, 
         User_id, 
         ntotal, 
         nno_agent, 
         nxfer, 
         nabnd_xfer, 
         nabnd_ring, 
         nno_answer, 
         nabnd_dialog, 
         nanswer, 
         nlost, 
         tque, 
         txfer, 
         tring, 
         tdialog, 
         tnotes, 
         tresp, 
         nhangup, 
         nMoh, 
         nWHag, 
         nWHcl, 
         time_endque, 
         time_ring, 
         time_dialog, 
         time_notes, 
         time_end_call, 
         phone_out, 
         cal_id, 
         cal_puerto
        )
               SELECT *
               FROM
               (
                   SELECT cal_Inicio AS dateStartDetail, 
                          DATEADD(ss, ISNULL(SUM(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas), 0), cal_Inicio) AS dateEndDetail, 
                          dbo.GetTimeGroup(cal_inicio, 0) AS timegroup, 
                          dbo.GetTimeGroup(DATEADD(ss, ISNULL(SUM(cal_txfer + cal_tring + cal_tdialog + cal_tnotas), 0), cal_Inicio), 1) AS timegroup_next, 
                          cam_id, 
                          [User_id], 
                          COUNT(cal_id) AS ntotal, 
                          ISNULL(COUNT(CASE
                                           WHEN(statuscall_id = 4)
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nno_agent, 
                          ISNULL(COUNT(CASE
                                           WHEN(statuscall_id >= 10)
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nxfer, 
                          ISNULL(COUNT(CASE
                                           WHEN(statuscall_id = 11)
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nabnd_xfer, 
                          ISNULL(COUNT(CASE
                                           WHEN((statuscall_id = 15)
                                                AND (cal_tring <= @tresRing))
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nabnd_ring, 
                          ISNULL(COUNT(CASE
                                           WHEN((statuscall_id = 15)
                                                AND (cal_tring > @tresRing))
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nno_answer, 
                          ISNULL(COUNT(CASE
                                           WHEN((statuscall_id = 13)
                                                AND (cal_tdialog <= @tresDialog))
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nabnd_dialog, 
                          ISNULL(COUNT(CASE
                                           WHEN((statuscall_id = 13)
                                                AND (cal_tdialog > @tresDialog))
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nanswer, 
                          ISNULL(COUNT(CASE
                                           WHEN(statuscall_id = 16)
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nlost, 
                          ISNULL(SUM(cal_twait), 0) AS tque, 
                          ISNULL(SUM(cal_txfer), 0) AS txfer, 
                          ISNULL(SUM(cal_tring), 0) AS tring, 
                          ISNULL(SUM(cal_tdialog), 0) AS tdialog, 
                          ISNULL(SUM(cal_tnotas), 0) AS tnotes, 
                          ISNULL(SUM(CASE
                                         WHEN((statuscall_id = 13)
                                              AND (cal_tdialog > @tresDialog))
                                         THEN(cal_txfer + cal_tring)
                                         ELSE NULL
                                     END), 0) AS tresp, 
                          ISNULL(COUNT(CASE
                                           WHEN(statuscall_id = 6)
                                           THEN cal_id
                                           ELSE NULL
                                       END), 0) AS nhangup, 
                          ISNULL(SUM(CASE
                                         WHEN cal_tMoh > 0
                                         THEN 1
                                         ELSE 0
                                     END), 0) AS nMoh, 
                          ISNULL(SUM(CASE
                                         WHEN cal_whoHung > 0
                                         THEN 1
                                         ELSE 0
                                     END), 0) AS nWHag, 
                          ISNULL(SUM(CASE
                                         WHEN cal_whoHung = 0
                                         THEN 1
                                         ELSE 0
                                     END), 0) AS nWHcl, 
                          DATEADD(ss, ISNULL(SUM(0), 0), cal_inicio) AS time_endque, 
                          DATEADD(ss, ISNULL(SUM(0 + cal_txfer), 0), cal_inicio) AS time_ring, 
                          DATEADD(ss, ISNULL(SUM(0 + cal_txfer + cal_tring), 0), cal_inicio) AS time_dialog, 
                          DATEADD(ss, ISNULL(SUM(0 + cal_txfer + cal_tring + cal_tdialog), 0), cal_inicio) AS time_notes, 
                          DATEADD(ss, ISNULL(SUM(0 + cal_txfer + cal_tring + cal_tdialog + cal_tnotas), 0), cal_inicio) AS time_end_call, 
                          ISNULL(MAX(cal_telefono), 0) AS phone_out, 
                          cal_id, 
                          cal_puerto
                   FROM ccoCallsOut WITH (NOLOCK, INDEX(IX_ccoCallsOut_2))
                   WHERE cal_Inicio >= @fromExtended
                         AND cal_inicio < @to
                         -- para contar bien las llamadas manuales
                         AND cal_manual IN(0, 2)
                   GROUP BY cal_id, 
                            [User_id], 
                            cam_id, 
                            cal_Inicio, 
                            cal_puerto
               ) outboundData
               WHERE NOT(ntotal = 0
                         AND nno_agent = 0
                         AND nxfer = 0
                         AND nabnd_xfer = 0
                         AND nabnd_ring = 0
                         AND nno_answer = 0
                         AND nabnd_dialog = 0
                         AND nanswer = 0
                         AND nlost = 0
                         AND txfer = 0
                         AND tring = 0
                         AND tdialog = 0
                         AND tnotes = 0
                         AND tresp = 0)

        UPDATE C
          SET 
              C.dateEndDetail = @dateNow, 
              C.timegroup_next = dbo.GetTimeGroup(DATEADD(ss, tiempo, B.fecha), 1), 
              C.time_dialog = CASE
                                  WHEN A.currentStatus IN(4, 5, 9)
                                  THEN @dateNow
                                  WHEN A.TipoStatusAge_id = 4
                                  THEN B.fecha
                                  ELSE C.dateStartDetail
                              END, 
              C.time_notes = @dateNow, 
              C.time_end_call = @dateNow, 
              C.tdialog = CASE
                              WHEN A.currentStatus IN(4, 5, 9)
                              THEN B.tiempo
                              WHEN A.TipoStatusAge_id = 4
                              THEN DATEDIFF(ss, C.dateStartDetail, B.fecha)
                              ELSE 0
                          END, 
              C.tnotes = CASE
                             WHEN A.currentStatus = 6
                             THEN B.tiempo
                             ELSE 0
                         END
        FROM ccLogAgentesDia A
             INNER JOIN #tempAgentLastStatus B ON A.fecha = B.fecha
                                                  AND A.User_id = B.id
             INNER JOIN #outboundData C ON A.callID = C.cal_id
        WHERE currentStatus IN(4, 5, 6, 9)
        AND A.Tipo = 1;

        SELECT *
        INTO #outboundData2
        FROM #outboundData
        WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

        DELETE #outboundData
        WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

        INSERT INTO #outboundData
        (dateStartDetail, 
         dateEndDetail, 
         timegroup, 
         timegroup_next, 
         cam_id, 
         User_id, 
         ntotal, 
         nno_agent, 
         nxfer, 
         nabnd_xfer, 
         nabnd_ring, 
         nno_answer, 
         nabnd_dialog, 
         nanswer, 
         nlost, 
         tque, 
         txfer,
		 tdialog,
		 tnotes,
         tring,
		 tresp, 
         nhangup, 
         nMoh, 
         nWHag, 
         nWHcl, 
         time_endque, 
         time_ring, 
         time_dialog, 
         time_notes, 
         time_end_call, 
         phone_out, 
         cal_id, 
         cal_puerto
        )
               SELECT dateStartDetail, 
                      dateEndDetail, 
                      CONVERT(VARCHAR, th.start, 121) AS timegroup, 
                      CONVERT(VARCHAR, th.stop, 121) AS timegroup_next, 
                      cam_id, 
                      [User_id],
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN ntotal
                          ELSE 0
                      END AS ntotal,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nno_agent
                          ELSE 0
                      END AS nno_agent,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nxfer
                          ELSE 0
                      END AS nxfer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd_xfer
                          ELSE 0
                      END AS nabnd_xfer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd_ring
                          ELSE 0
                      END AS nabnd_ring,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nno_answer
                          ELSE 0
                      END AS nno_answer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nabnd_dialog
                          ELSE 0
                      END AS nabnd_dialog,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nanswer
                          ELSE 0
                      END AS nanswer,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nlost
                          ELSE 0
                      END AS nlost, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, time_endque) AS tque, 
                      dbo.TimeInterval(th.start, th.stop, time_endque, time_ring) AS txfer, 
                      dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog, 
                      dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes, 
                      dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tresp, dateStartDetail)) AS tresp,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nhangup
                          ELSE 0
                      END AS nhangup,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nMoh
                          ELSE 0
                      END AS nMoh,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nWHag
                          ELSE 0
                      END AS nWHag,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN nWHcl
                          ELSE 0
                      END AS nWHcl, 
                      time_endque, 
                      time_ring, 
                      time_dialog, 
                      time_notes, 
                      time_end_call, 
                      phone_out, 
                      cal_id, 
                      cal_puerto
               FROM #outboundData2 t
                    INNER JOIN TmpTimesInterval th ON(t.timegroup > th.Start
                                                      AND t.timegroup < th.stop)
                                                     OR th.Start BETWEEN t.timegroup AND t.timegroup_next
               WHERE DATEDIFF(ss, th.start, timegroup_next) > 0
                     AND th.Start BETWEEN @from AND @to
			   order by timegroup


        INSERT INTO #tempccLogAgentesDia
        (row, 
         [User_id], 
         TipoStatusAge_id, 
         tStatus, 
         dateIni, 
         dateEnd, 
         currentStatus
        )
               SELECT ROW_NUMBER() OVER(PARTITION BY user_id
                      ORDER BY DATEADD(ss, -tStatus, fecha)) AS Row, 
                      User_id, 
                      TipoStatusAge_id, 
                      tStatus, 
                      DATEADD(ss, -tStatus, fecha) dateIni, 
                      fecha dateEnd, 
                      ISNULL(currentStatus, -2)
               FROM ccLogAgentesDia
               WHERE DATEADD(ss, -tStatus, fecha) >= @from
                     AND DATEADD(ss, -tStatus, fecha) < @to;


        DELETE A
        FROM
        (
            SELECT CASE
                       WHEN A.tStatus > S.tStatus
                       THEN S.row
                       ELSE A.row
                   END row, 
                   A.user_id
            FROM #tempccLogAgentesDia A
                 LEFT JOIN #tempccLogAgentesDia S ON A.Row = S.Row - 1
                                                     AND A.user_id = S.user_id
            WHERE A.dateIni >= @from
                  AND A.dateIni < @to
                  AND A.TipoStatusAge_id = S.TipoStatusAge_id
                  AND (S.dateEnd BETWEEN A.dateIni AND A.dateEnd
                       OR S.dateIni BETWEEN A.dateIni AND A.dateEnd)
                  AND ABS(DATEDIFF(ss, A.dateEnd, S.dateIni)) > 2
        ) x
        INNER JOIN #tempccLogAgentesDia A ON A.row = x.row
                                             AND A.user_id = x.user_id;


        SELECT ROW_NUMBER() OVER(PARTITION BY user_id
               ORDER BY dateIni) AS Row, 
               User_id, 
               TipoStatusAge_id, 
               tStatus, 
               dateIni, 
               dateEnd, 
               currentStatus
        INTO #tempccLogAgentesDia2
        FROM #tempccLogAgentesDia;


        INSERT INTO #timeDetailAgent
               SELECT A.user_id, 
                      A.dateIni, 
                      A.dateEnd, 
                      dbo.GetTimeGroup(A.dateIni, 0) AS timegroup, 
                      dbo.GetTimeGroup(A.dateEnd, 1) AS timegroup_next,
                      CASE
                          WHEN A.tipostatusage_id = 1
                          THEN A.tStatus
                          ELSE 0
                      END tunknown,
                      CASE
                          WHEN A.tipostatusage_id = 2
                          THEN A.tStatus
                          ELSE 0
                      END tnot_av,
                      CASE
                          WHEN A.tipostatusage_id = 3
                          THEN A.tStatus
                          ELSE 0
                      END tav,
                      CASE
                          WHEN A.tipostatusage_id IN(11, 25, 26, 27)
                          THEN A.tStatus
                          ELSE 0
                      END tprob, --11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida
                      CASE
                          WHEN A.tipostatusage_id = 7
                          THEN A.tStatus
                          ELSE 0
                      END tother,
                      CASE
                          WHEN A.tipostatusage_id = 7
                          THEN 1
                          ELSE 0
                      END nother,
                      CASE
                          WHEN A.tipostatusage_id = 21
                          THEN A.tStatus
                          ELSE 0
                      END tmanualcall,
                      CASE
                          WHEN ABS(ISNULL(1.0 * DATEDIFF(ms, A.dateEnd, S.dateIni) / 1000, 0)) > A.tStatus
                          THEN 0
                          WHEN A.currentStatus IN(0, -1, -2)
                          THEN 0 --Logout
                          WHEN S.TipoStatusAge_id = 1
                          THEN 0
                          ELSE ISNULL(1.0 * DATEDIFF(ms, A.dateEnd, S.dateIni) / 1000, 0)
                      END AS tunknown2,
                      CASE
                          WHEN A.tipostatusage_id IN(23, 24)
                          THEN A.tStatus
                          ELSE 0
                      END AS tchatting
               FROM #tempccLogAgentesDia2 A
                    LEFT JOIN #tempccLogAgentesDia2 S ON A.Row = S.Row - 1
                                                         AND A.user_id = S.user_id
               WHERE A.dateIni >= @from
                     AND A.dateIni < @to
                     AND A.TipoStatusAge_id <> 0;


        UPDATE #timeDetailAgent
          SET 
              tunknown2 = 0
        WHERE ABS(tunknown2) > 2.7;


        INSERT INTO #timeDetailAgent
        (User_id, 
         dateStartDetail, 
         dateEndDetail, 
         timegroup, 
         timegroup_next, 
         tunknown, 
         tnot_av, 
         tav, 
         tprob, 
         tother, 
         nother, 
         tmanualcall, 
         tunknown2, 
         tchatting
        )
               SELECT User_id, 
                      B.fecha AS dateStartDetail, 
                      @dateNow AS dateEndDetail, 
                      dbo.GetTimeGroup(B.fecha, 0) AS timegroup, 
                      dbo.GetTimeGroup(DATEADD(ss, tiempo, B.fecha), 1) AS timegroup_next,
                      CASE
                          WHEN currentStatus = 1
                          THEN tiempo
                          ELSE 0
                      END AS tunknown,
                      CASE
                          WHEN currentStatus = 2
                          THEN tiempo
                          ELSE 0
                      END AS tnot_av,
                      CASE
                          WHEN tipostatusage_id = 1
                          THEN tiempo
                          WHEN currentStatus = 3
                          THEN tiempo
                          ELSE 0
                      END AS tav, 
                      0, 
                      0, 
                      0, 
                      0, 
                      0 AS tunknown2,
                      CASE
                          WHEN currentStatus IN(23, 24)
                          THEN tiempo
                          ELSE 0
                      END AS tchatting
               FROM ccLogAgentesDia A
                    INNER JOIN #tempAgentLastStatus B ON A.fecha = B.fecha
                                                         AND A.User_id = B.id
               WHERE A.currentStatus NOT IN(-2, -1, 0);


        SELECT *
        INTO #timeDetailAgent2
        FROM #timeDetailAgent
        WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;


        DELETE #timeDetailAgent
        WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;


        INSERT INTO #timeDetailAgent
        (dateStartDetail, 
         dateEndDetail, 
         timegroup, 
         timegroup_next, 
         User_id, 
         tunknown, 
         tnot_av, 
         tav, 
         tprob, 
         tother, 
         nother, 
         tmanualCall, 
         tunknown2, 
         tchatting
        )
               SELECT dateStartDetail, 
                      dateEndDetail, 
                      th.start AS timegroup, 
                      th.stop AS timegroup_next, 
                      [User_id], 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tunknown, dateStartDetail)) AS tunknown, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tnot_av, dateStartDetail)) AS tnot_av, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tav, dateStartDetail)) AS tav, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tprob, dateStartDetail)) AS tprob, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tother, dateStartDetail)) AS tother, 
                      ISNULL((CASE
                                  WHEN th.start > dateStartDetail
                                       AND th.stop > dateEndDetail
                                  THEN nother
                                  ELSE 0
                              END), 0) AS nother, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tmanualCall, dateStartDetail)) AS tmanualCall,
                      CASE
                          WHEN th.start > dateStartDetail
                               AND th.stop > dateEndDetail
                          THEN tunknown2
                          ELSE 0
                      END AS tunknown2, 
                      dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tchatting, dateStartDetail)) AS tchatting
               FROM #timeDetailAgent2 t
                    INNER JOIN TmpTimesInterval th ON(t.timegroup > th.Start
                                                      AND t.timegroup < th.stop)
                                                     OR th.Start BETWEEN t.timegroup AND t.timegroup_next
               WHERE DATEDIFF(ss, th.start, timegroup_next) > 0
                     AND th.Start BETWEEN @from AND @to;


        SELECT ROW_NUMBER() OVER(PARTITION BY xTimeDetail.user_id
               ORDER BY xTimeDetail.timegroup) AS Row, 
               xTimeDetail.timegroup, 
               xTimeDetail.[user_id], 
               timeSession.tlog, 
               xTimeDetail.tav, 
               xTimeDetail.tnot_av, 
               xTimeDetail.tprob, 
               xTimeDetail.tother, 
               xTimeDetail.tunknown, 
               xTimeDetail.tchatting, 
               xTimeDetail.tmanualCall, 
               xTimeDetail.nother, 
               ISNULL(B.txfer, 0) + ISNULL(C.txfer, 0) AS txfer, 
               ISNULL(B.tdialog, 0) + ISNULL(C.tdialog, 0) AS tdialog, 
               ISNULL(B.tnotes, 0) + ISNULL(C.tnotes, 0) AS tnotes, 
               ISNULL(B.tring, 0) + ISNULL(C.tring, 0) AS tring, 
               ISNULL(B.nMoh, 0) + ISNULL(C.nMoh, 0) AS nMoh, 
               ISNULL(B.nWHag, 0) + ISNULL(C.nWHag, 0) AS nWHag, 
               ISNULL(B.nWHcl, 0) + ISNULL(C.nWHcl, 0) AS nWHcl
        INTO #agentInformation
        FROM
        (
            SELECT x.User_id, 
                   x.timegroup,
                   CASE
                       WHEN SUM(tunknown + tunknown2) > 0
                       THEN SUM(tunknown + tunknown2)
                       ELSE SUM(tunknown)
                   END AS tunknown, 
                   SUM(tnot_av) AS tnot_av,
                   CASE
                       WHEN SUM(tav + tav2) > 0
                       THEN SUM(tav + tav2)
                       ELSE SUM(tav)
                   END AS tav,
                   CASE
                       WHEN SUM(tprob + tprob2) > 0
                       THEN SUM(tprob + tprob2)
                       ELSE SUM(tprob)
                   END AS tprob,
                   CASE
                       WHEN SUM(tother + tother2) > 0
                       THEN SUM(tother + tother2)
                       ELSE SUM(tother)
                   END AS tother,
                   CASE
                       WHEN SUM(tmanualcall + tmanualcall2) > 0
                       THEN SUM(tmanualcall + tmanualcall2)
                       ELSE SUM(tmanualcall)
                   END AS tmanualcall, 
                   SUM(nother) AS nother,
                   CASE
                       WHEN SUM(tchatting + tchatting2) > 0
                       THEN SUM(tchatting + tchatting2)
                       ELSE SUM(tchatting)
                   END AS tchatting
            FROM
            (
                SELECT User_id, 
                       timegroup, 
                       tunknown, 
                       tnot_av, 
                       tav, 
                       tprob, 
                       tother, 
                       tmanualcall, 
                       nother, 
                       tchatting, 
                       ISNULL(CAST(CASE
                                       WHEN tunknown > 0
                                       THEN tunknown2
                                       ELSE 0
                                   END AS INT), 0) AS tunknown2, 
                       ISNULL(CAST(CASE
                                       WHEN tav > 0
                                            AND (tav > ABS(tunknown2)
                                                 AND (tunknown2 + tav) > 0)
                                       THEN tunknown2
                                       ELSE 0
                                   END AS INT), 0) AS tav2, 
                       ISNULL(CAST(CASE
                                       WHEN tprob > 0
                                       THEN tunknown2
                                       ELSE 0
                                   END AS INT), 0) AS tprob2, 
                       ISNULL(CAST(CASE
                                       WHEN tother > 0
                                       THEN tunknown2
                                       ELSE 0
                                   END AS INT), 0) AS tother2, 
                       ISNULL(CAST(CASE
                                       WHEN tmanualcall > 0
                                       THEN tunknown2
                                       ELSE 0
                                   END AS INT), 0) AS tmanualcall2, 
                       ISNULL(CAST(CASE
                                       WHEN tchatting > 0
                                            OR (tchatting > ABS(tunknown2)
                                                AND (tunknown2 + tchatting) > 0)
                                       THEN tunknown2
                                       ELSE 0
                                   END AS INT), 0) AS tchatting2
                FROM #timeDetailAgent A
            ) x
            GROUP BY x.timegroup, 
                     x.User_id
        ) xTimeDetail
        INNER JOIN
        (
            SELECT user_id, 
                   timegroup, 
                   SUM(tlog) AS tlog
            FROM #sessionTimeGroup
            GROUP BY user_id, 
                     timegroup
        ) timeSession ON xTimeDetail.User_id = timeSession.user_id
                         AND xTimeDetail.timegroup = timeSession.timegroup
        LEFT JOIN
        (
            SELECT user_id, 
                   timegroup, 
                   SUM(txfer) AS txfer, 
                   SUM(tring) tring, 
                   SUM(tdialog) AS tdialog, 
                   SUM(tnotes) AS tnotes, 
                   SUM(nMoh) nMoh, 
                   SUM(nWHag) nWHag, 
                   SUM(nWHcl) nWHcl
            FROM #inboundData
            GROUP BY user_id, 
                     timegroup
        ) B ON xTimeDetail.timegroup = B.timegroup
               AND xTimeDetail.User_id = B.User_id
        LEFT JOIN
        (
            SELECT user_id, 
                   timegroup, 
                   SUM(txfer) AS txfer, 
                   SUM(tring) tring, 
                   SUM(tdialog) AS tdialog, 
                   SUM(tnotes) AS tnotes, 
                   SUM(nMoh) nMoh, 
                   SUM(nWHag) nWHag, 
                   SUM(nWHcl) nWHcl
            FROM #outboundData
            GROUP BY user_id, 
                     timegroup
        ) C ON xTimeDetail.timegroup = C.timegroup
               AND xTimeDetail.User_id = C.User_id;


        UPDATE B
          SET 
              B.tav = CASE
                          WHEN A.tav > 0
                               AND A.tav + A.tundefinded >= 0
                          THEN A.tav + A.tundefinded
                          ELSE A.tav
                      END
        FROM
        (
            SELECT User_id, 
                   timegroup, 
                   tlog, 
                   tav, 
                   tnot_av, 
                   tprob, 
                   tother, 
                   tunknown, 
                   tchatting, 
                   tmanualCall, 
                   nother, 
                   txfer, 
                   tdialog, 
                   tnotes, 
                   tring, 
                   tlog - tav - tnot_av - tprob - tother - tunknown - tchatting - tmanualCall - nother - txfer - tdialog - tnotes - tring AS tundefinded
            FROM #agentInformation
        ) A
        INNER JOIN #agentInformation B ON A.User_id = B.User_id
                                          AND A.timegroup = B.timegroup
        WHERE A.tundefinded < 0
              AND A.tav + A.tundefinded >= 0;


        UPDATE B
          SET 
              B.tunknown = CASE
                               WHEN A.tunknown > 0
                                    AND A.tunknown + A.tundefinded >= 0
                               THEN A.tunknown + A.tundefinded
                               ELSE A.tunknown
                           END
        FROM
        (
            SELECT User_id, 
                   timegroup, 
                   tlog, 
                   tav, 
                   tnot_av, 
                   tprob, 
                   tother, 
                   tunknown, 
                   tchatting, 
                   tmanualCall, 
                   nother, 
                   txfer, 
                   tdialog, 
                   tnotes, 
                   tring, 
                   tlog - tav - tnot_av - tprob - tother - tunknown - tchatting - tmanualCall - nother - txfer - tdialog - tnotes - tring AS tundefinded
            FROM #agentInformation
        ) A
        INNER JOIN #agentInformation B ON A.User_id = B.User_id
                                          AND A.timegroup = B.timegroup
        WHERE A.tundefinded < 0
              AND A.tunknown + A.tundefinded >= 0;


        SELECT ROW_NUMBER() OVER(
               ORDER BY CASE
                            WHEN agtInf.timegroup IS NOT NULL
                            THEN agtInf.timegroup
                            WHEN calls.timegroup IS NOT NULL
                            THEN calls.timegroup
                            ELSE 0
                        END,
                        CASE
                            WHEN agtInf.user_id IS NOT NULL
                            THEN agtInf.user_id
                            WHEN calls.userId IS NOT NULL
                            THEN calls.userId
                            ELSE-1
                        END) AS id, 
               agtInf.[row] rowAgentInformation, 
               ISNULL(rowIn, -1) rowIn, 
               ISNULL(rowOut, -1) rowOut, 
               ISNULL(callIdIn, '''') callIdIn, 
               ISNULL(phoneIn, '''') phoneIn, 
               ISNULL(dateStartDetailIn, '''') dateStartDetailIn, 
               ISNULL(callIdOut, '''') callIdOut, 
               ISNULL(phoneOut, '''') phoneOut, 
               ISNULL(dateStartDetailOut, '''') dateStartDetailOut, 
               (CASE
                    WHEN agtInf.timegroup IS NOT NULL
                    THEN agtInf.timegroup
                    WHEN calls.timegroup IS NOT NULL
                    THEN calls.timegroup
                    ELSE ''''
                END) [date], 
               (CASE
                    WHEN agtInf.user_id IS NOT NULL
                    THEN agtInf.user_id
                    WHEN calls.userId IS NOT NULL
                    THEN calls.userId
                    ELSE-1
                END) [userId], 
               u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + nombres AS [user], 
               u.login AS [login], 
               ISNULL(nxfer_in, 0) AS nxferin, 
               ISNULL(nanswer_in, 0) AS nanswerin, 
               ISNULL(nabnd_xfer_in, 0) AS nabndxferin, 
               ISNULL(nabnd_ring_in, 0) AS nabndringin, 
               ISNULL(nabnd_dlg_in, 0) AS nabnddlgin, 
               ISNULL(abnd_a_xfer_in, 0) AS abndaxferin, 
               ISNULL(nno_answer_in, 0) AS nnoanswerin, 
               ISNULL(nlost_in, 0) AS nlostin, 
               ISNULL(tdialog_in, 0) AS tdialogin, 
               ISNULL(tnotes_in, 0) AS tnotesin, 
               ISNULL(tring_in, 0) AS tringin, 
               ISNULL(txfer_in, 0) AS txferin, 
               ISNULL(nxfer_out, 0) AS nxferout, 
               ISNULL(nanswer_out, 0) AS nanswerout, 
               ISNULL(nabnd_xfer_out, 0) AS nabndxferout, 
               ISNULL(nabnd_ring_out, 0) AS nabndringout, 
               ISNULL(nabnd_dlg_out, 0) AS nabnddlgout, 
               ISNULL(abnd_a_xfer_out, 0) AS abndaxferout, 
               ISNULL(nno_answer_out, 0) AS nnoanswerout, 
               ISNULL(nlost_out, 0) AS nlostout, 
               ISNULL(tdialog_out, 0) AS tdialogout, 
               ISNULL(tnotes_out, 0) AS tnotesout, 
               ISNULL(tring_out, 0) AS tringout, 
               ISNULL(txfer_out, 0) AS txferout, 
               ISNULL(agtInf.nother, 0) AS nother, 
               ISNULL(agtInf.tunknown, 0) AS tunknown, 
               ISNULL(agtInf.tnot_av, 0) AS tnotav, 
               agtInf.tlog AS tlog, 
               ISNULL(agtInf.tav, 0) AS tav, 
               ISNULL(agtInf.tother, 0) + ISNULL(tmanualcall, 0) AS tother, 
               ISNULL(agtInf.tprob, 0) AS tprob, 
               ISNULL(agtInf.tchatting, 0) AS tchatting, 
               ISNULL(nMoh_in, 0) AS nMohin, 
               ISNULL(nMoh_out, 0) AS nMohout, 
               ISNULL(nWHag_in, 0) AS nWHagin, 
               ISNULL(nWHag_out, 0) AS nWHagout, 
               ISNULL(nWHcl_in, 0) AS nWHcliin, 
               ISNULL(nWHcl_out, 0) AS nWHcliout,
               CASE
                   WHEN agtInf.timegroup IS NOT NULL
                   THEN DATEPART(yy, agtInf.timegroup)
                   WHEN calls.timegroup IS NOT NULL
                   THEN DATEPART(yy, calls.timegroup)
                   ELSE 0
               END AS [year],
               CASE
                   WHEN agtInf.timegroup IS NOT NULL
                   THEN DATEPART(mm, agtInf.timegroup)
                   WHEN calls.timegroup IS NOT NULL
                   THEN DATEPART(mm, calls.timegroup)
                   ELSE 0
               END AS [month],
               CASE
                   WHEN agtInf.timegroup IS NOT NULL
                   THEN DATEPART(dd, agtInf.timegroup)
                   WHEN calls.timegroup IS NOT NULL
                   THEN DATEPART(dd, calls.timegroup)
                   ELSE 0
               END AS [day],
               CASE
                   WHEN agtInf.timegroup IS NOT NULL
                   THEN DATEPART(hh, agtInf.timegroup)
                   WHEN calls.timegroup IS NOT NULL
                   THEN DATEPART(hh, calls.timegroup)
                   ELSE 0
               END AS [hour],
               CASE
                   WHEN agtInf.timegroup IS NOT NULL
                   THEN DATEPART(mi, agtInf.timegroup)
                   WHEN calls.timegroup IS NOT NULL
                   THEN DATEPART(mi, calls.timegroup)
                   ELSE 0
               END AS [minutes]
        INTO #tempRepAgentGI
        FROM #agentInformation agtInf
             LEFT JOIN ccUserView u ON agtInf.[user_id] = u.[user_id]
             LEFT JOIN
        (
            SELECT(CASE
                       WHEN _in.timegroup IS NOT NULL
                       THEN _in.timegroup
                       ELSE _out.timegroup
                   END) timegroup, 
                  (CASE
                       WHEN _in.[user_id] IS NOT NULL
                       THEN _in.[user_id]
                       ELSE _out.[user_id]
                   END) [userId], 
                  ISNULL(_in.row, -1) AS rowIn, 
                  ISNULL(_out.row, -1) AS rowOut, 
                  ISNULL((_in.nxfer), 0) AS nxfer_in, 
                  ISNULL((_in.nanswer), 0) AS nanswer_in, 
                  ISNULL((_in.nabnd_xfer), 0) AS nabnd_xfer_in, 
                  ISNULL((_in.nabnd_ring), 0) AS nabnd_ring_in, 
                  ISNULL((_in.nabnd_dialog), 0) AS nabnd_dlg_in, 
                  ISNULL((_in.nabnd_xfer), 0) + ISNULL((_in.nabnd_ring), 0) + ISNULL((_in.nabnd_dialog), 0) AS abnd_a_xfer_in, 
                  ISNULL((_in.nno_answer), 0) AS nno_answer_in, 
                  ISNULL((_in.nlost), 0) AS nlost_in, 
                  ISNULL((_in.tdialog), 0) AS tdialog_in, 
                  ISNULL((_in.tnotes), 0) AS tnotes_in, 
                  ISNULL((_in.tring), 0) AS tring_in, 
                  ISNULL((_in.txfer), 0) AS txfer_in, 
                  ISNULL((_in.nMoh), 0) AS nMoh_in, 
                  ISNULL((_in.nWHag), 0) AS nWHag_in, 
                  ISNULL((_in.nWHcl), 0) AS nWHcl_in, 
                  ISNULL((_out.nxfer), 0) AS nxfer_out, 
                  ISNULL((_out.nanswer), 0) AS nanswer_out, 
                  ISNULL((_out.nabnd_xfer), 0) AS nabnd_xfer_out, 
                  ISNULL((_out.nabnd_ring), 0) AS nabnd_ring_out, 
                  ISNULL((_out.nabnd_dialog), 0) AS nabnd_dlg_out, 
                  ISNULL((_out.nabnd_xfer), 0) + ISNULL((_out.nabnd_ring), 0) + ISNULL((_out.nabnd_dialog), 0) AS abnd_a_xfer_out, 
                  ISNULL((_out.nno_answer), 0) AS nno_answer_out, 
                  ISNULL((_out.nlost), 0) AS nlost_out, 
                  ISNULL((_out.tdialog), 0) AS tdialog_out, 
                  ISNULL((_out.tnotes), 0) AS tnotes_out, 
                  ISNULL((_out.tring), 0) AS tring_out, 
                  ISNULL((_out.txfer), 0) AS txfer_out, 
                  ISNULL((_out.nMoh), 0) AS nMoh_out, 
                  ISNULL((_out.nWHag), 0) AS nWHag_out, 
                  ISNULL((_out.nWHcl), 0) AS nWHcl_out, 
                  ISNULL((_in.cal_id), '''') AS callIdIn, 
                  ISNULL((_in.phone_in), '''') AS phoneIn, 
                  ISNULL((_in.dateStartDetail), '''') AS dateStartDetailIn, 
                  ISNULL((_out.cal_id), '''') AS callIdOut, 
                  ISNULL((_out.phone_out), '''') AS phoneOut, 
                  ISNULL((_out.dateStartDetail), '''') AS dateStartDetailOut
            FROM #inboundData _in
                 FULL OUTER JOIN #outboundData _out ON _in.timegroup = _out.timegroup
                                                       AND _in.[user_id] = _out.[user_id]
        ) calls ON calls.timegroup = agtInf.timegroup
                   AND agtInf.[user_id] = calls.[userid]
        WHERE agtInf.timegroup IS NOT NULL;


        UPDATE A
          SET 
              nother = 0, 
              tunknown = 0, 
              tnotav = 0, 
              tlog = 0, 
              tother = 0, 
              tprob = 0, 
              tav = 0, 
              tchatting = 0
        FROM
        (
            SELECT RANK() OVER(PARTITION BY A.rowAgentInformation, 
                                            A.userId
                   ORDER BY id) AS [rank], 
                   A.id
            FROM #tempRepAgentGI A
                 INNER JOIN
            (
                SELECT temp.rowAgentInformation, 
                       temp.[UserId]
                FROM #tempRepAgentGI temp
                GROUP BY temp.rowAgentInformation, 
                         temp.[UserId]
                HAVING COUNT(*) > 1
            ) B ON A.userId = B.userId
                   AND A.rowAgentInformation = B.rowAgentInformation
        ) x
        INNER JOIN #tempRepAgentGI A ON A.id = x.id
        WHERE x.rank > 1;


        UPDATE A
          SET 
              nxferin = 0, 
              nanswerin = 0, 
              nabndxferin = 0, 
              nabndringin = 0, 
              nabnddlgin = 0, 
              abndaxferin = 0, 
              nnoanswerin = 0, 
              nlostin = 0, 
              tdialogin = 0, 
              tnotesin = 0, 
              tringin = 0, 
              txferin = 0, 
              nMohin = 0, 
              nWHagin = 0, 
              nWHcliin = 0
        FROM
        (
            SELECT RANK() OVER(PARTITION BY A.rowIn, 
                                            A.userId
                   ORDER BY id) AS [rank], 
                   A.id
            FROM #tempRepAgentGI A
                 INNER JOIN
            (
                SELECT temp.rowIn, 
                       temp.[UserId]
                FROM #tempRepAgentGI temp
                GROUP BY temp.rowIn, 
                         temp.[UserId]
                HAVING COUNT(*) > 1
            ) B ON A.userId = B.userId
                   AND A.rowIn = B.rowIn
        ) x
        INNER JOIN #tempRepAgentGI A ON A.id = x.id
        WHERE x.rank > 1;


        UPDATE A
          SET 
              nxferout = 0, 
              nanswerout = 0, 
              nabndxferout = 0, 
              nabndringout = 0, 
              nabnddlgout = 0, 
              abndaxferout = 0, 
              nnoanswerout = 0, 
              nlostout = 0, 
              tdialogout = 0, 
              tnotesout = 0, 
              tringout = 0, 
              txferout = 0, 
              nMohout = 0, 
              nWHagout = 0, 
              nWHcliout = 0
        FROM
        (
            SELECT RANK() OVER(PARTITION BY A.rowOut, 
                                            A.userId
                   ORDER BY id) AS [rank], 
                   A.id
            FROM #tempRepAgentGI A
                 INNER JOIN
            (
                SELECT temp.rowOut, 
                       temp.[UserId]
                FROM #tempRepAgentGI temp
                GROUP BY temp.rowOut, 
                         temp.[UserId]
                HAVING COUNT(*) > 1
            ) B ON A.userId = B.userId
                   AND A.rowOut = B.rowOut
        ) x
        INNER JOIN #tempRepAgentGI A ON A.id = x.id
        WHERE x.rank > 1;


        DELETE FROM RepAgentGI
        WHERE date >= @from
              AND date < @to;


        INSERT INTO RepAgentGI
        (date, 
         userId, 
         [user], 
         login, 
         nxferin, 
         nanswerin, 
         nabndxferin, 
         nabndringin, 
         nabnddlgin, 
         abndaxferin, 
         nnoanswerin, 
         nlostin, 
         tdialogin, 
         tnotesin, 
         tringin, 
         txferin, 
         nxferout, 
         nanswerout, 
         nabndxferout, 
         nabndringout, 
         nabnddlgout, 
         abndaxferout, 
         nnoanswerout, 
         nlostout, 
         tdialogout, 
         tnotesout, 
         tringout, 
         txferout, 
         nother, 
         tunknown, 
         tnotav, 
         tlog, --treq,
         tav, 
         tother, 
         tprob, 
         nmohin, 
         nmohout, 
         nwhagin, 
         nwhagout, 
         nwhcliin, 
         nwhcliout, 
         year, 
         month, 
         day, 
         hour, 
         minutes, 
         phonein, 
         dateStartDetailIn, 
         callIdIn, 
         phoneout, 
         dateStartDetailOut, 
         callIdOut, 
         tnotavg, 
         tundefined, 
         tchatting
        )
               SELECT date, 
                      userId, 
                      ISNULL([user], ''otro''), 
                      ISNULL(login, ''otro'') login, 
                      nxferin, 
                      nanswerin, 
                      nabndxferin, 
                      nabndringin, 
                      nabnddlgin, 
                      abndaxferin, 
                      nnoanswerin, 
                      nlostin, 
                      tdialogin, 
                      tnotesin, 
                      tringin, 
                      txferin, 
                      nxferout, 
                      nanswerout, 
                      nabndxferout, 
                      nabndringout, 
                      nabnddlgout, 
                      abndaxferout, 
                      nnoanswerout, 
                      nlostout, 
                      tdialogout, 
                      tnotesout, 
                      tringout, 
                      txferout, 
                      nother, 
                      tunknown, 
                      tnotav, 
                      tlog, --treq,
                      tav, 
                      tother, 
                      tprob, 
                      nmohin, 
                      nmohout, 
                      nwhagin, 
                      nwhagout, 
                      nwhcliin, 
                      nwhcliout, 
                      year, 
                      month, 
                      day, 
                      hour, 
                      minutes, 
                      phonein, 
                      dateStartDetailIn, 
                      callIdIn, 
                      phoneout, 
                      dateStartDetailOut, 
                      callIdOut, 
                      tnotav, 
                      (tlog - tdialogin - tnotesin - tringin - txferin - tdialogout - tnotesout - tringout - txferout - tunknown - tnotav - tav - tother - tprob - tchatting) AS tundefined, 
                      tChatting
               FROM #tempRepAgentGI;

		
        --DROP TABLES TEMP	
        IF OBJECT_ID(''tempdb..#inboundData'') IS NOT NULL
            DROP TABLE #inboundData;
        IF OBJECT_ID(''tempdb..#inboundData2'') IS NOT NULL
            DROP TABLE #inboundData2;
        IF OBJECT_ID(''tempdb..#outboundData'') IS NOT NULL
            DROP TABLE #outboundData;
        IF OBJECT_ID(''tempdb..#outboundData2'') IS NOT NULL
            DROP TABLE #outboundData2;
        IF OBJECT_ID(''tempdb..#timeDetailAgent'') IS NOT NULL
            DROP TABLE #timeDetailAgent;
        IF OBJECT_ID(''tempdb..#timeDetailAgent2'') IS NOT NULL
            DROP TABLE #timeDetailAgent2;
        IF OBJECT_ID(''tempdb..#agentInformation'') IS NOT NULL
            DROP TABLE #agentInformation;
        IF OBJECT_ID(''tempdb..#tempRepAgentGI'') IS NOT NULL
            DROP TABLE #tempRepAgentGI;
        IF OBJECT_ID(''tempdb..#tempAgentLastStatus'') IS NOT NULL
            DROP TABLE #tempAgentLastStatus;
        IF OBJECT_ID(''tempdb..#tempccLogAgentesDia'') IS NOT NULL
            DROP TABLE #tempccLogAgentesDia;
        IF OBJECT_ID(''tempdb..#tempccLogAgentesDia2'') IS NOT NULL
            DROP TABLE #tempccLogAgentesDia2;
        IF OBJECT_ID(''tempdb..#sessionTimeGroup'') IS NOT NULL
            DROP TABLE #sessionTimeGroup;
END;'
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
