/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/04/06
Description:

Database: CCenterRia
Required version: 123.18

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
values(228,''1|1|5|13:00|192.168.1.115|root|toor|21|/mnt/Utilidades/Utilidades/Reminder/slingshot-installer/Series/USASeries.zip''
,''Descarga automática de las series USA''
,1,''GLR'',''Activo(0:apagado,1:Mensual,2:semanal,3:diario)|# Semana Ejecucion|Dia Ejecucion(1:LU,2:Ma,3:Mi,4:Ju,5:Vi,6:Sa,0:Do)|Hora Inicio(00:00)|Servidor FTP|usuario FTP|contraseña FTP|Ruta de descarga FTP'',''USA number series automatic download'',1,''.*'')
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
							left join ccTimeZones B on A.tz_standar=B.tz_offset
							left join ccTimeZones C on A.tz_dayligth=C.tz_offset			
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
	set @sql = 'if not exists (select * from sys.objects where object_id = OBJECT_ID(N''ChangePriorityCall'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
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

  set @process = 'CW-'	
	set @sql = ''
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
