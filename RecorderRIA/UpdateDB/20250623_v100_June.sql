set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
    Set @Version = 100
    Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
    begin tran
    begin try

	
	SET @process = 'CW-9760 Drop sp ccsp_BaseXmngr'
    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_BaseXmngr'')
    begin
        DROP PROCEDURE ccsp_BaseXmngr;
    end'
    EXEC(@sql)

	SET @process = 'CW-9760 Create sp ccsp_BaseXmngr'
    SET @sql = '
	
CREATE PROCEDURE ccsp_BaseXmngr
@action int = 0,
@option int = 0,
@idService int = 0,
@name varchar(25) = NULL,
@top varchar(max) = NULL,
@ids varchar(max)=null,
@dateStart dateTime= null,
@grabIds varchar(4000) = null

AS
declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
declare @parameterDefinition nvarchar(max)
declare @status tinyint

set @sql = ''''
if @action in(1,6) begin--obtiene los nodos a insertar en BX
	if @option = 2 begin
		if @action = 1 set @status =0
		else if @action = 6 set @status = 2

		set @parameterDefinition =N''@status int, @top int''

		set @sql=''declare @basexName varchar(25)
							select @basexName = Xname 
							from ccBaseXDB 
							where serviceId = @status and isFull = 0;

							with nodeA as (
								select top(@top) 
									grab_id,
									node,
									isnull(node.value(''''(/R02/@CDATE)[1]'''', ''''datetime''''), node.value(''''(/R02/@C06)[1]'''', ''''datetime'''')) as dateNode
								from ria_RecNode with(nolock)
								
							),
							nodeB as (
								select top(@top) 
									grab_id,
									node,
									isnull(node.value(''''(/R02/@CDATE)[1]'''', ''''datetime''''), node.value(''''(/R02/@C06)[1]'''', ''''datetime'''')) as dateNode
								from ria_RecNodeHistory with(nolock)
	
							),
							combinedNodes as (
								select grab_id, node, dateNode from nodeA
								union all
								select grab_id, node, dateNode from nodeB
							),
							formattedNodes as (
								select 
									grab_id,
									replace(replace(convert(nvarchar(max), node), ''''{'''', ''''&#123;''''), ''''}'''', ''''&#125;'''') as xmlString,
									dateNode
								from combinedNodes
							)
							select 
								fn.grab_id,
								fn.xmlString,
								isnull(b.Xname, @basexName) as Xname
							from formattedNodes fn
							left join ccBaseXDB b 
								on b.serviceId = 2 
								and fn.dateNode between b.dateStart and isnull(b.dateEnd, getdate())
							order by b.Xname''
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
end

else if @action = 13 begin
	set @sql = ''''
	select @tableName=''RIA_RecNode'',@tableNameHistory=''RIA_RecNodeHistory'',@columnId=''grab_id''
	set @sql=''
	;
	with duplicateIds as(
	select ''+@columnId+'',dateIn from ''+@tableName+'' where ''+@columnId+'' in(''+@grabIds+'')
	union
	select ''+@columnId+'',dateIn from ''+@tableNameHistory+'' where ''+@columnId+'' in(''+@grabIds+'')
	)

	select A.''+@columnId+'' as Id,min(B.Xname) Xname from duplicateIds A
	inner join ccbasexDB B on B.serviceId=2 and( A.dateIn between B.dateStart and B.dateEnd or A.dateIn>= B.dateStart)
	group by A.''+@columnId+'',A.dateIn
	Having count(*)>1
	order by Xname
	''
	exec (@sql)

end

else if @action = 14 begin

	if exists(
	select id,serviceId,dateStart,dateEnd,Xname,isFull
	FROM ccBaseXDB 
	WHERE serviceId=2
	)select 1
	else select 0

end'
    EXEC(@sql)

	SET @process = 'CW-9760 create table  ccsp_BaseXmngr'
    SET @sql = '
	if not exists (select * from sys.tables where name = N''ccBaseXDB'')
    begin
        CREATE TABLE ccBaseXDB (
            id INT NOT NULL,
            serviceId INT NULL,
            dateStart DATETIME NULL,
            dateEnd DATETIME NULL,
            Xname VARCHAR(25) NULL,
            isFull BIT NULL
        );
    end'
    EXEC(@sql)
	

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