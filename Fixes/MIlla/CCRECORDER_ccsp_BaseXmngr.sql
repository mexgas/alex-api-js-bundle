USE [CCRecorderRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_BaseXmngr]    Script Date: 28/02/2024 10:27:11 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
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

set @sql = ''
if @action in(1,6) begin--obtiene los nodos a insertar en BX
	if @option = 2 begin
		if @action = 1 set @status =0
		else if @action = 6 set @status = 2

		set @parameterDefinition =N'@status int, @top int'

		set @sql='declare @basexName varchar(max)

select @basexName=Xname from ccBaseXDB where serviceId=2 and isFull=0;

with node ( grab_id,xmlString,dateNode)
AS(
	select top(@top) grab_id, replace(replace(convert(nvarchar(max),node),''{'',''&#123;''),''}'',''&#125;'') xmlString
	,dateIn as dateNode
	from ria_RecNode A with(nolock)
	where A.status =@status
	union
	select top(@top) grab_id, replace(replace(convert(nvarchar(max),node),''{'',''&#123;''),''}'',''&#125;'') xmlString
	,dateIn as dateNode
	from ria_RecNodeHistory A with(nolock)
	where A.status =@status
)

select node.grab_id,node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
left join ccBaseXDB baseX on baseX.serviceId=2  and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
order by baseX.Xname'
	print(@sql)
	--exec(@sql)
	EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top

	end
end
if @action in(2,7) begin--actualiza los nodos insertados en BX
	if @option = 2 begin
		if @action = 2 set @status=0
		else if @action = 7 set @status = 2
		set @parameterDefinition =N'@status int'
		set @sql='update ria_RecNode with(rowlock) set [status] =@status+ 1 , dateOut = getDate() where grab_id in('+ @ids +') and [status] = @status'		
		
		EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
		set @sql='update RIA_RecNodeHistory with(rowlock) set [status] =@status+ 1 , dateOut = getDate() where grab_id in('+ @ids +') and [status] = @status'
		
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
		SELECT ISNULL(min(node.value('(/R02/@CDATE)[1]','datetime')),GETDATE()) as node FROM RIA_RecNode where status = 0
	end
	end
else if @action =12 begin
	declare @replicationName nvarchar(500)
		select @replicationName = name from msdb.dbo.sysjobs where name like '%-CCRecorderRIA- 0' and name like '%SpecialAVRS%'
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
		WAITFOR DELAY '00:00:10'
	end
end