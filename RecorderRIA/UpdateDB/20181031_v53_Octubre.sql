/*
Autor: Jesus Gallardo
Descripcion:


Version requerida: 50
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 53
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

	set @process = 'CW-2028 -- Drop Index IX_RIA_RecNodeHistory'
	set @Sql= 'if exists (select * from sys.indexes where name = N''IX_RIA_RecNodeHistory'' and object_id = OBJECT_ID(N''RIA_RecNodeHistory''))
	drop index IX_RIA_RecNodeHistory on RIA_RecNodeHistory'
    EXEC(@Sql)

    set @process = 'CW-2028 -- RIA_RecNodeHistory.grab_id is not null'
	set @Sql= 'ALTER TABLE RIA_RecNodeHistory ALTER COLUMN grab_id bigint NOT NULL'
    EXEC(@Sql)

    set @process = 'CW-2028 -- RIA_RecNodeHistory.grab_id PRIMARY KEY'
	set @Sql= 'if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''PK_RIA_RecNodeHistory'')
   ALTER TABLE RIA_RecNodeHistory ADD CONSTRAINT PK_RIA_RecNodeHistory PRIMARY KEY (grab_id)'
    EXEC(@Sql)

    set @process = 'CW-2028 -- Alter SP ccsp_BaseXmngr'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int = 0,
@option int = 0,
@idService int = 0,
@name varchar(25) = NULL,
@top varchar(max) = NULL,
@ids varchar(max)=null,
@dateStart dateTime= null

AS
declare @sql nvarchar(max)
declare @parameterDefinition nvarchar(max)
declare @status tinyint

set @sql = ''''
if @action in(1,6) begin--obtiene los nodos a insertar en BX
	if @option = 2 begin
		if @action = 1 set @status =0
		else if @action = 6 set @status = 2

		set @parameterDefinition =N''@status int, @top int''

		set @sql=''declare @basexName varchar(max)

select @basexName=Xname from ccBaseXDB where serviceId=2 and isFull=0;

with node ( grab_id,xmlString,dateNode)
AS(
	select top(@top) grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
	,isnull(node.value(''''(/R02/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R02/@C06)[1]'''',''''datetime'''')) as dateNode
	from ria_RecNode A with(nolock)
	where A.status =@status
	union
	select top(@top) grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
	,isnull(node.value(''''(/R02/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R02/@C06)[1]'''',''''datetime'''')) as dateNode
	from ria_RecNodeHistory A with(nolock)
	where A.status =@status
)

select node.grab_id,node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
left join ccBaseXDB baseX on baseX.serviceId=2  and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
order by baseX.Xname''
	--print(@sql)
	--exec(@sql)
	EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top

	end
end
if @action in(2,7) begin--actualiza los nodos insertados en BX
	if @option = 2 begin
		if @action = 2 set @status=0
		else if @action = 7 set @status = 2
		set @parameterDefinition =N''@status int''
		set @sql=''update ria_RecNode with(rowlock) set [status] =@status+ 1 , dateOut = getDate() where grab_id in(''+ @ids +'') and [status] = @status''		
		
		EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
		set @sql=''update RIA_RecNodeHistory with(rowlock) set [status] =@status+ 1 , dateOut = getDate() where grab_id in(''+ @ids +'') and [status] = @status''
		
		EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
	end
end
else if @action = 3 begin--trae el nombre de la base de datos en BX
	select Xname from ccBaseXDB where serviceId = @option and isFull=0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
	insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option, @dateStart, @name,0)
end
else if @action = 11 begin--trae el nombre de la base de datos en BX
	if @option =2 begin
		SELECT ISNULL(min(node.value(''(/R02/@CDATE)[1]'',''datetime'')),GETDATE()) as node FROM RIA_RecNode where status = 0
	end
	end
else if @action =12 begin
	declare @replicationName nvarchar(500)
		select @replicationName = name from msdb.dbo.sysjobs where name like ''%-CCRecorderRIA- 0'' and name like ''%SpecialAVRS%''
		exec msdb.dbo.sp_start_job @job_name = @replicationName
		while(
		SELECT count(*) FROM msdb.dbo.sysjobactivity ja
		LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
		INNER JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
		INNER JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
		WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions   ORDER BY agent_start_date DESC)
		AND start_execution_date is not null AND stop_execution_date is null and j.name=@replicationName
	) > 0
	begin
		WAITFOR DELAY ''00:00:10''
	end
end'
    EXEC(@Sql)

    set @process = 'CW-2028 -- Alter SP ccsp_CleanNodeBaseX'
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

    set @process = 'CW-2028 -- JOb CleanNodeBaseXCCRecorderRIA '
	set @Sql= 'USE [msdb]

if exists(select * from msdb.dbo.sysjobs where name=''CleanNodeBaseXCCRecorderRIA'') begin
	EXEC msdb.dbo.sp_delete_job @job_name=N''CleanNodeBaseXCCRecorderRIA'', @delete_unused_schedule=1
end

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 11/09/2018 11:29:05 a. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CleanNodeBaseXCCRecorderRIA'', 
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
/****** Object:  Step [MoveNodeBaseXRecording]    Script Date: 11/09/2018 11:29:05 a. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''MoveNodeBaseXRecording'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''exec ccsp_CleanNodeBaseX '', 
		@database_name=N''CCRecorderRIA'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''CleanNodeBaseXCCRecorderRIA'', 
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

    set @process = 'CW-2358  Alter SP trsp_InsertRecNode'
	set @Sql= 'ALTER procedure [dbo].[trsp_InsertRecNode]
@grabId int,
@type int=0
as
begin

  declare @shoutLevel as nvarchar(20)
 declare @language as int
 declare @start as int
 declare @callType int

 declare @xml as xml
 declare @crmNode as xml
 declare @manual as nvarchar(10)
 declare @rating as nvarchar(20)
 declare @sqlCRM nvarchar(max)
 declare @supervisor as nvarchar(50)
 declare @template as nvarchar(50)
 declare @callID as nvarchar(50)
 declare @isHistory bit
 declare @Prefijo varchar(50)
 set @Prefijo = ''''

 declare @table as nvarchar(20)
 set @table=''RIA''

 /*
  CDATE---> Date Generic
  C01-----> grab_id
  C02-----> Type of Recording (Inbound/Outbound)
  C03-----> Camp/ACD descripcion
  C04-----> ShoutLevel
  C05-----> Agent Login
  C06-----> Formated date
  C07-----> Position Computer
  C08-----> Duration
  C09-----> Ani
  C10-----> Dnis
  C11-----> Calkey
  C12-----> Manual
  C13-----> User ID
  C14-----> cal ID
  C15-----> Cam /ACD ID
  C16-----> Duration Reco@rding as 00:00:00
  C17-----> Position Extension
  C18-----> rating(Scoring Template)
  C19-----> Reposiory ID
  C20-----> Disposition
  C21-----> Disposition ID
  C22-----> Has Video
  C23-----> Agent Full Name
  C24-----> Supervisor Name
  C25-----> Score Template
  C26-----> graphic_id
  C27-----> Prefix recording
  CID-----> CamId
  CType---> Tipo de llamada
 */

 select @language= valor from ccSettings where setting_id = 27



 if exists (select *  from ria_grabacion where grab_id = @grabId   ) begin
		select @isHistory=0,@callType=rec.tipo_llamada
	  ,@Prefijo = rec.Prefijo
	  ,@manual = case when rec.cal_manual = 0 then ''N/A'' else ''Manual'' end
	  ,@shoutlevel =sho.nombre_nivel
	  ,@rating= isnull(total_forma  ,0)
	  ,@callID=cal_id
	 from ria_grabacion rec
	 left join ria_tipo_gritos sho on rec.id_nivel_grito = sho.id_nivel_grito
	 left join (select top 1 total_forma,id_grabacion from ria_formacalif where id_grabacion = @grabId order by fecha_calif desc)  formCalif on formCalif.id_grabacion=rec.grab_id
	 where grab_id = @grabId
 end
 else begin
	 select
	 @isHistory=1,
	 @callType=rec.tipo_llamada,  @manual = case when rec.cal_manual = 0 then ''N/A'' else ''Manual'' end
	  ,@shoutlevel =sho.nombre_nivel
	  ,@rating= isnull(total_forma  ,0)
	  ,@callID=cal_id
	 from RIA_GRABACIONCONSULTA rec
	 left join ria_tipo_gritos sho on rec.id_nivel_grito = sho.id_nivel_grito
	 left join (select top 1 total_forma,id_grabacion from ria_formacalif where id_grabacion = @grabId order by fecha_calif desc)  formCalif on formCalif.id_grabacion=rec.grab_id
	 where grab_id = @grabId
 end




 --Languages 0 spanish 1 english
 select @shoutlevel=case when @language =0 then substring(@shoutlevel,0,@start) else  substring(@shoutlevel,(@start+1),(LEN(@shoutlevel)-1)) end


 select @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
   RIA_FORMATOS as formatos
   inner join RIA_FORMACALIF formatosCalif on formatosCalif.id_formato=formatos.id_formato
   inner join RIA_GRABACION grabacion  on grabacion.grab_id= formatosCalif.id_grabacion
   inner join ccUsers supervisor on supervisor.User_id = formatosCalif.id_supervisor
   where grabacion.grab_id=@grabId and formatosCalif.tipo=1

if @isHistory=0 begin

 set @xml = (
	 select * from (
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	   ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27'',rec.cam_id as ''@CID'',rec.tipo_llamada AS ''@CType''
	   	   from
	   ria_grabacion rec
	   inner join ccinbound inb on rec.cam_id = inb.Inbound_id and rec.tipo_llamada  = 1
	   inner join ccUsers usr on usr.User_id = rec.age_id
	   inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	   left join ccTipoCalif AS e  ON rec.calif_id = e.calif_id
	   inner join ccRIAInboundGraph grap on grap.Inbound_id=inb.Inbound_id
	   where rec.grab_id = @grabId
	  union
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'',inb.cam_descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'',convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.Description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	  ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27'',rec.cam_id as ''@CID'',rec.tipo_llamada AS ''@CType''
	   from
	  ria_grabacion rec
	  inner join cccamps inb on rec.cam_id = inb.cam_id and rec.tipo_llamada  = 2
	  inner join ccUsers usr on usr.User_id = rec.age_id
	  inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	  left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
	  inner join ccRIACampsGraph grap on grap.cam_id=inb.cam_id
	  where rec.grab_id = @grabId  )x
	  for xml path(''R02'')
	 )
 end
 else begin
	 set @xml = (
	 select * from (
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	   ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27'',rec.cam_id as ''@CID'',rec.tipo_llamada AS ''@CType''
	   from
	   RIA_GRABACIONCONSULTA rec
	   inner join ccinbound inb on rec.cam_id = inb.Inbound_id and rec.tipo_llamada  = 1
	   inner join ccUsers usr on usr.User_id = rec.age_id
	   inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	   left join ccTipoCalif AS e  ON rec.calif_id = e.calif_id
	   inner join ccRIAInboundGraph grap on grap.Inbound_id=inb.Inbound_id
	   where rec.grab_id = @grabId
	  union
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'',inb.cam_descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'',convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.Description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	  ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27'',rec.cam_id as ''@CID'',rec.tipo_llamada AS ''@CType''
	   from
	  RIA_GRABACIONCONSULTA rec
	  inner join cccamps inb on rec.cam_id = inb.cam_id and rec.tipo_llamada  = 2
	  inner join ccUsers usr on usr.User_id = rec.age_id
	  inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	  left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
	  inner join ccRIACampsGraph grap on grap.cam_id=inb.cam_id
	  where rec.grab_id = @grabId  )x
	  for xml path(''R02'')
	 )
 end

if @xml is not null begin
	select @crmNode = node from ccCRMNodes where [type]= @callType and cal_id=@callID
	if @crmNode is not null begin
		update ccCRMNodes set grab_id=@grabId where [type]=@callType and cal_id=@callID
		set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(max),@crmNode)+'' into(/R02)[1]'''') ''
		execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
	end

  if exists(select * from RIA_RecNodeHistory where grab_id=@grabId) begin
	update RIA_RecNodeHistory set node =@xml,[status]=2 where grab_id = @grabId
  end
  else if not exists(select * from ria_RecNode where grab_id=@grabId) begin
	insert into ria_RecNode (grab_id,node,dateIn,[status]) values (@grabId,@xml, getdate(),0)
  end
  else begin
	update ria_RecNode set node =@xml,[status]=2 where grab_id = @grabId
	end
	--select @xml
 end
end'
    EXEC(@Sql)
		
------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	select par_valor from trec_parametros where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end
 else begin
	select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
