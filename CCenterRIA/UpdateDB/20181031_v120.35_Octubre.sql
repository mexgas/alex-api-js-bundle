/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author:Daniel Vega
		
Date: 
Description:

Database: CCenterRia
Required version: 

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 120--**********actualizar a 119 sin fix
set @versionfix = 35
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 34
	begin
		begin tran
		begin try
			

		set @process = 'CW-1799 Version 120.25 Display error message on email service failure.'
        set @Sql= '	if not exists(select * from ccSettings where setting_id=208) begin
	--PT-->Exibir mensagem de erro na falha do serviço de e-mail.
	insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) 
	values(208,''0'',''Mostrar mensaje de error en falla del servicio de correo electrónico.'',1,''X'',''Mensaje cuando la carpeta compartida para leer o escribir un correo no tiene permisos''
		,''Display error message on email service failure.'',1,''^[0-1]$'')
end'
        EXEC(@Sql)

        set @process = 'CW-2028 Alter Column ccChatsNodeHistory.chatId is not null'
    set @Sql= 'ALTER TABLE ccChatsNodeHistory ALTER COLUMN chatId int NOT NULL'
    EXEC(@Sql)

    set @process = 'CW-2028 Alter Column ccEmailNodeHistory.emailId is not null'
    set @Sql= 'ALTER TABLE ccEmailNodeHistory ALTER COLUMN emailId int NOT NULL'
    EXEC(@Sql)

    set @process = 'CW-2028 Alter Column ccTwitterNodeHistory.conversationTwitterId is not null'
    set @Sql= 'ALTER TABLE ccTwitterNodeHistory ALTER COLUMN conversationTwitterId int NOT NULL'
    EXEC(@Sql)

    set @process = 'CW-2028 Alter Column ccChatsNodeHistory.chatId PRIMARY KEY'
    set @Sql= 'if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''PK_ccChatsNodeHistory'')
   ALTER TABLE ccChatsNodeHistory ADD CONSTRAINT PK_ccChatsNodeHistory PRIMARY KEY (chatId)
'
    EXEC(@Sql)

    set @process = 'CW-2028 Alter Column ccEmailNodeHistory.emailId PRIMARY KEY'
    set @Sql= 'if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''PK_ccEmailNodeHistory'')
   ALTER TABLE ccEmailNodeHistory ADD CONSTRAINT PK_ccEmailNodeHistory PRIMARY KEY (emailId)'
    EXEC(@Sql)

    set @process = 'CW-2028 Alter Column ccTwitterNodeHistory.conversationTwitterId PRIMARY KEY'
    set @Sql= 'if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''PK_ccTwitterNodeHistory'')
   ALTER TABLE ccTwitterNodeHistory ADD CONSTRAINT PK_ccTwitterNodeHistory PRIMARY KEY (conversationTwitterId)
'
    EXEC(@Sql)

	set @process = 'CW-2028 -- Alter SP ccsp_BaseXmngr'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
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
	select @chat = case when valor > 1 then 1 else 0 end from ccSettings where setting_id = 145
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
	update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()) where serviceId= @option and  isfull = 0 and dateEnd is null
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
    EXEC(@Sql)

	set @process = 'CW-2028 -- ALter SP ccsp_CleanNodeBaseX'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_CleanNodeBaseX]
@option int
AS
BEGIN

declare @percentage int,@setting int
declare @top int
declare @table table(id bigint primary key,node xml not null,status	tinyint not null)
declare @tableNotExists table(id bigint primary key)

set @percentage=20 --porcentaje de registros que se pasaran esta en funcion del setting 188


select  @setting  = valor from ccSettings where setting_id = 188
if @setting is null set @setting = 40000
set @top=@setting/@percentage

	
if @option = 1 begin
		
		insert into @table
		select top (@top)  A.chatId, A.node,status from ccChatsNode A with(nolock) where A.status in(1,3) order by chatId
		
		insert into @tableNotExists
		select A.id from  @table A 
		left join ccChatsNodeHistory  B with(nolock)  on B.chatId=A.id 
		where B.chatId is null
		
		insert into ccChatsNodeHistory(chatId,node,dateIn,status)		
		select  A.id,A.node,GETDATE() as dateIn,A.status from @table A
		inner join @tableNotExists B on A.id=B.id

		delete from ccChatsNode where chatId in(select id from @table)

end
else if @option = 3  begin
	
	insert into @table
	select top (@top)  A.emailId, A.node,status from ccEmailNode A with(nolock) where A.status in(1,3) order by emailId
		
	insert into @tableNotExists
	select A.id from  @table A 
	left join ccEmailNodeHistory  B with(nolock)  on B.emailId=A.id 
	where B.emailId is null
		
	insert into ccEmailNodeHistory(emailId,node,dateIn,status)		
	select  A.id,A.node,GETDATE() as dateIn,A.status from @table A
	inner join @tableNotExists B on A.id=B.id

	delete from ccEmailNode where emailId in(select id from @table)
end
else if @option = 4  begin
	
	insert into @table
	select top (@top)  A.conversationTwitterId, A.node,status from ccTwitterNode A with(nolock) where A.status in(1,3) order by conversationTwitterId
		
	insert into @tableNotExists
	select A.id from  @table A 
	left join ccTwitterNodeHistory  B with(nolock)  on B.conversationTwitterId=A.id 
	where B.conversationTwitterId is null
		
	insert into ccTwitterNodeHistory(conversationTwitterId,node,dateIn,status)		
	select  A.id,A.node,GETDATE() as dateIn,A.status from @table A
	inner join @tableNotExists B on A.id=B.id

	delete from ccTwitterNode where conversationTwitterId in(select id from @table)
end

END'
    EXEC(@Sql)

    set @process = 'CW-2028 -- Job CleanNodeBaseXCCenterRIA every day by 10 minutes'
    set @Sql= 'USE [msdb]

/****** Object:  Job [CleanNodeBaseXCCenterRIA]    Script Date: 11/09/2018 11:25:13 a. m. ******/
if exists(select * from msdb.dbo.sysjobs where name=''CleanNodeBaseXCCenterRIA'') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N''CleanNodeBaseXCCenterRIA'', @delete_unused_schedule=1
end


/****** Object:  Job [CleanNodeBaseXCCenterRIA]    Script Date: 11/09/2018 11:25:13 a. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 11/09/2018 11:25:13 a. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CleanNodeBaseXCCenterRIA'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Move the history database records'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [MoveNodeBaseXChat]    Script Date: 11/09/2018 11:25:14 a. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''MoveNodeBaseXChat'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec ccsp_CleanNodeBaseX 1'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [MoveNodeBaseXEmail]    Script Date: 11/09/2018 11:25:14 a. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''MoveNodeBaseXEmail'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec ccsp_CleanNodeBaseX 3'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [MoveNodeBaseXTwitter]    Script Date: 11/09/2018 11:25:14 a. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''MoveNodeBaseXTwitter'', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec ccsp_CleanNodeBaseX 4'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''CleanNodeBaseXCCenterRIA'', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180911, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959		
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
    EXEC(@Sql)      
	

				
		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix 

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
