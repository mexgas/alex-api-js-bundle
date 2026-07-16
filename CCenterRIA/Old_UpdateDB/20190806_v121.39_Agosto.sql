/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

    
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.38

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
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 39
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 38
BEGIN
  BEGIN TRAN

  BEGIN TRY



set @process = 'CW-3265 DROP PROCEDURE ccsp_GalateaLoadCamps Agregar grupos de trabajo a AdminKolob'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaLoadCamps'')
    begin
        DROP PROCEDURE ccsp_GalateaLoadCamps;
    end'

  exec (@sql)

    SET @process = 'CW-3265 Alter ccsp_GalateaAdminLogin Agregar grupos de trabajo al SP de login de Kolob'
    SET @Sql = 'Alter PROCEDURE [dbo].[ccsp_GalateaAdminLogin] @Login       VARCHAR(20) = '''', 
                                            @Password    VARCHAR(40) = '''', 
                                            @PasswordLwC VARCHAR(40) = NULL, 
                                            @IPAddress   VARCHAR(20) = '''', 
                                            @adminId     INT         = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LoginOK BIT, @PswdOK BIT, @User_id SMALLINT, @Nombre VARCHAR(100), 
    @ADMServer VARCHAR(300), @AreaId SMALLINT, @ViewAvrs INT, @changeRecDisposition INT, 
    @PasswordExpired INT, @UsernameMatch BIT, @UserBlocked BIT, @LastPasswordChange DATETIME, 
    @Ext VARCHAR(80), @ViewAgents BIT;
        
  select @LoginOK=0,@PswdOK=0,@PasswordExpired=0,@UserBlocked = 0,@ViewAgents = 0,@UsernameMatch = 1
        
  CREATE TABLE #temp
    (LoginOK              INT, 
        PswdOK               INT, 
        User_id              SMALLINT, 
        Nombre               VARCHAR(100), 
        ADMServer            VARCHAR(300), 
        AreaId               SMALLINT, 
        ViewAvrs             INT, 
        changeRecDisposition INT, 
        LastPasswordchange   INT
    );
    INSERT INTO #temp
    EXEC ccsp_RIAADMChecaLogin 
            @Login, 
            @Password, 
            @PasswordLwC, 
            @adminId;
    SELECT @LoginOK = LoginOK, 
            @PswdOK = PswdOK, 
            @Nombre = Nombre, 
            @ADMServer = ADMServer, 
            @AreaId = AreaId, 
            @ViewAvrs = ViewAvrs, 
            @changeRecDisposition = changeRecDisposition, 
            @PasswordExpired = LastPasswordchange
    FROM #temp;
    IF @LoginOK = 1
        BEGIN
            SELECT @User_id = User_id, 
                    @ViewAgents = viewAgents
            FROM ccUsers
            WHERE Login = @Login;
            DECLARE @LastLoginAttempt DATETIME, @LoginAttempts INT, @MaxAttemptsAllow INT, 
            @TimeBloqued INT, @TimeFromLastAttempt INT;
            SELECT @LastLoginAttempt = LastLoginAttempt, 
                    @LoginAttempts = LoginAttempts, 
                    @LastPasswordChange = LastPasswordChange
            FROM ccUsers
            WHERE User_id = @User_id;
            SELECT @MaxAttemptsAllow = valor
            FROM ccSettings
            WHERE setting_id = 198;
            SELECT @TimeBloqued = valor
            FROM ccSettings
            WHERE setting_id = 197;
            SELECT @TimeFromLastAttempt = DATEDIFF(MINUTE, @LastLoginAttempt, GETDATE());
            IF @LoginAttempts > @MaxAttemptsAllow
                BEGIN
                    SET @LoginAttempts = 0;
                    UPDATE ccUsers
                        SET 
                            LoginAttempts = 0, 
                            LastLoginAttempt = GETDATE()
                    WHERE User_id = @User_id;
            END;
            IF(@LoginAttempts >= @MaxAttemptsAllow
                AND @TimeFromLastAttempt < @TimeBloqued)
                BEGIN
                    SET @UserBlocked = 1;
            END;

            --Checks Username match case sensitive    
            IF CAST(@Login AS VARBINARY(200)) <>
            (
                SELECT CAST(LOGIN AS VARBINARY(200))
                FROM ccUsers
                WHERE User_id = @User_id
            )
                BEGIN
                    SET @UsernameMatch = 0;
            END;

            --Increments attemps if error
            IF @UserBlocked = 0
                AND (@UsernameMatch = 0
                    OR @PswdOK = 0)
                BEGIN
                    UPDATE ccUsers
                        SET 
                            LoginAttempts = @LoginAttempts + 1, 
                            LastLoginAttempt = GETDATE(), 
                            onLine = 0
                    WHERE User_id = @User_id;
            END;

            --Sets to default to try another attempt
            DECLARE @ExpirationTime INT;
            SELECT @ExpirationTime = valor
            FROM ccSettings
            WHERE setting_id = 29;
            SELECT @PasswordExpired = (CASE
                                            WHEN DATEDIFF(DAY, LastPasswordChange, GETDATE()) > @ExpirationTime
                                                AND @ExpirationTime > 0
                                            THEN 1
                                            ELSE 0
                                        END)
            FROM ccUsers;
            IF @UserBlocked = 0
                AND @UsernameMatch = 1
                AND @PswdOK = 1
                AND @PasswordExpired = 0
                BEGIN
                    UPDATE ccUsers
                        SET 
                            LoginAttempts = 0, 
                            LastLoginAttempt = GETDATE(), 
                            onLine = 1
                    WHERE User_id = @User_id;
            END;
            SELECT @Ext = dbo.fn_Ext_X_ip(@IPAddress);
                
      DECLARE @WorkGroup VARCHAR(MAX);
            SELECT @WorkGroup = COALESCE(@WorkGroup + ''|'' + CAST(IDWG AS VARCHAR(MAX)), CAST(IDWG AS VARCHAR(MAX)))
            FROM ccRIAWorkGroupUsers
            WHERE User_id = @User_id;
    END;
    SELECT @LoginOK UserExists, 
            @UserBlocked UserBlocked, 
            @UsernameMatch UsernameMatch, 
            @PswdOK PasswordMatch, 
            CAST(@PasswordExpired AS BIT) PasswordExpired, 
            @User_id UserID, 
            @Nombre Name, 
            @ADMServer ADMServer, 
            @AreaId AreaId, 
            @ViewAvrs ViewAvrs, 
            @changeRecDisposition ChangeRecDisposition, 
            @Ext Ext, 
            @ViewAgents ViewAgents,
      ISNULL(@WorkGroup, 0) WorkGroup;
END;'



  exec (@sql)




  set @process = 'CW-2703 Creacion de la tabla ccCallCost_Ria '
  set @sql = 'if not exists (select * from sys.tables where name = N''ccCallCost_RIA'')
        begin
            CREATE TABLE [dbo].[ccCallCost_RIA](
          [country_id] [smallint] NOT NULL,
          [tipoLlamada_id] [smallint] NULL,
          [cost_per_min] [float] NULL,
          [additional_min] [float] NULL
        ) ON [PRIMARY]
        end'

  exec (@sql)

  set @process = 'CW-2703 Creacion del indice de la tabla ccCallCost_Ria '
  set @sql = 'if not exists (select * from sys.indexes where name = N''PK_ccCallCost'' and object_id = OBJECT_ID(N''ccCallCost_RIA''))
          begin
              CREATE UNIQUE INDEX PK_ccCallCost ON ccCallCost_RIA (country_id,tipoLlamada_id)
          end'

  exec (@sql)

    set @process = 'CW-2703 Llenado de la tabla ccCallCost_RIA'
    set @sql = 'if not exists (select * from ccCallCost_RIA)
begin
  insert into ccCallCost_RIA (country_id,tipoLlamada_id,cost_per_min,additional_min)
  select country_id,tipoLlamada_id,1,1 from cstoTipoLlamada
end'

    exec (@sql)

    set @process = 'CW-3226 update ccListaNegra set Hashtel=null'
    set @sql = 'update ccListaNegra set Hashtel=null where Hashtel is not null'
    exec (@sql)

    set @process = 'cw-3226 Drop index IX_ccListaNegra_I on ccListaNegra'
    set @sql = 'if exists (select * from sys.indexes where name = N''IX_ccListaNegra_I'' and object_id = OBJECT_ID(N''ccListaNegra''))
begin
    Drop index IX_ccListaNegra_I on ccListaNegra
end'
    exec (@sql)

    set @process = 'cw-3226 Drop index IX_ccListaNegra_II on ccListaNegra'
    set @sql = 'if exists (select * from sys.indexes where name = N''IX_ccListaNegra_II'' and object_id = OBJECT_ID(N''ccListaNegra''))
begin
    Drop index IX_ccListaNegra_II on ccListaNegra
end'
    exec (@sql)

    set @process = 'cw-3226 Alter COLUMN ccListaNegra.Hashtel'
    set @sql = 'if exists(select A.name,B.name from sys.columns A inner join  sys.types B on A.system_type_id=B.system_type_id
where A.name = N''Hashtel'' and Object_ID = Object_ID(N''ccListaNegra'') and B.name=''int'') begin
ALTER TABLE ccListaNegra ALTER COLUMN Hashtel bigint
select ''change''
end'
    exec (@sql)

    set @process = 'cw-3226 Alter COLUMN ccListaNegra.HashKey'
    set @sql = 'if exists(select A.name,B.name from sys.columns A inner join  sys.types B on A.system_type_id=B.system_type_id
where A.name = N''HashKey'' and Object_ID = Object_ID(N''ccListaNegra'') and B.name=''int'') begin
ALTER TABLE ccListaNegra ALTER COLUMN HashKey bigint
select ''change''
end'
    exec (@sql)

    set @process = 'cw-3226 CREATE index IX_ccListaNegra_I on ccListaNegra'
    set @sql = 'if not exists (select * from sys.indexes where name = N''IX_ccListaNegra_I'' and object_id = OBJECT_ID(N''ccListaNegra''))
begin
    CREATE index IX_ccListaNegra_I on ccListaNegra(idtipolista, Hashtel)
end
'
    exec (@sql)

    set @process = 'cw-3226 CREATE index IX_ccListaNegra_II on ccListaNegra'
    set @sql = 'if not exists (select * from sys.indexes where name = N''IX_ccListaNegra_II'' and object_id = OBJECT_ID(N''ccListaNegra''))
begin
    CREATE index IX_ccListaNegra_II on ccListaNegra([idtipolista], Hashtel, HashKey)
end'
    exec (@sql)

    set @process = 'cw-3226 Alter dbo.hashPhone '
    set @sql = 'ALTER FUNCTION [dbo].[hashPhone] (@phoneNumber varchar(30)) 
RETURNS bigint AS
BEGIN
  return convert(bigint,@phoneNumber) % 99999999999973
END
'
    exec (@sql)

    set @process = 'cw-3226 Alter dbo.hashList'
    set @sql = '
ALTER FUNCTION [dbo].[hashList] (@calKey varchar(255)) 
RETURNS bigint AS
BEGIN
declare @codigo varchar(max)
declare @hash bigint

set @codigo=''''
set @hash=0
declare @i int,@len int
select @i=1,@len=len(@calKey)
while @i<=@len begin
  select @codigo=@codigo+convert(varchar(max), ASCII(SUBSTRING(@calKey,@i,1)))
  
  if @i%5=0 begin
    set @hash=@hash+cast(@codigo as bigint)
    set @codigo=''''
  end 
  set @i=@i+1
end
if @codigo<>''''
set @hash=@hash+cast(@codigo as bigint)
return @hash % 99999999999973
END'
    exec (@sql)

    set @process = 'CW-3226 Cambia el tipo bigint  @hashCalKey bigint, @hashPhone BIGINT'
  set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIADNCList] @phoneNumber AS VARCHAR(30), @idDNCList AS INTEGER, @tipoMov AS TINYINT, @calKey AS VARCHAR(20) = NULL
AS
DECLARE @hashCalKey bigint, @hashPhone BIGINT

IF @calKey IS NOT NULL
BEGIN
  SELECT @hashCalKey = dbo.hashList(@calKey)
END

IF @tipoMov = 1
BEGIN -- Inserta Lista Negra  
  EXEC ccsp_InsertDNCList @telephone = @phoneNumber, @ln_id = @idDNCList, @hashCalKey = @hashCalKey

  INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
  VALUES (@phoneNumber, 7, @idDNCList)
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
END
'
  exec (@sql)

set @process = 'CW-3226 Cambia el tipo bigint  @hashCalKey bigint, @hashPhone BIGINT'
  set @sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey bigint=null
AS

declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)

insert into cclistanegra(telefono,idtipolista,HashKey) values(@telephone, @ln_id,@hashCalKey)

CREATE TABLE [dbo].[#mycamps] (
  [campsid] [int] NULL
  )

CREATE UNIQUE INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

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

CREATE UNIQUE INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltemp]([callout_id]) 
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

CREATE UNIQUE INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) 

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @tel = dbo.completa(@telephone, @pais, @ld)

declare @Sql nvarchar(max)

if @hashCalKey is not null or @hashCalKey > 0
begin
  set @Sql = ''insert into [#myprincipaltemp] '' +
  ''SELECT callout_id as callout_id, cam_id,''''3'''','' + cast(@ln_id as nvarchar) + '' as idtipolista , [cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5] '' +
  ''FROM [ccoCallsOutSource] a with(nolock) inner join #mycamps b on (a.cam_id = b.campsid) '' +
  ''WHERE dbo.hashList(cal_Key) = '' + cast(@hashCalKey as nvarchar) +
  '' and  cal_fechadial > dateadd(dd,-30,getdate())''
end
else begin
  set @Sql = ''insert into [#myprincipaltemp] '' +
  ''SELECT callout_id as callout_id, cam_id,''''3'''','' + cast(@ln_id as nvarchar) + '' as idtipolista , [cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5] '' +
  ''FROM [ccoCallsOutSource] a with(nolock) inner join #mycamps b on (a.cam_id = b.campsid) '' +
  ''WHERE ('''''' + @tel + '''''' IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) '' +
  ''or right('''''' + @tel + '''''',10) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) '' +
  ''or right('''''' + @tel + '''''',11) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5])) '' +
  ''and  cal_fechadial > dateadd(dd,-30,getdate())''
end

EXEC(@Sql)

if (select count(*) from #myprincipaltemp with(nolock)) > 0
  begin
    /******************/
    /*** Telefono 1 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono = @tel or cal_telefono = right(@tel, 10) or cal_telefono = right(@tel, 11))

    if (select count(*) from #mytemp with(nolock)) > 0
    begin
      -- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable with(rowlock)
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > getdate()-30 
      and cs.cal_telefono = wt.cal_telefono
      and rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
                 + cs.cal_telefono3 + ''         ''
                 + cs.cal_telefono4 + ''         ''
                 + cs.cal_telefono5 + ''         ''),13)) = ''''

      -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
      update ccoWOrkingTable with(rowlock)
      set cal_telefono = rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
                        + cs.cal_telefono3 + ''         ''
                        + cs.cal_telefono4 + ''         ''
                        + cs.cal_telefono5 + ''         ''),13))
      from ccoCallsOutSource cs 
      inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
      inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > getdate()-30 
      and cs.cal_telefono= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono1 de CS
      update ccoCallsOutSource with(rowlock)
      set cal_telefono = ''''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > getdate()-30

      truncate table #mytemp
    end

    /******************/
    /*** Telefono 2 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono2,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono2 = @tel or cal_telefono2 = right(@tel, 10) or cal_telefono2 = right(@tel, 11))

    if (select count(*) from #mytemp with(nolock)) > 0
    begin
      -- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable with(rowlock)
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > getdate()-30 
      and cs.cal_telefono2= wt.cal_telefono 
      and rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
                 + cs.cal_telefono4 + ''         ''
                 + cs.cal_telefono5 + ''         ''),13)) = ''''

      -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
      update ccoWOrkingTable with(rowlock)
      set cal_telefono = rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
                        + cs.cal_telefono4 + ''         ''
                        + cs.cal_telefono5 + ''         ''),13))
      from ccoCallsOutSource cs 
      inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
      inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > getdate()-30 
      and cs.cal_telefono2= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono2 de CS
      update ccoCallsOutSource with(rowlock)
      set cal_telefono2 = ''''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > getdate()-30

      truncate table #mytemp
    end

    /******************/
    /*** Telefono 3 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono3,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono3 = @tel or cal_telefono3 = right(@tel, 10) or cal_telefono3 = right(@tel, 11))

    if (select count(*) from #mytemp with(nolock)) > 0
    begin
      -- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable with(rowlock)
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > getdate()-30
      and cs.cal_telefono3= wt.cal_telefono  
      and  rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
                  + cs.cal_telefono5 + ''         ''),13)) = ''''

      -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
      update ccoWOrkingTable with(rowlock)
      set cal_telefono = rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
                        + cs.cal_telefono5 + ''         ''),13))
      from ccoCallsOutSource cs 
      inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
      inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > getdate()-30
      and cs.cal_telefono3= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono3 de CS
      update ccoCallsOutSource with(rowlock)
      set cal_telefono3 = ''''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > getdate()-30

      truncate table #mytemp
    end

    /******************/
    /*** Telefono 4 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono4,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono4 = @tel or cal_telefono4 = right(@tel, 10) or cal_telefono4 = right(@tel, 11))

    if (select count(*) from #mytemp with(nolock)) > 0
    begin
      -- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable with(rowlock)
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > getdate()-30
      and cs.cal_telefono4= wt.cal_telefono 
      and rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13)) = ''''

      -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
      update ccoWOrkingTable with(rowlock)
      set cal_telefono = rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13))
      from ccoCallsOutSource cs 
      inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
      inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > getdate()-30 
      and cs.cal_telefono4= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono4 de CS
      update ccoCallsOutSource with(rowlock)
      set cal_telefono4 = ''''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > getdate()-30

      truncate table #mytemp
    end

    /******************/
    /*** Telefono 5 ***/
    /******************/
    insert #mytemp
    select callout_id,cal_telefono5,cam_id,tipomov,idtipolista
    from [#myprincipaltemp] with(nolock)
    where (cal_telefono5 = @tel or cal_telefono5 = right(@tel, 10) or cal_telefono5 = right(@tel, 11))

    if (select count(*) from #mytemp with(nolock)) > 0
    begin
      -- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
      delete ccoWOrkingTable with(rowlock)
      from ccoWOrkingTable wt 
      inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
      inner join #mytemp t on wt.callout_id = t.callout_id
      where cs.cal_fechadial > getdate()-30
      and cs.cal_telefono5= wt.cal_telefono

      ---insertar el historial
      insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
      select * from #mytemp

      -- Eliminamos el telefono5 de CS
      update ccoCallsOutSource with(rowlock)
      set cal_telefono5 = ''''
      from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
      where cs.cal_fechadial > getdate()-30
    end
  end

drop table [#myprincipaltemp]
drop table [#mytemp]
drop table [#mycamps]   
'
  exec (@sql) 

    set @process = 'cw-3226 CW Update ccListaNegra Hashtel JOb'
    set @sql = 'USE [msdb]


if exists(select * from msdb.dbo.sysjobs_view where name=N''CW Update ccListaNegra Hashtel'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW Update ccListaNegra Hashtel'', @delete_unused_schedule=1

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Update ccListaNegra Hashtel'', 
    @enabled=1, 
    @notify_level_eventlog=2, 
    @notify_level_email=0, 
    @notify_level_netsend=0, 
    @notify_level_page=0, 
    @delete_level=0, 
    @description=N''No description available.'', 
    @category_name=N''[Uncategorized (Local)]'', 
    @owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp]    Script Date: 05/06/2019 10:12:59 a. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run sp'', 
    @step_id=1, 
    @cmdexec_success_code=0, 
    @on_success_action=1, 
    @on_success_step_id=0, 
    @on_fail_action=2, 
    @on_fail_step_id=0, 
    @retry_attempts=0, 
    @retry_interval=1, 
    @os_run_priority=0, @subsystem=N''TSQL'', 
    @command=N''if exists(select * from ccListaNegra where Hashtel is null) begin
    update top (20000) ccListaNegra set  Hashtel=dbo.hashPhone(telefono) where Hashtel is null
end
else begin 
    EXEC msdb.dbo.sp_delete_job @job_name=N''''CW Update ccListaNegra Hashtel'''', @delete_unused_schedule=1
end'', 
    @database_name=N''CCenterRia'', 
    @flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''CW Update ccListaNegra Hashtel schedule'', 
    @enabled=1, 
    @freq_type=4, 
    @freq_interval=1, 
    @freq_subday_type=4, 
    @freq_subday_interval=5, 
    @freq_relative_interval=0, 
    @freq_recurrence_factor=0, 
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
    exec (@sql)

    ------------------------------------------------- 121.03-9_20190808_1 -------------------------------------


    set @process = 'CW-3195 OLACA WebApi Y Services deshecha si existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaExcelTemplatesABC'')
      begin
        DROP PROCEDURE ccsp_GalateaExcelTemplatesABC;
      end'
    EXEC (@Sql)

    set @process = 'CW-3195 OLACA WebApi Y Services crea'
    set @sql = '
          CREATE procedure [dbo].[ccsp_GalateaExcelTemplatesABC]
          -- @Type = 1:Consulta de plantillas por archivo | 2:Detalle de plantilla por id
          @action tinyint, 
          @userID smallint = null, 
          @camID smallint = null, 
          @filename varchar(100) = null,
          @tempID smallint = null 

          AS
          set nocount on
          if @action not in (1,2) or (isnull(@userID,0)=0 and isnull(@camID,0)=0 and isnull(@filename,'''')='''')
            raiserror(''ERROR. No se ingreso parametro de entrada'', 18, 1)

          Declare @idioma tinyint
          select @idioma=valor from ccsettings where setting_id=27

          if @action=1 -- Catalogo de Templates
           begin
            if not exists(select User_id from ccUsers where TipoUser_id in(2,6) and Status>0 and User_id=@userID)
             begin
              raiserror(''ERROR. invalid user id'', 18, 1)
              return(0)
             end

            select Temp_id as id, Temp_Desc as name from ccTideWater_Templates
            where User_id = @userID
            AND cam_id = @camID
            AND PathFile = @filename


            return(0)
           end

          if @action=2 -- Detalle de plantilla por id
           begin
            if not exists(select Temp_id from ccTideWater_Templates where TempStatus>0 and Temp_id=@tempID)
             begin
              raiserror(''ERROR. invalid template ID'', 18, 1)
              return(0)
             end
           end
          set nocount off
          '
    exec (@sql)
    

  SET @process = 'CW-2611 Alter Function [dbo].[TelAni]'
    
  SET @Sql = 'ALTER Function [dbo].[TelAni](@tel varchar(32), @lista smallint)
RETURNS varchar(32)
AS
BEGIN
declare @cldLocal varchar(10), @pais tinyint, @lon tinyint, @ret as varchar(10)
declare @telResp varchar(32) 
set @telResp = ''''

select  @cldLocal = valor from ccsettings where setting_id = 17
select @pais = valor, @ret = '''' from ccSettings where setting_id = 104

  if @lista = 0 begin
    select @tel = ''''
  end

  if @pais = 1 begin --Empieza Mexico
    select @lon = len(@tel)
    if @lon >= 10 begin
      select TOP 1 @telResp = telani from ccEstadosAni WITH (NOLOCK) where id_anilist = @lista and (
        ( left(right(@tel, 10), 3) = area and len(area) = 3 )
        or
        ( left(right(@tel, 10), 2) = area and len(area) = 2 ))
      AND telani <> ''''
    end
    else begin
      select @telResp = ''''
    end

    return @telResp
  end --Termina Mexico

  if @pais = 2 begin  -- Empieza Argentina
    select @lon = len(@tel)
    if @lon >= 6 and @lon <=13 begin
      select @telResp = telAni from ccEstadosAni where id_anilist = @lista and
        (( @lon = 6 and left(@tel,4) = area and len(area) = 4 )
        or
        ( @lon = 7 and left(@tel,3) = area and len(area) = 3 )
        or
        ( @lon = 8 and left(@tel,2) = area and len(area) = 2 )
        or
        ( @lon = 11 and substring(@tel, 2, 2) = area and len(area) = 2 )
        or
        ( @lon = 11 and substring(@tel, 2, 3) = area and len(area) = 3 )
        or
        ( @lon = 11 and substring(@tel, 2, 4) = area and len(area) = 4 )
        or
        ( @lon = 13 and substring(@tel, 2, 2) = area and len(area) = 2 )
        or
        ( @lon = 13 and substring(@tel, 2, 3) = area and len(area) = 3 )
        or
        ( @lon = 13 and substring(@tel, 2, 4) = area and len(area) = 4 ))
    end
    else begin
      select @telResp = ''''
    end
      return @telResp
  end  --Termina Argentina

  if @pais = 3 begin  --Empieza Colombia
    select @lon = len(@tel)
    if @lon >= 6 and @lon <=13 begin
      select @telResp = telani from ccEstadosAni where id_anilist = @lista and
        (( len(@tel) = 7 and @cldlocal = area )
        or
        ( len(@tel) = 8 and left(@tel,5) = area )
        or
        ( len(@tel) in(10,11) and (left(@tel,1) = ''3'' or substring(@tel,2,1) = ''3'')))
    end
    else begin
      select @telResp = ''''
    end
    return @telResp
  end  --Termina Colombia

  if @pais = 4 begin --Empieza USA
    select @lon = len(@tel)
    if @lon >= 6 and @lon <=15 begin
      if @lon = 7 begin
        set @tel = @cldLocal + @tel
      end
      set @tel = right(@tel, 10)
      select @telResp = telani from ccEstadosAni where area = left(@tel,3) and id_anilist = @lista
    end
    else begin
      select @telResp = ''''
    end
    return @telResp
  end --Termina USA

  if @pais = 5 begin -- Empieza Chile
    select @lon = len(@tel)
    if @lon >= 6 and @lon <=15 begin
      select @telResp = telani from ccEstadosAni where id_anilist = @lista and
      (( len(@tel) = 6 and @cldlocal = area )
      or
      ( len(@tel) = 7 and @cldlocal = area )
      or
      ( len(@tel) = 8 and left(@tel,1) = area )
      or
      ( len(@tel) = 8 and left(@tel,2) = area )
      or
      ( len(@tel) = 9 and left(@tel,2) = area )
      or
      ( len(@tel) = 10 and substring(@tel,3,1) = area and left(@tel,2) = ''09'' ))
    end
    else begin
      select @telResp = ''''
    end
    return @telResp
  end --Termina Chile

  if @pais = 6 begin -- Venezuela
    select @lon = len(@tel)
    if @lon >= 7 and @lon <=11 begin
      select @telResp = telani from ccEstadosAni where id_anilist = @lista and
        (len(@tel) = 7 and left(@tel,3) = area or
        len(@tel) = 11 and substring(@tel,2,3) = area)
    end
    else begin
      select @telResp = ''''
    end

    return @telResp
  end --Termina Venezuela

  if @pais = 7 begin -- Empieza UK
    select @lon = len(@tel)
    if left(@tel,1) = ''0'' begin
      set  @tel = substring(@tel,2,(len(@tel)-1))
    end

    if @lon >= 9 and @lon <=11 begin
      select @telResp = telani from ccEstadosAni where id_anilist = @lista and
      (( len(@tel) = 10 and substring(@tel,1,5) = area )
      or
      ( len(@tel) = 10 and substring(@tel,1,4) = area )
      or
      ( len(@tel) = 10 and substring(@tel,1,3) = area )
      or
      ( len(@tel) = 10 and substring(@tel,1,2) = area )
      or
      ( len(@tel) = 9 and substring(@tel,1,5) = area )
      or
      ( len(@tel) = 9 and substring(@tel,1,4) = area ) )
    end
    else begin
      select @telResp = ''''
    end
    return @telResp
  end --Termina UK

  if @pais = 8 begin --Empieza Arabia Saudita
    select @lon = len(@tel)
    if @lon >= 7 and @lon <=13 begin
      select @telResp = telani from ccEstadosAni where id_anilist = @lista and
        (len(@tel) = 7 and ''0''+@cldlocal + ''-''+ substring(@tel,1,1) + ''00'' = area or
        len(@tel) = 9 and substring(@tel,1,3) + ''00'' = replace(area,''-'','''') or
        len(@tel) = 10 and substring(@tel,1,4) + ''00'' = replace(area,''-'','''') or
        len(@tel) = 11 and substring(@tel,1,4)+ ''0'' = replace(area,''-'','''') or
        len(@tel) = 11 and substring(@tel,1,5) = replace(area,''-'',''''))
    end
    else begin
      select @telResp = ''''
    end

    return @telResp
  end --Termina Arabia Saudita

  if @pais = 9 --Empieza Australia
    begin
      select @lon = len(@tel)
      if @lon >= 8 and @lon <=10
        begin
          select @telResp = telani from ccEstadosAni where id_anilist = @lista
          and (len(@tel) = 8 and @cldLocal + substring(@tel,1,2) = area or
              len(@tel) = 9 and ''0'' + substring(@tel,1,3) = area or
              len(@tel) = 10 and substring(@tel,1,4) = area)
        end
      else
        begin
          select @telResp = ''''
        end

      return @telResp
    end --Termina Australia

  if @pais = 10 begin -- Empieza Brasil
    select @lon = len(@tel)
    if @lon >= 8 and @lon <=15 begin
      select @telResp = telani from ccEstadosAni where id_anilist = @lista and (
        ((@lon       = 8        )                                    and             @cldlocal = area) or
        ((@lon       = 9        ) and substring(@tel, 1, 1) = ''9''    and             @cldlocal = area) or
        ((@lon between 10 and 11)                                    and substring(@tel, 1, 2) = area) or
        ((@lon between 12 and 13) and substring(@tel, 1, 4) = ''9090'' and             @cldlocal = area) or
        ((@lon       = 13       )                                    and substring(@tel, 4, 2) = area) or
        ((@lon between 14 and 15) and substring(@tel, 1, 2) = ''90''   and substring(@tel, 5, 2) = area) or
        ((@lon       = 14       ) and substring(@tel, 1, 1) = ''0''    and substring(@tel, 4, 2) = area))
    end
    else begin
      select @telResp = ''''
    end

    return @telResp
  end -- Termina Brasil

  if @pais = 11 begin --Empieza Guatemala
    if len(@tel) = 8  begin
      select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
    end
    else begin
      select @telResp = ''''
    end

    return @telResp
  end --Termina Guatemala

  if @pais = 12 begin --Empieza Costa Rica
    if len(@tel) = 8  begin
      select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
    end
    else if len(@tel) = 10 begin
      select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 3) = area
    end
    else begin
      if charindex(substring(@tel,1,2),''00,08'') <= 0
        select @telResp = ''''
      else
        select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 2) = area
    end

    return @telResp
  end --Termina Costa Rica

  if @pais = 13 begin --Empieza Salvador
    if len(@tel) = 8  begin
      select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
    end
    else begin
      if charindex(substring(@tel,1,2),''00'') <= 0
        select @telResp = ''''
      else
        select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 2) = area
    end

    return @telResp
  end --Termina Salvador

  if @pais = 14 begin --Empieza Espa?a
    if len(@tel) = 9  begin
      select @telResp = telani from ccEstadosAni where id_anilist = @lista and
      ((substring(@tel, 1, 1) = area) or
      (substring(@tel, 1, 2) = area) or
      (substring(@tel, 1, 3) = area))
    end
    else
      select @telResp = ''''

    return @telResp
  end --Termina Espa?a

  if @pais = 15 begin -- Empieza Peru
    select @lon = len(@tel)
    if @lon >= 6 and @lon <=9 begin
      select @telResp = telani from ccEstadosAni where id_anilist = @lista and
      (( len(@tel) = 6 and @cldlocal = area )
      or
      ( len(@tel) = 7 and @cldlocal = area )
      or
      ( len(@tel) = 9 and left(@tel,1)=''0'' and substring(@tel,2,len(@cldlocal)) = area ))
    end
    else begin
      select @telResp = ''''
    end
    return @telResp
  end --Termina Peru

  if @pais = 16 begin --Empieza Panama
    if len(@tel) = 7  begin
      select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
    end
    else begin
      if charindex(substring(@tel,1,2),''00'') <= 0
        select @telResp = ''''
      else
        select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 2) = area
    end

    return @telResp
  end --Termina Panama

  return @ret
END'

  exec (@sql)
  
  SET @process = 'CW-3155 Drop Function [dbo].[fnGetCallType]'
  SET @Sql = 'IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N''[dbo].[fnGetCallType]'')
                  AND type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
      DROP FUNCTION [dbo].[fnGetCallType]'
  exec (@sql)
  
  SET @process = 'CW-3155 Create Function [dbo].[fnGetCallType]'
  SET @Sql = 'CREATE function [dbo].[fnGetCallType](@tel varchar(32))
    RETURNS tinyint
    AS
    BEGIN
        
      declare @ladatemp smallint, @ldlocal smallint, @serie smallint, @numeracion smallint, @lenght tinyint, @tipo tinyint
      declare @mod varchar(10)

      set @lenght = LEN(@tel)

      select top 1 @tipo=tipollamada_id from cstoTipoLlamada nolock where country_id=1 and tipoLlamada_id in (5,6,7) and (longitud=@lenght or longitud=0) and @tel like prefijo order by tipollamada_id

      if @tipo is not null
      begin
        return @tipo
      end

      select @tipo = 0, @ldlocal = valor from ccSettings with(nolock) where setting_id = 17
        
      if @lenght = 10 - LEN(@ldlocal) begin
        select @tel = convert(varchar(3),@ldlocal) + @tel
      end
        
      select @tel = RIGHT(@tel,10)
      select @ladatemp = left(@tel,2)
        
      if(@ladatemp in (55,56,33,81)) begin
        select @serie = convert(smallint,SUBSTRING(@tel,3,4)), @numeracion = RIGHT(@tel,4)
        select @mod = MODALIDAD from Series nolock where CLD = @ladatemp and SERIE = @serie and @numeracion between [NUMERACION INICIAL] and [NUMERACION FINAL]
      end
      else begin
        select @ladatemp = left(@tel,3)
        select @serie = convert(smallint,SUBSTRING(@tel,4,3)), @numeracion = RIGHT(@tel,4)
        select @mod =MODALIDAD from Series nolock where CLD = @ladatemp and SERIE = @serie and @numeracion between [NUMERACION INICIAL] and [NUMERACION FINAL]
      end
        
      if @mod in (''FIJO'', ''MPP'') begin
        if @ldlocal = @ladatemp begin
          set @tipo = 1
        end
        else begin
          set @tipo = 2
        end
      end
        
      if @mod in (''CPP'') begin
        if @ldlocal = @ladatemp begin
          set @tipo = 3
        end
        else begin
          set @tipo = 4
        end
      end

      return @tipo
    END'
  exec (@sql)
  
  SET @process = 'CW-3155 Alter SP [dbo].[ccsp_OUTGetNewJobs]'
  SET @Sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
    @CAMPID int,
    @test int=0,
    @nAgentsLogin int=1,
    @iZonas int = null
    as
    --set nocount on
    declare @total int
    declare @topCount smallint, @bIsDaylight bit, @revHorario bit
    declare @country_id int, @TipoJobs int
    --declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
    declare @sql varchar(MAX), @Order_Asc_Desc char(4)
    declare @camSurvey int
    select @camSurvey = 0
    DECLARE @iZonasTable TABLE (value int)

    select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

    -- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
    SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
    select @revHorario=valor from ccsettings where setting_id = 112
    -- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
    SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
    SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

    SET DATEFIRST 1
    --Checamos si es horario de verano
    select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

    if @iZonas is null begin

        INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
        select @iZonas=value from @iZonasTable
    --Checamos si la campaña tiene horarios configurados
        if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
        begin
              if @iZonas = 0 begin
                SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                return
              end
        end
        else begin
          if @camSurvey > 0
              begin
                SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                return
              end
        end
    end

    set @sql=''CREATE TABLE #NEW_JOBS
    (callout_id int,
        cam_id int,
        cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
        cal_status tinyint,
        cal_fechaDial datetime,
        user_id int,
        tz int,
    tz2 int,
    tz3 int,
    tz4 int,
    tz5 int,
    list_id int,
    sequence smallint,
    calkey varchar(max)
    )''


    -- 0=Ambas, 1=CallBacks, 2=Nuevas
    select @topCount=valor from ccSettings where setting_id=94

    if isnull(@topCount,0)=0
    select @topCount=case when @nAgentsLogin<3 then 30
        when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
        when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
        when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
        when @nAgentsLogin>=16 then 240 else 20 end

    select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

    declare @isVerano varchar(max)
    set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

    if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
    begin

          select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

          select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
          SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
          +@isVerano+'',''
          +@isVerano+''2,''
          +@isVerano+''3,''
          +@isVerano+''4,''
          +@isVerano+''5,
          W.list_id, isNull(R.sequence,0) as sequence,
          cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
          FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
          left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
          WHERE W.cal_status=1 -- CallBacks
          and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
          and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
          and (
              ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
          or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
              ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
          or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
              ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
          or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
              ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
          or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
              ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
          or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
          )
          and isnull(R.status,2) = 2
          order by prioridad_cb desc, W.cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)

          --select @sql
    end -- TOMA EN CUENTA LOS CALLBACKS

    if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
    begin
          select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

          select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
          SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
          +@isVerano+'',''
          +@isVerano+''2,''
          +@isVerano+''3,''
          +@isVerano+''4,''
          +@isVerano+''5,
          W.list_id, isNull(R.sequence,0) as sequence,
          cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
          FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
          left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
          WHERE W.cal_status=0 -- Nuevas
          and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
          and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
          and (
              ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
          or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
               ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
          or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
               ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
          or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
               ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
          or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
               ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
          or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
          )
          and isnull(R.status,2) = 2
          order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id''

    end -- TOMA EN CUENTA LAS NUEVAS
    ----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
    select @sql=@sql+nchar(13)+ ''SET rowcount 0''
    if @Test=0
        begin
          select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
          WHERE callout_id in(select callout_id from #NEW_JOBS)''
    end

    if @Test = 2
    begin
        select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
        declare @nSQL nvarchar(4000)
        set @nSQL=cast(@sql as nvarchar(4000))
        exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
        return(@total)
    end
    else
    begin
        select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
    user_id, tz, tz2, tz3, tz4, tz5,
    case when tz is null then '''''''' else cal_telefono end as tel,
    case when tz2 is null then '''''''' else cal_telefono end as tel2,
    case when tz3 is null then '''''''' else cal_telefono end as tel3,
    case when tz4 is null then '''''''' else cal_telefono end as tel4,
    case when tz5 is null then '''''''' else cal_telefono end as tel5,
    NULL as dialOrder, list_id, sequence, calkey,
    0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type
    FROM #NEW_JOBS where len(cal_telefono)>0

    ---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
    declare @regval int
    SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
    exec ccsp_RIAGetCampsNvosCB @cam_id=1,@Tipo=2,@user_id =0,@regval=@regval
    ''
    end

    set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
    print (@sql)
    exec(@sql)

    return(0)'
  exec (@sql)
  
  SET @process = 'CW-3155 Alter SP [dbo].[ccsp_OUTGetNewProviderJobs]'
  SET @Sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewProviderJobs]
    @CAMPID as int,
    @test as int=0,
    @nAgentsLogin as int=1
    as
    set nocount on
    declare @topCount smallint, @bIsDaylight bit, @revHorario bit
    declare @country_id int, @TipoJobs int
    declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
    declare @sql varchar(MAX), @Order_Asc_Desc char(4)
    declare @camSurvey int
    DECLARE @iZonasTable TABLE (value int)

    select @camSurvey = 0

    select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

    -- VALIDAMOS EL PAIS Y LADA CONFIGURADA --
    SELECT @country_id =valor FROM ccSettings WHERE setting_id=104
    select @revHorario=valor from ccsettings where setting_id = 112
    -- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
    SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
    SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

    SET DATEFIRST 1
    --Checamos si es horario de verano
    select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
    if @iZonas is null begin

      INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
      select @iZonas=value from @iZonasTable
      --Checamos si la campaña tiene horarios configurados
      if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
        begin
        declare @horaUniversal as datetime
        set @horaUniversal=getutcdate()

        if @iZonas = 0 begin
          SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
          return
        end
        end

      else
      begin
        if @camSurvey > 0
          begin
            SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
            return
          end
      end
    end

    set @sql=''CREATE TABLE #NEW_JOBS
    (callout_id int,
      cam_id int,
      cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
      cal_status tinyint,
      cal_fechaDial datetime,
      user_id int,
      tz int,
    tz2 int,
    tz3 int,
    tz4 int,
    tz5 int,
    tel varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
    tel2 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
    tel3 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
    tel4 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
    tel5 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
    tel_type smallint,
    tel2_type smallint,
    tel3_type smallint,
    tel4_type smallint,
    tel5_type smallint,
    dialOrder varchar(10),
    list_id int,
    sequence smallint,
    calkey varchar(max)
    )''

    -- 0=Ambas, 1=CallBacks, 2=Nuevas
    select @topCount=valor from ccSettings where setting_id=94

    if isnull(@topCount,0)=0
      select @topCount=case when @nAgentsLogin<3 then 30
      when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
      when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
      when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
      when @nAgentsLogin>=16 then 240 else 20 end

    select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

    declare @isVerano varchar(max)
    set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

    if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
      begin
      select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

      select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
      SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
      W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
      W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
      W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
      W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
      W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
      couts.cal_telefono as tel,
      couts.cal_telefono2 as tel2,
      couts.cal_telefono3 as tel3,
      couts.cal_telefono4 as tel4,
      couts.cal_telefono5 as tel5,''
      if @country_id = 1
      begin
        set @sql=@sql+''dbo.fnGetCallType(couts.cal_telefono) tel_type,
        dbo.fnGetCallType(couts.cal_telefono2) tel2_type,
        dbo.fnGetCallType(couts.cal_telefono3) tel3_type,
        dbo.fnGetCallType(couts.cal_telefono4) tel4_type,
        dbo.fnGetCallType(couts.cal_telefono5) tel5_type,
        ''
      end
      else
      begin
        set @sql=@sql+''0 tel_type,0 tel2_type,0 tel3_type,0 tel4_type,0 tel5_type,''
      end
      set @sql=@sql+''
      couts.dial_tels as dialOrder, W.list_id, isnull(R.sequence,0) as sequence,
      couts.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
      FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
      on W.list_id = R.list_id
      left join ccocallsoutsource couts (nolock)
      on W.callout_id = couts.callout_id
      WHERE W.cal_status=1 -- CallBacks
      and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
      and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
      and (
        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
      or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
      or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
      or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
      or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
      or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
      )
      and isnull(R.status,2) = 2
      order by W.prioridad_cb desc, W.cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
      end -- TOMA EN CUENTA LOS CALLBACKS

    if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
      begin
      select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

      select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
      SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
      W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
      W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
      W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
      W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
      W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
      couts.cal_telefono as tel,
      couts.cal_telefono2 as tel2,
      couts.cal_telefono3 as tel3,
      couts.cal_telefono4 as tel4,
      couts.cal_telefono5 as tel5,''
      if @country_id = 1
      begin
        set @sql=@sql+''dbo.fnGetCallType(couts.cal_telefono) tel_type,
        dbo.fnGetCallType(couts.cal_telefono2) tel2_type,
        dbo.fnGetCallType(couts.cal_telefono3) tel3_type,
        dbo.fnGetCallType(couts.cal_telefono4) tel4_type,
        dbo.fnGetCallType(couts.cal_telefono5) tel5_type,
        ''
      end
      else
      begin
        set @sql=@sql+''0 tel_type,0 tel2_type,0 tel3_type,0 tel4_type,0 tel5_type,''
      end
      set @sql=@sql+''
      couts.dial_tels as dialOrder, W.list_id, isNull(R.sequence,0) as sequence,
      couts.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
      FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
      on W.list_id = R.list_id
      left join ccocallsoutsource couts (nolock)
      on W.callout_id = couts.callout_id
      WHERE W.cal_status=0 -- Nuevas
      and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
      and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
      and (
        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
      or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
      or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
      or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
      or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
      or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
      )
      and isnull(R.status,2) = 2
      order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', W.callout_id''

      end -- TOMA EN CUENTA LAS NUEVAS

    ----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
    select @sql=@sql+nchar(13)+ ''SET rowcount 0''
    if @Test=0
      begin
      select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
      WHERE callout_id in(select callout_id from #NEW_JOBS)''
      end

    select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
    user_id, tz, tz2, tz3, tz4, tz5, tel, tel2, tel3, tel4, tel5, dialOrder, list_id, sequence, calkey,
    tel_type, tel2_type, tel3_type, tel4_type, tel5_type
    FROM #NEW_JOBS where len(cal_telefono)>0''

    select @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
    --print @sql
    exec(@sql)
    return(0)'
  exec (@sql)
  
  SET @process = 'CW-3316 Alter SP [dbo].[ccspGalateaGetAgentCounters]'
  SET @Sql = 'ALTER PROCEDURE [dbo].[ccspGalateaGetAgentCounters] @type AS     INT, 
                                                    @sup_id AS   INT = 0, 
                                                    @agent_id AS INT = 0, 
                                                    @WG AS       INT = 0
AS
     SET NOCOUNT ON;
     IF @type = 1
         BEGIN
             WITH TableUserAgent(userId)
                  AS (SELECT DISTINCT 
                             wgAgt.User_id AS userId --,usr.login 
                      FROM ccriaworkgroupusers wgAdmin
                           INNER JOIN ccriaworkgroupusers wgAgt ON wgAdmin.IDWG = wgAgt.IDWG
                           INNER JOIN ccUsers usr ON usr.User_id = wgAgt.User_id
                                                     AND usr.TipoUser_id = 1
                      WHERE wgAdmin.User_id = @sup_id)
                  SELECT a.user_id, 
                         a.login AS UserName, 
                         a.Nombres + '' '' + a.ApellidoPaterno + '' '' + a.ApellidoMaterno AS Name
                  FROM ccusers a(NOLOCK)--, ccGenViewRelsSupsAgent b
                       INNER JOIN TableUserAgent b ON a.User_id = b.userId
                  ORDER BY a.Login ASC;
     END;
     IF @type = 2
         BEGIN
             SELECT Login UserName, 
                    Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno Name
             FROM ccUsers
             WHERE User_id = @agent_id;
     END;
     IF @type = 3 --Agents by supervisor and WG
         BEGIN
             DECLARE @table2 TABLE
             (userId INT
              PRIMARY KEY NOT NULL
             );
             INSERT INTO @table2
                    SELECT DISTINCT 
                           wg.User_id
                    FROM ccRIAWorkGroupUsers wg
                         LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                    WHERE us.TipoUser_id = 1
                          AND wg.IDWG IN
                    (
                        SELECT IDWG
                        FROM ccRIAWorkGroupUsers
                        WHERE User_id = @sup_id
                              AND IDWG <> @WG
                    );
             SELECT CAST(B.User_id AS NVARCHAR(MAX)) AS AgentId
             FROM @table2 A
                  RIGHT JOIN
             (
                 SELECT DISTINCT 
                        wg.User_id
                 FROM ccRIAWorkGroupUsers wg
                      LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                 WHERE wg.IDWG = @WG
                       AND us.TipoUser_id = 1
             ) B ON A.userId = B.User_id
             WHERE A.userId IS NULL;
     END;
     SET NOCOUNT ON;'
    exec (@sql)

    SET @process = 'CW-3316 Alter SP [dbo].[ccsp_GalateaLoadCamps]'
    SET @Sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaLoadCamps] @option    SMALLINT, 
                                              @Sup       SMALLINT     = NULL, 
                                              @TypeCamp  SMALLINT     = NULL, 
                                              @CamId     SMALLINT     = NULL, 
                                              @PinUpdate SMALLINT     = NULL, 
                                              @Wg        SMALLINT     = NULL, 
                                              @WgList    VARCHAR(256) = NULL
AS
     SET NOCOUNT ON;
     DECLARE @AreaId SMALLINT;
     SELECT @AreaId = IDArea
     FROM ccUsers
     WHERE User_id = @Sup;
     IF @option = 1 -- Get Camps
         BEGIN
             IF @TypeCamp = 1 -- Campañas salida por Supervisor
                 SELECT DISTINCT 
                        rel.cam_id, 
                        camps.cam_descripcion, 
                        graph.graphic_id AS Frame,
                        CASE
                            WHEN(ISNULL(pin.Cam_Id, 0)) >= 1
                            THEN 1
                            ELSE 0
                        END AS Pin, 
                        camps.DNCScrub
                 FROM ccSupervisorCam rel
                      LEFT JOIN PinCampaings pin ON rel.user_id = pin.Sup_Id
                                                    AND rel.cam_id = pin.Cam_Id
                      LEFT JOIN ccCamps camps ON camps.cam_id = rel.cam_id
                      LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                 WHERE rel.user_id = @Sup
                       AND rel.tipo = 1
                 ORDER BY camps.cam_descripcion ASC;
             IF @TypeCamp = 2 -- Campañas entrada por Supervisor (ACDs)
                 BEGIN
                     SELECT CAST(inbound.Inbound_id AS INT) AS Cam_id, 
                            inbound.descripcion AS Cam_descripcion, 
                            graph.graphic_id AS Frame, 
                            0
                     FROM ccInbound inbound
                          LEFT JOIN ccRIAinboundGraph graph ON inbound.Inbound_id = graph.Inbound_id
                          LEFT JOIN ccSupervisorCam supCam ON inbound.Inbound_id = supCam.cam_id
                     WHERE supCam.user_id = @Sup
                           AND tipo = 0
                     ORDER BY inbound.descripcion ASC;
             END;
     END;
     IF @option = 2 -- update Pin campaing
         BEGIN
             IF @PinUpdate = 1
                 BEGIN
                     INSERT INTO PinCampaings
                     (Cam_Id, 
                      Sup_Id
                     )
                     VALUES
                     (@CamId, 
                      @Sup
                     );
             END;
                 ELSE
                 IF @PinUpdate = 0
                     BEGIN
                         DELETE FROM PinCampaings
                         WHERE Cam_Id = @CamId
                               AND Sup_Id = @Sup;
                 END;
     END;
     IF @option = 3  --Get campaign info 
         BEGIN
             SELECT DISTINCT 
                    rel.cam_id, 
                    camps.cam_descripcion, 
                    graph.graphic_id AS Frame,
                    CASE
                        WHEN(ISNULL(pin.Cam_Id, 0)) >= 1
                        THEN 1
                        ELSE 0
                    END AS Pin, 
                    camps.DNCScrub
             FROM ccSupervisorCam rel
                  LEFT JOIN PinCampaings pin ON rel.user_id = pin.Sup_Id
                                                AND rel.cam_id = pin.Cam_Id
                  LEFT JOIN ccCamps camps ON camps.cam_id = rel.cam_id
                  LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
             WHERE rel.user_id = @Sup
                   AND rel.cam_id = @CamId
                   AND rel.tipo = @TypeCamp;
     END;
     IF @option = 4 -- Get Campaigns by Supervisor, Wg and type
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
                        WHERE User_id = @Sup
                              AND IDWG <> @WG
                    );
             SELECT CAST(B.IdCampEsp AS INT) AS Cam_id, 
                    CAST(B.Tipo AS INT) AS Type
             FROM @table A
                  RIGHT JOIN
             (
                 SELECT wg.IdCampEsp, 
                        wg.Tipo
                 FROM ccRIACampEspWG wg
                 WHERE wg.IDWG = @WG
             ) B ON A.camId = B.IdCampEsp
                    AND A.campType = B.Tipo
             WHERE A.camId IS NULL
             ORDER BY IdCampEsp;
     END;
     IF @option = 5 -- Get Campaigns by Supervisor, Wgs and type
         BEGIN
             SELECT COUNT(IdCampEsp)
             FROM ccRIACampEspWG
             WHERE IDWG IN
             (
                 SELECT Value
                 FROM dbo.fn_RIASplitDelimited(@WgList, ''|'')
             )
             AND Tipo = 1
             AND IdCampEsp = @CamId;
     END;'
    exec (@sql)
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
