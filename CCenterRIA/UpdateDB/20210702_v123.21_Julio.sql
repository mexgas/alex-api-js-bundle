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
SET @versionfix = 21
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= 19
BEGIN
	BEGIN TRAN

	BEGIN TRY

set @process = 'CW-5580 Menu detalle agentes cambio a licencia tipo 1'
    set @sql = 'update ccMenus 
set release=''4517765b05ed60dd03269f5ee41a18e4c127d9296149a3a6e076f310a261a4335b58f5dccbb784d329d9bef77519eeb4''
where type=3 and menu_id=2080'
    EXEC(@sql)

	set @process = 'CW-5390 se quita el sp ccsp_GalateaAdminGetPermissions si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminGetPermissions'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminGetPermissions;
            end'
    EXEC(@sql)

	set @process = 'CW-5390 Alter procedure ccsp_GalateaAdminGetPermissions'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
                    @user_id varchar(255),
                    @Type int
                AS
                set nocount on

                Select distinct A.User_id as AgentId, Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' +
                isNull(ApellidoMaterno, '''') as FullName, cast(dialMask & 1 as int) as AllowCellPhoneCalls,
                cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
                cast( xfermask as int) as AllowTransferCalls, cast(CanChangeStatus as tinyint) CanChangeStatus,
                cast(XferAgents as tinyint) XferAgents,
                ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording
                from ccUsers A
                join ccRIAWorkGroupUsers B on A.user_id = B.user_id
                where tipoUser_id = 1 and IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
                return(0)

                set nocount off'
	exec (@sql)

	set @process = 'CW-5390 se quita el sp ccsp_GalateaGetAdminRelations si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetAdminRelations'')
            begin
          DROP PROCEDURE ccsp_GalateaGetAdminRelations;
            end'
    EXEC(@sql)

	set @process = 'CW-5390 se quita el sp ccsp_GalateaGetAdminRelations si ya existe'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetAdminRelations]
                @Option smallint,
                @areaId AS INT = 0,
                @AdminId AS INT = 0
                as
                declare @agentes varchar(max)
                declare @wgs varchar(max)
                declare @count int
                declare @id int
                declare @wg int

                if @option =1 --Obtiene las relaciones de los Administradores con los WG
                begin
                    SELECT 
                    ROW_NUMBER() OVER(ORDER BY idWG ASC) AS Row,
                    IDWG,@agentes as agents
                    into #Relations
                    FROM ccRIAAreaWorkGroup 

                    if not exists(select * from ccRIACat_Areas) or (select count(idWG) from #Relations) = 0
                    begin
                        select Null as IDWG ,@agentes as agents, @wgs as idsWg
                        return (0)
                    end

                    select @count = count(idWG) from #Relations
                    set @id =1
                    while @id<=@count
                    begin
                        select @wg =idwg from #Relations where Row =@id
                        select @agentes=null
                        select @agentes = coalesce(@agentes + '','', '''') +  convert(varchar(12),wgu.user_id)
                        from ccUsers u inner join ccRIAWorkGroupUsers wgu on wgu.User_id = u.User_id
                        where TipoUser_id = 1 and wgu.IDWG =@wg
                        order by u.user_id

                        Update #Relations set agents= @agentes where IDWG= @wg
                        set @id=@id+1
                    end
                    if exists (select * from ccUsers_Roles where User_id = @AdminId and Rol_id = (select Rol_id from ccRoles where Level = 7))
                        BEGIN
                            select  Cast(Re.IDWG as varchar(10)) as idwg,agents
                            from #Relations Re
                            right JOIN  ccRIACat_WorkGroup wg ON wg.IDWG = Re.IDWG
                            where wg.StatusWorkGroup = 1
                        END

                        ELSE
                        BEGIN
                            SELECT @AdminId = ISNULL(@AdminId, 0)			
                        
                            select  Cast(Re.IDWG as varchar(10)) as idwg,agents
                            from #Relations Re
                            Left JOIN  ccRIAWorkGroupUsers wg ON wg.IDWG = Re.IDWG
                            WHERE wg.User_id = @AdminId
                        END		

                end'
	exec (@sql)

	set @process = 'CW-5390 se quita el sp ccsp_GalateaAdminSetPermissions si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSetPermissions'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminSetPermissions;
            end'
    EXEC(@sql)

    set @process = 'CW-5390 Alter procedure ccsp_GalateaAdminSetPermissions'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
                    @user_id varchar(MAX),
                    @permissionName VARCHAR(255),
                    @permissionValue INT
                AS
                SET NOCOUNT ON

                DECLARE @changeBit INT

                SET @changeBit =
                CASE
                    WHEN @permissionName = ''AllowCellPhoneCalls'' or @permissionName = ''startStopRecording'' or @permissionName = ''XferManual'' or @permissionName = ''AllowTransferCalls'' or @permissionName = ''AgentPermissionDailing''
                    THEN 1
                    WHEN @permissionName = ''AllowLongDistanceCalls'' or @permissionName = ''XferExt'' or @permissionName = ''DailingMode''
                    THEN 2
                    WHEN @permissionName = ''AllowLocalCalls'' or @permissionName = ''XferCamps''
                    THEN 4
                    WHEN @permissionName = ''XferAgents''
                    THEN 8
                    ELSE 0
                END

                IF @user_id IS NOT NULL
                BEGIN
                    
                    UPDATE
                        ccUsers
                    SET DialMask =
                        CASE
                        WHEN @permissionName = ''AllowCellPhoneCalls''
                        OR @permissionName = ''AllowLongDistanceCalls''
                        OR @permissionName = ''AllowLocalCalls''
                        THEN 
                            CASE
                            WHEN @permissionValue = 1
                            THEN
                                CASE
                                WHEN (DialMask & @changeBit) <> @changeBit
                                THEN DialMask ^ @changeBit
                                ELSE DialMask
                                END
                            WHEN @permissionValue = 0
                            THEN
                                CASE
                                WHEN (DialMask & @changeBit) = @changeBit
                                THEN DialMask ^ @changeBit
                                ELSE DialMask
                                END
                            END	
                        ELSE DialMask
                        END,
                        
                        XferMask =
                        CASE
                        WHEN @permissionName = ''AllowTransferCalls''
                        THEN
                            CASE
                            WHEN @permissionValue = 1
                            THEN
                                CASE
                                WHEN (XferMask & @changeBit) <> @changeBit
                                THEN XferMask ^ @changeBit
                                ELSE XferMask
                                END
                            WHEN @permissionValue = 0
                            THEN
                                CASE
                                WHEN (XferMask & @changeBit) = @changeBit
                                THEN XferMask ^ @changeBit
                                ELSE XferMask
                                END
                            END
                        ELSE XferMask
                        END,

                        XferAgents =
                        CASE
                        WHEN @permissionName = ''XferAgents''
                        OR @permissionName = ''XferCamps'' 
                        OR @permissionName = ''XferExt'' 
                        OR @permissionName = ''XferManual'' 
                        THEN 
                            CASE
                            WHEN @permissionValue = 1
                            THEN
                                CASE
                                WHEN (XferAgents & @changeBit) <> @changeBit
                                THEN XferAgents ^ @changeBit
                                ELSE XferAgents
                                END
                            WHEN @permissionValue = 0
                            THEN
                                CASE
                                WHEN (XferAgents & @changeBit) = @changeBit
                                THEN XferAgents ^ @changeBit
                                ELSE XferAgents
                                END
                            END
                        ELSE XferAgents
                        END,

						startStopRecording =
						CASE
						WHEN @permissionName = ''startStopRecording'' 
						THEN 
							CASE
							WHEN @permissionValue = 1
							THEN 1
							WHEN @permissionValue = 0
							THEN 0
							END
						ELSE startStopRecording
						END,

                        DialingMode = 
                        CASE
                        WHEN @permissionName = ''DailingMode'' 
                        OR @permissionName = ''AgentPermissionDailing'' 
                        THEN 
                            CASE
                            WHEN @permissionValue = 1
                            THEN
                                CASE
                                WHEN (DialingMode & @changeBit) <> @changeBit
                                THEN DialingMode ^ @changeBit
                                ELSE DialingMode
                                END
                            WHEN @permissionValue = 0
                            THEN
                                CASE
                                WHEN (DialingMode & @changeBit) = @changeBit
                                THEN DialingMode ^ @changeBit
                                ELSE DialingMode
                                END
                            END	
                        ELSE DialingMode
                        END
                    WHERE User_id IN (select value from dbo.fn_RIASplitDelimited(@user_id,'',''))
                END

                SET NOCOUNT OFF'
	exec (@sql)

    set @process = 'CW-5310 Alter Table para la columna DialingMode'
	set @sql = '
        ALTER TABLE ccUsers DROP CONSTRAINT DF_ccUsers_DialingMode

        ALTER TABLE ccUsers
        ALTER COLUMN DialingMode 
        TINYINT NOT NULL 

        ALTER TABLE ccUsers
        ADD CONSTRAINT DF_ccUsers_DialingMode
        DEFAULT 0 FOR DialingMode'
	exec (@sql)


	set @process = 'CW-55543 No se muestran los datos de llamadas de entrada en reportes'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateDataCallIn'')
            begin
          DROP PROCEDURE ccsp_RIAUpdateDataCallIn;
            end'
    EXEC(@sql)

	set @process = 'CW-55543 No se muestran los datos de llamadas de entrada en reportes'
    set @sql = 'CREATE procedure [dbo].[ccsp_RIAUpdateDataCallIn]
@calloutid int,
@callid int,
@typecall smallint,
@data1 varchar(100),
@data2 varchar(100),
@data3 varchar(100),
@data4 varchar(100),
@data5 varchar(100)

AS

if @typecall = 1 --Inbound 
begin
	IF EXISTS (SELECT * FROM DataCallIn WHERE CallId=@callid )
		DELETE FROM DataCallIn WHERE CallId=@callid

	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data1, ''Dato 1'' )
	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data2, ''Dato 2'' )
	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data3, ''Dato 3'' )
	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data4, ''Dato 4'' )
	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data5, ''Dato 5'' )
end
	
if @typecall = 2 --Outbound 
begin
	update ccocallsoutsource set Dato1 = @data1,
			Dato2 = @data2,
			Dato3 = @data3,
			Dato4 = @data4,
			Dato5 = @data5 where callout_id = @calloutid
end
'
    EXEC(@sql)

    set @process = 'Chats Masivos- se agrega tabla ccChatLog_AreaWg'
    set @sql = 'if not exists (select * from sys.tables where name = N''ccChatLog_AreaWg'')
    begin
        CREATE TABLE ccChatLog_AreaWg (
    ChatID int FOREIGN KEY (ChatID) REFERENCES ccRIAChat_Log(ChatID),
    IdGroup int,
    TypeGroup varchar(15)
);
    end'
    EXEC(@sql)

    set @process = 'Chats Masivos- se agregan tipos de mensaje'
    set @sql = 'if not exists (select * from ccRIAChat_TipoMsg where MsgDescripcion = ''ADM to Area'')
begin
    insert into ccRIAChat_TipoMsg values(''ADM to Area'', ''Administrador escribe mensaje a Area'',1)
end'
    EXEC(@sql)

    set @process = 'Chats Masivos- se agregan tipos de mensaje'
    set @sql = 'if not exists (select * from ccRIAChat_TipoMsg where MsgDescripcion = ''ADM to WG'')
begin
    insert into ccRIAChat_TipoMsg values(''ADM to WG'', ''Administrador escribe mensaje a Workgroup'',1)
end'
    EXEC(@sql)

    set @process = 'Chats Masivos- se quita el sp ccsp_RIAABCChat si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAABCChat'')
            begin
          DROP PROCEDURE ccsp_RIAABCChat;
            end'
    EXEC(@sql)

    set @process = 'Chats Masivos e Historial Agente- se modifica sp ccsp_RIAABCChat'
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

 
select 0
set nocount off'
    EXEC(@sql)

    set @process = 'Chats- se quita el sp ccsp_RIAGetRelsSupsAgent si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAGetRelsSupsAgent'')
            begin
          DROP PROCEDURE ccsp_RIAGetRelsSupsAgent;
            end'
    EXEC(@sql)

    set @process = 'Chats- se modifica sp ccsp_RIAGetRelsSupsAgent'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAGetRelsSupsAgent]

AS
--Relaciones Sup-Agt de acuerdo a WorkGroups
IF OBJECT_ID(''tempdb..#Agt'') IS NOT NULL
    DROP TABLE #Agt;
IF OBJECT_ID(''tempdb..#Adm'') IS NOT NULL
    DROP TABLE #Adm;
SELECT u.user_id AS agt, 
       w.IDWG
INTO #Agt
FROM ccusers u
     INNER JOIN ccriaworkgroupusers w WITH(NOLOCK) ON u.user_id = w.user_id
                                                      AND tipouser_id = 1;
SELECT u.user_id, 
       w.IDWG, 
       u.login, 
       ur.rol_id
INTO #Adm
FROM ccusers u
     INNER JOIN ccriaworkgroupusers w ON(u.user_id = w.user_id
                                         AND (tipouser_id = 2
                                              OR tipouser_id = 6)
                                         AND u.onLine = 1)
     LEFT JOIN ccUsers_Roles ur WITH(NOLOCK) ON ur.User_id = u.User_id
                                                AND ur.rol_id = 7;
SELECT DISTINCT 
       agt.agt AS agt, 
       adm.user_id AS sup, 
       adm.login
FROM #Agt agt
     INNER JOIN #Adm adm WITH(NOLOCK) ON agt.IDWG = adm.IDWG
                                         OR adm.Rol_id = 7
WHERE adm.user_id NOT IN
(
    SELECT User_id
    FROM ccRIAUsr_AdminPermissions
    WHERE per_id = 4
) -- Excluye sólo monitoreo
ORDER BY agt.agt, 
         adm.user_id;

IF OBJECT_ID(''tempdb..#Agt'') IS NOT NULL
    DROP TABLE #Agt;
IF OBJECT_ID(''tempdb..#Adm'') IS NOT NULL
    DROP TABLE #Adm;'
    EXEC(@sql)

    set @process = 'Chats- se quita el sp ccsp_GalateaLoadAreas si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaLoadAreas'')
            begin
          DROP PROCEDURE ccsp_GalateaLoadAreas;
            end'
    EXEC(@sql)

    set @process = 'Chats- se quita el sp ccsp_GalateaLoadAreas'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaLoadAreas]
as
SET NOCOUNT ON; 
select u.IDArea, ca.AreaName, User_id, TipoUser_id 
from ccUsers u
join ccRIACat_Areas ca on u.IDArea=ca.IDArea
where TipoUser_id=1
order by IDArea, User_id
SET NOCOUNT OFF'
    EXEC(@sql)

	
	set @process = 'CW-5484 ALTER ccsp_RIAInsertChat SP'
	
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAInsertChat]
@action int,
@inboundId smallint = 0,
@domain varchar(50) = '''',
@session varchar(50) = '''',
@tTimeout smallint = 0,
@chatId int = 0,
@status tinyInt = 0,
@userId smallint = 0,
@finished tinyInt = 0,
@chattingTime int = 0,
@startTime datetime = null,
@clientName varchar(50) = '''',
@firstMessage int = 0,
@firstMessageTime datetime = null,
@crmNode xml = null,
@supervisor varchar(100) =null,
@template varchar (100)= null,
@ScoreTemplate int = null
AS

declare @xml xml
declare @sql nvarchar(2000)

if @action = 1 begin -- Inserta nuevo chat request /*comentario: se recomienda hacer la busqueda del userid del CRM en esta action*/
       insert into ccRIAChats (domain,session,chatStatus,requestDate,inboundId,clientName)
       values(@domain,@session,@status,getDate(),0,@clientName)
       set @chatId = scope_identity()
       select @chatId
end

else if @action = 2 begin -- Save Initial Info
update ccRIAChats set inboundId = @inboundId, chatStatus = @status, userId = case when @userId = 0 then userId else @userId end, tTimeout = @tTimeout where chatId = @chatId
end

else if @action = 3 begin -- Update Status
update ccRIAChats set chatStatus = @status where chatId = @chatId
end

else if @action = 4 begin -- Save Final Status
if @firstMessage = 0
       begin
             update ccRIAChats set finishedBy = @finished, userID =case when @userId = 0 then userId else @userId end where chatId = @chatId
       end
else
       begin
             update ccRIAChats set finishedBy = @finished, firstMessageTime  = @firstMessageTime where chatId = @chatId
       end
end

else if @action in (5,6) begin -- Save Chatting Time /*comentario: la insercion del nodo (registro final para el finder) se recomiendo en esta action, no olvidar validar status = 4, finishedby != null y validar los tiempos para garantizar el dato final */
       if @action = 5 begin
             update ccRIAChats set tChatting = @chattingTime, userId = case when @userId = 0 then userId else @userId end, chatDate = @startTime where chatId = @chatId
       end

	   if @action = 6 begin
			update ccRIAChats set userId = case when @userId = 0 then userId else @userId end  where chatId = @chatId
	   end



	   set @crmNode = null

	   exec ccsp_CreateNodeMultimedia @conversationId=@chatId, @type=0,@xml=@xml OUTPUT,@supervisor=@supervisor,@template =@template,@ScoreTemplate=@ScoreTemplate

       if @xml is not null
       begin
             select @crmNode = node from ccCRMNodes where chatId = @chatId
             if @crmNode is not null
             begin
                    set @sql = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R01)[1]'''') ''
                    execute sp_executesql @sql,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
             end

             if not exists(select * from ccChatsNode where chatId=@chatId) begin ---insert finder
                insert into ccChatsNode (chatId,node, dateIn,[status]) values (@chatId,@xml, getdate(),0)
             end
             else begin ---update finder
		     update ccChatsNode set [status] = 2, node =@xml  where chatId = @chatId                
             end
       end
end'
    EXEC(@sql)

        set @process = 'CW-5591 Se valida si es root para mostrarle todos los agentes o solo los de su grupo'
        set @sql = ' 
        ALTER PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
            @user_id varchar(255),
            @Type int
            AS
            set nocount on

            declare @isRoot int;

            if exists (Select Rol_id from ccUsers A join ccUsers_Roles B on A.User_id = B.User_id where A.User_id = @user_id and rol_id = 7) set @isRoot = 1 else set @isRoot = 0;
            print @isRoot

            IF @isRoot = 1
            BEGIN
                Select 
                User_id as AgentId, 
                Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
                cast(dialMask & 1 as int) as AllowCellPhoneCalls,
                cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
                cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
                cast( xfermask as int) as AllowTransferCalls, 
                cast(CanChangeStatus as tinyint) CanChangeStatus,
                cast(XferAgents as tinyint) XferAgents,
                ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
                ISNULL(cast( (DialingMode & 2) / 2 as int), 0) as AgentPermissionDailing,
                ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode
            from 
                ccUsers
            where 
                tipoUser_id = 1
            return(0)
            END
            ELSE
            BEGIN
                Select distinct 
                A.User_id as AgentId, 
                Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
                cast(dialMask & 1 as int) as AllowCellPhoneCalls,
                cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
                cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
                cast( xfermask as int) as AllowTransferCalls, 
                cast(CanChangeStatus as tinyint) CanChangeStatus,
                cast(XferAgents as tinyint) XferAgents,
                ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
                ISNULL(cast( (DialingMode & 2) / 2 as int), 0) as AgentPermissionDailing,
                ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode
            from 
                ccUsers A
            join ccRIAWorkGroupUsers B on 
                A.user_id = B.user_id
            where 
                tipoUser_id = 1 and 
                IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
            return(0)
            END
            set nocount off
        '
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