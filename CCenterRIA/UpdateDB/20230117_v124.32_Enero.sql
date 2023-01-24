/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.25

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
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 32
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

	/**---------------------------------- BEGIN CW-7740 MARCO GARCIA - MARCO CHAGOLLA ----------------------------------------------------------*/
	SET @process = 'CW-7740-Configuración de buzón de voz delete procedure ccsp_RIACATvoiceMail'
	SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIACATvoiceMail'')
		BEGIN
			DROP PROCEDURE ccsp_RIACATvoiceMail;
		END';
	EXEC(@sql);

	SET @process = 'CW-7740-Configuración de buzón de voz create procedure ccsp_RIACATvoiceMail'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_RIACATvoiceMail]
	@type TINYINT,
	@user_id SMALLINT,
	@ACDvm_id VARCHAR(1000)=NULL,
	@vmID VARCHAR(1000)=NULL,
	@mailbox VARCHAR(50)=NULL,
	@inbound_id SMALLINT=NULL,
	@isKolob BIT=0
	AS
	SET NOCOUNT ON
	DECLARE @IDarea SMALLINT;

	SELECT @IDarea=IDarea FROM ccUsers WHERE user_id=@user_id

	IF ISNULL(@IDarea,'''')=''''
	 BEGIN
		SELECT -1, ''invalid user area''
		RETURN(0)
	 END

	IF @type=1 -- Get acd catalog
	 BEGIN
	 IF(@isKolob = 1)
		BEGIN
			SELECT ci.Inbound_id, ci.descripcion FROM dbo.ccRIACat_WorkGroup AS crcwg INNER JOIN dbo.ccRIACampEspWG AS crcew ON crcew.IDWG = crcwg.IDWG 
			INNER JOIN dbo.ccRIAWorkGroupUsers AS crwgu ON crwgu.IDWG = crcwg.IDWG AND crwgu.User_id = @user_id
			INNER JOIN dbo.ccRIAAreaWorkGroup AS crawg ON crawg.IDWG = crcew.IDWG INNER JOIN dbo.ccInbound AS ci ON crcew.IdCampEsp = ci.Inbound_id
			WHERE crcew.Tipo = 0 AND crawg.IDArea = @IDarea AND ci.chat = 0
			ORDER BY ci.descripcion
		END
		ELSE
		BEGIN
			SELECT Inbound_id, descripcion from ccInbound where IDArea=@IDArea order by descripcion
		END
		return(0)
	 end

	if @type=2 -- Get mail vs inbound_id relationship by inbound_id
	 begin
		select r.ACDvm_id, m.mailbox, m.vmID, m.IDArea, r.inbound_id
		from ccRIA_vmMailBoxes m join ccRIA_vmACDMailBoxes r on m.vmID=r.vmID
		where r.inbound_id=@inbound_id and m.IDArea=@IDarea order by m.mailbox
		return(0)
	 end

	if @type=3 -- Get email catalog by user area
	 begin
		select vmID, mailbox, IDArea from ccRIA_vmMailBoxes where IDArea=@IDarea
		return(0)
	 end

	if @type=4 -- add mail vs inbound_id relationship
	 BEGIN
		if not exists(select vmID from ccRIA_vmMailBoxes where IDArea=@IDArea and vmID in (select value from dbo.fn_RIASplitDelimited(@vmID, '',''))) 
		 begin
			select CAST(-5 AS INT) --, ''invalid mailbox id''
			return(0)
		 end

		if not exists(select inbound_id from ccInbound where inbound_id=@inbound_id and IDArea=@IDArea)
		 begin
			select CAST(-3 AS INT) --, ''invalid inbound_id''
			return(0)
		 end

		if not exists(select ACDvm_id from ccRIA_vmACDMailBoxes where inbound_id=@inbound_id and vmID in (select value from dbo.fn_RIASplitDelimited(@vmID, '','')))
			insert ccRIA_vmACDMailBoxes (vmID, inbound_id) 
			select vmID, @inbound_id from ccRIA_vmMailBoxes where IDArea=@IDArea and vmID in (select value from dbo.fn_RIASplitDelimited(@vmID, '','')) and
			cast(vmID as char(5))+''-''+cast(@inbound_id as char(5)) not in (select cast(vmID as char(5))+''-''+cast(inbound_id as char(5)) from ccRIA_vmACDMailBoxes)
			select CAST(1 AS INT) -- isnull(SCOPE_IDENTITY(), -7), ''relation exists''
		return(0)
	 end

	if @type=5 -- del mail vs inbound_id relationship
	 begin
 		if not exists(select ACDvm_id from ccRIA_vmACDMailBoxes where ACDvm_id in (select value from dbo.fn_RIASplitDelimited(@ACDvm_id, '','')))
		 begin
			select CAST(-4 AS INT) --, ''invalid relationship''
			return(0)
		 end

		select top 1 @inbound_id = inbound_id from ccRIA_vmACDMailBoxes where ACDvm_id in (select value from dbo.fn_RIASplitDelimited(@ACDvm_id, '',''))
		delete ccRIA_vmACDMailBoxes where ACDvm_id in (select value from dbo.fn_RIASplitDelimited(@ACDvm_id, '',''))
		select CAST(@inbound_id AS INT)
 		return(0)
	 end

	if @type=6 -- Insert email into catalog
	 begin
		if len(replace(isnull(@mailbox,''''),'' '',''''))<10
		 begin
			select CAST(-2 AS int)--, ''invalid mailbox adress''
			return(0)
		 end

		if not exists (select mailbox from ccRIA_vmMailBoxes where mailbox=@mailbox and @IDArea=IDArea)
			insert ccRIA_vmMailBoxes (mailbox, IDarea) select @mailbox, @IDarea

		select CAST(isnull(SCOPE_IDENTITY(),-6) AS int)--, ''mailbox exists''
		return(0)
	 end

	if @type=7 -- update mail
	 begin
		if not exists(select mailbox from ccRIA_vmMailBoxes where vmID=@vmID and IDArea=@IDArea) 
		 begin
			select CAST(-5 AS int)--, ''invalid mailbox id''
			return(0)
		 end

		if len(replace(isnull(@mailbox,''''),'' '',''''))<10 
		 begin
			select CAST(-2 AS int)--, ''invalid mailbox adress''
			return(0)
		 end

		if exists(select mailbox from ccRIA_vmMailBoxes where mailbox=@mailbox and IDArea=@IDArea and vmID<>@vmID) 
		 begin
			select CAST(-6 AS int)
			return(0)
		 end

	
		if(@isKolob = 1)
		begin
			update ccRIA_vmMailBoxes set mailbox=@mailbox where vmID=@vmID
			select CAST(@vmID AS int)
		end
		else
		begin
			update ccRIA_vmMailBoxes set mailbox=@mailbox where vmID=@vmID
		end
		return(0)
	 end

	if @type=8 -- check mail references
	 begin
		if exists(select ACDvm_id from ccRIA_vmACDMailBoxes where vmID in (select vmID from ccRIA_vmMailBoxes where vmID=@vmID and IDArea=@IDArea))
			select -8, ''mail with active relationships''	
		return(0)
	 end

	if @type=9 -- del mail
	 BEGIN
		if not exists(select mailbox from ccRIA_vmMailBoxes where vmID IN (select value from dbo.fn_RIASplitDelimited(@vmID, '','')) and IDArea=@IDArea) 
		 BEGIN
			IF (@iskolob = 1) 
			BEGIN
				SELECT ''-5'' --, ''invalid mailbox id'' ; 
			END
			ELSE
			BEGIN
				SELECT CAST(-5 AS INT) --, ''invalid mailbox id'' 
			END
		 end

		IF EXISTS(SELECT crvamb.inbound_id FROM dbo.ccRIA_vmACDMailBoxes AS crvamb INNER JOIN dbo.ccRIA_vmMailBoxes AS crvmb
		ON crvmb.vmID = crvamb.vmID WHERE crvamb.vmID IN (select value from dbo.fn_RIASplitDelimited(@vmID, '',''))
		AND crvmb.IDArea = @IDArea
		GROUP BY crvamb.inbound_id)
		BEGIN

			SELECT @inbound_id = crvamb.inbound_id FROM dbo.ccRIA_vmACDMailBoxes AS crvamb INNER JOIN dbo.ccRIA_vmMailBoxes AS crvmb
			ON crvmb.vmID = crvamb.vmID WHERE crvamb.vmID IN (select value from dbo.fn_RIASplitDelimited(@vmID, '',''))
			AND crvmb.IDArea = @IDArea
			GROUP BY crvamb.inbound_id

			DELETE dbo.ccRIA_vmACDMailBoxes WHERE vmID IN (select value from dbo.fn_RIASplitDelimited(@vmID, '','')) AND inbound_id = @inbound_id
		END

		if(@isKolob = 1)
		begin
			DELETE ccRIA_vmMailBoxes where vmID IN (select value from dbo.fn_RIASplitDelimited(@vmID, '',''))
			select @vmID
		end
		else
		begin
			DELETE ccRIA_vmMailBoxes where vmID IN (select value from dbo.fn_RIASplitDelimited(@vmID, '',''))
		END
		return(0)
	 end

	set nocount off';

	EXEC(@sql);	

	/**---------------------------------- END CW-7740 MARCO GARCIA - MARCO CHAGOLLA ----------------------------------------------------------*/
	/**---------------------------------- BEGIN K028000_HistorialChat GERARDO - IVAN MARTIN ----------------------------------------------------------*/
	SET @process = 'K028000_HistorialChat DROP procedure ccsp_RIAABCChat'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIAABCChat'')
				BEGIN
					DROP PROCEDURE ccsp_RIAABCChat;
				END';
	EXEC(@sql);

	SET @process = 'K028000_HistorialChat Se modifico el store procedure ccsp_RIAABCChat en el cual se agrego el @OperationType 9 y @OperationType 10
					el @OperationType 10 es para la consulta de las conversaciones mientras que el @OperationType 9 es para la obtención de la información de las conversaciones para generar los csv'
	SET @sql = 'CREATE Procedure [dbo].[ccsp_RIAABCChat]
				@OperationType tinyint = 0, -- 0:Select | 1:Insert | 2:Select Excel | 3:DateRange | 4:Admins | 5:Agents | 6:GalateaAdmin
				@TipoMsgChat tinyint = null,
				@User_id_Adm varchar(8000) = null,
				@User_id_Agt varchar(8000) = null,
				@ChatMsg varchar(1500) = null,
				@Fecha_Chat_ini datetime = null,
				@Fecha_Chat_fin datetime = null,
				@Fechas_Chat varchar(8000) = null,
				@IDArea int = null,
				@IDGroup int = null
				AS
				set nocount on

				declare @new_chat_id int;

				if @OperationType not in (0,1,2,3,4,5,6,7,8,9,10)
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

				 if @OperationType=9
				  begin

				  -- Realizamos la Select para extraer las tablas
				    if isnull(@User_id_Adm,''0'')=''0'' and isnull(@User_id_Agt,''0'')=''0'' and isnull(@TipoMsgChat,0)=0 and @Fechas_Chat is null
				        raiserror(''Invalid Data 2'', 18, 2)
					Declare @languageSystem smallint;
					select @languageSystem = valor from ccsettings where setting_id=27
					Declare @SenderToAgent varchar(500) 
					set @SenderToAgent = case when @languageSystem = 1 then ''From admin to agent'' else ''De admin para agente'' end
					Declare @SenderToAdmin varchar(500) 
					set @SenderToAdmin = case when @languageSystem = 1 then ''From agent to admin'' else ''De agente para admin'' end

				    select Fecha_Chat Date,
					case C.TipoMsgChat when 1 then @SenderToAgent when 2 then @SenderToAdmin else ''Admin -> Global'' end SenderToRecipient,
					isnull(U2.Nombres + isnull('' '' + U2.ApellidoPaterno, '''') + isnull('' '' + U2.ApellidoMaterno, ''''),'''') Administrator,
					isnull(U1.Nombres + isnull('' '' + U1.ApellidoPaterno, '''') + isnull('' '' + U1.ApellidoMaterno, ''''),'''') Agent,
					''"''+ REPLACE(C.ChatMsg,''"'',''""'') + ''"'' as Message, isnull(U2.User_id,0) Admin_Id, isnull(U1.User_id,0) Agent_Id, case C.TipoMsgChat when 1 then U2.Login when 2 then U1.Login when 4 then U2.Login when 5 then U2.Login else '''' end UserName
					from ccRIAChat_Log C left join ccUsers U1 on U1.user_id = C.User_id_Agt
						left join ccUsers U2 on U2.user_id = C.User_id_Adm
					where TipoMsgChat = case when isnull(@TipoMsgChat,0)=0 then TipoMsgChat else @TipoMsgChat end
						and User_id_Adm in (select case when isnull(@User_id_Adm,''0'')=''0'' then User_id_Adm else value end from dbo.fn_RIASplitDelimited (@User_id_Adm, '',''))
						and User_id_Agt in (select case when isnull(@User_id_Agt,''0'')=''0'' then User_id_Agt else value end from dbo.fn_RIASplitDelimited (@User_id_Agt, '',''))
						and convert(varchar,Fecha_Chat,103) in (select  value  from dbo.fn_RIASplitDelimited (@Fechas_Chat, '','')) -- order by Fecha_Chat desc
				    --103
					  return (0)
				  end

				 if @OperationType=10
				 begin
				    Declare @User_id_Adm3 smallint, @User_id_Agt3 smallint, @Fecha5 varchar(10), @Fecha6 varchar(10), @Fecha7 varchar(10)
				    CREATE TABLE #CHAT2 (id int identity, xmlType tinyint, User_id_Adm smallint, User_id_Agt smallint, date varchar(10),
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
				    Into @User_id_Adm3, @User_id_Agt3, @Fecha5, @Fecha6, @Fecha7

				    if @@FETCH_STATUS = 0
				     Begin

				    -- Mientras hay resultados para procesar
				        While @@FETCH_STATUS = 0
				         Begin
				            insert into #CHAT2 select ''1'' xmlType, @User_id_Adm3 User_id_Adm, @User_id_Agt3 User_id_Agt,
				             @Fecha5 date, @Fecha6 iniTime, @Fecha7 endTime, 0 TipoMsgChat, '''' text, '''' time

				            -- Iniciamos el proceso
				            insert into #CHAT2 select ''0'' xmlType, @User_id_Adm3 User_id_Adm, @User_id_Agt3 User_id_Agt, @Fecha5 date, '''' iniTime,
				            '''' endTime, TipoMsgChat, ChatMsg text, convert(varchar(25), Fecha_Chat, 108) time
				            from ccRIAChat_Log where User_id_Adm = @User_id_Adm3 and User_id_Agt = @User_id_Agt3 and convert(varchar(25), Fecha_Chat, 103) = @Fecha5
				            order by time desc

				            -- Recuperamos la siguiente fila
				            Fetch Next From CursorChat
				                Into @User_id_Adm3, @User_id_Agt3, @Fecha5, @Fecha6, @Fecha7
				         End
				     End


				    Close CursorChat
				    Deallocate CursorChat
				    select C.xmlType, U2.Nombres + isnull('' '' + U2.ApellidoPaterno, '''') + isnull('' '' + U2.ApellidoMaterno, '''') Nombre_Adm,
				      isnull(U1.Nombres + isnull('' '' + U1.ApellidoPaterno, '''') + isnull('' '' + U1.ApellidoMaterno, ''''),'''') Nombre_Agt,
				    C.date, C.iniTime, C.endTime, C.TipoMsgChat, C.text, C.time, isnull(U2.user_id,0) Admin_Id, isnull(U1.user_id,case when C.TipoMsgChat=4 then -4 when C.TipoMsgChat=5 then -5 else 0 end) Agent_Id
				    from #CHAT2 C left join ccUsers U1 on U1.user_id = C.User_id_Agt
				     left join ccUsers U2 on U2.user_id = C.User_id_Adm
				    order by C.id
				    return(0)
				 end
				select 0
				set nocount off';
	EXEC(@sql);

	SET @process = 'Creacion de campañas de entrada y salida: Se corrige case para que ponga el tipo de campaña de entrada y salida correctamente'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
	                @cam_id smallint,
	                @cam_descripcion varchar(40) = null,
	                @cam_tnotas smallint = null,
	                @cam_ocupado tinyint = null,
	                @cam_NoInt_ocupado tinyint = null,
	                @cam_inter_ocupado smallint = null,
	                @cam_nocontesto tinyint = null,
	                @cam_NoInt_nocontesto tinyint = null,
	                @cam_inter_nocontesto smallint = null,
	                @cam_fax tinyint = null,
	                @cam_NoInt_fax tinyint = null,
	                @cam_inter_fax smallint = null,
	                @cam_ModoManual tinyint= null,
	                @ANI varchar(15) = null,
	                @cam_ShowCalifWnd bit = null,
	                @cam_StartTimerOnHangUp bit = null,
	                @editableCallKey bit = null,
	                @cam_tNoContesta tinyint = null,
	                @cam_intensive_dialing tinyint = null,
	                @detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
	                @detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
	                @compliance TinyInt = null,
	                @cam_inter_graba smallint = null,
	                @cam_NoInt_graba tinyint = null,
	                @progDial smallint = null,
	                @excCallBack Tinyint = null,
	                @dialOrder Tinyint = null,
	                @dialPrefix varchar(10) = null,
	                @dialPrefixMan varchar(10) = null,
	                @dialPrefixXfe varchar(10) = null,
	                @listenManualCall bit = null,
	                @stopRecording bit = null,
	                @abandonCallback bit = null,
	                @autoCB smallint = null,
	                @id_listAni int = null,
	                @tDialonWrapUp smallint = null,
	                @quesize smallint=null,
	                @DNCScrub int=null,
	                @callerIdDesc varchar(15)=null,
	                @timeZoneRule int=null,
	                @callsBySurvey int=null,
	                @ivrScript int=null,
	                @surveyPctg int=null,
	                @call_record tinyint=null,
	                @dRestrictPlay bit = null,
	                @leaveRecMessage bit = null,
	                @manualCallOnChat bit = null,
	                @callBackSurveyClient bit = null,
	                @callBackSurveyAgent bit = null,
	                @funcEspDtmf int =null,
	                @sipHdrsCfg varchar(255) = null,
	                @cam_inter_cancelled smallint = null,
	                @prefijo varchar(max) = null,
	                @exitAssisted bit = null,
	                @previewDiscard bit = null,
	                @rotativeAlgo tinyint = null,
	                @timesPreview tinyint = null,
	                @cam_tPreview smallint = null,
	                @timesDiscard tinyint = null,
					@CampType int = null 
	                as
	                set nocount on
	                DECLARE @timesDiscardActual int = (SELECT timesDiscard FROM ccCamps WHERE cam_id = @cam_id)
	                DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)

	                UPDATE ccCamps SET
	                 cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
	                 cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
	                 cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
	                 cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
	                 cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
	                 cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
	                 cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
	                 cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
	                 cam_inter_cancelled = isnull(@cam_inter_cancelled,cam_inter_cancelled),
	                 cam_fax = isnull(@cam_fax,cam_fax),
	                 cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
	                 cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
	                 cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
	                 ANI = isnull(@ANI,ANI),
	                 cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
	                 editableCallKey = isnull(@editableCallKey, editableCallKey),
	                 cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
	                 iTipoDial = isnull(@cam_intensive_dialing, iTipoDial),
	                 detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine),
	                 detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
	                 compliance = isnull(@compliance, compliance),
	                 cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
	                 cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
	                 cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
	                 progDial = isnull(@progDial, progDial),
	                 excCallBack = isnull(@excCallBack,excCallBack),
	                 dialOrder = isnull(@dialOrder, dialOrder),
	                 dialPrefix = isnull(@dialPrefix, dialPrefix),
	                 dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
	                 dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
	                 listenManualCall = isnull(@listenManualCall, listenManualCall),
	                 stopRecording = isnull(@stopRecording, stopRecording),
	                 abandonCallback = isnull(@abandonCallback, abandonCallback),
	                 t_autoCB = isnull(@autoCB,t_autoCB),
	                 id_anilist = isnull(@id_listAni,id_anilist),
	                 tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
	                 cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
	                 cam_maxqueue = isnull(@quesize,cam_maxqueue),
	                 DNCScrub = isnull(@DNCScrub,DNCScrub),
	                 callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
	                 timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
	                 callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
	                 ivrScript = isnull(@ivrScript,ivrScript),
	                 surveyPctg = isnull(@surveyPctg,surveyPctg),
	                 call_record = isnull(@call_record,call_record),
	                 startStopRecording = isnull(@dRestrictPlay, startStopRecording),
	                 leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
	                 manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
	                 callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
	                 callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
	                 funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf ),
	                 sipHdrFormat = isnull(@sipHdrsCfg, sipHdrFormat),
	                 prefijo = isnull(@prefijo, prefijo),
	                 exitAssisted = isnull(@exitAssisted, exitAssisted),
	                 previewDiscard = isnull(@previewDiscard, previewDiscard),
	                 rotativeAlgo = isnull(@rotativeAlgo, rotativeAlgo),
	                 timesPreview = isnull(@timesPreview, timesPreview),
	                 cam_tPreview = isnull(@cam_tPreview,cam_tPreview),
	                 timesDiscard = isnull(@timesDiscard, timesDiscard),
	                 CampType = (CASE  WHEN @CampType is not null THEN @CampType WHEN @progDial = 3 THEN @progDiaL ELSE 1 END)

	                Where cam_id = @cam_id

	                if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
	                begin
	                    EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
	                end

	                if @cam_ShowCalifWnd = 1
	                 begin
	                 If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1)
	                  begin
	                  select 0
	                  return(0)
	                  end

	                 UPDATE ccCamps SET cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd, cam_ShowCalifWnd)
	                 where cam_id = @cam_id
	                 select 1
	                 return(0)
	                  end

	                --else
	                UPDATE ccCamps SET
	                cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
	                where cam_id = @cam_id
	                select 2
	                return(0)

	                set nocount off';
	EXEC(@sql);

	/**---------------------------------- END K028000_HistorialChat GERARDO - IVAN MARTIN ----------------------------------------------------------*/

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
