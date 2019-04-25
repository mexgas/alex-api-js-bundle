/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Vic Gonzalez
		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.34

Se agrega la tarea
CW-SETTNGS

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

IF @actualVersion = @version AND @actualVersionFix >= 34
BEGIN
	BEGIN TRAN
	BEGIN TRY
		
			EXEC (@Sql)
		SET @process = 'CW-2770 Alter SP -- Version 121.34'
		SET @Sql = 'ALTER Procedure [dbo].[ccsp_RIAABCChat]
@OperationType tinyint = 0, -- 0:Select | 1:Insert | 2:Select Excel | 3:DateRange | 4:Admins | 5:Agents | 6:GalateaAdmin
@TipoMsgChat tinyint = null,
@User_id_Adm varchar(8000) = null,
@User_id_Agt varchar(8000) = null,
@ChatMsg varchar(1500) = null,
@Fecha_Chat_ini datetime = null,
@Fecha_Chat_fin datetime = null,
@IDArea int = null
AS
set nocount on

if @OperationType not in (0,1,2,3,4,5,6)
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
	select SCOPE_IDENTITY() ChatID
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
	--This action was created for Galatea''s Agent Chat Log
	SELECT  convert(varchar(10),Fecha_Chat,108) HourChat,
	C.TipoMsgChat , u2.Login AdminLogin,
	U1.Login AgentLogin,
	''"''+ REPLACE(C.ChatMsg,''"'',''""'') + ''"'' AS ChatMsg
	FROM ccRIAChat_Log C join ccUsers U1 on U1.user_id = C.User_id_Agt
	 JOIN ccUsers U2 on U2.user_id = C.User_id_Adm
	WHERE 
	  User_id_Agt in (select case when isnull(@User_id_Agt,''0'')=''0'' then User_id_Agt else value end from dbo.fn_RIASplitDelimited (@User_id_Agt, '',''))
	 AND Fecha_Chat BETWEEN ISNULL(@Fecha_Chat_ini, ''19000101 00:00'')
	 AND ISNULL(@Fecha_Chat_fin, DATEADD(hh, 1, getdate()))

 end
select 0
set nocount off'
		EXEC (@Sql)
		
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		--EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
