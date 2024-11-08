set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
    Set @Version = 94
    Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
    begin tran
    begin try
   
---------------------------------------BEGIN KR091000 Setting grabar llamadas por campaña ---------------------------------------------------------
 -------------------------------------------- Begin Jesus Gallardo hotfix/125.20230719.0.7 -------------------------------------------------------------------------------
	
	set @process = 'DEV1-435 Alter SP trsp_muevegrabaciones se modifica left join RIA_GRABACIONCONSULTA B on A.grab_id=B.grab_id where B.grab_id is null para que revise si los registros ya se ingresaron'
	set @sql = 'ALTER PROCEDURE [dbo].[trsp_muevegrabaciones]
AS
BEGIN
Set NOCOUNT ON

declare @fecha datetime
declare @Integrado as int

select @integrado = par_valor from trec_parametros where par_id = 29
set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)
declare @top int
set @top=3000

declare @sql nvarchar(max) 
set @sql=''declare @RIA_GRABACION table(	
[grab_id] [bigint] NOT NULL,
[cli_id] [int] NULL,
[age_id] [int] NULL,
[puerto_id] [int] NULL,
[tipo_grab_id] [tinyint] NULL,
[age_id_rec] [int] NULL,
[ffin] [datetime] NOT NULL,
[finicio] [datetime] NOT NULL,
[ani] [varchar](30) NOT NULL,
[dni] [varchar](15) NULL,
[tamano] [int] NULL,
[duracion] [int] NULL,
[pos_pc] [varchar](25) NULL,
[extension] [varchar](25) NULL,
[razon_id] [tinyint] NULL,
[nombre_archivo] [varchar](20) NULL,
[info1] [varchar](50) NULL,
[info2] [varchar](50) NULL,
[info3] [varchar](50) NULL,
[info4] [varchar](50) NULL,
[info5] [varchar](50) NULL,
[id_repositorio] [tinyint] NULL,
[id_nivel_grito] [int] NULL,
[tipo_llamada] [smallint] NULL,
[cam_id] [smallint] NULL,
[calif_id] [smallint] NULL,
[cal_id] [int] NULL,
[cal_key] [varchar](40) NOT NULL,
[cal_manual] [tinyint] NULL,
[cal_extension] [int] NULL,
[cal_whoHung] [smallint] NULL,
[cal_whoRec] [int] NULL,
[id_plantilla] [smallint] NULL,
[fvalida] [datetime] NULL,
[fvalida2] [datetime] NULL,
[borra_id] [bit] NULL,
[cal_fcallback] [smalldatetime] NULL,
[dni_id] [smallint] NULL,
[extra_info] [varchar](50) NULL,
[extra_info2] [varchar](50) NULL,
[id_rep_video] [tinyint] NULL,
[video] [int] NOT NULL,
[IDWG] [varchar](800) NULL,
[califSub_id] [smallint] NOT NULL,
[cal_tMoh] [smallint] NOT NULL,
[Prefijo] [varchar](max) NULL,
primary key (grab_id)
)
''

--AVRS XION
if (@integrado = 2) BEGIN
		set @sql=@sql+''  
insert into @RIA_GRABACION
(grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh,Prefijo)
SELECT top(@top) grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
	info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
	cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh,Prefijo
FROM [RIA_GRABACION] with(nolock, index(IX_RIA_GRABACION_3)) WHERE [finicio] < @fecha;

INSERT INTO [RIA_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh,Prefijo)

select A.grab_id,A.cli_id,A.age_id,A.puerto_id,A.tipo_grab_id,A.age_id_rec,A.ffin,A.finicio,A.ani,A.dni,A.tamano,A.duracion,A.pos_pc,A.extension,A.razon_id,A.nombre_archivo,A.info1,A.info2,A.info3,A.info4,A.
info5,A.id_repositorio,A.id_nivel_grito,A.tipo_Llamada,A.cam_id,A.calif_id,A.cal_id,A.cal_key,A.cal_manual,A.cal_extension,A.cal_whoHung,A.cal_whoRec,A.id_plantilla,A.fvalida,A.fvalida2,A.borra_id,A.
cal_fcallback,A.dni_id,A.extra_info,A.extra_info2,A.id_rep_video,A.video,A.IDWG,A.califSub_id,A.cal_tMoh,A.Prefijo
from @RIA_GRABACION A
left join RIA_GRABACIONCONSULTA B on A.grab_id=B.grab_id
where B.grab_id is null

delete A from RIA_GRABACION A 
inner join @RIA_GRABACION B on A.grab_id=B.grab_id
		''
END
else BEGIN  --AVRS Integrada ó AVRS Stand Alone
	
	set @sql=@sql+''
SET IDENTITY_INSERT TREC_GRABACIONCONSULTA ON

insert into @RIA_GRABACION
(grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh,Prefijo)		  
SELECT grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
	info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
	cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG
FROM [TREC_GRABACION] with(nolock, index(IX_TREC_GRABACION_3)) WHERE [finicio] < @fecha;

INSERT INTO [TREC_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG)
select grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG
from @RIA_GRABACION

SET IDENTITY_INSERT TREC_GRABACIONCONSULTA OFF

delete A from TREC_GRABACION A 
inner join @RIA_GRABACION B on A.grab_id=B.grab_id''
	
END

exec sp_executesql @sql, N''@top int, @fecha datetime'', @top,@fecha

END'
	EXEC(@sql)
    -------------------------------------------- END Jesus Gallardo hotfix/25.20230719.0.7 -------------------------------------------------------------------------------
	-------------------------------------------- Begin Jesus Gallardo hotfix/25.20230719.0.9 -------------------------------------------------------------------------------
      SET @process = 'DEV1-440 alter SP ccspGalatea_Finder hotfix/25.20230719.0.9'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccspGalatea_Finder] 
@action int,
@grabIds varchar(max)=null,
@grabId int =null,
@userId int =0, 
@markTime int=null,
@markId int=null,
@isSuperUser bit=0,
@dateStart datetime=null,
@dateEnd datetime=null,
@idRepository int = 0
AS
BEGIN

    SET NOCOUNT ON;
    declare @sql varchar(max)
    declare @camType table(Id int,camType tinyint)

if @action=0 begin
    if @isSuperUser =0 begin            
                SELECT WGCam.IdCampEsp AS [Id], 2 callType
                FROM ccRIAWorkGroupUsers Wguser
                    INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                    INNER JOIN ccCamps c ON WGCam.IdCampEsp = c.cam_id
                                            AND WGCam.Tipo = 1
                WHERE Wguser.User_id = @userId
                UNION
                SELECT WGCam.IdCampEsp AS [Id], 1 AS callType
                FROM ccRIAWorkGroupUsers Wguser
                    INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                    INNER JOIN ccInbound inb ON WGCam.IdCampEsp = inb.Inbound_id
                                                AND WGCam.Tipo = 0
                WHERE Wguser.User_id = @userId;
            end
    else begin           
        SELECT c.cam_id as [Id], 2 AS callType FROM ccCamps c
        UNION
        SELECT inb.Inbound_id AS [Id], 1 AS callType FROM ccInbound inb;
    end
        
end

    else if @action=1 begin
        select id_repositorio as repositoryId,dirvirtual_audio as pathAudio,dirvirtual_video as pathVideo,ruta_repositorio as pathRepositoryAudio, 
            ruta_repositorio_secundario as PathRepositoryAudioSecundario, dirvirtual_audio_secundario as PathAudioSecundario
        from TREC_REPOSITORIOS
    end
else if @action=2 begin

    ;with grab as (
    select grab_id,cal_id,tipo_llamada,age_id as userId from RIA_GRABACION A with(nolock) 
    where A.grab_id=@grabId
    union
    select grab_id,cal_id,tipo_llamada,age_id as userId from RIA_GRABACIONCONSULTA C with(nolock) 
    where C.grab_id=@grabId
    )

    select isnull(mark.id_marca,0) as markId, grab.grab_id as grabId
    ,isnull(b.login,'''') as userName, isnull(mark.user_id,0) as [userId],isnull(mark.marca,'''') as mark
    ,convert(bit,case when b.TipoUser_id =1 then 0 else 1 end ) as IsAdmin
    from grab 
    left join RIA_MARCAS mark  on grab.cal_id=mark.call_id and grab.tipo_llamada=mark.tipo_llamada
    left join ccUsers b on b.user_id = mark.user_id
    order by grab.grab_id,mark.tipo_marca 


end
else if @action =3 begin
    select cast(case when par_valor =''1'' then 1 else 0 end as bit) as isEncrypt from TREC_PARAMETROS where par_id=15
end
else if @action =4 begin
    set @sql=''declare @nameFolder table (callType int,nameFolder varchar(100),prefijo varchar(2))
insert into @nameFolder values(1,''''INBOUND'''',''''I_'''')
insert into @nameFolder values(2,''''OUTBOUND'''',''''O_'''')
declare @ext varchar(30)

select @ext = case when par_valor=''''1'''' then ''''.wav.enc'''' else ''''.wav'''' end from TREC_PARAMETROS where par_id=15
    ;
    with grab as (
    select grab_id,cal_id,tipo_llamada,id_repositorio,Prefijo as subFijo from RIA_GRABACION with(nolock) where grab_id in(''+@grabIds+'')
    union
    select grab_id,cal_id,tipo_llamada,id_repositorio,Prefijo as subFijo from RIA_GRABACIONCONSULTA with(nolock) where grab_id in(''+@grabIds+'')
    )
    
    select grab.grab_id as grabId,grab.id_repositorio as repositoryId,rep.dirvirtual_audio as virtualAudio
    ,rep.ruta_repositorio+''''\''''+f.nameFolder+''''\''''+ cast(cal_id/10000 as varchar(100))+''''\'''' as pathRep,
    rep.dirvirtual_audio_secundario as VirtualAudioSecundario, 
    rep.ruta_repositorio_secundario+''''\''''+f.nameFolder+''''\''''+ cast(cal_id/10000 as varchar(100))+''''\'''' as PathRepSecundario,
    f.prefijo+cast(cal_id as varchar(100))  + case when subFijo<>'''''''' then ''''_''''+subFijo else '''''''' end + @ext as [fileAudio]
    from grab 
    inner join TREC_REPOSITORIOS rep on grab.id_repositorio=rep.id_repositorio
    inner join @nameFolder f on f.callType=grab.tipo_llamada  
    order by repositoryId
    ''
    --print @sql
    exec (@sql)
end
else if @action =5 begin
    select top 1 id_repositorio as repositoryId,rep.ruta_repositorio as pathRep, Cred.domain, Cred.[user], Cred.[password],Rep.dirvirtual_audio as virtualAudio
    from TREC_REPOSITORIOS Rep
    inner join TREC_REPO_NWCREDENTIALS  RepCred on Rep.id_repositorio =repCred.id_repository
    inner join RIA_NETWORKCREDENTIALS  Cred on RepCred.id_nwCredential=Cred.id
    where Cred.type = 1 and status=1
end
else if @action=6 begin
    declare @cal_id int,@tipo_llamada int

    select @cal_id= cal_id,@tipo_llamada=tipo_llamada from RIA_GRABACION with(nolock) where grab_id=@grabId

    if @cal_id is null and @tipo_llamada is null begin
        select @cal_id= cal_id,@tipo_llamada=tipo_llamada from RIA_GRABACIONCONSULTA with(nolock) where grab_id=@grabId
    end            
    insert RIA_MARCAS (grab_id,user_id,marca,tipo_marca,tipo_llamada,call_id) values (@grabId,@userId,CONVERT(varchar, DATEADD(ss, @markTime , 0), 8),2,@tipo_llamada,@cal_id )
    select cast( @@IDENTITY  as int) as markId
end
else if @action=7 begin
    delete from RIA_MARCAS  where id_marca=@markId
end
else if @action=8 begin 
    select par_valor as hexKey from TREC_PARAMETROS where par_id=75
end

else if @action=12 begin    
          
    insert into @camType
    exec ccspGalatea_Finder @action=0,@userId=@userId,@isSuperUser=@isSuperUser

    select distinct A.dni from RIA_GRABACION A with(nolock)
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
    union
    select distinct A.dni from RIA_GRABACIONCONSULTA A with(nolock) 
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
end
else if @action=13 begin                    
    insert into @camType
    exec ccspGalatea_Finder @action=0,@userId=@userId,@isSuperUser=@isSuperUser
        
    select distinct convert(varchar(100), A.cal_extension) as cal_extension from RIA_GRABACION A with(nolock)
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
    union
    select distinct convert(varchar(100), A.cal_extension) from RIA_GRABACIONCONSULTA A with(nolock)
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
end

else if @action=14 begin                    
    insert into @camType
    exec ccspGalatea_Finder @action=0,@userId=@userId,@isSuperUser=@isSuperUser

    
    select isnull(min(minDuration),0) as MinDuration, isnull(max(maxDuration),600) as MaxDuration from (
        select max(duracion) as maxDuration,min(duracion) as minDuration from RIA_GRABACION A with(nolock) 
        inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
        where A.finicio between @dateStart and @dateEnd
        union
        select max(duracion) as maxDuration,min(duracion) as minDuration from RIA_GRABACIONCONSULTA A with(nolock)
        inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
        where A.finicio between @dateStart and @dateEnd
    )X
end

else if @action = 15 begin
    select cast(id_repositorio as int) as idRepository from RIA_GRABACION where grab_id = @grabId
end

else if @action = 16 begin
    select id_repositorio as repositoryId,rep.ruta_repositorio as pathRep, Cred.domain, Cred.[user], Cred.[password],Rep.dirvirtual_audio as virtualAudio
    from TREC_REPOSITORIOS Rep
    inner join TREC_REPO_NWCREDENTIALS  RepCred on Rep.id_repositorio =repCred.id_repository
    inner join RIA_NETWORKCREDENTIALS  Cred on RepCred.id_nwCredential=Cred.id
    where Cred.type = 1 and status=1 and Rep.id_repositorio = @idRepository
end

else if @action = 17 begin  -- Get Inbound and Outbound cal_ids 
    insert into @camType
    exec ccspGalatea_Finder @action=0,@userId=@userId,@isSuperUser=@isSuperUser
        
    select A.cal_id from RIA_GRABACION A with(nolock) 
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
    union
    select A.cal_id from RIA_GRABACIONCONSULTA A with(nolock) 
    inner join @camType B on A.cam_id=B.Id and A.tipo_llamada=B.camType
    where A.finicio between @dateStart and @dateEnd
end

END'
  	EXEC(@sql) 
	

      -------------------------------------------- End Jesus Gallardo hotfix/125.20231211.0.9 -------------------------------------------------------------------------------

      -------------------------------------------- Begin Jesus Gallardo hotfix/125.20231211.0.13 -------------------------------------------------------------------------------

    SET @process = 'ALTER SP ccsp_BaseXmngr se modifica para que se ordene por Xname en lugar baseX.Xname'
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
order by Xname''
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

end'
    EXEC(@sql) 

      ---------------------------------------BEGIN KR087000 Modificaciones Recordings Manager Exportacion Automatica ---------------------------------------------------------

   	SET @process = 'DEV1-474 KR087000 Drop procedure trsp_ExportManagerAutomatic'
	SET @sql = 'if exists (select * from sys.procedures where name = N''trsp_ExportManagerAutomatic'')
    begin
        DROP PROCEDURE trsp_ExportManagerAutomatic;
    end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 Drop procedure trsp_GetParametersExportService'
	SET @sql = 'if exists (select * from sys.procedures where name = N''trsp_GetParametersExportService'')
    begin
        DROP PROCEDURE trsp_GetParametersExportService;
    end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 Drop procedure trsp_SaveAVRSExportParameters'
	SET @sql = 'if exists (select * from sys.procedures where name = N''trsp_SaveAVRSExportParameters'')
    begin
        DROP PROCEDURE trsp_SaveAVRSExportParameters;
    end'
	EXEC(@sql)

    SET @process = 'DEV1-474 KR087000 create table ccConfigurationExportManagerAutomatic'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccConfigurationExportManagerAutomatic'') begin
create table ccConfigurationExportManagerAutomatic(
	ccConfigurationExportId bigint Not null identity primary key,
	DateStartExport datetime null,
	DateEndExport  datetime null,
	Json varchar(4000) not null,	
	ExportStatus tinyint not null--0 Create,1 Process ,2 End,3 Cancelada
)
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 create table ccExportStatusConfiguration'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccExportStatusConfiguration'') begin
create table ccExportStatusConfiguration(
	ExportStatusId tinyint not null primary key,
	Description varchar(150) not null
)
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 create table ccExportManagerAutomatic'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccExportManagerAutomatic'') begin
create table ccExportManagerAutomatic(
	GrabId bigint Not null,
	ccConfigurationExportId bigint not null,
	DateDownload datetime not null,
	StatusId tinyint not null,
	FOREIGN KEY (ccConfigurationExportId) REFERENCES ccConfigurationExportManagerAutomatic(ccConfigurationExportId)
)
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 create table ccStatusExportManager'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccStatusExportManager'') begin
create table ccStatusExportManager(
	StatusId tinyint not null primary key,
	Description varchar(150) not null
)
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 update TREC_PARAMETROS par_id=65'
	SET @sql = 'update TREC_PARAMETROS 
set par_valor=''1'' 
where par_id=65 and par_valor=''C:\Centerware/Sites/CWAdminEngine/AVRSExportRecs'''
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 Add insert ccStatusExportManager y ccExportStatusConfiguration'
	SET @sql = 'if not exists(select * from ccStatusExportManager) begin
	insert into ccStatusExportManager values(0,''Scheduled'')
	insert into ccStatusExportManager values(1,''Downloaded'')
	insert into ccStatusExportManager values(2,''Export error'')
	insert into ccStatusExportManager values(3,''Cancelled'')
end
if not exists(select * from ccExportStatusConfiguration) begin
	insert into ccExportStatusConfiguration values(0,''Create'')
	insert into ccExportStatusConfiguration values(1,''Process'')
	insert into ccExportStatusConfiguration values(2,''End'')
	insert into ccExportStatusConfiguration values(3,''Cancelada'')
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 Add TREC_PARAMETROS par_id 77 y 78'
	SET @sql = 'if not exists(select * from TREC_PARAMETROS where par_id =77) begin
	insert into TREC_PARAMETROS values(77,''Configuracion Automatica descarga Ftp AvrsExport'','''',''Configuracion formato Json para exportar grabaciones'');
end
if not exists(select * from TREC_PARAMETROS where par_id =78) begin
	insert into TREC_PARAMETROS values(78,''Id Export Configuration'',''0'',''Id de la tabla ccConfigurationExportManagerAutomatic'');
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 alter COLUMN TREC_PARAMETROS par_valor'
	SET @sql = 'alter table TREC_PARAMETROS ALTER COLUMN par_valor varchar(4000);'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 alter Sp trsp_AdmRecSearchCallIdStr'
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
	select id_formato,id_grabacion,max(version) as version from ria_formacalif 	A
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
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
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
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
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
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
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
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
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
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
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
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
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
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
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
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
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
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
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
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
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
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
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
						left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
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

	SET @process = 'DEV1-474 KR087000 Alter SP trsp_AdmRecSearchNodeWorkgroup Remove Index'
	SET @sql = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeWorkgroup]
@User_id int,
@WG_id int = 0
AS
BEGIN
	SET NOCOUNT ON;

	if @User_id in( 0,1)
	begin
		select IDWG,WGName from ccRIACat_WorkGroup nolock
	end
	else
	if @WG_id = 0
	begin
		select distinct IDWG,WGName from (
		select b.IDWG, c.WGName from ccusers a inner join ccRIAWorkGroupUsersConsulta b
		on b.user_id = @User_id inner join ccRIACat_WorkGroup c on c.IDWG = b.IDWG /*and c.StatusWorkGroup = 1*/
		where a.user_id = @User_id
		union --camp history
		select distinct a.IDWG,WGName
		from ccRIACampEspWGConsulta a inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG where cast(a.IdCampEsp as varchar(6))+''&''+cast(a.Tipo as varchar(6)) in (
		select distinct cast(a.IdCampEsp as varchar(6))+''&''+cast(a.Tipo as varchar(6)) from ccRIACampEspWGConsulta a
		inner join  ccRIAWorkGroupUsersConsulta b with (nolock) on b.User_id = @User_id and a.IDWG = b.IDWG)
		union --user history
		select distinct a.IDWG,WGName
		from ccRIAWorkGroupUsersConsulta a inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG where user_id in (
		select user_id from ccRIAWorkGroupUsersConsulta where IDWG in (
		select distinct a.IDWG from ccRIACampEspWGConsulta a
		inner join  ccRIAWorkGroupUsersConsulta b with (nolock) on b.User_id = @User_id and a.IDWG = b.IDWG))
		)x
		order by 1
	end
	else
		select IDWG,WGName from ccRIACat_WorkGroup nolock where IDWG = @WG_id
END'
	EXEC(@sql)

	

	SET @process = 'DEV1-474 KR087000 create SP trsp_ExportManagerAutomatic'
	SET @sql = 'CREATE PROCEDURE [dbo].[trsp_ExportManagerAutomatic] @action int
,@grabIds varchar(max)='''',@ccConfigurationExportId bigint=0,@ExportStatus tinyint=0,@StatusId tinyint=0
AS
BEGIN
	declare @sql varchar(max)
	declare @grabIdTmp table (grabId bigint not null)
	if @action=0 begin -- Insert Status
		if @grabIds='''' or @ccConfigurationExportId=0 begin
		return
		end

		insert into @grabIdTmp
		select convert(bigint, value) grabId from dbo.fn_RIASplitDelimited(@grabIds,'','')
		
		insert into ccExportManagerAutomatic
		select T.grabId,@ccConfigurationExportId ccConfigurationExportId,getdate() DateDownload,0 StatusId
		from @grabIdTmp T
		left join ccExportManagerAutomatic E on T.grabId=E.GrabId and E.ccConfigurationExportId=@ccConfigurationExportId
		where E.ccConfigurationExportId is null

		update ccConfigurationExportManagerAutomatic set ExportStatus=1 
		where ccConfigurationExportId=@ccConfigurationExportId and ExportStatus=0
	end
	else if @action=1 begin --GetStatus ccExportManagerAutomatic
		select ExportStatus from ccConfigurationExportManagerAutomatic where ccConfigurationExportId=@ccConfigurationExportId
	end
	else if @action=2 begin --Update Status ccExportManagerAutomatic
		insert into @grabIdTmp
		select convert(bigint, value) grabId from dbo.fn_RIASplitDelimited(@grabIds,'','')
		
		insert into ccExportManagerAutomatic
		select T.grabId,@ccConfigurationExportId ccConfigurationExportId,getdate() DateDownload,@StatusId StatusId
		from @grabIdTmp T
		left join ccExportManagerAutomatic E on T.grabId=E.GrabId and E.ccConfigurationExportId=@ccConfigurationExportId
		where E.ccConfigurationExportId is null

		update E set
		E.StatusId=@StatusId
		--select T.grabId,@ExportStatus
		from @grabIdTmp T
		inner join ccExportManagerAutomatic E on T.grabId=E.GrabId and E.ccConfigurationExportId=@ccConfigurationExportId	
	end
	else if @action=3 begin --Update Status ccExportManagerAutomatic
		
		select isnull(min(GrabId),0) GrabId from ccExportManagerAutomatic 
		where StatusId=0 and ccConfigurationExportId=@ccConfigurationExportId
	end
	else if @action=4 begin --Update Status ccExportManagerAutomatic
		
		update ccConfigurationExportManagerAutomatic set ExportStatus=@ExportStatus 
		where ccConfigurationExportId=@ccConfigurationExportId

		if @ExportStatus=2 begin
			update ccExportManagerAutomatic set StatusId=3 where ccConfigurationExportId=@ccConfigurationExportId and StatusId=0
		end
	end

END'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 create procedure trsp_GetParametersExportService'
	SET @sql = 'CREATE PROCEDURE [dbo].[trsp_GetParametersExportService]
AS
BEGIN

DECLARE  @avrs_enviroment AS INT

SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

IF @avrs_enviroment = 2
	BEGIN
		SELECT * FROM
		(
			SELECT par_valor,par_id,par_descripcion FROM TREC_PARAMETROS
			WHERE par_id in (2,15,29,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,62,63,65,67,77,78)
			Union
			SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66,'''' FROM RIA_GRABACION
			union
			select @@Servername+''|''+valor as par_valor,66 as par_id,descripcion as par_descripcion from ccsettings where setting_id=8
		)x
		ORDER BY x.par_id
	END
ELSE
	BEGIN
		SELECT * FROM
		(
			SELECT par_valor,par_id FROM TREC_PARAMETROS
			WHERE par_id in (2,15,29,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,62,63,65,66,67,77,78)
			UNION
			SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
			FROM TREC_GRABACION)x
			ORDER BY x.par_id
	END	
END'
	EXEC(@sql)


	SET @process = 'DEV1-474 KR087000 create procedure trsp_SaveAVRSExportParameters'
	SET @sql = 'CREATE PROCEDURE [dbo].[trsp_SaveAVRSExportParameters] @export_mode AS INT, @netcred_id 
	AS INT = - 1, @net_user AS VARCHAR(100) = '''', @net_password AS VARCHAR(100) = '''', 
	@net_sever AS VARCHAR(max) = '''', @net_path AS VARCHAR(max) = '''', @ftp_user AS VARCHAR(
		100) = '''', @ftp_password AS VARCHAR(100) = '''', @ftp_sever AS VARCHAR(max) = '''', 
	@ftp_path AS VARCHAR(max) = '''', @ftp_port AS INT = - 1, @ftp_protocol AS INT = - 1, 
	@time_export AS VARCHAR(100) = '''', @grabid_start AS INT = - 1, @csv_log AS INT = - 1, 
	@delete_rec AS INT = - 1, @export_format AS INT = 1, @export_encrypted AS BIT = 0, 
	@file_encrypted AS BIT, @AutomaticConfigurationDto VARCHAR(max) = ''''
	,@DateStartExport	datetime null,@DateEndExport	datetime =null
AS
BEGIN
	DECLARE @repo_Id AS INT
	declare @ccConfigurationExportId bigint=0

	IF LEN(@time_export) > 0
	BEGIN
		UPDATE TREC_PARAMETROS
		SET par_valor = @time_export
		WHERE par_id = 33
	END

	UPDATE TREC_PARAMETROS
	SET par_valor = @export_format
	WHERE par_id = 35

	-- Update FTP Parameters
	IF @export_mode = 1
	BEGIN
		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_path
		WHERE par_id = 41

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_protocol
		WHERE par_id = 42

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_sever
		WHERE par_id = 43

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_user
		WHERE par_id = 44

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_password
		WHERE par_id = 45

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_port
		WHERE par_id = 46		
		
	END
	ELSE
	BEGIN
		-- Update NetBios parameters
		DECLARE @avrs_enviroment AS INT
		
		SELECT @avrs_enviroment=par_valor
		FROM TREC_PARAMETROS
		WHERE par_id = 29
				

		IF @avrs_enviroment = 2
		BEGIN
			UPDATE RIA_NETWORKCREDENTIALS
			SET [domain] = @net_sever, [user] = @net_user, [password] = @net_password
			WHERE id = @netcred_id
		END
		ELSE
		BEGIN
			UPDATE TREC_NETWORKCREDENTIALS
			SET [domain] = @net_sever, [user] = @net_user, [password] = @net_password
			WHERE id = @netcred_id
		END

		UPDATE TREC_PARAMETROS
		SET par_valor = @net_path
		WHERE par_id = 36
	END

	

	IF @grabid_start <> - 1
	BEGIN
		UPDATE TREC_PARAMETROS
		SET par_valor = @grabid_start
		WHERE par_id = 40
	END

	UPDATE TREC_PARAMETROS
	SET par_valor = @csv_log
	WHERE par_id = 50

	UPDATE TREC_PARAMETROS
	SET par_valor = @export_mode
	WHERE par_id = 51

	UPDATE TREC_PARAMETROS
	SET par_valor = @delete_rec
	WHERE par_id = 57

	UPDATE TREC_PARAMETROS
	SET par_valor = @file_encrypted
	WHERE par_id = 61

	UPDATE TREC_PARAMETROS
	SET par_valor = @export_encrypted
	WHERE par_id = 62

	if @AutomaticConfigurationDto<>'''' begin
		UPDATE TREC_PARAMETROS
		SET par_valor =case when @AutomaticConfigurationDto='''' then par_valor else  @AutomaticConfigurationDto end
		WHERE par_id = 77
		select @ccConfigurationExportId=case when par_valor='''' then 0 else  convert(bigint,par_valor) end 
		from TREC_PARAMETROS WHERE par_id = 78

		if @ccConfigurationExportId=0 begin		
			insert into ccConfigurationExportManagerAutomatic(DateStartExport,DateEndExport,Json,ExportStatus)
			values(@DateStartExport,@DateEndExport, @AutomaticConfigurationDto,0) 
			select @ccConfigurationExportId=@@IDENTITY
		end
		else begin
			declare @ExportStatus tinyint 
			select @ExportStatus=ExportStatus from ccConfigurationExportManagerAutomatic
			where ccConfigurationExportId=@ccConfigurationExportId
			if @ExportStatus =0 begin--Create
				update ccConfigurationExportManagerAutomatic set [Json]=@AutomaticConfigurationDto where ccConfigurationExportId=@ccConfigurationExportId
			end
			else if @ExportStatus =1 begin--Process
				update ccExportManagerAutomatic set StatusId=3 where ccConfigurationExportId=@ccConfigurationExportId
				update ccConfigurationExportManagerAutomatic set ExportStatus =3 where ccConfigurationExportId=@ccConfigurationExportId
				set @ExportStatus=3
			end
			if @ExportStatus in(2,3) begin--2 End,3 Cancelada
				insert into ccConfigurationExportManagerAutomatic(DateStartExport,DateEndExport,Json,ExportStatus)
				values(@DateStartExport,@DateEndExport, @AutomaticConfigurationDto,0) 
				select @ccConfigurationExportId=@@IDENTITY				
			end		
		end
		UPDATE TREC_PARAMETROS
		SET par_valor =convert(varchar(100),@ccConfigurationExportId)
		WHERE par_id = 78
	end
END'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 CW_trsp_AdmRecSearchAllRecs Se agrega para busqueda por @IdCallList'
	SET @sql = 'ALTER PROCEDURE [dbo].[CW_trsp_AdmRecSearchAllRecs]
@Sup_id int,
@dateStart datetime,
@dateEnd datetime,
@IdCallList varchar(MAX) =null,
@UserList varchar(MAX) =null,
@IDWGList varchar(MAX) =null,
@TypeCall int = null,
@CampaingsList varchar(MAX) =null,
@ACDList varchar(MAX) =null,
@DispositionList varchar(MAX) =null,
@SubdispositionList varchar(MAX) =null,
@GrabId bigInt = null,
@TopRecords int = 0

AS
		declare @encrypted bit
		select @encrypted = par_valor from TREC_PARAMETROS where par_id = 15
;
			
IF OBJECT_ID(''tempdb..#userAgent'') IS NOT NULL
	DROP TABLE #userAgent
IF OBJECT_ID(''tempdb..#tmpRecords'') IS NOT NULL
	DROP TABLE #tmpRecords
IF OBJECT_ID(''tempdb..#WorkGroupCamps'') IS NOT NULL
	DROP TABLE #WorkGroupCamps
IF OBJECT_ID(''tempdb..#tmpWGconcat'') IS NOT NULL
	DROP TABLE #tmpWGconcat

CREATE TABLE #userAgent(UserId smallint);

IF((select [User_id] from ccUsers WHERE [Login] = ''root'') = @Sup_id)
BEGIN
	INSERT INTO #userAgent(UserId)
		select distinct User_id as UserId from ccRIAWorkGroupUsersConsulta
END
ELSE
BEGIN
	INSERT INTO #userAgent(UserId)
	select distinct User_id as UserId from ccRIAWorkGroupUsersConsulta where IDWG in(
		select distinct IDWG from ccRIAWorkGroupUsersConsulta where User_id = @Sup_id)
END

CREATE TABLE #WorkGroupCamps(IDWG smallint, WGName varchar(50),  cam_id smallint, campType smallint, campName varchar(50));

INSERT INTO #WorkGroupCamps(IDWG, WGName, cam_id, campType, campName)
SELECT WG.IDWG,WG.WGName, cCamp.cam_id, cWG.Tipo, cCamp.cam_descripcion
FROM cccamps cCamp
inner join ccRIACampEspWG cWG on cWG.IdCampEsp = cCamp.cam_id AND cWG.Tipo = 1
inner join ccRIACat_WorkGroup WG on WG.IDWG = cWG.IDWG
UNION
SELECT WG.IDWG,WG.WGName, cCamp.Inbound_id, cWG.Tipo, cCamp.descripcion
FROM ccinbound cCamp
inner join ccRIACampEspWG cWG on cWG.IdCampEsp = cCamp.Inbound_id AND cWG.Tipo = 0
inner join ccRIACat_WorkGroup WG on WG.IDWG = cWG.IDWG


SELECT  cam_id, campType,
	STUFF((
	SELECT '', '' + wgc.WGName
	FROM #WorkGroupCamps wgc WHERE (wgc.cam_id = wgc1.cam_id and wgc.campType = wgc1.campType) 
	FOR XML PATH ('''')),1,2,'' '') AS WGNames,
	STUFF((
	SELECT '', '' + CAST(wgc.IDWG AS VARCHAR(MAX))
	FROM #WorkGroupCamps wgc WHERE (wgc.cam_id = wgc1.cam_id and wgc.campType = wgc1.campType)
	FOR XML PATH ('''')),1,2,'' '') AS WGIDs
INTO #tmpWGconcat
FROM #WorkGroupCamps wgc1
GROUP BY cam_id, campType


select cal_id,tipo_llamada,A.cam_id,
case when a.tipo_llamada=2 then  campOut.cam_descripcion else campIn.descripcion end  AS campDescription,
A.calif_id,duracion,id_nivel_grito,age_id as user_id, U.login as [username],
	U.Nombres + '' '' +  U.ApellidoPaterno+ '' '' +  U.ApellidoMaterno as [FullName],
finicio,A.ani,dni,cal_key,cal_manual,
isnull(P.pos_id,0) as posicion,P.computer,isnull (z.total_forma,0) as total_forma, A.id_repositorio,
case when a.tipo_llamada=2 then  isnull (dispOut.[Description],'''') else isnull (dispIn.[Description],'''') end  AS score,
convert(varchar(8),DATEADD(ss, duracion, 0),114) as formato_duracion,A.grab_id,
case when a.tipo_llamada=2 then  isnull( subOut.califSubDesc ,'''') else isnull( subIn.califSubDesc ,'''') end  AS califSub_id,
a.cal_tMoh as cal_tMoh,repositorios.ruta_repositorio,
@encrypted as IsEncrypted, A.Prefijo as Prefix
INTO #tmpRecords
from RIA_GRABACION A with(nolock)
inner join #userAgent on #userAgent.userId=A.age_id
inner join trec_repositorios repositorios on repositorios.id_repositorio=A.id_repositorio
left join ccPosicion P on A.cal_extension * -1 =P.pos_id
left join (select id_grabacion,avg(total_forma) as total_forma from ria_formacalif group by id_grabacion) Z on A.grab_id=Z.id_grabacion
left join cctipocalifout AS dispOut ON A.calif_id = dispOut.calif_id and a.tipo_llamada=2
left join cctipocalifsubout subOut on subOut.califSub_id=a.califSub_id and a.tipo_llamada=2
left join cctipocalif AS dispIn ON A.calif_id = dispIn.calif_id and a.tipo_llamada=1
left join cctipocalifsub subIn on subIn.califSub_id=a.califSub_id and a.tipo_llamada=1
left join cccamps campOut on campOut.cam_id=a.cam_id and a.tipo_llamada=2
left join ccinbound campIn on campIn.Inbound_id=a.cam_id and a.tipo_llamada=1
left join ccUsers U on A.age_id=U.user_id
where 
(
(A.finicio >= @dateStart and A.finicio <=@dateEnd) or
	(@IdCallList is not null and @IdCallList <>'''')
	
)
and (
	@IdCallList is null or @IdCallList ='''' or
		A.cal_id in (select Value from dbo.fn_RIASplitDelimited(@IdCallList,'',''))
)
and (
	@UserList is null or @UserList ='''' or
		A.age_id in (select Value from dbo.fn_RIASplitDelimited(@UserList,'',''))
)
and (
	@TypeCall is null or a.tipo_llamada=@TypeCall
)
and (
	@CampaingsList is null or @CampaingsList ='''' or
	( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@CampaingsList,'','')) and a.tipo_llamada=2 )
)
and (
	@ACDList is null or @ACDList ='''' or
	( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@ACDList,'','')) and a.tipo_llamada=1 )
)
and (
	@DispositionList is null or @DispositionList ='''' or
	( A.calif_id in (select Value from dbo.fn_RIASplitDelimited(@DispositionList,'','')) )
)
and (
	@SubdispositionList is null or @SubdispositionList ='''' or
	( A.califSub_id in (select Value from dbo.fn_RIASplitDelimited(@SubdispositionList,'','')) )
)
and (
	@GrabId is null or @GrabId = 0 or
		A.grab_id > @GrabId
)
union all
select cal_id,tipo_llamada,A.cam_id,
case when a.tipo_llamada=2 then  campOut.cam_descripcion else campIn.descripcion end  AS campDescription,
A.calif_id,duracion,id_nivel_grito,age_id as user_id, U.login as [username],
	U.Nombres + '' '' +  U.ApellidoPaterno+ '' '' +  U.ApellidoMaterno as [FullName],
finicio,A.ani,dni,cal_key,cal_manual,
isnull(P.pos_id,0) posicion,P.computer,isnull (z.total_forma,0) as total_forma, A.id_repositorio,
case when a.tipo_llamada=2 then  isnull (dispOut.[Description],'''') else isnull (dispIn.[Description],'''') end  AS score,
convert(varchar(8),DATEADD(ss, duracion, 0),114) as formato_duracion,A.grab_id, 
case when a.tipo_llamada=2 then  isnull( subOut.califSubDesc ,'''') else isnull( subIn.califSubDesc ,'''') end  AS califSub_id,
a.cal_tMoh as cal_tMoh,repositorios.ruta_repositorio,
@encrypted as IsEncrypted, A.Prefijo as Prefix 
from RIA_GRABACIONConsulta A with(nolock)
inner join #userAgent on #userAgent.userId=A.age_id
inner join trec_repositorios repositorios on repositorios.id_repositorio=A.id_repositorio
left join ccPosicion P on A.cal_extension * -1 =P.pos_id
left join (select id_grabacion,avg(total_forma) as total_forma from ria_formacalif group by id_grabacion) Z on A.grab_id=Z.id_grabacion
left join cctipocalifout AS dispOut ON A.calif_id = dispOut.calif_id and a.tipo_llamada=2
left join cctipocalifsubout subOut on subOut.califSub_id=a.califSub_id and a.tipo_llamada=2
left join cctipocalif AS dispIn ON A.calif_id = dispIn.calif_id and a.tipo_llamada=1
left join cctipocalifsub subIn on subIn.califSub_id=a.califSub_id and a.tipo_llamada=1
left join cccamps campOut on campOut.cam_id=a.cam_id and a.tipo_llamada=2
left join ccinbound campIn on campIn.Inbound_id=a.cam_id and a.tipo_llamada=1
left join ccUsers U on A.age_id=U.user_id
where 
( 
(A.finicio >= @dateStart and A.finicio <=@dateEnd) or 
(@IdCallList is not null and @IdCallList <>'''')
)
and (
	@IdCallList is null or @IdCallList ='''' or
		A.cal_id in (select Value from dbo.fn_RIASplitDelimited(@IdCallList,'',''))
)
and (
	@UserList is null or @UserList ='''' or
		A.age_id in (select Value from dbo.fn_RIASplitDelimited(@UserList,'',''))
)
and (
	@TypeCall is null or a.tipo_llamada=@TypeCall
)
and (
	@CampaingsList is null or @CampaingsList ='''' or
	( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@CampaingsList,'','')) and a.tipo_llamada=2 )
)
and (
	@ACDList is null or @ACDList ='''' or
	( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@ACDList,'','')) and a.tipo_llamada=1 )
)
and (
	@DispositionList is null or @DispositionList ='''' or
	( A.calif_id in (select Value from dbo.fn_RIASplitDelimited(@DispositionList,'','')) )
)
and (
	@SubdispositionList is null or @SubdispositionList ='''' or
	( A.califSub_id in (select Value from dbo.fn_RIASplitDelimited(@SubdispositionList,'','')) )
)
and (
	@GrabId is null or @GrabId = 0 or
		A.grab_id > @GrabId
)
order by finicio

IF (@TopRecords = 0) 
BEGIN
	SELECT cal_id, tipo_llamada, tr.cam_id, campDescription, calif_id, duracion, id_nivel_grito,
	user_id, username, FullName, finicio, ani, dni, cal_key, cal_manual, posicion, computer,
	total_forma, id_repositorio, score, formato_duracion, grab_id, ISNULL(wgc.WGIDs, ''0'') IDWG, califSub_id, 
	cal_tMoh, ruta_repositorio, IsEncrypted, Prefix, ISNULL(wgc.WGNames, ''0'') WGName
	FROM #tmpRecords tr
	LEFT JOIN #tmpWGconcat wgc on tr.cam_id = wgc.cam_id and tr.tipo_llamada-1 = wgc.campType
	order by finicio
				
END
ELSE BEGIN
	SELECT TOP(@TopRecords) 
	cal_id, tipo_llamada, tr.cam_id, campDescription, calif_id, duracion, id_nivel_grito,
	user_id, username, FullName, finicio, ani, dni, cal_key, cal_manual, posicion, computer,
	total_forma, id_repositorio, score, formato_duracion, grab_id, ISNULL(wgc.WGIDs, ''0'') IDWG, califSub_id, 
	cal_tMoh, ruta_repositorio, IsEncrypted, Prefix, ISNULL(wgc.WGNames, ''0'') WGName
	FROM #tmpRecords tr
	LEFT JOIN #tmpWGconcat wgc on tr.cam_id = wgc.cam_id and tr.tipo_llamada-1 = wgc.campType
	order by finicio
END


	
IF OBJECT_ID(''tempdb..#userAgent'') IS NOT NULL
	DROP TABLE #userAgent
IF OBJECT_ID(''tempdb..#tmpRecords'') IS NOT NULL
	DROP TABLE #tmpRecords
IF OBJECT_ID(''tempdb..#WorkGroupCamps'') IS NOT NULL
	DROP TABLE #WorkGroupCamps
IF OBJECT_ID(''tempdb..#tmpWGconcat'') IS NOT NULL
	DROP TABLE #tmpWGconcat'
	EXEC(@sql)


	---------------------------------------END KR087000 Modificaciones Recordings Manager Exportacion Automatica ---------------------------------------------------------


	-------------------------------------------- End Jesus Gallardo hotfix/125.20231211.0.13 -------------------------------------------------------------------------------
	SET @process = 'CREATE table RIA_GRABACION_TEMP'
	SET @sql = 'if not exists(select * from sys.tables where name=''RIA_GRABACION_TEMP'') begin
	CREATE TABLE [dbo].[RIA_GRABACION_TEMP](
	[AvrTransferId] int,
	[tipo_llamada] [smallint] NULL,
	[cal_id] [int] NULL,
	[age_id] [int] NULL,
	[cam_id] [smallint] NULL,
	[calif_id] [smallint] NULL,
	[cal_extension] [int] NULL,
	[finicio] [datetime] NOT NULL,
	[ffin] [datetime] NOT NULL,
	[ani] [varchar](30) NOT NULL,
	[duracion] [int] NULL,
	[cal_key] [varchar](40) NOT NULL,
	[puerto_id] [int] NULL,
	[dni_id] [smallint] NULL,
	[id_repositorio] [tinyint] NULL,
	[razon_id] [tinyint] NULL,
	[tipo_grab_id] [tinyint] NULL,
	[fvalida] [datetime] NULL,
	[cal_whoHung] [smallint] NULL,
	[califSub_id] [smallint] NOT NULL,
	[cal_tMoh] [smallint] NOT NULL,
	[cal_manual] [tinyint] NULL,
	[id_nivel_grito] [int] NULL,
	[Prefijo] [varchar](512) NULL,
	[dni] [varchar](15) NULL,
	[IDWG] [varchar](800) NULL,
	[extra_info] [varchar](50) NULL,
	[extra_info2] [varchar](50) NULL	
	)	
end'
	EXEC(@sql)

	SET @process = 'CREATE INDEX IX_RIA_GRABACION_TEMP_I'
	SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = ''IX_RIA_GRABACION_TEMP_I'')
BEGIN
    -- Crea el índice utilizando las columnas tipo_llamada y cal_id
    CREATE INDEX IX_RIA_GRABACION_TEMP_I
    ON [dbo].[RIA_GRABACION_TEMP] ([tipo_llamada], [cal_id]);
END'
	EXEC(@sql)

	set @process = 'Drop SP ccsp_InsertOrUpdateRecordingRIA_Grabacion'
		set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_InsertOrUpdateRecordingRIA_Grabacion'')
BEGIN
	DROP PROCEDURE ccsp_InsertOrUpdateRecordingRIA_Grabacion
END'
		EXEC(@sql)

	SET @process = 'CREATE PROCEDURE ccsp_InsertOrUpdateRecordingRIA_Grabacion'
	SET @sql = 'CREATE PROCEDURE ccsp_InsertOrUpdateRecordingRIA_Grabacion
AS
BEGIN
    -- Declaramos una tabla temporal para almacenar grab_id, cal_id, tipo_llamada y AvrTransferId de los registros procesados
    DECLARE @ProcessedRecords TABLE (       
        grab_id BIGINT,
        cal_id INT,
        tipo_llamada INT,
		AvrTransferId int
    );

    -- Utilizamos MERGE para insertar o actualizar registros en la tabla ria_grabacion
	
    MERGE INTO ria_grabacion AS Target
    USING RIA_GRABACION_TEMP AS Source
    ON Target.cal_id = Source.cal_id AND Target.tipo_llamada = Source.tipo_llamada
    WHEN MATCHED THEN 
        UPDATE SET
            Target.calif_id = Source.calif_id,
            Target.califSub_id = Source.califSub_id,
            Target.cal_tMoh = Source.cal_tMoh,
            Target.duracion = Source.duracion,
            Target.cal_extension = Source.cal_extension,
            Target.IDWG = Source.IDWG,
            Target.extra_info = Source.extra_info,
            Target.extra_info2 = Source.extra_info2
        --OUTPUT ''UPDATE'' AS ActionType, inserted.grab_id, inserted.cal_id, inserted.tipo_llamada INTO @ProcessedRecords
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (tipo_llamada, cal_id, age_id, cam_id, calif_id, cal_extension, finicio, ffin, ani, duracion, cal_key, puerto_id, dni_id, id_repositorio, razon_id, tipo_grab_id,
                fvalida, cal_whohung, califSub_id, cal_tMoh, cal_manual, id_nivel_grito, prefijo, dni, IDWG, extra_info, extra_info2)
        VALUES (Source.tipo_llamada, Source.cal_id, Source.age_id, Source.cam_id, Source.calif_id, Source.cal_extension, Source.finicio, Source.ffin, Source.ani, Source.duracion, 
                Source.cal_key, Source.puerto_id, Source.dni_id, Source.id_repositorio, Source.razon_id, Source.tipo_grab_id, Source.fvalida, Source.cal_whohung, Source.califSub_id, 
                Source.cal_tMoh, Source.cal_manual, Source.id_nivel_grito, Source.prefijo, Source.dni, Source.IDWG, Source.extra_info, Source.extra_info2)
       
	   OUTPUT inserted.grab_id, inserted.cal_id, inserted.tipo_llamada 
	   INTO @ProcessedRecords(grab_id,cal_id,tipo_llamada)
		;
    -- Ahora añadimos el AvrTransferId a @ProcessedRecords uniendo con RIA_GRABACION_TEMP
    UPDATE PR
    SET PR.AvrTransferId = S.AvrTransferId
    FROM @ProcessedRecords PR
    INNER JOIN RIA_GRABACION_TEMP S ON PR.cal_id = S.cal_id AND PR.tipo_llamada = S.tipo_llamada;

    -- Regresamos grab_id, cal_id, tipo_llamada y AvrTransferId para los registros insertados o actualizados
    SELECT grab_id, cal_id, tipo_llamada, AvrTransferId FROM @ProcessedRecords;

    -- Limpiar la tabla temporal
    TRUNCATE TABLE RIA_GRABACION_TEMP;
END;
'
	EXEC(@sql)


	-------------------------------------------- Begin Jesus Gallardo hotfix/125.20231211.0.18 -------------------------------------------------------------------------------

	SET @process = 'feature/KR179003 CREATE TABLE [dbo].[RIA_GRABACION_TEMP]'
	SET @sql = 'if not exists(select * from sys.tables where name=''RIA_GRABACION_TEMP'') begin
	CREATE TABLE [dbo].[RIA_GRABACION_TEMP](
	[AvrTransferId] int,
	[tipo_llamada] [smallint] NULL,
	[cal_id] [int] NULL,
	[age_id] [int] NULL,
	[cam_id] [smallint] NULL,
	[calif_id] [smallint] NULL,
	[cal_extension] [int] NULL,
	[finicio] [datetime] NOT NULL,
	[ffin] [datetime] NOT NULL,
	[ani] [varchar](30) NOT NULL,
	[duracion] [int] NULL,
	[cal_key] [varchar](40) NOT NULL,
	[puerto_id] [int] NULL,
	[dni_id] [smallint] NULL,
	[id_repositorio] [tinyint] NULL,
	[razon_id] [tinyint] NULL,
	[tipo_grab_id] [tinyint] NULL,
	[fvalida] [datetime] NULL,
	[cal_whoHung] [smallint] NULL,
	[califSub_id] [smallint] NOT NULL,
	[cal_tMoh] [smallint] NOT NULL,
	[cal_manual] [tinyint] NULL,
	[id_nivel_grito] [int] NULL,
	[Prefijo] [varchar](512) NULL,
	[dni] [varchar](15) NULL,
	[IDWG] [varchar](800) NULL,
	[extra_info] [varchar](50) NULL,
	[extra_info2] [varchar](50) NULL	
	)

	
end
'
	EXEC(@sql)

	SET @process = 'feature/KR179003 CREATE INDEX IX_RIA_GRABACION_TEMP_I'
	SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = ''IX_RIA_GRABACION_TEMP_I'')
BEGIN
    -- Crea el índice utilizando las columnas tipo_llamada y cal_id
    CREATE INDEX IX_RIA_GRABACION_TEMP_I
    ON [dbo].[RIA_GRABACION_TEMP] ([tipo_llamada], [cal_id]);
END'
	EXEC(@sql)


  	
    SET @process = 'feature/KR179003 Drop procedure ccsp_InsertOrUpdateRecordingRIA_Grabacion'
    SET @sql = 'if exists (select 1 from sys.procedures where name = N''ccsp_InsertOrUpdateRecordingRIA_Grabacion'')
                begin
                    DROP PROCEDURE ccsp_InsertOrUpdateRecordingRIA_Grabacion;
                end'
    EXEC(@sql);


	SET @process = 'feature/KR179003 Create SP ccsp_InsertOrUpdateRecordingRIA_Grabacion'
	SET @sql = 'CREATE PROCEDURE ccsp_InsertOrUpdateRecordingRIA_Grabacion
AS
BEGIN
    -- Declaramos una tabla temporal para almacenar grab_id, cal_id, tipo_llamada y AvrTransferId de los registros procesados
    DECLARE @ProcessedRecords TABLE (       
        grab_id BIGINT,
        cal_id INT,
        tipo_llamada INT,
		AvrTransferId int
    );

    -- Utilizamos MERGE para insertar o actualizar registros en la tabla ria_grabacion
	
    MERGE INTO ria_grabacion AS Target
    USING RIA_GRABACION_TEMP AS Source
    ON Target.cal_id = Source.cal_id AND Target.tipo_llamada = Source.tipo_llamada
    WHEN MATCHED THEN 
        UPDATE SET
            Target.calif_id = Source.calif_id,
            Target.califSub_id = Source.califSub_id,
            Target.cal_tMoh = Source.cal_tMoh,
            Target.duracion = Source.duracion,
            Target.cal_extension = Source.cal_extension,
            Target.IDWG = Source.IDWG,
            Target.extra_info = Source.extra_info,
            Target.extra_info2 = Source.extra_info2
        --OUTPUT ''UPDATE'' AS ActionType, inserted.grab_id, inserted.cal_id, inserted.tipo_llamada INTO @ProcessedRecords
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (tipo_llamada, cal_id, age_id, cam_id, calif_id, cal_extension, finicio, ffin, ani, duracion, cal_key, puerto_id, dni_id, id_repositorio, razon_id, tipo_grab_id,
                fvalida, cal_whohung, califSub_id, cal_tMoh, cal_manual, id_nivel_grito, prefijo, dni, IDWG, extra_info, extra_info2)
        VALUES (Source.tipo_llamada, Source.cal_id, Source.age_id, Source.cam_id, Source.calif_id, Source.cal_extension, Source.finicio, Source.ffin, Source.ani, Source.duracion, 
                Source.cal_key, Source.puerto_id, Source.dni_id, Source.id_repositorio, Source.razon_id, Source.tipo_grab_id, Source.fvalida, Source.cal_whohung, Source.califSub_id, 
                Source.cal_tMoh, Source.cal_manual, Source.id_nivel_grito, Source.prefijo, Source.dni, Source.IDWG, Source.extra_info, Source.extra_info2)
       
	   OUTPUT inserted.grab_id, inserted.cal_id, inserted.tipo_llamada 
	   INTO @ProcessedRecords(grab_id,cal_id,tipo_llamada)
		;
    -- Ahora añadimos el AvrTransferId a @ProcessedRecords uniendo con RIA_GRABACION_TEMP
    UPDATE PR
    SET PR.AvrTransferId = S.AvrTransferId
    FROM @ProcessedRecords PR
    INNER JOIN RIA_GRABACION_TEMP S ON PR.cal_id = S.cal_id AND PR.tipo_llamada = S.tipo_llamada;

    -- Regresamos grab_id, cal_id, tipo_llamada y AvrTransferId para los registros insertados o actualizados
    SELECT grab_id, cal_id, tipo_llamada, AvrTransferId FROM @ProcessedRecords;

    -- Limpiar la tabla temporal
    TRUNCATE TABLE RIA_GRABACION_TEMP;
END;
'
	EXEC(@sql)

	SET @process = 'Drop procedure trsp_InsertRecNodeGrabIds'
    SET @sql = 'if exists (select * from sys.procedures where name = N''trsp_InsertRecNodeGrabIds'')
    begin
        DROP PROCEDURE trsp_InsertRecNodeGrabIds;
    end'
    EXEC(@sql)


	SET @process = 'feature/KR179003 Alter SP trsp_InsertRecNode'
	SET @sql = 'CREATE PROCEDURE [dbo].[trsp_InsertRecNodeGrabIds]
@grabIds varchar(8000),
@rateEvaluationFormatKolob int = -1
AS
BEGIN
    declare @grabIdTmp table(grabId bigint primary key)
    declare @tEvaluationTmp table(grabId bigint primary key,total float)    
    DECLARE @XMLTable TABLE (grab_id INT, dateIn datetime, [node] xml, [status] bit);
    
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
    C30 BIT             ------> LLamada VoiceMail @extraInfo 2
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
    ,cal_extension
    FROM ria_grabacion rec with(nolock)
    inner join @grabIdTmp t on rec.grab_id=t.grabId
    left join @tEvaluationTmp E on t.grabId=E.grabId    
    UNION ALL
    SELECT rec.grab_id, rec.tipo_llamada, '''' AS Prefijo, rec.cal_manual, rec.id_nivel_grito, 
    rec.cal_id, rec.finicio, rec.extra_info, rec.extra_info2, NULL AS video,
    isnull(E.total,0) AS total_forma
    ,calif_id,cam_id,duracion,ani,dni,cal_key,id_repositorio,califSub_id,age_id
    ,cal_extension
    FROM RIA_GRABACIONCONSULTA rec with(nolock)
    inner join @grabIdTmp t on rec.grab_id=t.grabId
    left join @tEvaluationTmp E on t.grabId=E.grabId
)
INSERT INTO @RecNodeTable
SELECT 
rec.finicio,
CONVERT(VARCHAR(23), rec.finicio, 126) AS ''@CDATE'',
rec.cam_id AS ''@CID'',
rec.tipo_llamada AS ''@CType'',
rec.grab_id AS ''@C01'',
CASE WHEN rec.tipo_llamada = 1 THEN ''Inbound'' ELSE ''Outbound'' END AS ''@C02'',
CASE WHEN rec.tipo_llamada = 1 THEN inb.descripcion ELSE outb.cam_descripcion END AS ''@C03'',
ISNULL(rec.id_nivel_grito, -1) AS ''@C04'',
ISNULL(usr.LOGIN, ''N/A'') AS ''@C05'',
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
ISNULL(usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno, ''N/A'') AS ''@C23'',
'''' AS ''@C24'',
'''' AS ''@C25'',
isnull(grap.graphic_id,1) AS ''@C26'',
rec.Prefijo AS ''@C27'',    
case when  rec.califSub_id<=0 then ''N/A'' when rec.tipo_llamada = 1 then subDisposition.califSubDesc  when rec.tipo_llamada = 2 then subDispositionOut.califSubDesc end  AS ''@C28'',    
CONVERT(BIT, ISNULL(rec.extra_info, ''1'')) AS ''@C29'',
CONVERT(BIT, ISNULL(rec.extra_info2, ''0'')) AS ''@C30''
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


insert into @XMLTable (grab_id,status, dateIn, node)       
SELECT  
    C01,0 [status],[date],
    case when C03 is null then null 
    when (C30=0 and C05 is not null and C20 is not null and C28 is not null) or  (C30=1) then   
    (
        SELECT 
            CDATE AS "@CDATE",
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
            C30 AS "@C30"
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

    SET @process = 'feature/KR179003 Alter SP trsp_InsertRecNode'
    SET @sql = 'ALTER PROCEDURE [dbo].[trsp_InsertRecNode]
@grabId INT, 
@type INT = 0, 
@rateEvaluationFormatKolob BIT = 0
AS
BEGIN
    declare @grabIds varchar(8000)
    set @grabIds=convert(varchar(20),@grabId)
   exec trsp_InsertRecNodeGrabIds @grabIds=@grabIds,@rateEvaluationFormatKolob=@rateEvaluationFormatKolob

END'
    EXEC(@sql)

    -- SET @PROCESS = 'FEATURE/KR179003 ALTER SP '
    -- SET @SQL = ''
    -- EXEC(@SQL)


	-------------------------------------------- End Jesus Gallardo hotfix/125.20231211.0.18 -------------------------------------------------------------------------------

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
