/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio Chagolla
Date: 2024/09/30
Description: Release 126.20241218.0.0
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
SET @versionfix = 30
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

	------------------------------------------- BEGIN Frida ----------------------------------------
	SET @process = 'DEV2-807 DROP PROCEDURE ccsp_GalateaAdminBlackListCampout'
	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminBlackListCampout'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminBlackListCampout
    end'
	EXEC(@sql)

	SET @process = 'DEV2-807 CREATE PROCEDURE ccsp_GalateaAdminBlackListCampout'
	SET @sql = '
	
CREATE PROCEDURE ccsp_GalateaAdminBlackListCampout
@Option smallint,
@IDArea smallint = 0,
@CamID SmallInt = 0,
@InsertSchedule_id varchar(max) = ''0'',
@DeleteSchedule_id varchar(max) = ''0'',
@ManyOutboundIDs varchar(max)='''',
@PhoneNumber varchar(20)=''''
as

if @Option = 1 -- Asignar listas negras a una campaña de salida
 begin

  if @CamID = 0
   begin
    update Camplistanegra set status = 1 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '',''))

    insert into Camplistanegra (idtipolista, cam_id, status)
    select FN.value, C.cam_id, 1 from ccCamps C, dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','') FN where C.IDArea = @IDArea
    and C.cam_id not in (select CL.cam_id from Camplistanegra CL join dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','') FN
    on CL.idtipolista = FN.value where CL.status = 1)
    return(0)
   end

  update Camplistanegra set status = 1 where cam_id = @CamID
  and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '',''))

  insert into Camplistanegra (idtipolista, cam_id, status)
  select value, @CamID, 1 from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','')
    where value not in (select idtipolista from Camplistanegra where cam_id = @CamID and status = 1
    and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','')))

  Insert Into ccAgendaListaNegra (campsid,fecharegs,fechaaplicar) values (@CamID,''20100101'',getDate()) -- El 2010 es para que quite registros viejos con base en el cal fecha dial de ccocallsoutsource, principalmente para quitar callbacks de numeros cargados hace mucho tiempo

  declare @idAgenda as int
  select @idAgenda = SCOPE_IDENTITY()

  insert into ccAgenda_TipoListaNegra(idAgenda,idtipolista)
  select @idAgenda, value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '','')

  select DISTINCT idtipolista as BlacklistIdAssigned from Camplistanegra 
  where cam_id=@CamID and status=1 and idtipolista in (select value from dbo.fn_RIASplitDelimited(@InsertSchedule_id, '',''))
 end

if @Option = 2 -- Desasignar listas negras de la campaña de salida @CamID
 begin
  update Camplistanegra set status = 0 where cam_id = @CamID  and idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, '',''))
  return(0)
 end

if @Option = 3 -- Desasignar listas negras de todas las campañas de salida a las que esten asignadas
 begin
 update Camplistanegra set status = 0 where idtipolista in (select value from dbo.fn_RIASplitDelimited(@DeleteSchedule_id, '',''))
  return(0)
 end

 if @Option = 4 -- trae las listas negras de la campaña de salida indicada en @CamID
 begin
  select cl.cam_id as CampId, ca.cam_descripcion as CampName, cl.idtipolista as BlacklistId, tl.Tipolista as BlacklistName
  from Camplistanegra cl join ccCamps ca on cl.cam_id = ca.cam_id
   join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
  where cl.status = 1 and cl.cam_id = @CamID
  order by 1, 3
  return(0)
 end

  if @Option = 5 -- trae las relaciones entre listas negras y las campaña de salida indicadas en @ManyOutboundIDs
 begin
  select cl.cam_id as CampId, ca.cam_descripcion as CampName, cl.idtipolista as BlacklistId, tl.Tipolista as BlacklistName
  from Camplistanegra cl join ccCamps ca on cl.cam_id = ca.cam_id
   join cctiposlistanegra tl on cl.idtipolista = tl.idtipolista
  where cl.status = 1 and cl.cam_id in(select value from dbo.fn_RIASplitDelimited(@ManyOutboundIDs, '',''))
  order by 1, 3
  return(0)
 end
 if @Option = 6 --Regresa si el teléfono existe o no en alguna lista negra
 begin
	declare @matchPhoneNumber varchar(20)
	set @matchPhoneNumber = (select top(1) telefono from cchistoriallistanegra cch
	join Camplistanegra cln 
	on cln.idtipolista = cch.idtipolista
	and cln.cam_id=@CamID and cch.telefono=@PhoneNumber)
	if (@matchPhoneNumber <> '''')
	begin
		select 1
	end
	else
		select 0
 end
'
	EXEC(@sql)
    -------------------------------------------- END Frida -----------------------------------------

------------------------------------ Begin Daniel Hernandez -------------------------------------

SET @process = 'Verify if exists ccsp_AgentGetEspecialidadesActivas'
SET @sql='
IF EXISTS
(SELECT * FROM sys.sql_modules WHERE OBJECT_NAME(OBJECT_ID)= ''ccsp_AgentGetEspecialidadesActivas'')
BEGIN
    DROP PROCEDURE ccsp_AgentGetEspecialidadesActivas
END'
EXEC(@sql);

SET @process = 'CREATE SP ccsp_AgentGetEspecialidadesActivas'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_AgentGetEspecialidadesActivas]
    @userID INT,
    @current INT = 0
    AS
    BEGIN
        SET NOCOUNT ON;
        SET DATEFIRST 1; -- Asegura que el primer día de la semana sea lunes

        DECLARE @fecha DATETIME = GETDATE();
        DECLARE @dia SMALLINT = DATEPART(dw, @fecha);
        DECLARE @hora SMALLINT = DATEPART(HOUR, @fecha);
        DECLARE @minuto SMALLINT = DATEPART(MINUTE, @fecha);
        DECLARE @value INT = (SELECT valor FROM ccSettings WHERE setting_id = 191);

        IF @value = 0
        BEGIN
            -- Consulta cuando @value es 0
            SELECT -8 AS inbound_id, ''Survey'' AS name, 1 AS frame
            UNION
            SELECT -1 AS inbound_id, ''IVR'' AS name, 1 AS frame
            UNION
            SELECT inb.inbound_id AS inbound_id, descripcion AS name, graphic.graphic_id AS frame
            FROM ccInbound inb
            LEFT JOIN ccRIAInboundGraph graphic ON inb.Inbound_id = graphic.Inbound_id
            WHERE inb.inbound_id IN (
                SELECT inbound_id
                FROM ccInboundHorarios
                WHERE horario_id IN (
                    SELECT horario_id
                    FROM ccHorarios
                    WHERE (@hora > HoraInicio OR (@hora = HoraInicio AND @minuto >= MinInicio))
                      AND (@hora < HoraFin OR (@hora = HoraFin AND @minuto <= MinFin))
                      AND (
                          (Lunes = 1 AND @dia = 2) OR
                          (Martes = 1 AND @dia = 3) OR
                          (Miercoles = 1 AND @dia = 4) OR
                          (Jueves = 1 AND @dia = 5) OR
                          (Viernes = 1 AND @dia = 6) OR
                          (Sabado = 1 AND @dia = 7) OR
                          (Domingo = 1 AND @dia = 1)
                      )
                )
            )
            AND inb.inbound_id <> @current
            AND status <> 0
            ORDER BY 1;
        END
        ELSE IF @value = 1
        BEGIN
            IF @current <> 0
            BEGIN
                -- Consulta cuando @value es 1 y @current no es 0
                SELECT -1 AS inbound_id, ''IVR'' AS name, 1 AS frame
                UNION
                SELECT inb.inbound_id AS inbound_id, descripcion AS name, graphic.graphic_id AS frame
                FROM ccInbound inb
                LEFT JOIN ccRIAInboundGraph graphic ON inb.Inbound_id = graphic.Inbound_id
                WHERE inb.inbound_id IN (
                    SELECT inbound_id
                    FROM ccInboundHorarios
                    WHERE horario_id IN (
                        SELECT horario_id
                        FROM ccHorarios
                        WHERE (@hora > HoraInicio OR (@hora = HoraInicio AND @minuto >= MinInicio))
                          AND (@hora < HoraFin OR (@hora = HoraFin AND @minuto <= MinFin))
                          AND (
                              (Lunes = 1 AND @dia = 2) OR
                              (Martes = 1 AND @dia = 3) OR
                              (Miercoles = 1 AND @dia = 4) OR
                              (Jueves = 1 AND @dia = 5) OR
                              (Viernes = 1 AND @dia = 6) OR
                              (Sabado = 1 AND @dia = 7) OR
                              (Domingo = 1 AND @dia = 1)
                          )
                    )
                )
                AND inb.inbound_id <> @current
                AND status <> 0
                AND IDArea IN (SELECT cu.IDArea FROM ccUsers cu WHERE cu.User_id = @current)
                ORDER BY 2;
            END
            ELSE
            BEGIN
                -- Consulta cuando @value es 1 y @current es 0
                SELECT -1 AS inbound_id, ''IVR'' AS name, 1 AS frame
                UNION
                SELECT inb.inbound_id AS inbound_id, descripcion AS name, graphic.graphic_id AS frame
                FROM ccInbound inb
                LEFT JOIN ccRIAInboundGraph graphic ON inb.Inbound_id = graphic.Inbound_id
                WHERE inb.inbound_id IN (
                    SELECT inbound_id
                    FROM ccInboundHorarios
                    WHERE horario_id IN (
                        SELECT horario_id
                        FROM ccHorarios
                        WHERE (@hora > HoraInicio OR (@hora = HoraInicio AND @minuto >= MinInicio))
                          AND (@hora < HoraFin OR (@hora = HoraFin AND @minuto <= MinFin))
                          AND (
                              (Lunes = 1 AND @dia = 2) OR
                              (Martes = 1 AND @dia = 3) OR
                              (Miercoles = 1 AND @dia = 4) OR
                              (Jueves = 1 AND @dia = 5) OR
                              (Viernes = 1 AND @dia = 6) OR
                              (Sabado = 1 AND @dia = 7) OR
                              (Domingo = 1 AND @dia = 1)
                          )
                    )
                )
                AND inb.inbound_id <> @current
                AND status <> 0
                AND IDArea IN (SELECT IDArea FROM ccUsers WHERE User_id = @userID)
                ORDER BY 2;
            END
        END
    END';
EXEC(@sql);

-------------------------END Daniel Hernandez--------------------------------------------

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
