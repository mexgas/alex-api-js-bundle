set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
    Set @Version = 101
    Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
    begin tran
    begin try

	-------------------------------------------------BEGIN MACL-------------------------------------------------
    SET @process = 'Se modifica el sp trsp_InsertRecNodeGrabIds para crear el nodo con la info de las campañas de AI'
    SET @sql = '
ALTER PROCEDURE [dbo].[trsp_InsertRecNodeGrabIds]
@grabIds varchar(8000),
@rateEvaluationFormatKolob int = -1
AS
BEGIN
    declare @grabIdTmp table(grabId bigint primary key)
    declare @tEvaluationTmp table(grabId bigint primary key,total float)    
    DECLARE @XMLTable TABLE (grab_id INT, dateIn datetime, [node] xml, [status] bit);
	DECLARE @InboudAI int = 11, @OutboundAI int = 10
    
    DECLARE @RecNodeTable TABLE (
    Date datetime,
    CDATE VARCHAR(23),  -----> Date Generic
    CID int,            -----> CamId
    CType int,          -----> Tipo de llamada
    C01 bigint,         -----> grab_id
    C02 VARCHAR(50),    -----> Type of Recording (Inbound/Outbound)
    C03 VARCHAR(250),   -----> Camp/ACD descripcion
    C04 INT,            -----> ShoutLevel
    C05 VARCHAR(250),   -----> Agent Login
    C06 VARCHAR(50),    -----> Formated date
    C07 VARCHAR(50),    -----> Position Computer
    C08 VARCHAR(50),    -----> Duration
    C09 VARCHAR(50),    -----> Ani
    C10 VARCHAR(50),    -----> Dnis
    C11 VARCHAR(100),   -----> Calkey
    C12 VARCHAR(50),    -----> Manual
    C13 INT,            -----> User ID
    C14 int,            -----> cal ID
    C15 INT,            -----> Cam /ACD ID
    C16 VARCHAR(12),    -----> Duration Reco@rding as 00:00:00
    C17 INT,            -----> Position Extension
    C18 VARCHAR(50),    -----> rating(Scoring Template)
    C19 INT,            -----> Reposiory ID
    C20 VARCHAR(250),   -----> Disposition
    C21 INT,            -----> Disposition ID
    C22 TINYINT,        -----> Has Video
    C23 VARCHAR(300),   -----> Agent Full Name
    C24 VARCHAR(300),   -----> Supervisor Name
    C25 VARCHAR(250),   -----> Score Template
    C26 INT,            -----> graphic_id
    C27 VARCHAR(250),   -----> Prefix recording
    C28 VARCHAR(250),   -----> subDisposition
    C29 BIT,            -----> LLamada Grabada --@extraInfo 1 Record, 0 Dont Record
    C30 BIT,            ------> LLamada VoiceMail @extraInfo 2
	C31 VARCHAR(250)    ------> AI Model Name
);
insert into @grabIdTmp
select value from  dbo.fn_RIASplitDelimited(@grabIds,'','')


if @rateEvaluationFormatKolob = 0 begin
    ;with maxFechaCalif as(
    select max(fecha_calif) as fecha_calif,B.grabId from ria_formacalif A 
    inner join @grabIdTmp B on A.id_grabacion=B.grabId
    group by B.grabId
    ), ria_formacalifTop as(
    select A.grabId,B.total_forma from maxFechaCalif A
    inner join ria_formacalif B on A.grabId=B.id_grabacion and A.fecha_calif=B.fecha_calif
    )
    insert into @tEvaluationTmp
    select * from ria_formacalifTop
end
else if @rateEvaluationFormatKolob = 1 begin
    insert into @tEvaluationTmp
    SELECT A.grab_id,AVG(totalPoints) FROM RECORDERRIA_RECORDINGEVALUATION  A
    inner join @grabIdTmp T on A.grab_id=T.grabId
    WHERE deleted != 1 
    group by A.grab_id
end

;with GrabacionSource AS (
    SELECT rec.grab_id, rec.tipo_llamada, rec.Prefijo, rec.cal_manual, rec.id_nivel_grito, 
    rec.cal_id, rec.finicio, rec.extra_info, rec.extra_info2, rec.video, 
    isnull(E.total,0) AS total_forma
    ,calif_id,cam_id,duracion,ani,dni,cal_key,id_repositorio,califSub_id,age_id
    ,cal_extension, rec.virtualAgentId
    FROM ria_grabacion rec with(nolock)
    inner join @grabIdTmp t on rec.grab_id=t.grabId
    left join @tEvaluationTmp E on t.grabId=E.grabId    
    UNION ALL
    SELECT rec.grab_id, rec.tipo_llamada, '''' AS Prefijo, rec.cal_manual, rec.id_nivel_grito, 
    rec.cal_id, rec.finicio, rec.extra_info, rec.extra_info2, NULL AS video,
    isnull(E.total,0) AS total_forma
    ,calif_id,cam_id,duracion,ani,dni,cal_key,id_repositorio,califSub_id,age_id
    ,cal_extension, rec.virtualAgentId
    FROM RIA_GRABACIONCONSULTA rec with(nolock)
    inner join @grabIdTmp t on rec.grab_id=t.grabId
    left join @tEvaluationTmp E on t.grabId=E.grabId
)
INSERT INTO @RecNodeTable
SELECT 
rec.finicio,
CONVERT(VARCHAR(23), rec.finicio, 126) AS ''@CDATE'',
rec.cam_id AS ''@CID'',

CASE WHEN rec.tipo_llamada = 1 THEN
	CASE WHEN rec.virtualAgentId > 0 THEN @InboudAI ELSE rec.tipo_llamada END
	ELSE CASE WHEN rec.virtualAgentId > 0 THEN @OutboundAI ELSE rec.tipo_llamada END END
AS ''@CType'',

rec.grab_id AS ''@C01'',
CASE WHEN rec.tipo_llamada = 1 THEN ''Inbound'' ELSE ''Outbound'' END AS ''@C02'',
CASE WHEN rec.tipo_llamada = 1 THEN inb.descripcion ELSE outb.cam_descripcion END AS ''@C03'',
ISNULL(rec.id_nivel_grito, -1) AS ''@C04'',
CASE WHEN ISNULL(rec.virtualAgentId, 0) > 0 THEN '''' ELSE
ISNULL(usr.LOGIN, ''N/A'') END AS ''@C05'',
CONVERT(VARCHAR(23), rec.finicio, 126) AS ''@C06'',
pos.Computer AS ''@C07'',
CONVERT(NVARCHAR(10), rec.duracion) AS ''@C08'',
rec.ani AS ''@C09'',
rec.dni AS ''@C10'',
rec.cal_key AS ''@C11'',
CASE WHEN rec.cal_manual = 0 THEN ''N/A'' ELSE ''Manual'' END AS ''@C12'',
ISNULL(usr.[User_id], 0) AS ''@C13'',
rec.cal_id AS ''@C14'',
rec.cam_id AS ''@C15'',
CONVERT(CHAR(8), DATEADD(SECOND, rec.duracion, 0), 108) AS ''@C16'',
ISNULL(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END, -1) AS ''@C17'',
ISNULL(rec.total_forma, 0) AS ''@C18'',
rec.id_repositorio AS ''@C19'',
case when rec.calif_id<=0 then ''N/A'' when rec.tipo_llamada = 1 then e.description  when rec.tipo_llamada = 2 then eOut.Description end  AS ''@C20'',
rec.calif_id AS ''@C21'',
rec.video AS ''@C22'',
ISNULL(usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno, CASE WHEN ISNULL(rec.virtualAgentId, 0) > 0 THEN '''' ELSE ''N/A'' END) AS ''@C23'',
'''' AS ''@C24'',
'''' AS ''@C25'',
isnull(grap.graphic_id,1) AS ''@C26'',
rec.Prefijo AS ''@C27'',    
case when  rec.califSub_id<=0 then ''N/A'' when rec.tipo_llamada = 1 then subDisposition.califSubDesc  when rec.tipo_llamada = 2 then subDispositionOut.califSubDesc end  AS ''@C28'',    
CONVERT(BIT, ISNULL(rec.extra_info, ''1'')) AS ''@C29'',
CONVERT(BIT, ISNULL(rec.extra_info2, ''0'')) AS ''@C30'',
CASE WHEN ISNULL(rec.virtualAgentId, 0) > 0 THEN va.nameAgent ELSE '''' END AS ''@C31''
FROM GrabacionSource rec
LEFT JOIN ccinbound inb ON rec.cam_id = inb.Inbound_id AND rec.tipo_llamada = 1
LEFT JOIN cccamps outb ON rec.cam_id = outb.cam_id AND rec.tipo_llamada = 2
LEFT JOIN ccUsers usr ON usr.User_id = rec.age_id
LEFT JOIN ccPosicion pos ON pos.pos_id = rec.cal_extension * -1
LEFT JOIN ccTipoCalif AS e ON rec.calif_id = e.calif_id AND rec.tipo_llamada = 1
LEFT JOIN ccTipoCalifOUT AS eOut ON rec.calif_id = eOut.calif_id AND rec.tipo_llamada = 2
LEFT JOIN cctipocalifsub AS subDisposition ON rec.califSub_id = subDisposition.califSub_id
LEFT JOIN cctipocalifsubout AS subDispositionOut ON rec.califSub_id = subDispositionOut.califSub_id AND rec.tipo_llamada = 2
LEFT JOIN ccRIAInboundGraph grap ON grap.Inbound_id = inb.Inbound_id AND rec.tipo_llamada = 1
LEFT JOIN ccRIACampsGraph grapOut ON grapOut.cam_id = outb.cam_id AND rec.tipo_llamada = 2
LEFT JOIN ccVirtualAgent va ON rec.virtualAgentId = va.idAgent


insert into @XMLTable (grab_id,status, dateIn, node)       
SELECT  
    C01,0 [status],[date],
    case when C03 is null then null 
    when (C30=0 and C05 is not null and C20 is not null and C28 is not null) or  (C30=1) then   
    (
        SELECT 
            CDATE AS "@CDATE",
            CID As "@CID",
            CType As "@CType",
            C01 AS "@C01",
            C02 AS "@C02",
            C03 AS "@C03",
            C04 AS "@C04",
            C05 AS "@C05",
            C06 AS "@C06",
            C07 AS "@C07",
            C08 AS "@C08",
            C09 AS "@C09",
            C10 AS "@C10",
            C11 AS "@C11",
            C12 AS "@C12",
            C13 AS "@C13",
            C14 AS "@C14",
            C15 AS "@C15",
            C16 AS "@C16",
            C17 AS "@C17",
            C18 AS "@C18",
            C19 AS "@C19",
            C20 AS "@C20",
            C21 AS "@C21",
            C22 AS "@C22",
            C23 AS "@C23",
            C24 AS "@C24",
            C25 AS "@C25",
            C26 AS "@C26",
            C27 AS "@C27",
            C28 AS "@C28",
            C29 AS "@C29",
            C30 AS "@C30",
			C31 AS "@C31"
        FROM @RecNodeTable AS innerTable
        WHERE innerTable.C01 = outerTable.C01       
        FOR XML PATH(''R02''), TYPE
    ) 
    end AS node
FROM @RecNodeTable AS outerTable;


INSERT INTO ria_RecNode (grab_id, node, dateIn, [status]) 
select X.grab_id,X.[node],X.dateIn,-1 from @XMLTable X
left join ria_RecNode R on R.grab_id=X.grab_id
where X.node is null and R.grab_id is null

delete  from @XMLTable where node is null

update h set h.node=t.node,h.status=2
from RIA_RecNodeHistory h with(nolock)
inner join @XMLTable t on h.grab_id=t.grab_id and t.node is not null

update t set t.status=1
from RIA_RecNodeHistory h with(nolock)
inner join @XMLTable t on h.grab_id=t.grab_id and t.node is not null

if exists(select 1 from @XMLTable where status=0) begin
    update h set h.node=t.node,h.status=2
    from ria_RecNode h with(nolock)
    inner join @XMLTable t on h.grab_id=t.grab_id

    update t set t.status=1
    from ria_RecNode h with(nolock)
    inner join @XMLTable t on h.grab_id=t.grab_id
end
if exists(select 1 from @XMLTable where status=0) begin
    INSERT INTO ria_RecNode (grab_id, node, dateIn, [status]) 
    select grab_id,[node],dateIn,0 from @XMLTable where status=0    
end

END'
    EXEC(@sql)

	-------------------------------------------------BEGIN MAGV-------------------------------------------------
	SET @process = 'Se modifica el sp ccsp_BaseXmngr para filtrar por status en el action in (1,6)'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
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
								where serviceId = 2 and isFull = 0;

								with nodeA as (
									select top(@top) 
										grab_id,
										node,
										isnull(node.value(''''(/R02/@CDATE)[1]'''', ''''datetime''''), node.value(''''(/R02/@C06)[1]'''', ''''datetime'''')) as dateNode
									from ria_RecNode with(nolock)
									where status = @status
								
								),
								nodeB as (
									select top(@top) 
										grab_id,
										node,
										isnull(node.value(''''(/R02/@CDATE)[1]'''', ''''datetime''''), node.value(''''(/R02/@C06)[1]'''', ''''datetime'''')) as dateNode
									from ria_RecNodeHistory with(nolock)
									where status = @status
	
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
