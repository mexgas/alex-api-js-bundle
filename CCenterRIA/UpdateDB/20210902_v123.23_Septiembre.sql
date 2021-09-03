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
SET @versionfix = 23
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

    set @process = 'CW-5629 ccsp_CleanNodeBaseX - Se quita el SP ccsp_CleanNodeBaseX si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_CleanNodeBaseX'')
            begin
          DROP PROCEDURE ccsp_CleanNodeBaseX;
            end'
    EXEC(@sql)

    set @process = 'CW-5629 ccsp_CleanNodeBaseX - Se modifica SP ccsp_CleanNodeBaseX'
    set @sql = 'CREATE Procedure [dbo].[ccsp_CleanNodeBaseX]

	@option int
	AS
	BEGIN

		declare @percentage int,@setting int
		declare @top int
		declare @table table(id bigint primary key,node xml not null,dateStart datetime, status	tinyint not null)
		declare @tableNotExists table(id bigint primary key)

		set @percentage=20 --porcentaje de registros que se pasaran esta en funcion del setting 188

		select  @setting  = valor from ccSettings where setting_id = 188
		if @setting is null set @setting = 40000
		set @top=@setting/@percentage
	
		if @option = 1 begin
		
				insert into @table
				select top (@top)  A.chatId, A.node,A.dateIn, status from ccChatsNode A with(nolock) where A.status in(1,3) order by chatId
		
				insert into @tableNotExists
				select A.id from  @table A 
				left join ccChatsNodeHistory  B with(nolock)  on B.chatId=A.id 
				where B.chatId is null
		
				insert into ccChatsNodeHistory(chatId,node,dateIn,status)		
				select  A.id,A.node,A.dateStart,A.status from @table A
				inner join @tableNotExists B on A.id=B.id

				delete from ccChatsNode where chatId in(select id from @table)

		end
		else if @option = 3  begin
	
			insert into @table
			select top (@top)  A.emailId, A.node,A.dateIn,status from ccEmailNode A with(nolock) where A.status in(1,3) order by emailId
		
			insert into @tableNotExists
			select A.id from  @table A 
			left join ccEmailNodeHistory  B with(nolock)  on B.emailId=A.id 
			where B.emailId is null
		
			insert into ccEmailNodeHistory(emailId,node,dateIn,status)		
			select  A.id,A.node,A.dateStart,A.status from @table A
			inner join @tableNotExists B on A.id=B.id

			delete from ccEmailNode where emailId in(select id from @table)
		end
		else if @option = 4  begin
	
			insert into @table
			select top (@top)  A.conversationTwitterId, A.node,A.dateIn,status from ccTwitterNode A with(nolock) where A.status in(1,3) order by conversationTwitterId
		
			insert into @tableNotExists
			select A.id from  @table A 
			left join ccTwitterNodeHistory  B with(nolock)  on B.conversationTwitterId=A.id 
			where B.conversationTwitterId is null
		
			insert into ccTwitterNodeHistory(conversationTwitterId,node,dateIn,status)		
			select  A.id,A.node,A.dateStart,A.status from @table A
			inner join @tableNotExists B on A.id=B.id

			delete from ccTwitterNode where conversationTwitterId in(select id from @table)
		end

	END'
    EXEC(@sql)

	 
	set @process = 'CW-5629 ccsp_RIAInsertChat - Se quita el SP ccsp_RIAInsertChat si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAInsertChat'')
            begin
          DROP PROCEDURE ccsp_RIAInsertChat;
            end'
    EXEC(@sql)

	set @process = 'CW-5629 ccsp_RIAInsertChat - Se modifica SP ccsp_RIAInsertChat'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAInsertChat]

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
          

				 if exists(select * from ccChatsNodeHistory where chatId=@chatId) begin
					update ccChatsNodeHistory set [status] = 2, node =@xml  where chatId = @chatId
				 end
				 else if exists(select * from ccChatsNode where chatId=@chatId) 
				 begin
					update ccChatsNode set [status] = 2, node =@xml  where chatId = @chatId
				 end
				 else begin 
					insert into ccChatsNode (chatId,node, dateIn,[status]) values (@chatId,@xml, getdate(),0)				                
				 end
		   end
	end'
    EXEC(@sql)

	set @process = 'CW-5762 Valor por default para maximo de WhatsApp por agente'
    set @sql = 'IF EXISTS (SELECT *  FROM SYS.COLUMNS  WHERE OBJECT_ID = OBJECT_ID(''ccRIACat_Areas'') AND NAME = ''maxWhats'')
begin
	ALTER TABLE ccRIACat_Areas DROP COLUMN maxWhats;
	ALTER TABLE ccRIACat_Areas ADD maxWhats tinyint;
	ALTER TABLE [dbo].[ccRIACat_Areas] ADD  DEFAULT ((3)) FOR [maxWhats];
	Update ccRIACat_Areas set maxWhats = 3 where maxWhats is null
	
end
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