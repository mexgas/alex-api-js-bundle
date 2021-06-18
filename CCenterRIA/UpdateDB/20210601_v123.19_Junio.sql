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
