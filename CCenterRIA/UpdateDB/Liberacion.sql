/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K089000

Database: CCenterRia
Required version: 125.37

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 46
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	    -----------------------------------------------------BEGIN hotfix/125.20231211.0.4 Jesus Gallardo  ----------------------------------------------------------------

         SET @process = 'Create table replicationMergeClean '
        SET @sql = 'if not exists(select * from sys.tables where name=''replicationMergeClean'')begin
create table replicationMergeClean (
dateStart datetime not null,
dateEnd datetime not null,
num_genhistory_rows int not null,
num_contents_rows int not null,
num_tombstone_rows int not null,
MSmerge_contents int not null,
MSmerge_genhistory int not null,
MSmerge_tombstone  int not null,
)
end
'
        EXEC(@sql);


        SET @process = 'Add Column ccSmsConversationsResult.Exception int'
        SET @sql = 'if not exists (select * from sys.columns where name = N''Exception'' and Object_ID = Object_ID(N''ccSmsConversationsResult''))
begin
    alter table ccSmsConversationsResult add Exception int null
end'
        EXEC(@sql);

        SET @process = 'update ccSmsConversationsResult set Exception=0 where Exception is null'
        SET @sql = 'update ccSmsConversationsResult set Exception=0 where Exception is null'
        EXEC(@sql);

        SET @process = ''
        SET @sql = ''
        EXEC(@sql);

        SET @process = ''
        SET @sql = ''
        EXEC(@sql);

        SET @process = ''
        SET @sql = ''
        EXEC(@sql);

        SET @process = ''
        SET @sql = ''
        EXEC(@sql);


        SET @process = 'Alter SP ccspSaveDispositionResult Se agrega With(nolock)'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccspSaveDispositionResult]
@action int,
@callType TINYINT=null,
@camId int =null,
@callid BIGINT=0,
@statusCallId int=0,
@dispotitionId int=null,
@subDispotitionId int=null
AS

declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
declare @callTypeInOut tinyint
if @action in(3,4) begin
    select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end
    from ccsettings where setting_id = 27 -- 0 esp
    
end
if @action in(5,6) begin    
    select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
    from ccsettings where setting_id = 27 -- 0 esp  
end

set @callTypeInOut= case when @callType=1 then 0 else 1 end


if @action=0 begin
    declare @today date
    set @today =CONVERT(date,getdate())

    truncate table ccDispositionDashboardResultOut
    truncate table ccDispositionDashboardResultIn

    insert into ccDispositionDashboardResultOut
    select cam_id as CamId,statusCall_id as statusCallId,cal_id as callId
    ,calif_id as Disposition
    ,case  when califSub_id<=0 or califSub_id is null then 0 else califSub_id end as SubDispotitionId 
    from ccoCallsOut 
    where cal_Inicio>=@today

    insert into ccDispositionDashboardResultIn
    select Inbound_id as CamId,statusCall_id as statusCallId,cal_id as callId
    ,calif_id as Disposition
    ,case  when califSub_id<=0 or califSub_id is null then 0 else califSub_id end as SubDispotitionId 
    from ccCallsIn 
    where cal_Inicio>=@today
end
else if @action=1 begin
    set @dispotitionId=0
    set @subDispotitionId=0
    if @callType=1 begin
        insert into ccDispositionDashboardResultOut values(@camId,@statusCallId,@callid,@dispotitionId,@subDispotitionId)
    end
    else begin
        insert into ccDispositionDashboardResultIn values(@camId,@statusCallId,@callid,@dispotitionId,@subDispotitionId)
    end
end
else if @action=2 begin
    set @subDispotitionId=case when @subDispotitionId is null then null when @subDispotitionId>0 then @subDispotitionId else 0 end
    if @callType=1 begin
        update ccDispositionDashboardResultOut set statusCallId=@statusCallId,DispotitionId=isnull(@dispotitionId,DispotitionId)
        ,SubDispotitionId=isnull(@subDispotitionId,SubDispotitionId)
        where callId=@callid 
    end
    else begin
        update ccDispositionDashboardResultIn set statusCallId=@statusCallId,DispotitionId=isnull(@dispotitionId,DispotitionId)
        ,SubDispotitionId=isnull(@subDispotitionId,SubDispotitionId)
        where callId=@callid 
    end
end
else if @action=3 begin 
    select @callTypeInOut as tipo,dash.CamId as CamId
    ,case when dash.statusCallId = 13 then
        case when ca.[description] is not null then ca.[description] else @nIdioma end
        else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma end
    end as Calificacion
    ,case when count( case when dash.SubDispotitionId>0 then 1 end ) > 0 then 1 else 0 end as WithSubDisposition
    ,dash.DispotitionId as DispotitionId
    ,count(*) Amount
    ,ISNULL(GraphColor,''1DB4E2'') GraphColor
    ,CASE WHEN ISNULL(rel.calif_id, 0) = 0 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS IsSubDisp
    from ccDispositionDashboardResultOut dash with(nolock)
    left join ccTipoCalifOut ca on dash.DispotitionId = ca.calif_id 
    left join ccTipoCalifSubOUT tcsout on dash.SubDispotitionId = tcsout.califSub_id
    left join ccstatusllamada sll on sll.statuscall_id = dash.statusCallId
    left join ccCamps ci on ci.cam_id = dash.CamId
    LEFT join cctipoSubCalifRel rel on rel.calif_id = ca.calif_id and dash.SubDispotitionId = rel.califSub_id and tipoSubRel = 0
    where CamId=@camId
    group by  dash.CamId, dash.statusCallId,ca.[description],sll.descripcion,dash.DispotitionId,GraphColor,rel.calif_id

end
else if @action=4 begin 
    select @callTypeInOut as tipo
    ,dash.CamId
    ,case when ca.[Description] is not null then ca.[Description] else @nIdioma end as Calificacion
    ,case when count( case when dash.SubDispotitionId>0 then 1 end ) > 0 then 1 else 0 end as WithSubDisposition
    ,dash.DispotitionId
    ,count(*)  as Amount
    ,ISNULL(GraphColor,''1DB4E2'') GraphColor
    ,0 IsSubDisp
    from ccDispositionDashboardResultIn dash with(nolock)
    left join ccTipoCalif ca on dash.DispotitionId = ca.calif_id 
    left join ccInbound cci on cci.inbound_id = dash.CamId 
    where dash.CamId = @camId and dash.statusCallId = 13 
    group by ca.[Description], dash.CamId,dash.SubDispotitionId,dash.DispotitionId,GraphColor

end

else if @action=5 begin 
    select 0 as Type,co.CamId as CampId,
    case when co.statusCallId = 13
    then case when description is not null
    then description else @nIdioma end
    else
    case when sll.descripcion is not null
    then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma
    end
    end as Calification,
    isnull(cso.califSubDesc,@nIdiomaSub) as SubCalificationName ,count(cso.califSub_id) Quantity
    from ccDispositionDashboardResultOut co
    left join ccTipoCalifOut ca on co.DispotitionId = ca.calif_id
    left join ccTipoCalifSubOUT cso on co.SubDispotitionId = cso.califSub_id 
    left join ccstatusllamada sll on sll.statuscall_id = co.statusCallId
    left join ccCamps ci on ci.cam_id = co.CamId
    where co.CamId = @camId
    and co.DispotitionId = @dispotitionId
    group by  co.CamId, co.statusCallId,description,descripcion,cso.califSubDesc
end
else if @action=6 begin 
    select 0 as [type],CamId as CampId
    , ca.[description] as Calification
    , isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName
    , count(ctcs.califSubDesc) as Quantity
    --,dash.DispotitionId
    from ccDispositionDashboardResultIn dash
    left join ccTipoCalif ca on dash.DispotitionId = ca.calif_id
    left join ccInbound cci on cci.inbound_id = dash.CamId
    left join ccTipoCalifSub ctcs on dash.SubDispotitionId = ctcs.califSub_id
    where dash.CamId=@camId and dash.statusCallId=13 and dash.DispotitionId=@dispotitionId
    group by ca.description, dash.CamId,ctcs.califSubDesc,dash.DispotitionId
end
'
        EXEC(@sql);

       

       

        SET @process = 'Alter SP ccsp_GalateaGetCampsNvosCB Se quita proceso que no ocupa Kolob y se agrega agrupacion para no poner datos dobles @TotalNew'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0, @tcpa int=0
as
set nocount on

declare @TipoJobs as int, @isExecOutbound bit

set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

    declare @id AS INTEGER;

    CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,campType INT)
    CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime,campType INT)

    create table #tempoutsource (cam_id int,Pend  int)

    create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

    if @cam_id = 0 begin
        if @user_id > 0 and not exists (select 1 from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
            insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
            select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
            ,isnull(cam.CampType,0) as CampType
            from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
            where user_id = @user_id and tipo = 1
        end
        else begin
            insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
            select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
            ,isnull(cam.CampType,0) as CampType
            from ccCamps cam (nolock)
        end
    end
    else begin
        if @Tipo = 2
            insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
            select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
            ,isnull(cam.CampType,0) as CampType
            from ccCamps cam with(nolock) 
            where cam.cam_id = @cam_id
        else
            if @user_id > 0 and not exists (select 1 from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
                insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
                select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
                ,isnull(cam.CampType,0) as CampType
                from ccCamps cam with(nolock) 
                inner join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
                where user_id = @user_id and tipo = 1 and cam.cam_id = @cam_id
            end
            else begin
                insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
                select cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
                ,isnull(cam.CampType,0) as CampType
                from ccCamps cam (nolock) 
                where cam_activo=1  and cam.cam_id = @cam_id
            end
    end
    
    ;with ccCampsNvosCBTmp as(
    select A.*,dateUpdate from #Tcamps A
    left join ccCampsNvosCB B (nolock) on A.cam_id=B.id
    where datediff(ss,B.dateUpdate,getdate())> case @tcpa when 1 then 1 else 5 end or B.dateUpdate is null
    )
    insert into #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,dateUpdate,campType)
    select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0,max(dateUpdate),max(campType) as campType 
    from ccCampsNvosCBTmp
    group by cam_id

    if exists(select 1 from #Tcamps2) BEGIN

        if exists(select 1 from #Tcamps2 where campType=7) BEGIN
            insert into #tempoutsource(cam_id,Pend)
            SELECT sos.cam_id, count(sos.cam_id) as Pend
            FROM dbo.smsOutSource AS sos  with(index(IX_smsOutSource_1),nolock)
            inner join #Tcamps2 tcam on sos.cam_id = tcam.cam_id
            WHERE tcam.campType=7 and sos.sms_status in(0, 7)
            GROUP BY sos.cam_id

            insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
            SELECT swt.cam_id,
            count(case swt.sms_status when 0 then 1 else null end) as New,
            count(case swt.sms_status when 1 then 1 else null end) as Cb,
            count(case swt.sms_status when 2 then 1 else null end) as Pro,
            count(case swt.sms_status when 3 then 1 else null end) as Fin
            FROM dbo.smsWorkingTable AS swt  with(index(IX_smsWorkingTable_1),nolock)
            inner join #Tcamps2 B on swt.cam_id = B.cam_id 
            where B.campType=7
            GROUP BY swt.cam_id 
        end
            insert into #tempoutsource(cam_id,Pend)
            SELECT ccos.cam_id, count(ccos.cam_id) as Pend
            FROM ccocallsoutsource ccos with(index(IX_ccoCallsOutSource_17),nolock)
            join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
            WHERE tcam.campType<>7 and cal_status in(0, 7)
            GROUP BY ccos.cam_id

            insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
            SELECT A.cam_id,
            count(case cal_status when 0 then 1 else null end) as New,
            count(case cal_status when 1 then 1 else null end) as Cb,
            count(case cal_status when 2 then 1 else null end) as Pro,
            count(case cal_status when 3 then 1 else null end) as Fin
            FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
            inner join #Tcamps2 B on A.cam_id = B.cam_id
            WHERE B.campType<>7 
            GROUP BY A.cam_id   
        
        if (@regval = 0 and @cam_id >0 and @Tipo =2) or @tcpa = 1 begin
            update #Tcamps2 set status =1,cantidad=0  where cam_id = @cam_id
        end        

        declare @TotalNew table(
            cam_id int primary key,
            OverallTotalNew int 
            )
        


            insert into @TotalNew
        select CampNvosCB.id,max(isnull( CASE WHEN CampNvosCB.OverallTotalNew = 0 THEN NULL ELSE CampNvosCB.OverallTotalNew END,CampNvosCB.new) )
        from ccCampsNvosCB CampNvosCB with(nolock)
        inner join #Tcamps2 tcamp on CampNvosCB.id = tcamp.cam_id
        group by CampNvosCB.id

            delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
            where CampNvosCB.id = tcamp.cam_id

            INSERT into ccCampsNvosCB 
        SELECT distinct cams.cam_id, cams.cam_descripcion,
            isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
            isNull(cs.Pend,0) as pend,
            isNull(wt.Pro,0) as pro,
            isNull(cams.procesando,0) cam_procesando,
            isNull(cams.cam_tipojobs,0) cam_tipojobs,
            isNull(wt.Fin,0) Fin,
            isNull(cams.cantidad,0) cantidad,
            getdate(),
            isnull(T.OverallTotalNew,0)  as OverallTotalNew
            FROM #Tcamps2 cams with(nolock)
            LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
            LEFT JOIN #tempoutsource cs on cams.cam_id = cs.cam_id
            LEFT JOIN @TotalNew  T on T.cam_id = cams.cam_id

    end

    if @isExecOutbound = 0 begin

    if @Tipo = 2 begin
        -- devuelve resultado de la taba, solo las camps del usuario
        SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, cc.cam_procesando as st, res.job, res.Fin, 
        isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial,cc.aggressionFactor, OverallTotalNew
        FROM #Tcamps tcam
        left join  ccCampsNvosCB res (nolock) on tcam.cam_id  = res.id
        LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
        inner join cccamps cc (nolock) on res.id=cc.cam_id
    end
    else 
        SELECT id, campaña, new, cb, pro, pen,cc.cam_procesando as st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial,
        cc.aggressionFactor, OverallTotalNew
        FROM ccCampsNvosCB res (nolock)
        LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
        inner join cccamps cc (nolock) on res.id=cc.cam_id
        WHERE res.id = @cam_id
    end

    drop table #Tcamps
    drop table #Tcamps2
    drop table #tempoutsource
    drop table #temWorkinTable

    return(0)

end

set nocount off'
        EXEC(@sql);

        SET @process = 'Alter Sp ccsp_GalateaArtificialIntelligence IF @option = 7 obtener el ultimo id de la carga'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaArtificialIntelligence] 

@option AS SMALLINT, 
@tableName varchar(255) = null,
@tableNameTmpIA varchar(255) = null,
@columnNameId varchar(255) = null,
@dateLastCheck datetime = null,
@columnWhereDays varchar(255)=null,
@EnableOrDisableTrigger bit =0,
@listLoadings varchar(8000) =null,
@IAState int =null

AS
BEGIN
SET NOCOUNT ON;

DECLARE @object_name SYSNAME, @object_id INT;
DECLARE @SQL NVARCHAR(MAX) = '''', @primaryKey NVARCHAR(max), @CONSTRAINT NVARCHAR(max) = ''''
DECLARE @columns XML,@index nvarchar(max)=''''

IF @option in(0,1) begin
    SELECT @object_name = ''['' + s.name + ''].['' + o.name + '']'', @object_id = o.object_id
    FROM sys.objects AS o WITH (NOWAIT)
    INNER JOIN sys.schemas AS s WITH (NOWAIT) ON o.schema_id = s.schema_id
    WHERE o.name = @tableName AND o.type = ''U'' AND o.is_ms_shipped = 0;
end

IF @option = 0   --Create Table
BEGIN  
    SET @columns = (
    SELECT CHAR(9) + '', ['' + c.name + ''] '' 
    + CASE 
    WHEN c.is_computed = 1
        THEN ''AS '' + cc.DEFINITION
    ELSE UPPER(tp.name) + CASE 
            WHEN tp.name IN (''varchar'', ''char'', ''varbinary'', ''binary'', ''text'')
                THEN ''('' + CASE 
                        WHEN c.max_length = - 1
                            THEN ''MAX''
                        ELSE CAST(c.max_length AS VARCHAR(5))
                        END + '')''
            WHEN tp.name IN (''nvarchar'', ''nchar'', ''ntext'')
                THEN ''('' + CASE 
                        WHEN c.max_length = - 1
                            THEN ''MAX''
                        ELSE CAST(c.max_length / 2 AS VARCHAR(5))
                        END + '')''
            WHEN tp.name IN (''datetime2'', ''time2'', ''datetimeoffset'')
                THEN ''('' + CAST(c.scale AS VARCHAR(5)) + '')''
            WHEN tp.name = ''decimal''
                THEN ''('' + CAST(c.precision AS VARCHAR(5)) + '','' + CAST(c.scale AS VARCHAR(5)) + '')''
            ELSE ''''
            END + CASE 
            WHEN c.collation_name IS NOT NULL
                THEN '' COLLATE '' + c.collation_name
            ELSE ''''
            END + CASE 
            WHEN c.is_nullable = 1
                THEN '' NULL''
            ELSE '' NOT NULL''
            END  
                
    END + CHAR(13) 
    FROM sys.columns AS c WITH (NOWAIT)
    INNER JOIN sys.types AS tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id
    --inner join @tableColumn T on c.name=T.columnName
    LEFT JOIN sys.computed_columns AS cc WITH (NOWAIT) ON c.object_id = cc.object_id
        AND c.column_id = cc.column_id
    LEFT JOIN sys.default_constraints AS dc WITH (NOWAIT) ON c.default_object_id != 0
        AND c.object_id = dc.parent_object_id
        AND c.column_id = dc.parent_column_id
    LEFT JOIN sys.identity_columns AS ic WITH (NOWAIT) ON c.is_identity = 1
        AND c.object_id = ic.object_id
        AND c.column_id = ic.column_id
    WHERE c.object_id = @object_id
        AND c.name <> ''rowguid''
    ORDER BY c.column_id
    FOR XML PATH(''''), TYPE
    )

    SELECT @primaryKey = isnull(CHAR(9) + '', CONSTRAINT ['' + k.name + ''] PRIMARY KEY ('' + (
                SELECT STUFF((
                            SELECT '', ['' + c.name + ''] '' + CASE WHEN ic.is_descending_key = 1 THEN ''DESC'' ELSE ''ASC'' END
                            FROM sys.index_columns AS ic WITH (NOWAIT)
                            INNER JOIN sys.columns AS c WITH (NOWAIT) ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                            WHERE ic.is_included_column = 0 AND ic.object_id = k.parent_object_id AND ic.index_id = k.unique_index_id
                            FOR XML PATH(N''''), TYPE
                            ).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''')
                ) + '')'' + CHAR(13), '''') + '')'' + CHAR(13)
    FROM sys.key_constraints AS k WITH (NOWAIT)
    WHERE k.parent_object_id = @object_id AND k.type = ''PK'';


    SELECT @SQL = ''CREATE TABLE '' + @object_name + CHAR(13) + ''('' + CHAR(13)  + CHAR(9)+'' ''
    + STUFF((@columns).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''')
    + isnull(@primaryKey,'')'')
    + @CONSTRAINT
    + @index

    select @SQL as [query];

END;

ELSE IF @option = 1  -- Alter Table Add Column
BEGIN
    SELECT  
    ''if not exists (select * from sys.columns where name = N'''''' + c.name + '''''' and Object_ID = Object_ID(N'''''' + @tableName + 
        '''''')) begin '' + ''ALTER TABLE '' + @tableName + '' ADD ['' + c.name + ''] '' + CASE 
    WHEN c.is_computed = 1
        THEN ''AS '' + cc.DEFINITION
    ELSE UPPER(tp.name) + CASE 
            WHEN tp.name IN (''varchar'', ''char'', ''varbinary'', ''binary'', ''text'')
                THEN ''('' + CASE 
                        WHEN c.max_length = - 1
                            THEN ''MAX''
                        ELSE CAST(c.max_length AS VARCHAR(5))
                        END + '')''
            WHEN tp.name IN (''nvarchar'', ''nchar'', ''ntext'')
                THEN ''('' + CASE 
                        WHEN c.max_length = - 1
                            THEN ''MAX''
                        ELSE CAST(c.max_length / 2 AS VARCHAR(5))
                        END + '')''
            WHEN tp.name IN (''datetime2'', ''time2'', ''datetimeoffset'')
                THEN ''('' + CAST(c.scale AS VARCHAR(5)) + '')''
            WHEN tp.name = ''decimal''
                THEN ''('' + CAST(c.precision AS VARCHAR(5)) + '','' + CAST(c.scale AS VARCHAR(5)) + '')''
            ELSE ''''
            END + CASE 
            WHEN c.collation_name IS NOT NULL
                THEN '' COLLATE '' + c.collation_name
            ELSE ''''
            END + CASE 
            WHEN c.is_nullable = 1
                THEN '' NULL''
            ELSE '' NOT NULL''
            END  
                
    END + CHAR(13) + '' end'' as [query]
    FROM sys.columns AS c WITH (NOWAIT)
    INNER JOIN sys.types AS tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id
    --inner join @tableColumn T on c.name=T.columnName
    LEFT JOIN sys.computed_columns AS cc WITH (NOWAIT) ON c.object_id = cc.object_id
    AND c.column_id = cc.column_id
    LEFT JOIN sys.default_constraints AS dc WITH (NOWAIT) ON c.default_object_id != 0
    AND c.object_id = dc.parent_object_id
    AND c.column_id = dc.parent_column_id
    LEFT JOIN sys.identity_columns AS ic WITH (NOWAIT) ON c.is_identity = 1
    AND c.object_id = ic.object_id
    AND c.column_id = ic.column_id
    WHERE c.object_id = @object_id
    AND c.name <> ''rowguid''
    ORDER BY c.column_id

END;

ELSE IF @option = 2  -- Get Tables Configuration
BEGIN
    update [ccAIReplicaConfiguration] set dateLastCheck=null;
    
    SELECT idConfig,
    tableName,
    columnPrimaryKey,
    triggerName,
    active,
    timeCheck,
    dateLastCheck,
    columnWhereDays,
    isnull(copyContent,1)  as copyContent FROM [ccAIReplicaConfiguration] WHERE active = 1


End;

ELSE IF @option = 3  -- Get DataTable
BEGIN   
    DECLARE @params NVARCHAR(4000) = ''@dateLastCheck datetime''
    
    if @dateLastCheck is not null begin
        set @SQL=''select B.* from ''+@tableNameTmpIA+ '' A with(nolock) 
        inner join '' +@tableName+'' B with(nolock) on A.''+@columnNameId+''=B.''+@columnNameId+''
        where A.dateUpdate>@dateLastCheck ''
    end
    else begin
        declare @where NVARCHAR(MAX) = ''''
        declare @datenow datetime= dateadd(dd,-30,convert(date,getdate()))
        set @dateLastCheck=@datenow
        if @columnWhereDays is not null or @columnWhereDays<>'''' begin
            set @where='' where ''+@columnWhereDays+''>@dateLastCheck''
        end

        set @SQL=''select A.* from ''+@tableName +'' A with(nolock) ''
        + case when @tableName in(''ccUsers'') then '' '' else
         ''inner join ccCamps c with(nolock) on c.cam_id=A.cam_id and c.CampType=4 '' end
         + @where
    end

    
    if @tableName=''ccRIALoading'' begin
    set @SQL=@SQL+'' and ia_state=1 ''
    end
    
    print @SQL
    --select @dateLastCheck
    EXEC sp_executesql @SQL, @params, @dateLastCheck=@dateLastCheck;
End;

ELSE IF @option = 4   -- Enable and Disable trigger
BEGIN
    declare @command varchar(10) = case when @EnableOrDisableTrigger=0 then ''DISABLE'' else ''ENABLE'' end
    declare @i int
    declare @tmpTable table(idConfig SMALLINT primary key,
    tableName varchar(255) not null,
    triggerName varchar(255) not null,status bit
    )
    insert into @tmpTable
    select idConfig,tableName,triggerName,0 from ccAIReplicaConfiguration
    while exists(select * from @tmpTable where status=0) begin
        select top 1 @columnNameId=triggerName,@tableName=tableName,@i=idConfig from @tmpTable where status=0

        set @SQL=@command+'' TRIGGER ''+@columnNameId+'' ON ''+@tableName
        update @tmpTable set status=1 where idConfig=@i
        --print(@sql)
        exec (@SQL)
        
    end
End;

ELSE IF @option = 5   -- Update Last Check Date
BEGIN
    IF EXISTS (SELECT * FROM ccAIReplicaConfiguration WHERE tableName = @tableName)
    BEGIN
        UPDATE ccAIReplicaConfiguration SET dateLastCheck = @dateLastCheck WHERE tableName = @tableName
    END;
End;

ELSE IF @option = 6   -- Erase Temporary Tables Data
BEGIN
declare @id int

declare @tableTruncate table(
    id int identity primary key,
    tableName varchar(255) not null,
    status bit not null
)
    insert into @tableTruncate(tableName,status)
    select tableName+''TmpIA'',0 from [ccAIReplicaConfiguration]
    while exists(select * from @tableTruncate where status=0) begin
        select top 1 @id=id,@tableNameTmpIA=tableName from @tableTruncate where status=0
            set @sql=''IF EXISTS (SELECT * FROM sys.tables WHERE name = N''''''+@tableNameTmpIA+'''''')
        BEGIN
            TRUNCATE TABLE ''+@tableNameTmpIA+''
        END;''
        exec (@sql)
        update  @tableTruncate set status=1 where @id=id
    end

    update [ccAIReplicaConfiguration] set dateLastCheck=null;
    SELECT CAST(1 AS BIT) AS Result
End;
ELSE IF @option = 7   -- List Loading
BEGIN
    declare @tableRegistry table(
    LoadId int not null,    
    ListId int not null,
    CamId int not null
    )
    insert into @tableRegistry
    select A.load_id,A.list_id,A.cam_id from ccRIALoading A 
    inner join ccCamps C on A.cam_id=C.cam_id and C.CampType=4
    where (@dateLastCheck is null or A.loadDate>=@dateLastCheck) and A.ia_state=1 and pctg=100
    order by loadDate 
    if exists(select * from @tableRegistry) begin
        select max(A.LoadId) LoadId,max(A.ListId) ListId,A.CamId,B.callout_id as CalloutId from @tableRegistry A
        inner join ccoCallsOutSource B on A.listId=B.list_id
        group by A.CamId,B.callout_id
        order by CalloutId
    end
End;

ELSE IF @option = 8 and @listLoadings is not null  -- update State Loading
BEGIN
    
    update B set B.ia_state=@IAState from  dbo.fn_RIASplitDelimited(@listLoadings,'','') A
    inner join ccRIALoading B on A.value=B.load_id

    if @IAState =2 begin
        select @dateLastCheck= max(B.loadDate) from  dbo.fn_RIASplitDelimited(@listLoadings,'','') A
        inner join ccRIALoading B on A.value=B.load_id

        update [ccAIReplicaConfiguration] set dateLastCheck=@dateLastCheck where tableName=''ccRIALoading''
    end
    
End;
ELSE IF @option = 9  -- update State Loading
BEGIN
    update B set B.cal_fechaDial=A.DateDial from cc_CalloutDateIA A
    inner join ccoCallsOutSource B on A.CalloutId=B.callout_id
    

End;
End;
'
        EXEC(@sql);

        SET @process = 'Alter SP ccsp_GalateaAdminCampaigns'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] 
@Option AS      SMALLINT, 
@CampType AS    SMALLINT = 0, 
@WorkgroupId AS INT      = 0, 
@Id AS          INT      = 0, 
@AdminId AS     SMALLINT = 0, 
@PinUpdate AS   SMALLINT = 0, 
@LoadId AS      INT      = 0, 
@Type AS        SMALLINT = 0,
@InboundType    SMALLINT = 0,
@AreaId         SMALLINT = 0,
@multi_type     varchar(max) = null
AS
BEGIN
    SET NOCOUNT ON;
IF @Option = 1 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
        
    IF @CampType = 1 BEGIN-- Campaigns Out
        
    IF @WorkgroupId IS NOT NULL BEGIN
        SELECT CAST(IdCampEsp AS INT) AS Id FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId AND Tipo = 1
        ORDER BY IdCampEsp ASC;
    END;
    ELSE BEGIN
        RAISERROR(''ERROR. No existe una lista de campañas de salida con el id de grupo de trabajo especificado'', 18, 1);
    END;
END;
    IF @CampType = 0 BEGIN-- Campaigns In (ACD)
        IF @WorkgroupId IS NOT NULL BEGIN
            SELECT CAST(IdCampEsp AS INT) AS Id FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId AND Tipo = 0
            ORDER BY IdCampEsp ASC;
        END;
        ELSE
        BEGIN
            RAISERROR(''ERROR. No existe una lista de campañas de entrada con el id de grupo de trabajo especificado'', 18, 1);
        END;
    END;
    RETURN 0;
END;
IF @Option = 2 BEGIN-- Get Campaign complete information per Campaign Type and Campaign Id      
    IF @CampType = 1 BEGIN-- Campaigns Out      
        IF @Id IS NOT NULL BEGIN
            SELECT DISTINCT 
            CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
            isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
            camps.cam_procesando IsStarted, 
            ISNULL(a.AreaName, '''') AS Area, 
            CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
            CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
            CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 ELSE isnull(camps.CampType,0) END as OutboundType,
            ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
            a.ToolsTransfer         
            FROM ccCamps camps
            LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
            LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
            LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
            WHERE camps.cam_id = @Id
            ORDER BY camps.cam_descripcion ASC;
        END;
        ELSE BEGIN
            RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
        END;
    END;
    ELSE IF @CampType = 0 -- Campaigns In (ACD)
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    SELECT DISTINCT 
                    CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, 
                    ISNULL(a.AreaName, '''') AS Area, 
                            CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType,
                            a.ToolsTransfer
                    FROM ccInbound inb
                            LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                            LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
                    WHERE inb.Inbound_id = @Id
                            ORDER BY inb.descripcion ASC;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. No existe campañas de entrada con el id especificado'', 18, 1);
            END;
    END;
    RETURN 0;
END;
ELSE IF @Option = 3  BEGIN -- Update OverallTotalNew By Campaign

    IF @Id IS NOT NULL BEGIN
        UPDATE ccCampsNvosCB SET  OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id;
    END;
    ELSE BEGIN
        RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
    END;
    RETURN 0;
END;
ELSE IF @Option = 4 -- Update Pin from Campaign per Admin
BEGIN
    IF @Id IS NOT NULL
        AND @AdminId IS NOT NULL
    BEGIN
        IF @PinUpdate = 1
        BEGIN
            INSERT INTO PinedCampaigns (CampId, AdminId, Type)
            VALUES (@Id, @AdminId, @Type);
        END;

        IF @PinUpdate = 0
        BEGIN
            DELETE
            FROM PinedCampaigns
            WHERE CampId = @Id
                AND AdminId = @AdminId
                AND Type = @Type;
        END;
    END;
    ELSE
    BEGIN
        RAISERROR (''ERROR. La campañas o administrador no existen'', 18, 1
                );
    END;

    RETURN 0;
END;

ELSE IF @Option = 5 BEGIN  -- Get Pin from Campaign Ids per Admin       
    IF @AdminId IS NOT NULL BEGIN
        SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
        ORDER BY Id ASC;
    END;
    ELSE BEGIN
        RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
    END;
    RETURN 0;
END;
ELSE IF @Option = 6 -- Get Blacklist Ids by Campaign Id
BEGIN
    IF @Id IS NOT NULL
    BEGIN
        DECLARE @BlackListIds VARCHAR(MAX);

        SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR
                    (MAX)), CAST(idtipolista AS VARCHAR(MAX)))
        FROM Camplistanegra
        WHERE cam_id = @Id
            AND STATUS = 1;

        SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
    END;
    ELSE
    BEGIN
        RAISERROR (''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
    END;

    RETURN 0;
END;
    
ELSE IF @Option = 7 -- Get RegistryListIds Ids by Campaign Id
BEGIN
    IF (
            @Id IS NOT NULL
            AND EXISTS (
                SELECT *
                FROM cccamps
                WHERE cam_id = @Id
                )
            )
    BEGIN
        SELECT TOP 1 list_id
        FROM ccRIARegistryLists
        WHERE cam_id = @Id
            AND STATUS = 2
        ORDER BY list_id DESC;
    END;
    ELSE
    BEGIN
        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
        RAISERROR (''ERROR. No existe una campaña con el id especificado'', 18, 1);
    END;

    RETURN 0;
END;

ELSE IF @Option = 8 -- Delete RegistryListIds Ids by LoadId
BEGIN
    IF (
            @LoadId IS NOT NULL
            AND EXISTS (
                SELECT *
                FROM ccRIARegistryLists
                WHERE list_id = @loadID
                    AND STATUS <> 0
                )
            )
    BEGIN
        UPDATE ccoCallsOutSource
        SET cal_status = ''5''
        WHERE list_id = @loadID;

        DELETE
        FROM ccoWorkingTable
        WHERE list_id = @LoadId;

        EXEC ccsp_RIARegistryLists @action = 6, @list_id = @LoadId;
    END;
    ELSE
    BEGIN
        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
        RAISERROR (''ERROR. No existe una carga el id especificado'', 18, 1);
    END;

    RETURN 0;
END;

ELSE IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
BEGIN
    DECLARE @table TABLE (camId INT, campType TINYINT, PRIMARY KEY (camId, campType)
        );

    INSERT INTO @table
    SELECT DISTINCT IdCampEsp, Tipo
    FROM ccRIACampEspWG wg
    WHERE wg.IDWG IN (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers
            WHERE IDWG <> @WorkgroupId
                AND User_id = @AdminId
            );

    SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
    FROM @table A
    RIGHT JOIN (
        SELECT wg.IdCampEsp, wg.Tipo
        FROM ccRIACampEspWG wg
        WHERE wg.IDWG = @WorkgroupId
        ) B ON A.camId = B.IdCampEsp
        AND A.campType = B.Tipo
    WHERE A.camId IS NULL
    ORDER BY IdCampEsp;

    RETURN 0;
END;

ELSE IF @option = 10 BEGIN -- Get Agents States with totals per campaign by admin id and campaign type
    DECLARE @date DATETIME = CONVERT(DATE, DATEADD(hh, - 3, GETDATE()));
    DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY (id));
    DECLARE @AgentsList TABLE (id INT, PRIMARY KEY (id));
    DECLARE @tmpCamAgent TABLE (
        camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY (camId, userId
            )
        );
    DECLARE @AgentStatus TABLE (CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT
        );
    DECLARE @CurrentStatus TABLE (userId INT, CurrentState INT, IdCampEsp INT, camType INT
        );
    DECLARE @campDataTotal TABLE (
        camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY (camId
            )
        );

    INSERT INTO @AdminWorkgroups
    SELECT DISTINCT IDWG
    FROM ccRIAWorkGroupUsers WG, ccUsers_Roles R
    WHERE WG.User_id = @AdminId
        OR (
            R.User_id = @AdminId
            AND R.Rol_id = 7
            );

    INSERT INTO @AgentsList
    SELECT DISTINCT A.User_id
    FROM ccRIAWorkGroupUsers A
    INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
    INNER JOIN ccUsers C ON A.User_id = C.User_id
        AND C.TipoUser_id = 1
    ORDER BY A.User_id;

    INSERT INTO @tmpCamAgent
    SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, CASE WHEN @Id = 0
                AND @CampType = 0 THEN inbound.chat ELSE NULL END
    FROM ccRIACampEspWG campPerWg
    INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
    INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
    INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
    LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp
        AND @CampType = 0
    LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp
        AND @CampType = 1
    WHERE C.TipoUser_id = 1
        AND campPerWg.Tipo = @CampType
        AND (
            @Id = 0
            OR campPerWg.IdCampEsp = @Id
            );;

    WITH lastState
    AS (
        SELECT A.user_id, MAX(A.fecha) AS fecha
        FROM ccLogAgentesDia A
        INNER JOIN @AgentsList B ON A.User_id = B.id
        WHERE fecha >= @date
        GROUP BY user_id
        )
    INSERT INTO @CurrentStatus
    SELECT B.User_id, CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS 
        currentStatus, B.IdCampEsp, B.Tipo
    FROM lastState A
    INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
        AND A.fecha = B.fecha;

    IF @Id = 0
        AND @CampType = 0
    BEGIN
        DELETE
        FROM @tmpCamAgent
        WHERE multimediaType = 5
    END

    DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;

    IF @CampType = 1
    BEGIN
        SELECT @MultimediaType = meanContactTypeId
        FROM contactMeanOut
        WHERE camp_id = @Id
    END
    ELSE
    BEGIN
        SELECT @chatType = ci.chat
        FROM dbo.ccInbound AS ci
        WHERE ci.Inbound_id = @Id;

        SELECT @MultimediaType = meanContactTypeId
        FROM contactMeanIn
        WHERE inboundId = @Id
    END

    IF (@chatType = 1)
    BEGIN
        SET @MultimediaType = 1
    END

    DECLARE @StateIds VARCHAR(100) = (
            SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN 
                            ''23'' ELSE ''4,5,6,9'' END
            ) -- Add more for multimediaTypes

    INSERT INTO @AgentStatus
    SELECT A.camId, A.userId, B.CurrentState, (
            CASE WHEN @chatType = 1 THEN CASE WHEN B.CurrentState IN (
                                    SELECT value
                                    FROM dbo.fn_RIASplitDelimited(@StateIds, '','')
                                    ) THEN @CampType ELSE CASE WHEN B.CurrentState IN (
                                            SELECT value
                                            FROM dbo.fn_RIASplitDelimited(
                                                    @StateIds, '','')
                                            )
                                        AND B.IdCampEsp = A.camId
                                        AND B.camType = @CampType THEN @CampType ELSE 
                                        NULL END END END
            ) AS isCampDialog, B.camType
    FROM @tmpCamAgent A
    INNER JOIN @CurrentStatus B ON A.userId = B.userId
    WHERE (
            @Id = 0
            OR A.camId = @Id
            )

    IF @CampType = 1
    BEGIN
            ;

        WITH campDataTotal
        AS (
            SELECT camId, count(*) total
            FROM @tmpCamAgent A
            GROUP BY camId
            )
        INSERT INTO @campDataTotal
        SELECT A.camId, B.cam_descripcion AS campName, A.Total, C.AreaName AS Area
        FROM campDataTotal A
        INNER JOIN ccCamps B ON A.camId = B.cam_id
        INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END
    ELSE
    BEGIN
            ;

        WITH campDataTotal
        AS (
            SELECT camId, count(*) total
            FROM @tmpCamAgent A
            GROUP BY camId
            )
        INSERT INTO @campDataTotal
        SELECT A.camId, B.descripcion AS campName, A.Total, C.AreaName AS Area
        FROM campDataTotal A
        INNER JOIN ccInbound B ON A.camId = B.Inbound_id
        INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END;

    WITH stateCamp
    AS (
        SELECT A.CampId, count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready, 
            count(CASE WHEN A.CurrentState NOT IN (- 2, - 1, 0, 3, 4, 5, 6, 9, 30, 34
                            ) THEN 1 WHEN A.CurrentState IN (6, 34, 4
                            )
                        AND (
                            A.CampId != C.IdCampEsp
                            OR A.campType != @CampType
                            ) THEN 1 ELSE NULL END) AS notReady, COUNT(isCampDialog) AS 
            dialog, COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS 
            disconnected
        FROM @AgentStatus A
        INNER JOIN @CurrentStatus C ON A.userId = C.userId
        GROUP BY A.CampId
        )
    SELECT A.camId, A.campName, A.Total, ISNULL(B.ready, 0) AS Ready, ISNULL(B.notReady, 
            0) AS NotReady, ISNULL(B.dialog, 0) AS Dialog, CASE WHEN B.disconnected IS NULL 
                THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END 
        Disconnected, A.Area
    FROM @campDataTotal A
    LEFT JOIN stateCamp B ON A.camId = B.CampId
    ORDER BY A.campName

    RETURN 0;
END;
ELSE IF @Option = 11 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
    IF NOT EXISTS (
            SELECT *
            FROM ccUsers_Roles WITH (NOLOCK)
            WHERE User_id = @AdminId
                AND Rol_id = 7
            )
    BEGIN
        --print ''xxxx SIn Super''
            ;

        WITH wgId
        AS (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers WITH (NOLOCK)
            WHERE user_id = @AdminId
            )
        SELECT DISTINCT CAST(IdCampEsp AS INT) AS Id
        FROM ccRIACampEspWG A WITH (NOLOCK)
        INNER JOIN wgId ON wgId.IDWG = A.IDWG
            AND A.Tipo = @CampType;
    END;
    ELSE
    BEGIN
        --print ''xxxx Super''
        IF @CampType = 1
        BEGIN
            SELECT DISTINCT CAST(cam_id AS INT) AS Id
            FROM ccCamps WITH (NOLOCK)
            WHERE IDArea IS NOT NULL
        END
        ELSE
        BEGIN
            SELECT DISTINCT CAST(Inbound_id AS INT) AS Id
            FROM ccInbound WITH (NOLOCK)
            WHERE IDArea IS NOT NULL
        END
    END;

    RETURN 0;
END;

ELSE IF @Option = 12 BEGIN-- Get All Campaigns complete information per Campaign Type and Campaign Id
    IF @CampType = 1 -- Campaigns Out
    BEGIN
                    SELECT DISTINCT 
                    CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
                    isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
                    camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
                    CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, 
                    CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 ELSE isnull(camps.CampType,0) END as OutboundType,
                    ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
        FROM ccCamps camps(NOLOCK)
        INNER JOIN ccRIACampsGraph graph(NOLOCK) ON camps.cam_id = graph.cam_id
        INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = camps.IDArea
        LEFT JOIN ccCampsExtend extended(NOLOCK) ON camps.cam_id = extended.cam_id
        ORDER BY camps.cam_descripcion ASC;
    END;
    ELSE
    BEGIN
        SELECT DISTINCT CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, isnull
            (CAST(graph.graphic_id AS INT), 1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(
                inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea AS INT) AS 
            AreaId, inb.chat AS InboundType, 0 AS OutboundType
        FROM ccInbound inb(NOLOCK)
                            INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
        INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = inb.IDArea
        ORDER BY inb.descripcion ASC;
    END;

    RETURN 0;
END;

ELSE IF @Option = 13
BEGIN
    BEGIN
        IF NOT EXISTS (
                SELECT *
                FROM ccUsers_Roles NOLOCK
                WHERE User_id = @AdminId
                    AND Rol_id = 7
                )
        BEGIN
            IF @CampType = 1
            BEGIN
                WITH wgId
                AS (
                    SELECT IDWG
                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT 
                                    CAST(IdCampEsp AS INT) AS CampId,
                                    cam_descripcion AS Description,
                                    isnull(IDArea, -1) AS AreaID,
                                    CAST(-1 AS SMALLINT) AS CampaignType,
                                    CAST(-1 AS INT) AS RelatedCampId,
                                    CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN CampType ELSE 8 END AS INT) AS Channel,
                                    CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
                                    CAST(1 AS INT) As CampType
                FROM ccRIACampEspWG A
                INNER JOIN wgId ON wgId.IDWG = A.IDWG
                    AND A.Tipo = 1
                                    INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id
                                    LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
            END
            ELSE
            BEGIN
                WITH wgId
                AS (
                    SELECT IDWG
                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT 
                                    CAST(IdCampEsp AS INT) AS CampId,
                                    descripcion AS Description,
                                    isnull(IDArea, -1) AS AreaID,
                                    CAST(chat AS SMALLINT) AS CampaignType,
                                    CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
                                    CAST(chat AS INT) AS Channel,
                                    CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                    CAST(0 AS INT) As CampType
                FROM ccRIACampEspWG A(NOLOCK)
                INNER JOIN wgId ON wgId.IDWG = A.IDWG
                    AND A.Tipo = 0
                INNER JOIN ccInbound cci(NOLOCK) ON A.IdCampEsp = cci.Inbound_id
                                    LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
                                    LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
                                    AND ((@multi_type is null AND cci.chat = @InboundType)
                                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
            END
        END;
        ELSE
        BEGIN
            IF @CampType = 1
            BEGIN
                        SELECT DISTINCT 
                                CAST(ccc.cam_id AS INT) AS CampId,
                                cam_descripcion AS Description,
                                isnull(IDArea, -1) AS AreaID,
                                CAST(-1 AS SMALLINT) AS CampaignType,
                                -1 AS RelatedCampId,
                                CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN CampType ELSE 8 END AS INT) AS Channel,
                                CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
                                CAST(1 AS INT) As CampType
                        FROM ccCamps AS ccc (NOLOCK) 
                            LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
                        where IDArea = @AreaId
            END
            ELSE
            BEGIN
                        SELECT DISTINCT 
                                CAST(cci.Inbound_id AS INT) AS CampId,
                                descripcion AS Description,
                                isnull(IDArea, -1) AS AreaID,
                                CAST(chat AS SMALLINT) AS CampaignType,
                                CAST(chat AS INT) AS Channel,
                                CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
                                CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                CAST(0 AS INT) As CampType
                FROM ccInbound cci(NOLOCK)
                            LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
                            LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
                        where IDArea = @AreaId
                        AND ((@multi_type is null AND cci.chat = @InboundType)
                            OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

            END
        END;

        RETURN 0;
    END;
END;
ELSE IF @Option = 14
BEGIN
    IF NOT EXISTS (
            SELECT *
            FROM ccUsers_Roles NOLOCK
            WHERE User_id = @AdminId
                AND Rol_id = 7
            )
    BEGIN
        WITH wgId
        AS (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers NOLOCK
                                WHERE user_id = @AdminId)
                            SELECT DISTINCT 
                                CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
        FROM ccRIACampEspWG A(NOLOCK)
        INNER JOIN wgId ON wgId.IDWG = A.IDWG
            AND A.Tipo = 0
                                INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND isnull(cci.cam_id,-1) = -1
                                AND ((@multi_type is null AND cci.chat = @InboundType)
                                    OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

    END
    ELSE
    BEGIN
                    SELECT DISTINCT 
                    CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                    FROM ccInbound cci (NOLOCK) where IDArea = @AreaId AND isnull(cam_id,-1) = -1
                    AND ((@multi_type is null AND cci.chat = @InboundType)
                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

    END
END

ELSE IF @Option = 15
BEGIN
            SELECT DISTINCT 
            CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
            FROM ccInbound NOLOCK where cam_id = @Id
END

END;
'
        EXEC(@sql);

        SET @process = 'Alter SP ccsp_GalateaAdminGetAgentCounters Se agrega @workgroupIds para filtrar las campañas al iniciar sesion'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminGetAgentCounters] @type AS      INT, 
                                                          @sup_id AS    INT          = 0, 
                                                          @agent_id AS  INT          = 0, 
                                                          @WG AS        INT          = 0, 
                                                          @AgentsIds AS VARCHAR(MAX) = '''', 
                                                          @campId AS    INT          = 0, 
                                                          @CampType AS  SMALLINT     = 1,
                                                          @workgroupIds  varchar(max)=''0''
AS
     SET NOCOUNT ON;
     DECLARE @dateStart DATETIME;
     IF @type = 1
         BEGIN
             WITH TableUserAgent(userId)
                  AS (SELECT DISTINCT 
                             wgAgt.User_id AS Id --,usr.login 
                      FROM ccriaworkgroupusers wgAdmin
                           INNER JOIN ccriaworkgroupusers wgAgt ON wgAdmin.IDWG = wgAgt.IDWG
                           INNER JOIN ccUsers usr ON usr.User_id = wgAgt.User_id
                                                     AND usr.TipoUser_id = 1
                      WHERE wgAdmin.User_id = @sup_id)
                  SELECT CAST(a.User_id AS INT) Id, a.login AS Username, a.Nombres + '' '' + a.ApellidoPaterno + '' '' + a.ApellidoMaterno AS Name
                  FROM ccusers a with(NOLOCK)
                       INNER JOIN TableUserAgent b ON a.User_id = b.userId
                         ORDER BY a.Login ASC;
             RETURN 0;
     END;
     IF @type = 2
         BEGIN
             SELECT CAST(u.User_id AS INT) Id, Login Username, Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno Name,
                                                                                                                       CASE WHEN p.publicIp IS NULL
                                                                                                                                 OR p.publicIp = '''' THEN ''000.000.000.000''
                                                                                                                       ELSE p.publicIp
                                                                                                                       END IP
             FROM ccUsers u
                  LEFT JOIN ccPosicion p ON p.user_id = @agent_id
             WHERE u.User_id = @agent_id;
             RETURN 0;
     END;
     IF @type = 3 --Agents by supervisor and WG
         BEGIN
             DECLARE @table2 TABLE(userId INT PRIMARY KEY NOT NULL);
             INSERT INTO @table2
                    SELECT DISTINCT 
                           wg.User_id
                    FROM ccRIAWorkGroupUsers wg
                         LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                    WHERE us.TipoUser_id = 1
                          AND wg.IDWG IN
                    (
                        SELECT IDWG
                        FROM ccRIAWorkGroupUsers
                        WHERE User_id = @sup_id
                              AND IDWG <> @WG
                    );
             SELECT CAST(B.User_id AS INT) AS Id
             FROM @table2 A
                  RIGHT JOIN
             (
                 SELECT DISTINCT 
                        wg.User_id
                 FROM ccRIAWorkGroupUsers wg
                      LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                 WHERE wg.IDWG = @WG
                       AND us.TipoUser_id = 1
             ) B ON A.userId = B.User_id
             WHERE A.userId IS NULL;
             RETURN 0;
     END;
     IF @type = 4 --Agents IDs by WG
         BEGIN
             SELECT CAST(wg.User_id AS INT) Id
             FROM ccRIAWorkGroupUsers wg
                  JOIN CCUsers u ON u.user_id = wg.user_id
                                    AND u.TipoUser_id = 1
             WHERE IDWG = @WG;
             RETURN 0;
     END;
     IF @type = 5 --Agents IDs by Campaign
         BEGIN
             SELECT DISTINCT
                    (CAST(U.User_id AS INT)) Id
             FROM ccRIACampEspWG camp
                  JOIN ccRIAWorkGroupUsers wg ON camp.IDWG = wg.IDWG
                  JOIN ccUsers U ON U.User_id = WG.User_id
                                    AND U.TipoUser_id = 1
             WHERE IdCampEsp = @campId
                   AND TIPO = @CampType;
             RETURN 0;
     END;
     IF @type = 6 -- Get Agent current state
         BEGIN
             WITH UserMaxFecha(User_id, fecha)
                  AS (SELECT User_id, MAX(fecha) AS fecha
                      FROM ccLogAgentesDia
                      WHERE fecha >= CONVERT(DATE, GETDATE())
                      GROUP BY User_id)
                  SELECT CASE WHEN CurrentState.currentStatus IS NULL
                                   OR CurrentState.currentStatus < 0 THEN 0
                         ELSE CAST(CurrentState.currentStatus AS INT)
                         END CurrentState
                  FROM ccUsers u
                       LEFT JOIN
                  (
                      SELECT A.User_id, B.currentStatus
                      FROM UserMaxFecha A
                           INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
                                                           AND A.fecha = B.fecha
                  ) CurrentState ON u.User_id = CurrentState.User_id
                  WHERE u.TipoUser_id = 1
                        AND u.User_id = @agent_id;
             RETURN 0;
     END;
     IF @type = 7 -- Get superuser id''s except root
         BEGIN
             DECLARE @superuserId AS INT;
             SET @superuserId =
             (
                 SELECT Rol_id
                 FROM ccRoles
                 WHERE Level = 7
             ); -- obtenemos el id del rol superusuario

             SELECT CAST(cr.User_id AS INT) User_id
             FROM ccUsers_Roles cr
             WHERE Rol_id = @superuserId
                   --AND cr.User_id NOT IN(1);
             RETURN 0;
     END;
     IF @type = 8 -- Get all Agent''s ID, Login and Full Names related to a workgroup
         BEGIN
             SET @dateStart = CONVERT(DATE, GETDATE());
             declare @wgIds table (wgId int primary key)

             insert into @wgIds
             select distinct value from dbo.fn_RIASplitDelimited(@workgroupIds,'','') 

             ;
             WITH wgAgt AS (
                SELECT DISTINCT 
                A.User_id, us.Login Username, --se agrega distinct porque el agente si puede estar en dos grupos de trabajo diferentes
                us.Nombres + '' '' + us.ApellidoPaterno + '' '' + us.ApellidoMaterno Name
                FROM ccRIAWorkGroupUsers A
                INNER JOIN ccusers us ON A.User_id = us.User_id
                inner join @wgIds w on w.wgId=A.IDWG
                WHERE us.TipoUser_id = 1
            ), lastState AS (
            SELECT user_id, MAX(fecha) dateStart
            FROM ccLogAgentesDia WITH(NOLOCK)
            WHERE fecha > @dateStart and User_id in(select [User_id] from wgAgt)
            GROUP BY user_id
            )
                  
            SELECT CONVERT(INT, us.User_id) AS Id, us.Username AS Username, us.Name
            , LastStateId = CASE WHEN B.currentStatus IS NULL OR B.currentStatus < 0 THEN 0
                ELSE B.currentStatus END
            FROM wgAgt us
            LEFT JOIN lastState A ON A.User_id = us.User_id
            LEFT JOIN ccLogAgentesDia B ON A.User_id = B.User_id AND A.dateStart = B.fecha;
             RETURN 0;
     END;
     ELSE
         IF @type = 9 -- GET AGENT IP
             BEGIN
                 SELECT publicIp
                 FROM ccPosicion with(nolock)
                 WHERE user_id = @agent_id;
                 RETURN 0;
         END;
         ELSE
             IF @type = 10 -- GET ONLINE AGENTS IP
                 BEGIN
                     SELECT CAST(user_id AS INT) AgentId, publicIp Ip
                     FROM ccPosicion
                     WHERE user_id <> 0;
                     RETURN 0;
             END;
     IF @type = 11
         BEGIN
             WITH UserMaxFecha(User_id, fecha)
                  AS (SELECT User_id, MAX(fecha) AS fecha
                      FROM ccLogAgentesDia
                      WHERE fecha >= CONVERT(DATE, GETDATE())
                      GROUP BY User_id)
                  SELECT CAST(u.User_id AS INT) AS UserId,
                                                   CASE WHEN CurrentState.currentStatus IS NULL
                                                             OR CurrentState.currentStatus < 0 THEN 0
                                                   ELSE CAST(CurrentState.currentStatus AS INT)
                                                   END CurrentState
                  FROM ccUsers u
                       LEFT JOIN
                  (
                      SELECT A.User_id, B.currentStatus
                      FROM UserMaxFecha A
                           INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
                                                           AND A.fecha = B.fecha
                  ) CurrentState ON u.User_id = CurrentState.User_id
                  WHERE u.TipoUser_id = 1
                        AND u.User_id IN
                  (
                      SELECT value
                      FROM dbo.fn_RIASplitDelimited(@AgentsIds, '','')
                  );
             RETURN 0;
     END;
     IF @type = 12
         BEGIN
             SET @dateStart = CONVERT(DATE, GETDATE());
             WITH lastState
                  AS (SELECT user_id, MAX(fecha) dateStart
                      FROM ccLogAgentesDia WITH(NOLOCK)
                      WHERE fecha > @dateStart
                      GROUP BY user_id),
                  currentState
                  AS (SELECT A.User_id,
                               CASE WHEN B.currentStatus IS NULL
                                         OR B.currentStatus < 0 THEN 0
                               ELSE B.currentStatus
                               END AS LastStateId
                      FROM lastState A
                           INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
                                                           AND A.dateStart = B.fecha)
                  SELECT CONVERT(INT, us.User_id) AS Id, us.Login Username, --se agrega distinct porque el agente si puede estar en dos grupos de trabajo diferentes
                  us.Nombres + '' '' + us.ApellidoPaterno + '' '' + us.ApellidoMaterno AS Name, ISNULL(B.LastStateId, 0) LastStateId
                  ,isnull(c.publicIp,''0.0.0.0'') as [Ip]
                  FROM ccusers us
                       LEFT JOIN currentState B ON us.User_id = B.User_id
                       left join ccposicion C on C.user_id=us.user_id
                  WHERE us.TipoUser_id = 1;
             RETURN 0;
     END;
     SET NOCOUNT ON;'
        EXEC(@sql);

        SET @process = 'Alter Sp ccsp_GalateaAdminRolesManagement se agrega CTE PermissionsTmp en lugar tabla temporal'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminRolesManagement]
    @action SMALLINT,
    @User_id VARCHAR(MAX)= '''',
    @subaction VARCHAR(50)= '''',
    @description VARCHAR(250)= '''',
    @keyJson VARCHAR(250)= '''',
    @active BIT= 1,
    @Roles_id VARCHAR(MAX)= '''',
    @Permissions_Id VARCHAR(MAX)= '''',
    @menus_id VARCHAR(250)= ''''
AS

BEGIN TRY
    BEGIN TRANSACTION;-- Inicia el bloque de la transaccion
    DECLARE @resultado varchar(50) = '''';
    DECLARE @returnValue SMALLINT;
    BEGIN
     IF @action = 1
        BEGIN
        IF @subaction = ''Permissions''
            BEGIN

            ;with PermissionsTmp as(
                
                SELECT DISTINCT
                       (rp.Permissions_id) as Permissions_id
                
                FROM ccUsers_Roles ur
                     INNER JOIN ccRoles_Permissions rp WITH(NOLOCK) ON rp.Rol_id = ur.Rol_id
                WHERE User_id = @User_id
            )
                SELECT p.Permissions_Id, 
                       p.KeyJson, 
                       p.Parent, 
                       p.Type, 
                       p.OrderGrl,
                       CASE
                           WHEN tp.Permissions_Id IS NOT NULL
                           THEN 1
                           ELSE 0
                       END AS State
                FROM ccPermissions p
                     LEFT JOIN PermissionsTmp tp WITH(NOLOCK) ON tp.Permissions_Id = p.Permissions_Id
                ORDER BY OrderGrl, 
                         Parent;


        END;
        IF @subaction = ''Roles''
            BEGIN
                SELECT r.Rol_id AS RolId, 
                       r.KeyJson, 
                       r.Description,
                       r.Level,
                       CONVERT(VARCHAR(10), r.CreateDate, 103) AS CreateDate,
                       CASE
                           WHEN ur.Rol_id IS NOT NULL
                           THEN 1
                           ELSE 0
                       END AS State,
                       STUFF(
                                (SELECT '', '' + CAST(ur.User_id AS varchar)
                                FROM ccUsers_Roles ur
                                INNER JOIN ccRoles C ON ur.Rol_id = C.Rol_id
                                WHERE c.Rol_id = r.Rol_id
                                FOR XML PATH ('''')),
                            1,2,'''')As Users_Ids,
                        STUFF(
                                (SELECT '', '' + CAST(pr.Permissions_Id AS varchar)
                                FROM ccRoles_Permissions pr
                                INNER JOIN ccRoles C ON pr.Rol_id = C.Rol_id
                                WHERE c.Rol_id = r.Rol_id
                                FOR XML PATH ('''')),
                            1,2,'''')As Permissions_ids
                FROM ccRoles r
                     LEFT JOIN ccUsers_Roles ur WITH(NOLOCK) ON r.Rol_id = ur.Rol_id
                                                                AND ur.User_id = @User_id AND ur.User_id = @User_id where r.Active=1
        END;
        IF @subaction = ''Users''
            BEGIN
                if exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) --User super root
                begin
                    SELECT User_id, Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno AS Names
                    FROM ccUsers
                    WHERE TipoUser_id = 2 AND User_id > 1;
                end
                else
                begin 
                    declare @idArea int
                    set @idArea = (select IDArea from ccUsers where User_id = @User_id)
                    
                    SELECT User_id, Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno AS Names
                    FROM ccUsers
                    WHERE TipoUser_id = 2 AND User_id > 1 AND IDArea = @idArea
                end
        END;
    END;
    END;
    IF @action = 2
        BEGIN
            SELECT p.Permissions_id, 
                   Parent, 
                   Type, 
                   OrderGrl
            FROM ccUsers_Roles ur
                 INNER JOIN ccRoles r WITH(NOLOCK) ON r.Rol_id = ur.Rol_id
                 INNER JOIN ccRoles_Permissions rp WITH(NOLOCK) ON rp.Rol_Id = ur.Rol_id
                 INNER JOIN ccPermissions p WITH(NOLOCK) ON p.Permissions_id = rp.Permissions_id
            WHERE ur.User_Id = @User_id
                  AND r.Active = 1
                  AND p.Active = 1;
    END;
    IF @action = 3 -- assign roles to user
        BEGIN
            IF OBJECT_ID(''tempdb..#Users_Ids'') IS NOT NULL DROP TABLE #Users_Ids
            IF OBJECT_ID(''tempdb..#Users_split'') IS NOT NULL DROP TABLE #Users_split
            IF OBJECT_ID(''tempdb..#Roles_split'') IS NOT NULL DROP TABLE #Roles_split
            
            SELECT value
            INTO #Users_split
            FROM fn_RIASplitDelimited(@User_id, '','')

            SELECT value
            INTO #Roles_split
            FROM fn_RIASplitDelimited(@Roles_id, '','')

            SELECT DISTINCT(User_id)
            INTO #Users_Ids
            FROM ccUsers_Roles
            WHERE User_id in (SELECT value FROM #Users_split)

            IF @subaction = ''NewRelate''
            BEGIN
                IF EXISTS( select top 1 * from #Users_Ids)
                    BEGIN
                        DELETE ccUsers_Roles
                        WHERE User_id IN (select * from #Users_Ids);
                    END
                END
            IF @Roles_id <> ''''
            BEGIN
                INSERT INTO ccUsers_Roles
                select a.value User_id,b.value as Rol_id from #Users_split a
                CROSS JOIN #Roles_split b

            END
            SET @returnValue = (select top 1 * from  #Users_split)
    END;
    IF @action = 4 -- Delete Roles
        BEGIN
            IF OBJECT_ID(''tempdb..#UsersIds'') IS NOT NULL DROP TABLE #UsersIds
            SET @resultado = STUFF(
                    (SELECT Distinct('', '' + CAST(ur.User_id AS varchar))
                    FROM ccUsers_Roles ur
                    INNER JOIN ccRoles C ON ur.Rol_id = C.Rol_id
                    WHERE c.Rol_id in (SELECT value FROM fn_RIASplitDelimited(@Roles_id, '',''))
                    FOR XML PATH ('''')),
                1,2,'''')
            IF OBJECT_ID(''tempdb..#roles_permissions'') IS NOT NULL DROP TABLE #roles_permissions
            IF OBJECT_ID(''tempdb..#Users_Roles'') IS NOT NULL DROP TABLE #Users_Roles

            SELECT DISTINCT(Rol_id)
            INTO #roles_permissions
                FROM ccroles_permissions a
                        INNER JOIN
                (
                    SELECT value
                    FROM fn_RIASplitDelimited(@Roles_id, '','')
                ) b ON b.value = a.Rol_Id

            SELECT  DISTINCT(value) AS Rol_id
            INTO #Users_Roles
            FROM fn_RIASplitDelimited(@Roles_id, '','') a
                    INNER JOIN ccUsers_Roles b ON b.Rol_id = a.Value
            WHERE b.Rol_id IS NOT NULL
            IF EXISTS(SELECT TOP 1 * FROM #roles_permissions)
            BEGIN
                --select * from #roles_permissions
                DELETE ccroles_permissions WHERE Rol_id in (select Rol_id from #roles_permissions )
            END
            IF EXISTS(SELECT TOP 1 * FROM #Users_Roles)
            BEGIN
                --select * from #Users_Roles
                DELETE ccUsers_Roles WHERE Rol_id in (select Rol_id from #Users_Roles )
            END
            IF EXISTS(select top 1 Rol_id from ccRoles where Rol_id in (SELECT  DISTINCT(value) FROM fn_RIASplitDelimited(@Roles_id, '','')))
            BEGIN
                --select * from ccRoles where Rol_id in (SELECT  DISTINCT(value) FROM fn_RIASplitDelimited(@Roles_id, '',''))
                DELETE ccRoles WHERE Rol_id in (SELECT  DISTINCT(value) FROM fn_RIASplitDelimited(@Roles_id, '',''))
                IF(@resultado IS NULL OR @resultado = '''') SET @resultado = ''1''
            END
        END;
    IF @action = 5 -- New Role
        BEGIN
            IF @menus_id <> ''''
               OR @Permissions_Id <> ''''
                BEGIN
                    DECLARE @exists BIT;
                    SET @returnValue = 0;
                    SET @exists = 1;

                    /*IF @menus_id <> '''' --Check if role with same menus exists
                        BEGIN
                            Para cuando esten los menus
                        END*/

                    IF @Permissions_Id <> ''''
                       AND @exists = 1 --Check if role with same permissions exists
                        BEGIN
                            IF NOT EXISTS
                            (
                                SELECT c.Rol_Id
                                FROM ccroles_permissions a
                                     INNER JOIN
                                (
                                    SELECT value
                                    FROM fn_RIASplitDelimited(@Permissions_Id, '','')
                                ) b ON b.value = a.Permissions_Id
                                     INNER JOIN
                                (
                                    SELECT Rol_id, 
                                           COUNT(*) AS contador
                                    FROM ccRoles_Permissions
                                    GROUP BY Rol_Id
                                ) AS c ON c.Rol_id = a.Rol_id
                                     INNER JOIN
                                (
                                    SELECT COUNT(*) AS contador
                                    FROM fn_RIASplitDelimited(@Permissions_Id, '','')
                                ) d ON d.contador = c.contador
                                GROUP BY c.Rol_Id
                                HAVING COUNT(*) =
                                (
                                    SELECT COUNT(*) AS contador
                                    FROM fn_RIASplitDelimited(@Permissions_Id, '','')
                                )
                            )
                                SET @exists = 0;
                    END;
                    IF @exists = 0 -- IF not exist role with same menus and permissions create
                        BEGIN
                            SELECT @exists = COUNT(*)
                            FROM ccRoles
                            WHERE Description = @description;
                            IF @exists = 0
                                BEGIN
                                    DECLARE @newRoleId INT;
                                    INSERT INTO ccroles
                                    (Description, 
                                     KeyJson, 
                                     CreateDate, 
                                     Active,
                                     Level
                                    )
                                    VALUES
                                    (@description, 
                                     @keyJson, 
                                     GETDATE(), 
                                     @active,
                                     1001
                                    );
                                    SELECT @newRoleId = SCOPE_IDENTITY();
                                    IF @Permissions_Id <> ''''
                                        BEGIN
                                            INSERT INTO ccroles_permissions
                                                   SELECT @newRoleId, 
                                                          value
                                                   FROM fn_RIASplitDelimited(@Permissions_Id, '','') AS a
                                                        INNER JOIN ccPermissions b ON a.value = b.Permissions_Id
                                                   GROUP BY value;
                                    END;
                                    SET @returnValue = @newRoleId; --  if new role was created return Role_id
                            END;
                                ELSE
                                BEGIN
                                    SET @returnValue = -1;
                            END;-- else if role name exists, return -1
                    END;
                    --SELECT @returnValue; --  else if exists role with same menus & permissions, return 0
            END;
    END;
    COMMIT TRANSACTION;
    if @resultado <>''''
    begin
        select @resultado
    end
    else
    begin
    -- Indica que la operación se efectuo correctamente
        SELECT @returnValue
    end
END TRY

/* Manejo de error de la transacción */

BEGIN CATCH
    SET @returnValue = -1;
    SELECT @returnValue
    ROLLBACK TRANSACTION;
END CATCH;
        '
        EXEC(@sql);

        SET @process = 'Alter SP ccsp_GalateaAreas se agrega if @option = 2 borrar la tabla #Areas'
        SET @sql = 'ALTER procedure [dbo].[ccsp_GalateaAreas] 
    @option int = 2,
    @IDArea smallint = 0,
    @Descripcion varchar(40) = NULL,
    @maxMails smallint = 3,
    @maxChats smallint = 3,
    @maxTweets smallint = 3,
    @defCampaing smallint = 0,
    @movesfromArea bit = 0,
    @userId int = NULL,
    @groupAreas varchar (MAX) = NULL,
    @toolsTransfer tinyint = NULL
AS

SET NOCOUNT ON;
    
    declare @opt int = @option -1
    
    DECLARE @userLogin as varchar(40);
    SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @userId);

    if @option = 1 --Superuser info
    begin
        create table #campsIds(
            id int,
            cadena varchar(max)
        )
            
        declare @sql varchar(max),@idPivots varchar(max),@idConcat varchar(max)
            
        set @idPivots =''''
        set @idConcat=''''
            
        select @idPivots=@idPivots+Id+'','',
            @idConcat=@idConcat+''case when ''+id+'' is not null then convert(varchar(max),''+ id+'') + '''','''' else '''''''' end + 
            ''
            from (
            select distinct ''[''+convert(varchar(max),cam_id)+'']'' as Id from ccCamps   
            )x
            
        set @idPivots =SUBSTRING(@idPivots,0,len(@idPivots))
        set @idConcat =SUBSTRING(@idConcat,0,len(@idConcat)-7)
            
        set @sql=''
            select IDArea,''+@idConcat+'' from 
            (   select IDArea, cam_id from ccCamps) as T
            PIVOT (
            max(cam_id) for cam_id in (''+@idPivots+'') ) as P''

        insert into #campsIds
        exec(@sql)
            
        select a.IDArea Id, 
            a.AreaName Name, 
            a.StatusArea Status, 
            a.maxMails Mails, 
            a.maxChats Chats, 
            a.maxTweets Tweets, 
            a.CreateDate as CreateDate,         
            ISNULL(b.cadena, 0) as CampaignIds  
        from ccRIACat_Areas a --Falta el datetime 
        left join #campsIds b on a.IDArea = b.id

        drop table #campsIds
    end
    if @option = 2 -- Select de las areas
    begin
        IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
        Create table #Areas(
            IDArea smallint,
            AreaName varchar(MAX),
            maxChats tinyint ,
            maxMails tinyint ,
            users int,
            admins int,
            camps int,
            acds int,
            maxTweets tinyint,
            toolsTransfer tinyint
        )
        insert into #Areas
        EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@defCampaing=@defCampaing, @isKolob=1
        select a.*,rca.CreateDate,Isnull(rca.defCampaing,0) as defCampaing
        from #Areas a
        inner join ccRIACat_Areas rca with(nolock) on a.IDArea = rca.IDArea

        IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
    end
    if @option = 3 -- Insert new area
    begin
    IF OBJECT_ID(''tempdb..#InsertAreas'') IS NOT NULL DROP TABLE #InsertAreas;
        Create table #InsertAreas(
            result int,
            idAreas decimal
        )
        insert into #InsertAreas
        EXEC ccsp_RIA_ABCAreas 
            @option = @opt,
            @IDArea=@IDArea,
            @Descripcion=@Descripcion,
            @maxMails=@maxMails,
            @maxChats=@maxChats,
            @maxTweets=@maxTweets,
            @defCampaing=@defCampaing,
            @toolsTransfer=@toolsTransfer
        if (select result from #InsertAreas) = 1
            begin

                --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD AL CREAR UN AREA
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@Descripcion, getDate(), @userLogin, 17, 3, '''', '''', @Descripcion);

                if(@movesfromArea = 1) begin
                    Update ccUsers set IDArea = (select idAreas from #InsertAreas), status = 1 where User_id = @userId
                end
            end
        Select * from #InsertAreas
    end
    if @option = 4 -- Delete Areas
    begin
        IF OBJECT_ID(''tempdb..#AreasDelete'') IS NOT NULL DROP TABLE #AreasDelete;
        SELECT value As IDArea into #AreasDelete FROM fn_RIASplitDelimited(@groupAreas, '','')
        
        
        if (exists(select IDArea from ccUsers where IDArea=(Select top 1 IDArea from #AreasDelete)) or exists(select IDArea from ccCamps where IDArea = (Select top 1 IDArea from #AreasDelete))
          or exists(select IDArea from ccInbound where IDArea=(Select top 1 IDArea from #AreasDelete))) and (select valor from ccSettings where setting_id=95)<>1
        BEGIN
            Select -1 as result
        END
        ELSE
        BEGIN
            declare @DWorkGroups as varchar(500)
            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
            select user_id,cam_id,prioridad,skill,rel_id,IDWG
            from ccCampsAgente
            where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
            select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
            from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))
            Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
            select user_id,cam_id,tipo,IDWG,monitored
            from ccSupervisorCam
            where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
            delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
            delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
            where cam_id in (select cam_id from ccCamps where IDArea in (Select IDArea from #AreasDelete)))

            Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))
            Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))

            Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
            Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
            Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))

            select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)
            Delete from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)

            if (select valor from ccSettings where setting_id=95)=1
            begin
            Update ccInbound set IDArea=NULL, status=0 where IDArea in (Select IDArea from #AreasDelete)
            Update ccCamps set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
            Update ccUsers set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
            end

            Update ccRIACat_Areas set StatusArea=0 where IDArea in (Select IDArea from #AreasDelete)

            --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA AREA ELIMINADA
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            SELECT AreaName, getDate(), @userLogin, 19, 3, '''', '''', AreaName
            FROM ccRIACat_Areas 
            WHERE IDArea in (Select IDArea from #AreasDelete);

            select 1 as result
        END
    end
    if @option = 5 -- update Areas
    begin
        if exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion and IDArea <> @IDArea)
            begin
                select -1 as result
                return
            end
        else
            begin

                --INICIO - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

                DECLARE @PrevDescription AS VARCHAR(50);
                DECLARE @SelectedArea AS VARCHAR(10) = CAST(@IDArea AS varchar(10));

                SELECT @PrevDescription = AreaName
                FROM ccRIACat_Areas 
                WHERE IDArea = @IDArea;

                EXEC InsertLogAdminGalatea @action=1, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

                DECLARE @AreasTable TABLE 
                (
                    columnInfo VARCHAR(255),
                    dataInfo VARCHAR(255),
                    identifierInfo VARCHAR(255)
                )

                update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),defCampaing=isnull(@defCampaing, 0), ToolsTransfer=case when @toolsTransfer = 3 then ToolsTransfer else @toolsTransfer end where IDArea=@IDArea

                INSERT INTO @AreasTable EXEC InsertLogAdminGalatea @action=2, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId;

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                SELECT 
                    CASE WHEN AT.identifierInfo IS NOT NULL THEN
                        CASE 
                            WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                    ELSE '''' END,
                    getDate(), 
                    @userLogin, 
                    18, 
                    3, 
                    AT.identifierInfo,
                    CASE WHEN AT.identifierInfo IS NOT NULL THEN
                        CASE 
                            WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @Descripcion
                            WHEN AT.identifierInfo = ''T&SET_CAMPAIGN'' THEN 
                                CASE 
                                    WHEN @defCampaing IS NOT NULL AND @defCampaing <> 0 THEN
                                        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @defCampaing)
                                    ELSE ''T&COMMON_NONE'' END
                            WHEN AT.identifierInfo = ''T&SET_TOOLSTRANSFER'' THEN
                                CASE
                                    WHEN @toolsTransfer = 1 THEN ''COMMON_ENABLED''
                                    ELSE ''COMMON_DISABLED'' END
                            ELSE AT.dataInfo END
                    ELSE '''' END, 
                    CASE WHEN AT.identifierInfo IS NOT NULL THEN
                        CASE 
                            WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                    ELSE '''' END
                FROM @AreasTable AS AT;

                EXEC InsertLogAdminGalatea @action=3, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

                --FIN - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

            end
        if @maxChats is not null
            begin
                Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
            end
        if @movesfromArea = 1
        Begin
            Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @userId
        End
        select 1 as result
    end
SET NOCOUNT ON;'
        EXEC(@sql);

        SET @process = 'Alter SP ccsp_GalateaLoadWorkGroup #Relations se pone para que elimine las tabla temporal '
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaLoadWorkGroup]
@Option smallint,
@areaId int
as
declare @agentes varchar(max)
declare @admins varchar(max)
declare @campsIn varchar(max)
declare @campsOut varchar(max)
declare @wgs varchar(max)
declare @count int
declare @id int
declare @wg int

if @option =1 --Obtiene las relaciones de los WG de una area
begin

    IF OBJECT_ID(''tempdb..#Relations'') IS NOT NULL DROP TABLE #Relations;

    SELECT 
    ROW_NUMBER() OVER(ORDER BY idWG ASC) AS Row,
    IDWG,@agentes as agents,@admins as admins,@campsIn as campsIn,@campsOut as campsOut
    into #Relations
    FROM ccRIAAreaWorkGroup 
    WHERE IDArea = @areaId;

    if not exists(select * from ccRIACat_Areas where IDArea = @areaId) or (select count(idWG) from #Relations) = 0
    begin
        select Null as IDWG ,@agentes as agents, @admins as admins, @campsIn as campsIn, @campsOut as campsOut, @wgs as idsWg
        return (0)
    end

    select @count = count(idWG) from #Relations
    set @id =1
    while @id<=@count
    begin
        select @wg =idwg from #Relations where Row =@id
        select @agentes=null, @admins=null,@campsIn=null,@campsOut=null
        select @agentes = coalesce(@agentes + '','', '''') +  convert(varchar(12),wgu.user_id)
        from ccUsers u inner join ccRIAWorkGroupUsers wgu on wgu.User_id = u.User_id
        where TipoUser_id = 1 and u.IdArea = @areaId and wgu.IDWG =@wg
        order by u.user_id

        select @admins = coalesce(@admins + '','', '''') +  convert(varchar(12),u.user_id)
        from ccUsers u inner join ccRIAWorkGroupUsers wgu on wgu.User_id = u.User_id
        where u.TipoUser_id > 1 and u.IdArea = @areaId  and wgu.IDWG =@wg
        order by u.user_id

        select @campsIn = coalesce(@campsIn + '','', '''') +  convert(varchar(12),inbound_id)
        from ccInbound i inner join ccRIACampEspWG wg on wg.IdCampEsp =i.Inbound_id
        where IdArea = @areaId  and wg.IDWG = @wg and wg.Tipo=0
        order by inbound_id
    
        select @campsOut = coalesce(@campsOut + '','', '''') +  convert(varchar(12),cam_id)
        from ccCamps c inner join ccRIACampEspWG wg on wg.IdCampEsp = c.cam_id
        where IdArea = @areaId and wg.IDWG = @wg and wg.Tipo=1
        order by cam_id

        Update #Relations set agents= @agentes, admins=@admins, campsIn = @campsIn, CampsOut = @campsOut where IDWG= @wg
        set @id=@id+1
    end
    select Cast(IDWG as varchar(10)) as idwg,agents,admins,campsIn,CampsOut from #Relations
    IF OBJECT_ID(''tempdb..#Relations'') IS NOT NULL DROP TABLE #Relations;
end'
        EXEC(@sql);

        SET @process = ''
        SET @sql = 'ALTER procedure [dbo].[ccspOutboundSmsMessage] 
@action int,
@camId int = null,
@SentMsg int=null,
@smsoutIds varchar(max)=null,
@SystemApiId varchar(100)=null,
@statusSystemsId int =null,
@InsufficientBalance int=null,
@date datetime =null,
@IsCharged BIT = null,
@smsOutId INT = NULL
as
declare @sql varchar(max)
if @action=1 begin
    select distinct cast(c. cam_id as int) as CamId,cam_descripcion as [Name],cam_procesando as [Start] 
    from ccCamps c with(nolock)
    left join ccCampsNvosCB w with(nolock) on c.cam_id = w.id
    where CampType=7 and c.IDArea is not null and( @camId is null or c.cam_id=@camId) and w.new >0
    
end
else if @action=2 begin
    select tz_offset from ccTimeZones ORDER BY tz_id
end
else if @action=3 begin
    select cast(camId as int) CamId,SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected 
    from ccSmsConversationsResult where ( @camId is null or camId=@camId)
end
else if @action=4 begin
    truncate table ccSmsConversationsResult
end
else if @action=5 begin
    if not exists(select 1 from ccSmsConversationsResult where camId=@camId) begin
        insert into ccSmsConversationsResult values(@camId,@SentMsg,0,0,0,0,@InsufficientBalance,0)
    end
    else begin
        update ccSmsConversationsResult set SentMsg=SentMsg+@SentMsg 
        ,InsufficientBalance=InsufficientBalance+@InsufficientBalance
        where camId=@camId
    end
end
else if @action=6 begin 
    set @sql=''declare @listCamId table(camId int,status bit)

declare @camId int
insert into @listCamId
select distinct cam_id,0 from smsWorkingTable with(nolock) where smsout_id in(''+@smsoutIds+'')

while exists(select 1 from @listCamId where status=0)begin
    select top 1 @camId=CamId from @listCamId where status=0
                    
    exec ccsp_GalateaGetCampsNvosCB @cam_id=@camId,@Tipo=2,@regval=1
    update @listCamId set status=1 where status=0 and @camId=CamId 
end
delete from smsWorkingTable where smsout_id in(''+@smsoutIds+'')
    ''
    exec (@sql)
end
else if @action=7 begin

    IF @IsCharged = 1
    BEGIN
        UPDATE ccSettings2 WITH(TABLOCK) SET valor = valor - 1 WHERE setting_id = 258 AND valor > 0;
    END

    declare @statusSystemsIdOld int
    declare @ccSmsConversationsResult table(camId int,statusSystemsId int,description varchar(255), value int)
    select top(1) @camId =cam_id,@statusSystemsIdOld=statusSystemsId, @smsOutId=smsout_id from smsccoLogDial with(nolock) where SystemApiId=@SystemApiId
    update smsccoLogDial set statusSystemsId=@statusSystemsId where SystemApiId=@SystemApiId
                    
    insert into @ccSmsConversationsResult
    select camId, ROW_NUMBER() OVER(ORDER BY camId ASC)-1 AS statusSystemsId, description,value
    from ccSmsConversationsResult
    unpivot
    (
        value
        for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected,Exception,InsufficientBalance)
    ) unpiv
    where camId= @camId

    update @ccSmsConversationsResult set value =case when value>0 then value-1 else 0 end where statusSystemsId=@statusSystemsIdOld
    update @ccSmsConversationsResult set value =value+1 where statusSystemsId=@statusSystemsId
                    
    ;with res as(
    select * from 
    (
        select camId, description, value
        from @ccSmsConversationsResult 
    ) src
    pivot
    (
    sum(value)
    for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected,Exception,InsufficientBalance)
    ) piv
    )

    update B 
    set B.SentMsg=A.SentMsg
    ,B.Delivered=A.Delivered
    ,B.NotDelivered=A.NotDelivered
    ,B.RecipientRejected=A.RecipientRejected
    ,B.CarrierRejected=A.CarrierRejected
    ,B.Exception=A.Exception
    ,B.InsufficientBalance=A.InsufficientBalance
    from
    res A
    inner join ccSmsConversationsResult B on A.camId=B.camId

    exec ccspOutboundSmsMessage @action = 11, @smsOutId=@smsOutId
end
else if @action=8 begin
    update smsccoLogDial set Bill=0.70 where smsDate>=@date and statusSystemsId not in(3,4,5,6)
end
else if @action=9 begin
    CREATE TABLE #TempSmsOutIds (
    smsout_id INT
    );

    INSERT INTO #TempSmsOutIds (smsout_id)
    SELECT DISTINCT wt.smsout_id
    FROM smsWorkingTable wt
    JOIN smsOutSource os ON wt.smsout_id = os.smsout_id
    LEFT JOIN smsccoLogDial cco ON wt.smsout_id = cco.smsout_id
    WHERE wt.sms_status IN(1,2) 
    AND wt.cam_id = @camId;

    UPDATE wt
    SET wt.sms_status = 0, sms_dateDial = DATEADD(mi,30,GETDATE())
    FROM smsWorkingTable wt
    JOIN #TempSmsOutIds temp ON wt.smsout_id = temp.smsout_id;

    DROP TABLE #TempSmsOutIds;
end

else if @action=10 begin
    IF NOT EXISTS(SELECT 1 FROM smsWorkingTable WHERE cam_id = @camId) BEGIN
        UPDATE ccCamps SET cam_procesando = 0 WHERE cam_id = @camId
        SELECT CAST(0 AS BIT) 
    END
    ELSE BEGIN
        SELECT CAST(1 AS BIT) -- Has unsent messages 
    END
end

else if @action=11 begin
    UPDATE wt
    SET sms_status = 0, sms_dateDial = DATEADD(mi,30,GETDATE())
    FROM smsWorkingTable wt with (rowlock) WHERE smsout_id = @smsOutId;
end
else if @action=12 begin
    if exists(select 1 from ccSmsSchedules with(nolock) where cam_id = @camId and getdate() between iDate and fDate)
    begin
        if exists(select 1 from smsWorkingTable with(nolock) where cam_id = @camId)
        begin
            select cast(1 as bit)
            return
        end
    end
    select cast(0 as bit)
    update ccCamps set cam_procesando=0 where cam_id=@camId
end'
        EXEC(@sql);

        SET @process = ''
        SET @sql = ''
        EXEC(@sql);

        SET @process = ''
        SET @sql = ''
        EXEC(@sql);


        SET @process = ''
        SET @sql = ''
        EXEC(@sql);

        SET @process = ''
        SET @sql = ''
        EXEC(@sql);

        SET @process = ''
        SET @sql = ''
        EXEC(@sql);

        SET @process = ''
        SET @sql = ''
        EXEC(@sql);

        SET @process = ''
        SET @sql = ''
        EXEC(@sql);

        SET @process = ''
        SET @sql = ''
        EXEC(@sql);






        -----------------------------------------------------BEGIN hotfix/125.20231211.0.4 Jesus Gallardo  ----------------------------------------------------------------

             /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
        EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
        EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

        COMMIT TRAN
    END TRY

    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

        RAISERROR (@errorGenerated, 11, 1)

        ROLLBACK TRAN
    END CATCH
END 
