/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/05/23
Description: Archivo mayo 2022, cambios preview

Database: CCenterRia
Required version: 123.27

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
SET @version = 123 --**********actualizar a 123 sin fix
SET @versionfix = 31
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
    BEGIN TRAN

    BEGIN TRY

     set @process = 'AutomaticMessages_V1  Create table ccRIA_AutamaticMessages_VariableDataTags '
    set @sql = 'if not exists(select * from sys.tables where name=''ccRIA_AutamaticMessages_VariableDataTags'') begin
    CREATE TABLE [dbo].[ccRIA_AutamaticMessages_VariableDataTags](
    [LanguageId] [tinyint] NOT NULL,
    [VariableDataTag] [varchar](10) NOT NULL)
end'
    EXEC(@sql)

      set @process = 'AutomaticMessages_V1 Create table ccRIA_AutamaticMessages_TtsTypesTags'
    set @sql = 'if not exists (select * from sys.tables where name=''ccRIA_AutamaticMessages_TtsTypesTags'') begin
CREATE TABLE [dbo].[ccRIA_AutamaticMessages_TtsTypesTags](
    [Id] [tinyint] NOT NULL,
    [TtsTypesTagsSpanish] [varchar](10) NOT NULL,
    [TtsTypesTagsEnglish] [varchar](10) NOT NULL,
    [TtsTypesTagsPortuguese] [varchar](10) NOT NULL)
end


'
    EXEC(@sql)

    set @process = 'AutomaticMessages_V1 insert into ccRIA_AutamaticMessages_VariableDataTags'
    set @sql = 'if not exists(select * from [ccRIA_AutamaticMessages_VariableDataTags]) begin
    insert into [ccRIA_AutamaticMessages_VariableDataTags] values(0,''Dato'')
    insert into [ccRIA_AutamaticMessages_VariableDataTags] values(1,''Data'')
    insert into [ccRIA_AutamaticMessages_VariableDataTags] values(2,''Dado'')
end'
    EXEC(@sql)

      set @process = 'AutomaticMessages_V1 insert into ccRIA_AutamaticMessages_TtsTypesTags'
    set @sql = 'if not exists(select * from  [ccRIA_AutamaticMessages_TtsTypesTags]) begin

insert into [ccRIA_AutamaticMessages_TtsTypesTags] values(0,''Deletreo'',''Spelling'',''Soletração'')
insert into [ccRIA_AutamaticMessages_TtsTypesTags] values(1,''Fecha'',''Date'',''Data'')
insert into [ccRIA_AutamaticMessages_TtsTypesTags] values(2,''Hora'',''Time'',''Hora'')
insert into [ccRIA_AutamaticMessages_TtsTypesTags] values(3,''Moneda'',''Currency'',''Moeda'')
insert into [ccRIA_AutamaticMessages_TtsTypesTags] values(4,''Número'',''Number'',''Número'')
insert into [ccRIA_AutamaticMessages_TtsTypesTags] values(5,''General'',''General'',''Geral'')

end'
    EXEC(@sql)



    set @process = 'AutomaticMessages_V1 DROP PROCEDURE  ccsp_AutomaticMessages'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_AutomaticMessages'')
    begin
        DROP PROCEDURE  ccsp_AutomaticMessages;
    end'
    EXEC(@sql)

    set @process = 'AutomaticMessages_V1 Drop sP ccsp_GalateaAutomaticMessages'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAutomaticMessages'')
    begin
        DROP PROCEDURE  ccsp_GalateaAutomaticMessages;
    end'
    EXEC(@sql)

    set @process = 'AutomaticMessages_V1 Add column ccMsgFiles.msgName'
    set @sql = 'if not exists (select * from sys.columns where name = N''msgName'' and Object_ID = Object_ID(N''ccMsgFiles''))
    begin
        ALTER TABLE ccMsgFiles ADD msgName VARCHAR(40) NULL
    end'
    EXEC(@sql)

     set @process = 'AutomaticMessages_V1 ccRIALog_Operation EDITAR ORDEN DE AUDIO/VARIABLE'
    set @sql = 'if not exists(select * from ccRIALog_Operation where operationType=194) begin
    INSERT INTO ccRIALog_Operation VALUES(194, ''EDITAR ORDEN DE AUDIO/VARIABLE|EDIT AUDIO/VARIABLE ORDER'');
end'
    EXEC(@sql)

    set @process = 'AutomaticMessages_V1 Create SP ccsp_AutomaticMessages'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_AutomaticMessages]
@command smallint, -- 1=Insert, 2=Delete
@msg_id varchar(255)=null,
@campIO_id int=null,
@type tinyint=null,
@campType int=null
as
set nocount on

declare @maxOrden int, @campName varchar(max)
declare @T_all as table (id int, msg_id int)

if @campType=0
    set @campName = (select descripcion from ccInbound where Inbound_id=@campIO_id)
else
    set @campName = (select cam_descripcion from ccCamps where cam_id=@campIO_id)

    If @command=1
     begin
        if @campType=0 
         begin
            insert @T_all 
            select ROW_NUMBER() OVER(ORDER BY A.id ASC) AS Row#,
            A.value from dbo.fn_RIASplitDelimited(@msg_id, '','') A
            left join ccInboundMsgs B on A.Value=B.Msg_id and B.Inbound_id=@campIO_id and B.Type=@type
            where B.Inbound_id  is null

            select @maxOrden =isnull(max(orden),0) from ccInboundMsgs where Inbound_id=@campIO_id and type=@type

            insert into ccInboundMsgs (msg_id, inbound_id, orden, type)
            select B.msg_id, @campIO_id as inbound_id, @maxOrden+B.id as orden,@type as type 
            from  @T_all B
            where msg_id not in(select Msg_id from ccInboundMsgs where Inbound_id=@campIO_id and Type=@type)

            if @@ROWCOUNT > 0
                select @campName
         end

        if @campType=1 
         begin
            insert @T_all 
            select ROW_NUMBER() OVER(ORDER BY A.id ASC) AS Row#,
            A.value from dbo.fn_RIASplitDelimited(@msg_id, '','') A
            left join ccCampsMsgs B on A.Value=B.Msg_id and B.cam_id=@campIO_id and B.Type=@type
            where B.cam_id  is null

            select @maxOrden =isnull(max(orden),0) from ccCampsMsgs where cam_id=@campIO_id and type=@type

            insert into ccCampsMsgs(msg_id, cam_id, orden, type)
            select B.msg_id, @campIO_id as cam_id, @maxOrden+B.id as orden,@type as type 
            from  @T_all B
            where msg_id not in(select Msg_id from ccCampsMsgs where cam_id=@campIO_id and Type=@type)

            if @@ROWCOUNT > 0
                select @campName
         end
     end

    if @command=2
     begin
        if @campType=0
        begin
            delete im from ccInboundMsgs im
            where Msg_id IN(select Value from dbo.fn_RIASplitDelimited(@msg_id, '','')) and Inbound_id=@campIO_id and Type=@type

            insert @T_all
            select ROW_NUMBER() OVER(ORDER BY B.orden ASC)-1 AS Row#,
            b.Msg_id from ccInboundMsgs B
            where B.Inbound_id=@campIO_id and B.Type=@type
            order by orden

            UPDATE ccInboundMsgs SET orden = a.id
            FROM ccInboundMsgs IM
            INNER JOIN @T_all A ON IM.Msg_id = A.msg_id
            WHERE IM.Inbound_id=@campIO_id and IM.Type=@type

            if @@ROWCOUNT > 0
                select @campName
        end

        if @campType=1
        begin
            delete cm from ccCampsMsgs cm
            where Msg_id IN(select Value from dbo.fn_RIASplitDelimited(@msg_id, '','')) and cam_id=@campIO_id and Type=@type

            insert @T_all
            select ROW_NUMBER() OVER(ORDER BY B.orden ASC)-1 AS Row#,
            b.Msg_id from ccCampsMsgs B 
            where B.cam_id=@campIO_id and B.Type=@type
            order by orden

            UPDATE ccCampsMsgs SET orden = a.id
            FROM ccCampsMsgs CM
            INNER JOIN @T_all A ON CM.Msg_id = A.msg_id
            WHERE CM.cam_id=@campIO_id and CM.Type=@type

            if @@ROWCOUNT > 0
                select @campName
        end
     end


set nocount off'
    EXEC(@sql)

    set @process = 'AutomaticMessages_V1 Create SP ccsp_GalateaAutomaticMessages'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAutomaticMessages]
@action as tinyint,
@type as int = null,
@msgFile as varchar(40) = '''',
@Description as varchar(40) = '''',
@length as int = null,
@CampId INT = 0,
@CampType SMALLINT = 0,
@MessageType TINYINT = 0,
@msgIdLst varchar(8000) = null,
@msgName as varchar(40) = '''',
@msg_id int = 0,
@VariableData TINYINT = 0,
@TtsType TINYINT = 0,
@VariableOrder TINYINT = 0,
@MsgRelation varchar(8000) = null

AS

SET NOCOUNT ON

if @action = 1  -- Get audio catalog
begin
    select ISNULL(msgName, msgFile) [MsgName], Descripcion [MsgDescription], msg_id [MsgId] from ccMsgFiles
    where msgFile not like ''TTS|%''
    return (0)
end

if @action = 2
begin
    if EXISTS(select msgName from ccMsgFiles where msgName=@msgName)
    begin
        select 1 as result
    end
    else
    begin 
        insert into ccMsgFiles (msgFile, descripcion, length, msgName) values (@msgFile, @Description, @length, @msgName)
        select 0 as result
    end 
    
end 

if @action = 3
begin
    select msg_id from ccMsgFiles where msgName=@msgName
end

IF @action = 4 -- Get Assigned Messages by Campaign Id and Campaign Type
BEGIN
    DECLARE @CampaignMessagesRelation TABLE (MessageType TINYINT, MessageOrder TINYINT, MessageFile VARCHAR(MAX), 
                                             MessageId INT, MessageDescription VARCHAR(MAX), Queue BIT)
    IF @CampType = 0  -- Inbound Campaigns
        BEGIN
            INSERT INTO @CampaignMessagesRelation (MessageType, MessageOrder, MessageFile, MessageId, MessageDescription, Queue) 
            EXEC ccsp_RIAADMInboundMsgs @Command = 1,@Inbound_id = @CampId
        END
    ELSE              -- Outbound Campaigns
        BEGIN 
            INSERT INTO @CampaignMessagesRelation (MessageType, MessageOrder, MessageFile, MessageId, MessageDescription)
            EXEC ccsp_RIAADMCampMsgs @Command = 1, @cam_id = @CampId
            UPDATE @CampaignMessagesRelation SET Queue = 0
        END
    SELECT * FROM @CampaignMessagesRelation WHERE MessageType = @MessageType
END 

IF @action = 5 -- Delete audio message
begin
    if exists(select Msg_id from ccInboundMsgs where Msg_id in (select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')))
    begin
        select 0 as result
        return(0)
    end
    if exists(select Msg_id from ccCampsMsgs where Msg_id in (
select B.msg_id from dbo.fn_RIASplitDelimited(@msgIdLst, '','') A
inner join ccMsgFiles B on A.Value=B.msg_id 
where msgFile not like ''TTS|%''
)
)
    begin
        select 0 as result
        return(0)
    end
    
    delete A from ccCampsMsgs A where Msg_id in (
    select B.msg_id from dbo.fn_RIASplitDelimited(@msgIdLst, '','') A
    inner join ccMsgFiles B on A.Value=B.msg_id 
    where msgFile like ''TTS|%'')

    delete ccMsgFiles Where msg_id in (select value from dbo.fn_RIASplitDelimited(@msgIdLst, '',''))
    select 1 as result
    return(0)
end 

if @action = 6
BEGIN
    if @type = 0
        BEGIN
            update ccMsgFiles set Descripcion = @Description, msgName = @msgName where msg_id = @msg_id
        END
    else
        BEGIN
            update ccMsgFiles set Descripcion = @Description, msgName = @msgName, msgFile = @msgFile where msg_id = @msg_id
        END
END 

if @action = 7
BEGIN
    select msg_id as msgId, msgName as MsgName, Descripcion as MsgDescription from ccMsgFiles where msg_id = @msg_id
END

IF @action = 8
BEGIN
    DECLARE @Language TINYINT = (SELECT valor from ccSettings where setting_id = 27)
    DECLARE @TempMsgFile VARCHAR(10) = (''TTS'' + ''|'' + CONVERT(VARCHAR(2), @TtsType) + ''|'' + CONVERT(VARCHAR(2), @VariableData))
    SET @Description = (SELECT CASE WHEN @Language = 0 THEN TtsTypesTagsSpanish 
                                    WHEN @Language = 1 THEN TtsTypesTagsEnglish 
                                    ELSE TtsTypesTagsPortuguese END 
                        FROM ccRIA_AutamaticMessages_TtsTypesTags 
                        WHERE Id = @VariableData) 
                        + ''|'' + 
                        (SELECT VariableDataTag FROM ccRIA_AutamaticMessages_VariableDataTags 
                        WHERE LanguageId = @Language)
                        + CONVERT(VARCHAR(2), @VariableData) 
                        + ''|'' + CONVERT(VARCHAR(2), @CampId) 

    EXEC ccsp_RIAADMCampMsgs @Command = 3, @cam_id = @CampId, @order = @VariableOrder,@type=8,@msgFile=@TempMsgFile,@description=@Description   

    
END

IF @action = 9
BEGIN
    select msgFile [MsgFile] from ccMsgFiles where msg_id in (select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')) and msgFile not like ''TTS|%''
END

IF @action = 10
BEGIN
    IF @CampType = 0  -- Inbound Campaigns
        BEGIN
            UPDATE b SET b.orden = a.Id - 1 FROM dbo.fn_RIASplitDelimited(@MsgRelation, '','') a INNER JOIN ccInboundMsgs b ON b.Inbound_id = @CampId AND b.Type = @MessageType AND b.Msg_id = a.Value 
        END
    ELSE              -- Outbound Campaigns
        BEGIN 
            UPDATE b SET b.orden = a.Id - 1 FROM dbo.fn_RIASplitDelimited(@MsgRelation, '','') a INNER JOIN ccCampsMsgs b ON b.cam_id = @CampId AND b.Type = @MessageType AND b.Msg_id = a.Value 
        END
END


SET NOCOUNT OFF'
    EXEC(@sql)

    set @process = 'AutomaticMessages_V1 '
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCLog] @option TINYINT, @areaName VARCHAR(50) = NULL, @operationType TINYINT = NULL, @login VARCHAR(20) = NULL, @moduleId INT = NULL, @value VARCHAR(250) = NULL, @target VARCHAR(250) = NULL, @operationDateIni SMALLDATETIME = NULL, @operationDateFin SMALLDATETIME = NULL, @top INT = 0
AS
SET NOCOUNT ON

IF @option = 1 -- muestra todo
BEGIN
    SELECT log_id, areaName, operationDate, operationType, LOGIN, module_id, value, target
    FROM ccRIALog WITH (NOLOCK)

    RETURN (0)
END

IF @option = 2 -- insert
BEGIN
    DECLARE @areaNameValue AS VARCHAR(50)
    DECLARE @loginNameValue AS VARCHAR(50)

    SET @areaNameValue = isnull(@areaName,'''')

    IF (left(@areaName, 1) = ''!'')
    BEGIN
        SELECT @areaNameValue = areaName
        FROM dbo.ccRIACat_Areas AS AREAS WITH (NOLOCK)
        WHERE AREAS.IDArea = right(@areaName, len(@areaName) - 1)
    END

    SET @loginNameValue = @login

    IF (left(@login, 1) = ''!'')
    BEGIN
        SELECT @loginNameValue = Login, 
        @areaNameValue = case datalength(@areaNameValue) when 0 then isnull(AreaName,'''') else @areaNameValue end
        FROM ccUsers us (nolock) left join ccRIACat_Areas area (nolock) on area.IDArea=us.IDArea
        WHERE [Login] = right(@login, len(@login) - 1)
    END

    INSERT INTO ccRIALog
    VALUES (@areaNameValue, GETDATE(), @operationType, @loginNameValue, @moduleId, @value, @target)

    RETURN (0)
END

DECLARE @lang TINYINT

SELECT @lang = valor
FROM ccsettings
WHERE setting_id = 27

IF @option = 3 -- muestra información por filtros (System>Log) // Fechas
BEGIN
    SET ROWCOUNT @top

    SELECT L.log_id, L.areaName, L.operationDate, CASE @lang WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion) + 1, len(o.descripcion)) END operationType, L.LOGIN, CASE @lang WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion) + 1, len(m.descripcion)) END module_id, CASE WHEN t.targetT IS NULL THEN L.target ELSE CASE @lang WHEN 0 THEN t.es WHEN 2 THEN t.pt ELSE t.en END END AS target, CASE WHEN v.valueT IS NULL THEN L.value ELSE CASE @lang WHEN 0 THEN v.es WHEN 2 THEN v.pt ELSE v.en END END AS value
    FROM CCRIALOG L
    JOIN ccRIALog_Module M WITH (INDEX (IX_ccRIALog_Module)) ON L.module_id = M.module_id
    JOIN ccRIALog_Operation O WITH (INDEX (IX_ccRIALog_Operation)) ON L.operationType = O.operationType
    LEFT JOIN targetRecord t ON t.targetT = L.target
    LEFT JOIN valueRecord v ON v.valueT = L.value
    WHERE L.operationType = CASE isnull(@operationType, 0) WHEN 0 THEN L.operationType ELSE @operationType END AND L.LOGIN = CASE isnull(@login, '''') WHEN '''' THEN L.LOGIN ELSE @login END AND L.module_id = CASE isnull(@moduleId, 0) WHEN 0 THEN L.module_id ELSE @moduleId END AND L.target = CASE isnull(@target, '''') WHEN '''' THEN L.target ELSE @target END AND L.operationDate >= CASE WHEN isnull(@operationDateIni, '' 19000101 '') <> '' 19000101 '' AND isnull(@operationDateFin, '' 19000101 '') <> '' 19000101 '' THEN dateadd(minute, - 1, @operationDateIni) ELSE L.operationDate END AND L.operationDate <= CASE WHEN isnull(@operationDateIni, '' 19000101 '') <> '' 19000101 '' AND isnull(@operationDateFin, '' 19000101 '') <> '' 19000101 '' THEN dateadd(minute, 1, @operationDateFin) ELSE L.operationDate END
    ORDER BY L.operationDate DESC

    RETURN (0)
END

IF @option = 4 -- Catalogo de modulos
BEGIN
    SELECT m.module_id, o.operationType, CASE @lang WHEN 0 THEN SUBSTRING(m.descripcion, 1, CHARINDEX(''|'', m.descripcion) - 1) ELSE SUBSTRING(m.descripcion, CHARINDEX(''|'', m.descripcion) + 1, len(m.descripcion)) END AS mDescripcion, CASE @lang WHEN 0 THEN SUBSTRING(o.descripcion, 1, CHARINDEX(''|'', o.descripcion) - 1) ELSE SUBSTRING(o.descripcion, CHARINDEX(''|'', o.descripcion) + 1, len(o.descripcion)) END AS oDescripcion
    FROM ccRIALog_Operation o WITH (INDEX (IX_ccRIALog_Operation))
    JOIN ccRIALog_Cat_Relation r ON o.operationType = r.operationType
    JOIN ccRIALog_Module m WITH (INDEX (IX_ccRIALog_Module)) ON r.module_id = m.module_id
    
    UNION
    
    SELECT 0, - 1, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, '' - ''
    
    UNION
    
    SELECT 0, 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
    
    UNION
    
    SELECT module_id, 0, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
    FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module))
    
    UNION
    
    SELECT module_id, - 1, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion, '' - ''
    FROM ccRIALog_Module WITH (INDEX (IX_ccRIALog_Module))
    ORDER BY mDescripcion, oDescripcion

    RETURN (0)
END

IF @option = 5 -- Catalogo de operaciones
BEGIN
    SELECT operationType, CASE @lang WHEN 0 THEN SUBSTRING(descripcion, 1, CHARINDEX(''|'', descripcion) - 1) ELSE SUBSTRING(descripcion, CHARINDEX(''|'', descripcion) + 1, len(descripcion)) END AS descripcion
    FROM ccRIALog_Operation WITH (INDEX (IX_ccRIALog_Operation))
    
    UNION
    
    SELECT 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
    ORDER BY 2

    RETURN (0)
END

SET NOCOUNT OFF
'
    EXEC(@sql)

   
    set @process = 'AutomaticMessages_V1 '
    set @sql = ''
    EXEC(@sql)

  
        /* End script release */
        /* Upgrade database version (use your own script to do it) */
        --exec ccsp_getVersion 'BD', @version
        --EXEC ccsp_getVersion 'BDF', @versionFix

        COMMIT TRAN
    END TRY

    BEGIN CATCH
        /* Error generated based on sintax */
        SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

        RAISERROR (@errorGenerated, 11, 1)

        ROLLBACK TRAN
    END CATCH
END


