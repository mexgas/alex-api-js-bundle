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

	set @process = 'CW-5594 Alter SP ccsp_AgentGetCalificaciones'
    set @sql = 'ALTER PROCEDURE dbo.ccsp_AgentGetCalificaciones
    @inOut        TINYINT

/**********
0 in, 1 out
**********/

,   @cam_id       INT
,   @isXml        BIT    =1
AS
    SET NOCOUNT ON
    DECLARE @sql NVARCHAR(MAX)

    IF @inOut = 0
    BEGIN
        IF EXISTS
               (
                  SELECT calif.calif_id
                  FROM ccTipoCalif AS calif
                  JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
                  LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 1
                  LEFT JOIN ccTipoCalifSub AS sb ON rel.califsub_id = sb.califsub_id
                  WHERE cam_id = @cam_id AND tipo = @inOut
               )
        BEGIN
           DECLARE @relationCamId INT
           SELECT @relationCamId=cam_id
           FROM ccInbound
           WHERE Inbound_id = @cam_id
           IF @relationCamId IS NULL
           SET @relationCamId=0

           SET @sql=
           '';WITH disposition
    AS (SELECT DISTINCT
             1 AS tag,NULL AS parent,calif.calif_id AS "selection!1!id",calif.Description AS "selection!1!string",calif.
             orden AS "selection!1!califorden",ISNULL(calif.EndConversation,0) AS "selection!1!endConversation",NULL AS
             "subSelection!2!id",NULL AS "subSelection!2!string",NULL AS "subSelection!2!orden",NULL AS
             "subSelection!2!endConversation",ISNULL(calif.CanReprogram,0) AS "selection!1!canReprogram",NULL AS
             "subSelection!2!canReprogram"
        FROM ccTipoCalif AS calif
        INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id AND camp.cam_id = @cam_id AND camp.tipo = @inOut
        LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 1
        LEFT JOIN ccTipoCalifSub AS sb ON rel.califsub_id = sb.califsub_id
        WHERE calif.CanReprogram = 0 OR calif.CanReprogram = 1 AND @relationCamId > 0
        UNION
        SELECT DISTINCT
             2 AS tag,1 AS parent,calif.calif_id AS "selection!1!id",NULL AS "selection!1!string",calif.orden AS
             "selection!1!califorden",ISNULL(calif.EndConversation,0) AS "selection!1!endConversation",sb.califsub_id AS
             "subSelection!2!id",sb.califSubDesc AS "subSelection!2!string",CAST(sb.orden AS INT) AS
             "subSelection!2!orden",ISNULL(sb.EndConversation,0) AS "subSelection!2!endConversation",NULL AS
             "selection!1!canReprogram",ISNULL(sb.CanReprogram,0) AS "subSelection!2!canReprogram"
        FROM ccTipoCalif AS calif
        INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id AND camp.cam_id = @cam_id AND camp.tipo = @inOut
        LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 1
        LEFT JOIN ccTipoCalifSub AS sb ON rel.califsub_id = sb.califsub_id
        WHERE sb.califsub_id IS NOT NULL AND (sb.CanReprogram = 0 OR sb.CanReprogram = 1 AND @relationCamId > 0))
''

           IF @isXml = 1
           BEGIN
              SET @sql=@sql +
              ''select * from disposition
               order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden" for xml explicit, type''           
           END
           ELSE
           BEGIN
              SET @sql=@sql +
''select 
tag as Tag, isnull(parent,0) as Parent, "selection!1!id" as Id,isnull("selection!1!string",'''''''') as Description,
"selection!1!califorden" as Orden, 
"selection!1!endConversation" EndConversation, isnull("subSelection!2!id",0) as SubId,
isnull("subSelection!2!string",'''''''') as SubDescription, 
isnull("subSelection!2!orden",0) as SubOrden,   
--CAST(  ROW_NUMBER() OVER(PARTITION BY parent ORDER BY "subSelection!2!orden" ASC) as tinyint) AS SubOrden,
isnull("subSelection!2!endConversation",0) as SubEndConversation, 
isnull("selection!1!canReprogram",0) as CanReprogram,isnull("subSelection!2!canReprogram",0) as SubCanReprogram
FROM disposition''
           END
--         PRINT @sql


           EXEC sp_executesql
             @sql
            ,N''@cam_id int, @InOut tinyint,@relationCamId int''
            ,@cam_id
            ,@inOut
            ,@relationCamId
        END
        RETURN 0
    END
    ELSE
    IF @inOut = 1
    BEGIN
        IF EXISTS
               (
                  SELECT calif.calif_id
                  FROM ccTipoCalifOUT AS calif
                  JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
                  LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 0
                  LEFT JOIN ccTipoCalifSubOUT AS sb ON rel.califsub_id = sb.califsub_id
                  WHERE cam_id = @cam_id AND tipo = @inOut
               )
        BEGIN
           SET @sql=
       '';WITH disposition
AS (SELECT DISTINCT
       1 AS tag,NULL AS parent,calif.calif_id AS "selection!1!id",calif.Description AS "selection!1!string",calif.
       keepDial AS "selection!1!keepOnDial",calif.orden AS "selection!1!califorden",ISNULL(calif.finishPreview,0)
       AS "selection!1!finishPreview",NULL AS "subSelection!2!id",NULL AS "subSelection!2!string",NULL AS
       "subSelection!2!keepOnDial",NULL AS "subSelection!2!orden",ISNULL(calif.CanReprogram,0) AS
       "selection!1!canReprogram",NULL AS "subSelection!2!canReprogram"
    FROM ccTipoCalifOUT AS calif
    INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
    LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 0
    LEFT JOIN ccTipoCalifSubOUT AS sb ON rel.califsub_id = sb.califsub_id
    WHERE cam_id = @cam_id AND tipo = @inOut
    UNION
    SELECT DISTINCT
       2 AS tag,1 AS parent,calif.calif_id AS "selection!1!id",NULL AS "selection!1!string",NULL AS
       "selection!1!keepOnDial",calif.orden AS "selection!1!califorden",ISNULL(calif.finishPreview,0) AS
       "selection!1!finishPreview",sb.califsub_id AS "subSelection!2!id",sb.califSubDesc AS "subSelection!2!string",
       sb.keepDial AS "subSelection!2!keepOnDial",CAST(sb.orden AS INT) AS "subSelection!2!orden",NULL AS
       "selection!1!canReprogram",ISNULL(sb.CanReprogram,0) AS "subSelection!2!canReprogram"
    FROM ccTipoCalifOUT AS calif
    INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
    LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 0
    LEFT JOIN ccTipoCalifSubOUT AS sb ON rel.califsub_id = sb.califsub_id
    WHERE cam_id = @cam_id AND tipo = @inOut AND sb.califsub_id IS NOT NULL)
''
           IF @isXml = 1
           BEGIN
              SET @sql=@sql +
              ''select * from disposition
               order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden" for xml explicit, type''
           END
           ELSE
           BEGIN
              SET @sql=@sql +
''SELECT tag AS Tag,ISNULL(parent,0) AS Parent,"selection!1!id" AS Id,ISNULL("selection!1!string",'''''''') AS Description,
    ISNULL("selection!1!keepOnDial",'''''''') AS KeepOnDial,
    --"selection!1!califorden" AS Orden,
    CAST(  ROW_NUMBER() OVER(ORDER BY "selection!1!califorden" ASC) as tinyint) AS Orden,
    "selection!1!finishPreview" AS
    FinishPreview,ISNULL("subSelection!2!id",0) AS SubId,ISNULL("subSelection!2!string",'''''''') AS SubDescription
    ,ISNULL("subSelection!2!keepOnDial",0) AS SubKeepOnDial,
    ISNULL("subSelection!2!orden",0) AS SubOrden,    
    ISNULL("selection!1!canReprogram",0) AS CanReprogram,ISNULL("subSelection!2!canReprogram",0) AS SubCanReprogram
    FROM disposition''
           END
           --PRINT @sql

           EXEC sp_executesql
             @sql
            ,N''@cam_id int, @InOut tinyint''
            ,@cam_id
            ,@inOut
        END
        RETURN 0
    END
    ELSE
    IF @inOut = 10
    BEGIN
        SELECT DISTINCT
             S.califSub_id,S.califSubDesc,orden
        FROM cctipoSubCalifRel AS R
        JOIN cctipoCalifSub AS S ON R.califSub_id = S.califSub_id
        WHERE R.tipoSubRel = 1 AND S.califSub_Status = 1 AND R.calif_id = @cam_id
        ORDER BY S.orden,S.califSubDesc
        RETURN 0
    END
    ELSE
    IF @inOut = 11
    BEGIN
        SELECT DISTINCT
             S.califSub_id,S.califSubDesc,orden
        FROM cctipoSubCalifRel AS R
        JOIN cctipoCalifSubOut AS S ON R.califSub_id = S.califSub_id
        WHERE R.tipoSubRel = 0 AND S.califSubOut_Status = 1 AND R.calif_id = @cam_id
        ORDER BY S.orden,S.califSubDesc
        RETURN 0
    END

    SET NOCOUNT OFF'
    EXEC(@sql)

    set @process = 'CW-5594 Alter ccsp_BaseXmngr'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option tinyint = 0,
@ids varchar(max)=null,
@name varchar(25) = NULL,
@top int = 0,
@dateIni datetime =null,
@dateEnd datetime =null,
@dateStart dateTime= null,
@userId int = 0
AS

declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
declare @parameterDefinition nvarchar(max)
declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
declare @status tinyint
set @sql = ''''


if @action in (1,2,6,7) begin
    if @option = 1 begin
        set @tableName=''ccChatsNode''
        set @columnId=''chatId''
        set @tableNameHistory = ''ccChatsNodeHistory''
    end
    else if @option = 3 begin
        set @tableName=''ccEmailNode''
        set @columnId=''emailId''
        set @tableNameHistory = ''ccEmailNodeHistory''
        end
    else if @option = 4 begin
        set @tableName=''ccTwitterNode''
        set @columnId=''conversationTwitterId''
        set @tableNameHistory = ''ccTwitterNodeHistory''
    end
end



if @action in (1,6) begin --obtiene los nodos a insertar en BX
    if @action = 1 set @status =0
    else if @action = 6 set @status = 2

    if @option in (1,3,4) begin

    declare @auxTag nvarchar(4)
    
    select @auxTag =case when @option = 1 then ''@C09'' when @option in (3,4) then ''@C02'' end
    set @parameterDefinition =N''@status int, @top int,@option int''
    set @sql=''declare @basexName varchar(max)
select @basexName=Xname from ccBaseXDB where serviceId=@option and isFull=0;
    with node ( ''+@columnId+ '',xmlString,dateNode)
    AS(
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableName + '' A with(rowlock)
        where A.status =@status
        union
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableNameHistory + '' A with(rowlock)
        where A.status =@status  
    )

    select node.''+@columnId+ '',node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
    left join ccBaseXDB baseX on baseX.serviceId= @option and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
    order by baseX.Xname''

    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top,@option=@option
    end
end
else if @action in (2,7) begin--actualiza los nodos insertados en BX
    if @action = 2 set @status =0
    else if @action = 7 set @status = 2

    set @parameterDefinition =N''@status int''

    set @sql = ''update ''+@tableName+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    select @tableName,@columnId,@ids,@sql
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
    set @sql = ''update ''+@tableNameHistory+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status

end
else if @action = 3 --trae el nombre de la base de datos en BX
begin
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
    insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option,@dateStart, @name,0)
end
else if @action = 5 begin --obtener servicios disponibles
    select @chat= 0,@rec= 2,@email= 0,@twitter=0
    select @chat = case when valor >= 1 then 1 else 0 end from ccSettings where setting_id = 145
    select @email = case when valor = 1 then 3 else 0 end from ccSettings where setting_id = 155
    select @twitter = case when valor = 1 then 4 else 0 end from ccSettings where setting_id = 173
    select id, ref  from ccFinderServices where id in (@chat, @rec, @email,@twitter)    
end
else if @action = 8 begin--trae la lista de las bases para la busqueda
    select Xname from ccBaseXDB where serviceId = @option
    and (

    @dateIni between dateStart and dateEnd
    or @dateEnd between dateStart and dateEnd
    or dateStart between @dateIni and @dateEnd
    )
    union
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
    and (
        dateStart between @dateIni and @dateEnd
        or @dateIni>=dateStart

    )
end
else if @action = 9 begin--Cierra la base datos
       update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()), dateStart=isnull(@dateStart,dateStart) where serviceId= @option and  isfull = 0 and dateEnd is null
       and Xname=@name
end

else if @action = 10 begin
    declare @filterWg varchar(max)
    declare @len int
    set @filterWg=''''
         
        select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId
         
        set @len=len(@filterWg)- CHARINDEX(''ro )'', REVERSE(@filterWg))
        select SUBSTRING(@filterWg,0, @len)
end


else if @action = 11 begin--trae el nombre de la base de datos en BX

    if @option =1 begin
    SELECT isnull(ISNULL(min(node.value(''(/R01/@CDATE)[1]'',''datetime'')),min(node.value(''(/R01/@C09)[1]'',''datetime''))),GETDATE()) as node FROM ccChatsNode where status = 0
    end
    if @option =3 begin
    SELECT isnull(ISNULL(min(node.value(''(/R03/@CDATE)[1]'',''datetime'')),min(node.value(''(/R03/@C02)[1]'',''datetime''))),GETDATE()) as node FROM ccEmailNode where status = 0
    end
    if @option =4  begin
    SELECT isnull(ISNULL(min(node.value(''(/R04/@CDATE)[1]'',''datetime'')),min(node.value(''(/R04/@C02)[1]'',''datetime''))),GETDATE()) as node FROM ccTwitterNode where status = 0
    end

end'
    EXEC(@sql)	

    set @process = 'CW-5594 Alter ccsp_RIAChecaLogin'
    set @sql = 'ALTER PROCEDURE dbo.ccsp_RIAChecaLogin
    @login             VARCHAR(40)
,   @password          VARCHAR(40)
,   @computer          VARCHAR(20)
,   @passwordLwC       VARCHAR(40)=NULL
AS
    DECLARE @loginOK TINYINT,@pswdOK TINYINT,@compuOK TINYINT,@extenOK TINYINT,@teclaOK TINYINT,@xferAgents TINYINT

    DECLARE @nombre VARCHAR(60),@extension VARCHAR(15),@userID SMALLINT,@cCServer VARCHAR(20),@dialingMode INT

    DECLARE @passwordDb VARCHAR(33)

    DECLARE @crmxActive TINYINT

    DECLARE @passSecure INT

/*************************
Para posiciones ip, by ODC
*************************/

    DECLARE @ext_id INT,@pos_id INT,@isIP BIT,@ipExtension VARCHAR(15)

    DECLARE @tipoConexion SMALLINT

/***************************************************************
 Para live connected Tipo de conexion: 0 normal, 1 liveconnected
***************************************************************/

    SELECT @loginOK=0,@pswdOK=0,@compuOK=0,@extenOK=0,@teclaOK=0,@xferAgents=0,@extension='' '',@userID=0,@nombre='' '',
    @tipoConexion=0,@ipExtension='''',@isIP=0,@cCServer=''127.0.0.1'',@dialingMode=0,@crmxActive=0,@passSecure=0

    SELECT @userID=User_id,@passwordDb=Password
    FROM ccUsers WITH(NOLOCK)
    WHERE Login = @login AND STATUS > 0 AND tipoUser_id = 1

    IF @userID > 0
    SET @loginOK=1

    IF @loginOK = 1 AND (@passwordDb = @password OR @passwordDb = dbo.md5(@password) OR dbo.md5(@passwordDb) = @password OR
    @passwordDb = @passwordLwC OR @passwordDb = dbo.md5(@passwordLwC) OR dbo.md5(@passwordDb) = @passwordLwC)
    SET @pswdOK=1

    IF @pswdOK = 1 AND NOT EXISTS
                            (
                               SELECT Computer
                               FROM ccPosicion WITH(NOLOCK)
                               WHERE STATUS = ''1'' AND Computer = @computer
                            )
    INSERT INTO ccposicion(computer,ext_id,user_id,IP)
    VALUES(@computer,0,@userID,@computer)

    SET @compuOK=1

    IF @pswdOK = 1
    BEGIN

        IF EXISTS
               (
                  SELECT Computer
                  FROM ccPosicion AS P
                  JOIN ccMonitorExt AS M ON P.ext_id = M.ext_id
                  WHERE p.STATUS = ''1'' AND M.STATUS = ''1'' AND Computer = @computer
               )
        SET @extenOK=1

        SELECT @extension=Extension,@ext_id=p.ext_id,@pos_id=p.pos_id,@tipoConexion=p.tipoConexion,@isIP=isIP
        FROM ccPosicion AS P
        INNER JOIN ccMonitorExt AS M ON P.ext_id = M.ext_id
        WHERE Computer = @computer

        SELECT @teclaOK=COUNT(*)
        FROM ccTeclaExtensionPuerto AS T
        INNER JOIN ccMonitorExt AS M ON T.ext_id = M.ext_id
        WHERE M.Extension = @extension

        SELECT @nombre=Nombres + '' '' + ISNULL(ApellidoPaterno,'''') + '' '' + ISNULL(ApellidoMaterno,''''),@xferAgents=XferAgents,
        @dialingMode=DialingMode
        FROM ccUsers
        WHERE User_id = @userID

/******************************************************************************************
Para posiciones ip, by ODC
 No verifica ccTeclaExtensionPuerto, @TeclaOK =1
 Regresa un extension ''virtual''.  Debe ser diferente a cualquiera de ccMonitorExt.Extension
******************************************************************************************/

        IF @ext_id = 0
        BEGIN
           SELECT @teclaOK=1,@extension=CAST(@pos_id * -1 AS VARCHAR(15))
        END

/*****************************************************************************************
-Por OAYC IPExtension, extension, para cuando es posición IP con alguna extension asignada
*****************************************************************************************/

        ELSE
        IF @ext_id > 0 AND @isIP = 1
        BEGIN
           SELECT @teclaOK=1,@ipExtension=@extension,@extension=CAST(@pos_id * -1 AS VARCHAR(15))
        END

        IF @tipoConexion = 1
        SET @teclaOK=1

        SELECT @cCServer=valor
        FROM ccSettings
        WHERE setting_id = 7

        SELECT @crmxActive=valor
        FROM ccsettings
        WHERE setting_id = 168

        SELECT @passSecure=valor
        FROM ccSettings
        WHERE setting_id = 207

    END

    SELECT @loginOK AS LoginOK,@pswdOK AS PswdOK,@compuOK AS CompuOK,@extenOK AS ExtenOK,@extension AS Extension,@userID AS
    UserID,@nombre AS Nombre,@cCServer AS CCServer,@teclaOK AS TeclaOK,@tipoConexion AS TipoConexion,@ipExtension AS
    ipExtension,@xferAgents AS XferAgents,@crmxActive AS CRMx,@passSecure AS passSecure,@dialingMode AS dialingMode'
    EXEC(@sql)

    set @process = 'Se actualiza valor default del setting 226'
    set @sql = 'update ccsettings set valor=60000 where setting_id=''226'''
    EXEC(@sql)    
	
	set @process = 'CW-WhatsApp crea SP tabla conversaciones whatsapp'
    set @sql = 'IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[ccWhatsAppConversations]'') AND type in (N''U''))
BEGIN
CREATE TABLE [dbo].[ccWhatsAppConversations](
	[conversationId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[inboundId] [smallint] NOT NULL,
	[phoneACD] [varchar](50) NOT NULL,
	[clientId] [varchar](25) NOT NULL,
	[conversationStatus] [smallint] NOT NULL,
	[tChatting] [int] NOT NULL,
	[tConversation] [int] NULL,
	[tWrapUp] [smallint] NOT NULL,
	[requestDate] [datetime] NOT NULL,
	[finishedBy] [tinyint] NULL,
	[onQueue] [bit] NULL,
	[tQueue] [smallint] NOT NULL,
	[tTimeout] [int] NOT NULL,
	[disposition] [smallint] NOT NULL,
	[subDisposition] [smallint] NOT NULL,
	[conversationDate] [datetime] NULL,
	[clientName] [varchar](100) NULL,
	[firstMessageTime] [datetime] NULL,
 CONSTRAINT [pk_ccWhatsAppMessages_1] PRIMARY KEY CLUSTERED 
(
	[conversationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[DF_ccWhatsAppConversations_requestDate]'') AND type = ''D'')
BEGIN
ALTER TABLE [dbo].[ccWhatsAppConversations] ADD  CONSTRAINT [DF_ccWhatsAppConversations_requestDate]  DEFAULT (getdate()) FOR [requestDate]
END

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[DF_ccWhatsAppConversations_conversationDate]'') AND type = ''D'')
BEGIN
ALTER TABLE [dbo].[ccWhatsAppConversations] ADD  CONSTRAINT [DF_ccWhatsAppConversations_conversationDate]  DEFAULT (getdate()) FOR [conversationDate]
END

'
 EXEC(@sql)


	set @process = 'CW-WhatsApp valida y si existe SP´para guardar calificaciones whatsapp'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_SaveDispositionsMultimedia'')
            begin
          DROP PROCEDURE ccsp_SaveDispositionsMultimedia;
            end'
    EXEC(@sql)

	set @process = 'CW-WhatsApp crea SP ccsp_SaveDispositionsMultimedia'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_SaveDispositionsMultimedia]

	@action int,
	@conversationId int=0,
	@disposition smallint=0,
	@subDisposition smallint=0,
	@tWrapUp smallint=0,
	@mediaType smallint=0

AS
BEGIN
	
SET NOCOUNT ON;
	
	IF @action = 1 BEGIN --Califica la conversación y pone el tiempo Notas
		DECLARE @Temp NVARCHAR(1000)= N''UPDATE '' + (SELECT CASE @mediaType
						WHEN 5 THEN ''ccWhatsAppConversations''
						WHEN 6 THEN ''chat''
						ELSE ''''
					END AS MediaTypeString) + 
					'' SET disposition= @disposition ,subDisposition= @subDisposition ,tWrapUp= @tWrapUp WHERE conversationId= @conversationId;'' 
		EXEC sp_executesql @temp, N''@disposition SMALLINT, @subDisposition SMALLINT, @tWrapUp SMALLINT, @conversationId INT'', @disposition, @subDisposition, @tWrapUp, @conversationId;
	END
END'
	
	EXEC(@sql)
	
	
	set @process = 'CW-WhatsApp valida y si existe SP MultimediaCommon'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_MultimediaCommon'')
            begin
          DROP PROCEDURE ccsp_MultimediaCommon;
            end'
    EXEC(@sql)

	set @process = 'CW-WhatsApp crea SP ccsp_MultimediaCommon '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_MultimediaCommon] 
@Option AS SMALLINT, 
@inboundId AS SMALLINT = 0, 
@conversationId AS INT = 0, 
@ServiceType AS SMALLINT = 0,
@status as SMALLINT =0
AS
BEGIN
    SET NOCOUNT ON;

    IF(@Option = 1)
		BEGIN

			 SELECT --inbound.chat AS ServiceType,
			   CAST(inbound.Inbound_id AS INT) AS ACDId,
			   inbound.descripcion AS ACDName,
			   ISNULL(configuration.conexionInfo, '''') AS PhoneACD,
			   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
			   inbound.tNotas AS WrapUpTime

			   FROM  ccInbound inbound
			   INNER JOIN  contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId
		END      

	IF(@Option = 2)
		BEGIN
			SELECT 
				cast(i.chat as int) AS ServiceType,
				cast(c.conversationId as int) as ConversationID,
				c.clientId as ClientId,
				cm.conexionInfo as [To],
				cast(i.Inbound_id as int) as ACDId,
				i.descripcion as ACDName,
				cast(g.graphic_id as int) as ACDGraphicId,
				cast(cm.closeConversationTime as int) as [TimeOut],
				cast(cm.answerTimeOut as int) as [TimeOutWarning],
				i.tNotas as [WrapUpTime]
			FROM  ccInbound i
				INNER JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId
				INNER JOIN ccWhatsAppConversations c ON (c.inboundId = i.Inbound_id and c.conversationId = @conversationId)
				INNER JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
			WHERE i.chat = @ServiceType and i.Inbound_id = @inboundId
		END
	IF(@Option = 3)
		BEGIN
			 SELECT 
			   CAST(inbound.Inbound_id AS INT) AS ACDId,
			   inbound.descripcion AS ACDName,
			   ISNULL(configuration.conexionInfo, '''') AS PhoneACD,
			   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
			   inbound.tNotas AS WrapUpTime

			   FROM  ccInbound inbound
			   INNER JOIN  contactMeanIn configuration ON (inbound.Inbound_id = configuration.inboundId and inbound.Inbound_id = @inboundId)
		END   	
END'
	
	EXEC(@sql)
	
	set @process = 'CW-WhatsApp valida y si existe SP ccsp_ConversationWASave'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ConversationWASave'')
            begin
          DROP PROCEDURE ccsp_ConversationWASave;
            end'
    EXEC(@sql)

	set @process = 'CW-WhatsApp crea SP ccsp_ConversationWASave '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_ConversationWASave]

	@action int,
	@conversationId int=0,
	@inboundId smallint=null,
	@phoneACD varchar(50)= null,
	@clientId varchar(25)= null,
	@conversationStatus smallint=0,
	@tChatting smallint=0,
	@tWrapUp smallint=0,
	@finishedBy tinyint = 0,
	@onQueue bit = null,
	@tQueue smallint = 0,
	@tTimeout int = 0,
	@disposition smallint=0,
	@subDisposition smallint=0

AS
BEGIN
	DECLARE @isEndConversation bit
	DECLARE @meanContactTypeId smallint

	SET @meanContactTypeId = 1
SET NOCOUNT ON;

	IF @action = 1 BEGIN --new Conversation
		IF NOT EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId) BEGIN
			INSERT INTO [ccWhatsAppConversations](
												inboundId, phoneACD, clientId, conversationStatus, tChatting, 
												tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition) values 
											   (@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, 
												@tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition)
			SELECT @conversationId=SCOPE_IDENTITY()
			SELECT @conversationId as ConversationId
			RETURN (0)
		END
		ELSE BEGIN
			SELECT 0 AS ConversationId
			RETURN (0)
		END
	END

	IF @action = 2 BEGIN --save conversation Times
		Update ccWhatsAppConversations 
		set tChatting = DATEDIFF(ss,conversationDate,getdate()), 
			conversationStatus = @conversationStatus, finishedBy = 1,
			tConversation = DATEDIFF(ss,requestDate,getdate()) 
		where conversationId = @conversationId  
	END
END'
	
	EXEC(@sql)
	

	
	set @process = 'CW-WhatsApp insert setting 230 MultimediaCommon'
	set @sql = 'if not exists(select * from ccsettings where setting_id=230) 
	begin
		INSERT INTO ccSettings (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate)
		VALUES (230,''\Multimedia\Conversations\WhatsApp\ '',''Ruta donde se guardarán las conversaciones de WhatsApp'',	1,
				''GRL'',''Se guardan los archivos .json separados por carpetas'',''Path for saving WhatsApp conversations'',1,''.{0,99}'');
	end'
  EXEC(@sql)

  set @process = 'Valida y si existe SP'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaDeleteCampaignAndACD'')
            begin
          DROP PROCEDURE ccsp_GalateaDeleteCampaignAndACD;
            end'
    EXEC(@sql)

    set @process = 'CW-5636'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaDeleteCampaignAndACD]
        --declare
        @userId           SMALLINT,
        @DeleteCamId      VARCHAR(MAX),
        @DeleteACDGroupId VARCHAR(MAX),
        @moduleId         SMALLINT = 49
    AS
    BEGIN

        IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
            SELECT value As DeleteCamId, c.IDArea AS IDAreaCamp, 1 AS CampTypeCamp
            INTO #CampsDelete 
            FROM fn_RIASplitDelimited(@DeleteCamId, '','') a
            inner join ccCamps c on  a.value = c.cam_id and c.IDArea IS NOT NULL
        IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
            SELECT value As DeleteACDId, c.IDArea AS IDAreaACD, 0 AS CampTypeACD
            INTO #ACDDelete 
            FROM fn_RIASplitDelimited(@DeleteACDGroupId, '','') a
            inner join ccInbound c on  a.value = c.Inbound_id and c.IDArea IS NOT NULL

        IF  not Exists (select * from #CampsDelete union select * from #ACDDelete )
        begin 
            select ''-1'' AS Result
            return 
        end

        IF datalength(@DeleteCamId) > 0
            BEGIN

            if exists(select cam_id from ccInbound where cam_id in (select DeleteCamId from #CampsDelete)) begin
                --Borra las calificacion con reprogramacion
                delete ccCalifCamp from ccInbound A 
                inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
                inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
                where A.cam_id in (select DeleteCamId from #CampsDelete)
                --Borra las subcalificacion con reprogramacion
                delete rel from ccInbound A 
                inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
                inner join ccTipoCalif C on B.calif_id=C.calif_id 
                inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
                inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
                where A.cam_id in (select DeleteCamId from #CampsDelete) and sb.canReprogram=1
        
                update ccInbound set cam_id = null where cam_id in (select DeleteCamId from #CampsDelete)           
             
            end

            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) 
            select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete)

            delete from ccCampsAgente where cam_id in (select DeleteCamId from #CampsDelete)
            insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) 
            select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete) and A.tipo = 1
        
            delete from ccSupervisorCam where cam_id in (select DeleteCamId from #CampsDelete) and tipo = 1
            delete from ccRIACampEspWG where IdCampEsp in (select DeleteCamId from #CampsDelete) and tipo = 1

            IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
            SELECT ca.AreaName,
                   GETDATE() operationDate,
                   27 operationType,
                   (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                   @moduleId module_id,
                   c.cam_descripcion value,
                   ca.AreaName AS target
            INTO #CampLog
            FROM ccRIACat_Areas ca
            Inner join ccCamps c with(nolock) on ca.IDArea = c.IDArea
            WHERE c.cam_id in (select DeleteCamId from #CampsDelete)

            Update ccCamps set IDArea = null where cam_id in (select DeleteCamId from #CampsDelete)

        END
        IF datalength(@DeleteACDGroupId) > 0
            BEGIN

            if exists(select top 1 cam_id from ccInbound where Inbound_id in (select DeleteACDId from #ACDDelete))
                begin
                    update ccInbound set cam_id = null where Inbound_id in (select DeleteACDId from #ACDDelete)
            end

            IF OBJECT_ID(''tempdb..#AllWGACD'') IS NOT NULL DROP TABLE #AllWGACD
            SELECT DISTINCT(IDWG)
            INTO #AllWGACD
            FROM ccRIACampEspWG ce 
            WHERE IDCampEsp in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0

            insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) 
            select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG 
            from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id 
            where B.User_id is null and A.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

            delete ccInboundHorarios Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
            delete ccInboundMsgs Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) 
            select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 
            from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id 
            where B.User_id is null and A.cam_id in (SELECT DeleteACDId FROM #ACDDelete)

            delete ccSupervisorCam where cam_id in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0
            delete ccInboundAgentes where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
            delete ccRIACampEspWG where IdCampEsp  in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0


            IF OBJECT_ID(''tempdb..#ACDLog'') IS NOT NULL DROP TABLE #ACDLog
            SELECT ca.AreaName,
                    GETDATE() operationDate,
                    28 operationType,
                    (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                    @moduleId module_id,
                    i.descripcion value,
                    ca.AreaName AS target
            INTO #ACDLog
            FROM ccRIACat_Areas ca
            inner join ccInbound i with(nolock) on ca.IDArea = i.IDArea
            WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

            Update ccInbound set IDArea = null, status = 0 where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
        
            if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
                begin
                    update ContactMeanIn set name = '''', conexionInfo = ''usuarioID|token|tokenSecret|1|0'', connUser = '''', isActive = 0 
                    where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=2
            end
            if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
                begin
                    update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=1
            end
            update ccinbound set chatDomain = '''' where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)--para desasociar el dominio del chat
            
            if exists (SELECT inboundId FROM contactMeanIn WHERE inboundId in (select DeleteACDId from #ACDDelete))
                begin
                    update contactMeanIn set isActive = 0 where inboundId in (select DeleteACDId from #ACDDelete)
            end
        END

        IF datalength(@DeleteCamId) > 0
            Insert into ccRIALog Select * from #CampLog
        IF datalength(@DeleteACDGroupId) > 0
            Insert into ccRIALog Select * from #ACDLog
        
        SELECT DeleteCamId AS DeleteId,IDAreaCamp AS IDArea,CampTypeCamp AS CampType,''1'' AS Result FROM #CampsDelete
        UNION
        SELECT DeleteACDId,IDAreaACD,CampTypeACD,''1'' AS Result FROM #ACDDelete
        IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
        IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
    END'
    
    EXEC(@sql)

    set @process = 'Valida y si existe SP'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateEspecConfig'')
            begin
          DROP PROCEDURE ccsp_RIAUpdateEspecConfig;
            end'
    EXEC(@sql)

    set @process = 'CW-5636'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAUpdateEspecConfig] @inbound_id              SMALLINT, 
                                                  @descripcion             VARCHAR(50)  = NULL, 
                                                  @Status                  TINYINT      = NULL, 
                                                  @tNotas                  INT          = NULL, 
                                                  @tMaxWaitCall            INT          = NULL, 
                                                  @nMaxQue                 INT          = NULL, 
                                                  @tel_maxwait             VARCHAR(15)  = NULL, 
                                                  @tel_MaxQueue            VARCHAR(15)  = NULL, 
                                                  @tel_outservice          VARCHAR(15)  = NULL, 
                                                  @tel_noct                VARCHAR(15)  = NULL, 
                                                  @ShowCalifWnd            BIT          = NULL, 
                                                  @StartTimerOnHangUp      BIT          = NULL, 
                                                  @editableCallKey         BIT          = NULL, 
                                                  @queuePosition           BIT          = NULL, 
                                                  @tMaxQueueCallBack       SMALLINT     = NULL, 
                                                  @stopRecording           BIT          = NULL, 
                                                  @dialPrefixOverflow      VARCHAR(10)  = NULL, 
                                                  @OpriorityT              SMALLINT     = NULL, 
                                                  @callerIdDesc            VARCHAR(15)  = NULL, 
                                                  @chat                    TINYINT      = NULL, 
                                                  @inactiveChatTime        SMALLINT     = NULL, 
                                                  @maxChats                TINYINT      = NULL, 
                                                  @chatDomain              VARCHAR(MAX) = NULL, 
                                                  @chatQueue               SMALLINT     = NULL, 
                                                  @chatTime                SMALLINT     = NULL, 
                                                  @dRestrictPlay           BIT          = NULL, 
                                                  @callBackSurveyAgent     BIT          = NULL, 
                                                  @callBackSurveyClient    BIT          = NULL, 
                                                  @agts_notavailable       VARCHAR(15)  = NULL, 
                                                  @editableDtmf            BIT          = NULL, 
                                                  @prefijo                 VARCHAR(MAX) = NULL, 
                                                  @addDataCallBackReminder BIT          = NULL
AS
     SET NOCOUNT ON;
     UPDATE ccInbound
       SET 
           descripcion = ISNULL(@descripcion, descripcion), 
           STATUS = ISNULL(@status, STATUS), 
           tNotas = ISNULL(@tNotas, tNotas), 
           tMaxWaitCall = ISNULL(@tMaxWaitCall, tMaxWaitCall), 
           nMaxQue = ISNULL(@nMaxQue, nMaxQue), 
           tel_maxwait = ISNULL(@tel_maxwait, tel_maxwait), 
           tel_MaxQueue = ISNULL(@tel_MaxQueue, tel_MaxQueue), 
           tel_outservice = ISNULL(@tel_outservice, tel_outservice), 
           tel_noct = ISNULL(@tel_noct, tel_noct), 
           bnocturno = CASE
                           WHEN ISNULL(@tel_noct, 0) = ''0''
                                OR @tel_noct = ''''
                           THEN ''0''
                           ELSE ''1''
                       END, 
           StartTimerOnHangUp = ISNULL(@StartTimerOnHangUp, StartTimerOnHangUp), 
           editableCallKey = ISNULL(@editableCallKey, editableCallKey), 
           queuePosition = ISNULL(@queuePosition, queuePosition), 
           tMaxQueueCallBack = ISNULL(@tMaxQueueCallBack, tMaxQueueCallBack), 
           stopRecording = ISNULL(@stopRecording, stopRecording), 
           dialPrefixOverflow = ISNULL(@dialPrefixOverflow, dialPrefixOverflow), 
           OpriorityT = ISNULL(@OpriorityT, OpriorityT), 
           callerIdDesc = ISNULL(@callerIdDesc, callerIdDesc), 
           chat = ISNULL(@chat, chat), 
           inactiveChatTime = ISNULL(@inactiveChatTime, inactiveChatTime), 
           maxChats = ISNULL(@maxChats, maxChats), 
           chatQueueOverflow = ISNULL(@chatQueue, ISNULL(chatQueueOverflow, 15)), 
           chatTimeOverflow = ISNULL(@chatTime, ISNULL(chatTimeOverflow, 300)), 
           startStopRecording = ISNULL(@dRestrictPlay, startStopRecording), 
           callBackSurveyAgent = ISNULL(@callBackSurveyAgent, callBackSurveyAgent), 
           callBackSurveyClient = ISNULL(@callBackSurveyClient, callBackSurveyClient), 
           agts_notavailable = ISNULL(@agts_notavailable, agts_notavailable), 
           editableDtmf = ISNULL(@editableDtmf, editableDtmf), 
           prefijo = ISNULL(@prefijo, prefijo), 
           addDataCallBackReminder = ISNULL(@addDataCallBackReminder, addDataCallBackReminder)
     WHERE inbound_id = @inbound_id;
     IF @chat = 5 
        BEGIN
            IF NOT EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
            BEGIN
                INSERT INTO contactMeanIn (meanContactTypeId, name, inboundId, isActive) values (@chat, @descripcion, @inbound_id, (select status from ccInbound where Inbound_id = @inbound_id));
            END
        END;

    IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
        BEGIN
           UPDATE contactMeanIn set name = @descripcion where inboundId = @inbound_id;
        END
     IF NOT EXISTS
     (
         SELECT inbound_id
         FROM ccinbound
         WHERE inbound_id <> @inbound_id
               AND chatDomain = @chatDomain
               AND chatDomain <> ''''
     )
         BEGIN
             IF @chatDomain IS NOT NULL
                 BEGIN
                     UPDATE ccinbound
                       SET 
                           chatDomain = @chatDomain
                     WHERE inbound_id = @inbound_id;
             END;
     END;
         ELSE
         BEGIN
             UPDATE ccinbound
               SET 
                   chatDomain = ''''
             WHERE inbound_id = @inbound_id;
             RAISERROR(''Domain already in another ACD Group'', 15, 4);
     END;
     IF @ShowCalifWnd = 1
         BEGIN
             IF EXISTS
             (
                 SELECT cam_id
                 FROM ccCalifCamp
                 WHERE cam_id = @inbound_id
                       AND tipo = 0
             )
                 BEGIN
                     UPDATE ccInbound
                       SET 
                           ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd)
                     WHERE inbound_id = @inbound_id;
                     SELECT 1;
                     RETURN(0);
             END;
             SELECT 0;
             RETURN(0);
     END;
         ELSE
         UPDATE ccInbound
           SET 
               ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd)
         WHERE inbound_id = @inbound_id;
         

     SELECT 2;
     RETURN(0);
     SET NOCOUNT OFF;'
    
    EXEC(@sql)

    set @process = 'Valida y si existe SP'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_UpdateACDWhatsappConfig'')
            begin
          DROP PROCEDURE ccsp_UpdateACDWhatsappConfig;
            end'
    EXEC(@sql)

    set @process = 'CW-5636'
    set @sql = 'CREATE procedure  [dbo].[ccsp_UpdateACDWhatsappConfig]

    @ConexionInfo varchar(400),
    @inbound_id int,
    @ConnUser varchar(60),
    @tNotas int,
    @closeConversationTime tinyint,
    @ShowCalifWnd bit 

    AS
    set nocount on
        IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
        BEGIN
            UPDATE contactMeanIn SET conexionInfo = @conexionInfo, connUser = @connUser, closeConversationTime = @closeConversationTime where inboundId = @inbound_id;
        END;

        IF EXISTS (SELECT Inbound_id FROM ccInbound WHERE Inbound_id = @inbound_id) 
        BEGIN
            UPDATE ccInbound SET tNotas = @tNotas, ShowCalifWnd = @ShowCalifWnd where Inbound_id = @inbound_id;
        END;
    SELECT @inbound_id;
    return(@inbound_id)

    set nocount off'
    
    EXEC(@sql)

    set @process = 'Borra SP ccsp_GalateaAdminBlackListHistoricalLog si existe. Tarea CW-5254 Historial de listas negras'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminBlackListHistoricalLog'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminBlackListHistoricalLog;
            end'
    EXEC(@sql)

    set @process = 'Crea el SP ccsp_GalateaAdminBlackListHistoricalLog. Tarea CW-5254 Historial de listas negras'
    set @sql = 'CREATE PROCEDURE ccsp_GalateaAdminBlackListHistoricalLog --guiandose del sp ccsp_RIABlackListLog
@date smalldatetime,--start date
@endDate smalldatetime,
@idtipomov int,
@telephone varchar(1000),
@Scam_id varchar(1000),
@GenCSV tinyint

AS
set nocount on
declare @sql as nvarchar (4000), @params nvarchar(1000), @newFinalDate nvarchar(22), @newStartDate nvarchar(22)

set @params = ''@Ndate varchar(22), @Nidtipomov varchar(1),@Ntelephone varchar(1000)''

select @sql = case @GenCSV when 1 then ''select '' else ''select top 200 '' end

select @newFinalDate = convert(varchar(8), @endDate, 112)
select @newStartDate = convert(varchar(8), @date, 112)

set @sql = @sql + '' idhistorial, isnull(callout_id,0) as callout_id, telefono, fecha, isnull(cam_descripcion,'''''''') as campaign, movimiento, a4.Tipolista 
from cchistoriallistanegra a1 
inner join cctipomovslistanegra a2 on (a1.idtipomov=a2.idtipomov) 
left join cccamps a3 on (a1.cam_id=a3.cam_id)
inner join cctiposlistanegra a4 on (a1.idtipolista = a4.idtipolista) 
where fecha between ''''''+ @newStartDate +'' 00:00:01''''  and '' + nchar(39) + @newFinalDate + '' 23:59:59'''' ''
+ case isnull(@idtipomov, 0) when ''0'' then '''' when ''1'' then '' and a1.idtipomov in (1,7)''-- estas lineas las modifique
else '' and a1.idtipomov = @Nidtipomov '' end--aqui solo le di enter y lo puse en otra linea
+ case isnull(@telephone, 0) when ''0'' then '''' else '' and telefono = @Ntelephone '' end
+ case isnull(@Scam_id, 0) when ''0'' then '''' else '' and a1.cam_id in ('' + @Scam_id + '') '' end

execute sp_executesql @sql, @params,@Ndate=@date,@Nidtipomov=@idtipomov,@Ntelephone=@telephone

return(0)'
    EXEC(@sql)
    
	set @process = 'CW-5697 Valida si existe ccsp_ConversationWASave'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ConversationWASave'')
            begin
          DROP PROCEDURE ccsp_ConversationWASave;
            end'
    EXEC(@sql)

	set @process = 'CW-5697 Crea SP ccsp_ConversationWASave '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_ConversationWASave]

	@action int,
	@conversationId int=0,
	@inboundId smallint=null,
	@phoneACD varchar(50)= null,
	@clientId varchar(25)= null,
	@conversationStatus smallint=0,
	@tChatting smallint=0,
	@tWrapUp smallint=0,
	@finishedBy tinyint = 0,
	@onQueue bit = null,
	@tQueue smallint = 0,
	@tTimeout int = 0,
	@disposition smallint=0,
	@subDisposition smallint=0

AS
BEGIN
	DECLARE @isEndConversation bit
	DECLARE @meanContactTypeId smallint

	SET @meanContactTypeId = 1
SET NOCOUNT ON;

	IF @action = 1 BEGIN --new Conversation
		IF NOT EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId) BEGIN
			INSERT INTO [ccWhatsAppConversations](
												inboundId, phoneACD, clientId, conversationStatus, tChatting, 
												tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition) values 
											   (@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, 
												@tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition)
			SELECT @conversationId=SCOPE_IDENTITY()
			SELECT @conversationId as ConversationId
			RETURN (0)
		END
		ELSE BEGIN
			SELECT 0 AS ConversationId
			RETURN (0)
		END
	END

	IF @action = 2 BEGIN --save conversation Times
		Update ccWhatsAppConversations 
		set tChatting = DATEDIFF(ss,conversationDate,getdate()), 
			conversationStatus = @conversationStatus, finishedBy = 1,
			tConversation = DATEDIFF(ss,requestDate,getdate()) 
		where conversationId = @conversationId  
	END
	
	IF @action = 3 BEGIN --save conversation Status
		Update ccWhatsAppConversations 
		set conversationDate = getdate(),
			conversationStatus = @conversationStatus
		where conversationId = @conversationId  
	END
END'
	
	EXEC(@sql)

    set @process = 'CW-5722 Valida si existe la columna clientName ccWhatsAppConversations y la borra'
    set @sql = '
    IF exists (SELECT * FROM sys.columns WHERE name = N''clientName'' AND Object_ID = Object_ID(N''ccWhatsAppConversations''))
    BEGIN
        ALTER TABLE ccWhatsAppConversations DROP COLUMN clientName
    END'
    EXEC(@sql)

    set @process = 'CW-5722 Valida si no existe la columna clientName ccWhatsAppConversations y la agrega'
    set @sql = '
    IF not exists (SELECT * FROM sys.columns WHERE name = N''agentId'' AND Object_ID = Object_ID(N''ccWhatsAppConversations''))
    BEGIN
        ALTER TABLE ccWhatsAppConversations ADD agentId INT;
    END'
    EXEC(@sql)

    set @process = 'CW-XXX Mejoras 477 Alter SP ccsp_OUTResetJobs'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTResetJobs] 
        @camid AS INT= 0
AS
BEGIN

  CREATE TABLE #TempccoLogDials ( 
    callout_id INT, PRIMARY KEY (callout_id)
  );
  DECLARE @today DATETIME;

  SELECT @today = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 121), 121);
  
  IF @camid = 0
  BEGIN
    INSERT INTO #TempccoLogDials
         SELECT callout_id
         FROM ccoLogDials AS ld WITH(NOLOCK)
         WHERE fecha >= @today
         GROUP BY callout_id;
  END;
     ELSE
    IF @camid > 0
    BEGIN
      INSERT INTO #TempccoLogDials
           SELECT callout_id
           FROM ccoLogDials AS ld WITH(NOLOCK)
           WHERE cam_id = @camid AND 
             fecha >= @today
           GROUP BY callout_id;
    END;

  -- CALLBACKS Se han marcado recientemente
  UPDATE ccoWorkingTable WITH(ROWLOCK)
    SET cal_status = 1
  FROM ccoWorkingTable wt
     INNER JOIN
     #TempccoLogDials ld
     ON wt.callout_id = ld.callout_id
  WHERE wt.cal_status = 2   

  IF @camid = 0
  BEGIN
    -- NUEVAS - Nunca se han marcado
    UPDATE ccoWorkingTable --WITH(ROWLOCK)
      SET cal_status = 0
    WHERE cal_status = 2;
  END;
     ELSE
  BEGIN  
    -- NUEVAS - Nunca se han marcado
    UPDATE ccoWorkingTable WITH(ROWLOCK)
      SET cal_status = 0
    WHERE cal_status = 2 AND 
        cam_id = @camid;
  END;

  DROP TABLE #TempccoLogDials;
END;'
    EXEC(@sql)

    set @process = 'CW-XXX Mejoras 477 Alter SP ccspAgent_GetLastCalls'
    set @sql = 'ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
AS
     SET NOCOUNT ON;
     DECLARE @lastCallAgt TABLE(id           INT NOT NULL
                              , tipo         VARCHAR(10) NOT NULL
                              , Hora         DATETIME NOT NULL --VARCHAR(19) NOT NULL, 
                              , Telefono     VARCHAR(55) NOT NULL
                              , EspCamp      VARCHAR(55) NOT NULL
                              , Calificacion VARCHAR(60)
                              , Duracion     VARCHAR(10) NOT NULL
                              , CallBack     DATETIME
                              , cal_key      VARCHAR(40)
                              , IDCampEsp    SMALLINT NOT NULL
                              , prefijo      VARCHAR(255) NULL
                              , GraphicID    INT
                              , PRIMARY KEY(id)
     );

     DECLARE @pais TINYINT;
     DECLARE @maxHours SMALLINT;
     DECLARE @topRows INT;
     DECLARE @setting VARCHAR(6);
     DECLARE @hidePhone BIT;
     DECLARE @dateStart DATETIME;

     SET @hidePhone = 1;

     SELECT @setting = valor FROM ccSettings WHERE setting_id = 255;

     SET @maxHours = CAST(SUBSTRING(@setting, 1, (SELECT PATINDEX(''%|%'', @setting)) - 1) AS SMALLINT);
     SET @topRows = CAST(SUBSTRING(@setting, (SELECT PATINDEX(''%|%'', @setting)) + 1, LEN(@setting)) AS INT);

     IF @maxHours = 0
     BEGIN
         SELECT Id
              , tipo
              , (CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) AS Hora
              , Telefono
              , EspCamp
              , Calificacion
              , CallBack
              , Duracion
              , '''' AS CallBack
              , cal_key
              , IDCampEsp
              , prefijo
              , GraphicID
              , @hidePhone AS HidePhone FROM @lastCallAgt;

         RETURN 0;
     END;

     SELECT @pais = valor FROM ccSettings WHERE setting_id = 104;

     SELECT @hidePhone = CASE WHEN valor = ''0''
                         THEN 0 ELSE 1
                         END FROM ccSettings WHERE setting_id = 223;

     IF @topRows = 0
     BEGIN
         SET @topRows = 10000;
     END;

     SET @dateStart = DATEADD(hh, -@maxHours, GETDATE());

     WITH timeTransfer
          AS (SELECT cal_id
                   , tipo
                   , SUM(tAntesXfer) AS tAntesXfer
                   , SUM(tDespuesXfer) AS tDespuesXfer FROM ccLogTransfers
              WHERE fechaFin > @dateStart
              GROUP BY cal_id
                     , tipo)

          INSERT INTO @lastCallAgt
                 ---Insert OUT
                 SELECT TOP (@topRows) c.cal_id AS id
                                     , ''OUT'' AS Tipo
                                     , cal_inicio
                                     , cal_telefono AS Telefono
                                     , cam_descripcion AS EspCamp
                                     , ISNULL(cal.Description, '''') AS Calificacion
                                     , CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
                                                                                                THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
                                                                                                END, 0), 114) AS Duracion
                                     , cal_fcallback AS CallBack
                                     , cal_key
                                     , c.cam_id AS IDCampEsp
                                     , ISNULL(ccCamps.prefijo, '''') Prefijo
                                     , graph.graphic_id GraphicID FROM ccoCallsOut c
                                                                       INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
                                                                       LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
                                                                       LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
                                                                       LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
                                                                                                   AND t.tipo = 2
                 WHERE user_id = @user_id
                       AND cal_inicio > @dateStart
                 UNION
                 --- IN
                 SELECT TOP (@topRows) c.cal_id AS id
                                     , ''IN'' AS Tipo
                                     , cal_inicio
                                     , cal_ani AS Telefono
                                     , descripcion AS EspCamp
                                     , ISNULL(cal.Description, '''') AS Calificacion
                                     , CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
                                                                                                     THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
                                                                                                     END, 0), 108) Duracion
                                     , NULL AS CallBack
                                     , cal_key
                                     , c.inbound_id AS IDCampEsp
                                     , ISNULL(ccInbound.prefijo, '''') Prefijo
                                     , graph.graphic_id GraphicID FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
                                                                       JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
                                                                       INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
                                                                       LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
                                                                       LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
                                                                                                   AND t.tipo = 1
                 WHERE user_id = @user_id
                       AND cal_inicio > @dateStart;

     SELECT Id
          , tipo
          , CASE WHEN @pais = 4
            THEN(CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) ELSE(CONVERT(VARCHAR(10), Hora, 103) + '' '' + CONVERT(VARCHAR(8), Hora, 14))
            END AS Hora
          , Telefono
          , EspCamp
          , Calificacion
          , ISNULL(CONVERT(VARCHAR(16), CallBack, 121), '''') AS CallBack
          , Duracion
          , CallBack
          , cal_key
          , IDCampEsp
          , prefijo
          , GraphicID
          , @hidePhone AS HidePhone FROM @lastCallAgt
     ORDER BY hora DESC;
     SET NOCOUNT OFF;
     '
    EXEC(@sql)
	
	set @process = 'CW-5697 Valida si no existe la columna maxWhats ccRIACat_Areas y la agrega'
    set @sql = '
    IF not exists (SELECT * FROM sys.columns WHERE name = N''maxWhats'' AND Object_ID = Object_ID(N''ccRIACat_Areas''))
    BEGIN
        ALTER TABLE ccRIACat_Areas ADD maxWhats tinyint;
    END'
    EXEC(@sql)
	
	set @process = 'CW-5697 Valida si existe ccsp_Multimedia2'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_Multimedia2'')
            begin
          DROP PROCEDURE ccsp_Multimedia2;
            end'
    EXEC(@sql)

	set @process = 'CW-5697 Crea SP ccsp_Multimedia2 '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_Multimedia2] @action INT, @inboundId INT = NULL, @userId INT = NULL, @senderId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	IF @action = 1
	BEGIN --Lista  ACD
		SELECT DISTINCT A.inbound_id AS Id, A.chat AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets, 
		cast(isnull(C.maxWhats, 3) AS TINYINT) AS MaxWhats, A.IDArea AS AreaId
		FROM ccInbound A
		INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
		WHERE @inboundId IS NULL OR @inboundId = A.Inbound_id
	END
	ELSE IF @action = 2
	BEGIN --Lista Agentes  
		SELECT DISTINCT A.User_id AS [Id], C.idCampEsp AcdId, isnull(skill, 8) Skill
		FROM ccRIAWorkGroupUsers A
		INNER JOIN ccusers B ON A.User_id = B.User_id
		INNER JOIN ccRIACampEspWG C ON C.IDWG = A.IDWG AND C.Tipo = 0
		INNER JOIN ccInbound D ON C.idCampEsp = D.inbound_id
		LEFT JOIN ccskills S ON S.inbound_id = D.inbound_id AND S.user_id = B.user_id
		WHERE B.TipoUser_id = 1 AND (@userId IS NULL OR @userId = A.User_id)
		ORDER BY A.User_id
	END
	ELSE IF @action = 3
	BEGIN --List Sender Mail
		SELECT A.contactMeanOutId AS Id, ISNULL(R.inboundId, 0) AS AcdId, A.isActive AS IsActive
		FROM contactMeanOut A
		LEFT JOIN relationContactMeanOutInbound R ON A.contactMeanOutId = R.contactMeanOutId
		WHERE @senderId IS NULL OR @senderId = A.contactMeanOutId
	END
END'
	
	EXEC(@sql)
	
	set @process = 'CW-5697 Valida si existe ccsp_ConversationWASave'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ConversationWASave'')
            begin
          DROP PROCEDURE ccsp_ConversationWASave;
            end'
    EXEC(@sql)

	set @process = 'CW-5697 Crea SP ccsp_ConversationWASave '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_ConversationWASave]

	@action int,
	@conversationId int=0,
	@inboundId smallint=null,
	@phoneACD varchar(50)= null,
	@clientId varchar(25)= null,
	@conversationStatus smallint=0,
	@tChatting smallint=0,
	@tWrapUp smallint=0,
	@finishedBy tinyint = 0,
	@onQueue bit = null,
	@tQueue smallint = 0,
	@tTimeout int = 0,
	@disposition smallint=0,
	@subDisposition smallint=0,
	@agentId int = 0

AS
BEGIN
	DECLARE @isEndConversation bit
	DECLARE @meanContactTypeId smallint

	SET @meanContactTypeId = 1
SET NOCOUNT ON;

	IF @action = 1 BEGIN --new Conversation
		IF NOT EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId) BEGIN
			INSERT INTO [ccWhatsAppConversations](
												inboundId, phoneACD, clientId, conversationStatus, tChatting, 
												tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition,agentId) values 
											   (@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, 
												@tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition,@agentId)
			SELECT @conversationId=SCOPE_IDENTITY()
			SELECT @conversationId as ConversationId
			RETURN (0)
		END
		ELSE BEGIN
			SELECT 0 AS ConversationId
			RETURN (0)
		END
	END

	IF @action = 2 BEGIN --save conversation Times
		Update ccWhatsAppConversations 
		set tChatting = DATEDIFF(ss,conversationDate,getdate()), 
			conversationStatus = @conversationStatus, finishedBy = 1,
			tConversation = DATEDIFF(ss,requestDate,getdate()) 
		where conversationId = @conversationId  
	END
	
	IF @action = 3 BEGIN --save conversation Status
		Update ccWhatsAppConversations 
		set conversationDate = getdate(),
			conversationStatus = @conversationStatus
		where conversationId = @conversationId  
	END
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