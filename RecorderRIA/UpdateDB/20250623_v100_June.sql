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
	SET @process = 'CW-9760 delete table  ccBaseXDB'
    SET @sql = '
	   IF EXISTS (
		SELECT 1
		FROM sys.columns c
		INNER JOIN sys.tables t ON c.object_id = t.object_id
		WHERE t.name = N''ccBaseXDB''
		  AND c.name = N''id''
		  AND c.is_identity = 1
	)
	BEGIN
	 DROP TABLE ccBaseXDB;
	END'
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

    
--------------------------------- Begin   Jesus Gallardo .31 tickets #1867 ----------------------------------------------------------


	SET @process = 'ALTER PROCEDURE [dbo].[trsp_AdmRecGetWGforSearch] remove replica WorkGroup_Calid'
    SET @sql = 'ALTER PROCEDURE [dbo].[trsp_AdmRecGetWGforSearch]
@Cal_id int,
@User_id int,
@CallType int



AS
BEGIN

SET NOCOUNT ON;

declare @IdWG varchar(1000)

select  @IdWG=IDWG from RIA_GRABACION where cal_id=@Cal_id and age_id=@User_id 
and tipo_llamada=@CallType+1

select convert(smallint, Value) as IDWG from dbo.fn_RIASplitDelimited(@IdWG,'','')


END'
    EXEC(@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchAllRecs] remove replica WorkGroup_Calid'
    SET @sql = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchAllRecs]
@Sup_id int,
@Finicio datetime,
@Ffin datetime,
@UserList varchar(MAX) =null,
@IDWGList varchar(MAX) =null,
@TypeCall int = null,
@CampaingsList varchar(MAX) =null,
@ACDList varchar(MAX) =null,
@DispositionList varchar(MAX) =null,
@SubdispositionList varchar(MAX) =null

AS
BEGIN

SET NOCOUNT ON

declare @sql1 nvarchar(max)

--Tabla con toda la informaciom
CREATE TABLE #tempRiAAllInfo(
    cal_id int,
    tipo_llamada smallint,
    cam_id smallint,
    calif_id smallint,
    duracion int,
    id_nivel_grito int,
    [user_id] int,
    finicio datetime,
    ani varchar (100),
    dni varchar (100),
    cal_key varchar (100),
    cal_manual tinyint, 
    posicion int,
    computer varchar(100),
    total_forma int,
    id_repositorio tinyint,
    score varchar (100),
    formato_duracion varchar(15),
    grab_id bigint,
    IDWG varchar (800),
    califSub_id varchar(800),
    cal_tMoh smallint
)   

CREATE CLUSTERED INDEX [IX_tempRiAAllInfodate] ON [#tempRiAAllInfo]
(         
[finicio] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]


create table #auxOutbound(
        cal_id int,
    tipo_llamada smallint,
    cam_id smallint,
    calif_id smallint,
    duracion int,
    id_nivel_grito int,
    [user_id] int,
    finicio datetime,
    ani varchar (100),
    dni varchar (100),
    cal_key varchar (100),
    cal_manual tinyint, 
    posicion int,
    computer varchar(100),
    total_forma int,
    id_repositorio tinyint,
    score varchar (100),
    formato_duracion varchar(15),
    grab_id bigint,
    IDWG varchar (800),
    califSub_id  varchar(800),
    cal_tMoh smallint
    )

--Segmento de Calificaciones
create table #tempRiaFormaCalif6(
id_grabacion bigint,
total_forma int)

insert into #tempRiaFormaCalif6 (id_grabacion,total_forma)
select r.id_grabacion, avg(r.total_forma) as total_forma
from ria_formacalif r
inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t
on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
group by r.id_grabacion


--Segmento de Supervisor
create table #tempCampEspWG6(
IdCampEsp smallint,
Tipo smallint,
[user_id] smallint,
IDWG smallint)

CREATE NONCLUSTERED INDEX [IX_tempCampEspWG6] ON [#tempCampEspWG6] 
(
[user_id] ASc
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]

insert into #tempCampEspWG6 (IdCampEsp,Tipo,user_id,IDWG)
  select distinct a.IdCampEsp, a.Tipo as Tipo_llamada,b.User_id,a.IDWG
from ccRIACampEspWG a
inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = @Sup_id and a.IDWG = b.IDWG     

--Segmento de usurios asociados al supervisor                
create table #tempComplete6(
IdCampEsp smallint,
Tipo smallint,
[user_id] int,
IDWG smallint)                 

CREATE NONCLUSTERED INDEX [IX_tempComplete6User] ON [#tempComplete6] 
(         
[user_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]



if @UserList is not null and @UserList <> ''''
BEGIN
    set @sql1=''insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)
            select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
            from ccRIACampEspWG a  inner join 
            (select IDWG,user_id from ccRIAWorkGroupUsers where IDWG in 
            (select  distinct a.IDWG from ccRIACampEspWG a
                        inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = ''+cast(@Sup_id as nvarchar(max))+'' and a.IDWG = b.IDWG
            )and user_id <> ''+cast(@Sup_id as nvarchar(max))+'' and user_id in (''+@UserList+'')
            ) b on a.IDWG=b.IDWG''
    exec (@sql1)
    
END
else
BEGIN
    insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)  
    select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
    from  ccRIACampEspWG a  inner join
    (select IDWG,user_id from ccRIAWorkGroupUsers where IDWG in 
        (select  distinct a.IDWG from ccRIACampEspWG a
            inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = @Sup_id and a.IDWG = b.IDWG
            )and user_id <> @Sup_id 
    ) b on a.IDWG=b.IDWG
END


if @TypeCall is not null and @TypeCall <> ''''
    BEGIN
        if @TypeCall=1 -- Only Inbound 
            BEGIN
                set @sql1 =''
                insert into #tempRiAAllInfo
                select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                            finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                            isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                            isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                            isnull (f.description,'''''''')  AS score,
                            CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                            grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))           
                left join ccTipoCalif AS f ON a.calif_id = f.calif_id           
                left join cctipocalifsub p on p.califSub_id=a.califSub_id
                left join ccPosicion b on b.pos_id = a.cal_extension * -1               
                left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
                inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id  
                where'' 
                if @IDWGList is not null and @IDWGList <> '''' 
                    set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                '' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                else
                    --set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                    set @sql1 = @sql1 + ''  a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
    
                if @ACDList is not null and @ACDList <> ''''
                    set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''                         
        
                if @DispositionList is not null and @DispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                if @SubdispositionList is not null and @SubdispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                --print @sql1
                exec (@sql1)

                set @sql1 =''
                insert into #tempRiAAllInfo
                select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                            finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                            isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                            isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                            isnull (f.description,'''''''')  AS score,
                            CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                            grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))           
                left join ccTipoCalif AS f ON a.calif_id = f.calif_id           
                left join cctipocalifsub p on p.califSub_id=a.califSub_id
                left join ccPosicion b on b.pos_id = a.cal_extension * -1               
                left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
                inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id  
                where'' 
                if @IDWGList is not null and @IDWGList <> '''' 
                    set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                '' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                else
                    --set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                    set @sql1 = @sql1 + '' a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                                        
                if @ACDList is not null and @ACDList <> ''''
                    set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' 
            
                if @DispositionList is not null and @DispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                if @SubdispositionList is not null and @SubdispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                --print @sql1
                exec (@sql1)

                if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where finicio BETWEEN cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) )> 0
                    begin
                        set @sql1 =''
                        insert into #tempRiAAllInfo
                        select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                isnull (f.description,'''''''')  AS score,
                                CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))           
                        left join ccTipoCalif AS f ON a.calif_id = f.calif_id           
                        left join cctipocalifsub p on p.califSub_id=a.califSub_id
                        left join ccPosicion b on b.pos_id = a.cal_extension * -1                       
                        left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                        left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
                        inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id  
                        where'' 
        
                        if @IDWGList is not null and @IDWGList <> '''' 
                            set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                    '' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                        else
                            set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                            
            
                        if @ACDList is not null and @ACDList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''
            
                        if @DispositionList is not null and @DispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                        if @SubdispositionList is not null and @SubdispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''
                                                                        
                        set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                        --print @sql1
                        exec (@sql1)

                        set @sql1 =''
                        insert into #tempRiAAllInfo
                        select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                    finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                    isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                    isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                    isnull (f.description,'''''''')  AS score,
                                    CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                    grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))           
                        left join ccTipoCalif AS f ON a.calif_id = f.calif_id           
                        left join cctipocalifsub p on p.califSub_id=a.califSub_id
                        left join ccPosicion b on b.pos_id = a.cal_extension * -1                       
                        left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                        left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
                        inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id  
                        where'' 
        
                        if @IDWGList is not null and @IDWGList <> '''' 
                            set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                    '' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                        else
                            set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                                    
                        if @ACDList is not null and @ACDList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''             
            
                        if @DispositionList is not null and @DispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                        if @SubdispositionList is not null and @SubdispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''
                                                                        
                        set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                        --print @sql1
                        exec (@sql1)
                    end
            END
        ELSE
            BEGIN --Only Outbound
                set @sql1 =''
                insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)      
                select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                isnull (e.description,'''''''')  AS score,
                                CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
                left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id            
                left join cctipocalifsubout k on k.califSub_id=a.califSub_id        
                left join ccPosicion b on b.pos_id = a.cal_extension * -1               
                left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion         
                left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
                where'' 

                if @IDWGList is not null and @IDWGList <> '''' 
                    set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                '' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                else
                    --set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                    set @sql1 = @sql1 + ''  a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
            
                if @CampaingsList is not null and @CampaingsList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''                           
    
                if @DispositionList is not null and @DispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                if @SubdispositionList is not null and @SubdispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''                               

                set @sql1 = @sql1 + '' and a.tipo_llamada=2''
                --print @sql1
                exec (@sql1)

                insert into #tempRiAAllInfo
                select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
                inner join #tempComplete6 U  on a.user_id=U.user_id

                insert into #tempRiAAllInfo
                select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
                inner join #tempCampEspWG6 U  on a.user_id=U.user_id
    
    
                if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where finicio BETWEEN cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) )> 0
                    begin
                        set @sql1 =''
                        insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
                                    finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                    id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)      
                        select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                        finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                        isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                        isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                        isnull (e.description,'''''''')  AS score,
                                        CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                        grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
                        left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id            
                        left join cctipocalifsubout k on k.califSub_id=a.califSub_id        
                        left join ccPosicion b on b.pos_id = a.cal_extension * -1                       
                        left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion         
                        left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
                        where'' 
        
                        if @IDWGList is not null and @IDWGList <> '''' 
                            set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                    '' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                        else
                            set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                                                            
                        if @CampaingsList is not null and @CampaingsList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''                           
            
                        if @DispositionList is not null and @DispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                        if @SubdispositionList is not null and @SubdispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''       
                                                                                                    
                        set @sql1 = @sql1 + '' and a.tipo_llamada=2''
                        --print @sql1
                        exec (@sql1)

                        insert into #tempRiAAllInfo
                        select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                        finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
                        inner join #tempComplete6 U  on a.user_id=U.user_id

                        insert into #tempRiAAllInfo
                        select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                        finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
                        inner join #tempCampEspWG6 U  on a.user_id=U.user_id
            
                    end
            END
    END
ELSE
    BEGIN --NOT Inbound or Outbound this mean both
                set @sql1 =''
                insert into #tempRiAAllInfo
                select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                            finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                            isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                            isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                            isnull (f.description,'''''''')  AS score,
                            CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                            grab_id as grabID, a.IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))           
                left join ccTipoCalif AS f ON a.calif_id = f.calif_id           
                left join cctipocalifsub p on p.califSub_id=a.califSub_id
                left join ccPosicion b on b.pos_id = a.cal_extension * -1               
                left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id  
                where'' 
                if @IDWGList is not null and @IDWGList <> '''' 
                    set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                '' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                else
                    --set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                    set @sql1 = @sql1 + '' a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
    
                if @ACDList is not null and @ACDList <> ''''
                    set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''                         
    
                if @DispositionList is not null and @DispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                if @SubdispositionList is not null and @SubdispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''   
            
                set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                print @sql1
                exec (@sql1)

                set @sql1 =''
                insert into #tempRiAAllInfo
                select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                            finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                            isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                            isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                            isnull (f.description,'''''''')  AS score,
                            CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                            grab_id as grabID, a.IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))           
                left join ccTipoCalif AS f ON a.calif_id = f.calif_id           
                left join cctipocalifsub p on p.califSub_id=a.califSub_id
                left join ccPosicion b on b.pos_id = a.cal_extension * -1           
                left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id  
                where'' 
                if @IDWGList is not null and @IDWGList <> '''' 
                    set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                '' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                else
                    --set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                    set @sql1 = @sql1 + ''  a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                                        
                if @ACDList is not null and @ACDList <> ''''
                    set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' 
                
                if @DispositionList is not null and @DispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                if @SubdispositionList is not null and @SubdispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''
            
                set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                --print @sql1
                exec (@sql1)

                set @sql1 =''
                insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)      
                select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                isnull (e.description,'''''''')  AS score,
                                CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                grab_id as grabID, a.IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
                left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id            
                left join cctipocalifsubout k on k.califSub_id=a.califSub_id        
                left join ccPosicion b on b.pos_id = a.cal_extension * -1           
                left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion         
                where'' 

                if @IDWGList is not null and @IDWGList <> '''' 
                    set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                '' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                else
                    --set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                    set @sql1 = @sql1 + '' a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
            
                if @CampaingsList is not null and @CampaingsList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''                           
    
                if @DispositionList is not null and @DispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                if @SubdispositionList is not null and @SubdispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''   
                                                                        
                set @sql1 = @sql1 + '' and a.tipo_llamada=2''
                --print @sql1
                exec (@sql1)

                insert into #tempRiAAllInfo
                select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
                inner join #tempComplete6 U  on a.user_id=U.user_id

                insert into #tempRiAAllInfo
                select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
                inner join #tempCampEspWG6 U  on a.user_id=U.user_id

                if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where finicio BETWEEN cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) )> 0
                begin
                        set @sql1 =''
                        insert into #tempRiAAllInfo
                        select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                isnull (f.description,'''''''')  AS score,
                                CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                grab_id as grabID, a.IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))           
                        left join ccTipoCalif AS f ON a.calif_id = f.calif_id           
                        left join cctipocalifsub p on p.califSub_id=a.califSub_id
                        left join ccPosicion b on b.pos_id = a.cal_extension * -1                       
                        left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                        inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id  
                        where'' 
        
                        if @IDWGList is not null and @IDWGList <> '''' 
                            set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                    '' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                        else
                            set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                            
            
                        if @ACDList is not null and @ACDList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''
            
                        if @DispositionList is not null and @DispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                        if @SubdispositionList is not null and @SubdispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''
                                                                                
                        set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                        --print @sql1
                        exec (@sql1)

                        set @sql1 =''
                        insert into #tempRiAAllInfo
                        select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                    finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                    isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                    isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                    isnull (f.description,'''''''')  AS score,
                                    CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                    grab_id as grabID, a.IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))           
                        left join ccTipoCalif AS f ON a.calif_id = f.calif_id           
                        left join cctipocalifsub p on p.califSub_id=a.califSub_id
                        left join ccPosicion b on b.pos_id = a.cal_extension * -1                       
                        left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                        inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id  
                        where'' 
        
                        if @IDWGList is not null and @IDWGList <> '''' 
                            set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                    '' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                        else
                            set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
            
            
                        if @ACDList is not null and @ACDList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''             
            
                        if @DispositionList is not null and @DispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                        if @SubdispositionList is not null and @SubdispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''
                                                                            
                        set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                        --print @sql1
                        exec (@sql1)

                        set @sql1 =''
                        insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
                                    finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                    id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)      
                        select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                        finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                        isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                        isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                        isnull (e.description,'''''''')  AS score,
                                        CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                        grab_id as grabID, a.IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
                        left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id            
                        left join cctipocalifsubout k on k.califSub_id=a.califSub_id        
                        left join ccPosicion b on b.pos_id = a.cal_extension * -1                       
                        left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion         
                        where'' 
        
                        if @IDWGList is not null and @IDWGList <> '''' 
                            set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                    '' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                        else
                            set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                                                            
                        if @CampaingsList is not null and @CampaingsList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''                           
            
                        if @DispositionList is not null and @DispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                        if @SubdispositionList is not null and @SubdispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                        set @sql1 = @sql1 + '' and a.tipo_llamada=2''
                        --print @sql1
                        exec (@sql1)

                        insert into #tempRiAAllInfo
                        select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                        finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
                        inner join #tempComplete6 U  on a.user_id=U.user_id

                        insert into #tempRiAAllInfo
                        select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                        finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
                        inner join #tempCampEspWG6 U  on a.user_id=U.user_id

                end

    END



--Seleccionar info de tabla global
select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,i.user_id,
       finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
       id_repositorio,score,formato_duracion,grab_id, IDWG,califSub_id,cal_tMoh 
from #tempRiAAllInfo i with (index(IX_tempRiAAllInfodate))  
order by finicio asc

drop table #tempRiaFormaCalif6
drop table #tempCampEspWG6
drop table #tempComplete6
drop table #tempRiAAllInfo
drop table #auxOutbound

END'
    EXEC(@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchANI] remove replica WorkGroup_Calid'
    SET @sql = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchANI]
@Sup_id int,
@ani as varchar(100)

AS
BEGIN

SET NOCOUNT ON;

declare @fecha  datetime

set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

    select r.id_grabacion, avg(r.total_forma) as total_forma
    into #tempRiaFormaCalif from ria_formacalif r
    inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t
    on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
    group by r.id_grabacion

    select distinct a.IdCampEsp, a.Tipo as Tipo_llamada
    into #tempCampEspWG from ccRIACampEspWGConsulta a
    inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG

 -- CTE con resultados combinados de grabación
        ;WITH CombinedCalls AS (
            SELECT 
                a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion,
                ISNULL(a.id_nivel_grito, -1) AS id_nivel_grito,
                a.age_id, a.finicio, a.ani, a.dni, a.cal_key,
                ISNULL(a.cal_manual, 0) AS cal_manual,
                ISNULL(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END, -1) AS pos_id,
                b.Computer,
                ISNULL(z.total_forma, 0) AS total_forma,
                a.id_repositorio,
                CASE 
                    WHEN a.tipo_llamada = 2 THEN e.description 
                    ELSE f.description 
                END AS score,
                RIGHT(''0'' + RTRIM(a.duracion / 3600), 2) + '':'' +
                RIGHT(''0'' + RTRIM((a.duracion % 3600) / 60), 2) + '':'' +
                RIGHT(''0'' + RTRIM(a.duracion % 60), 2) AS formato_duracion,
                a.grab_id AS grabID
                ,a.IDWG
                --,ISNULL(g.IDWG, ''0'') AS IDWG
            FROM RIA_GRABACION a WITH (INDEX(IX_RIA_GRABACION_9))
            LEFT JOIN ccPosicion b ON b.pos_id = a.cal_extension * -1
            LEFT JOIN ccTipoCalifOUT e ON a.calif_id = e.calif_id
            LEFT JOIN ccTipoCalif f ON a.calif_id = f.calif_id          
            LEFT JOIN #tempRiaFormaCalif z ON a.grab_id = z.id_grabacion
            INNER JOIN #tempCampEspWG campEspWg ON a.cam_id = campEspWg.IdCampEsp AND campEspWg.Tipo_llamada = (a.Tipo_llamada - 1)       
            WHERE a.ani = @ani

            UNION

            SELECT 
                a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion,
                ISNULL(a.id_nivel_grito, -1) AS id_nivel_grito,
                a.age_id, a.finicio, a.ani, a.dni, a.cal_key,
                ISNULL(a.cal_manual, 0) AS cal_manual,
                ISNULL(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END, -1) AS pos_id,
                b.Computer,
                ISNULL(z.total_forma, 0) AS total_forma,
                a.id_repositorio,
                CASE 
                    WHEN a.tipo_llamada = 2 THEN e.description 
                    ELSE f.description 
                END AS score,
                RIGHT(''0'' + RTRIM(a.duracion / 3600), 2) + '':'' +
                RIGHT(''0'' + RTRIM((a.duracion % 3600) / 60), 2) + '':'' +
                RIGHT(''0'' + RTRIM(a.duracion % 60), 2) AS formato_duracion,
                a.grab_id AS grabID
                ,a.IDWG
                --,ISNULL(g.IDWG, ''0'') AS IDWG
            FROM RIA_GRABACIONCONSULTA a WITH (INDEX(IX_RIA_GRABACIONCONSULTA_9))
            LEFT JOIN ccPosicion b ON b.pos_id = a.cal_extension * -1
            LEFT JOIN ccTipoCalifOUT e ON a.calif_id = e.calif_id
            LEFT JOIN ccTipoCalif f ON a.calif_id = f.calif_id        
            LEFT JOIN #tempRiaFormaCalif z ON a.grab_id = z.id_grabacion
            INNER JOIN #tempCampEspWG campEspWg ON a.cam_id = campEspWg.IdCampEsp AND campEspWg.Tipo_llamada = (a.Tipo_llamada - 1)        
            WHERE a.ani = @ani
        ),

        Numeros AS (
            SELECT TOP 1000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
            FROM master.dbo.spt_values
        ),

        SplitIDWG AS (
            SELECT 
                c.*,
                CAST(
                    LTRIM(RTRIM(
                        SUBSTRING(
                            c.IDWG + '','', 
                            n, 
                            CHARINDEX('','', c.IDWG + '','', n) - n
                        )
                    )) AS VARCHAR(10)
                ) AS IDWG_Value
            FROM CombinedCalls c
            JOIN Numeros n ON n.n <= LEN(c.IDWG)
                AND SUBSTRING('','' + c.IDWG, n.n, 1) = '',''
        )

        -- Resultado final con IDWG desnormalizado
        SELECT 
            a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, a.id_nivel_grito, a.age_id,
            a.finicio, a.ani, a.dni, a.cal_key, a.cal_manual, a.pos_id, a.Computer, a.total_forma,
            a.id_repositorio, a.score, a.formato_duracion, a.grabID,convert(smallint, a.IDWG_Value) as IDWG
        FROM SplitIDWG a
        
        ORDER BY cal_id, IDWG_Value;

IF OBJECT_ID(''tempdb..#tempRiaFormaCalif'') IS NOT NULL DROP TABLE #tempRiaFormaCalif;
        IF OBJECT_ID(''tempdb..#tempCampEspWG'') IS NOT NULL DROP TABLE #tempCampEspWG;

END'
    EXEC(@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchCallIdStr] remove replica WorkGroup_Calid'
    SET @sql = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchCallIdStr]
@Sup_id int,
@callIdList as nvarchar(max),
@UserList varchar(MAX) =null,
@IDWGList varchar(MAX) =null,
@TypeCall int = null,
@CampaingsList varchar(MAX) =null,
@ACDList varchar(MAX) =null,
@DispositionList varchar(MAX) =null,
@SubdispositionList varchar(MAX) =null

AS
BEGIN

SET NOCOUNT ON

declare @sql1 nvarchar(max)

declare @callIdTmp table (callId int primary key)
declare @grabIdTmp table (grabId bigint primary key)
            
insert into @callIdTmp
select distinct value  from dbo.fn_RIASplitDelimited(@callIdList,'','')

insert into @grabIdTmp
select distinct A.grab_id from RIA_GRABACION A
inner join @callIdTmp B on A.cal_id=B.callId
union
select distinct A.grab_id from RIA_GRABACIONCONSULTA A
inner join @callIdTmp B on A.cal_id=B.callId


--Tabla con toda la informaciom
CREATE TABLE #tempRiAAllInfo(
    cal_id int,
    tipo_llamada smallint,
    cam_id smallint,
    calif_id smallint,
    duracion int,
    id_nivel_grito int,
    [user_id] int,
    finicio datetime,
    ani varchar (100),
    dni varchar (100),
    cal_key varchar (100),
    cal_manual tinyint,
    posicion int,
    computer varchar(100),
    total_forma int,
    id_repositorio tinyint,
    score varchar (100),
    formato_duracion varchar(15),
    grab_id bigint,
    IDWG varchar (800),
    califSub_id varchar(800),
    cal_tMoh smallint,
    Prefijo varchar(max)
)

CREATE CLUSTERED INDEX [IX_tempRiAAllInfodate] ON [#tempRiAAllInfo]
(
[finicio] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]


create table #auxOutbound(
    cal_id int,
    tipo_llamada smallint,
    cam_id smallint,
    calif_id smallint,
    duracion int,
    id_nivel_grito int,
    [user_id] int,
    finicio datetime,
    ani varchar (100),
    dni varchar (100),
    cal_key varchar (100),
    cal_manual tinyint,
    posicion int,
    computer varchar(100),
    total_forma int,
    id_repositorio tinyint,
    score varchar (100),
    formato_duracion varchar(15),
    grab_id bigint,
    IDWG varchar (800),
    califSub_id  varchar(800),
    cal_tMoh smallint,
    Prefijo varchar(max)
    )

--Segmento de Calificaciones
create table #tempRiaFormaCalif6( id_grabacion bigint, total_forma int)

;with formatCalifMax as (
    select id_formato,id_grabacion,max(version) as version from ria_formacalif  A
    inner join @grabIdTmp t on A.id_grabacion=t.grabId
    group by id_grabacion,id_formato    
)

insert into #tempRiaFormaCalif6 (id_grabacion,total_forma)
select r.id_grabacion, avg(r.total_forma) as total_forma
from ria_formacalif r
inner join formatCalifMax t on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
group by r.id_grabacion



--Segmento de Supervisor
create table #tempCampEspWG6(
IdCampEsp smallint,
Tipo smallint,
[user_id] smallint,
IDWG smallint)

CREATE NONCLUSTERED INDEX [IX_tempCampEspWG6] ON [#tempCampEspWG6]
(
[user_id] ASc
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]




insert into #tempCampEspWG6 (IdCampEsp,Tipo,user_id,IDWG)
    select distinct a.IdCampEsp, a.Tipo as Tipo_llamada,b.User_id,a.IDWG
from ccRIACampEspWG a
inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = @Sup_id and a.IDWG = b.IDWG

--Segmento de usurios asociados al supervisor
create table #tempComplete6(
IdCampEsp smallint,
Tipo smallint,
[user_id] int,
IDWG smallint)

CREATE NONCLUSTERED INDEX [IX_tempComplete6User] ON [#tempComplete6]
(
[user_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]



if @UserList is not null and @UserList <> ''''
BEGIN
    set @sql1=''insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)
            select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
            from ccRIACampEspWG a  inner join
            (select IDWG,user_id from ccRIAWorkGroupUsers where IDWG in
            (select  distinct a.IDWG from ccRIACampEspWG a
                        inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = ''+cast(@Sup_id as nvarchar(max))+'' and a.IDWG = b.IDWG
            )and user_id <> ''+cast(@Sup_id as nvarchar(max))+'' and user_id in (''+@UserList+'')
            ) b on a.IDWG=b.IDWG''
    exec (@sql1)

END
else
BEGIN
    insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)
    select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
    from  ccRIACampEspWG a  inner join
    (select IDWG,user_id from ccRIAWorkGroupUsers where IDWG in
        (select  distinct a.IDWG from ccRIACampEspWG a
            inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = @Sup_id and a.IDWG = b.IDWG
            )and user_id <> @Sup_id
    ) b on a.IDWG=b.IDWG
END


if @TypeCall is not null and @TypeCall <> ''''
    BEGIN
        if @TypeCall=1 -- Only Inbound
            BEGIN
                set @sql1 =''
                insert into #tempRiAAllInfo
                select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                            finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                            isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                            isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                            isnull (f.description,'''''''')  AS score,
                            CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                            grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
                left join ccTipoCalif AS f ON a.calif_id = f.calif_id
                left join cctipocalifsub p on p.califSub_id=a.califSub_id
                left join ccPosicion b on b.pos_id = a.cal_extension * -1               
                left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
                inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
                where''
                if @IDWGList is not null and @IDWGList <> ''''
                    set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                '' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
                else
                    --set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                    set @sql1 = @sql1 + ''  a.cal_id in('' + @callIdList +'')''

                if @ACDList is not null and @ACDList <> ''''
                    set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

                if @DispositionList is not null and @DispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                if @SubdispositionList is not null and @SubdispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                print @sql1
                exec (@sql1)

                set @sql1 =''
                insert into #tempRiAAllInfo
                select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                            finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                            isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                            isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                            isnull (f.description,'''''''')  AS score,
                            CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                            grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
                left join ccTipoCalif AS f ON a.calif_id = f.calif_id
                left join cctipocalifsub p on p.califSub_id=a.califSub_id
                left join ccPosicion b on b.pos_id = a.cal_extension * -1               
                left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
                inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
                where''
                if @IDWGList is not null and @IDWGList <> ''''
                    set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                '' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
                else
                    --set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                    set @sql1 = @sql1 + '' a.cal_id in('' + @callIdList +'')''

                if @ACDList is not null and @ACDList <> ''''
                    set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

                if @DispositionList is not null and @DispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                if @SubdispositionList is not null and @SubdispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                --print @sql1
                exec (@sql1)

                if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where cal_id in (select * from split_me(@callIdList) ) )> 0
                    begin
                        set @sql1 =''
                        insert into #tempRiAAllInfo
                        select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                isnull (f.description,'''''''')  AS score,
                                CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
                        left join ccTipoCalif AS f ON a.calif_id = f.calif_id
                        left join cctipocalifsub p on p.califSub_id=a.califSub_id
                        left join ccPosicion b on b.pos_id = a.cal_extension * -1                       
                        left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                        left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
                        inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
                        where''

                        if @IDWGList is not null and @IDWGList <> ''''
                            set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                    '' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
                        else
                            set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''


                        if @ACDList is not null and @ACDList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

                        if @DispositionList is not null and @DispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                        if @SubdispositionList is not null and @SubdispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                        set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                        --print @sql1
                        exec (@sql1)

                        set @sql1 =''
                        insert into #tempRiAAllInfo
                        select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                    finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                    isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                    isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                    isnull (f.description,'''''''')  AS score,
                                    CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                    grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
                        left join ccTipoCalif AS f ON a.calif_id = f.calif_id
                        left join cctipocalifsub p on p.califSub_id=a.califSub_id
                        left join ccPosicion b on b.pos_id = a.cal_extension * -1                   
                        left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                        left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
                        inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
                        where''

                        if @IDWGList is not null and @IDWGList <> ''''
                            set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                    '' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
                        else
                            set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''

                        if @ACDList is not null and @ACDList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

                        if @DispositionList is not null and @DispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                        if @SubdispositionList is not null and @SubdispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                        set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                        --print @sql1
                        exec (@sql1)
                    end
            END
        ELSE
            BEGIN --Only Outbound
                set @sql1 =''
                insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)
                select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                isnull (e.description,'''''''')  AS score,
                                CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
                left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
                left join cctipocalifsubout k on k.califSub_id=a.califSub_id
                left join ccPosicion b on b.pos_id = a.cal_extension * -1               
                left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
                where''

                if @IDWGList is not null and @IDWGList <> ''''
                    set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                '' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
                else
                    --set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                    set @sql1 = @sql1 + ''  a.cal_id in('' + @callIdList +'')''

                if @CampaingsList is not null and @CampaingsList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

                if @DispositionList is not null and @DispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                if @SubdispositionList is not null and @SubdispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                set @sql1 = @sql1 + '' and a.tipo_llamada=2''
                --print @sql1
                exec (@sql1)

                insert into #tempRiAAllInfo
                select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
                inner join #tempComplete6 U  on a.user_id=U.user_id

                insert into #tempRiAAllInfo
                select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
                inner join #tempCampEspWG6 U  on a.user_id=U.user_id


                if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where cal_id in (select * from split_me(@callIdList) ) )> 0
                    begin
                        set @sql1 =''
                        insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
                                    finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                    id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)
                        select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                        finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                        isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                        isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                        isnull (e.description,'''''''')  AS score,
                                        CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                        grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
                        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
                        left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
                        left join cctipocalifsubout k on k.califSub_id=a.califSub_id
                        left join ccPosicion b on b.pos_id = a.cal_extension * -1                       
                        left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                        left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
                        where''

                        if @IDWGList is not null and @IDWGList <> ''''
                            set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                    '' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
                        else
                            set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''

                        if @CampaingsList is not null and @CampaingsList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

                        if @DispositionList is not null and @DispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                        if @SubdispositionList is not null and @SubdispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                        set @sql1 = @sql1 + '' and a.tipo_llamada=2''
                        --print @sql1
                        exec (@sql1)

                        insert into #tempRiAAllInfo
                        select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                        finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
                        inner join #tempComplete6 U  on a.user_id=U.user_id

                        insert into #tempRiAAllInfo
                        select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                        finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
                        inner join #tempCampEspWG6 U  on a.user_id=U.user_id

                    end
            END
    END
ELSE
    BEGIN --NOT Inbound or Outbound this mean both
                set @sql1 =''
                insert into #tempRiAAllInfo
                select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                            finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                            isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                            isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                            isnull (f.description,'''''''')  AS score,
                            CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                            grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh, ISNULL(a.prefijo,'''''''')
                from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
                left join ccTipoCalif AS f ON a.calif_id = f.calif_id
                left join cctipocalifsub p on p.califSub_id=a.califSub_id
                left join ccPosicion b on b.pos_id = a.cal_extension * -1               
                left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
                inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
                where''
                if @IDWGList is not null and @IDWGList <> ''''
                    set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                '' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
                else
                    --set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                    set @sql1 = @sql1 + '' a.cal_id in('' + @callIdList +'')''

                if @ACDList is not null and @ACDList <> ''''
                    set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

                if @DispositionList is not null and @DispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                if @SubdispositionList is not null and @SubdispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                --print @sql1
                exec (@sql1)

                set @sql1 =''
                insert into #tempRiAAllInfo
                select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                            finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                            isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                            isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                            isnull (f.description,'''''''')  AS score,
                            CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                            grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh,ISNULL(a.prefijo,'''''''')
                from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
                left join ccTipoCalif AS f ON a.calif_id = f.calif_id
                left join cctipocalifsub p on p.califSub_id=a.califSub_id
                left join ccPosicion b on b.pos_id = a.cal_extension * -1               
                left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
                inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
                where''
                if @IDWGList is not null and @IDWGList <> ''''
                    set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                '' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
                else
                    --set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                    set @sql1 = @sql1 + ''  a.cal_id in('' + @callIdList +'')''

                if @ACDList is not null and @ACDList <> ''''
                    set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

                if @DispositionList is not null and @DispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                if @SubdispositionList is not null and @SubdispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                --print @sql1
                exec (@sql1)

                set @sql1 =''
                insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh,prefijo)
                select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                isnull (e.description,'''''''')  AS score,
                                CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh,ISNULL(a.prefijo,'''''''')
                from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
                left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
                left join cctipocalifsubout k on k.califSub_id=a.califSub_id
                left join ccPosicion b on b.pos_id = a.cal_extension * -1               
                left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
                where''

                if @IDWGList is not null and @IDWGList <> ''''
                    set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                '' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
                else
                    --set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
                    set @sql1 = @sql1 + '' a.cal_id in('' + @callIdList +'')''

                if @CampaingsList is not null and @CampaingsList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

                if @DispositionList is not null and @DispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                if @SubdispositionList is not null and @SubdispositionList <> ''''
                    set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                set @sql1 = @sql1 + '' and a.tipo_llamada=2''
            
                print @sql1
                exec (@sql1)
                
                insert into #tempRiAAllInfo
                select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh, prefijo from #auxOutbound a
                inner join #tempComplete6 U  on a.user_id=U.user_id

                insert into #tempRiAAllInfo
                select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh, prefijo from #auxOutbound a
                inner join #tempCampEspWG6 U  on a.user_id=U.user_id

                
                if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where cal_id in (select * from split_me(@callIdList) ) ) = 0
                begin
                        set @sql1 =''
                        insert into #tempRiAAllInfo
                        select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                isnull (f.description,'''''''')  AS score,
                                CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh ,''''''''
                        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
                        left join ccTipoCalif AS f ON a.calif_id = f.calif_id
                        left join cctipocalifsub p on p.califSub_id=a.califSub_id
                        left join ccPosicion b on b.pos_id = a.cal_extension * -1                       
                        left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                        left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
                        inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
                        where''

                        if @IDWGList is not null and @IDWGList <> ''''
                            set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                    '' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
                        else
                            set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''


                        if @ACDList is not null and @ACDList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

                        if @DispositionList is not null and @DispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                        if @SubdispositionList is not null and @SubdispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                        set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                        --print @sql1
                        exec (@sql1)

                        set @sql1 =''
                        insert into #tempRiAAllInfo
                        select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                    finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                    isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                    isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                    isnull (f.description,'''''''')  AS score,
                                    CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                    grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh, ''''''''
                        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
                        left join ccTipoCalif AS f ON a.calif_id = f.calif_id
                        left join cctipocalifsub p on p.califSub_id=a.califSub_id
                        left join ccPosicion b on b.pos_id = a.cal_extension * -1                       
                        left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                        left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
                        inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
                        where''

                        if @IDWGList is not null and @IDWGList <> ''''
                            set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                    '' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
                        else
                            set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''


                        if @ACDList is not null and @ACDList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

                        if @DispositionList is not null and @DispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                        if @SubdispositionList is not null and @SubdispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                        set @sql1 = @sql1 + '' and a.tipo_llamada=1''
                        --print @sql1
                        exec (@sql1)

                        set @sql1 =''
                        insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
                                    finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                    id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh, prefijo)
                        select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                        finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                        isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                        isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                        isnull (e.description,'''''''')  AS score,
                                        CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                        grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh , ''''''''
                        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
                        left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
                        left join cctipocalifsubout k on k.califSub_id=a.califSub_id
                        left join ccPosicion b on b.pos_id = a.cal_extension * -1                       
                        left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                        left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
                        where''

                        if @IDWGList is not null and @IDWGList <> ''''
                            set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
                                    '' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
                        else
                            set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''

                        if @CampaingsList is not null and @CampaingsList <> ''''
                            set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

                        if @DispositionList is not null and @DispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

                        if @SubdispositionList is not null and @SubdispositionList <> ''''
                            set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

                        set @sql1 = @sql1 + '' and a.tipo_llamada=2''
                        print @sql1
                        exec (@sql1)

                        insert into #tempRiAAllInfo
                        select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                        finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh,a.Prefijo from #auxOutbound a
                        inner join #tempComplete6 U  on a.user_id=U.user_id

                        insert into #tempRiAAllInfo
                        select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                        finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh,a.Prefijo from #auxOutbound a
                        inner join #tempCampEspWG6 U  on a.user_id=U.user_id

                end

    END



--Seleccionar info de tabla global
select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
        finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
        id_repositorio,score,formato_duracion,grab_id,IDWG,califSub_id,cal_tMoh,Prefijo
from #tempRiAAllInfo with (index(IX_tempRiAAllInfodate))  order by finicio asc

drop table #tempRiaFormaCalif6
drop table #tempCampEspWG6
drop table #tempComplete6
drop table #tempRiAAllInfo
drop table #auxOutbound

END
    '
    EXEC(@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchGreaterThatGrabID] remove replica WorkGroup_Calid'
    SET @sql = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchGreaterThatGrabID]
@Sup_id int,
@Grab_id int
AS
BEGIN

SET NOCOUNT ON

declare @sql1 nvarchar(max)
DECLARE @baseSQL NVARCHAR(MAX)

--Tabla con toda la informaciom
CREATE TABLE #tempRiAAllInfo(
    cal_id int,
    tipo_llamada smallint,
    cam_id smallint,
    calif_id smallint,
    duracion int,
    id_nivel_grito int,
    [user_id] int,
    finicio datetime,
    ani varchar (100),
    dni varchar (100),
    cal_key varchar (100),
    cal_manual tinyint,
    posicion int,
    computer varchar(100),
    total_forma int,
    id_repositorio tinyint,
    score varchar (100),
    formato_duracion varchar(15),
    grab_id bigint,
    IDWG varchar (800),
    califSub_id varchar(800),
    cal_tMoh smallint,
    Prefijo varchar(max)
)

CREATE CLUSTERED INDEX [IX_tempRiAAllInfodate] ON [#tempRiAAllInfo]
(
[finicio] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]


create table #auxOutbound(
    cal_id int,
    tipo_llamada smallint,
    cam_id smallint,
    calif_id smallint,
    duracion int,
    id_nivel_grito int,
    [user_id] int,
    finicio datetime,
    ani varchar (100),
    dni varchar (100),
    cal_key varchar (100),
    cal_manual tinyint,
    posicion int,
    computer varchar(100),
    total_forma int,
    id_repositorio tinyint,
    score varchar (100),
    formato_duracion varchar(15),
    grab_id bigint,
    IDWG varchar (800),
    califSub_id  varchar(800),
    cal_tMoh smallint,
    Prefijo varchar(max)
    )

--Segmento de Calificaciones
create table #tempRiaFormaCalif6(
id_grabacion bigint,
total_forma int)

insert into #tempRiaFormaCalif6 (id_grabacion,total_forma)
select r.id_grabacion, avg(r.total_forma) as total_forma
from ria_formacalif r
inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t
on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
group by r.id_grabacion


--Segmento de Supervisor
create table #tempCampEspWG6(
IdCampEsp smallint,
Tipo smallint,
[user_id] smallint)

CREATE NONCLUSTERED INDEX [IX_tempCampEspWG6] ON [#tempCampEspWG6]
(
[user_id] ASc
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]

insert into #tempCampEspWG6 (IdCampEsp,Tipo,user_id)
    select distinct a.IdCampEsp, a.Tipo as Tipo_llamada,b.User_id
from ccRIACampEspWGConsulta a
inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on a.IDWG = b.IDWG
and b.User_id = case @Sup_id when 0 then b.User_id else @Sup_id end

--Segmento de usurios asociados al supervisor
create table #tempComplete6(
IdCampEsp smallint,
Tipo smallint,
[user_id] int,
IDWG smallint)

CREATE NONCLUSTERED INDEX [IX_tempComplete6User] ON [#tempComplete6]
(
[user_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]


    insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)
    select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
    from  ccRIACampEspWGConsulta a  inner join
    (select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in
        (select  distinct a.IDWG from ccRIACampEspWGConsulta a
            inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG
            )and user_id <> @Sup_id
    ) b on a.IDWG=b.IDWG

                set @baseSQL =''
                insert into #tempRiAAllInfo
                select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                            finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                            isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                            isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                            isnull (f.description,'''''''')  AS score,
                            CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                            grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh, ISNULL(a.prefijo,'''''''')
                from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
                left join ccTipoCalif AS f ON a.calif_id = f.calif_id
                left join cctipocalifsub p on p.califSub_id=a.califSub_id
                left join ccPosicion b on b.pos_id = a.cal_extension * -1               
                left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                inner join {#tempComplete6} on a.age_id=U.user_id
                WHERE a.grab_id > @GrabID AND a.tipo_llamada = @TipoLlamada''
                
                SET @sql1 = REPLACE(@baseSQL, ''{#tempComplete6}'', ''#tempComplete6 U with (index(IX_tempComplete6User))'')
                EXEC sp_executesql @sql1, N''@GrabID bigint, @TipoLlamada smallint'', @GrabID=@Grab_id, @TipoLlamada=1
                    
                SET @sql1 = REPLACE(@baseSQL, ''{#tempComplete6}'', ''#tempCampEspWG6 U with (index(IX_tempCampEspWG6))'')
                EXEC sp_executesql @sql1, N''@GrabID bigint, @TipoLlamada smallint'', @GrabID=@Grab_id, @TipoLlamada=1

                    


                set @sql1 =''
                insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh,prefijo)
                select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                isnull (e.description,'''''''')  AS score,
                                CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh,ISNULL(a.prefijo,'''''''')
                from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
                left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
                left join cctipocalifsubout k on k.califSub_id=a.califSub_id
                left join ccPosicion b on b.pos_id = a.cal_extension * -1               
                left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                WHERE a.grab_id > @GrabID AND a.tipo_llamada = @TipoLlamada''

                --print @sql1
                --exec (@sql1)
                EXEC sp_executesql @sql1, N''@GrabID bigint, @TipoLlamada smallint'', @GrabID=@Grab_id, @TipoLlamada=2
                                
                insert into #tempRiAAllInfo
                select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh, prefijo from #auxOutbound a
                inner join #tempComplete6 U  on a.user_id=U.user_id

                insert into #tempRiAAllInfo
                select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh, prefijo from #auxOutbound a
                inner join #tempCampEspWG6 U  on a.user_id=U.user_id

                                
                if exists(select 1 from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where grab_id > @Grab_id)
                begin

                    set @baseSQL =''insert into #tempRiAAllInfo
                        select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                isnull (f.description,'''''''')  AS score,
                                CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh ,''''''''
                        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
                        left join ccTipoCalif AS f ON a.calif_id = f.calif_id
                        left join cctipocalifsub p on p.califSub_id=a.califSub_id
                        left join ccPosicion b on b.pos_id = a.cal_extension * -1                       
                        left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                        inner join {#tempComplete6} on a.age_id=U.user_id
                        WHERE a.grab_id > @GrabID AND a.tipo_llamada = @TipoLlamada
                    ''

                    SET @sql1 = REPLACE(@baseSQL, ''{#tempComplete6}'', ''#tempComplete6 U with (index(IX_tempComplete6User))'')
                    EXEC sp_executesql @sql1, N''@GrabID bigint, @TipoLlamada smallint'', @GrabID=@Grab_id, @TipoLlamada=1
                    
                    SET @sql1 = REPLACE(@baseSQL, ''{#tempComplete6}'', ''#tempCampEspWG6 U with (index(IX_tempCampEspWG6))'')
                    EXEC sp_executesql @sql1, N''@GrabID bigint, @TipoLlamada smallint'', @GrabID=@Grab_id, @TipoLlamada=1
                    


                        set @sql1 =''
                        insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
                                    finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                    id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)
                        select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                                        finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                                        isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
                                        isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                                        isnull (e.description,'''''''')  AS score,
                                        CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                                        grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh , ''''''''
                        from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
                        left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
                        left join cctipocalifsubout k on k.califSub_id=a.califSub_id
                        left join ccPosicion b on b.pos_id = a.cal_extension * -1                       
                        left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
                        WHERE a.grab_id > @GrabID AND a.tipo_llamada = @TipoLlamada''

                print @sql1
                --exec (@sql1)
                EXEC sp_executesql @sql1, N''@GrabID bigint, @TipoLlamada smallint'', @GrabID=@Grab_id, @TipoLlamada=2

                        insert into #tempRiAAllInfo
                        select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                        finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh,a.Prefijo from #auxOutbound a
                        inner join #tempComplete6 U  on a.user_id=U.user_id

                        insert into #tempRiAAllInfo
                        select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                                        finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                                        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh,a.Prefijo from #auxOutbound a
                        inner join #tempCampEspWG6 U  on a.user_id=U.user_id

                end

--Seleccionar info de tabla global
select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
        finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
        id_repositorio,score,formato_duracion,grab_id,IDWG,califSub_id,cal_tMoh,Prefijo
from #tempRiAAllInfo with (index(IX_tempRiAAllInfodate))  order by finicio asc

drop table #tempRiaFormaCalif6
drop table #tempCampEspWG6
drop table #tempComplete6
drop table #tempRiAAllInfo
drop table #auxOutbound

END'
    EXEC(@sql)

    SET @process = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchOneDay] remove replica WorkGroup_Calid'
    SET @sql = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchOneDay]
@Sup_id int

AS
BEGIN

DECLARE @fechaInicio DATETIME = DATEADD(HOUR, -2, GETDATE());

--Tabla con toda la informaciom
  CREATE TABLE #tempRiAAllInfoOneDay(
    cal_id int,
    tipo_llamada smallint,
    cam_id smallint,
    calif_id smallint,
    duracion int,
    id_nivel_grito int,
    user_id int,
    finicio datetime,
    ani varchar (100),
    dni varchar (100),
    cal_key varchar (100),
    cal_manual tinyint, 
    posicion int,
    computer varchar(100),
    total_forma int,
    id_repositorio tinyint,
    score varchar (100),
    formato_duracion varchar(15),
    grab_id bigint,
    IDWG varchar (800),
    califSub_id varchar(800),
    cal_tMoh smallint
)   

CREATE CLUSTERED INDEX [IX_tempRiAAllInfoOneDaydate] ON [#tempRiAAllInfoOneDay]
(         
    [finicio] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]


create table #auxOutboundOneDay(
    cal_id int,
    tipo_llamada smallint,
    cam_id smallint,
    calif_id smallint,
    duracion int,
    id_nivel_grito int,
    user_id int,
    finicio datetime,
    ani varchar (100),
    dni varchar (100),
    cal_key varchar (100),
    cal_manual tinyint, 
    posicion int,
    computer varchar(100),
    total_forma int,
    id_repositorio tinyint,
    score varchar (100),
    formato_duracion varchar(15),
    grab_id bigint,
    IDWG varchar (800),
    califSub_id varchar(800),
    cal_tMoh smallint
    )
            
  --Segmento de Calificaciones
  create table #tempRiaFormaCalifOneDay(
  id_grabacion bigint,
  total_forma int)

  insert into #tempRiaFormaCalifOneDay (id_grabacion,total_forma)
  select r.id_grabacion, avg(r.total_forma) as total_forma
  from ria_formacalif r
  inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t
  on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
  group by r.id_grabacion
  

  --Segmento de Supervisor
  create table #tempCampEspWGfOneDay(
  IdCampEsp smallint,
  Tipo smallint,
  user_id smallint)
     
  CREATE NONCLUSTERED INDEX [IX_tempCampEspWGfOneDay] ON [#tempCampEspWGfOneDay] 
  (
    [user_id] ASc
  )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
     
  insert into #tempCampEspWGfOneDay (IdCampEsp,Tipo,user_id)
  select distinct a.IdCampEsp, a.Tipo as Tipo_llamada,b.User_id
  from ccRIACampEspWGConsulta a
  inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG        
    
   --Segmento de usurios asociados al supervisor                 
  create table #tempCompleteOneDay(
  IdCampEsp smallint,
  Tipo smallint ,
  user_id smallint,
  IDWG smallint)                 

  CREATE NONCLUSTERED INDEX [IX_tempCompleteOneDayUser] ON [#tempCompleteOneDay] 
  (       
   [user_id] ASC
  )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
     
 
   insert into #tempCompleteOneDay  (IdCampEsp,Tipo,user_id,IDWG)  
   select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
   from  ccRIACampEspWGConsulta a  inner join
   (select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in 
        (select  distinct a.IDWG from ccRIACampEspWGConsulta a
         inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG
         )and user_id <> @Sup_id
    ) b on a.IDWG=b.IDWG

    --Seccion Inbound RIAGrabacion

    insert into #tempRiAAllInfoOneDay
        select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
                isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                isnull (f.description,'''')  AS score,
                CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
        from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))           
        left join ccTipoCalif AS f ON a.calif_id = f.calif_id           
        left join cctipocalifsub p on p.califSub_id=a.califSub_id
        left join ccPosicion b on b.pos_id = a.cal_extension * -1       
        left join #tempRiaFormaCalifOneDay z on a.grab_id=z.id_grabacion
        inner join #tempCompleteOneDay U with (index(IX_tempCompleteOneDayUser)) on a.age_id=U.user_id  
        where a.finicio >=  @fechaInicio
        and a.tipo_llamada=1
        UNION ALL
        
    
        select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
                isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                isnull (f.description,'''')  AS score,
                CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
        from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))           
        left join ccTipoCalif AS f ON a.calif_id = f.calif_id           
        left join cctipocalifsub p on p.califSub_id=a.califSub_id
        left join ccPosicion b on b.pos_id = a.cal_extension * -1       
        left join #tempRiaFormaCalifOneDay z on a.grab_id=z.id_grabacion
        inner join #tempCampEspWGfOneDay U with (index(IX_tempCampEspWGfOneDay)) on a.age_id=U.user_id  
        where a.finicio >=  @fechaInicio
        and a.tipo_llamada=1
        

    ----Seccion Outbound RIAGrabacion
    insert into #auxOutboundOneDay(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
                        finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                        id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)      
            select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
                        finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
                        isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
                        isnull (z.total_forma,0) as total_forma,a.id_repositorio,
                        isnull (e.description,'''')  AS score,
                        CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
                        grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
            from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
            left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id            
            left join cctipocalifsubout k on k.califSub_id=a.califSub_id        
            left join ccPosicion b on b.pos_id = a.cal_extension * -1           
            left join #tempRiaFormaCalifOneDay z on a.grab_id=z.id_grabacion            
            where a.finicio >=  @fechaInicio
            and a.tipo_llamada=2
            
    
    
    insert into #tempRiAAllInfoOneDay
    select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                    finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                    id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutboundOneDay a 
    inner join #tempCompleteOneDay U  on a.user_id=U.user_id

    union
    select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
                    finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
                    id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutboundOneDay a 
    inner join #tempCampEspWGfOneDay U  on a.user_id=U.user_id

    --Seleccionar info de tabla global
    select distinct a.cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
           finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
           id_repositorio,score,formato_duracion,grab_id,cast(isnull(a.IDWG,'''') as nvarchar(max)) as IDWG,califSub_id,cal_tMoh
    into #tempFinal
    from #tempRiAAllInfoOneDay a with (index(IX_tempRiAAllInfoOneDaydate))
    order by finicio asc
    
    
    select distinct a.cal_id,a.tipo_llamada,a.cam_id,a.calif_id,a.duracion,a.id_nivel_grito,a.user_id,
           a.finicio,a.ani,a.dni,a.cal_key,a.cal_manual,a.posicion,computer,total_forma,
           a.id_repositorio,score,formato_duracion,a.grab_id,cast(isnull( REPLACE(b.IDWG, '','', ''|'')  ,'''') as nvarchar(max)) as IDWG,a.califSub_id,a.cal_tMoh
    from #tempFinal a
    inner join RIA_GRABACION b with(nolock) on a.grab_id= b.grab_id 
    order by a.finicio asc
    
    drop table #tempRiaFormaCalifOneDay
    drop table #tempCampEspWGfOneDay
    drop table #tempCompleteOneDay
    drop table #tempRiAAllInfoOneDay
    drop table #auxOutboundOneDay
    drop table #tempFinal
    --drop table #tempWgList
    
END'
    EXEC(@sql)

    SET @process = ' remove replica WorkGroup_Calid'
    SET @sql = ''
    EXEC(@sql)
	
	
--------------------------------- END   Jesus Gallardo .31 tickets #1867 ----------------------------------------------------------

	

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