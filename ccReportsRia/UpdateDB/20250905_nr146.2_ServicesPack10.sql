/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2025/03/25
Description: ServicesPACK9

Database: CCReportsRIA
Required version: 146

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
USE CCReportsRIA

SET NOCOUNT ON --

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
SET @version = 146 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		--- BEGIN Services Pack 10 --
    SET @process = 'ALTER  PROCEDURE [dbo].[ccspRepCatalogos] se agrega el area 0 S/Area'
    SET @sql = 'ALTER  PROCEDURE [dbo].[ccspRepCatalogos]
@type as tinyint,
@action tinyint = 0 -- 0 Filter select; 1 Filters Range
,@userId int =0 ---- se agrega parametro para filtros
,@menuId INT = 0

AS
declare @tablatemp table (id int, description varchar(100) null)
declare @tempwork table (idwg int)
DECLARE @SQL NVARCHAR(MAX);
DECLARE @condition NVARCHAR(300) = '''';
DECLARE @columnName NVARCHAR(100) = '''';
DECLARE @consult NVARCHAR (2000) = '''';

if @action = 0
BEGIN
IF OBJECT_ID(''TEMPDB..#filters'') IS NULL
BEGIN
    CREATE TABLE #filters ([Type] VARCHAR(200))
END

    -- CAMPAIGNS
IF @type = 1 BEGIN

    
    INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId
    IF EXISTS (SELECT * FROM #filters)
    BEGIN
        SET @condition = '' WHERE camp.campType IN (SELECT * FROM #filters)''
        SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''campaigns'' AND ReportId = @menuId;
    END
    ELSE BEGIN
        SET @columnName =   ''campaignId'';
    END

    SET @consult = N'' SELECT cam_id as id, cam_descripcion as description, @columnName as dbColumn FROM ccCamps camp''

    IF @userId <> 0 BEGIN
            
        DECLARE @isJustVoiceFilter BIT = CASE WHEN @menuId IN (4010) THEN 1 ELSE 0 END;

        SET @SQL = '' declare @tablatemp table (id int, description varchar(100) null) 
            insert into @tablatemp
            select distinct caesp.IdCampEsp,'''' '''' as description  from ccUserView us
            inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
            inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=1'';

        IF @isJustVoiceFilter = 1
        BEGIN 
            SET @SQL += '' INNER JOIN dbo.cccamps AS c ON caesp.IdCampEsp = c.cam_id ''
        END

        SET @SQL += '' where us.[User_id] = @userId '';

        IF @isJustVoiceFilter = 1
        BEGIN 
            SET @SQL += '' AND c.CampType IN (0,6,9) '';
        END
           
                
        SET @sql +=''if exists(select 1 from @tablatemp) begin ''
            + @consult + '' inner join @tablatemp A on camp.cam_id = A.id '' + @condition
            +''end
            else begin
                SELECT 0 as id, ''''N/A'''' as description, ''''campaignId'''' as dbColumn
            end'';
    END
    ELSE BEGIN
        SET @SQL = @consult + @condition;
    END
    EXEC sp_executesql @SQL, N''@userId AS int = 0, @columnName AS NVARCHAR(100)'', @userId=@userId, @columnName=@columnName;
        
END


    -- DIAL RESULTS
if @type = 2 begin
    Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn
    from ccTipoResultadoDial
    order by descripcion
end

    -- WORKGROUPS
if @type = 3 begin
    if @userId <> 0 begin
        select v.IDWG as id, c.WGName as description, ''workgroupId'' as dbColumn
        from ccWgByAcdView v
        inner join ccriacat_workgroup c on c.IDWG=v.IDWG
        where USER_ID= @userId
        return
    end
    else  begin
        select idwg as id, wgname as description, ''workgroupId'' as dbColumn
        from ccRIACat_WorkGroup
        group by idwg, wgname   select * from ccRIACat_WorkGroup
        order by wgname
    end
end


-- AREAS
if @type = 4 begin
if @userId <> 0 begin

    insert into @tablatemp
    select distinct isnull(us.IDArea,0) as IDArea, wgu.User_id from ccUserView us
    inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
    where us.[User_id] = @userId
    
    select distinct idArea as id, isnull(AreaName,''S/AREA'') as description, ''areaId'' as dbColumn
    from ccRIACat_Areas area inner join @tablatemp tem on area.IDArea = tem.id
    union ALL
    select 0, ''S/AREA'' as description, ''areaId'' as dbColumn
    
    return
end
    else begin

        select idArea as id, AreaName as description, ''areaId'' as dbColumn
        from ccRIACat_Areas
        union ALL
        select 0, ''S/AREA'' as description, ''areaId'' as dbColumn
        order by AreaName
    end
end

-- DISPOSITIONS OUT
if @type = 5 begin
    SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
    FROM ccTipoCalifOut
    order by [description]
end

    -- USER
if @type = 6    begin
    if @userId <> 0 begin

            insert into @tempwork
                    select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

            select distinct us.User_id as id, us.Login as description,  ''userId'' as dbcolumn from ccUserView us
            inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

            inner join @tempwork awg on wgu.IDWG = awg.idwg
            where us.TipoUser_id = 1 and [status] = 1

            return
        end

        else begin

            SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn
            FROM ccUserView B WHERE [status] = 1 and TipoUser_id = 1
            ORDER BY description
        end
end

    -- ACDS**************
IF @type = 7 BEGIN

    INSERT INTO #filters SELECT [Category] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId
    IF EXISTS (SELECT * FROM #filters)
    BEGIN
        SET @condition = '' WHERE B.chat IN (SELECT * FROM #filters)''
        SELECT @columnName = [dbColumn] FROM ReportsFiltersCategory WHERE FilterName = ''acds'' AND ReportId = @menuId;
    END
    ELSE BEGIN
        SET @columnName = ''inboundId'';
    END

    SET @consult = N'' SELECT inbound_id AS id, descripcion AS description, @columnName AS dbColumn
        FROM ccinbound B''

    IF @userId <> 0 BEGIN

        SET @SQL = '' declare @tablatemp table (id int, description varchar(100) null)
            insert into @tablatemp
            select distinct caesp.IdCampEsp,'''''''' as description  from ccUserView us
            inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
            inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
            where us.[User_id] = @userId;''
            +''if exists(select 1 from @tablatemp) begin''
            + @consult + '' inner join @tablatemp A on B.inbound_id = A.id'' + @condition + '' return;''
            +''end
            else begin
                SELECT 0 as id, ''''N/A'''' as description, ''''inboundId'''' as dbColumn
            end'';   
    END
    ELSE BEGIN
        SET @SQL = @consult + @condition;
    END
    EXEC sp_executesql @SQL, N''@userId INT = 0, @columnName AS NVARCHAR(100)'',@userId=@userId, @columnName=@columnName;
end

    -- DIDS
if @type = 8    begin
    select 0 as id, ''S/DNIS''  as description, ''dnisId'' as dbColumn
    union ALL
    select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
    from ccdnis
end

    --DISPOSITIONS IN
if @type = 9 begin
    SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
    FROM ccTipoCalif
    order by [description]
end

    --SUBDISPOSITIONS IN
if @type = 10   begin
    SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
    FROM ccTipoCalifSub
    order by [description]
end

    --PROVIDER
if @type = 11 begin
    SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
    FROM cstoProvedor
    order by [description]
end

    -- UNAVAILABLES
if @type = 12 begin
    SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn
    FROM cctiponotready
    order by descripcion
end

    -- DIALERS
if @type = 13 begin
    SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn
    FROM ccoDialers
    order by descripcion
end

    -- CallTYpes
if @type = 14   begin
        SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn
        FROM ccStatusLlamada
    order by descripcion
end

    -- SUBDISPOSITIONS OUT
if @type = 21   begin
    SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
    FROM cctipocalifsubout
    order by [description]
end

    --AVRS TEMPLATE-SECTION
if @type = 15   begin
    SELECT fc.id as id, (rf.nombre +'' ''+ rc.con_descripcion)+'' ''+convert(varchar(10),fc.id) as description, ''templateSectionId'' as dbColumn
    FROM RIA_FORMATOCONCEPTO fc
    INNER JOIN  (SELECT id_formato, nombre, MAX(version) as version
                                    FROM RIA_FORMATOS
                                    WHERE activo = 1
                                    group by id_formato, nombre) as rf
    ON rf.id_formato = fc.templateId
    inner join RIA_CONCEPTOS rc ON rc.id_concepto = fc.sectionId
    order by fc.id
END

--exec dbo.ccspRepCatalogos @type=15,@action=0

    --AVRS TEMPLATES
if @type = 16   begin
    SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn
    FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
                                    FROM RIA_FORMATOS
                                    WHERE activo = 1
                                    group by id_formato) as t
    ON f.id_formato = t.id_formato AND f.version = t.version
    order by f.nombre
end

    --AVRS TEMPLATES
if @type = 31   begin
    SELECT c.id_concepto as id, c.con_descripcion as description, ''sectionId'' as dbColumn
    FROM RIA_CONCEPTOS c INNER JOIN (SELECT id_concepto,MAX(version) as version
                                    FROM RIA_CONCEPTOS
                                    group by id_concepto) as t
    ON c.id_concepto = t.id_concepto AND c.version = t.version
    order by c.con_descripcion
END

    --AVRS QUESTIONS
if @type = 23   begin
    SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
    FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
                                    FROM RIA_PREGUNTAS
                                    group by id_pregunta) as t
    ON p.id_pregunta = t.id_pregunta
    order by p.enunciado_pregunta
END


--AVRS QUESTIONS CHAT
if @type = 24   begin
    SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
    FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
                                    FROM RIA_PREGUNTAS
                                    group by id_pregunta) as t
    ON p.id_pregunta = t.id_pregunta
    order by p.enunciado_pregunta
END

    -- AVRS SUPERVISOR
if @type = 17   begin
    SELECT [user_id] as id, [login] AS description, ''supervisorId'' as dbColumn
    FROM ccUserView
    WHERE [status] = 1
    and TipoUser_id = 2
    ORDER BY [login]
end

    --Status Call
if @type = 25   begin
    select statusCall_id as id, [descripcion] as description, ''statusCallId'' as dbcolumn
    from ccstatusllamada
    order by [descripcion]
end

    --Survey
if @type = 26   begin
    select surveyId as id, [description] as description, ''surveyId'' as dbcolumn
    from Survey
    order by [description]
end

--dialType
if @type = 29 begin
    select dialId as id, [description] as description, ''dialId'' as dbcolumn
    from dialType
    order by [description]
end

    --dial
if @type = 30   begin
    select id as id, [description] as description, ''dialId'' as dbcolumn
    from Dials
    order by [description]
end

if @type = 33 begin
    if @userId <> 0 begin       
        insert into @tablatemp
        select distinct caesp.IdCampEsp,'''' as description  from ccUserView us
        inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
        inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
        inner join ccinbound i on caesp.IdCampEsp = i.Inbound_id and i.chat = 0
        where us.[User_id] = @userId
        
        SELECT inbound_id as id, descripcion as description, ''inboundCamp'' as dbColumn
        from ccinbound B
        inner join @tablatemp A on B.inbound_id = A.id
        union ALL 
        SELECT 0 AS id, ''IVR'' AS description, ''inboundCamp'' AS dbColumn
        WHERE @menuId = 3010;               

        return
    end
    else begin


        
        select inbound_id as id, descripcion as description, ''inboundCamp'' as dbColumn
        from ccinbound where chat = 0
    end
end
IF @type = 34   
BEGIN
    SELECT DISTINCT TipoReadyAuxiliar_Id AS id, [Description] AS description, ''auxiliarId'' AS dbcolumn
    FROM TipoReadyAuxiliar
    ORDER BY [description]
END
IF @type = 35   
BEGIN
    select SegmentId as Id,Name as description, ''SegmentId'' as dbColumn from ccSmsSegments
END
if @type = 36 begin
    if @userId <> 0 begin

            insert into @tempwork
                    select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

            select distinct us.User_id as id, us.Login as description,  ''adminId'' as dbcolumn from ccUserView us
            inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

            inner join @tempwork awg on wgu.IDWG = awg.idwg
            where us.TipoUser_id = 2 and [status] = 1

            return
        end

        else begin

            SELECT [user_id] as id, [login] AS description, ''adminId'' as dbColumn
            FROM ccUserView B WHERE [status] = 1 and TipoUser_id = 2
            ORDER BY description
        end
end
end --Action 0

IF OBJECT_ID(''TEMPDB..#filters'') IS NOT NULL
BEGIN
    DROP TABLE #filters;
END

-----------------------------------------------------------
if @action = 1 begin
    -- TRUNKS
    if @type = 13
    begin
        SELECT MIN(trunk) as [min],MAX(trunk) as [max],''trunk'' as dbColumn  from RepTrunkBusy
    end

    -- AVRS DISPOSITION
    if @type = 18
    begin
        SELECT 0 as [min], 100 as [max],''Disposition'' as dbColumn
    end

    -- AVG DISPOSITION
    if @type = 19
    begin
        SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
    end

    -- SCORE
    if @type = 20
    begin
        SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
    end
end'
    exec (@sql)

    SET @process = '#9001_#8971 ALTER PROCEDURE [dbo].[ccspRepInNotTransferred]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepInNotTransferred]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
    select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
begin
    --1 as wgId
    --Borrar lo que esta para no repetir
    delete from RepInNotTransferred with(rowlock)
    where date >= @from AND date < @to

    ;with ccWgByAcdViewDistinct as(

        select distinct Inbound_id,IDArea,IDWG,descripcion from ccWgByAcdView 
    )

    insert into RepInNotTransferred
    select a.cal_Inicio as [date], a.Inbound_id, 
    b.descripcion as acd, a.statusCall_id, isnull(d.descripcion,'''') as statusCall,isnull(d.descripcion,'''')  + ''_Count'' as statusCallCount,1 as [count],  b.IDArea, 
    isnull(Area.AreaName, '''') as area, c.IDWG as wgId, isnull(c.WGName,''systemTranslated_WorkGroup'') as wg
    ,datepart(yyyy,cal_inicio) as [year]
    ,datepart(mm,cal_inicio) as [mount]
    ,datepart(dd,cal_inicio) as [day]
    ,datepart(hh,cal_inicio) as [hour]
    ,datepart(mi,cal_inicio) as [minutes]
    ,a.cal_id as cal_id,isnull(a.cal_Ani,'''') as phone_in
    from cccallsin a        
    inner join ccWgByAcdViewDistinct b on a.Inbound_id=b.Inbound_id
    left join ccRIACat_WorkGroup c on c.IDWG=b.IDWG
    left join ccstatusllamada d on a.statusCall_id = d.statusCall_id
    left join ccRIACat_Areas Area on Area.IDArea=b.IDArea
    where cal_inicio >= @from AND cal_inicio < @to and 
    a.statuscall_id in (1,2,3,4,6,7,8)
    and  b.IDArea is not null
end'
    exec (@sql)

     SET @process = '#9001_#8971 ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail]'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail] 
@action AS TINYINT,
@from  AS DATETIME = NULL,
@to    AS DATETIME = NULL
AS
IF @from IS NULL
    SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

IF @to IS NULL
    SELECT @to = GETDATE();
    print(@from)
    print(@to)
DECLARE @IVA INT, @IVAstring VARCHAR(3);
DECLARE @country AS TINYINT;

SELECT @IVA = CONVERT(INT, ISNULL(valor, 0))
FROM ccsettings
WHERE setting_id = 25;

SELECT @IVAstring = CONVERT(VARCHAR(5), @IVA) + ''%'';

SELECT @country = CONVERT(TINYINT, ISNULL(valor, 1))
FROM ccsettings
WHERE setting_id = 104;

IF @country IS NULL
    SET @country = 1;

IF @action = 1
BEGIN
    DELETE FROM RepOutCallsDetail WITH (ROWLOCK)
    WHERE DATE >= @from 
      AND DATE <  @to;

    INSERT INTO dbo.RepOutCallsDetail
    (
        [date],
        [callKey],
        [telephone],
        [transfer],
        [dialog],
        [nque],
        [wrapup],
        [CallDisposition],
        [extension],
        [userId],
        [login],
        [username],
        [campaignId],
        [campaign],
        [duration],
        [ncost],
        [iva],
        [total],
        [ByCarrier],
        [Calltypes],
        [dialType],
        [whoHangUp],
        [subDisposition],
        [dialResult],
        [calId],
        [year],
        [month],
        [day],
        [hour],
        [minutes],
        [trunk],
        [data1],
        [data2],
        [data3],
        [data4],
        [data5],
        [MessageTime],
        [grabId],
        [areaId],
        [area],
originNumber,
callbackDate,
queueTimes,
ringingTime
    )
    SELECT 
        Call.cal_inicio AS [date],
        Call.cal_key AS [callKey],
        Call.cal_telefono AS [telephone],
        Call.cal_txfer + Call.cal_tring AS [transfer],
        Call.cal_tdialog AS [dialog],
        ISNULL(Call.cal_tMoh, 0) AS [nque],
        Call.cal_tnotas AS [wrapup],
        ISNULL(Tipo.[description], '''') AS [CallDisposition],
        Call.cal_extension AS [extension],
        ISNULL(Usr.user_id, 0) AS [userId],
        ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [login],
        ISNULL(CONVERT(VARCHAR(255), Usr.[LOGIN]), ''systemTranslated_NoUserName'') AS [username],
        camps.cam_id AS [campaignId],
        ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
        (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60) AS [duration],
        CONVERT(DECIMAL(10, 2), dbo.fnGetCstoTarifa(
            Call.tipoLlamada_id, 
            Call.provedor_id, 
            (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),
            @country
        )) AS [ncost],
        @IVAstring AS iva,
        CONVERT(DECIMAL(10, 2), dbo.fnGetCstoTarifa(
            Call.tipoLlamada_id, 
            Call.provedor_id, 
            (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),
            @country
        ) * (1 + (@IVA / 100.00))) AS total,
        CASE 
            WHEN prov.descrip IS NOT NULL THEN prov.descrip
            ELSE ''systemTranslated_NoCarrier'' 
        END AS [ByCarrier],
        CASE 
            WHEN @country <> 1 THEN ''''
            WHEN ld.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo'' 
            WHEN ld.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone'' 
            ELSE ''systemTranslated_Indefinite'' 
        END AS [Calltypes],
        CASE 
            WHEN ld.TipoDialingMode = ''100000000''  THEN ''systemTranslated_Preview'' 
            WHEN SUBSTRING(ld.TipoDialingMode, 2, 1) = ''1'' AND Call.cal_manual = 0 THEN ''systemTranslated_Assisted''
            WHEN ld.TipoDialingMode IN (''00001000'',''00010000'', ''000010000'') THEN ''systemTranslated_Callback'' 
            WHEN RIGHT(ld.TipoDialingMode, 3) = ''100'' THEN ''systemTranslated_Auto'' 
            WHEN RIGHT(ld.TipoDialingMode, 2) IN (''10'', ''01'') AND ISNULL(ld.manualCRM,0) = 1 THEN ''systemTranslated_Manual_Mode_Integration''
            WHEN RIGHT(ld.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' 
            WHEN ld.TipoDialingMode = ''000000000'' THEN ''systemTranslated_Auto''
            ELSE ''''
        END AS [dialType], 
        CASE 
            WHEN Call.cal_whoHung = 0 THEN ''systemTranslated_Client'' 
            WHEN Call.cal_whoHung = 1 THEN ''systemTranslated_Agent'' 
            ELSE ''systemTranslated_AgentSurvey'' 
        END AS [whoHangUp], 
        CASE 
            WHEN Call.califsub_id = 0 THEN ''systemTranslated_NoSubDisposition'' 
            ELSE ISNULL(sub.califSubDesc, '''') 
        END AS [subDisposition],
        ISNULL(sta.descTranslated,'''') AS  [dialResult], 
        Call.cal_id AS [calId],
        DATEPART(yyyy, Call.cal_inicio) AS [year],
        DATEPART(mm,   Call.cal_inicio) AS [month],
        DATEPART(dd,   Call.cal_inicio) AS [day],
        DATEPART(hh,   Call.cal_inicio) AS [hour],
        DATEPART(mi,   Call.cal_inicio) AS [minutes],
        Call.cal_puerto,
        ISNULL(cod.Data1, ISNULL(cs.Dato1, '''')) AS [data1],
        ISNULL(cod.Data2, ISNULL(cs.Dato2, '''')) AS [data2],
        ISNULL(cod.Data3, ISNULL(cs.Dato3, '''')) AS [data3],
        ISNULL(cod.Data4, ISNULL(cs.Dato4, '''')) AS [data4],
        ISNULL(cod.Data5, ISNULL(cs.Dato5, '''')) AS [data5],
        ISNULL(Call.cal_tMsg, 0) AS [MessageTime],
        ISNULL(rc.grab_id, 0) AS grabId,
        concat(camps.IDArea,Usr.IDArea,1) AS [areaId],
        isnull(ar.AreaName,'''') AS [area],
ld.ani as originNumber,
call.cal_fcallback as callbackDate,
cal_que as queueTimes,
Call.cal_txfer + call.cal_tring 
+ CASE WHEN RIGHT(ld.TipoDialingMode, 2) IN (''10'', ''01'') THEN ld.tDialing ELSE 0 END
as ringingTime
    FROM ccoCallsOut Call (NOLOCK)
    LEFT JOIN ccoLogDials      ld   (NOLOCK) ON Call.cal_id    = ld.cal_id
    LEFT JOIN ccTipoCalifOUT   Tipo (NOLOCK) ON Call.calif_id  = Tipo.calif_id
    LEFT JOIN ccUserView       Usr  (NOLOCK) ON Usr.[user_id]  = Call.[user_id]
    LEFT JOIN ccCamps          camps(NOLOCK) ON camps.[cam_id] = Call.[cam_id]
    LEFT JOIN ccStatusLlamada  sta  (NOLOCK) ON Call.statuscall_id = sta.statuscall_id
    LEFT JOIN cstoProvedor     prov (NOLOCK) ON prov.[provedor_id] = Call.[provedor_id]
    LEFT JOIN cstoTipoLlamada  tl   (NOLOCK) ON tl.[tipoLlamada_id] = ld.[tipoLlamada_id] 
                                            AND tl.Country_id       = @country
    LEFT JOIN ccTipoCalifSubOut sub (NOLOCK) ON Call.califsub_id = sub.califsub_id
    LEFT JOIN ccoDialers       di   (NOLOCK) ON di.dialer_id = Call.cal_puerto 
                                            AND Call.provedor_id = di.provedor_id
    LEFT JOIN ccoCallsOutSource cs  (NOLOCK) ON Call.callout_id = cs.callout_id
    LEFT JOIN ccoCallsOutData  cod  (NOLOCK) ON cod.cal_id = Call.cal_id
    LEFT JOIN ccCallCost_RIA   cc   (NOLOCK) ON cc.country_id = tl.country_id 
                                            AND cc.tipoLlamada_id = tl.tipoLlamada_id
    LEFT JOIN Ria_grabacion    rc   (NOLOCK) ON rc.cal_id = Call.cal_id 
                                            AND rc.tipo_llamada = 2
    LEFT JOIN dbo.ccRIACat_Areas AS ar (NOLOCK) ON ar.IDArea = camps.IDArea or Usr.IDArea=ar.IDArea
    WHERE Call.cal_inicio >= @from 
      AND Call.cal_inicio <  @to 
      AND Call.cal_manual IN (0, 2) 
      AND ld.TipoDialingMode IS NOT NULL              
    ORDER BY DATE;
END'
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)

     SET @process = ''
    SET @sql = ''
    exec (@sql)

    SET @process = ''
    SET @sql = ''
    exec (@sql)
  
    	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
