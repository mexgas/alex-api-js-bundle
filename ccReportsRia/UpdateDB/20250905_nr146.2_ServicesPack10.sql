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

    SET @process = 'DROP usp_SetObjectDescription'
    SET @sql = 'if exists (select * from sys.procedures where name = N''usp_SetObjectDescription'')
    begin
            DROP PROCEDURE usp_SetObjectDescription;
    end'
    exec (@sql)

    SET @process = 'DROP usp_SetColumnDescription'
    SET @sql = 'if exists (select * from sys.procedures where name = N''usp_SetColumnDescription'')
    begin
            DROP PROCEDURE usp_SetColumnDescription;
    end'
    exec (@sql)

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

    SET @process = 'CREATE PROCEDURE dbo.usp_SetObjectDescription'
    SET @sql = 'CREATE PROCEDURE dbo.usp_SetObjectDescription
(
    @SchemaName  SYSNAME,
    @ObjectName  SYSNAME,
    @Description NVARCHAR(4000)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Level1Type VARCHAR(30);

    SELECT @Level1Type = CASE o.[type]
        WHEN ''U''  THEN ''TABLE''
        WHEN ''V''  THEN ''VIEW''
        WHEN ''P''  THEN ''PROCEDURE''
        WHEN ''FN'' THEN ''FUNCTION''
        WHEN ''IF'' THEN ''FUNCTION''
        WHEN ''TF'' THEN ''FUNCTION''
        ELSE NULL
    END
    FROM sys.objects o
    INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = @SchemaName
      AND o.name = @ObjectName;

    IF @Level1Type IS NULL
    BEGIN
        PRINT CONCAT(''Objeto no encontrado o no soportado: '', @SchemaName, ''.'', @ObjectName);
        RETURN;
    END;

    IF EXISTS (
        SELECT 1
        FROM sys.extended_properties ep
        INNER JOIN sys.objects o ON ep.major_id = o.object_id
        INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE ep.name = N''MS_Description''
          AND s.name = @SchemaName
          AND o.name = @ObjectName
          AND ep.minor_id = 0
    )
    BEGIN
        EXEC sys.sp_updateextendedproperty
            @name = N''MS_Description'',
            @value = @Description,
            @level0type = N''SCHEMA'', @level0name = @SchemaName,
            @level1type = @Level1Type, @level1name = @ObjectName;
    END
    ELSE
    BEGIN
        EXEC sys.sp_addextendedproperty
            @name = N''MS_Description'',
            @value = @Description,
            @level0type = N''SCHEMA'', @level0name = @SchemaName,
            @level1type = @Level1Type, @level1name = @ObjectName;
    END
END;'
    exec (@sql)

     SET @process = 'CREATE PROCEDURE dbo.usp_SetColumnDescription'
    SET @sql = 'CREATE PROCEDURE dbo.usp_SetColumnDescription
(
    @SchemaName  SYSNAME,
    @ObjectName  SYSNAME,
    @ColumnName  SYSNAME,
    @Description NVARCHAR(4000)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Level1Type VARCHAR(30);

    SELECT @Level1Type = CASE o.[type]
        WHEN ''U'' THEN ''TABLE''
        WHEN ''V'' THEN ''VIEW''
        ELSE NULL
    END
    FROM sys.objects o
    INNER JOIN sys.schemas s ON s.schema_id = o.schema_id
    WHERE s.name = @SchemaName
      AND o.name = @ObjectName;

    IF @Level1Type IS NULL
    BEGIN
        PRINT CONCAT(''Objeto no encontrado/no es tabla o vista: '', @SchemaName, ''.'', @ObjectName);
        RETURN;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.objects o
        INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
        INNER JOIN sys.columns c ON c.object_id = o.object_id
        WHERE s.name = @SchemaName
          AND o.name = @ObjectName
          AND c.name = @ColumnName
    )
    BEGIN
        PRINT CONCAT(''Columna no encontrada: '', @SchemaName, ''.'', @ObjectName, ''.'', @ColumnName);
        RETURN;
    END;

    IF EXISTS (
        SELECT 1
        FROM sys.extended_properties ep
        INNER JOIN sys.objects o ON ep.major_id = o.object_id
        INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
        INNER JOIN sys.columns c ON c.object_id = o.object_id AND c.column_id = ep.minor_id
        WHERE ep.name = N''MS_Description''
          AND s.name = @SchemaName
          AND o.name = @ObjectName
          AND c.name = @ColumnName
    )
    BEGIN
        EXEC sys.sp_updateextendedproperty
            @name = N''MS_Description'',
            @value = @Description,
            @level0type = N''SCHEMA'', @level0name = @SchemaName,
            @level1type = @Level1Type, @level1name = @ObjectName,
            @level2type = N''COLUMN'', @level2name = @ColumnName;
    END
    ELSE
    BEGIN
        EXEC sys.sp_addextendedproperty
            @name = N''MS_Description'',
            @value = @Description,
            @level0type = N''SCHEMA'', @level0name = @SchemaName,
            @level1type = @Level1Type, @level1name = @ObjectName,
            @level2type = N''COLUMN'', @level2name = @ColumnName;
    END
END;'
    exec (@sql)

    SET @process = 'Se agrega las description para documentacion'
    SET @sql = '
/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepACDChats'',
    @Description = N''Reporte de métricas operativas de chats ACD agrupadas por periodo, dominio, área y campaña. Incluye indicadores de volumen, atención, espera, abandono, finalización y nivel de servicio.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''date'',
    N''Fecha y hora del periodo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''inboundId'',
    N''Identificador de la campaña o grupo asociado al registro.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''inbound'',
    N''Nombre de la campaña o grupo asociado al registro.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''domain'',
    N''Dominio asociado al registro.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''areaId'',
    N''Identificador del área.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''area'',
    N''Nombre del área.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''totalChats'',
    N''Conteo total de chats del periodo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''wAbandoned'',
    N''Conteo de chats abandonados en espera.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''wConnected'',
    N''Conteo de chats conectados después de espera.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''tquemax'',
    N''Tiempo máximo en cola de espera.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''tqueavg'',
    N''Tiempo promedio en cola de espera.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''nmohin'',
    N''Conteo de chats en espera.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''contacted'',
    N''Conteo de chats contactados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''uncontacted'',
    N''Conteo de chats no contactados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''SL'',
    N''Porcentaje de nivel de servicio del periodo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''finishedByCostumer'',
    N''Conteo de chats finalizados por el cliente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''finishedByAgent'',
    N''Conteo de chats finalizados por el agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''finishedBySystem'',
    N''Conteo de chats finalizados por el sistema.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''finishedByAdmin'',
    N''Conteo de chats finalizados por administrador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''others'',
    N''Conteo de chats clasificados como otros.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''tqueueOverflow'',
    N''Conteo de chats que superaron la tolerancia de espera.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepACDChats'', N''totalConnected'',
    N''Conteo total de chats conectados.'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAgentCallStatusesByInterval'',
    @Description = N''Reporte de tiempos operativos del agente por intervalo. Incluye estados de disponibilidad, cierre, timbrado, transferencias, trabajo previo a llamada y auxiliares Ready.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''login'',
    N''Login del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''startInterval'',
    N''Fecha y hora de inicio del intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''endInterval'',
    N''Fecha y hora de fin del intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''readyTime'',
    N''Tiempo en estado disponible, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''twrapup'',
    N''Tiempo en cierre posterior a llamada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''tring'',
    N''Tiempo de timbrado de llamada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''tother'',
    N''Tiempo en otros estados, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''tnav'',
    N''Tiempo en capacitación o estado no disponible configurado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''tCallTransf'',
    N''Tiempo asociado a llamadas transferidas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''twbCall'',
    N''Tiempo en trabajo previo a llamada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''tipoAuxiliarReady_id'',
    N''Identificador del auxiliar Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''descripcion'',
    N''Descripción del auxiliar Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''descripcion_Time'',
    N''Nombre de métrica de tiempo del auxiliar Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentCallStatusesByInterval'', N''time'',
    N''Tiempo del auxiliar Ready, en segundos.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAgentGI'',
    @Description = N''Reporte general de indicadores del agente por intervalo. Incluye tiempos de sesión, disponibilidad, estados operativos, llamadas de entrada, llamadas de salida, abandonos, transferencias, espera y auxiliares Ready.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''user'',
    N''Nombre completo del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''login'',
    N''Login del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tlog'',
    N''Tiempo de sesión del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tunknown'',
    N''Tiempo en estado desconocido, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tav'',
    N''Tiempo disponible del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tnotav'',
    N''Tiempo no disponible del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tother'',
    N''Tiempo en otros estados, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tprob'',
    N''Tiempo en estados de problema, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tChatting'',
    N''Tiempo en conversación de chat, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tundefined'',
    N''Tiempo no clasificado dentro del intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nxferin'',
    N''Conteo de transferencias de entrada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nanswerin'',
    N''Conteo de llamadas de entrada contestadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nabndxferin'',
    N''Conteo de llamadas de entrada abandonadas en transferencia.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nabndringin'',
    N''Conteo de llamadas de entrada abandonadas durante timbrado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nabnddlgin'',
    N''Conteo de llamadas de entrada abandonadas durante diálo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''abndaxferin'',
    N''Conteo total de abandonos de entrada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nnoanswerin'',
    N''Conteo de llamadas de entrada no contestadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nlostin'',
    N''Conteo de llamadas de entrada perdidas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tdialogin'',
    N''Tiempo de diálo en llamadas de entrada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tnotesin'',
    N''Tiempo de notas en llamadas de entrada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tringin'',
    N''Tiempo de timbrado en llamadas de entrada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''txferin'',
    N''Tiempo de transferencia en llamadas de entrada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nxferout'',
    N''Conteo de transferencias de salida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nanswerout'',
    N''Conteo de llamadas de salida contestadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nabndxferout'',
    N''Conteo de llamadas de salida abandonadas en transferencia.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nabndrinut'',
    N''Conteo de llamadas de salida abandonadas durante timbrado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nabnddlut'',
    N''Conteo de llamadas de salida abandonadas durante diálo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''abndaxferout'',
    N''Conteo total de abandonos de salida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nnoanswerout'',
    N''Conteo de llamadas de salida no contestadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nlostout'',
    N''Conteo de llamadas de salida perdidas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tdialout'',
    N''Tiempo de diálo en llamadas de salida, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tnotesout'',
    N''Tiempo de notas en llamadas de salida, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''trinut'',
    N''Tiempo de timbrado en llamadas de salida, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''txferout'',
    N''Tiempo de transferencia en llamadas de salida, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nother'',
    N''Conteo de registros en otros estados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nmohin'',
    N''Conteo de llamadas de entrada en espera musical.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nmohout'',
    N''Conteo de llamadas de salida en espera musical.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nwhagin'',
    N''Conteo de llamadas de entrada en espera por agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nwhaut'',
    N''Conteo de llamadas de salida en espera por agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nwhcliin'',
    N''Conteo de llamadas de entrada en espera por cliente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''nwhcliout'',
    N''Conteo de llamadas de salida en espera por cliente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tManual'',
    N''Tiempo en llamada manual, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentGI'', N''tauxiliarready'',
    N''Tiempo en auxiliar Ready, en segundos.'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAgentHistory'',
    @Description = N''Historial de estados del agente. Incluye eventos de conexión, desconexión, estados operativos, duración del estado, campaña, llamada y área asociada.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHistory'', N''AgentName'',
    N''Login del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHistory'', N''date'',
    N''Fecha y hora del evento del estado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHistory'', N''EstadoAgente'',
    N''Estado registrado para el agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHistory'', N''TiempoEstado'',
    N''Duración del estado del agente en formato HH:mm:ss.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHistory'', N''Campaign'',
    N''Campaña o entrada asociada al estado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHistory'', N''CallKey'',
    N''Clave de llamada asociada al estado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHistory'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHistory'', N''areaId'',
    N''Identificador del área del agente.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAgentHSBCKPI'',
    @Description = N''Reporte diario de KPI operativos de agentes. Incluye horas operativas, horas pagadas, actividades offline, sign in, idle, conversación, cierre, AHT y auxiliar Ready.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''date'',
    N''Fecha del KPI reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''OpHoursOutbound'',
    N''Horas operativas de llamadas de salida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''OpHoursInbound'',
    N''Horas operativas de llamadas de entrada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''PaidHours'',
    N''Horas pagadas calculadas para el día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''OffLineActivities'',
    N''Horas promedio de actividades offline por analista.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''SignIn'',
    N''Horas consideradas como tiempo de sesión o sign in.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''AvgIdleSeconds'',
    N''Promedio de tiempo no disponible por analista, expresado en horas decimales.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''AvgTalkSeconds'',
    N''Tiempo total de conversación outbound, expresado en horas decimales.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''AvgWrapSeconds'',
    N''Tiempo total de cierre outbound, expresado en horas decimales.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''AvgAHTSeconds'',
    N''Tiempo total de conversación más cierre outbound, expresado en horas decimales.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''Year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''Month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''Day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''Hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''Minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentHSBCKPI'', N''AvgAuxiliarySeconds'',
    N''Tiempo total en auxiliar Ready, expresado en horas decimales.'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAgentKPI'',
    @Description = N''Reporte diario de KPI por agente. Incluye volumen de llamadas, llamadas de entrada y salida, llamadas finalizadas por umbrales de duración, indicador de quién colgó y tiempos promedio operativos.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''date'',
    N''Fecha del KPI reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''login'',
    N''Login del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''user'',
    N''Nombre completo del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''totalCalls'',
    N''Conteo total de llamadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''callsIn'',
    N''Conteo de llamadas de entrada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''callsOut'',
    N''Conteo de llamadas de salida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''finishedCalls10'',
    N''Conteo de llamadas finalizadas antes de 10 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''finishedCalls20'',
    N''Conteo de llamadas finalizadas antes de 20 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''finishedCalls30'',
    N''Conteo de llamadas finalizadas antes de 30 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''whoHung'',
    N''Indicador acumulado de quién colgó la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''callsAvgTime'',
    N''Tiempo promedio de cálculo de llamada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentKPI'', N''callsAvgTimeCustom'',
    N''Tiempo promedio operativo sin diálo por llamada, en segundos.'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAgentNotReady'',
    @Description = N''Reporte de estados Not Ready del agente por intervalo horario. Incluye tiempo de sesión, tipo Not Ready, conteo de eventos y tiempo acumulado por tipo.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''login'',
    N''Login del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''user'',
    N''Nombre completo del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''sessionTime'',
    N''Tiempo de sesión del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''tiponotreadyId'',
    N''Identificador del tipo Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''descripcion'',
    N''Descripción del tipo Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''descripcion_count'',
    N''Nombre de métrica de conteo del tipo Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''count'',
    N''Conteo de eventos Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''descripcion_time'',
    N''Nombre de métrica de tiempo del tipo Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''time'',
    N''Tiempo en estado Not Ready, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''timeSeconds'',
    N''Tiempo en estado Not Ready, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReady'', N''minutes'',
    N''Minuto'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAgentNotReadyDet'',
    @Description = N''Detalle de eventos Not Ready del agente. Incluye agente, tipo Not Ready, fecha y hora de inicio, fecha y hora de fin, duración del estado y desglose de fecha.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''date'',
    N''Fecha del inicio del estado Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''login'',
    N''Login del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''user'',
    N''Nombre completo del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''tiponotreadyId'',
    N''Identificador del tipo Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''status'',
    N''Descripción del tipo Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''startDate'',
    N''Fecha y hora de inicio del estado Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''endDate'',
    N''Fecha y hora de fin del estado Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''statusTime'',
    N''Duración del estado Not Ready, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''statusTimeSeconds'',
    N''Duración del estado Not Ready, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentNotReadyDet'', N''minutes'',
    N''Minuto'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAgentSession'',
    @Description = N''Reporte de sesiones de agentes. Incluye inicio y cierre de sesión, extensión utilizada, duración de la sesión y desglose de fecha.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSession'', N''date'',
    N''Fecha y hora de inicio de sesión.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSession'', N''login'',
    N''Login del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSession'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSession'', N''user'',
    N''Nombre completo del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSession'', N''extension'',
    N''Extensión utilizada por el agente en la sesión.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSession'', N''loginTime'',
    N''Fecha y hora de inicio de sesión.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSession'', N''loutTime'',
    N''Fecha y hora de cierre de sesión.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSession'', N''sessionTime'',
    N''Duración de la sesión, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSession'', N''sessionTimeSeconds'',
    N''Duración de la sesión, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSession'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSession'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSession'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSession'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSession'', N''minutes'',
    N''Minuto'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAgentSessionByInterval'',
    @Description = N''Reporte de sesión de agentes por intervalo. Incluye agente, extensión, tiempo de sesión acumulado y desglose de fecha del intervalo.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSessionByInterval'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSessionByInterval'', N''login'',
    N''Login del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSessionByInterval'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSessionByInterval'', N''user'',
    N''Nombre completo del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSessionByInterval'', N''extension'',
    N''Extensión utilizada por el agente en el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSessionByInterval'', N''sessionTime'',
    N''Tiempo de sesión del agente en el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSessionByInterval'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSessionByInterval'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSessionByInterval'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSessionByInterval'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSessionByInterval'', N''minutes'',
    N''Minuto'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAgentSummary'',
    @Description = N''Resumen diario de operación del agente. Incluye sesión, llamadas de entrada y salida, tiempos de conversación, cierre, disponibilidad, estados Not Ready, auxiliares Ready, estados operativos y área del agente.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''date'',
    N''Fecha del resumen del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''login'',
    N''Login del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''user'',
    N''Nombre completo del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''sessionTime'',
    N''Tiempo total de sesión del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''loginMktTime'',
    N''Fecha y hora del primer inicio de sesión del día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''loutMktTime'',
    N''Fecha y hora del último cierre de sesión del día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''callTengaged'',
    N''Tiempo total de conversación en llamadas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''ndTime'',
    N''Tiempo total en estados Not Ready, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''NCallsOut'',
    N''Conteo de llamadas de salida atendidas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''NCallsIn'',
    N''Conteo de llamadas de entrada atendidas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''NCallsCorta'',
    N''Conteo de llamadas cortadas o abandonadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''NAtend'',
    N''Conteo de llamadas no atendidas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''NNoCalif'',
    N''Conteo de llamadas sin calificación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''Available'',
    N''Tiempo disponible del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''avgCallTengaged'',
    N''Tiempo promedio de conversación más cierre por llamada atendida, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''twrapup'',
    N''Tiempo total de cierre posterior a llamada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''TypeNotReady'',
    N''Identificador del tipo Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''descripcion'',
    N''Descripción del tipo Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''descripcion_time'',
    N''Nombre de métrica de tiempo del tipo Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''time'',
    N''Tiempo del tipo Not Ready, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''transferStatus'',
    N''Tiempo total en transferencia de llamadas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''ringingTime'',
    N''Tiempo total de timbrado de llamadas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''unknownStatus'',
    N''Tiempo en estado desconocido, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''otherStatus'',
    N''Tiempo en otros estados, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''failureStatus'',
    N''Tiempo en estados de falla o problema, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''chatTengaged'',
    N''Tiempo en conversación de chat, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''undefinedTime'',
    N''Tiempo no clasificado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''dialingStatus'',
    N''Tiempo en marcación o llamada manual, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''TipoReadyAuxiliarId'',
    N''Identificador del auxiliar Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''auxiliarRedy_descripcion'',
    N''Descripción del auxiliar Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''descripcion_auxiliarRedyTime_time'',
    N''Nombre de métrica de tiempo del auxiliar Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''auxiliarRedyTime'',
    N''Tiempo en auxiliar Ready, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''areaId'',
    N''Identificador del área del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentSummary'', N''area'',
    N''Nombre del área del agente.'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAgentTimeShift'',
    @Description = N''Resumen diario de turno del agente. Incluye tiempos de sesión, diálo, llamadas manuales y predictivas, entrada, WhatsApp, transferencias, espera, marcación, notas, hold, Not Ready, problemas, otros estados, porcentajes sobre tiempo real, conteos de interacciones y datos del área.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''userName'',
    N''Login del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''fullName'',
    N''Nombre completo del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''date'',
    N''Fecha del resumen del turno.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''floginTime'',
    N''Fecha y hora del primer inicio de sesión del turno.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''floutTime'',
    N''Fecha y hora del último cierre de sesión del turno.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''statusAgente'',
    N''Clasificación del agente por antigüedad.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''areaName'',
    N''Nombre del área del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tDialo'',
    N''Tiempo total de diálo del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tManualAgent'',
    N''Tiempo de diálo en llamadas manuales, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tPredictivo'',
    N''Tiempo de diálo en llamadas predictivas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tIn'',
    N''Tiempo de diálo en llamadas de entrada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tWAIn'',
    N''Tiempo en conversaciones WhatsApp de entrada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tWAOut'',
    N''Tiempo en conversaciones WhatsApp de salida, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tTransferRecivied'',
    N''Tiempo en transferencias recibidas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tWaiting'',
    N''Tiempo disponible o en espera, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tDialing'',
    N''Tiempo en marcación manual, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tNotes'',
    N''Tiempo total en notas o cierre, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tHold'',
    N''Tiempo total en hold, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tGlobalNotReady'',
    N''Tiempo total en Not Ready, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''descripcion'',
    N''Descripción del tipo Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''descripcion_time'',
    N''Nombre de métrica de tiempo del tipo Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''time'',
    N''Tiempo del tipo Not Ready, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tProblem'',
    N''Tiempo en estados de problema, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tOthers'',
    N''Tiempo en otros estados, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pDialog'',
    N''Porcentaje de tiempo en diálo respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pManual'',
    N''Porcentaje de tiempo en llamadas manuales respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pPredictivo'',
    N''Porcentaje de tiempo en llamadas predictivas respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pIn'',
    N''Porcentaje de tiempo en llamadas de entrada respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pWAIn'',
    N''Porcentaje de tiempo en WhatsApp de entrada respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pWAOut'',
    N''Porcentaje de tiempo en WhatsApp de salida respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pTransferRecivied'',
    N''Porcentaje de tiempo en transferencias recibidas respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pWaiting'',
    N''Porcentaje de tiempo disponible o en espera respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pDialing'',
    N''Porcentaje de tiempo en marcación respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pNotes'',
    N''Porcentaje de tiempo en notas o cierre respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pHold'',
    N''Porcentaje de tiempo en hold respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pGlobalNotReady'',
    N''Porcentaje de tiempo en Not Ready respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''descripcion_percentage'',
    N''Nombre de métrica de porcentaje del tipo Not Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''percentage'',
    N''Porcentaje del tipo Not Ready respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pProblem'',
    N''Porcentaje de tiempo en problemas respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pOther'',
    N''Porcentaje de tiempo en otros estados respecto al tiempo real.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''pRealTime'',
    N''Porcentaje de tiempo real respecto al tiempo de trabajo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''nTotalAgente'',
    N''Conteo total de interacciones del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''nManual'',
    N''Conteo de llamadas manuales.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''nPredictivo'',
    N''Conteo de llamadas predictivas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''nIn'',
    N''Conteo de llamadas de entrada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''nTransferRecivied'',
    N''Conteo de transferencias recibidas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''nTransferDone'',
    N''Conteo de transferencias realizadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''nWAIn'',
    N''Conteo de conversaciones WhatsApp de entrada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''nWAOut'',
    N''Conteo de conversaciones WhatsApp de salida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tRealTime'',
    N''Tiempo real de sesión del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tOccupation'',
    N''Tiempo de ocupación del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''tWorkTime'',
    N''Tiempo transcurrido entre primer login y último lout, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAgentTimeShift'', N''hour'',
    N''Hora'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAnsweredCallsByDialingRetries'',
    @Description = N''Reporte de llamadas de salida por intentos de marcación. Incluye resultado de marcación, campaña, agente, extensión, horario, conversación, tipificación, subtipificación y cierre de llamada.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''date'',
    N''Fecha y hora de inicio de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''calId'',
    N''Identificador de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''telephone'',
    N''Teléfono marcado en la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''dialResultId'',
    N''Identificador del resultado de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''dialResult'',
    N''Descripción del resultado de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''tries'',
    N''Número de intentos de marcación de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''campaignId'',
    N''Identificador de la campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''campaign'',
    N''Nombre de la campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''agentName'',
    N''Nombre completo del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''extension'',
    N''Extensión asociada al agente durante el periodo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''startHour'',
    N''Hora de inicio de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''endHour'',
    N''Hora estimada de fin de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''dialogTime'',
    N''Tiempo de conversación de la llamada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''dispositionId'',
    N''Identificador de la tipificación de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''subDispositionId'',
    N''Identificador de la subtipificación de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''disposition'',
    N''Descripción de la tipificación de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''subDisposition'',
    N''Descripción de la subtipificación de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''wrapup'',
    N''Tiempo de cierre posterior a la llamada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAnsweredCallsByDialingRetries'', N''minutes'',
    N''Minuto'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAuxiliariesByAgentDet'',
    @Description = N''Reporte horario de auxiliares Ready por agente. Incluye tiempo de sesión, auxiliar registrado, conteo de eventos y tiempo acumulado por auxiliar.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAuxiliariesByAgentDet'', N''Date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAuxiliariesByAgentDet'', N''AgentName'',
    N''Nombre del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAuxiliariesByAgentDet'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAuxiliariesByAgentDet'', N''Login'',
    N''Login del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAuxiliariesByAgentDet'', N''sessionTime'',
    N''Tiempo de sesión del agente en el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAuxiliariesByAgentDet'', N''descripcion'',
    N''Descripción del auxiliar Ready o estatus especial.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAuxiliariesByAgentDet'', N''descripcion_count'',
    N''Nombre de métrica de conteo del auxiliar Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAuxiliariesByAgentDet'', N''count'',
    N''Conteo de eventos del auxiliar Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAuxiliariesByAgentDet'', N''descripcion_time'',
    N''Nombre de métrica de tiempo del auxiliar Ready.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAuxiliariesByAgentDet'', N''time'',
    N''Tiempo en auxiliar Ready, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAuxiliariesByAgentDet'', N''auxiliarId'',
    N''Identificador del auxiliar Ready.'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAvgAnswerTimeChats'',
    @Description = N''Reporte de tiempo promedio de primera respuesta en chats. Incluye agente, inbound, chat, periodo de atención y tiempo promedio de respuesta calculado en segundos.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAvgAnswerTimeChats'', N''date'',
    N''Fecha y hora del periodo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAvgAnswerTimeChats'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAvgAnswerTimeChats'', N''login'',
    N''Login del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAvgAnswerTimeChats'', N''inboundId'',
    N''Identificador del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAvgAnswerTimeChats'', N''inbound'',
    N''Nombre del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAvgAnswerTimeChats'', N''userName'',
    N''Nombre completo del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAvgAnswerTimeChats'', N''avgAnswerTime'',
    N''Tiempo promedio de primera respuesta del chat, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAvgAnswerTimeChats'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAvgAnswerTimeChats'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAvgAnswerTimeChats'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAvgAnswerTimeChats'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAvgAnswerTimeChats'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAvgAnswerTimeChats'', N''chatId'',
    N''Identificador del chat.'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAVRSAgent'',
    @Description = N''Reporte de evaluaciones de calidad por agente. Incluye agente evaluado, supervisor o calificador, formato de evaluación, medio, campaña o inbound, tipo de llamada y calificación obtenida.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''date'',
    N''Fecha de la evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''userId'',
    N''Identificador del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''user'',
    N''Login del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''agentName'',
    N''Nombre completo del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''Dispositions'',
    N''Calificación total de la evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''Disposition2'',
    N''Calificación total duplicada para compatibilidad del reporte.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''avgDisposition'',
    N''Calificación promedio o total de la evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''supervisorId'',
    N''Identificador del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''supervisorUser'',
    N''Login del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''Supervisor'',
    N''Nombre completo del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''idFormato'',
    N''Identificador del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''Template'',
    N''Nombre del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''idMedia'',
    N''Identificador de la grabación o medio evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''media'',
    N''Medio evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''cam_id'',
    N''Identificador de la campaña o inbound evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''tipoLlamada'',
    N''Tipo de llamada evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''campaignAcd'',
    N''Nombre de la campaña o inbound evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgent'', N''minutes'',
    N''Minuto'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAVRSAgentChat'',
    @Description = N''Reporte de evaluaciones de calidad de chats por agente. Incluye agente evaluado, formato de evaluación, calificación, chat, inbound y fecha de evaluación.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''date'',
    N''Fecha de la evaluación del chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''userId'',
    N''Identificador del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''user'',
    N''Login del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''agentName'',
    N''Nombre completo del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''Dispositions'',
    N''Calificación total de la evaluación del chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''Disposition2'',
    N''Calificación total duplicada para compatibilidad del reporte.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''avgDisposition'',
    N''Calificación total de la evaluación del chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''idFormato'',
    N''Identificador del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''Template'',
    N''Nombre del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''chatId'',
    N''Identificador del chat evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''inboundId'',
    N''Identificador del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''inbound'',
    N''Nombre del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSAgentChat'', N''minutes'',
    N''Minuto'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAVRSDetailChat'',
    @Description = N''Detalle de evaluaciones de calidad de chats. Incluye agente evaluado, formato, pregunta, respuesta, puntaje de la pregunta, inbound y chat evaluado.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDetailChat'', N''date'',
    N''Fecha de la evaluación del chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDetailChat'', N''userId'',
    N''Identificador del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDetailChat'', N''user'',
    N''Login del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDetailChat'', N''agentName'',
    N''Nombre completo del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDetailChat'', N''templateId'',
    N''Identificador del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDetailChat'', N''Template'',
    N''Nombre del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDetailChat'', N''question'',
    N''Pregunta evaluada en el formato.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDetailChat'', N''answer'',
    N''Respuesta seleccionada para la pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDetailChat'', N''Disposition2'',
    N''Puntaje obtenido en la pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDetailChat'', N''inboundId'',
    N''Identificador del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDetailChat'', N''inbound'',
    N''Nombre del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDetailChat'', N''chatId'',
    N''Identificador del chat evaluado.'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAVRSDisposition'',
    @Description = N''Reporte de calificaciones AVRS por formato, agente y grabación evaluada. Incluye fecha de evaluación, formato, agente, grabación y calificación total obtenida.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDisposition'', N''date'',
    N''Fecha y hora de la evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDisposition'', N''idFormato'',
    N''Identificador del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDisposition'', N''Template'',
    N''Nombre del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDisposition'', N''userId'',
    N''Identificador del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDisposition'', N''agentName'',
    N''Nombre completo del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDisposition'', N''grabId'',
    N''Identificador de la grabación evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDisposition'', N''Disposition'',
    N''Calificación total de la evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDisposition'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDisposition'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDisposition'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDisposition'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSDisposition'', N''minutes'',
    N''Minuto'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAVRSQuestion'',
    @Description = N''Reporte de resultados AVRS por pregunta evaluada. Incluye agente, supervisor, formato, sección, pregunta, medio, campaña o inbound y puntaje promedio obtenido.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''date'',
    N''Fecha de la evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''userId'',
    N''Identificador del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''user'',
    N''Login del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''agentName'',
    N''Nombre completo del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''supervisorId'',
    N''Identificador del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''supervisorUser'',
    N''Login del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''Supervisor'',
    N''Nombre completo del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''templateId'',
    N''Identificador del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''Template'',
    N''Nombre del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''sectionId'',
    N''Identificador de la sección o concepto evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''Section'',
    N''Nombre de la sección o concepto evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''questionId'',
    N''Identificador de la pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''question'',
    N''Pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''Dispositions'',
    N''Puntaje promedio obtenido en la pregunta.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''avgDisposition'',
    N''Puntaje promedio obtenido en la pregunta.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''mediaId'',
    N''Identificador de la grabación o medio evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''media'',
    N''Medio evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''cam_id'',
    N''Identificador de la campaña o inbound evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestion'', N''campaignAcd'',
    N''Nombre de la campaña o inbound evaluado.'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAVRSQuestionChat'',
    @Description = N''Reporte de resultados AVRS por pregunta en evaluaciones de chat. Incluye agente evaluado, formato, pregunta, puntaje obtenido e inbound asociado.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionChat'', N''date'',
    N''Fecha de la evaluación del chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionChat'', N''userId'',
    N''Identificador del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionChat'', N''user'',
    N''Login del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionChat'', N''agentName'',
    N''Nombre completo del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionChat'', N''templateId'',
    N''Identificador del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionChat'', N''Template'',
    N''Nombre del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionChat'', N''questionId'',
    N''Identificador de la pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionChat'', N''question'',
    N''Pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionChat'', N''Dispositions'',
    N''Puntaje obtenido en la pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionChat'', N''avgDisposition'',
    N''Puntaje obtenido en la pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionChat'', N''inboundId'',
    N''Identificador del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionChat'', N''inbound'',
    N''Nombre del inbound asociado al chat.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAVRSQuestionDetail'',
    @Description = N''Detalle de evaluaciones AVRS por agente, supervisor, formato y medio evaluado. Incluye fecha de evaluación, calificación total obtenida y desglose de fecha.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''date'',
    N''Fecha y hora de la evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''userId'',
    N''Identificador del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''user'',
    N''Login del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''agentName'',
    N''Nombre completo del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''supervisorId'',
    N''Identificador del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''supervisorUser'',
    N''Login del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''Supervisor'',
    N''Nombre completo del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''templateId'',
    N''Identificador del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''Template'',
    N''Nombre del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''score'',
    N''Calificación total de la evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''media'',
    N''Medio evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSQuestionDetail'', N''minutes'',
    N''Minuto'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAVRSRateChat'',
    @Description = N''Detalle de calificaciones AVRS por pregunta en evaluaciones de chat. Incluye agente evaluado, chat, formato, pregunta, respuesta, puntaje obtenido, formulario de evaluación e inbound asociado.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''date'',
    N''Fecha de la evaluación del chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''userId'',
    N''Identificador del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''user'',
    N''Login del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''agentName'',
    N''Nombre completo del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''chatId'',
    N''Identificador del chat evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''templateId'',
    N''Identificador del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''Template'',
    N''Nombre del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''question'',
    N''Pregunta evaluada en el formato.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''answer'',
    N''Respuesta seleccionada para la pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''Disposition2'',
    N''Puntaje obtenido en la pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''Dispositions'',
    N''Puntaje obtenido en la pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''avgDisposition'',
    N''Puntaje obtenido en la pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''formaId'',
    N''Identificador del formulario de evaluación aplicado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''inboundId'',
    N''Identificador del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''inbound'',
    N''Nombre del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateChat'', N''minutes'',
    N''Minuto'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAVRSRateDetail'',
    @Description = N''Detalle de calificaciones AVRS por pregunta evaluada. Incluye agente, supervisor o calificador, medio, formato, sección, pregunta, respuesta, puntaje obtenido, campaña o inbound y fecha de evaluación.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''date'',
    N''Fecha y hora de la evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''userId'',
    N''Identificador del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''user'',
    N''Login del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''agentName'',
    N''Nombre completo del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''supervisorId'',
    N''Identificador del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''supervisorUser'',
    N''Login del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''Supervisor'',
    N''Nombre completo del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''idMedia'',
    N''Identificador de la grabación evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''media'',
    N''Medio evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''templateId'',
    N''Identificador del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''Template'',
    N''Nombre del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''Section'',
    N''Sección o concepto evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''question'',
    N''Pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''answer'',
    N''Respuesta registrada para la pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''Disposition2'',
    N''Puntaje obtenido en la pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''Dispositions'',
    N''Puntaje obtenido en la pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''avgDisposition'',
    N''Puntaje obtenido en la pregunta evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''cam_id'',
    N''Identificador de la campaña o inbound evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''tipoLlamada'',
    N''Tipo de llamada evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''campaignAcd'',
    N''Nombre de la campaña o inbound evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''formaId'',
    N''Identificador del formulario o formato aplicado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSRateDetail'', N''minutes'',
    N''Minuto'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAVRSScores'',
    @Description = N''Resumen diario de evaluaciones AVRS por usuario. Incluye conteo de evaluaciones y promedio de calificación, considerando agentes evaluados y supervisores.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSScores'', N''date'',
    N''Fecha del resumen de evaluaciones.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSScores'', N''userId'',
    N''Identificador del usuario evaluado o supervisor.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSScores'', N''login'',
    N''Login del usuario evaluado o supervisor.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSScores'', N''agentName'',
    N''Nombre completo del usuario evaluado o supervisor.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSScores'', N''disposition'',
    N''Conteo de evaluaciones AVRS del usuario en el día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSScores'', N''avgDisposition'',
    N''Promedio de calificación AVRS del usuario en el día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSScores'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSScores'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSScores'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSScores'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSScores'', N''minutes'',
    N''Minuto'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepAVRSSection'',
    @Description = N''Reporte de resultados AVRS por sección evaluada. Incluye agente, supervisor o calificador, formato, sección, medio, campaña o inbound y puntaje promedio obtenido.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''date'',
    N''Fecha de la evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''userId'',
    N''Identificador del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''user'',
    N''Login del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''agentName'',
    N''Nombre completo del agente evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''supervisorId'',
    N''Identificador del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''supervisorUser'',
    N''Login del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''Supervisor'',
    N''Nombre completo del supervisor o calificador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''templateId'',
    N''Identificador del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''Template'',
    N''Nombre del formato de evaluación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''sectionId'',
    N''Identificador de la sección o concepto evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''Section'',
    N''Nombre de la sección o concepto evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''Dispositions'',
    N''Puntaje promedio obtenido en la sección evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''avgDisposition'',
    N''Puntaje promedio obtenido en la sección evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''idMedia'',
    N''Identificador de la grabación o medio evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''media'',
    N''Medio evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''cam_id'',
    N''Identificador de la campaña o inbound evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''tipoLlamada'',
    N''Tipo de llamada evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''campaignAcd'',
    N''Nombre de la campaña o inbound evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''idForma'',
    N''Identificador del formulario o formato aplicado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''TemplateSection'',
    N''Nombre compuesto del formato y sección evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepAVRSSection'', N''templateSectionId'',
    N''Identificador de la sección dentro del formato.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepCallbackQueue'',
    @Description = N''Reporte de callbacks en cola asociados a campañas inbound. Incluye llamada, ANI, campaña, reintentos, fecha de transferencia, duración de conversación y teléfono relacionado.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallbackQueue'', N''date'',
    N''Fecha y hora de registro del callback en cola.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallbackQueue'', N''calid'',
    N''Identificador de la llamada asociada al callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallbackQueue'', N''CALANI'',
    N''ANI registrado en la solicitud de callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallbackQueue'', N''inboundCampaignId'',
    N''Identificador de la campaña inbound asociada al callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallbackQueue'', N''inboundCampaign'',
    N''Nombre de la campaña inbound asociada al callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallbackQueue'', N''retry'',
    N''Número de reintentos del callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallbackQueue'', N''xferDate'',
    N''Fecha y hora de transferencia del callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallbackQueue'', N''duration'',
    N''Tiempo de conversación de la llamada asociada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallbackQueue'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallbackQueue'', N''mounth'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallbackQueue'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallbackQueue'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallbackQueue'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallbackQueue'', N''telephone'',
    N''Teléfono ANI de la llamada inbound asociada.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepCallTimeSummary'',
    @Description = N''Resumen de tiempos de atención por agente e intervalo. Incluye sesión, disponibilidad, indisponibilidad, diálo de llamadas de entrada y salida, chats atendidos, llamadas contestadas y abandonadas.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''user'',
    N''Nombre del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''Agent'',
    N''Login del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''sessionTime'',
    N''Tiempo de sesión del agente en el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''unavailableTime'',
    N''Tiempo no disponible del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''TiempoDispo'',
    N''Tiempo disponible del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''loginTime'',
    N''Hora de inicio de sesión del intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''loutTime'',
    N''Hora de cierre de sesión del intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''genDialogTime'',
    N''Tiempo total de diálo en llamadas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''avgCallTime'',
    N''Tiempo promedio de diálo por llamada contestada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''inboundTime'',
    N''Tiempo de diálo en llamadas de entrada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''avginboundTime'',
    N''Tiempo promedio de diálo en llamadas de entrada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''outboundTime'',
    N''Tiempo de diálo en llamadas de salida, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''avutboundTime'',
    N''Tiempo promedio de diálo en llamadas de salida, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''tChatting'',
    N''Tiempo total en chats atendidos, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''avgchatTime'',
    N''Tiempo promedio de chat atendido, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''chatsAttended'',
    N''Conteo de chats atendidos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''callsOut'',
    N''Conteo de llamadas de salida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''callsIn'',
    N''Conteo de llamadas de entrada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''abandonedCalls'',
    N''Conteo de llamadas abandonadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''nanswer2'',
    N''Conteo total de llamadas contestadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallTimeSummary'', N''minutes'',
    N''Minuto'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepCallXfer'',
    @Description = N''Reporte de transferencias de llamadas. Incluye llamada, tipo de transferencia, destino, agente, origen, tiempos antes y después de transferir, duración total, tipo de teléfono y número entrante.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''date'',
    N''Fecha de finalización de la transferencia.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''callid'',
    N''Identificador de la llamada transferida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''CallTypes'',
    N''Tipo de llamada transferida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''Agent'',
    N''Nombre completo del agente asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''xfertype'',
    N''Tipo de transferencia realizada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''destination'',
    N''Destino de la transferencia.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''timebeforexfer'',
    N''Tiempo antes de realizar la transferencia, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''timeafterxfer'',
    N''Tiempo posterior a la transferencia, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''startDate'',
    N''Fecha y hora estimada de inicio del periodo de transferencia.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''endDate'',
    N''Fecha y hora de finalización de la transferencia.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''Origin'',
    N''Campaña o inbound de origen de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''TotalTimeDuration'',
    N''Duración total del periodo de transferencia, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''TipoTel'',
    N''Tipo de teléfono asociado a la transferencia.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''userId'',
    N''Identificador del agente asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepCallXfer'', N''incomingNumber'',
    N''ANI o número entrante asociado a la transferencia.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepChatsAndCallsGeneral'',
    @Description = N''Reporte general de llamadas de entrada y chats por inbound e intervalo horario. Incluye totales, abandonos en cola, tiempos de espera, no atendidos, atendidos, conectados y niveles de servicio por canal.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''date'',
    N''Fecha y hora del periodo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''inboundId'',
    N''Identificador del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''inbound'',
    N''Nombre del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''totalCalls'',
    N''Conteo total de llamadas de entrada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''totalChats'',
    N''Conteo total de chats.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''abndQueueCalls'',
    N''Conteo de llamadas abandonadas en cola.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''abndQueueChats'',
    N''Conteo de chats abandonados en espera.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''maxTQueueCalls'',
    N''Tiempo máximo en cola de llamadas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''maxTQueueChats'',
    N''Tiempo máximo en cola de chats, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''noAnswerCalls'',
    N''Conteo de llamadas no atendidas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''noAnswerChats'',
    N''Conteo de chats no conectados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''answerCalls'',
    N''Conteo de llamadas contestadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''answerChats'',
    N''Conteo de chats conectados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''serviceLevelCalls'',
    N''Porcentaje de llamadas contestadas respecto al total de llamadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''serviceLevelChats'',
    N''Porcentaje de chats conectados o abandonados válidos respecto al total de chats evaluados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''avgTQueueCalls'',
    N''Tiempo promedio en cola de llamadas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''avgTQueueChats'',
    N''Tiempo promedio en cola de chats, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsAndCallsGeneral'', N''minutes'',
    N''Minuto'';



/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepChatsDetail'',
    @Description = N''Detalle de chats por solicitud. Incluye inbound, estatus, tipificación, dominio, agente, cliente, tiempos de espera, transferencia, conversación y desglose de fecha.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''date'',
    N''Fecha y hora de solicitud del chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''inboundId'',
    N''Identificador del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''inbound'',
    N''Nombre del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''chatStatusId'',
    N''Identificador del estatus del chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''chatStatus'',
    N''Descripción del estatus del chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''dispositionId'',
    N''Identificador de la tipificación del chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''disposition'',
    N''Descripción de la tipificación del chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''subDispositionId'',
    N''Identificador de la subtipificación del chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''subDisposition'',
    N''Descripción de la subtipificación del chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''domain'',
    N''Dominio asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''userId'',
    N''Identificador del agente asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''userName'',
    N''Login del agente asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''clientName'',
    N''Nombre del cliente registrado en el chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''mohTime'',
    N''Tiempo en cola o espera del chat, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''xferTime'',
    N''Tiempo previo a la conexión del chat después de descontar la espera en cola, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''tChatting'',
    N''Tiempo de conversación del chat, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''agentName'',
    N''Nombre completo del agente asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsDetail'', N''chatId'',
    N''Identificador del chat.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepChatsEffectiveness'',
    @Description = N''Reporte de efectividad de chats por inbound e intervalo horario. Incluye chats totales, contestados, abandonados, tiempos promedio de respuesta, cola y abandono, además de conteos por estatus operativo del chat.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''date'',
    N''Fecha y hora del periodo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''inboundId'',
    N''Identificador del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''inbound'',
    N''Nombre del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''ntotalChat'',
    N''Conteo total de chats del periodo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''nanswerChat'',
    N''Conteo de chats contestados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''nabndChat'',
    N''Conteo de chats abandonados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''avgAnswerTime'',
    N''Tiempo promedio de primera respuesta en chats contestados, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''avgQueueTime'',
    N''Tiempo promedio en cola de chats contestados, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''avgAbandonTimeChat'',
    N''Tiempo promedio en cola de chats abandonados, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''nrequestChat'',
    N''Conteo de chats en estado solicitado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''ninactiveDomainChat'',
    N''Conteo de chats con dominio inactivo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''nunavailableAgentsChat'',
    N''Conteo de chats sin agentes disponibles.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''nassignedChat'',
    N''Conteo de chats asignados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''noutOfServiceChat'',
    N''Conteo de chats fuera de servicio.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''noutOfScheduleChat'',
    N''Conteo de chats fuera de horario.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''nnoSignedAgents'',
    N''Conteo de chats sin agentes firmados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''nqueuedChat'',
    N''Conteo de chats en cola.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''nqueueOverflow'',
    N''Conteo de chats con desbordamiento de cola.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsEffectiveness'', N''ntimeOverflow'',
    N''Conteo de chats con desbordamiento por tiempo.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepChatsNotContacted'',
    @Description = N''Reporte de chats no contactados por inbound, área, estatus e intervalo horario. Incluye conteo de chats en estados operativos que impidieron el contacto.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsNotContacted'', N''date'',
    N''Fecha y hora del periodo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsNotContacted'', N''inboundId'',
    N''Identificador del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsNotContacted'', N''inbound'',
    N''Nombre del inbound asociado al chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsNotContacted'', N''areaId'',
    N''Identificador del área asociada al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsNotContacted'', N''area'',
    N''Nombre del área asociada al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsNotContacted'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsNotContacted'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsNotContacted'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsNotContacted'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsNotContacted'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsNotContacted'', N''chatStatusId'',
    N''Identificador del estatus de chat no contactado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsNotContacted'', N''chatStatus_count'',
    N''Nombre de métrica de conteo del estatus de chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepChatsNotContacted'', N''count'',
    N''Conteo de chats no contactados del estatus.'';



/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepDetailAgent'',
    @Description = N''Detalle operativo del agente por intervalo horario. Incluye tiempos de sesión, actividad, conversación, espera, no disponibilidad, auxiliares Ready, llamadas, llamadas completas y porcentajes operativos.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''userId'',
    N''Identificador del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''user'',
    N''Login del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''userName'',
    N''Nombre completo del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''sessionTime'',
    N''Tiempo de sesión del agente en el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''activeTime'',
    N''Tiempo activo del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''talkingtTime'',
    N''Tiempo de conversación y notas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''holdTime'',
    N''Tiempo de transferencia y timbrado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''unavaibleTime'',
    N''Tiempo no disponible del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''talkingPercent'',
    N''Porcentaje de tiempo en conversación respecto a una hora.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''waitpercent'',
    N''Porcentaje de tiempo en transferencia y timbrado respecto a una hora.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''readyPercent'',
    N''Porcentaje de tiempo disponible respecto a una hora.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''adherencia'',
    N''Proporción de tiempo activo respecto al tiempo de sesión.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''totalCalls'',
    N''Conteo total de llamadas del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''callsByHour'',
    N''Conteo de llamadas del agente en el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''complete'',
    N''Conteo de llamadas con calificación completa.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''completeByHourHideAndRename'',
    N''Promedio objetivo de llamadas completas por hora.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''percentComplete'',
    N''Proporción de llamadas completas respecto al total de llamadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''auxiliaryReadyTime'',
    N''Tiempo en auxiliar Ready, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''readyTime'',
    N''Tiempo disponible del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''otherTime'',
    N''Tiempo en estados no clasificados principales, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''auxiliaryReadyPercent'',
    N''Porcentaje de tiempo en auxiliar Ready respecto a una hora.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''unavaiblePercent'',
    N''Porcentaje de tiempo no disponible respecto a una hora.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDetailAgent'', N''otherPercent'',
    N''Porcentaje de tiempo en otros estados respecto a una hora.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepDialingResultsDetail'',
    @Description = N''Detalle de resultados de marcación outbound. Incluye teléfono marcado, resultado de marcación, agente asociado, campaña y fecha del intento.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDialingResultsDetail'', N''date'',
    N''Fecha y hora del intento de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDialingResultsDetail'', N''telephone'',
    N''Teléfono marcado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDialingResultsDetail'', N''dialResultId'',
    N''Identificador del resultado de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDialingResultsDetail'', N''dialResult'',
    N''Descripción del resultado de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDialingResultsDetail'', N''userId'',
    N''Identificador del agente asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDialingResultsDetail'', N''login'',
    N''Login del agente asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDialingResultsDetail'', N''campaignId'',
    N''Identificador de la campaña asociada a la marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDialingResultsDetail'', N''campaign'',
    N''Nombre de la campaña asociada a la marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDialingResultsDetail'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDialingResultsDetail'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDialingResultsDetail'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDialingResultsDetail'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepDialingResultsDetail'', N''minutes'',
    N''Minuto'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepInAbnd'',
    @Description = N''Reporte de llamadas inbound abandonadas en cola por intervalo, área, inbound y grupos de trabajo. Incluye conteo de abandonos, tiempo máximo, tiempo total y distribución por rans de duración.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''areaId'',
    N''Identificador del área asociada al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''area'',
    N''Nombre del área asociada al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''workgroupId'',
    N''Identificador del grupo de trabajo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''workgroup'',
    N''Nombres de grupos de trabajo asociados al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''inboundId'',
    N''Identificador del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''inbound'',
    N''Nombre del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''amount'',
    N''Conteo de llamadas abandonadas en cola.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''timeMax'',
    N''Tiempo máximo antes del abandono, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''timeTot'',
    N''Tiempo total acumulado antes del abandono, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''LT10'',
    N''Conteo de abandonos con duración menor a 10 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''LT20'',
    N''Conteo de abandonos con duración de 10 a 19 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''LT30'',
    N''Conteo de abandonos con duración de 20 a 29 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''LT40'',
    N''Conteo de abandonos con duración de 30 a 39 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''LT50'',
    N''Conteo de abandonos con duración de 40 a 49 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''LT60'',
    N''Conteo de abandonos con duración de 50 a 59 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''LT120'',
    N''Conteo de abandonos con duración de 60 a 119 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''LT180'',
    N''Conteo de abandonos con duración de 120 a 179 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''LT240'',
    N''Conteo de abandonos con duración de 180 a 239 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''LT300'',
    N''Conteo de abandonos con duración de 240 a 299 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''GT300'',
    N''Conteo de abandonos con duración igual o mayor a 300 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAbnd'', N''workgroupIds'',
    N''Identificadores de grupos de trabajo asociados al inbound.'';



/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepInAnsw'',
    @Description = N''Reporte de llamadas inbound contestadas por intervalo, área, inbound y grupos de trabajo. Incluye conteo de llamadas contestadas, tiempo máximo, tiempo total y distribución por rans de tiempo antes de contestar.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''areaId'',
    N''Identificador del área asociada al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''area'',
    N''Nombre del área asociada al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''workgroupId'',
    N''Identificador del grupo de trabajo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''workgroup'',
    N''Nombres de grupos de trabajo asociados al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''inboundId'',
    N''Identificador del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''inbound'',
    N''Nombre del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''amount'',
    N''Conteo de llamadas inbound contestadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''timeMax'',
    N''Tiempo máximo antes de contestar, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''timeTot'',
    N''Tiempo total acumulado antes de contestar, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''LT10'',
    N''Conteo de llamadas contestadas en menos de 10 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''LT20'',
    N''Conteo de llamadas contestadas entre 10 y 19 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''LT30'',
    N''Conteo de llamadas contestadas entre 20 y 29 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''LT40'',
    N''Conteo de llamadas contestadas entre 30 y 39 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''LT50'',
    N''Conteo de llamadas contestadas entre 40 y 49 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''LT60'',
    N''Conteo de llamadas contestadas entre 50 y 59 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''LT120'',
    N''Conteo de llamadas contestadas entre 60 y 119 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''LT180'',
    N''Conteo de llamadas contestadas entre 120 y 179 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''LT240'',
    N''Conteo de llamadas contestadas entre 180 y 239 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''LT300'',
    N''Conteo de llamadas contestadas entre 240 y 299 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''GT300'',
    N''Conteo de llamadas contestadas en 300 segundos o más.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInAnsw'', N''workgroupIds'',
    N''Identificadores de grupos de trabajo asociados al inbound.'';



/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepInBill01900'',
    @Description = N''Reporte de facturación de llamadas inbound asociadas al DNIS 01900 por inbound e intervalo horario. Incluye volumen de llamadas, transferencias, tiempos operativos, minutos facturables y costo estimado.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''inboundId'',
    N''Identificador del inbound asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''inbound'',
    N''Nombre del inbound asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''ntotalin'',
    N''Conteo total de llamadas inbound del intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''nxfer'',
    N''Conteo de llamadas transferidas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''tque2'',
    N''Tiempo total en cola de llamadas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''txfer'',
    N''Tiempo total de transferencia, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''tdialog'',
    N''Tiempo total de conversación, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''tring'',
    N''Tiempo total de timbrado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''nminutes'',
    N''Minutos facturables calculados sobre cola, transferencia, conversación y timbrado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''ncost'',
    N''Costo estimado de la llamada o intervalo facturable.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInBill01900'', N''minutes'',
    N''Minuto'';



/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepInboundKPI'',
    @Description = N''Reporte diario de KPI inbound. Incluye volumen de llamadas, llamadas con agente, abandonos, nivel de servicio, métricas por tipificación, quejas y tiempos operativos de idle, conversación y cierre.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''date'',
    N''Fecha del KPI inbound reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''NCO'',
    N''Conteo total de registros inbound evaluados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''NCH'',
    N''Conteo de registros inbound con agente asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''abandonedCalls'',
    N''Conteo de llamadas inbound abandonadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''SL'',
    N''Porcentaje de llamadas contestadas dentro del umbral de nivel de servicio.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''RPC'',
    N''Conteo de llamadas inbound contestadas con tipificaciones RPC.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''PTP'',
    N''Conteo de llamadas inbound contestadas con tipificaciones PTP.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''PK'',
    N''Conteo de llamadas inbound contestadas con tipificaciones PK.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''Quejas'',
    N''Conteo de llamadas clasificadas como queja.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''AvgIdleSeconds'',
    N''Promedio de tiempo no disponible por agente, expresado en horas decimales.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''AvgTalkSeconds'',
    N''Tiempo total de conversación inbound, expresado en horas decimales.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''AvgWrapSeconds'',
    N''Tiempo total de cierre inbound, expresado en horas decimales.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''Year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInboundKPI'', N''minutes'',
    N''Minuto'';



/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepInCalls'',
    @Description = N''Reporte de llamadas inbound por intervalo, inbound, DNIS, grupo de trabajo y área. Incluye volumen, transferencias, abandonos, tiempos de cola, llamadas contestadas, no contestadas, nivel de servicio, indicadores de espera y datos de detalle de llamada.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''inboundId'',
    N''Identificador del inbound asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''inbound'',
    N''Nombre del inbound asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''dnisId'',
    N''Identificador del DNIS asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''dnis'',
    N''Descripción del DNIS asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''workgroupId'',
    N''Identificador del grupo de trabajo asociado al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''workgroup'',
    N''Nombre del grupo de trabajo asociado al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''areaId'',
    N''Identificador del área asociada al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''area'',
    N''Nombre del área asociada al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''ntotalin'',
    N''Conteo total de llamadas inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''nxfer'',
    N''Conteo de llamadas transferidas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''nabndque'',
    N''Conteo de llamadas abandonadas en cola.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''nxferque'',
    N''Conteo de llamadas transferidas que pasaron por cola.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''nnoxfer'',
    N''Conteo de llamadas no transferidas por condiciones operativas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''tquemax'',
    N''Tiempo máximo en cola, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''tque'',
    N''Tiempo total en cola, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''nque'',
    N''Conteo de llamadas que pasaron por cola.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''nanswer'',
    N''Conteo de llamadas contestadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''nnoanswer'',
    N''Conteo de llamadas no contestadas durante timbrado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''nlost'',
    N''Conteo de llamadas perdidas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''nabndxferincall'',
    N''Conteo de llamadas abandonadas durante transferencia.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''nabndringincall'',
    N''Conteo de llamadas abandonadas durante timbrado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''nabnddialogincall'',
    N''Conteo de llamadas abandonadas durante diálo corto.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''postot'',
    N''Conteo de posiciones o agentes asociados al inbound en el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''postime'',
    N''Tiempo efectivo de posiciones del inbound en el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''SLP1'',
    N''Numerador del nivel de servicio inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''SLP2'',
    N''Denominador del nivel de servicio inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''avg'',
    N''Tiempo promedio en cola, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''SL'',
    N''Porcentaje de nivel de servicio inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''nMoh'',
    N''Conteo de llamadas con tiempo en espera musical.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''nWHag'',
    N''Conteo de llamadas colgadas por agente o con indicador WhoHung mayor a cero.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''nWHcl'',
    N''Conteo de llamadas colgadas por cliente o con indicador WhoHung igual a cero.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''callIdIn'',
    N''Identificador de la llamada inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''phonein'',
    N''ANI o teléfono de origen de la llamada inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''dateStartDetail'',
    N''Fecha y hora de inicio de la llamada inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCalls'', N''DniNumber'',
    N''Número DNIS marcado por la llamada inbound.'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepInCallsDetail'',
    @Description = N''Detalle de llamadas inbound. Incluye inbound, estatus, tipificación, DNIS, agente, tiempos operativos, grabación, proveedor, troncal, datos capturados, IVR, callback, área y números origen/destino.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''date'', N''Fecha y hora de inicio de la llamada inbound.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''inboundId'', N''Identificador del inbound asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''ACDGroup'', N''Nombre del inbound o grupo ACD asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''callStatusId'', N''Identificador del estatus de la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''callStatus'', N''Descripción del estatus de la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''dispositionId'', N''Identificador de la tipificación de la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''disposition'', N''Descripción de la tipificación de la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''subDispositionId'', N''Identificador de la subtipificación de la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''subDisposition'', N''Descripción de la subtipificación de la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''dnisId'', N''Identificador del DNIS asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''dnis'', N''Número DNIS asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''userId'', N''Identificador del agente o agente virtual asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''user'', N''Login del agente asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''callKey'', N''Clave funcional de la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''ANI'', N''ANI o número de origen de la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''queueTime'', N''Tiempo de espera en cola, en segundos.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''xferTime'', N''Tiempo de transferencia, en segundos.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''ringingTime'', N''Tiempo de timbrado, en segundos.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''dialogTime'', N''Tiempo de conversación, en segundos.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''extension'', N''Extensión asociada a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''agentName'', N''Nombre completo del agente asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''whoHangUp'', N''Persona o entidad que colgó la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''mohTime'', N''Tiempo en espera musical, en segundos.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''year'', N''Año'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''month'', N''Mes'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''day'', N''Día'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''hour'', N''Hora'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''minutes'', N''Minuto'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''provedorId'', N''Identificador del proveedor asociado al puerto/troncal.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''provider'', N''Nombre del proveedor asociado al puerto/troncal.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''trunk'', N''Puerto o troncal por donde ingresó la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''fileMoved'', N''Ubicación o estado de movimiento del archivo de grabación.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''twrapup'', N''Tiempo de cierre posterior a la llamada, en segundos.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''AverageHandleTime'', N''Tiempo de conversación más cierre de la llamada, en segundos.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''Dato1'', N''Dato capturado 1 asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''Dato2'', N''Dato capturado 2 asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''Dato3'', N''Dato capturado 3 asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''Dato4'', N''Dato capturado 4 asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''Dato5'', N''Dato capturado 5 asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''callid'', N''Identificador de la llamada inbound.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''grabId'', N''Identificador de la grabación asociada a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''nameDNI'', N''Nombre o descripción del DNIS.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''numDNI'', N''Número DNIS asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''collectCall'', N''Indicador textual de existencia de estatus de llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''timeTotalInCallSec'', N''Duración total de la llamada, en segundos.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''timeTotalInCallMin'', N''Duración total de la llamada, en minutos redondeados hacia arriba.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''statusCallByIVR'', N''Estatus de la llamada determinado por IVR.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''IVR_ID'', N''Identificador del IVR asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''callHung'', N''Entidad que colgó la llamada en flujo IVR.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''recibeCallBy'', N''Medio por el que se recibió la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''cal_final'', N''Fecha y hora de finalización de la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''areaId'', N''Identificador del área asociada al inbound.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''area'', N''Nombre del área asociada al inbound.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''source'', N''Número origen de la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''destinationNumber'', N''Número destino DNIS de la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''cal_tWait'', N''Tiempo de espera en cola redondeado, en segundos.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''callbackDate'', N''Fecha y hora de callback asociada a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''ModelName'', N''Nombre del modelo o agente virtual asociado a la llamada.'';
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInCallsDetail'', N''CapturedData'', N''Datos capturados asociados a la llamada.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepInChangeFlow'',
    @Description = N''Reporte horario de cambios o transferencias de flujo inbound por día de la semana. Incluye inbound, hora del intervalo, etiqueta dinámica del día y conteo de llamadas transferidas o con flujo de transferencia.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInChangeFlow'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInChangeFlow'', N''time'',
    N''Hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInChangeFlow'', N''inboundId'',
    N''Identificador del inbound asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInChangeFlow'', N''inbound'',
    N''Nombre del inbound asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInChangeFlow'', N''weekday_count'',
    N''Nombre de métrica de conteo por día de la semana.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInChangeFlow'', N''count'',
    N''Conteo de llamadas inbound transferidas o con flujo de transferencia en el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInChangeFlow'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInChangeFlow'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInChangeFlow'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInChangeFlow'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInChangeFlow'', N''minutes'',
    N''Minuto'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepInDIDResume'',
    @Description = N''Resumen de llamadas inbound contestadas por DNIS e intervalo horario. Incluye DNIS, etiqueta dinámica de conteo y cantidad de llamadas contestadas.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDIDResume'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDIDResume'', N''dnisId'',
    N''Identificador del DNIS asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDIDResume'', N''dnis'',
    N''Descripción o número del DNIS asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDIDResume'', N''dnis_count'',
    N''Nombre de métrica de conteo del DNIS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDIDResume'', N''count'',
    N''Conteo de llamadas contestadas asociadas al DNIS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDIDResume'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDIDResume'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDIDResume'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDIDResume'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDIDResume'', N''minutes'',
    N''Minuto'';




/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepInDispositions'',
    @Description = N''Reporte de tipificaciones inbound por intervalo horario, inbound, agente, área y grupo de trabajo. Incluye llamadas inbound contestadas y chats asignados, agrupados por disposición.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''inboundId'',
    N''Identificador del inbound asociado a la llamada o chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''ACDGroup'',
    N''Nombre del grupo ACD o inbound asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''dispositionId'',
    N''Identificador de la tipificación registrada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''disposition'',
    N''Nombre técnico de la tipificación inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''disposition_count'',
    N''Nombre de métrica de conteo de la tipificación inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''count'',
    N''Conteo de registros con la tipificación en el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''userId'',
    N''Identificador del agente asociado a la llamada o chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''agentName'',
    N''Login del agente asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''user'',
    N''Nombre completo del agente asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''areaId'',
    N''Identificador del área asociada al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''area'',
    N''Nombre del área asociada al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''workgroupId'',
    N''Identificador del grupo de trabajo asociado al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''wg'',
    N''Nombre del grupo de trabajo asociado al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInDispositions'', N''minutes'',
    N''Minuto'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepInEffectiveness'',
    @Description = N''Reporte de efectividad inbound por intervalo horario e inbound. Incluye volumen de llamadas, contestadas, abandonadas, tiempos promedio de atención, cola y abandono, nivel de servicio, agentes asociados y porcentaje de abandono.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''inboundId'',
    N''Identificador del inbound evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''inbound'',
    N''Nombre del inbound evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''ntotalin'',
    N''Conteo total de llamadas inbound del intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''nanswer2'',
    N''Conteo de llamadas inbound contestadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''nabnd'',
    N''Conteo de llamadas inbound abandonadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''tatencion'',
    N''Tiempo promedio de atención por llamada contestada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''tqueavg'',
    N''Tiempo promedio en cola, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''tQuetot'',
    N''Tiempo total en cola, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''nQuetot'',
    N''Conteo total de llamadas que pasaron por cola.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''avgAbandonTime'',
    N''Tiempo promedio antes del abandono, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''SLP1'',
    N''Numerador del nivel de servicio inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''SLP2'',
    N''Denominador del nivel de servicio inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''tresp'',
    N''Tiempo total de respuesta de llamadas contestadas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''poscount'',
    N''Conteo de agentes asociados al inbound en el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''Porcentaje'',
    N''Porcentaje de nivel de servicio inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''avgAbandon'',
    N''Porcentaje de llamadas abandonadas respecto al total de llamadas inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInEffectiveness'', N''tabndtot'',
    N''Tiempo total acumulado antes del abandono, en segundos.'';



/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepInNotTransferred'',
    @Description = N''Reporte de llamadas inbound no transferidas o no atendidas por condiciones operativas. Incluye inbound, estatus de llamada, área, grupo de trabajo, llamada y teléfono origen.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''date'',
    N''Fecha y hora de inicio de la llamada inbound no transferida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''inboundId'',
    N''Identificador del inbound asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''ACDGroup'',
    N''Nombre del inbound o grupo ACD asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''callStatusId'',
    N''Identificador del estatus de la llamada no transferida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''callStatus'',
    N''Descripción del estatus de la llamada no transferida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''callStatus_Count'',
    N''Nombre de métrica de conteo del estatus de llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''count'',
    N''Conteo de llamadas con el estatus indicado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''areaId'',
    N''Identificador del área asociada al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''area'',
    N''Nombre del área asociada al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''workgroupId'',
    N''Identificador del grupo de trabajo asociado al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''wg'',
    N''Nombre del grupo de trabajo asociado al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''minutes'',
    N''Minuto'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''callIdIn'',
    N''Identificador de la llamada inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInNotTransferred'', N''phonein'',
    N''ANI o teléfono origen de la llamada inbound.'';



/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepInRejectedCalls'',
    @Description = N''Detalle de llamadas inbound rechazadas. Incluye DNIS, inbound, fecha de registro, ANI, puerto de ingreso y desglose de fecha.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInRejectedCalls'', N''dnisId'',
    N''Identificador del DNIS asociado a la llamada rechazada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInRejectedCalls'', N''dnisNumber'',
    N''Número DNIS marcado en la llamada rechazada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInRejectedCalls'', N''dnisDescription'',
    N''Descripción del DNIS asociado a la llamada rechazada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInRejectedCalls'', N''inboundId'',
    N''Identificador del inbound asociado a la llamada rechazada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInRejectedCalls'', N''inbound'',
    N''Nombre del inbound asociado a la llamada rechazada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInRejectedCalls'', N''date'',
    N''Fecha y hora de inicio o registro de la llamada rechazada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInRejectedCalls'', N''ANI'',
    N''ANI o número origen de la llamada rechazada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInRejectedCalls'', N''port'',
    N''Puerto por el que ingresó la llamada rechazada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInRejectedCalls'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInRejectedCalls'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInRejectedCalls'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInRejectedCalls'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInRejectedCalls'', N''minutes'',
    N''Minuto'';



/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepInSubDispositions'',
    @Description = N''Reporte de subtipificaciones inbound por intervalo horario, inbound, agente y área. Incluye llamadas inbound contestadas y chats asignados, agrupados por subtipificación.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''inboundId'',
    N''Identificador del inbound asociado a la llamada o chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''ACDGroup'',
    N''Nombre del inbound o grupo ACD asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''subDispositionId'',
    N''Identificador de la subtipificación registrada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''subDisposition'',
    N''Nombre técnico de la subtipificación inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''subDisposition_count'',
    N''Nombre de métrica de conteo de la subtipificación inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''count'',
    N''Conteo de registros con la subtipificación en el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''userId'',
    N''Identificador del agente asociado a la llamada o chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''agentName'',
    N''Nombre completo del agente asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''user'',
    N''Login del agente asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''areaId'',
    N''Identificador del área asociada al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''area'',
    N''Nombre del área asociada al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''workgroupId'',
    N''Identificador del grupo de trabajo asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''wg'',
    N''Nombre del grupo de trabajo asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInSubDispositions'', N''minutes'',
    N''Minuto'';



/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepInTrunkBusy'',
    @Description = N''Reporte de ocupación de troncales inbound por intervalo, inbound y puerto. Incluye tiempo ocupado de la troncal y cantidad de llamadas asociadas.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInTrunkBusy'', N''date'',
    N''Fecha y hora del intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInTrunkBusy'', N''inboundId'',
    N''Identificador del inbound asociado a la troncal ocupada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInTrunkBusy'', N''inbound'',
    N''Nombre del inbound asociado a la troncal ocupada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInTrunkBusy'', N''trunk'',
    N''Puerto o troncal utilizada por la llamada inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInTrunkBusy'', N''tBusy'',
    N''Tiempo total de ocupación de la troncal en llamadas inbound, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInTrunkBusy'', N''Calls'',
    N''Conteo de llamadas inbound asociadas a la troncal en el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInTrunkBusy'', N''year'',
    N''Año'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInTrunkBusy'', N''month'',
    N''Mes'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInTrunkBusy'', N''day'',
    N''Día'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInTrunkBusy'', N''hour'',
    N''Hora'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepInTrunkBusy'', N''minutes'',
    N''Minuto'';



/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepIVRByOptions'',
    @Description = N''Reporte de opciones seleccionadas en IVR por fecha y nivel de opción. Permite identificar cuántas llamadas siguieron una ruta o nivel específico dentro del flujo IVR.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRByOptions'', N''date'',
    N''Fecha del intervalo o día reportado para la agrupación de llamadas IVR.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRByOptions'', N''levelOption'',
    N''Nivel o ruta de opción IVR evaluada dentro del flujo, usada para identificar la secuencia de opciones seleccionadas por la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRByOptions'', N''descriptionOption'',
    N''Descripción funcional de la opción IVR asociada al nivel reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRByOptions'', N''quantityOption'',
    N''Conteo de llamadas IVR cuya secuencia de opciones seleccionadas coincide con el nivel de opción reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRByOptions'', N''year'',
    N''Año calendario correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRByOptions'', N''month'',
    N''Mes calendario correspondiente a la fecha reportada, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRByOptions'', N''day'',
    N''Día del mes correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRByOptions'', N''hour'',
    N''Hora del día correspondiente a la fecha reportada, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRByOptions'', N''minutes'',
    N''Minuto correspondiente a la fecha reportada, expresado en formato de 0 a 59.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepIVRDetail'',
    @Description = N''Reporte detallado de llamadas IVR. Incluye información de origen, usuario o agente asociado cuando la llamada fue transferida a ACD, calificación, opciones seleccionadas, duración en IVR, DNIS, nombre del IVR y estatus funcional de la llamada.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''date'',
    N''Fecha y hora asociada a la llamada IVR. Si la llamada fue transferida a ACD, corresponde al inicio de la llamada en ACD; en caso contrario, corresponde a la fecha registrada en IVR.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''telephone'',
    N''Número telefónico de origen de la llamada que ingresó al IVR.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''user'',
    N''Nombre completo del usuario o agente asociado a la llamada cuando esta fue transferida a ACD.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''disposition'',
    N''Descripción de la calificación o disposición asignada a la llamada cuando existe información de ACD.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''callid'',
    N''Identificador de la llamada en ACD asociada a la interacción IVR. Si la llamada no fue transferida a ACD, el valor registrado es 0.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''options'',
    N''Secuencia de opciones seleccionadas por el llamante durante su navegación en el IVR, concatenadas en orden cronológico y separadas por coma.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''statusTime'',
    N''Tiempo de permanencia o duración registrada de la llamada dentro del IVR, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''year'',
    N''Año calendario correspondiente a la fecha y hora de la llamada IVR.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''month'',
    N''Mes calendario correspondiente a la fecha y hora de la llamada IVR, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''day'',
    N''Día del mes correspondiente a la fecha y hora de la llamada IVR.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''hour'',
    N''Hora del día correspondiente a la fecha y hora de la llamada IVR, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''minutes'',
    N''Minuto correspondiente a la fecha y hora de la llamada IVR, expresado en formato de 0 a 59.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''dnis'',
    N''Número DNIS marcado o destino de entrada por el que ingresó la llamada al IVR.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''ivrName'',
    N''Nombre del IVR asociado a la llamada. Cuando no existe nombre registrado, se utiliza el texto traducible de sistema para indicar que no tiene nombre.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''callStatus'',
    N''Estatus funcional de la llamada IVR, indicando si fue transferida a ACD o si fue abandonada dentro del IVR.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRDetail'', N''IVR_ID'',
    N''Identificador único de la interacción o llamada registrada en IVR.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepIVRFirstOption'',
    @Description = N''Reporte de primeras opciones seleccionadas en IVR por fecha. Permite identificar cuántas llamadas iniciaron su navegación en el IVR con cada opción disponible.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRFirstOption'', N''date'',
    N''Fecha del día reportado para la primera opción seleccionada en el IVR.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRFirstOption'', N''descriptionOption'',
    N''Primera opción seleccionada por el llamante dentro del flujo IVR.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRFirstOption'', N''option_Count'',
    N''Etiqueta técnica generada a partir de la primera opción seleccionada, utilizada para identificar el contador asociado a esa opción.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRFirstOption'', N''Count'',
    N''Conteo de llamadas IVR cuya primera opción seleccionada corresponde a la opción reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRFirstOption'', N''year'',
    N''Año calendario correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRFirstOption'', N''month'',
    N''Mes calendario correspondiente a la fecha reportada, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRFirstOption'', N''day'',
    N''Día del mes correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRFirstOption'', N''hour'',
    N''Hora correspondiente a la fecha reportada, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRFirstOption'', N''minutes'',
    N''Minuto correspondiente a la fecha reportada, expresado en formato de 0 a 59.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepIVRGeneral'',
    @Description = N''Reporte general diario de llamadas IVR. Resume el total de llamadas que ingresaron al IVR, separando las que fueron transferidas a ACD y las que no fueron transferidas.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRGeneral'', N''date'',
    N''Fecha del día reportado para el resumen general de llamadas IVR.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRGeneral'', N''noTransferred'',
    N''Conteo de llamadas que ingresaron al IVR y no fueron transferidas a ACD.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRGeneral'', N''transferred'',
    N''Conteo de llamadas que ingresaron al IVR y fueron transferidas a ACD.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRGeneral'', N''total'',
    N''Conteo total de llamadas que ingresaron al IVR en la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRGeneral'', N''year'',
    N''Año calendario correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRGeneral'', N''month'',
    N''Mes calendario correspondiente a la fecha reportada, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRGeneral'', N''day'',
    N''Día del mes correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRGeneral'', N''hour'',
    N''Hora del intervalo reportado para el resumen general de IVR. El valor registrado es 0 porque el reporte se genera a nivel diario.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRGeneral'', N''minutes'',
    N''Minuto del intervalo reportado para el resumen general de IVR. El valor registrado es 0 porque el reporte se genera a nivel diario.'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepIVRSurveys'',
    @Description = N''Reporte detallado de encuestas IVR asociadas a llamadas inbound, outbound y registros de marcación. Incluye información de agente, encuesta, pregunta, respuesta, campaña o inbound de origen, fecha del registro y teléfono del cliente.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''date'',
    N''Fecha y hora en que se registró la llamada asociada a la encuesta IVR.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''userId'',
    N''Identificador del usuario o agente asociado a la llamada de encuesta.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''login'',
    N''Login del usuario o agente asociado a la llamada de encuesta.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''scriptId'',
    N''Identificador del IVR o script donde se capturó la respuesta de la encuesta.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''surveyId'',
    N''Identificador de la encuesta asociada al IVR.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''survey'',
    N''Nombre o descripción de la encuesta asociada al IVR.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''calId'',
    N''Identificador de la llamada asociada al registro de encuesta.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''calKey'',
    N''Clave operativa de la llamada asociada al registro de encuesta.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''campaignId'',
    N''Identificador de la campaña asociada a la encuesta cuando el origen es outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''inboundId'',
    N''Identificador del inbound asociado a la encuesta cuando el origen es ACD inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''campACDDescription'',
    N''Descripción del origen operativo de la encuesta, indicando si proviene de ACD inbound o de campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''questionId'',
    N''Identificador de la pregunta de encuesta asociada al registro.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''questionDescription'',
    N''Descripción de la pregunta de encuesta presentada al cliente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''question_Count'',
    N''Etiqueta técnica generada a partir de la pregunta de encuesta para identificar el contador asociado a esa pregunta.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''Count'',
    N''Respuesta registrada para la pregunta de encuesta, mostrando la descripción de la respuesta cuando existe en catálo o el valor seleccionado cuando no tiene equivalencia configurada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''year'',
    N''Año calendario correspondiente a la fecha y hora del registro de encuesta.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''month'',
    N''Mes calendario correspondiente a la fecha y hora del registro de encuesta, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''day'',
    N''Día del mes correspondiente a la fecha y hora del registro de encuesta.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''hour'',
    N''Hora del día correspondiente a la fecha y hora del registro de encuesta, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''minutes'',
    N''Minuto correspondiente a la fecha y hora del registro de encuesta, expresado en formato de 0 a 59.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepIVRSurveys'', N''clientPhoneNumber'',
    N''Número telefónico del cliente asociado a la llamada de encuesta.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepMKTAgentes'',
    @Description = N''Reporte de productividad de agentes para campañas MKT por intervalo. Incluye llamadas ACD atendidas, tiempos de conversación, atención, estados del agente, transferencias, ayuda y trabajo posterior a la llamada.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''date'',
    N''Fecha y hora del intervalo reportado para la actividad del agente en campañas MKT.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''userId'',
    N''Identificador del usuario o agente asociado al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''login'',
    N''Login del agente asociado al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''agentName'',
    N''Nombre completo del agente asociado al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''CallsperACDGroupD'',
    N''Conteo de llamadas ACD atendidas por el agente en el intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''tACD'',
    N''Tiempo total de conversación ACD del agente en el intervalo reportado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''tAgent'',
    N''Tiempo total de atención del agente asociado a llamadas ACD, considerando espera, transferencia y timbrado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''oHour'',
    N''Tiempo total registrado en otros estados del agente durante el intervalo reportado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''tAux'',
    N''Tiempo total del agente en estado auxiliar durante el intervalo reportado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''readyTime'',
    N''Tiempo total del agente en estado disponible durante el intervalo reportado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''tPer'',
    N''Tiempo total registrado del agente en estados operativos durante el intervalo reportado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''Ayuda'',
    N''Tiempo total asociado a eventos de ayuda o transferencia asistida del agente en el intervalo reportado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''nxfer'',
    N''Tiempo total asociado a transferencias salientes del agente en el intervalo reportado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''nacw'',
    N''Conteo de llamadas ACD que registraron tiempo de trabajo posterior a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''tACW'',
    N''Tiempo total de trabajo posterior a la llamada del agente en el intervalo reportado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''year'',
    N''Año calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''month'',
    N''Mes calendario correspondiente al intervalo reportado, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''day'',
    N''Día del mes correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''hour'',
    N''Hora del día correspondiente al intervalo reportado, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''minutes'',
    N''Minuto correspondiente al intervalo reportado, expresado en formato de 0 a 59.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''TiempoPromACD'',
    N''Tiempo promedio de conversación ACD por llamada atendida por el agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTAgentes'', N''TiempoPromACW'',
    N''Tiempo promedio de trabajo posterior a la llamada por llamada con ACW registrada, en segundos.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepMKTDiarioTiemposTotales'',
    @Description = N''Reporte diario de tiempos totales y promedios de atención para campañas MKT. Incluye métricas por agente e inbound, como tiempo promedio ACD, ACW, retención, timbrado, AHT y llamadas atendidas.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''date'',
    N''Fecha del día reportado para los tiempos diarios de atención en campañas MKT.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''OpaId'',
    N''Login del operador o agente asociado a las llamadas atendidas en el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''NombreDeOperadora'',
    N''Nombre completo del operador o agente asociado a las llamadas atendidas en el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''InboundId'',
    N''Identificador del inbound asociado a las llamadas atendidas por el agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''tPromACD'',
    N''Tiempo promedio de conversación ACD por llamada atendida, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''tPromACW'',
    N''Tiempo promedio de trabajo posterior a la llamada por llamada con ACW registrado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''TiempoPromReten'',
    N''Tiempo promedio en retención o espera durante llamadas atendidas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''TiempoPromRing'',
    N''Tiempo promedio de timbrado en llamadas atendidas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''AHT'',
    N''Tiempo promedio total de manejo de llamadas atendidas, considerando conversación ACD, ACW, timbrado y retención, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''LlamadasAtendidas'',
    N''Conteo de llamadas atendidas por el agente en el inbound y día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''year'',
    N''Año calendario correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''month'',
    N''Mes calendario correspondiente a la fecha reportada, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''day'',
    N''Día del mes correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''hour'',
    N''Hora correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTDiarioTiemposTotales'', N''minutes'',
    N''Minuto correspondiente a la fecha reportada.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepMKTIntervalos'',
    @Description = N''Reporte de métricas MKT por intervalo, inbound y agente. Incluye llamadas atendidas y abandonadas, tiempos promedio, flujos de transferencia, salidas externas, eliminación de cola, ocupación ACD, personal promedio y tiempos acumulados operativos.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''date'',
    N''Fecha y hora del intervalo reportado para métricas MKT por inbound y agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''inboundId'',
    N''Identificador del inbound asociado a las métricas del intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''Acds'',
    N''Descripción del inbound o ACD asociado al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''avrAnswer'',
    N''Tiempo promedio de respuesta para llamadas ACD atendidas en el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''avgAbandonTime'',
    N''Tiempo promedio de abandono de llamadas no atendidas en el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''acdCalls'',
    N''Conteo de llamadas ACD atendidas en el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''tPromACD'',
    N''Tiempo promedio de conversación ACD por llamada atendida en el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''tPromACW'',
    N''Tiempo promedio de trabajo posterior a la llamada por llamada con ACW registrado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''abandonedCalls'',
    N''Conteo de llamadas abandonadas en el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''maxDelay'',
    N''Tiempo total de demora acumulado en llamadas atendidas durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''entryFlow'',
    N''Conteo de eventos de entrada por transferencia al inbound durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''outFlow'',
    N''Conteo de eventos de salida por transferencia desde el inbound durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''callsOutExt'',
    N''Conteo de llamadas o eventos de transferencia saliente externa durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''tPromSalidaExt'',
    N''Tiempo promedio asociado a salidas externas durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''callsDeleteQue'',
    N''Conteo de llamadas eliminadas de cola durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''tPromElimCola'',
    N''Tiempo promedio en cola para llamadas eliminadas de cola durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''avrTimeACD'',
    N''Porcentaje de ocupación de tiempo ACD respecto al tiempo de sesión disponible en el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''avrCallsAnswer'',
    N''Porcentaje de llamadas atendidas respecto al total de llamadas atendidas y abandonadas en el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''PromPosicionPersonal'',
    N''Promedio de posiciones de personal disponibles durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''LlamadasporPosicion'',
    N''Promedio de llamadas atendidas por posición de agente durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''tresp'',
    N''Tiempo total de respuesta acumulado en llamadas ACD durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''tabnd'',
    N''Tiempo total acumulado de abandono en llamadas no atendidas durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''tacd'',
    N''Tiempo total de conversación ACD acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''tacw'',
    N''Tiempo total de trabajo posterior a la llamada acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''nacw'',
    N''Conteo de llamadas ACD con trabajo posterior a la llamada registrado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''tcalque'',
    N''Tiempo total en cola de llamadas eliminadas de cola durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''tprosalext'',
    N''Tiempo total asociado a salidas externas durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''tlog'',
    N''Tiempo total de sesión o logueo del agente durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''accountUserId'',
    N''Identificador del agente o usuario asociado a las métricas del intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''year'',
    N''Año calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''month'',
    N''Mes calendario correspondiente al intervalo reportado, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''day'',
    N''Día del mes correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''hour'',
    N''Hora del día correspondiente al intervalo reportado, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalos'', N''minutes'',
    N''Minuto correspondiente al intervalo reportado, expresado en formato de 0 a 59.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepMKTIntervalosSalida'',
    @Description = N''Reporte de métricas de salida para campañas MKT por intervalo. Incluye resultados de marcación, llamadas contactadas y contestadas, abandonos, disponibilidad de agentes, tiempos operativos, ocupación y campaña asociada.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''date'',
    N''Fecha y hora del intervalo reportado para métricas de salida en campañas MKT.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''ran1'',
    N''Hora inicial del ran o intervalo evaluado en el reporte de salida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''ran2'',
    N''Hora final del ran o intervalo evaluado en el reporte de salida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''Staff'',
    N''Cantidad de agentes o posiciones consideradas para el intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''Realizadas'',
    N''Conteo de llamadas de salida realizadas durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''Ocupado'',
    N''Conteo de llamadas de salida con resultado ocupado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''NoContestan'',
    N''Conteo de llamadas de salida en las que el cliente no contestó.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''Fax'',
    N''Conteo de llamadas de salida detectadas como fax.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''Buzon'',
    N''Conteo de llamadas de salida que terminaron en buzón de voz.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''SinTono'',
    N''Conteo de llamadas de salida sin tono detectado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''nout_service'',
    N''Conteo de llamadas de salida con resultado de fuera de servicio.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''Other'',
    N''Conteo de llamadas de salida con resultado distinto a las caterías principales del reporte.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''Congestion'',
    N''Conteo de llamadas de salida con resultado de congestión.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''Cancelado'',
    N''Conteo de llamadas de salida canceladas durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''contacted'',
    N''Conteo de llamadas de salida contactadas durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''Answered'',
    N''Conteo de llamadas de salida contestadas durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''abandonedCalls'',
    N''Conteo de llamadas de salida abandonadas durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''SinAgentes'',
    N''Conteo de llamadas de salida sin agentes disponibles para atención.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''NoContestadas'',
    N''Conteo de llamadas de salida no contestadas durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''nabndxferout'',
    N''Conteo de llamadas de salida abandonadas durante transferencia.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''nabndrinut'',
    N''Conteo de llamadas de salida abandonadas durante timbrado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''nabnddlut'',
    N''Conteo de llamadas de salida abandonadas durante diálo o atención.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''TMO'',
    N''Tiempo medio operativo de llamadas de salida durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''promDialo'',
    N''Tiempo promedio de diálo en llamadas de salida durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''holdTime'',
    N''Tiempo de retención en llamadas de salida durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''tnotesout'',
    N''Tiempo de trabajo posterior a la llamada de salida durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''trinut'',
    N''Tiempo de timbrado acumulado en llamadas de salida durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''readyTime'',
    N''Tiempo total en estado disponible de los agentes durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''notReadyTime'',
    N''Tiempo total en estado no disponible de los agentes durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''Personal'',
    N''Cantidad o promedio de personal considerado en el intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''avrAnswer'',
    N''Tiempo promedio de respuesta en llamadas de salida contestadas, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''Reductor'',
    N''Factor reductor aplicado al cálculo operativo del intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''AvgAbandon'',
    N''Tiempo o porcentaje promedio de abandono en llamadas de salida durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''OcupacionCOPC'',
    N''Porcentaje de ocupación operativa calculado bajo criterio COPC para el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosSalida'', N''Cam_id'',
    N''Identificador de la campaña asociada a las métricas de salida del intervalo.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepMKTIntervalosTiemposAcuTotales'',
    @Description = N''Reporte acumulado de tiempos totales MKT por intervalo e inbound. Incluye llamadas recibidas, atendidas y abandonadas, tiempos operativos de atención y estados del agente, nivel de servicio, AHT, retención, timbrado, salidas externas y personal promedio.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''date'',
    N''Fecha y hora del intervalo reportado para el acumulado de tiempos totales MKT por inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''inboundId'',
    N''Identificador del inbound asociado al acumulado de tiempos y llamadas del intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''descripcion'',
    N''Descripción del inbound asociado al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''PromPosicionPersonal'',
    N''Promedio de posiciones de personal disponibles durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''LlamadasRecibidas'',
    N''Conteo total de llamadas recibidas en el inbound durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''LlamadasAtendidas'',
    N''Conteo de llamadas atendidas en el inbound durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''LlamadasAban'',
    N''Conteo de llamadas abandonadas en el inbound durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''tACD'',
    N''Tiempo total de conversación ACD acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''tACW'',
    N''Tiempo total de trabajo posterior a la llamada acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''tLout'',
    N''Tiempo total en estado lout durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''tDescon'',
    N''Tiempo total en estado desconocido o sin clasificación durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''tnotav'',
    N''Tiempo total en estado no disponible durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''TiempoDispo'',
    N''Tiempo total en estado disponible durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''txfer'',
    N''Tiempo total de transferencia acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''tother'',
    N''Tiempo total en otros estados operativos durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''tCliente'',
    N''Tiempo total en estado cliente durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''tring'',
    N''Tiempo total de timbrado acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''tprob'',
    N''Tiempo total en estados de problema durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''tManual'',
    N''Tiempo total en llamada manual durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''timeretention'',
    N''Tiempo total de retención acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''LlamadasSalidaExt'',
    N''Conteo de llamadas o eventos de salida externa durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''TiempoSalidaExt'',
    N''Tiempo total asociado a salidas externas durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''PorcNiveldeServicio4080'',
    N''Porcentaje de nivel de servicio 40/80 para llamadas recibidas en el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''AHT'',
    N''Tiempo promedio total de manejo de llamadas, considerando conversación ACD, ACW, timbrado y retención, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''LlamadasRetenidas'',
    N''Conteo de llamadas con retención registrada durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''LlamadasenRing'',
    N''Conteo de llamadas con tiempo de timbrado registrado durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''year'',
    N''Año calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''month'',
    N''Mes calendario correspondiente al intervalo reportado, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''day'',
    N''Día del mes correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''hour'',
    N''Hora del día correspondiente al intervalo reportado, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''minutes'',
    N''Minuto correspondiente al intervalo reportado, expresado en formato de 0 a 59.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''nserv'',
    N''Conteo de llamadas consideradas dentro del nivel de servicio 40/80 durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''nacw'',
    N''Conteo de llamadas con trabajo posterior a la llamada registrado durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTIntervalosTiemposAcuTotales'', N''tAuxiliar'',
    N''Tiempo total en estado auxiliar durante el intervalo, en segundos.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepMKTTiemposTotales'',
    @Description = N''Reporte de tiempos totales MKT por intervalo, inbound y agente. Incluye llamadas recibidas, atendidas y abandonadas, tiempos promedio de conversación, ACW, retención, disponibilidad, ring, salidas externas, AHT, tiempos acumulados y métricas de estado auxiliar.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''date'',
    N''Fecha y hora del intervalo reportado para los tiempos totales MKT por inbound y agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''inboundId'',
    N''Identificador del inbound asociado a las métricas de tiempos totales del intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''Acds'',
    N''Descripción del inbound o ACD asociado al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''PromPosicionPersonal'',
    N''Promedio de posiciones de personal disponibles durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''receivedCalls'',
    N''Conteo total de llamadas recibidas en el inbound durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''acdCalls'',
    N''Conteo de llamadas atendidas en ACD durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''abandonedCalls'',
    N''Conteo de llamadas abandonadas durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''tPromACD'',
    N''Tiempo promedio de conversación ACD por llamada atendida durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''tPromACW'',
    N''Tiempo promedio de trabajo posterior a la llamada por llamada con ACW registrado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''tPromRetention'',
    N''Tiempo promedio de retención por llamada retenida durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''callsOutExt'',
    N''Conteo de llamadas o eventos de salida externa durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''tPromSalidaExt'',
    N''Tiempo promedio asociado a salidas externas durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''TPromDispon'',
    N''Tiempo promedio en estado disponible durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''TPromRing'',
    N''Tiempo promedio de timbrado por llamada con ring durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''AHT'',
    N''Tiempo promedio total de manejo de llamadas, considerando conversación ACD, ACW, timbrado y retención, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''tacd'',
    N''Tiempo total de conversación ACD acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''tacw'',
    N''Tiempo total de trabajo posterior a la llamada acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''nacw'',
    N''Conteo de llamadas con trabajo posterior a la llamada registrado durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''tprosalext'',
    N''Tiempo total asociado a salidas externas durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''tlog'',
    N''Tiempo total de sesión o logueo del agente durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''thold'',
    N''Tiempo total de retención acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''nhold'',
    N''Conteo de llamadas con retención registrada durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''tdispo'',
    N''Tiempo total en estado disponible durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''ndispo'',
    N''Conteo de registros o fracciones de estado disponible durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''tring'',
    N''Tiempo total de timbrado acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''nring'',
    N''Conteo de llamadas con tiempo de timbrado registrado durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''accountUserId'',
    N''Identificador del agente o usuario asociado a las métricas del intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''year'',
    N''Año calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''month'',
    N''Mes calendario correspondiente al intervalo reportado, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''day'',
    N''Día del mes correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''hour'',
    N''Hora del día correspondiente al intervalo reportado, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''minutes'',
    N''Minuto correspondiente al intervalo reportado, expresado en formato de 0 a 59.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''TPromAuxiliar'',
    N''Tiempo promedio en estado auxiliar durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''tauxiliarRdy'',
    N''Tiempo total en estado auxiliar durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepMKTTiemposTotales'', N''nauxiliar'',
    N''Conteo de registros o eventos en estado auxiliar durante el intervalo.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutAnswAndXferCalls'',
    @Description = N''Reporte de llamadas de salida contestadas y transferidas. Incluye campaña o inbound asociado, agente, teléfono marcado, tipo de marcación, tipo de llamada, tiempos de diálo y marcación, costos, IVA, total, troncal y ANI utilizado.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''date'',
    N''Fecha y hora de inicio de la llamada contestada o transferida de salida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''callid'',
    N''Identificador de la llamada asociada al registro de salida contestada o transferida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''campaignId'',
    N''Identificador de la campaña o inbound asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''campaign'',
    N''Nombre de la campaña o inbound asociado a la llamada contestada o transferida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''userId'',
    N''Identificador del agente asociado a la llamada contestada o transferida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''Agent'',
    N''Nombre completo del agente asociado a la llamada contestada o transferida.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''dialog'',
    N''Tiempo de diálo efectivo de la llamada contestada o transferida, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''telephone'',
    N''Número telefónico o destino marcado en la llamada de salida o transferencia.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''dialId'',
    N''Identificador del tipo de marcación asociado a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''dialType'',
    N''Descripción del tipo de marcación o transferencia realizada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''CallTypes'',
    N''Descripción del tipo de llamada utilizado para clasificar la llamada y su costo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''ncost'',
    N''Costo neto calculado de la llamada antes de IVA.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''iva'',
    N''Porcentaje de IVA aplicado al costo de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''total'',
    N''Costo total de la llamada incluyendo IVA.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''trunk'',
    N''Puerto, canal o troncal utilizado para realizar la llamada o transferencia.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''ANI'',
    N''Número ANI utilizado como identificador de salida de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswAndXferCalls'', N''dialTimeSec'',
    N''Tiempo total asociado a la marcación o transferencia de la llamada, en segundos.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutAnswCalls'',
    @Description = N''Reporte diario de llamadas outbound por campaña, grupo de trabajo y área. Incluye total de llamadas y porcentajes por estatus operativo como asignadas, contestadas y abandonadas por sistema.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswCalls'', N''date'',
    N''Fecha del día reportado para el resumen de llamadas outbound por campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswCalls'', N''campaignId'',
    N''Identificador de la campaña outbound asociada al resumen de llamadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswCalls'', N''campaign'',
    N''Nombre o descripción de la campaña outbound asociada al resumen de llamadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswCalls'', N''workgroupId'',
    N''Identificador del grupo de trabajo asociado a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswCalls'', N''workgroup'',
    N''Nombre del grupo de trabajo asociado a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswCalls'', N''areaId'',
    N''Identificador del área asociada al grupo de trabajo de la campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswCalls'', N''area'',
    N''Nombre del área asociada al grupo de trabajo de la campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswCalls'', N''total'',
    N''Conteo total de llamadas outbound registradas para la campaña en la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswCalls'', N''asigTl'',
    N''Porcentaje de llamadas outbound con estatus asignada a TL respecto al total de llamadas de la campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswCalls'', N''asigNc'',
    N''Porcentaje de llamadas outbound con estatus asignada NC respecto al total de llamadas de la campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswCalls'', N''Answered'',
    N''Porcentaje de llamadas outbound contestadas respecto al total de llamadas de la campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswCalls'', N''assigned'',
    N''Porcentaje de llamadas outbound asignadas respecto al total de llamadas de la campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutAnswCalls'', N''abdnSis'',
    N''Porcentaje de llamadas outbound abandonadas por sistema respecto al total de llamadas de la campaña.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutboundKPI'',
    @Description = N''Reporte diario de indicadores KPI outbound. Incluye registros únicos trabajados, intentos de marcación, marcaciones completas, llamadas contestadas y conectadas, abandonos, RPC, PTP, PK y quejas.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''date'',
    N''Fecha del día reportado para los indicadores KPI outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''UniqueRecordCalls'',
    N''Conteo de registros únicos contactados o marcados durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''DialsAttempted'',
    N''Conteo total de intentos de marcación outbound realizados durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''DialsCompleteRing'',
    N''Conteo de intentos de marcación que completaron el ciclo de timbrado o resultado final de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''nanswer2'',
    N''Conteo de intentos de marcación contestados durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''ConnectedCalls'',
    N''Conteo de llamadas outbound conectadas con agente y tiempo de diálo mayor a cero.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''abandonedCalls'',
    N''Conteo de llamadas outbound abandonadas durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''RPC'',
    N''Conteo de contactos efectivos RPC registrados en llamadas outbound durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''PTP'',
    N''Conteo de compromisos de pa registrados en llamadas outbound durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''PK'',
    N''Conteo de gestiones clasificadas como PK durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''Quejas'',
    N''Conteo de quejas registradas en llamadas inbound u outbound durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''Year'',
    N''Año calendario correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''month'',
    N''Mes calendario correspondiente a la fecha reportada, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''day'',
    N''Día del mes correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''hour'',
    N''Hora correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutboundKPI'', N''minutes'',
    N''Minuto correspondiente a la fecha reportada.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutCallBacks'',
    @Description = N''Reporte de callbacks outbound programados por campaña y agente. Incluye teléfono original, teléfono programado, fecha original, fecha programada, estado del callback y fecha de marcación.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''date'',
    N''Fecha y hora en que se registró originalmente el callback outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''userId'',
    N''Identificador del agente o usuario asociado al callback outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''user'',
    N''Login del agente o usuario asociado al callback outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''campaignId'',
    N''Identificador de la campaña outbound asociada al callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''campaign'',
    N''Nombre o descripción de la campaña outbound asociada al callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''callKey'',
    N''Clave operativa de la llamada o registro asociado al callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''originalTel'',
    N''Número telefónico original asociado al registro de callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''scheduledTel'',
    N''Número telefónico programado para realizar el callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''originalDate'',
    N''Fecha y hora original en que se generó el registro de callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''scheduledDate'',
    N''Fecha y hora programada por el usuario para realizar el callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''status'',
    N''Estado funcional del callback, como pendiente, contestado, no contestado, reciclado, expirado, registro antiguo o registro cargado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''dialDate'',
    N''Fecha y hora en que se realizó o intentó la marcación del callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''year'',
    N''Año calendario correspondiente a la fecha original del callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''month'',
    N''Mes calendario correspondiente a la fecha original del callback, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''day'',
    N''Día del mes correspondiente a la fecha original del callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''hour'',
    N''Hora del día correspondiente a la fecha original del callback, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBacks'', N''minutes'',
    N''Minuto correspondiente a la fecha original del callback, expresado en formato de 0 a 59.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutCallBilling'',
    @Description = N''Reporte de facturación de llamadas outbound y transferidas. Incluye campaña o ACD de origen, agente, proveedor, tipo de llamada, llamadas, minutos facturados, costos, impuestos, inbound asociado y tipo de marcación.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''date'',
    N''Fecha y hora del intervalo reportado para la facturación de llamadas outbound o transferidas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''campaignId'',
    N''Identificador de la campaña asociada a la llamada facturada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''campACDDescription'',
    N''Descripción del origen facturado, indicando campaña outbound o ACD inbound asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''userId'',
    N''Identificador del agente asociado a la llamada facturada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''agentName'',
    N''Nombre completo del agente asociado a la llamada facturada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''user'',
    N''Login del agente asociado a la llamada facturada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''providerId'',
    N''Identificador del proveedor o carrier utilizado para la llamada facturada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''provider'',
    N''Nombre o descripción del proveedor o carrier utilizado para la llamada facturada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''tipoLlamadaId'',
    N''Identificador del tipo de llamada utilizado para clasificar la facturación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''tipoLlamada_count'',
    N''Etiqueta técnica traducible que identifica la métrica facturada para el tipo de llamada, como llamadas, minutos, costo o impuesto.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''count'',
    N''Valor de la métrica facturada para el tipo de llamada, según corresponda a cantidad de llamadas, minutos facturados, costo o impuesto.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''tipoLlamada'',
    N''Descripción del tipo de llamada asociado a la facturación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''costo'',
    N''Costo neto calculado cuando la métrica corresponde a costo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''year'',
    N''Año calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''month'',
    N''Mes calendario correspondiente al intervalo reportado, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''day'',
    N''Día del mes correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''hour'',
    N''Hora del día correspondiente al intervalo reportado, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''minutes'',
    N''Minuto correspondiente al intervalo reportado, expresado en formato de 0 a 59.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''inboundId'',
    N''Identificador del inbound asociado cuando la llamada facturada proviene de ACD o transferencia inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''dialId'',
    N''Identificador del origen de marcación o tipo operativo de la llamada facturada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallBilling'', N''dialType'',
    N''Descripción del origen de marcación o tipo operativo de la llamada facturada.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutCallsByTelephone'',
    @Description = N''Reporte diario de llamadas outbound agrupadas por teléfono, clave de llamada y campaña. Permite identificar cuántas marcaciones se realizaron a cada número telefónico dentro de una campaña.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsByTelephone'', N''date'',
    N''Fecha del día reportado para el conteo de llamadas outbound por teléfono.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsByTelephone'', N''telephone'',
    N''Número telefónico marcado en llamadas outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsByTelephone'', N''callKey'',
    N''Clave operativa de la llamada o registro outbound asociado al teléfono marcado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsByTelephone'', N''campaignId'',
    N''Identificador de la campaña outbound asociada al teléfono marcado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsByTelephone'', N''campaign'',
    N''Nombre o descripción de la campaña outbound asociada al teléfono marcado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsByTelephone'', N''quantity'',
    N''Conteo de llamadas outbound realizadas al mismo teléfono dentro de la campaña y fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsByTelephone'', N''year'',
    N''Año calendario correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsByTelephone'', N''month'',
    N''Mes calendario correspondiente a la fecha reportada, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsByTelephone'', N''day'',
    N''Día del mes correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsByTelephone'', N''hour'',
    N''Hora correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsByTelephone'', N''minutes'',
    N''Minuto correspondiente a la fecha reportada.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutCallsDetail'',
    @Description = N''Reporte detallado de llamadas outbound. Incluye información de campaña, agente, teléfono, disposición, subdisposición, resultado de marcación, tiempos operativos, costos, proveedor, tipo de llamada, modalidad de marcación, datos adicionales, grabación, área, callback y estado de llamada.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''date'',
    N''Fecha y hora de inicio de la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''callKey'',
    N''Clave operativa de la llamada o registro outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''telephone'',
    N''Número telefónico marcado en la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''transfer'',
    N''Tiempo total asociado a transferencia y timbrado de la llamada outbound, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''dialog'',
    N''Tiempo de conversación de la llamada outbound, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''nque'',
    N''Tiempo de retención o espera registrado en la llamada outbound, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''wrapup'',
    N''Tiempo de trabajo posterior a la llamada outbound, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''CallDisposition'',
    N''Descripción de la calificación o disposición asignada a la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''extension'',
    N''Extensión asociada al agente o llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''userId'',
    N''Identificador del agente asociado a la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''login'',
    N''Nombre completo del agente asociado a la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''username'',
    N''Login del agente asociado a la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''campaignId'',
    N''Identificador de la campaña outbound asociada a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''campaign'',
    N''Nombre o descripción de la campaña outbound asociada a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''duration'',
    N''Duración facturable de la llamada outbound redondeada a minutos completos y expresada en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''ncost'',
    N''Costo neto calculado de la llamada outbound antes de IVA.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''iva'',
    N''Porcentaje de IVA aplicado al costo de la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''total'',
    N''Costo total de la llamada outbound incluyendo IVA.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''ByCarrier'',
    N''Nombre o descripción del proveedor o carrier utilizado en la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''Calltypes'',
    N''Clasificación del tipo de llamada outbound, como fijo, celular o indefinido.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''dialType'',
    N''Tipo de marcación utilizado para la llamada outbound, como preview, asistida, callback, automática, manual o integración.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''whoHangUp'',
    N''Parte que finalizó la llamada outbound, como cliente, agente o encuesta de agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''subDisposition'',
    N''Subdisposición o subcalificación asignada a la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''dialResult'',
    N''Resultado de estado de la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''calId'',
    N''Identificador único de la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''year'',
    N''Año calendario correspondiente a la fecha de inicio de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''month'',
    N''Mes calendario correspondiente a la fecha de inicio de la llamada, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''day'',
    N''Día del mes correspondiente a la fecha de inicio de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''hour'',
    N''Hora del día correspondiente a la fecha de inicio de la llamada, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''minutes'',
    N''Minuto correspondiente a la fecha de inicio de la llamada, expresado en formato de 0 a 59.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''trunk'',
    N''Puerto o troncal utilizado para realizar la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''data1'',
    N''Dato adicional 1 asociado al registro outbound o a la fuente de datos de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''data2'',
    N''Dato adicional 2 asociado al registro outbound o a la fuente de datos de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''data3'',
    N''Dato adicional 3 asociado al registro outbound o a la fuente de datos de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''data4'',
    N''Dato adicional 4 asociado al registro outbound o a la fuente de datos de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''data5'',
    N''Dato adicional 5 asociado al registro outbound o a la fuente de datos de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''MessageTime'',
    N''Tiempo de mensaje asociado a la llamada outbound, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''grabId'',
    N''Identificador de la grabación asociada a la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''areaId'',
    N''Identificador del área asociada a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''area'',
    N''Nombre del área asociada a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''originNumber'',
    N''Número ANI u origen utilizado para la marcación outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''callbackDate'',
    N''Fecha y hora de callback asociada a la llamada outbound, cuando aplica.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''queueTimes'',
    N''Tiempo de cola asociado a la llamada outbound, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''ringingTime'',
    N''Tiempo total de timbrado o marcación previo a la atención de la llamada outbound, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsDetail'', N''callStatusId'',
    N''Identificador del estado operativo de la llamada outbound.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutCallsOnChatDetail'',
    @Description = N''Reporte detallado de llamadas outbound realizadas desde chat. Incluye información de campaña, agente, teléfono, disposición, subdisposición, resultado de llamada, tiempos operativos, costos, proveedor, tipo de llamada, modalidad de marcación, troncal y fecha de inicio.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''date'',
    N''Fecha y hora de inicio de la llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''callKey'',
    N''Clave operativa de la llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''telephone'',
    N''Número telefónico marcado en la llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''transfer'',
    N''Tiempo total asociado a transferencia y timbrado de la llamada outbound realizada desde chat, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''dialog'',
    N''Tiempo de conversación de la llamada outbound realizada desde chat, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''nque'',
    N''Tiempo de retención o espera registrado en la llamada outbound realizada desde chat, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''wrapup'',
    N''Tiempo de trabajo posterior a la llamada outbound realizada desde chat, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''CallDisposition'',
    N''Descripción de la calificación o disposición asignada a la llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''extension'',
    N''Extensión asociada al agente o llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''userId'',
    N''Identificador del agente asociado a la llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''login'',
    N''Login del agente asociado a la llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''username'',
    N''Nombre completo del agente asociado a la llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''campaignId'',
    N''Identificador de la campaña outbound asociada a la llamada realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''campaign'',
    N''Nombre o descripción de la campaña outbound asociada a la llamada realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''duration'',
    N''Duración facturable de la llamada outbound realizada desde chat, redondeada a minutos completos y expresada en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''ncost'',
    N''Costo neto calculado de la llamada outbound realizada desde chat antes de IVA.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''iva'',
    N''Porcentaje de IVA aplicado al costo de la llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''total'',
    N''Costo total de la llamada outbound realizada desde chat incluyendo IVA.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''ByCarrier'',
    N''Nombre o descripción del proveedor o carrier utilizado en la llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''Calltypes'',
    N''Descripción del tipo de llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''dialType'',
    N''Tipo de marcación de la llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''whoHangUp'',
    N''Parte que finalizó la llamada outbound realizada desde chat, cliente o agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''subDisposition'',
    N''Subdisposición o subcalificación asignada a la llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''dialResult'',
    N''Resultado de estado de la llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''calId'',
    N''Identificador único de la llamada outbound realizada desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''trunk'',
    N''Puerto o troncal utilizado para realizar la llamada outbound desde chat.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''year'',
    N''Año calendario correspondiente a la fecha de inicio de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''month'',
    N''Mes calendario correspondiente a la fecha de inicio de la llamada, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''day'',
    N''Día del mes correspondiente a la fecha de inicio de la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''hour'',
    N''Hora del día correspondiente a la fecha de inicio de la llamada, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutCallsOnChatDetail'', N''minutes'',
    N''Minuto correspondiente a la fecha de inicio de la llamada, expresado en formato de 0 a 59.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutDialDetail'',
    @Description = N''Reporte detallado de intentos de marcación outbound. Incluye campaña, teléfono, resultado de marcación, modalidad de marcación, datos adicionales del contacto, facturación, causa de desconexión, disposición, subdisposición, agente, área, agente virtual, ANI, datos capturados y tiempo de diálo.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''date'',
    N''Fecha y hora del intento de marcación outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''callKey'',
    N''Clave operativa de la llamada o registro outbound asociado al intento de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''telephone'',
    N''Número telefónico marcado en el intento outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''dialResultId'',
    N''Identificador del resultado de marcación outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''dialResult'',
    N''Descripción del resultado de marcación outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''campaignId'',
    N''Identificador de la campaña outbound asociada al intento de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''campaign'',
    N''Nombre o descripción de la campaña outbound asociada al intento de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''timeMessage'',
    N''Tiempo asociado al mensaje, tono ocupado o duración técnica del intento de marcación, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''year'',
    N''Año calendario correspondiente a la fecha del intento de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''month'',
    N''Mes calendario correspondiente a la fecha del intento de marcación, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''day'',
    N''Día del mes correspondiente a la fecha del intento de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''hour'',
    N''Hora del día correspondiente a la fecha del intento de marcación, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''minutes'',
    N''Minuto correspondiente a la fecha del intento de marcación, expresado en formato de 0 a 59.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''listName'',
    N''Nombre de la lista de registros asociada al intento de marcación outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''billed'',
    N''Indicador de si el intento de marcación fue considerado facturable o no facturable.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data1'',
    N''Dato adicional 1 asociado al registro outbound o a la fuente de datos de la marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data2'',
    N''Dato adicional 2 asociado al registro outbound o a la fuente de datos de la marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data3'',
    N''Dato adicional 3 asociado al registro outbound o a la fuente de datos de la marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data4'',
    N''Dato adicional 4 asociado al registro outbound o a la fuente de datos de la marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data5'',
    N''Dato adicional 5 asociado al registro outbound o a la fuente de datos de la marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''fileMoved'',
    N''Ubicación o condición de almacenamiento de la grabación asociada a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''disconnectCause'',
    N''Causa técnica de desconexión registrada para el intento de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''DCCustomer'',
    N''Descripción de la causa de desconexión presentada para el cliente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''dialType'',
    N''Tipo de marcación utilizado en el intento outbound, como preview, asistida, callback, automática, manual o integración.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''TipoTel'',
    N''Clasificación del teléfono marcado, como fijo, celular o indefinido.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''CallDisposition'',
    N''Disposición o calificación asignada a la llamada asociada al intento de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''CallSubDisposition'',
    N''Subdisposición o subcalificación asignada a la llamada asociada al intento de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data6'',
    N''Dato adicional 6 asociado al registro preview outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data7'',
    N''Dato adicional 7 asociado al registro preview outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data8'',
    N''Dato adicional 8 asociado al registro preview outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data9'',
    N''Dato adicional 9 asociado al registro preview outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data10'',
    N''Dato adicional 10 asociado al registro preview outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data11'',
    N''Dato adicional 11 asociado al registro preview outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data12'',
    N''Dato adicional 12 asociado al registro preview outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data13'',
    N''Dato adicional 13 asociado al registro preview outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data14'',
    N''Dato adicional 14 asociado al registro preview outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''data15'',
    N''Dato adicional 15 asociado al registro preview outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''preview_Time'',
    N''Tiempo utilizado en vista previa antes de realizar la marcación outbound, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''login'',
    N''Login del agente asociado al intento de marcación outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''areaId'',
    N''Identificador del área asociada a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''area'',
    N''Nombre del área asociada a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''ModelName'',
    N''Nombre del modelo o agente virtual asociado al intento de marcación, cuando aplica.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''ani'',
    N''Número ANI utilizado como origen de la marcación outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''CapturedData'',
    N''Información capturada durante la interacción outbound o por agente virtual.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''calId'',
    N''Identificador de la llamada outbound asociada al intento de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDialDetail'', N''dialog'',
    N''Tiempo de diálo asociado al intento de marcación outbound, en segundos.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutDials'',
    @Description = N''Reporte de resultados de marcación outbound por intervalo horario, campaña, grupo de trabajo y área. Incluye conteo y porcentaje de intentos por resultado de marcación.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''date'',
    N''Fecha y hora del intervalo reportado para resultados de marcación outbound por campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''campaignId'',
    N''Identificador de la campaña outbound asociada al resultado de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''campaign'',
    N''Nombre o descripción de la campaña outbound asociada al resultado de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''workgroupId'',
    N''Identificador del grupo de trabajo asociado a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''workgroup'',
    N''Nombre del grupo de trabajo asociado a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''areaId'',
    N''Identificador del área asociada a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''area'',
    N''Nombre del área asociada a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''dialResultId'',
    N''Identificador del resultado de marcación outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''dialResult'',
    N''Descripción del resultado de marcación outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''descripcion_count'',
    N''Etiqueta técnica generada a partir del resultado de marcación para identificar el conteo asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''count'',
    N''Conteo de intentos de marcación outbound con el resultado reportado dentro del intervalo y campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''descripcion_avg'',
    N''Etiqueta técnica generada a partir del resultado de marcación para identificar el porcentaje asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''avg'',
    N''Porcentaje de intentos de marcación con el resultado reportado respecto al total de intentos outbound del periodo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''year'',
    N''Año calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''month'',
    N''Mes calendario correspondiente al intervalo reportado, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''day'',
    N''Día del mes correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''hour'',
    N''Hora del día correspondiente al intervalo reportado, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDials'', N''minutes'',
    N''Minuto correspondiente al intervalo reportado. El valor registrado es 0 porque el reporte se agrupa por hora.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutDispositions'',
    @Description = N''Reporte de disposiciones outbound por intervalo horario, campaña, agente, área y grupo de trabajo. Incluye conteo de llamadas gestionadas por disposición o calificación.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''date'',
    N''Fecha y hora del intervalo reportado para disposiciones outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''campaignId'',
    N''Identificador de la campaña outbound asociada a la disposición.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''campaign'',
    N''Nombre o descripción de la campaña outbound asociada a la disposición.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''dispositionId'',
    N''Identificador de la disposición o calificación outbound asignada a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''disposition'',
    N''Descripción traducible de la disposición outbound asignada a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''disposition_count'',
    N''Etiqueta técnica generada a partir de la disposición outbound para identificar el conteo asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''count'',
    N''Conteo de llamadas outbound con la disposición reportada durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''userId'',
    N''Identificador del agente que registró la disposición outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''agentName'',
    N''Login del agente que registró la disposición outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''username'',
    N''Nombre completo del agente que registró la disposición outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''areaId'',
    N''Identificador del área asociada a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''area'',
    N''Nombre del área asociada a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''workgroupId'',
    N''Identificador del grupo de trabajo asociado a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''wg'',
    N''Nombre del grupo de trabajo asociado a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''year'',
    N''Año calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''month'',
    N''Mes calendario correspondiente al intervalo reportado, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''day'',
    N''Día del mes correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''hour'',
    N''Hora del día correspondiente al intervalo reportado, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositions'', N''minutes'',
    N''Minuto correspondiente al intervalo reportado, expresado en formato de 0 a 59.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutDispositionsContacOwner'',
    @Description = N''Reporte de disposiciones outbound con contacto al titular por intervalo horario y campaña. Incluye total de llamadas gestionadas, cantidad de contactos al titular y porcentaje correspondiente.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositionsContacOwner'', N''date'',
    N''Fecha y hora del intervalo reportado para disposiciones outbound con marca de contacto al titular.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositionsContacOwner'', N''campaignId'',
    N''Identificador de la campaña outbound asociada a las disposiciones evaluadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositionsContacOwner'', N''campaign'',
    N''Nombre o descripción de la campaña outbound asociada a las disposiciones evaluadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositionsContacOwner'', N''total'',
    N''Conteo total de llamadas outbound gestionadas en la campaña durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositionsContacOwner'', N''dispositionContactOwner'',
    N''Conteo de llamadas outbound cuya disposición o subdisposición indica contacto con el titular.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositionsContacOwner'', N''dispositionContactOwnerPctg'',
    N''Porcentaje de llamadas con contacto al titular respecto al total de llamadas outbound gestionadas en la campaña durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositionsContacOwner'', N''year'',
    N''Año calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositionsContacOwner'', N''month'',
    N''Mes calendario correspondiente al intervalo reportado, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositionsContacOwner'', N''day'',
    N''Día del mes correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositionsContacOwner'', N''hour'',
    N''Hora del día correspondiente al intervalo reportado, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutDispositionsContacOwner'', N''minutes'',
    N''Minuto correspondiente al intervalo reportado, expresado en formato de 0 a 59.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutKPI'',
    @Description = N''Reporte de indicadores KPI outbound por intervalo horario y campaña. Incluye total de llamadas, tiempos promedio, distribución de llamadas contestadas por duración, llamadas contestadas, restantes y abandonadas, así como sus porcentajes y tiempo promedio entre llamadas.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''date'',
    N''Fecha y hora del intervalo reportado para indicadores KPI outbound por campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''campaignId'',
    N''Identificador de la campaña outbound asociada a los indicadores KPI.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''campaign'',
    N''Nombre o descripción de la campaña outbound asociada a los indicadores KPI.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''totalCalls'',
    N''Conteo total de llamadas outbound registradas para la campaña durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''avgXfer'',
    N''Tiempo promedio de transferencia por llamada outbound durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''avgCallTime'',
    N''Tiempo promedio de conversación por llamada outbound durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''c10Secs'',
    N''Conteo de llamadas contestadas con duración de conversación de hasta 10 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''c20Secs'',
    N''Conteo de llamadas contestadas con duración de conversación mayor a 10 y hasta 20 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''c30Secs'',
    N''Conteo de llamadas contestadas con duración de conversación mayor a 20 y hasta 30 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''cMaxSecs'',
    N''Conteo de llamadas contestadas con duración de conversación mayor a 30 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''AnsweredCalls'',
    N''Conteo de llamadas outbound contestadas durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''answeredCallsPctg'',
    N''Porcentaje de llamadas outbound contestadas respecto al total de llamadas de la campaña durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''remainingCalls'',
    N''Conteo de llamadas outbound restantes o no finalizadas como contestadas o excluidas durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''remainingCallsPctg'',
    N''Porcentaje de llamadas restantes respecto al total de llamadas outbound de la campaña durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''abandonedCalls'',
    N''Conteo de llamadas outbound abandonadas durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''abandonedCallsPctg'',
    N''Porcentaje de llamadas abandonadas respecto al total de llamadas outbound de la campaña durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''avgTimeBetweenCalls'',
    N''Tiempo promedio estimado entre llamadas outbound durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''year'',
    N''Año calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''month'',
    N''Mes calendario correspondiente al intervalo reportado, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''day'',
    N''Día del mes correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''hour'',
    N''Hora del día correspondiente al intervalo reportado, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutKPI'', N''minutes'',
    N''Minuto correspondiente al intervalo reportado, expresado en formato de 0 a 59.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutManagementBase'',
    @Description = N''Base de gestión outbound por intento de marcación. Incluye resultado de marcación, disposición, subdisposición, agente, campaña, clave de llamada, teléfono y datos de calendario para análisis operativo.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''date'',
    N''Fecha y hora del intento de marcación outbound registrado en la base de gestión.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''dialResultCode'',
    N''Identificador del registro o lote de marcación asociado al resultado outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''dialResultId'',
    N''Identificador del resultado de marcación outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''dialResult'',
    N''Descripción del resultado de marcación outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''dispositionId'',
    N''Identificador de la disposición o calificación asignada a la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''disposition'',
    N''Descripción de la disposición o calificación asignada a la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''subDispositionId'',
    N''Identificador de la subdisposición o subcalificación asignada a la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''subDisposition'',
    N''Descripción de la subdisposición o subcalificación asignada a la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''total'',
    N''Conteo unitario del registro de gestión outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''Agent'',
    N''Login del agente asociado a la gestión outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''Campaigns'',
    N''Nombre o descripción de la campaña outbound asociada a la gestión.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''year'',
    N''Año calendario correspondiente a la fecha de la marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''month'',
    N''Mes calendario correspondiente a la fecha de la marcación, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''day'',
    N''Día del mes correspondiente a la fecha de la marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''hour'',
    N''Hora del día correspondiente a la fecha de la marcación, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''minutes'',
    N''Minuto correspondiente a la fecha de la marcación, expresado en formato de 0 a 59.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''calKey'',
    N''Clave operativa de la llamada o registro outbound asociado a la gestión.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''telephone'',
    N''Número telefónico marcado en la gestión outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutManagementBase'', N''campaignId'',
    N''Identificador de la campaña outbound asociada a la gestión.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutSMSAnswDetailByCamp'',
    @Description = N''Reporte detallado de respuestas SMS outbound por campaña. Incluye fecha del mensaje, campaña asociada, contenido del SMS y número telefónico remitente.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSAnswDetailByCamp'', N''date'',
    N''Fecha y hora en que se registró la respuesta SMS outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSAnswDetailByCamp'', N''camId'',
    N''Identificador de la campaña outbound asociada a la respuesta SMS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSAnswDetailByCamp'', N''campaignName'',
    N''Nombre o descripción de la campaña outbound asociada a la respuesta SMS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSAnswDetailByCamp'', N''message'',
    N''Contenido del mensaje SMS recibido o mensaje fuente asociado al registro.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSAnswDetailByCamp'', N''senderNumber'',
    N''Número telefónico del remitente asociado a la respuesta SMS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSAnswDetailByCamp'', N''campaignId'',
    N''Identificador de la campaña outbound asociada a la respuesta SMS.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutSMSSentMessagesDetail'',
    @Description = N''Reporte detallado de mensajes SMS outbound enviados. Incluye registro de envío, campaña, número destinatario, fecha del envío, resultado, costo, identificador del mensaje y sistema o API utilizado.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSSentMessagesDetail'', N''recordId'',
    N''Identificador del registro de envío SMS outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSSentMessagesDetail'', N''campaign'',
    N''Nombre o descripción de la campaña outbound asociada al envío SMS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSSentMessagesDetail'', N''recipientNumber'',
    N''Número telefónico destinatario al que se envió el SMS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSSentMessagesDetail'', N''date'',
    N''Fecha y hora en que se registró el envío del SMS outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSSentMessagesDetail'', N''messageResult'',
    N''Resultado del envío SMS reportado por el sistema o proveedor.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSSentMessagesDetail'', N''ncost'',
    N''Costo neto registrado para el envío del SMS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSSentMessagesDetail'', N''messageId'',
    N''Identificador del mensaje SMS registrado en el log de envío.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSSentMessagesDetail'', N''campaignId'',
    N''Identificador de la campaña outbound asociada al envío SMS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSMSSentMessagesDetail'', N''SystemApiId'',
    N''Identificador del sistema o API utilizado para procesar el envío SMS.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepOutSubDispositions'',
    @Description = N''Reporte de subdisposiciones outbound por intervalo horario, campaña, agente, área y grupo de trabajo. Incluye conteo de llamadas gestionadas por subdisposición o subcalificación.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''date'',
    N''Fecha y hora del intervalo reportado para subdisposiciones outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''campaignId'',
    N''Identificador de la campaña outbound asociada a la subdisposición.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''campaign'',
    N''Nombre o descripción de la campaña outbound asociada a la subdisposición.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''subDispositionId'',
    N''Identificador de la subdisposición o subcalificación outbound asignada a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''subDisposition'',
    N''Descripción traducible de la subdisposición outbound asignada a la llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''subDisposition_count'',
    N''Etiqueta técnica generada a partir de la subdisposición outbound para identificar el conteo asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''count'',
    N''Conteo de llamadas outbound con la subdisposición reportada durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''userId'',
    N''Identificador del agente que registró la subdisposición outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''agentName'',
    N''Nombre completo del agente que registró la subdisposición outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''user'',
    N''Login del agente que registró la subdisposición outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''areaId'',
    N''Identificador del área asociada a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''area'',
    N''Nombre del área asociada a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''workgroupId'',
    N''Identificador del grupo de trabajo asociado a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''wg'',
    N''Nombre del grupo de trabajo asociado a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''year'',
    N''Año calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''month'',
    N''Mes calendario correspondiente al intervalo reportado, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''day'',
    N''Día del mes correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''hour'',
    N''Hora del día correspondiente al intervalo reportado, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepOutSubDispositions'', N''minutes'',
    N''Minuto correspondiente al intervalo reportado, expresado en formato de 0 a 59.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepSMSDayReportBySegments'',
    @Description = N''Reporte diario de envíos SMS por segmento y crédito. Incluye información del crédito, segmentación, fecha de envío, semana, día de semana, hasta diez teléfonos contactados, resultado funcional, resultado de envío, estado funcional y corte real.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''id_credito'',
    N''Identificador del crédito asociado al envío SMS del reporte diario por segmento.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''credito'',
    N''Número o clave de crédito asociado al envío SMS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''fecha_foto'',
    N''Fecha del envío SMS considerada como fecha de corte o foto del reporte.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''meses_vencidos'',
    N''Número de meses vencidos del crédito al momento del envío SMS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''seg_cuenta'',
    N''Segmento de cuenta asociado al crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''fila'',
    N''Fila o clasificación operativa asociada al crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''locacion'',
    N''Locación asociada al crédito o cuenta.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''dia_corte'',
    N''Día de corte asociado al crédito o cuenta.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''SegmentId'',
    N''Identificador del segmento SMS asociado al registro.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''segmentoMC'',
    N''Segmento MC asociado al crédito para clasificación del envío SMS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''semana'',
    N''Semana del mes correspondiente a la fecha de envío SMS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''dia_semana'',
    N''Día de la semana asociado al reporte de envío SMS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''telefonos1'',
    N''Primer teléfono registrado para el crédito dentro del envío SMS del día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado1'',
    N''Resultado funcional asociado al primer teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado_de_envio1'',
    N''Resultado de envío SMS asociado al primer teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''telefonos2'',
    N''Segundo teléfono registrado para el crédito dentro del envío SMS del día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado2'',
    N''Resultado funcional asociado al segundo teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado_de_envio2'',
    N''Resultado de envío SMS asociado al segundo teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''telefonos3'',
    N''Tercer teléfono registrado para el crédito dentro del envío SMS del día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado3'',
    N''Resultado funcional asociado al tercer teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado_de_envio3'',
    N''Resultado de envío SMS asociado al tercer teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''telefonos4'',
    N''Cuarto teléfono registrado para el crédito dentro del envío SMS del día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado4'',
    N''Resultado funcional asociado al cuarto teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado_de_envio4'',
    N''Resultado de envío SMS asociado al cuarto teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''telefonos5'',
    N''Quinto teléfono registrado para el crédito dentro del envío SMS del día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado5'',
    N''Resultado funcional asociado al quinto teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado_de_envio5'',
    N''Resultado de envío SMS asociado al quinto teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''telefonos6'',
    N''Sexto teléfono registrado para el crédito dentro del envío SMS del día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado6'',
    N''Resultado funcional asociado al sexto teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado_de_envio6'',
    N''Resultado de envío SMS asociado al sexto teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''telefonos7'',
    N''Séptimo teléfono registrado para el crédito dentro del envío SMS del día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado7'',
    N''Resultado funcional asociado al séptimo teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado_de_envio7'',
    N''Resultado de envío SMS asociado al séptimo teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''telefonos8'',
    N''Octavo teléfono registrado para el crédito dentro del envío SMS del día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado8'',
    N''Resultado funcional asociado al octavo teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado_de_envio8'',
    N''Resultado de envío SMS asociado al octavo teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''telefonos9'',
    N''Noveno teléfono registrado para el crédito dentro del envío SMS del día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado9'',
    N''Resultado funcional asociado al noveno teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado_de_envio9'',
    N''Resultado de envío SMS asociado al noveno teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''telefonos10'',
    N''Décimo teléfono registrado para el crédito dentro del envío SMS del día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado10'',
    N''Resultado funcional asociado al décimo teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''resultado_de_envio10'',
    N''Resultado de envío SMS asociado al décimo teléfono del crédito.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''estado_funcional'',
    N''Estado funcional del crédito asociado al envío SMS.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSMSDayReportBySegments'', N''corte_real'',
    N''Corte real asociado al crédito o cuenta del envío SMS.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepSpececialAbnd'',
    @Description = N''Reporte especial diario de abandono por ACD inbound o campaña outbound. Incluye total de llamadas, llamadas abandonadas y porcentaje de abandono por origen operativo.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbnd'', N''date'',
    N''Fecha del día reportado para el resumen especial de abandono en ACD o campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbnd'', N''campaignId'',
    N''Identificador de la campaña outbound asociada al resumen de abandono.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbnd'', N''inboundId'',
    N''Identificador del inbound asociado al resumen de abandono.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbnd'', N''campACDDescription'',
    N''Descripción del origen evaluado, indicando si corresponde a un ACD inbound o a una campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbnd'', N''total'',
    N''Conteo total de llamadas registradas para el ACD o campaña en la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbnd'', N''abandonedCalls'',
    N''Conteo de llamadas abandonadas para el ACD o campaña en la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbnd'', N''abandonedCallsPctg'',
    N''Porcentaje de llamadas abandonadas respecto al total de llamadas del ACD o campaña en la fecha reportada.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepSpececialAbndPercentage'',
    @Description = N''Reporte especial diario de porcentaje acumulado de abandono por inbound. Incluye porcentajes de abandono por rans de tiempo de espera acumulados hasta 5, 10, 15, 20, 25, 30, 40, 50 y 60 segundos, además del porcentaje total de abandono.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndPercentage'', N''date'',
    N''Fecha del día reportado para el porcentaje acumulado de abandono por inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndPercentage'', N''inboundId'',
    N''Identificador del inbound asociado al análisis de abandono.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndPercentage'', N''inbound'',
    N''Nombre o descripción del inbound asociado al análisis de abandono.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndPercentage'', N''5'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 5 segundos respecto al total de llamadas del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndPercentage'', N''10'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 10 segundos respecto al total de llamadas del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndPercentage'', N''15'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 15 segundos respecto al total de llamadas del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndPercentage'', N''20'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 20 segundos respecto al total de llamadas del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndPercentage'', N''25'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 25 segundos respecto al total de llamadas del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndPercentage'', N''30'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 30 segundos respecto al total de llamadas del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndPercentage'', N''40'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 40 segundos respecto al total de llamadas del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndPercentage'', N''50'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 50 segundos respecto al total de llamadas del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndPercentage'', N''60'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 60 segundos respecto al total de llamadas del inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndPercentage'', N''gt60'',
    N''Porcentaje total de llamadas abandonadas respecto al total de llamadas del inbound.'';


/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepSpececialAbndProfiles'',
    @Description = N''Reporte especial diario de perfil de abandono por inbound. Incluye conteos acumulados de llamadas abandonadas por rans de tiempo hasta 5, 10, 15, 20, 25, 30, 40, 50 y 60 segundos, además del total de abandonos y llamadas evaluadas.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndProfiles'', N''date'',
    N''Fecha del día reportado para el perfil de abandono por inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndProfiles'', N''inboundId'',
    N''Identificador del inbound asociado al perfil de abandono.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndProfiles'', N''inbound'',
    N''Nombre o descripción del inbound asociado al perfil de abandono.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndProfiles'', N''5'',
    N''Conteo de llamadas abandonadas con tiempo de abandono menor o igual a 5 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndProfiles'', N''10'',
    N''Conteo de llamadas abandonadas con tiempo de abandono menor o igual a 10 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndProfiles'', N''15'',
    N''Conteo de llamadas abandonadas con tiempo de abandono menor o igual a 15 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndProfiles'', N''20'',
    N''Conteo de llamadas abandonadas con tiempo de abandono menor o igual a 20 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndProfiles'', N''25'',
    N''Conteo de llamadas abandonadas con tiempo de abandono menor o igual a 25 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndProfiles'', N''30'',
    N''Conteo de llamadas abandonadas con tiempo de abandono menor o igual a 30 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndProfiles'', N''40'',
    N''Conteo de llamadas abandonadas con tiempo de abandono menor o igual a 40 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndProfiles'', N''50'',
    N''Conteo de llamadas abandonadas con tiempo de abandono menor o igual a 50 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndProfiles'', N''60'',
    N''Conteo de llamadas abandonadas con tiempo de abandono menor o igual a 60 segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndProfiles'', N''gt60'',
    N''Conteo total de llamadas abandonadas del inbound en la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndProfiles'', N''total'',
    N''Conteo total de llamadas evaluadas para el inbound en la fecha reportada.'';

/* Descripción general del objeto */
EXEC dbo.usp_SetObjectDescription
    @SchemaName = N''dbo'',
    @ObjectName = N''RepSpececialAbndTimes'',
    @Description = N''Reporte especial diario de distribución porcentual de abandonos por tiempo en inbound. Incluye porcentajes acumulados de llamadas abandonadas por rans de tiempo hasta 5, 10, 15, 20, 25, 30, 40, 50 y 60 segundos, además del porcentaje total de abandono.'';

/* Descripción de columnas */
EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndTimes'', N''date'',
    N''Fecha del día reportado para la distribución porcentual de abandonos por tiempo en inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndTimes'', N''inboundId'',
    N''Identificador del inbound asociado a la distribución de abandono por tiempo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndTimes'', N''inbound'',
    N''Nombre o descripción del inbound asociado a la distribución de abandono por tiempo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndTimes'', N''5'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 5 segundos respecto al total de registros de abandono evaluados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndTimes'', N''10'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 10 segundos respecto al total de registros de abandono evaluados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndTimes'', N''15'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 15 segundos respecto al total de registros de abandono evaluados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndTimes'', N''20'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 20 segundos respecto al total de registros de abandono evaluados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndTimes'', N''25'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 25 segundos respecto al total de registros de abandono evaluados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndTimes'', N''30'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 30 segundos respecto al total de registros de abandono evaluados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndTimes'', N''40'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 40 segundos respecto al total de registros de abandono evaluados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndTimes'', N''50'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 50 segundos respecto al total de registros de abandono evaluados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndTimes'', N''60'',
    N''Porcentaje de llamadas abandonadas con tiempo de abandono menor o igual a 60 segundos respecto al total de registros de abandono evaluados.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAbndTimes'', N''gt60'',
    N''Porcentaje total de llamadas abandonadas respecto al total de registros de abandono evaluados.'';


EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepSpececialAgent'',
N''Reporte especial diario de actividad por agente. Incluye sesión, horarios de login y lout, tiempos de diálo y no disponible, llamadas inbound y outbound, abandonos, llamadas contestadas, llamadas sin calificación y tiempo auxiliar disponible.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''date'',
N''Fecha del día reportado para la actividad especial del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''userId'',
N''Identificador del agente asociado al resumen diario.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''user'',
N''Nombre completo del agente asociado al resumen diario.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''login'',
N''Login del agente asociado al resumen diario.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''sessionTime'',
N''Tiempo total de sesión del agente durante el día reportado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''loginTime'',
N''Fecha y hora del primer inicio de sesión del agente en el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''loutTime'',
N''Fecha y hora del último cierre de sesión del agente en el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''dialogTime'',
N''Tiempo total de diálo y trabajo posterior en llamadas inbound y outbound, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''ndTime'',
N''Tiempo total no disponible del agente durante el día reportado, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''callsOut'',
N''Conteo de llamadas outbound asociadas al agente durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''callsIn'',
N''Conteo de llamadas inbound asociadas al agente durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''abandonedCalls'',
N''Conteo total de llamadas abandonadas asociadas al agente durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''nanswer2'',
N''Conteo total de llamadas contestadas inbound y outbound asociadas al agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''unrated'',
N''Conteo total de llamadas contestadas sin calificación asignada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgent'', N''tauxiliarready'',
N''Tiempo total del agente en estado auxiliar disponible durante el día reportado, en segundos.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepSpececialAgtPerformance'',
N''Reporte especial diario de desempeño por agente. Incluye llamadas contestadas, promesas registradas, porcentaje de promesas, tiempo promedio de llamada y tiempo promedio de trabajo posterior.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgtPerformance'', N''date'',
N''Fecha del día reportado para el desempeño del agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgtPerformance'', N''userId'',
N''Identificador del agente asociado al desempeño diario.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgtPerformance'', N''user'',
N''Nombre completo del agente asociado al desempeño diario.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgtPerformance'', N''login'',
N''Login del agente asociado al desempeño diario.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgtPerformance'', N''Answered'',
N''Conteo de llamadas contestadas por el agente durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgtPerformance'', N''promises'',
N''Conteo de promesas registradas por el agente durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgtPerformance'', N''promisesPctg'',
N''Porcentaje de promesas registradas respecto al total de llamadas contestadas por el agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgtPerformance'', N''avgCallTime'',
N''Tiempo promedio de diálo por llamada contestada, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialAgtPerformance'', N''avgWrapupTime'',
N''Tiempo promedio de trabajo posterior a la llamada, en segundos.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepSpececialCamMovs'',
N''Reporte especial de movimientos de campañas outbound. Incluye fecha del movimiento, campaña, acción realizada, tipo de carga o trabajo, registros nuevos, callbacks, agentes involucrados y usuario responsable.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialCamMovs'', N''date'',
N''Fecha y hora en que se registró el movimiento de campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialCamMovs'', N''campaignId'',
N''Identificador de la campaña asociada al movimiento.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialCamMovs'', N''campaign'',
N''Nombre o descripción de la campaña asociada al movimiento.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialCamMovs'', N''action'',
N''Acción realizada sobre la campaña, como inicio, detención, carga, eliminación o generación de trabajo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialCamMovs'', N''type'',
N''Tipo de trabajo o carga asociada al movimiento de campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialCamMovs'', N''nnew'',
N''Cantidad de registros nuevos asociados al movimiento de campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialCamMovs'', N''ncallback'',
N''Cantidad de registros callback asociados al movimiento de campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialCamMovs'', N''Agents'',
N''Cantidad de agentes asociados al movimiento de campaña.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialCamMovs'', N''user'',
N''Nombre del usuario que realizó o quedó asociado al movimiento de campaña.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepSpececialPromises'',
N''Reporte especial diario de promesas por origen inbound u outbound. Incluye campaña o ACD, total de gestiones, promesas registradas y porcentaje de promesas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialPromises'', N''date'',
N''Fecha del día reportado para las promesas registradas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialPromises'', N''type'',
N''Tipo de origen de la promesa, inbound u outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialPromises'', N''campaignId'',
N''Identificador de la campaña outbound asociada a las promesas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialPromises'', N''inboundId'',
N''Identificador del inbound asociado a las promesas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialPromises'', N''campACDDescription'',
N''Descripción del origen operativo asociado a las promesas, ya sea campaña outbound o ACD inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialPromises'', N''promises'',
N''Conteo de promesas registradas para el origen operativo en la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialPromises'', N''total'',
N''Conteo total de gestiones evaluadas para el origen operativo en la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpececialPromises'', N''percentage'',
N''Proporción de promesas registradas respecto al total de gestiones evaluadas.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepSpecialAbndCamp'',
N''Reporte especial de abandono outbound por intervalo horario y campaña. Incluye llamadas marcadas, llamadas abandonadas, porcentaje de abandono y área asociada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialAbndCamp'', N''date'',
N''Fecha y hora del intervalo reportado para abandono por campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialAbndCamp'', N''campaignId'',
N''Identificador de la campaña outbound asociada al abandono.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialAbndCamp'', N''campaign'',
N''Nombre o descripción de la campaña outbound asociada al abandono.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialAbndCamp'', N''dialedCalls'',
N''Conteo total de llamadas outbound marcadas durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialAbndCamp'', N''abandonedCalls'',
N''Conteo de llamadas outbound abandonadas durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialAbndCamp'', N''abandonedCallsPctg'',
N''Porcentaje de llamadas abandonadas respecto al total de llamadas marcadas.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialAbndCamp'', N''year'',
N''Año calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialAbndCamp'', N''month'',
N''Mes calendario correspondiente al intervalo reportado, expresado como valor numérico de 1 a 12.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialAbndCamp'', N''day'',
N''Día del mes correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialAbndCamp'', N''hour'',
N''Hora del día correspondiente al intervalo reportado, expresada en formato de 0 a 23.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialAbndCamp'', N''minutes'',
N''Minuto correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialAbndCamp'', N''areaId'',
N''Identificador del área asociada a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialAbndCamp'', N''area'',
N''Nombre del área asociada a la campaña outbound.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepSpecialCallKeyHistory'',
N''Reporte especial de historial por clave de llamada outbound. Incluye campaña, teléfono, resultado de marcación, disposición, tiempo de diálo, callback y agente asociado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialCallKeyHistory'', N''date'',
N''Fecha y hora del intento de marcación asociado a la clave de llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialCallKeyHistory'', N''campaignId'',
N''Identificador de la campaña outbound asociada a la clave de llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialCallKeyHistory'', N''campaign'',
N''Nombre o descripción de la campaña outbound asociada a la clave de llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialCallKeyHistory'', N''callKey'',
N''Clave operativa de la llamada o registro outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialCallKeyHistory'', N''telephone'',
N''Número telefónico marcado asociado a la clave de llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialCallKeyHistory'', N''dialResult'',
N''Descripción del resultado de marcación asociado a la clave de llamada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialCallKeyHistory'', N''disposition'',
N''Descripción de la disposición asignada a la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialCallKeyHistory'', N''dialogTime'',
N''Tiempo de diálo registrado para la llamada outbound, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialCallKeyHistory'', N''CallBacks'',
N''Fecha de callback asociada a la llamada o indicador de que no existe callback.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialCallKeyHistory'', N''login'',
N''Login del agente asociado a la llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialCallKeyHistory'', N''user'',
N''Nombre completo del agente asociado a la llamada outbound.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepSpecialDialingResults'',
N''Reporte especial de resultados de marcación por intervalo, campaña y estado. Incluye conteo, porcentaje y columnas calendario para análisis operativo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialDialingResults'', N''date'',
N''Fecha y hora del intervalo reportado para resultados de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialDialingResults'', N''campaignId'',
N''Identificador de la campaña outbound asociada al resultado de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialDialingResults'', N''campaign'',
N''Nombre o descripción de la campaña outbound asociada al resultado de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialDialingResults'', N''statusCallId'',
N''Identificador del estado o resultado de marcación outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialDialingResults'', N''statusCall'',
N''Descripción del estado o resultado de marcación outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialDialingResults'', N''statusCall_Count'',
N''Etiqueta técnica generada para identificar el conteo del estado de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialDialingResults'', N''Count'',
N''Conteo de intentos de marcación con el estado reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialDialingResults'', N''statusCall_avg'',
N''Etiqueta técnica generada para identificar el porcentaje del estado de marcación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialDialingResults'', N''avg'',
N''Porcentaje de intentos con el estado reportado respecto al total de intentos del intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialDialingResults'', N''year'',
N''Año calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialDialingResults'', N''month'',
N''Mes calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialDialingResults'', N''day'',
N''Día del mes correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialDialingResults'', N''hour'',
N''Hora del día correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialDialingResults'', N''minutes'',
N''Minuto correspondiente al intervalo reportado.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepSpecialRecordingsDownload'',
N''Reporte especial de descargas de grabaciones. Incluye administrador, grabación, origen inbound u outbound, campaña o inbound asociado, disposición y subdisposición.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialRecordingsDownload'', N''date'',
N''Fecha y hora en que se registró la descarga de la grabación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialRecordingsDownload'', N''adminId'',
N''Identificador del administrador o usuario que descargó la grabación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialRecordingsDownload'', N''admin_name'',
N''Nombre del administrador o usuario que descargó la grabación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialRecordingsDownload'', N''grab_id'',
N''Identificador de la grabación descargada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialRecordingsDownload'', N''generalId'',
N''Identificador general del origen de la grabación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialRecordingsDownload'', N''inboundId'',
N''Identificador del inbound asociado cuando la grabación corresponde a una llamada inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialRecordingsDownload'', N''inboundCampaign'',
N''Nombre o descripción del inbound asociado cuando la grabación corresponde a una llamada inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialRecordingsDownload'', N''campaignId'',
N''Identificador de la campaña asociada cuando la grabación corresponde a una llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialRecordingsDownload'', N''outboundCampaign'',
N''Nombre o descripción de la campaña asociada cuando la grabación corresponde a una llamada outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialRecordingsDownload'', N''disposition'',
N''Descripción de la disposición asociada a la grabación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialRecordingsDownload'', N''subDisposition'',
N''Descripción de la subdisposición asociada a la grabación.'';


EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepSpecialStatusDetail'',
N''Reporte especial de detalle de estados auxiliares por agente. Incluye inicio, fin, duración, auxiliar registrado y columnas calendario.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialStatusDetail'', N''date'',
N''Fecha del día reportado para el detalle de estado auxiliar.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialStatusDetail'', N''agentName'',
N''Nombre completo del agente asociado al estado auxiliar.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialStatusDetail'', N''userId'',
N''Identificador del agente asociado al estado auxiliar.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialStatusDetail'', N''login'',
N''Login del agente asociado al estado auxiliar.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialStatusDetail'', N''auxiliar'',
N''Descripción del estado auxiliar registrado para el agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialStatusDetail'', N''startDate'',
N''Fecha y hora de inicio del estado auxiliar.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialStatusDetail'', N''endDate'',
N''Fecha y hora de fin del estado auxiliar.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialStatusDetail'', N''statusTimeAuxiliar'',
N''Duración del estado auxiliar del agente, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialStatusDetail'', N''year'',
N''Año calendario correspondiente al inicio del estado auxiliar.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialStatusDetail'', N''month'',
N''Mes calendario correspondiente al inicio del estado auxiliar.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialStatusDetail'', N''day'',
N''Día del mes correspondiente al inicio del estado auxiliar.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialStatusDetail'', N''hour'',
N''Hora del día correspondiente al inicio del estado auxiliar.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialStatusDetail'', N''minutes'',
N''Minuto correspondiente al inicio del estado auxiliar.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialStatusDetail'', N''auxiliarId'',
N''Identificador del tipo de auxiliar registrado para el agente.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'',
N''Reporte especial de cantidad de teléfonos por registro y lista. Incluye campaña, lista, conteo por posición de teléfono y porcentaje respecto al total de teléfonos del día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''date'',
N''Fecha del día reportado para teléfonos por registro.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''campaignId'',
N''Identificador de la campaña outbound asociada a la lista.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''campaign'',
N''Nombre o descripción de la campaña outbound asociada a la lista.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''listId'',
N''Identificador de la lista de registros asociada al conteo de teléfonos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''listName'',
N''Nombre de la lista de registros asociada al conteo de teléfonos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''cPhoneNumber'',
N''Etiqueta técnica de la posición de teléfono evaluada en el registro.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''cPhoneNumber_Count'',
N''Etiqueta técnica traducible para el conteo de la posición de teléfono.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''count'',
N''Conteo de teléfonos existentes para la posición evaluada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''percentage'',
N''Etiqueta técnica del porcentaje asociado a la posición de teléfono.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''percentage_avg'',
N''Etiqueta técnica traducible para el porcentaje de la posición de teléfono.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''avg'',
N''Porcentaje de teléfonos de la posición evaluada respecto al total de teléfonos del día.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''year'',
N''Año calendario correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''month'',
N''Mes calendario correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''day'',
N''Día del mes correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''hour'',
N''Hora correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByRegistry'', N''minutes'',
N''Minuto correspondiente a la fecha reportada.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepSpecialTelephoneNumbersByState'',
N''Reporte especial de teléfonos por estado y lista. Incluye conteo y porcentaje de registros por región o estado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByState'', N''date'',
N''Fecha del día reportado para teléfonos por estado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByState'', N''listId'',
N''Identificador de la lista de registros asociada al estado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByState'', N''listName'',
N''Nombre de la lista de registros asociada al estado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByState'', N''state'',
N''Estado o región asociada a los registros telefónicos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByState'', N''state_Count'',
N''Etiqueta técnica generada para el conteo por estado o región.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByState'', N''Count'',
N''Conteo de registros telefónicos asociados al estado o región.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByState'', N''state_avg'',
N''Etiqueta técnica generada para el porcentaje por estado o región.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByState'', N''avg'',
N''Porcentaje de registros del estado o región respecto al total evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByState'', N''year'',
N''Año calendario correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByState'', N''month'',
N''Mes calendario correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByState'', N''day'',
N''Día del mes correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByState'', N''hour'',
N''Hora correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTelephoneNumbersByState'', N''minutes'',
N''Minuto correspondiente a la fecha reportada.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepSpecialTimes'',
N''Reporte especial de tiempos por campaña o ACD. Incluye tiempo de sesión, disponible, diálo, no disponible, auxiliar, otros estados y detalle de tiempos no disponibles por descripción.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''date'',
N''Fecha y hora del intervalo reportado para tiempos por campaña o ACD.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''campaignId'',
N''Identificador de la campaña outbound asociada al intervalo de tiempos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''inboundId'',
N''Identificador del inbound asociado al intervalo de tiempos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''campACDDescription'',
N''Descripción del origen operativo asociado al intervalo, ya sea campaña outbound o ACD inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''sessionTime'',
N''Tiempo total de sesión acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''readyTime'',
N''Tiempo total disponible acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''dialogTime'',
N''Tiempo total de diálo acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''notReadyTime'',
N''Tiempo total no disponible acumulado durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''other'',
N''Tiempo total en otros estados durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''descripcion'',
N''Descripción del estado no disponible asociado al detalle del intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''descripcion_count'',
N''Etiqueta técnica generada para el conteo del estado no disponible.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''count'',
N''Conteo de ocurrencias del estado no disponible durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''descripcion_time'',
N''Etiqueta técnica generada para el tiempo del estado no disponible.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''time'',
N''Tiempo acumulado del estado no disponible durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''timeSeconds'',
N''Tiempo acumulado del estado no disponible expresado en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''year'',
N''Año calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''month'',
N''Mes calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''day'',
N''Día del mes correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''hour'',
N''Hora del día correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''minutes'',
N''Minuto correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepSpecialTimes'', N''auxiliaryReadyTime'',
N''Tiempo total auxiliar disponible acumulado durante el intervalo, en segundos.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepTrunkBusy'',
N''Reporte de ocupación de troncales por intervalo. Incluye troncal, tiempo ocupado, llamadas y columnas calendario.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepTrunkBusy'', N''date'',
N''Fecha y hora del intervalo reportado para ocupación de troncal.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepTrunkBusy'', N''trunk'',
N''Identificador de la troncal o puerto evaluado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepTrunkBusy'', N''tBusy'',
N''Tiempo total de ocupación de la troncal durante el intervalo, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepTrunkBusy'', N''Calls'',
N''Conteo de llamadas asociadas a la ocupación de la troncal durante el intervalo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepTrunkBusy'', N''year'',
N''Año calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepTrunkBusy'', N''month'',
N''Mes calendario correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepTrunkBusy'', N''day'',
N''Día del mes correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepTrunkBusy'', N''hour'',
N''Hora del día correspondiente al intervalo reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepTrunkBusy'', N''minutes'',
N''Minuto correspondiente al intervalo reportado.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepVirtualAgent'',
N''Reporte de métricas de agentes virtuales por día, modelo y campaña inbound. Incluye llamadas manejadas, llamadas transferidas, tiempo promedio de atención y tiempo activo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepVirtualAgent'', N''Id'',
N''Identificador interno del registro del reporte de agente virtual.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepVirtualAgent'', N''idAgent'',
N''Identificador del agente virtual asociado al reporte.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepVirtualAgent'', N''Date'',
N''Fecha del día reportado para las métricas del agente virtual.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepVirtualAgent'', N''ModelName'',
N''Nombre del modelo o agente virtual asociado al reporte.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepVirtualAgent'', N''CampaignName'',
N''Nombre de la campaña o inbound asociado al agente virtual.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepVirtualAgent'', N''CallsHandled'',
N''Conteo de llamadas manejadas por el agente virtual durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepVirtualAgent'', N''CallsTransferred'',
N''Conteo de llamadas transferidas por el agente virtual durante el día reportado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepVirtualAgent'', N''AverageHandleTime'',
N''Tiempo promedio de atención de llamadas manejadas por el agente virtual, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepVirtualAgent'', N''activeTime'',
N''Tiempo activo total del agente virtual durante el día reportado, en segundos.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepWhatsAppByCampaignIn'',
N''Reporte diario de conversaciones WhatsApp inbound por campaña. Incluye número asociado, contactos, mensajes enviados y recibidos, país, conversaciones, asignaciones, tiempos de espera, spam, nivel de servicio y cierres por tipo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''date'',
N''Fecha del día reportado para conversaciones WhatsApp inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''inboundid'',
N''Identificador del inbound asociado a las conversaciones WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''campaign'',
N''Nombre o descripción de la campaña inbound asociada a WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''associatedPhoneNumberWhatsApp'',
N''Número de WhatsApp asociado al ACD o campaña inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''numberSentMessagesWhatsApp'',
N''Conteo de mensajes WhatsApp enviados por agente o administrador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''totalContactsWhatsApp'',
N''Conteo total de contactos únicos en conversaciones WhatsApp inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''numberMsgReceivedWhats'',
N''Conteo de mensajes WhatsApp recibidos del cliente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''contactCountry'',
N''País asociado al número de contacto WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''totalConversationsWhatsApp'',
N''Conteo total de conversaciones WhatsApp inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''numberAssignedMessagesWhatsApp'',
N''Conteo de conversaciones WhatsApp asignadas a agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''maxWaitTimeWhatsApp'',
N''Tiempo máximo de espera en conversaciones WhatsApp, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''avgWaitTimeWhatsApp'',
N''Tiempo promedio de espera en conversaciones WhatsApp, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''spamWhatsApp'',
N''Conteo de conversaciones WhatsApp marcadas como spam.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''serviceLevelWhats'',
N''Porcentaje de conversaciones WhatsApp dentro del nivel de servicio configurado.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''contactFinishedConversationsWhatApp'',
N''Conteo de conversaciones WhatsApp finalizadas por el contacto.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''agentFinishedConversationsWhatApp'',
N''Conteo de conversaciones WhatsApp finalizadas por el agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''systemFinishedConversationsWhatsApp'',
N''Conteo de conversaciones WhatsApp finalizadas por el sistema.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''year'',
N''Año calendario correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''month'',
N''Mes calendario correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''day'',
N''Día del mes correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''hour'',
N''Hora correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignIn'', N''minutes'',
N''Minuto correspondiente a la fecha reportada.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepWhatsAppByCampaignOut'',
N''Reporte diario de conversaciones WhatsApp outbound por campaña. Incluye número asociado, contactos, mensajes enviados y recibidos, país, conversaciones, asignaciones, tiempos de espera, spam y cierres por tipo.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''date'',
N''Fecha del día reportado para conversaciones WhatsApp outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''campaignId'',
N''Identificador de la campaña outbound asociada a las conversaciones WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''campaign'',
N''Nombre o descripción de la campaña outbound asociada a WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''associatedPhoneNumberWhatsApp'',
N''Número de WhatsApp asociado a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''numberSentMessagesWhatsApp'',
N''Conteo de mensajes WhatsApp enviados por agente o administrador.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''totalContactsWhatsApp'',
N''Conteo total de contactos únicos en conversaciones WhatsApp outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''numberMsgReceivedWhats'',
N''Conteo de mensajes WhatsApp recibidos del cliente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''contactCountry'',
N''País asociado al número de contacto WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''totalConversationsWhatsApp'',
N''Conteo total de conversaciones WhatsApp outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''numberAssignedMessagesWhatsApp'',
N''Conteo de conversaciones WhatsApp asignadas a agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''maxWaitTimeWhatsApp'',
N''Tiempo máximo de espera en conversaciones WhatsApp, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''avgWaitTimeWhatsApp'',
N''Tiempo promedio de espera en conversaciones WhatsApp, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''spamWhatsApp'',
N''Conteo de conversaciones WhatsApp marcadas como spam.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''serviceLevelWhats'',
N''Nivel de servicio asociado a conversaciones WhatsApp outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''contactFinishedConversationsWhatApp'',
N''Conteo de conversaciones WhatsApp finalizadas por el contacto.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''agentFinishedConversationsWhatApp'',
N''Conteo de conversaciones WhatsApp finalizadas por el agente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''systemFinishedConversationsWhatsApp'',
N''Conteo de conversaciones WhatsApp finalizadas por el sistema.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''year'',
N''Año calendario correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''month'',
N''Mes calendario correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''day'',
N''Día del mes correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''hour'',
N''Hora correspondiente a la fecha reportada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppByCampaignOut'', N''minutes'',
N''Minuto correspondiente a la fecha reportada.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepWhatsAppDetailConversationIn'',
N''Reporte detallado de conversaciones WhatsApp inbound. Incluye campaña, conversación, global id, disposición, subdisposición, número asociado, agente, contacto, país, tiempos, facturación y calendario.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''date'',
N''Fecha y hora de solicitud de la conversación WhatsApp inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''inboundid'',
N''Identificador del inbound asociado a la conversación WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''campaign'',
N''Nombre o descripción del inbound asociado a la conversación WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''conversationid'',
N''Identificador de la conversación WhatsApp inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''dispositionId'',
N''Identificador de la disposición asignada a la conversación WhatsApp inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''disposition'',
N''Descripción de la disposición asignada a la conversación WhatsApp inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''subDispositionId'',
N''Identificador de la subdisposición asignada a la conversación WhatsApp inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''subDisposition'',
N''Descripción de la subdisposición asignada a la conversación WhatsApp inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''associatedPhoneNumberWhatsApp'',
N''Número de WhatsApp asociado al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''userId'',
N''Identificador del agente asociado a la conversación WhatsApp inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''agentName'',
N''Nombre completo del agente asociado a la conversación WhatsApp inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''contactPhoneNumberWhatsApp'',
N''Número de WhatsApp del contacto o cliente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''contactCountry'',
N''País asociado al número de WhatsApp del contacto.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''waitTimeWhatsApp'',
N''Tiempo de espera de la conversación WhatsApp, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''conversationTimeWhatsApp'',
N''Tiempo total de conversación WhatsApp, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''billedWhatsApp'',
N''Indicador traducible de si la conversación WhatsApp fue facturada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''year'',
N''Año calendario correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''month'',
N''Mes calendario correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''day'',
N''Día del mes correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''hour'',
N''Hora del día correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''minutes'',
N''Minuto correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationIn'', N''globalid'',
N''Identificador global asociado a la conversación WhatsApp.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepWhatsAppDetailConversationOut'',
N''Reporte detallado de conversaciones WhatsApp outbound. Incluye campaña, conversación, global id, disposición, subdisposición, número asociado, agente, contacto, país, tiempos, facturación y calendario.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''date'',
N''Fecha y hora de solicitud de la conversación WhatsApp outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''campaignId'',
N''Identificador de la campaña outbound asociada a la conversación WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''campaign'',
N''Nombre o descripción de la campaña outbound asociada a la conversación WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''conversationid'',
N''Identificador de la conversación WhatsApp outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''globalid'',
N''Identificador global asociado a la conversación WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''dispositionId'',
N''Identificador de la disposición asignada a la conversación WhatsApp outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''disposition'',
N''Descripción de la disposición asignada a la conversación WhatsApp outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''subDispositionId'',
N''Identificador de la subdisposición asignada a la conversación WhatsApp outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''subDisposition'',
N''Descripción de la subdisposición asignada a la conversación WhatsApp outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''associatedPhoneNumberWhatsApp'',
N''Número de WhatsApp asociado a la campaña outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''userId'',
N''Identificador del agente asociado a la conversación WhatsApp outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''agentName'',
N''Nombre completo del agente asociado a la conversación WhatsApp outbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''contactPhoneNumberWhatsApp'',
N''Número de WhatsApp del contacto o cliente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''contactCountry'',
N''País asociado al número de WhatsApp del contacto.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''waitTimeWhatsApp'',
N''Tiempo de espera de la conversación WhatsApp, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''conversationTimeWhatsApp'',
N''Tiempo total de conversación WhatsApp, en segundos.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''billedWhatsApp'',
N''Indicador traducible de si la conversación WhatsApp fue facturada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''year'',
N''Año calendario correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''month'',
N''Mes calendario correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''day'',
N''Día del mes correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''hour'',
N''Hora del día correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsAppDetailConversationOut'', N''minutes'',
N''Minuto correspondiente a la fecha de solicitud.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'',
N''Reporte de conversaciones WhatsApp inbound marcadas como spam. Incluye conversación, global id, inbound, campaña, números asociados, fecha de spam, agente y calendario.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''date'',
N''Fecha y hora de solicitud de la conversación WhatsApp marcada como spam.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''conversationid'',
N''Identificador de la conversación WhatsApp marcada como spam.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''globalid'',
N''Identificador global asociado a la conversación WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''inboundid'',
N''Identificador del inbound asociado a la conversación WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''campaign'',
N''Nombre o descripción del inbound asociado a la conversación WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''associatedPhoneNumberWhatsApp'',
N''Número de WhatsApp asociado al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''contactPhoneNumberWhatsApp'',
N''Número de WhatsApp del contacto o cliente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''spamDate'',
N''Fecha y hora en que la conversación fue marcada como spam.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''userId'',
N''Identificador del agente que marcó o estuvo asociado al spam.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''agentName'',
N''Nombre del agente que marcó o estuvo asociado al spam.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''year'',
N''Año calendario correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''month'',
N''Mes calendario correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''day'',
N''Día del mes correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''hour'',
N''Hora del día correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsMarkedAsSpam'', N''minutes'',
N''Minuto correspondiente a la fecha de solicitud.'';



EXEC dbo.usp_SetObjectDescription N''dbo'', N''RepWhatsConversationsUnassigned'',
N''Reporte de conversaciones WhatsApp inbound desasignadas. Incluye conversación, global id, inbound, campaña, números asociados, motivo de desasignación, agente y calendario.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''date'',
N''Fecha y hora de solicitud de la conversación WhatsApp desasignada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''conversationid'',
N''Identificador de la conversación WhatsApp desasignada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''globalid'',
N''Identificador global asociado a la conversación WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''inboundid'',
N''Identificador del inbound asociado a la conversación WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''campaign'',
N''Nombre o descripción del inbound asociado a la conversación WhatsApp.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''associatedPhoneNumberWhatsApp'',
N''Número de WhatsApp asociado al inbound.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''contactPhoneNumberWhatsApp'',
N''Número de WhatsApp del contacto o cliente.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''unassignedBy'',
N''Indicador traducible del origen o motivo de desasignación de la conversación.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''userId'',
N''Identificador del agente asociado a la conversación desasignada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''agentName'',
N''Nombre del agente asociado a la conversación desasignada.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''year'',
N''Año calendario correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''month'',
N''Mes calendario correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''day'',
N''Día del mes correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''hour'',
N''Hora del día correspondiente a la fecha de solicitud.'';

EXEC dbo.usp_SetColumnDescription N''dbo'', N''RepWhatsConversationsUnassigned'', N''minutes'',
N''Minuto correspondiente a la fecha de solicitud.'';
'
    exec (@sql)
------------------------ BEGIN Giovanni Martinez ------------------------
    SET @process = 'Actualizacion de ReportsTotals en reporte 7150 para corregir el tlog'
    
    SET @sql = '
        IF NOT EXISTS (SELECT 1 FROM ReportsTotals WHERE Id = 7150)
        BEGIN
            INSERT INTO ReportsTotals (Id, TotalColumns)
            VALUES (7150, ''special:avrAnswer:(case when sum(acdCalls)>0 then sum(tresp)/sum(acdCalls) else 0 end)|special:avgAbandonTime:(case when sum(abandonedCalls)>0 then sum(tabnd)/sum(abandonedCalls) else 0 end)|sum:acdCalls|special:tPromACD:(case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end)|special:tPromACW:(case when sum(nacw)>0 then sum(tacw)/sum(nacw) else 0 end)|sum:abandonedCalls|max:maxDelay|sum:entryFlow|sum:outFlow|sum:callsOutExt|special:tPromSalidaExt:(case when sum(callsOutExt)>0 then sum(tprosalext)/sum(callsOutExt) else 0 end)|sum:callsDeleteQue|special:tPromElimCola:(case when sum(callsDeleteQue)>0 then sum(tcalque)/sum(callsDeleteQue) else 0 end)|special:avrTimeACD:(case when (case when count(distinct accountUserId)>0 then (((convert(float,sum(tlog))*100)/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end)>0 then (case when convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when (count(distinct accountUserId))>0 then (((convert(float,sum(tlog))*100)/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end))*CONVERT(float_TIMEGROUP))))*100)>100 then 100         else convert(decimal(15,2),((sum(acdCalls) * case when sum(acdCalls)>0 then sum(tacd)/sum(acdCalls) else 0 end) / convert(float,(((case when count(distinct accountUserId)>0 then (((convert(float,sum(tlog))*100)/convert(float,count(distinct accountUserId)*CONVERT(float_TIMEGROUP)))*count(distinct accountUserId))/100 else 0 end))*CONVERT(float_TIMEGROUP))))*100) end)    else 0 end)|special:avrCallsAnswer:(isnull(case when (sum(acdCalls)+sum(abandonedCalls))>0 then convert(decimal(15,2),(convert(float,sum(acdCalls))*100)/(convert(float,sum(acdCalls))+convert(float,sum(abandonedCalls)))) else 0 end,0))'')
        END
        ELSE
        BEGIN
            UPDATE ReportsTotals 
            SET TotalColumns = REPLACE(
                TotalColumns,
                ''convert(float,(sum(tlog)*100))'',
                ''(convert(float,sum(tlog))*100)''
            )
            WHERE Id = 7150
            AND TotalColumns LIKE ''%convert(float,(sum(tlog)*100))%''
        END'
    exec (@sql)
------------------------ END Giovanni Martinez ------------------------

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
