/*
Autor: Carlos Chavez
Descripcion:


Version requerida: 42
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 43
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

	
	set @process = 'CW-1380 -- Alter SP ccsp_BaseXmngr'
 	set @sql ='ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int = 0,
@option int = 0,
@idService int = 0,
@name varchar(25) = NULL,
@top varchar(max) = NULL,
@ids varchar(max)=null,
@dateStart dateTime= null

AS
declare @sql nvarchar(max)
declare @status tinyint

set @sql = ''''
if @action in(1,6) begin--obtiene los nodos a insertar en BX
	if @option = 2 begin
		if @action = 1 set @status =0
		else if @action = 6 set @status = 2
		set @sql=''declare @basexName varchar(max)

select @basexName=Xname from ccBaseXDB where serviceId=2 and isFull=0;

		with node ( grab_id,xmlString,dateNode)
AS(
	select top('' + @top + '') grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
	,isnull(node.value(''''(/R02/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R02/@C06)[1]'''',''''datetime'''')) as dateNode
	from ria_RecNode A with(rowlock)
	where A.status ='''''' + cast(@status as nvarchar(max)) +''''''
	union
	select top('' + @top + '') grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
	,isnull(node.value(''''(/R02/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R02/@C06)[1]'''',''''datetime'''')) as dateNode
	from ria_RecNodeHistory A with(rowlock)
	where A.status ='''''' + cast(@status as nvarchar(max)) +'' ''''
)

select node.grab_id,node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
left join ccBaseXDB baseX on baseX.serviceId=2  and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
order by baseX.Xname''
		--print(@sql)
		exec(@sql)
	end
end
if @action in(2,7) begin--actualiza los nodos insertados en BX
	if @option = 2 begin
		if @action = 2 set @status=0
		else if @action = 7 set @status = 2
		set @sql=''update ria_RecNode with(rowlock) set [status] =''+CAST(@status as varchar(max)) +'' + 1 , dateOut = getDate() where grab_id in(''+ @ids +'') and [status] = ''+CAST(@status as varchar(max))		
		exec(@sql)
		set @sql=''update RIA_RecNodeHistory with(rowlock) set [status] =''+CAST(@status as varchar(max)) +'' + 1 , dateOut = getDate() where grab_id in(''+ @ids +'') and [status] = ''+CAST(@status as varchar(max))
		exec(@sql)
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
		WAITFOR DELAY ''00:00:01''
	end
end'
	
	EXEC(@sql)

	set @process = 'CW-1380'
 	set @sql =''
	
	EXEC(@sql)

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
