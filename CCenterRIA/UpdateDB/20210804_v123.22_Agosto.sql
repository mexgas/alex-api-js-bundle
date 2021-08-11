/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
Description:

Database: CCenterRia
Required version: 123.14

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
SET @versionfix = 22
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

    set @process = 'Historial Chat- se quita el sp ccsp_RIAABCChat si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAABCChat'')
            begin
          DROP PROCEDURE ccsp_RIAABCChat;
            end'
    EXEC(@sql)

    set @process = 'Historial Chat- se modifica sp ccsp_RIAABCChat'
    set @sql = 'CREATE Procedure [dbo].[ccsp_RIAABCChat]
@OperationType tinyint = 0, -- 0:Select | 1:Insert | 2:Select Excel | 3:DateRange | 4:Admins | 5:Agents | 6:GalateaAdmin
@TipoMsgChat tinyint = null,
@User_id_Adm varchar(8000) = null,
@User_id_Agt varchar(8000) = null,
@ChatMsg varchar(1500) = null,
@Fecha_Chat_ini datetime = null,
@Fecha_Chat_fin datetime = null,
@IDArea int = null,
@IDGroup int = null
AS
set nocount on

declare @new_chat_id int;

if @OperationType not in (0,1,2,3,4,5,6,7,8)
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
    select @new_chat_id = SCOPE_IDENTITY() 

    if(@TipoMsgChat in (4,5) and @new_chat_id is not null)
     begin
        insert ccChatLog_AreaWg(ChatID, IdGroup, TypeGroup)
        select @new_chat_id, @IDGroup, case @TipoMsgChat when 4 then ''Area'' else ''Workgroup'' end
     end

     select @new_chat_id as ChatID
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
    declare @tableArea table (UserId int,AgentLogin varchar(40),areaId int, primary key(userId))
    insert into @tableArea 
    SELECT B.User_id,B.Login, B.IDArea FROM dbo.fn_RIASplitDelimited(@User_id_Agt, '','') A
    inner join ccUsers B on A.Value=B.User_id

    declare @tableWG table (UserId int,AgentLogin varchar(40),WgId varchar(100))
    insert into @tableWG 
    SELECT B.User_id,B.Login, D.IDWG FROM dbo.fn_RIASplitDelimited(@User_id_Agt, '','') A
    inner join ccUsers B on A.Value=B.User_id
    inner join ccRIAWorkGroupUsers D on A.Value=D.User_id

   ;with Chats as(
     select A.TipoMsgChat,t.AgentLogin,A.User_id_Adm,A.ChatMsg,A.Fecha_Chat from ccRIAChat_Log A ,@tableArea t where TipoMsgChat=4
     union
     select  A.TipoMsgChat,t.AgentLogin,A.User_id_Adm,A.ChatMsg,A.Fecha_Chat from ccRIAChat_Log A ,@tableWG t 
     join ccChatLog_AreaWg caw on t.WgId=caw.IdGroup
     where TipoMsgChat=5
     union
     select A.TipoMsgChat,case when TipoMsgChat=3 then (select Login from ccUsers where User_id=@User_id_Agt) else U.Login end as AgentLogin,A.User_id_Adm,A.ChatMsg,A.Fecha_Chat 
     from ccRIAChat_Log A 
     join ccUsers U on A.User_id_Agt=U.User_id
     where TipoMsgChat in (1,2,3) and User_id_Agt in (select case when isnull(@User_id_Agt,''0'')=''0'' then User_id_Agt else value end from dbo.fn_RIASplitDelimited (@User_id_Agt, '',''))
    )

    select convert(varchar(10),Fecha_Chat,108) HourChat,C.TipoMsgChat , u2.Login AdminLogin,
    C.AgentLogin, c.ChatMsg from CHats C
    JOIN ccUsers U2 ON U2.user_id = C.User_id_Adm
    WHERE 
    Fecha_Chat BETWEEN ISNULL(@Fecha_Chat_ini, ''19000101 00:00'')
    AND ISNULL(@Fecha_Chat_fin, DATEADD(hh, 1, getdate()))
    order by Fecha_Chat asc
 end

 if @OperationType=7
  begin
    --This action was created for Galatea''s Admin Chat Log
    select @Fecha_Chat_ini = convert(datetime,convert(varchar(11),getdate()))
    select @Fecha_Chat_fin = GETDATE()
    ;with Chat as (
    select user_id_Agt, max(chatId) as ChatId
    from ccRiaChat_Log
    where Fecha_Chat between @Fecha_Chat_ini and @Fecha_Chat_fin
    group by user_id_Agt)
    select B.ChatID, B.TipoMsgChat, B.User_id_Agt, B.ChatMsg, B.Fecha_Chat, isnull(caw.IdGroup,0) GroupID
    from Chat A
    inner join ccRIAChat_Log B on A.ChatId=B.ChatID
    left join ccChatLog_AreaWg caw on caw.ChatID=B.ChatID 
    where User_id_Adm=@User_id_Adm
    return(0)
  end

 if @OperationType=8
  begin
    SELECT  convert(varchar(10),Fecha_Chat,108) HourChat,C.TipoMsgChat,
    case TipoMsgChat when 4 then ''A''+cast(caw.IdGroup as varchar(10)) 
    when 5 then ''W''+cast(caw.IdGroup as varchar(10)) 
    else cast(c.User_id_Agt as varchar(10)) end as User_id_Agt, 
    cast(C.User_id_Adm as varchar(10)) User_id_Adm,C.ChatMsg
    FROM ccRIAChat_Log C 
    left join ccChatLog_AreaWg caw on c.ChatID=caw.ChatID
    WHERE 
      User_id_Adm in (select case when isnull(@User_id_Adm,''0'')=''0'' then User_id_Adm else value end from dbo.fn_RIASplitDelimited (@User_id_Adm, '',''))
     AND Fecha_Chat BETWEEN ISNULL(@Fecha_Chat_ini, ''19000101 00:00'')
     AND ISNULL(@Fecha_Chat_fin, DATEADD(hh, 1, getdate()))
     return(0)
  end
select 0
set nocount off'
    EXEC(@sql)

	  set @process = 'CW-5566 Obtener IP para monitoreo de agentes'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_AgentLogINOUT'')
            begin
          DROP PROCEDURE ccsp_AgentLogINOUT;
            end'
    EXEC(@sql)

	  set @process = 'CW-5566 Obtener IP para monitoreo de agentes'
    set @sql = '

CREATE PROCEDURE [dbo].[ccsp_AgentLogINOUT] @UserID SMALLINT, @Extension VARCHAR(7) = NULL, @Computer VARCHAR(20) = NULL, @TipoMov TINYINT, -- 0= LogOut,  1=LogIN,	3=Consulta
	@fecha DATETIME = NULL,
	@ipPublica VARCHAR(15) = NULL
AS
SET NOCOUNT ON

IF @fecha IS NULL
	SET @fecha = getdate()

DECLARE @hourlogin VARCHAR(8)
DECLARE @sessionsecs INT
DECLARE @sessiontime VARCHAR(8)
DECLARE @fecha_ini DATETIME

IF @TipoMov = 1
BEGIN
	INSERT ccLogLogIn (User_id, Extension, TipoMov, fecha)
	VALUES (@UserID, @Extension, 1, @fecha)

	INSERT ccLogAgentesDia (User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus, callID)
	VALUES (@UserID, 0, 0, @fecha, 0, 0, 1, 0)

	UPDATE c
	SET User_id = @UserID, publicIp = @ipPublica
	FROM ccPosicion c WITH (INDEX (IX_ccPosicion))
	WHERE Computer = @Computer

	UPDATE c
	SET user_id = 0
	FROM ccPosicion c WITH (INDEX (IX_ccPosicion_2))
	WHERE Computer <> @Computer AND user_id = @UserId

	UPDATE ccUsers
	SET TipoStatusAge_id = 3, LastLoginAttempt = @fecha
	WHERE User_id = @UserID

	IF EXISTS (
			SELECT valor
			FROM ccSettings
			WHERE tipo = ''AGT'' AND STATUS = ''1'' AND setting_id = ''53'' AND valor = 2
			)
	BEGIN
		IF NOT EXISTS (
				SELECT axLic_Desc
				FROM axLicG729_Data
				WHERE axLic_Status = 1 AND pos_id IN (
						SELECT pos_id
						FROM ccPosicion
						WHERE Computer = @Computer OR user_id = @Userid
						)
				)
		BEGIN
			RAISERROR (''Error. Without License'', 18, 1)

			RETURN (0)
		END

		UPDATE axLicG729_Data
		SET axLic_Status = 2
		WHERE axLic_Status = 1 AND pos_id IN (
				SELECT pos_id
				FROM ccPosicion
				WHERE Computer = @Computer OR user_id = @Userid
				)

		SELECT ''0'' CPLic

		RETURN (0)
	END

	RETURN (0)
END

IF @TipoMov = 0
BEGIN
	INSERT ccLogLogIn (User_id, Extension, TipoMov, fecha)
	VALUES (@UserID, @Extension, 0, @fecha)

	UPDATE c
	SET User_id = 0
	FROM ccPosicion c WITH (INDEX (IX_ccPosicion_2))
	WHERE Computer = @Computer OR user_id = @Userid

	UPDATE ccUsers
	SET TipoStatusAge_id = 0
	WHERE User_id = @UserID

	IF EXISTS (
			SELECT valor
			FROM ccSettings
			WHERE tipo = ''AGT'' AND STATUS = ''1'' AND setting_id = 53 AND valor = ''2''
			)
	BEGIN
		UPDATE axLicG729_Data
		SET axLic_Status = 0, pos_id = NULL, fecha_log = NULL
		WHERE pos_id IN (
				SELECT pos_id
				FROM ccPosicion
				WHERE Computer = @Computer OR user_id = @Userid
				)
	END

	RETURN (0)
END

IF @TipoMov = 3
BEGIN
	SELECT @fecha_ini = convert(DATETIME, convert(VARCHAR(11), getdate()))

	SELECT @hourlogin = convert(VARCHAR(8), isnull(min(fecha), getdate()), 114)
	FROM ccLogLogin
	WHERE TipoMov = 1 AND user_id = @UserID AND fecha >= @fecha_ini

	SELECT @sessionsecs = isnull(CASE WHEN sum(convert(INT, DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14))) * (1 - 2 * tipomov)) > 0 THEN sum(convert(INT, DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14))) * (1 - 2 * tipomov)) ELSE sum(convert(INT, DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14))) * (1 - 2 * tipomov)) + convert(INT, DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14))) END, 0)
	FROM ccLogLogin
	WHERE user_id = @UserID AND fecha > dateadd(hh, - 10, getdate())

	SELECT @sessiontime = RIGHT(''0'' + CONVERT(VARCHAR(6), @sessionsecs / 3600), 2) + '':'' + RIGHT(''0'' + CONVERT(VARCHAR(2), (@sessionsecs % 3600) / 60), 2) + '':'' + RIGHT(''0'' + CONVERT(VARCHAR(2), @sessionsecs % 60), 2)

	SELECT ''HourLogin'' = @hourlogin, ''SessionTime'' = @sessiontime, ''SessionSecs'' = @sessionsecs

	RETURN (0)
END
'
    EXEC(@sql)

	
	  set @process = 'CW-5566 Obtener IP para monitoreo de agentes'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminGetAgentCounters'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminGetAgentCounters;
            end'
    EXEC(@sql)

	set @process = 'CW-5566 Obtener IP para monitoreo de agentes '
    set @sql = '
       CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetAgentCounters] @type AS     INT, 
                                                            @sup_id AS   INT = 0, 
                                                            @agent_id AS INT = 0, 
                                                            @WG AS       INT = 0,
                                  @campId AS INT = 0,
                                  @CampType AS SMALLINT = 1
            AS
             SET NOCOUNT ON;
             IF @type = 1
                 BEGIN
                     WITH TableUserAgent(userId)
                          AS (SELECT DISTINCT 
                                   wgAgt.User_id  AS Id --,usr.login 
                              FROM ccriaworkgroupusers wgAdmin
                                   INNER JOIN ccriaworkgroupusers wgAgt ON wgAdmin.IDWG = wgAgt.IDWG
                                   INNER JOIN ccUsers usr ON usr.User_id = wgAgt.User_id
                                                             AND usr.TipoUser_id = 1
                              WHERE wgAdmin.User_id = @sup_id)
                          SELECT CAST(a.User_id AS INT) Id, 
                                 a.login AS Username, 
                                 a.Nombres + '' '' + a.ApellidoPaterno + '' '' + a.ApellidoMaterno AS Name
                          FROM ccusers a(NOLOCK)--, ccGenViewRelsSupsAgent b
                               INNER JOIN TableUserAgent b ON a.User_id = b.userId
                          ORDER BY a.Login ASC;
             END;
             IF @type = 2
                 BEGIN
                     SELECT CAST(u.User_id AS INT) Id,
							Login Username, 
                            Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno Name,
							CASE WHEN p.publicIp is null or p.publicIp = '''' then ''000.000.000.000'' else p.publicIp end IP
                     FROM ccUsers u
					 LEFT JOIN ccPosicion p on p.user_id = @agent_id
                     WHERE u.User_id = @agent_id;
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
                     SELECT CAST(B.User_id AS int) AS Id
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

           IF @type = 4 --Agents IDs by WG
             BEGIN
            SELECT  CAST(wg.User_id AS INT) Id  
            FROM ccRIAWorkGroupUsers wg
            JOIN CCUsers u on u.user_id = wg.user_id AND u.TipoUser_id = 1
            where IDWG = @WG
             END;

           IF @type = 5 --Agents IDs by Campaign
             BEGIN
            SELECT Distinct(CAST(U.User_id AS INT)) Id FROM ccRIACampEspWG camp
            JOIN ccRIAWorkGroupUsers wg ON camp.IDWG = wg.IDWG
            JOIN ccUsers U ON U.User_id = WG.User_id AND U.TipoUser_id = 1
            WHERE IdCampEsp = @campId AND TIPO = @CampType
             END;

            IF @type = 6 -- Get Agent current state
           BEGIN
            WITH UserMaxFecha(User_id,fecha) as(
              SELECT User_id,max(fecha) as fecha from ccLogAgentesDia where fecha>=convert(date,getdate()) group by User_id
            )

            SELECT CASE WHEN CurrentState.currentStatus is null or  CurrentState.currentStatus<0 
                  then 0 else CAST(CurrentState.currentStatus as int) end CurrentState
            from ccUsers u
            left join 
            (
            select A.User_id,B.currentStatus from UserMaxFecha A 
            inner join ccLogAgentesDia  B on A.User_id=B.User_id and A.fecha=B.fecha
            ) CurrentState on u.User_id=CurrentState.User_id
            where u.TipoUser_id=1 and u.User_id = @agent_id
           END

           IF @type = 7 -- Get superuser id''s except root
           BEGIN
            declare @superuserId as int
            set @superuserId = (select Rol_id from ccRoles where Level = 7) -- obtenemos el id del rol superusuario

            select CAST(cr.User_id AS INT) User_id 
            from ccUsers_Roles cr
            where Rol_id = @superuserId
            and cr.User_id not in (1) 
           END

           IF @type = 8 -- Get all Agent''s ID, Login and Full Names related to a workgroup
           BEGIN
            SELECT DISTINCT 
              Convert(INT,wg.User_id) Id,
              us.Login Username,
              us.Nombres + '' '' + us.ApellidoPaterno + '' '' + us.ApellidoMaterno Name
            FROM ccRIAWorkGroupUsers wg
              LEFT JOIN ccUsers us ON wg.User_id = us.User_id
            WHERE wg.IDWG = @WG
              AND us.TipoUser_id = 1
           END

		   IF @type = 9 -- GET AGENT IP
		   BEGIN
				SELECT publicIp FROM ccPosicion where user_id = @agent_id
		   END

		    IF @type = 10 -- GET ONLINE AGENTS IP
		   BEGIN
				SELECT CAST ( user_id AS INT )    AgentId,  publicIp Ip FROM ccPosicion where user_id <> 0
		   END
           SET NOCOUNT ON;'
    EXEC(@sql)

		  set @process = 'CW-5566 Obtener IP para monitoreo de agentes'
    set @sql = 'IF not exists
(
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME = ''publicIp'' AND TABLE_NAME =''ccPosicion''
)
BEGIN
  ALTER TABLE ccPosicion ADD publicIp VARCHAR(15)
END'
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