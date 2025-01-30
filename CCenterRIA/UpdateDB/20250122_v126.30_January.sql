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

 --------------------------------------------- BEGIN Luis Miguel Zamora Nuñez ----------------------------------------
    SET @process = 'DEV1-742 DROP PROCEDURE ccsp_RIADNCList'
    SET @sql = '
    if exists (select * from sys.procedures where name = N''ccsp_RIADNCList'')
    begin
        DROP PROCEDURE ccsp_RIADNCList
    end'
    EXEC(@sql)

    SET @process = 'Listas negras internacional ccsp_RIADNCList se modifica VARCHAR a NVARCHAR para compatibilidad'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIADNCList] 
@phoneNumber AS NVARCHAR(30) = NULL, 
@idDNCList AS INTEGER, 
@tipoMov AS TINYINT, 
@calKey AS VARCHAR(40) = NULL,
@cleanType int=0 --0 limpia,2 verifica
AS
DECLARE @hashCalKey bigint, @hashPhone BIGINT

IF @calKey IS NOT NULL
BEGIN
    SELECT @hashCalKey = dbo.hashList(@calKey)
END

IF @tipoMov = 1
BEGIN -- Inserta Lista Negra    
    EXEC ccsp_InsertDNCList @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null,@cleanType=@cleanType
    EXEC ccsp_InsertDNCListSms @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null
    EXEC [ccsp_InsertDNCListWhatsApp] @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null
END

IF @tipoMov = 2
BEGIN -- Borra Lista Negra  
    SELECT @hashPhone = dbo.hashPhone(@phoneNumber)

    IF @hashCalKey IS NULL
    BEGIN
        DELETE
        FROM cclistanegra
        WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idDNCList
    END
    ELSE
    BEGIN
        DELETE
        FROM cclistanegra
        WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idDNCList
    END

    INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
    VALUES (@phoneNumber, 5, @idDNCList)
END

IF @tipoMov = 3
BEGIN -- Reemplaza Lista Negra
    INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
    SELECT telefono, ''4'', @idDNCList
    FROM cclistanegra
    WHERE idtipolista = @idDNCList

    DELETE
    FROM cclistanegra
    WHERE idtipolista = @idDNCList
END '
    EXEC(@sql)

    SET @process = 'DEV1-742 DROP PROCEDURE ccsp_InsertDNCList'
    SET @sql = '
    if exists (select * from sys.procedures where name = N''ccsp_InsertDNCList'')
    begin
        DROP PROCEDURE ccsp_InsertDNCList
    end'
    EXEC(@sql)

    SET @process = 'Listas negras [ccsp_InsertDNCList] se agrega @params y correcciones del SP en valores tipo NVARCHAR'
    SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as nvarchar(30)=null,
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL,
@cleanType int=0 --0 limpia,2 verifica
AS

Set nocount on

declare @sqlcmd nvarchar(max), @tmpTableName varchar(40), @sqlcmd_replace nvarchar(max),
@dropTmpPhone nvarchar(max) = null
,@fnPhone nvarchar(100) =null
,@motivo nvarchar(100)
,@keyTranslate nvarchar(100)
,@params nvarchar(max)  

declare @phoneEmpty nvarchar(1)
set @phoneEmpty =''''


set @fnPhone=case when @cleanType=0 then ''[dbo].[Limpia](@telephone)'' else  ''[dbo].[Verifica](@telephone)'' end

set @motivo=case when @cleanType=0 then ''Length exceeded'' else  ''Error en COFETEL'' end
set @keyTranslate=case when @cleanType=0 then ''description-length'' else  ''description-cofetel'' end


SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));

if (@telephone is not null) -- Para insertar un solo numero cuando se manda a BL por calificación
BEGIN
    IF EXISTS (SELECT * from ccListaNegra where idtipolista = @ln_id and telefono = @telephone and HashKey = dbo.hashList(@calKey)) begin
        RETURN 0;
    end

    set @tmpTableName = ''TMP_BLACKLIST_'' + @telephone;
    SET @dropTmpPhone = ''if exists (select * from sys.tables where name = N'''''' + @tmpTableName + '''''') drop table '' + @tmpTableName;

    SET @sqlcmd = ''CREATE TABLE '' + @tmpTableName + ''(
    [phoneNumber] VARCHAR(30),
    [calKey] VARCHAR(40)); 

    INSERT INTO '' + @tmpTableName + ''(phoneNumber, calKey) values(''+@fnPhone+'',@calKey );
    '';
    EXEC (@dropTmpPhone);   
    
    EXEC sp_executesql @sqlcmd, N''@telephone nvarchar(40), @calKey VARCHAR(40)'', @telephone,@calKey;
    
END
else if @cleanType<>0 begin
    set @fnPhone=case when @cleanType=0 then ''[dbo].[Limpia](phoneNumber)'' else  ''[dbo].[Verifica](phoneNumber)'' end
    
    set @sqlcmd=''update '' + @tmpTableName + '' set phoneNumber=''+@fnPhone
    
    EXEC (@sqlcmd);

    set @sqlcmd=''
    Insert into ccRIALogPhones 
select @ln_id,@phoneEmpty,phoneNumber,0,@motivo,@keyTranslate 
from ''+ @tmpTableName+''
where left(phoneNumber,1)= ''''E''''
delete from ''+ @tmpTableName+'' where left(phoneNumber,1)= ''''E''''
''
    
    set @params=''@ln_id int, @phoneEmpty nvarchar(1),@motivo nvarchar(100),@keyTranslate nvarchar(100)''
    EXEC sp_executesql @sqlcmd,@params,
    @ln_id=@ln_id
    ,@phoneEmpty=@phoneEmpty,@motivo =@motivo ,@keyTranslate =@keyTranslate 

end

set @sqlcmd=''delete A
FROM '' + @tmpTableName + '' A
left join cclistanegra B with(nolock,index(IX_ccListaNegra_1)) on A.phoneNumber=B.telefono AND (A.calKey = B.calKey OR (A.calKey IS NULL and B.calKey IS NULL ))
where B.telefono is not null''

EXEC (@sqlcmd);   

SET @sqlcmd = ''INSERT INTO cclistanegra(telefono,idtipolista,HashKey, calKey)
SELECT phoneNumber, @ln_id as idtipolista, dbo.hashList(calKey) as HashKey, calkey 
FROM '' + @tmpTableName + '' A 

INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
SELECT phoneNumber as telefono, 7 as idtipomov, @ln_id as idtipolista 
FROM '' + @tmpTableName + '' A '';


EXEC sp_executesql @sqlcmd, N''@ln_id int'', @ln_id;

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall


CREATE TABLE [dbo].[#mycamps] ( [campsid] [int] NULL)

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id and B.CampType not in(7,5)


CREATE TABLE [dbo].[#myprincipaltempCall](
    [callout_id] [bigint] NULL, 
    [cam_id] [int] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL,
    [cal_telefono] [varchar] (30) NULL ,
    [cal_telefono2] [varchar] (30) NULL ,
    [cal_telefono3] [varchar] (30) NULL ,
    [cal_telefono4] [varchar] (30) NULL ,
    [cal_telefono5] [varchar] (30) NULL
    )

CREATE CLUSTERED INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltempCall]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltempCall]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltempCall]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltempCall]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltempCall]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltempCall]([cal_telefono5]) 

CREATE TABLE [dbo].[#helpTempCall](
    [callout_id] [bigint] NULL, 
    [cam_id] [int] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL,
    [cal_telefono] [varchar] (30) NULL ,
    [cal_telefono2] [varchar] (30) NULL ,
    [cal_telefono3] [varchar] (30) NULL ,
    [cal_telefono4] [varchar] (30) NULL ,
    [cal_telefono5] [varchar] (30) NULL
    )

CREATE TABLE [dbo].[#mytempCall](
    [callout_id] [bigint] NULL, 
    [telefono] [varchar] (30) NULL ,
    [cam_id] [smallint] NULL ,
    [tipomov] [int] NULL,
    [idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempCall]([callout_id]) 

declare @fech datetime = getdate()-30
    SET @sqlcmd = ''
    insert into [#helpTempCall]
    SELECT a.callout_id as callout_id, a.cam_id,3, @ln_id as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
    FROM [ccoCallsOutSource] as a with(nolock)
    inner join #mycamps as b  on a.cam_id = b.campsid
    inner join '' + @tmpTableName +'' t on 
    t.phoneNumber IN ([SPACE_TEL])  AND t.calKey IS NULL
    where  cal_fechadial > getdate()-30
    ''

SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono'')   
EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

DECLARE @columnIndex INT = 2;
WHILE @columnIndex <= 5
BEGIN
    SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono''+CONVERT(varchar(10),@columnIndex))
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;
    set @columnIndex=@columnIndex+1;
END

    SET @sqlcmd = ''insert into [#helpTempCall]
    SELECT a.callout_id as callout_id, a.cam_id,3, @ln_id as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
    FROM [ccoCallsOutSource] as a with(nolock)
    inner join #mycamps as b  on a.cam_id = b.campsid
    inner join '' + @tmpTableName +'' t on a.cal_Key=t.calKey
    where cal_fechadial > getdate()-30;
    '';
    
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

    INSERT INTO #myprincipaltempCall
    SELECT * FROM #helpTempCall
    GROUP BY callout_id, cam_id, tipomov, idtipolista, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5

if EXISTS (select * from #myprincipaltempCall)
begin
    declare @column nvarchar(max), @sql nvarchar(max)
    ,@sqlDeleteWorking nvarchar(max)
    ,@sqlUpdateWorking nvarchar(max)
    ,@sqlCaseWorking nvarchar(max)
      
    ,@sqlWithReplace nvarchar(max)
    
    set @column=''cal_telefono''
    set @params=''@phoneEmpty varchar(1),@fech datetime''
    set @sqlDeleteWorking=''and cs.cal_telefono2=@phoneEmpty
    and cs.cal_telefono3=@phoneEmpty
    and cs.cal_telefono4=@phoneEmpty
    and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono2<>@phoneEmpty then cs.cal_telefono2 
    when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
    when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
    when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
    else @phoneEmpty end ''

    set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
    update wt 
    set cal_telefono = CASE_UPDATE_WT
    from ccoCallsOutSource cs 
    inner join ccoWOrkingTable wt on cs.callout_id = wt.callout_id
    inner join #mytempCall t on cs.callout_id = t.callout_id
    where cs.cal_fechadial > @fech and cs.COLUMN_CHECK= wt.cal_telefono''

    set @sql=''
insert #mytempCall
select callout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempCall] as a with(nolock)
inner join '' + @tmpTableName + '' t on
t.phoneNumber = COLUMN_CHECK
where COLUMN_CHECK<>@phoneEmpty


if EXISTS (select * from #mytempCall)
begin       
    -- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
    delete wt with(rowlock)
    from ccoWOrkingTable wt 
    inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
    inner join #mytempCall t on wt.callout_id = t.callout_id
    where cs.cal_fechadial > @fech and
    cs.COLUMN_CHECK = wt.cal_telefono
    AND_DELETE_WT

    UPDATE_SMS_WT_QUERY

    --insertar el historial
    insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
    select * from #mytempCall where [telefono]<>@phoneEmpty

    -- Eliminamos el telefono1 de CS
    update ccoCallsOutSource 
    set COLUMN_CHECK = @phoneEmpty
    from ccoCallsOutSource cs 
    inner join #mytempCall t on cs.callout_id = t.callout_id
    where cs.cal_fechadial > @fech      

    truncate table #mytempCall
end''

    
    /******************/
    /*** Telefono 1 ***/
    /******************/
    
    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    print(@sqlWithReplace)  
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  

    /******************/
    /*** Telefono 2 ***/
    /******************/
    set @column=''cal_telefono2''
    
    set @sqlDeleteWorking='' and cs.cal_telefono3=@phoneEmpty
        and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
        when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  

    /******************/
    /*** Telefono 3 ***/
    /******************/
    set @column=''cal_telefono3''
    
    set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  
    
    /******************/
    /*** Telefono 4 ***/
    /******************/    
    
    set @column=''cal_telefono4''
    
    set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
        and cs.cal_telefono5=@phoneEmpty''
    
    set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
        when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
        else @phoneEmpty end ''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  
    
    /******************/
    /*** Telefono 5 ***/
    /******************/

    set @column=''cal_telefono5''   
    set @sqlDeleteWorking='' and cs.cal_telefono5=@phoneEmpty'' 
    set @sqlCaseWorking=''''

    set @sqlWithReplace=    
    Replace(        
    REPLACE(
    REPLACE(
        REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',''''),
        ''COLUMN_CHECK'',@column)
        ,''AND_DELETE_WT'',@sqlDeleteWorking)
        ,''CASE_UPDATE_WT'',@sqlCaseWorking
        )
    --print(@sqlWithReplace)
    exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech  

end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall
IF @dropTmpPhone IS NOT NULL EXEC (@dropTmpPhone);'
    EXEC(@sql)

    --------------------------------------------- END Luis Miguel Zamora Nuñez  ----------------------------------------


    
--------------------------- Begin LRSV KR154000 ----------------------------------------------------------------------------------

SET @process = 'KR154000 se crea permiso 10043'
SET @sql = '
IF NOT EXISTS (select 1 from ccPermissions where Permissions_Id = 10043)
BEGIN
    insert into ccPermissions values (10043, ''Habilitar/deshabilitar marcación progresiva'', ''RolesPermissionProgressiveDialing'', 0, 0, 0, ''N/A'', 1)
END'
EXEC(@sql);

SET @process = 'KR154000 se crea permiso 10042'
SET @sql = '
IF NOT EXISTS (select 1 from ccPermissions where Permissions_Id = 10042)
BEGIN
    insert into ccPermissions values (10042, ''Marcar en orden ascendente/descendente'', ''RolesPermissionDialingOrder'', 0, 0, 0, ''N/A'', 1)
END'
EXEC(@sql);

SET @process = 'KR154000 se asigna permiso 10043 a root'
SET @sql = '
IF NOT EXISTS (select 1 from ccRoles_Permissions where Rol_Id = 1 AND Permissions_Id = 10043)
BEGIN
    insert into ccRoles_Permissions values (1, 10043)
END'
EXEC(@sql);

SET @process = 'KR154000 se asigna permiso 10042 a root'
SET @sql = '
IF NOT EXISTS (select 1 from ccRoles_Permissions where Rol_Id = 1 AND Permissions_Id = 10042)
BEGIN
    insert into ccRoles_Permissions values (1, 10042)
END'
EXEC(@sql);

--------------------------- END LRSV KR154000 ----------------------------------------------------------------------------------


--------------------------- Begin Ricardo Nuñez Alanis 126.20231211.0.22 ----------------------------------------------------------------------------------
SET @process = 'Create table ccMenuRol'
SET @sql = 'IF OBJECT_ID(''ccMenuRol'', ''U'') IS NOT NULL
BEGIN
    PRINT ''La tabla ccMenuRol ya existe.''
END
ELSE
BEGIN
    CREATE TABLE ccMenuRol (
        Rol_id INT,
        menu_id SMALLINT,
        "type" TINYINT,
        CONSTRAINT fk_rol FOREIGN KEY (Rol_id) REFERENCES ccRoles(Rol_id),
        CONSTRAINT fk_menu FOREIGN KEY (menu_id, "type") REFERENCES ccMenus(menu_id, "type")
    );
    PRINT ''La tabla ccMenuRol ha sido creada exitosamente.''
END;'
EXEC(@sql);

SET @process = 'Insert default data to ccMenuRol manually'
SET @sql = 'IF Exists(select * from ccRoles where Rol_id=1) and  NOT EXISTS (SELECT 1 FROM ccMenuRol where Rol_id=1) begin
    INSERT INTO ccMenuRol (menu_id, type, Rol_id)
    SELECT m.menu_id, m.type, 1 AS Rol_id  -- Root
    FROM ccMenus m
    WHERE m.parent IN (
        2000, 3000, 3140, 4000, 3130, 10000, 11000, 12000, 
        6000, 8000, 8050, 8060, 8080, 7000, 13000, 14000
    )
    AND m.type = 3
    AND m.menu_id NOT IN (2130, 12015, 12017, 8083, 7230, 13030, 1010) -- Excluir estos menu_id
end


IF Exists(select * from ccRoles where rol_id=6) and NOT EXISTS (SELECT 1 FROM ccMenuRol where Rol_id=6) begin
    INSERT INTO ccMenuRol (menu_id, type, Rol_id)
    SELECT menu_id, type, 6 AS Rol_id  -- Supervisor
        FROM ccMenus m
    WHERE m.parent IN (
        2000, 3000, 4000, 3130, 10000, 11000, 12000, 
        6000
    )
    AND m.type = 3
    AND m.menu_id NOT IN (2130, 12015, 12017, 8083, 7230, 13030, 1010) -- Excluir estos menu_id
end

IF Exists(select * from ccRoles where rol_id=8) and NOT EXISTS (SELECT 1 FROM ccMenuRol where Rol_id=8) begin
    INSERT INTO ccMenuRol (menu_id, type, Rol_id)
    SELECT menu_id, type, 8 AS Rol_id  -- Analista de Calidad
    FROM ccMenus m
    WHERE m.parent IN (
        2000, 3000, 4000, 8050
    )
    AND m.type = 3
    AND m.menu_id NOT IN (2130, 12015, 12017, 8083, 7230, 13030, 1010) -- Excluir estos menu_id
end

IF Exists(select * from ccRoles where rol_id=9) and NOT EXISTS (SELECT 1 FROM ccMenuRol where Rol_id=9) begin
    INSERT INTO ccMenuRol (menu_id, type, Rol_id)
    SELECT menu_id, type, 9 AS Rol_id  -- Monitor
    FROM ccMenus m
    WHERE m.parent IN (
        2000, 3000, 4000, 8050
    )
    AND m.type = 3
    AND m.menu_id NOT IN (2130, 12015, 12017, 8083, 7230, 13030, 1010) -- Excluir estos menu_id
end
'
EXEC(@sql);

set @process = 'Delete ccsp_GalateaMenuReporte'
    set @sql='
        if exists (select * from sys.procedures where name = N''ccsp_GalateaMenuReporte'')
    begin
        DROP PROCEDURE ccsp_GalateaMenuReporte;
    end'
    EXEC(@sql)

SET @process = 'Creation of ccsp_GalateaMenuReporte'
SET @sql = '

CREATE PROCEDURE [dbo].[ccsp_GalateaMenuReporte]
    @action SMALLINT,
    @Rol_id VARCHAR(MAX) = NULL,
    @id_User VARCHAR(MAX) = NULL,   
    @menu_id VARCHAR(MAX) = NULL,
    @ids_list VARCHAR(MAX) = NULL,
    @IsAdminsIds BIT = NULL,
    @RowsAffected INT = @@ROWCOUNT
AS

BEGIN
    IF @action = 1
    --Busca el id rol y regresa todos los menu id que tenga relacionados
    BEGIN
        IF @IsAdminsIds = 0
        BEGIN
            SELECT distinct CAST(menu_id as int) as MenuID --0 as RolID, 0 as type
            FROM ccMenuRol
            WHERE (Rol_id IN(Select Value from dbo.fn_RIASplitDelimited(@Rol_id, '','')))
        END
        ELSE
        BEGIN
            SELECT DISTINCT CAST(id_Menu AS INT) as MenuID
            FROM ccMenuUser 
            WHERE (id_User = @id_User) and type = 3 and id_Menu not in (1000, 1010);
        END
    END;

    IF @action = 2
    --Manda la información faltante para que el Front sepa todos los menus
    BEGIN
        SET NOCOUNT ON;
        SELECT CAST(menu_id as int) as MenuID, menu_descrip as MenuDesc, CAST(parent as int) as Parent
        FROM ccMenus 
        WHERE parent IN (
            2000, 3000, 3140, 4000, 3130, 10000, 11000, 12000, 
            6000, 8000, 8050, 8060, 8080, 7000, 13000, 14000
        )
        AND type = 3
        AND menu_id NOT IN (2130, 12015, 12017, 8083, 7230, 13030)
    END;

    IF @action = 3
    --Guarda información ya sea en la tabla ccMenuUser o ccMenuRol
    BEGIN
        IF @IsAdminsIds  = 0
        BEGIN
            SET NOCOUNT ON;
            INSERT INTO ccMenuRol(menu_id, Rol_id, type)
            SELECT DISTINCT t2.Value AS menu_id, t1.Value AS Rol_id, 3 as type
            FROM (SELECT Value FROM dbo.fn_RIASplitDelimited(@ids_list, '','')) t1
            CROSS JOIN 
            (SELECT Value FROM dbo.fn_RIASplitDelimited(@menu_id, '','')) t2
            WHERE NOT EXISTS 
            (SELECT 1 FROM ccMenuRol
            WHERE ccMenuRol.Rol_id = t1.Value
            AND ccMenuRol.menu_id = t2.Value);

            -- Determinar el resultado directamente con @@ROWCOUNT
            SELECT CASE 
                WHEN @@ROWCOUNT > 0 THEN 1 -- Se insertaron filas
                WHEN (LEN(@ids_list) - LEN(REPLACE(@ids_list, '','', ''''))) = 0 THEN -1 -- Solo un id en la lista, pero sin cambios
                ELSE -2 -- Múltiples ids, pero sin cambios
            END AS Result;
        END
        ELSE
        BEGIN
            SET NOCOUNT ON;
            INSERT INTO ccMenuUser(id_Menu, id_User, type)
            SELECT DISTINCT t2.Value AS id_Menu, t1.Value AS id_User, 3 as type
            FROM (SELECT Value FROM dbo.fn_RIASplitDelimited(@ids_list, '','')) t1
            CROSS JOIN 
            (SELECT Value FROM dbo.fn_RIASplitDelimited(@menu_id, '','')) t2
            WHERE NOT EXISTS 
            (SELECT 1 FROM ccMenuUser
            WHERE ccMenuUser.id_User = t1.Value
            AND ccMenuUser.id_Menu = t2.Value);

            -- Determinar el resultado directamente con @@ROWCOUNT
            SELECT CASE 
                WHEN @@ROWCOUNT > 0 THEN 1 -- Se insertaron filas
                WHEN (LEN(@ids_list) - LEN(REPLACE(@ids_list, '','', ''''))) = 0 THEN -1 -- Solo un id en la lista, pero sin cambios
                ELSE -2 -- Múltiples ids, pero sin cambios
            END AS Result;
        END
    END;


IF @action = 4
    --Elimina información ya sea en la tabla ccMenuUser o ccMenuRol
    BEGIN
        IF @IsAdminsIds = 0
        BEGIN
            SET NOCOUNT ON;
            DELETE FROM ccMenuRol
            WHERE EXISTS (
                SELECT 1
                FROM dbo.fn_RIASplitDelimited(@ids_list, '','') t1
                CROSS JOIN dbo.fn_RIASplitDelimited(@menu_id, '','') t2
                WHERE ccMenuRol.Rol_id = t1.Value
                AND ccMenuRol.menu_id = t2.Value
            );

            -- Determinar el resultado directamente con @@ROWCOUNT
            SELECT CASE 
                WHEN @@ROWCOUNT > 0 THEN 1 -- Se eliminaron filas
                WHEN (LEN(@ids_list) - LEN(REPLACE(@ids_list, '','', ''''))) = 0 THEN -1 -- Solo un id en la lista, pero sin cambios
                ELSE -2 -- Múltiples ids, pero sin cambios
            END AS Result;
        END
        ELSE
        BEGIN
            SET NOCOUNT ON;
            DELETE FROM ccMenuUser
            WHERE EXISTS (
                SELECT 1
                FROM dbo.fn_RIASplitDelimited(@ids_list, '','') t1
                CROSS JOIN dbo.fn_RIASplitDelimited(@menu_id, '','') t2
                WHERE ccMenuUser.id_User = t1.Value
                AND ccMenuUser.id_Menu = t2.Value
            );

            -- Determinar el resultado directamente con @@ROWCOUNT
            SELECT CASE 
                WHEN @@ROWCOUNT > 0 THEN 1 -- Se eliminaron filas
                WHEN (LEN(@ids_list) - LEN(REPLACE(@ids_list, '','', ''''))) = 0 THEN -1 -- Solo un id en la lista, pero sin cambios
                ELSE -2 -- Múltiples ids, pero sin cambios
            END AS Result;
        END
    END;
    IF @action = 5
    --Busca el id rol y regresa todos los menu id que tenga relacionados
    BEGIN
        IF @IsAdminsIds = 0
        BEGIN
            SELECT distinct CAST(menu_id as int) as MenuID --0 as RolID, 0 as type
            FROM ccMenuRol
            WHERE (Rol_id IN(Select Value from dbo.fn_RIASplitDelimited(@ids_list, '','')))
        END
        ELSE
        BEGIN
            SELECT DISTINCT CAST(id_Menu AS INT) as MenuID
            FROM ccMenuUser 
            WHERE (id_User = @ids_list) and type = 3 and id_Menu not in (1000, 1010);
        END
    END;
END;
'
EXEC(@sql);
--------------------------- End Ricardo Nuñez Alanis 126.20231211.0.22 ----------------------------------------------------------------------------------





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
