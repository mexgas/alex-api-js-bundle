/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.33

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
SET @versionfix = 35
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
		-------------------------------------- Begin CW-7757 Fix Historical Chat Ivan --------------------------------------------------------------------------------
		SET @process = 'CW-7757 Alter Procedure ccsp_RIAABCChat Cambio en Option 10 para que traiga el login en lugar del nombre del admin y agente lineas(358 y 359)'
		SET @sql = 'ALTER Procedure [dbo].[ccsp_RIAABCChat]
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
					    select C.xmlType, ISNULL(U2.Login, '''') Nombre_Adm,
					                      ISNULL(U1.Login, '''') Nombre_Agt,
					    C.date, C.iniTime, C.endTime, C.TipoMsgChat, C.text, C.time, isnull(U2.user_id,0) Admin_Id, isnull(U1.user_id,case when C.TipoMsgChat=4 then -4 when C.TipoMsgChat=5 then -5 else 0 end) Agent_Id
					    from #CHAT2 C left join ccUsers U1 on U1.user_id = C.User_id_Agt
					     left join ccUsers U2 on U2.user_id = C.User_id_Adm
					    order by C.id
					    return(0)
					 end
					select 0
					set nocount off';
		EXEC(@sql);
		-------------------------------------- End CW-7757 Fix Historical Chat Ivan --------------------------------------------------------------------------------

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
--		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
