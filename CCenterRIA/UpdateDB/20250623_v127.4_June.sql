/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Marco Antonio Chagolla
Date: 2025/06/23
Description: Release 127.20250623.0.0
Database: CCenterRia
Required version: 127.2
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
SET @version = 127 --**********actualizar a 124 sin fix
SET @versionfix = 4
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'
EXEC @actualVersionFix = ccsp_getVersion 'BDF'
SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;
SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;
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

	---------------------- BEGIN IGC ----------------------
	SET @process = 'K070051, K070208, K070219 - add columns to ccInboundExtend'
	SET @sql = '
		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''IsCallTranscriptionEnabled'' AND Object_ID = Object_ID(N''ccInboundExtend''))
		BEGIN
			ALTER TABLE ccInboundExtend ADD IsCallTranscriptionEnabled BIT NULL
		END

		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''TransferToHumanAgents'' AND Object_ID = Object_ID(N''ccInboundExtend''))
		BEGIN
			ALTER TABLE ccInboundExtend ADD TransferToHumanAgents INT NULL
		END

		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''TransferOnSuccessfulHandling'' AND Object_ID = Object_ID(N''ccInboundExtend''))
		BEGIN
			ALTER TABLE ccInboundExtend ADD TransferOnSuccessfulHandling INT NULL
		END

		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''TransferOnFallback_ExternalNumber'' AND Object_ID = Object_ID(N''ccInboundExtend''))
		BEGIN
			ALTER TABLE ccInboundExtend ADD TransferOnFallback_ExternalNumber VARCHAR(10) NULL;
		END
		
		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''TransferOnFallback_DirectoryId'' AND Object_ID = Object_ID(N''ccInboundExtend''))
		BEGIN
			ALTER TABLE ccInboundExtend ADD TransferOnFallback_DirectoryId SMALLINT NULL;
			ALTER TABLE ccInboundExtend ADD CONSTRAINT FK_ccIBX_Fallback_Directory FOREIGN KEY (TransferOnFallback_DirectoryId) REFERENCES dbo.telefonosTransferencia(numtra_id);
		END

		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''TransferOnFallback_Mode'' AND Object_ID = Object_ID(N''ccInboundExtend''))
		BEGIN
			ALTER TABLE ccInboundExtend ADD TransferOnFallback_Mode BIT NULL CONSTRAINT DF_ccIBX_Fallback_Mode DEFAULT(0);
		END

		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''TransferOnFallback_TimeoutSec'' AND Object_ID = Object_ID(N''ccInboundExtend''))
		BEGIN
			ALTER TABLE ccInboundExtend ADD TransferOnFallback_TimeoutSec SMALLINT NULL CONSTRAINT DF_ccIBX_Fallback_TimeoutSec DEFAULT(60);
		END

		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''TransferOnSuccess_ExternalNumber'' AND Object_ID = Object_ID(N''ccInboundExtend''))
		BEGIN
			ALTER TABLE ccInboundExtend ADD TransferOnSuccess_ExternalNumber VARCHAR(10) NULL;
		END

		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''TransferOnSuccess_DirectoryId'' AND Object_ID = Object_ID(N''ccInboundExtend''))
		BEGIN
			ALTER TABLE ccInboundExtend ADD TransferOnSuccess_DirectoryId SMALLINT NULL;
			ALTER TABLE ccInboundExtend ADD CONSTRAINT FK_ccIBX_Success_Directory FOREIGN KEY (TransferOnSuccess_DirectoryId) REFERENCES dbo.telefonosTransferencia(numtra_id);
		END

		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''TransferOnSuccess_Mode'' AND Object_ID = Object_ID(N''ccInboundExtend''))
		BEGIN
			ALTER TABLE ccInboundExtend ADD TransferOnSuccess_Mode BIT NULL CONSTRAINT DF_ccIBX_Success_Mode DEFAULT(0);
		END

		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''TransferOnSuccess_TimeoutSec'' AND Object_ID = Object_ID(N''ccInboundExtend''))
		BEGIN
			ALTER TABLE ccInboundExtend ADD TransferOnSuccess_TimeoutSec SMALLINT NULL CONSTRAINT DF_ccIBX_Success_TimeoutSec DEFAULT(60);
		END
	'
    EXEC(@sql)

	SET @process = 'K070051, K070208, K070219 - add operation create ai inbound campaign'
	SET @sql = '
		IF NOT EXISTS(SELECT * FROM ccGalateaOperations WHERE OperationId = 137) BEGIN 
			INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) VALUES (137, ''Crear campaña (llamada de entrada IA)'', ''Create campaign (AI inbound call)'', ''Criar campanha (chamada de entrada IA)'');
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId) VALUES (3, 137);
		END
	'
    EXEC(@sql)

	SET @process = 'K070051, K070208, K070219 - add identifier and relation to table-column'
	SET @sql = '
		IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_CALL_TRANSCRIPTION'') BEGIN 
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''IN_CALL_IA_CALL_TRANSCRIPTION'', ''Mostrar transcripción de llamadas en Buscador'', ''Show call transcripts in Finder'', ''Mostrar transcri��es de chamadas em Localizador'')
		END

		IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''IN_CALL_IA_CALL_TRANSCRIPTION'' AND tableName = ''ccInboundExtend'') BEGIN 
			INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
			VALUES (''IN_CALL_IA_CALL_TRANSCRIPTION'',''ccInboundExtend'',''IsCallTranscriptionEnabled'')
		END

		IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_TO_HUMAN_AGENTS'') BEGIN 
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''IN_CALL_IA_TRANSFER_TO_HUMAN_AGENTS'', ''Transferencia a agentes humanos'', ''Live agent transfer'', ''Transferência para agentes humanos'')
		END
		IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''IN_CALL_IA_TRANSFER_TO_HUMAN_AGENTS'' AND tableName = ''ccInboundExtend'') BEGIN 
			INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
			VALUES (''IN_CALL_IA_TRANSFER_TO_HUMAN_AGENTS'',''ccInboundExtend'',''TransferToHumanAgents'')
		END

		IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''IN_CALL_IA_TRANSFER_ON_SUCCESSFUL_HANDLING'') BEGIN 
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''IN_CALL_IA_TRANSFER_ON_SUCCESSFUL_HANDLING'', ''Transferencia por gestión exitosa'', ''Successful interaction transfer'', ''Transferência de interação bem-sucedida'')
		END
		IF NOT EXISTS(SELECT * FROM relationTableColumnIdentifiers WHERE Identifiers = ''IN_CALL_IA_TRANSFER_ON_SUCCESSFUL_HANDLING'' AND tableName = ''ccInboundExtend'') BEGIN 
			INSERT INTO relationTableColumnIdentifiers (Identifiers, tableName, colunName)
			VALUES (''IN_CALL_IA_TRANSFER_ON_SUCCESSFUL_HANDLING'',''ccInboundExtend'',''TransferOnSuccessfulHandling'')
		END
	'
    EXEC(@sql)

	SET @process = 'K070051, K070208, K070219 - Add multiple identifiers'
	SET @sql = '
		IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_CAMPAIGN'') BEGIN 
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''COMMON_CAMPAIGN'', ''campaña'', ''campaign'', ''campanha'')
		END
		IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_DIRECTORY'') BEGIN 
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''COMMON_DIRECTORY'', ''directorio '', ''transfer list '', ''catálogo '')
		END
		IF NOT EXISTS(SELECT * FROM ccGalateaIdentifiers WHERE Description = ''COMMON_EXTERNAL_NUMBER'') BEGIN 
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''COMMON_EXTERNAL_NUMBER'', ''número externo '', ''external number '', ''número externo '')
		END
	'
    EXEC(@sql)

	SET @process = 'K070051, K070208, K070219 - Delete scalar fuction GetAIVoiceCampaignHistory'
	SET @sql = '
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''dbo.GetAIVoiceCampaignHistory'') AND type IN (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
	BEGIN
		DROP FUNCTION dbo.GetAIVoiceCampaignHistory
	END'
	EXEC(@sql)
	SET @process = 'K070051, K070208, K070219 - Create scalar fuction GetAIVoiceCampaignHistory'
	SET @sql = '
CREATE FUNCTION GetAIVoiceCampaignHistory (@value VARCHAR(MAX), @lang INT)
RETURNS VARCHAR (MAX)
AS
BEGIN

	DECLARE @stringFormated VARCHAR(MAX) = '''';

	SELECT 
		@stringFormated = STRING_AGG(
			CASE 
				WHEN cgi.Description IS NULL THEN res.Value
				WHEN cgi.Description IS NOT NULL AND @lang = 0 THEN cgi.TagEs 
				WHEN cgi.Description IS NOT NULL AND @lang = 2 THEN cgi.TagPt 
				WHEN cgi.Description IS NOT NULL AND @lang > 0 AND @lang < 2 THEN cgi.TagEn
			END
		, ''('') + '')''
	FROM dbo.fn_RIASplitDelimited(@value, ''<'') res
	LEFT JOIN ccGalateaIdentifiers cgi ON cgi.Description = res.Value

	RETURN @stringFormated
END
	'
	EXEC(@sql)

	SET @process = 'K070051, K070208, K070219 - delete sp ccsp_GalateaChangeHistory'
	SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_GalateaChangeHistory'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_GalateaChangeHistory
	END'
	EXEC(@sql)

	SET @process = 'K070051, K070208, K070219 - create sp ccsp_GalateaChangeHistory'
	SET @sql = '
CREATE PROCEDURE ccsp_GalateaChangeHistory
@option TINYINT,
@loginLst VARCHAR(max) = NULL,
@moduleWithOperation varchar(max) = NULL,
@operationDateIni SMALLDATETIME = NULL,
@operationDateFin SMALLDATETIME = NULL,
@top INT = 0
AS
SET NOCOUNT ON

DECLARE @lang TINYINT

SELECT @lang = valor
FROM ccsettings
WHERE setting_id = 27

IF @option = 1 -- Catalogo de modulos
BEGIN
	WITH Catalog AS(
	SELECT m.ModuleId as module_id, o.OperationId as operationType, 
	CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS mDescripcion, 
	CASE @lang WHEN 0 THEN OpTagEs WHEN 2 THEN OpTagPt ELSE OpTagEn END AS oDescripcion
	FROM ccGalateaOperations o WITH (INDEX (IX_ccGalateaOperations_Op))
	JOIN ccGalateaModOpRelation r ON o.OperationId = r.OperationId
	JOIN ccGalateaModules m WITH (INDEX (IX_ccGalateaModules_Mod)) ON r.ModuleId = m.ModuleId --WITH (INDEX (IX_ccGalateaModules_Mod))

	UNION

	SELECT 0, - 1, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, '' - ''
	
	UNION

	SELECT 0, 0, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END, CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END

	UNION

	SELECT ModuleId as module_id, 0, CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS descripcion, 
	CASE @lang WHEN 0 THEN '' - TODAS - '' ELSE '' - ALL - '' END
	FROM ccGalateaModules WITH (INDEX (IX_ccGalateaModules_Mod))

	UNION

	SELECT ModuleId as module_id, - 1 , CASE @lang WHEN 0 THEN MTagEs WHEN 2 THEN MTagPt ELSE MTagEn END AS descripcion, '' - ''
	FROM ccGalateaModules WITH (INDEX (IX_ccGalateaModules_Mod)))

	SELECT module_id,operationType,mDescripcion,oDescripcion 
	FROM Catalog
	ORDER BY mDescripcion, oDescripcion

	RETURN (0)
END

IF @option = 2 -- Muestra informacion por filtros
BEGIN

	declare @sql as nvarchar(max)
	DECLARE @table TABLE(id int,value varchar(max))
	declare @id int
	declare @moduleId varchar(max)
	declare @operationLst varchar(max)
	declare @query varchar(max) = '' and (''
	declare @value varchar(max)
	declare @first int = 1
	declare @pos int

	insert into @table select * from dbo.fn_RIASplitDelimited(cast(isnull(@moduleWithOperation,'''') as varchar(max)), '','')
	while exists(select * from @table)
	begin
		select top 1 @id = id, @value = value from @table
		set @pos = charindex('':'', @value)
		if(@pos <> 0)
		begin
			set @moduleId = substring(@value, 1, @pos-1)
			set @operationLst = replace(substring(@value, @pos+1, len(@value)), ''-'', '','')
			if(@first = 1)
			begin
				set @query = @query + ''l.moduleId='' + @moduleId + '' and l.operationId in ('' + @operationLst + '')''
				set @first = 0
			end
			else
			begin
				set @query = @query + '' or l.moduleId='' + @moduleId + '' and l.operationId in ('' + @operationLst + '')''
			end
		end

		delete @table where id = @id
	end
	set @query = @query + '')''


	SET ROWCOUNT @top

	set @sql =
	''DECLARE @tableLogin TABLE(id int,value varchar(255))
	insert into @tableLogin  select * from dbo.fn_RIASplitDelimited('''''' + cast(isnull(@loginLst,'''') as varchar(max)) + '''''','''','''')

	SELECT L.LogId as log_id, L.Area as areaName, L.ActivityDate as operationDate,
	CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN O.OpTagEs WHEN 2 THEN O.OpTagPt ELSE O.OpTagEn END operationType,
	L.LOGIN,
	CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN M.MTagEs WHEN 2 THEN M.MTagPt ELSE M.MTagEn END module_id,
	CASE WHEN t.targetT IS NULL THEN L.target ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN t.es WHEN 2 THEN t.pt ELSE t.en END END AS target,
	CASE WHEN i.description IS NULL THEN L.Identifier ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN i.TagEs WHEN 2 THEN i.TagPt ELSE i.TagEn END END +
	CASE WHEN L.Identifier<>'''''''' AND L.Value<>'''''''' THEN '''': '''' ELSE '''''''' END +

	CASE WHEN V.description IS NULL 
		THEN 
			CASE 
				WHEN L.Identifier<>'''''''' AND (L.Identifier LIKE ''''COMMON_DELETE_SCHEDULE%'''' OR L.Identifier LIKE ''''COMMON_ADD_SCHEDULE%'''' OR L.Identifier LIKE ''''COMMON_DATE%'''')
					THEN dbo.GetDateByLangHistory(L.value,''+cast(@lang as varchar(5)) +'')''+
				''WHEN L.Identifier<>'''''''' AND L.Identifier = ''''OUT_SIP_IDENTIFIER'''' THEN dbo.GetSipLangHistory(L.value,''+cast(@lang as varchar(5)) +'')''+
				''WHEN L.Identifier<>'''''''' AND L.Identifier = ''''T&EDIT_TEMPLATE_BUTTONS'''' THEN dbo.GetMetaButtonTemplateHistory(L.value,''+CAST(@lang AS VARCHAR(5))+'')''+
				''WHEN L.Identifier<>'''''''' AND L.Identifier = ''''IN_CALL_IA_TRANSFER_TO_HUMAN_AGENTS'''' THEN dbo.GetAIVoiceCampaignHistory(L.value,''+CAST(@lang AS VARCHAR(5))+'')''+
				''WHEN L.Identifier<>'''''''' AND L.Identifier = ''''IN_CALL_IA_TRANSFER_ON_SUCCESSFUL_HANDLING'''' THEN dbo.GetAIVoiceCampaignHistory(L.value,''+CAST(@lang AS VARCHAR(5))+'')''+
		''ELSE L.value END
		ELSE CASE '' + cast(@lang as varchar(5)) + '' WHEN 0 THEN v.TagEs WHEN 2 THEN v.TagPt ELSE v.TagEn END END AS value

	FROM ccGalateaActivityLog L
	JOIN ccGalateaModules M WITH (INDEX (IX_ccGalateaModules_Mod)) ON L.ModuleId = M.ModuleId
	JOIN ccGalateaOperations O WITH (INDEX (IX_ccGalateaOperations_Op)) ON L.OperationId = O.OperationId
	LEFT JOIN targetRecord t ON t.targetT = L.target
	LEFT JOIN ccGalateaIdentifiers i ON i.Description = L.Identifier
	LEFT JOIN ccGalateaIdentifiers v ON v.Description = L.Value
	LEFT JOIN ccUsers CU ON CU.Login = L.login
	WHERE 1=1 
	AND
	CU.TipoUser_id = 2''
	+
	case isnull(@loginLst, '''') when '''' then '''' else
	'' AND L.LOGIN in (select value from @tableLogin) ''
	END
	+
	case isnull(@moduleWithOperation, '''') when '''' then '''' else
	@query
	end
	+ case ISNULL(@operationDateIni, '''') when '''' then '''' else
	''AND L.ActivityDate >= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull('''''' + convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, -1, '''''' + convert(varchar(19), @operationDateIni, 121) + '''''') ELSE L.ActivityDate END ''
	+ '' AND L.ActivityDate <= CASE WHEN isnull(''''''+ convert(varchar(19), @operationDateIni, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' AND isnull(''''''+ convert(varchar(19), @operationDateFin, 121) + '''''', '''' 19000101 '''') <> '''' 19000101 '''' THEN dateadd(minute, 1, '''''' + convert(varchar(19), @operationDateFin, 121) + '''''') ELSE L.ActivityDate END''
	end
	+
	'' ORDER BY L.ActivityDate DESC''
	execute sp_executesql @sql
	--print @sql
END
SET NOCOUNT OFF
	'
    EXEC(@sql)


	SET @process = 'K070051, K070208, K070219 - delete sp ccsp_RIA_ABCACDGroups'
	SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_RIA_ABCACDGroups'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_RIA_ABCACDGroups
	END
	'
    EXEC(@sql)

	SET @process = 'K070051, K070208, K070219 - create sp ccsp_RIA_ABCACDGroups'
	SET @sql = '
CREATE PROCEDURE ccsp_RIA_ABCACDGroups
@option smallint,
@userid int,
@descripcion varchar(40),
@inbound_id varchar(1000),
@idarea smallint = null,
@frame tinyint,
@Prefijo varchar(40) = null,
@MediaType int = 0,
@chatDomain varchar(500) = null
AS
SET NOCOUNT ON

declare @new_inbound_id smallint, @graph_id smallint

if @option = 0 -- all acd
    begin
        select acd.inbound_id, acd.descripcion, isnull(acd.idarea,0) as idarea,
    isnull(areas.areaname,'''') as areaname
        from ccinbound as acd with(nolock)
        left join dbo.ccriacat_areas as areas with(nolock) on acd.idarea = areas.idarea
        return(0)
    end

if @option = 1 -- select acd
    begin
        select a1.inbound_id, a1.descripcion, a3.frame, a1.showcalifwnd, a1.starttimeronhangup, isnull(a1.idarea,0)
        ,case when ext.SurveyCamId is not null or ext.SurveyCamId >0 then isnull(ext.SurveyCamId,0) else isnull(a1.cam_id,0) end cam_id,
        prefijo as Prefijo
        from ccinbound a1 
        inner join ccriainboundgraph a2 on (a1.inbound_id=a2.inbound_id)
        inner join ccriagraphics a3 on (a2.graphic_id=a3.graphic_id)
        left join ccInboundExtend  ext on ext.Inbound_id=a1.Inbound_id
        where a3.type_id = 1 and a1.inbound_id = (cast(@inbound_id as int))
        order by descripcion
        return(0)
    end

if @option = 2 -- insert
    begin
                 
    if exists (select descripcion from ccinbound where descripcion = @descripcion and status = 1)
    begin
        select -1   -- ''Nombre en uso''
        return(0)
    end
                    
    if (@MediaType = 1 and @chatDomain <> '''' and @chatDomain is not null)
    begin
        if exists (select 1 from ccInbound where chatDomain = @chatDomain and Status = 1)
        begin
            select -3   -- ''Domain in use''
            return(0)
        end
    end
                    
    if @idarea = 0
        set @idarea = null

    declare @pref int
    select  @pref = valor from ccSettings where setting_id = 201
    if (@pref = 0)
        set @Prefijo = ''''
                    
    DECLARE @tempDesc VARCHAR(40);
    SET @tempDesc = CASE WHEN @MediaType = 5 THEN @descripcion ELSE @descripcion+''Tmp'' END;

    insert into ccinbound (descripcion, starttimeronhangup, idarea, showcalifwnd,prefijo)
    select @tempDesc, 1, @idarea,case when exists(select calif_id from cctipocalif where Calif_Status = 1) then 1 else 0 end, @Prefijo
                    
    if @@rowcount = 1
        select @new_inbound_id = inbound_id from ccinbound where descripcion = @tempDesc and status = 1
    else
    begin
        select -2 -- Error al insertar
        return(0)
    end

    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @new_inbound_id, @userId= @userid

    UPDATE ccInbound SET descripcion = @descripcion, ShowCalifWnd = case when exists(select calif_id from cctipocalif where Calif_Status = 1) then 1 else 0 end
    WHERE Inbound_id = @new_inbound_id

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    Create table #ccInboundTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )

    EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @new_inbound_id, @userId = @userid, @tableTemp=''#ccInboundTable'';  
                    
    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        CASE 
            WHEN @MediaType = 5 THEN 40
            WHEN @MediaType = 1 THEN 63
			WHEN @MediaType = 11 THEN 137
            ELSE 60 END, 
        3, 
        CASE WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
                CASE WHEN @MediaType = 5 THEN ''IN_SHOW_DISPOSITIONS_WHATS'' ELSE  CCIT.identifierInfo END
                WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN ''''
        ELSE
            CCIT.identifierInfo
        END,
        CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
            CASE 
                WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN ''''
                ELSE CCIT.dataInfo END
        ELSE '''' END, 
        (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @new_inbound_id)
    FROM #ccInboundTable AS CCIT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @new_inbound_id, @userId = @userid;

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    insert into cccalifcamp (calif_id, cam_id, tipo) select calif_id, @new_inbound_id, 0 from cctipocalif where CanReprogram=0 and Calif_Status = 1

    if not exists (select msg_id from ccInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccMsgFiles where msgFile like ''%\Default%''))
    begin
        insert into ccInboundMsgs (msg_id, inbound_id, orden, type, queue)
        select msg_id, @new_inbound_id, 0, cast(substring(msgFile, 19,3) as integer),0 from ccMsgFiles where msgFile like ''%\Default%''
    end

    if not exists (select msg_id from ccRIAChatInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccRIAChatMsg where Descripcion like ''%\Default%''))
    begin
        insert into ccRIAChatInboundMsgs (msg_id, inbound_id, orden, type)
        select msg_id, @new_inbound_id, 0, cast(substring(Descripcion, 19,3) as integer) from ccRIAChatMsg where Descripcion like ''%\Default%''
    end

    if not exists(select frame from ccriagraphics where frame = @frame and type_id = 1)
        insert into ccriagraphics (frame,type_id) values (@frame,1)
                    
    select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
                     
    insert into ccriainboundgraph(Inbound_id,graphic_id) values(@new_inbound_id,@graph_id)
    select @new_inbound_id
    return(0) 
    end

if @option = 3 -- update
    begin
        if not exists (select frame from ccriagraphics where frame=@frame and type_id=1)
        insert into ccriagraphics (frame, type_id) values (@frame, 1)

        select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
        update ccinbound set descripcion = @descripcion where inbound_id = (cast(@inbound_id as int))
        update ccriainboundgraph set graphic_id = @graph_id where inbound_id = (cast(@inbound_id as int))
        return(0)
    end

if @option = 4 -- delete
    begin
        delete cccalifcamp where cam_id = @inbound_id and tipo = 0
        delete ccinboundhorarios where inbound_id = @inbound_id
        delete ccriainboundgraph where inbound_id = @inbound_id
        delete ccInboundMsgs where inbound_id = @inbound_id
        delete ccRIAChatInboundMsgs where inbound_id = @inbound_id
        delete ccSkills where inbound_id = @inbound_id
        return(0)
    end

if @option = 5 -- asignar campana a ACD
    begin
    if not exists (select inbound_id from ccInbound where inbound_id=@inbound_id) or
        (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
        not exists (select cam_id from ccCamps where cam_id=@descripcion))
        begin
        select -3 -- Campana o ACD invalido
        return(0)
        end
                    
    declare @cam_id int,@oldCamId int

    if @descripcion=0 begin

        set @descripcion = null
        --quitamos calificaciones relacionadas a la campana
        DELETE c FROM ccCalifCamp c
        INNER JOIN ccTipoCalif ci ON  ci.calif_id=c.calif_id
        Where c.cam_id=@inbound_id and ci.CanReprogram =1
        --quitamos subcalificaciones relacionadas a la calificacion
        DELETE rel FROM ccCalifCamp c
        INNER JOIN ccTipoCalif ci ON  ci.calif_id=c.calif_id and tipo=0
        inner join cctipoSubCalifRel rel on rel.calif_id=ci.calif_id and rel.tipoSubRel=1
        left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
        Where c.cam_id=@inbound_id and sb.canReprogram=1
                         
            update ccInbound set cam_id = 0 where Inbound_id = @inbound_id       
            update ccInboundExtend set SurveyCamId = 0 where Inbound_id = @inbound_id       
    end
    set @cam_id=@descripcion
    if @cam_id is null set @cam_id=0
                    


    if exists( select * from ccCamps where cam_id=@cam_id and ( 
    (CampType is null or CampType not in(5,7,8) ) and callsBySurvey=0 and ivrScript=0
                    
    )) begin
        update ccInbound set cam_id = @cam_id where Inbound_id = @inbound_id
    end
    else begin
        update ccInboundExtend set SurveyCamId = @cam_id where Inbound_id = @inbound_id
    end
                        
    if @@rowcount=0
        select -4 -- Error al actualizar

    return(0)
    end
set nocount off
	'
    EXEC(@sql)

	SET @process = 'K070051, K070208, K070219 - delete sp ccsp_RIAUpdateACDConfigExtend'
	SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_RIAUpdateACDConfigExtend'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_RIAUpdateACDConfigExtend
	END
	'
    EXEC(@sql)

	SET @process = 'K070051, K070208, K070219 - create sp ccsp_RIAUpdateACDConfigExtend'
	SET @sql = '
CREATE PROCEDURE ccsp_RIAUpdateACDConfigExtend
	@inbound_id smallint,
	@recordCalls tinyint = NULL,
	@userId smallint = NULL,
	@idArea smallint = NULL,
	@isCreating smallint = NULL,
	@module int = -1,
	@isCallTranscriptionEnabled BIT = NULL,
	@transferToHumanAgents INT = 0,
	@transferOnFallbackExternalNumber VARCHAR(10) = NULL,
	@transferOnFallbackDirectoryId INT = NULL,
	@transferOnFallbackMode BIT = NULL,
	@transferOnFallbackTimeoutSec SMALLINT = NULL,
	@transferOnSuccessfulHandling INT = 0,
	@transferOnSuccessExternalNumber VARCHAR(10) = NULL,
	@transferOnSuccessDirectoryId INT = NULL,
	@transferOnSuccessMode BIT = NULL,
	@transferOnSuccessTimeoutSec SMALLINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @country INT = (select valor from ccSettings where setting_id = 104); 
	DECLARE @excludeIdentifier VARCHAR(255) = CASE WHEN @country = 4 THEN ''IN_COMMON_INTERNATIONAL_RECORD_CALLS'' ELSE ''IN_COMMON_USA_RECORD_CALLS'' END;
	EXEC InsertLogAdminGalatea @action = 1,
								@tableName = ''ccInboundExtend'',
								@columnNameId = ''inbound_id'',
								@valueId = @inbound_id,
								@userId = @userid
	CREATE TABLE #ccInboundExtendTable (
	columnInfo varchar(255),
	dataInfo varchar(255),
	identifierInfo varchar(255)
	)


	DECLARE @chatType INT;

	SELECT @chatType = chat FROM ccInbound WHERE Inbound_id = @inbound_id;

	DECLARE @operation SMALLINT;

	IF @chatType = 11
	BEGIN
			SET @operation = CASE 
							 WHEN @isCreating = 1 THEN 137  -- Crear campaña IA
							 ELSE 138                       -- Editar campaña IA
            END;
	END
	ELSE
	BEGIN
			SET @operation = CASE 
							WHEN @isCreating = 1 THEN 60   -- Crear campaña normal
							ELSE 52                        -- Editar campaña normal
            END;
	END

	IF EXISTS (SELECT * FROM ccInboundExtend WHERE Inbound_id = @inbound_id)
	BEGIN
		
		
		UPDATE ccInboundExtend
		SET 
		    RecordCalls = ISNULL(@recordCalls, RecordCalls),
		    IsCallTranscriptionEnabled = ISNULL(@isCallTranscriptionEnabled, 1),

		    TransferToHumanAgents = 
				CASE 
					 WHEN @transferToHumanAgents IS NOT NULL AND @transferToHumanAgents <> TransferToHumanAgents
						THEN @transferToHumanAgents
					 ELSE TransferToHumanAgents
				END,

		    TransferOnFallback_ExternalNumber = 
		        CASE 
		            WHEN @transferToHumanAgents = 0 THEN NULL
		            WHEN @transferToHumanAgents = 1 THEN NULL
		            WHEN @transferToHumanAgents = 2 THEN 
		                CASE 
		                    WHEN @transferOnFallbackDirectoryId IS NOT NULL AND @transferOnFallbackDirectoryId != 0 THEN NULL
		                    ELSE @transferOnFallbackExternalNumber
		                END
					ELSE
						TransferOnFallback_ExternalNumber
		        END,

		    TransferOnFallback_DirectoryId = 
		        CASE 
		            WHEN @transferToHumanAgents = 0 THEN NULL
		            WHEN @transferToHumanAgents = 1 THEN NULL
		            WHEN @transferToHumanAgents = 2 THEN 
		                CASE 
		                    WHEN @transferOnFallbackExternalNumber IS NOT NULL AND @transferOnFallbackExternalNumber <> '''' THEN NULL
		                    ELSE @transferOnFallbackDirectoryId
		                END
					ELSE
						TransferOnFallback_DirectoryId
		        END,

		    TransferOnFallback_Mode = 
		        CASE 
		            WHEN @transferToHumanAgents = 0 THEN NULL
					WHEN @transferOnFallbackMode IS NULL THEN TransferOnFallback_Mode
		            ELSE @transferOnFallbackMode
 		       END,

		    TransferOnFallback_TimeoutSec = 
		        CASE 
		            WHEN @transferToHumanAgents = 0 THEN NULL
					WHEN @transferOnFallbackTimeoutSec IS NULL THEN TransferOnFallback_TimeoutSec
		            ELSE @transferOnFallbackTimeoutSec
		        END,

		    TransferOnSuccessfulHandling = 
				CASE 
					WHEN @transferOnSuccessfulHandling IS NOT NULL AND @transferOnSuccessfulHandling <> TransferOnSuccessfulHandling
						THEN @transferOnSuccessfulHandling
					ELSE TransferOnSuccessfulHandling
				END,

		    TransferOnSuccess_ExternalNumber = 
		        CASE 
		            WHEN @transferOnSuccessfulHandling = 0 THEN NULL
		            WHEN @transferOnSuccessfulHandling = 1 THEN NULL
		            WHEN @transferOnSuccessfulHandling = 2 THEN
		                CASE 
		                    WHEN @transferOnSuccessDirectoryId IS NOT NULL AND @transferOnSuccessDirectoryId != 0 THEN NULL
		                    ELSE @transferOnSuccessExternalNumber
		                END
					ELSE
						TransferOnSuccess_ExternalNumber
		        END,

		    TransferOnSuccess_DirectoryId = 
		        CASE 
		            WHEN @transferOnSuccessfulHandling = 0 THEN NULL
		            WHEN @transferOnSuccessfulHandling = 1 THEN NULL
		            WHEN @transferOnSuccessfulHandling = 2 THEN
		                CASE 
		                    WHEN @transferOnSuccessExternalNumber IS NOT NULL AND @transferOnSuccessExternalNumber <> '''' THEN NULL
 		                   ELSE @transferOnSuccessDirectoryId
		                END
					ELSE
						TransferOnSuccess_DirectoryId
		        END,

		    TransferOnSuccess_Mode = 
		        CASE 
		            WHEN @transferOnSuccessfulHandling = 0 THEN NULL
					WHEN @transferOnSuccessMode IS NULL THEN TransferOnSuccess_Mode
		            ELSE @transferOnSuccessMode
		        END,

		    TransferOnSuccess_TimeoutSec = 
		        CASE 
		            WHEN @transferOnSuccessfulHandling = 0 THEN NULL
					WHEN @transferOnSuccessTimeoutSec IS NULL THEN TransferOnSuccess_TimeoutSec
		            ELSE @transferOnSuccessTimeoutSec
		        END

		WHERE Inbound_id = @inbound_id;

	END
	ELSE
	BEGIN
		INSERT INTO ccInboundExtend (
			Inbound_id, RecordCalls, IsCallTranscriptionEnabled, 
			TransferToHumanAgents, TransferOnFallback_ExternalNumber, TransferOnFallback_DirectoryId, TransferOnFallback_Mode, TransferOnFallback_TimeoutSec, 
			TransferOnSuccessfulHandling, TransferOnSuccess_ExternalNumber, TransferOnSuccess_DirectoryId, TransferOnSuccess_Mode, TransferOnSuccess_TimeoutSec
			)
		VALUES (
			@inbound_id, @recordCalls, @isCallTranscriptionEnabled, 
			@transferToHumanAgents, @transferOnFallbackExternalNumber, @transferOnFallbackDirectoryId, @transferOnFallbackMode, @transferOnFallbackTimeoutSec,
			@transferOnSuccessfulHandling, @transferOnSuccessExternalNumber, @transferOnSuccessDirectoryId, @transferOnSuccessMode, @transferOnSuccessTimeoutSec
			)
	END

	IF (@isCreating > 0  AND @module > -1) 
	BEGIN
		EXEC InsertLogAdminGalatea @action = 2,
									@tableName = ''ccInboundExtend'',
									@columnNameId = ''Inbound_id'',
									@valueId = @inbound_id,
									@userId = @userid,
									@tableTemp = ''#ccInboundExtendTable''
	END
	ELSE IF (@isCreating = 1  AND @chatType = 11)
	BEGIN
		EXEC InsertLogAdminGalatea @action = 2,
									@tableName = ''ccInboundExtend'',
									@columnNameId = ''Inbound_id'',
									@valueId = @inbound_id,
									@userId = @userid,
									@tableTemp = ''#ccInboundExtendTable''
	END
	ELSE 
	BEGIN
		IF (@recordCalls != 1)
			EXEC InsertLogAdminGalatea @action = 2,
										@tableName = ''ccInboundExtend'',
										@columnNameId = ''Inbound_id'',
										@valueId = @inbound_id,
										@userId = @userid,
										@tableTemp = ''#ccInboundExtendTable'';
	END

	DELETE FROM #ccInboundExtendTable WHERE columnInfo IN (''TransferOnSuccess_ExternalNumber'', ''TransferOnFallback_ExternalNumber'')

	INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
	SELECT
		(SELECT
			[AreaName]
		FROM ccRIACat_Areas
		WHERE IDArea = @idArea),
		GETDATE(),
		(SELECT
			[Login]
		FROM ccUsers
		WHERE User_id = @userid),
		@operation,
		CASE WHEN @isCreating = 1 THEN 3 ELSE @module END,
		CCIE.identifierInfo,
		CASE
			WHEN CCIE.identifierInfo IS NOT NULL AND CCIE.identifierInfo <> '''' THEN 
					CASE
						WHEN CCIE.identifierInfo IN (''IN_COMMON_INTERNATIONAL_RECORD_CALLS'') 
							THEN 
								CASE
									WHEN CCIE.dataInfo = 1 THEN ''COMMON_ENABLED''
									ELSE ''COMMON_DISABLED''
								END
						WHEN CCIE.identifierInfo IN (''IN_COMMON_USA_RECORD_CALLS'') 
							THEN
								CASE 
									WHEN CCIE.dataInfo = 1 THEN ''COMMON_USA_RECORD_CALLS_MODE_ALL''
									WHEN CCIE.dataInfo = 2 THEN ''COMMON_USA_RECORD_CALLS_MODE_AUTH''
									WHEN CCIE.dataInfo = 4 THEN ''COMMON_USA_RECORD_CALLS_MODE_NOAUTH''
									ELSE ''COMMON_DISABLED'' 
								END
						WHEN CCIE.identifierInfo IN (''IN_CALL_IA_CALL_TRANSCRIPTION'') 
							THEN
								CASE
									WHEN CCIE.dataInfo = 1 THEN ''COMMON_ENABLED''
									ELSE ''COMMON_DISABLED''
								END
						WHEN CCIE.identifierInfo IN (''IN_CALL_IA_TRANSFER_TO_HUMAN_AGENTS'') 
							THEN
								CASE
									WHEN CCIE.dataInfo = 0 THEN ''COMMON_NONE_O''
									WHEN CCIE.dataInfo = 1 THEN ''COMMON_CAMPAIGN''
									WHEN CCIE.dataInfo = 2 AND (@transferOnFallbackDirectoryId IS NULL AND @transferOnFallbackExternalNumber IS NOT NULL)
										THEN ''COMMON_EXTERNAL_NUMBER<''+CONVERT(VARCHAR(10),@transferOnFallbackExternalNumber)
									WHEN CCIE.dataInfo = 2 AND (@transferOnFallbackDirectoryId IS NOT NULL AND @transferOnFallbackExternalNumber IS NULL)
										THEN ''COMMON_DIRECTORY<'' + (SELECT nombre FROM telefonosTransferencia WHERE numtra_id = @transferOnFallbackDirectoryId)
								END
						WHEN CCIE.identifierInfo IN (''IN_CALL_IA_TRANSFER_ON_SUCCESSFUL_HANDLING'') 
							THEN
								CASE
									WHEN CCIE.dataInfo = 0 THEN ''COMMON_NONE_O''
									WHEN CCIE.dataInfo = 1 THEN ''COMMON_CAMPAIGN''
									WHEN CCIE.dataInfo = 2 AND (@transferOnSuccessDirectoryId IS NULL AND @transferOnSuccessExternalNumber IS NOT NULL)
										THEN ''COMMON_EXTERNAL_NUMBER<'' + CONVERT(VARCHAR(10),@transferOnSuccessExternalNumber)
									WHEN CCIE.dataInfo = 2 AND (@transferOnSuccessDirectoryId IS NOT NULL AND @transferOnSuccessExternalNumber IS NULL)
										THEN ''COMMON_DIRECTORY<'' + (SELECT nombre FROM telefonosTransferencia WHERE numtra_id = @transferOnSuccessDirectoryId)
								END
						WHEN CCIE.identifierInfo IN (''IN_CALL_IA_TRANSFER_ON_FALLBACK_MODE'', ''IN_CALL_IA_TRANSFER_ON_SUCCESS_MODE'') 
							THEN
								CASE 
									WHEN CCIE.dataInfo = 0 THEN ''IN_CALL_IA_TRANSFER_ASSISTED_MODE''
									WHEN CCIE.dataInfo = 1 THEN ''IN_CALL_IA_TRANSFER_BLIND_MODE''
									ELSE ''''
								END
						ELSE CCIE.dataInfo
					END
				ELSE ''''
			END,
			(SELECT
				[descripcion]
			FROM ccInbound
			WHERE inbound_id = @inbound_id)
	FROM #ccInboundExtendTable AS CCIE 
	where CCIE.identifierInfo != @excludeIdentifier;

	EXEC InsertLogAdminGalatea	@action = 3,
								@tableName = ''ccInboundExtend'',
								@columnNameId = ''Inbound_id'',
								@valueId = @inbound_id,
								@userId = @userid;

	IF OBJECT_ID(N''tempdb..#ccInboundExtendTable'') IS NOT NULL
		DROP TABLE #ccInboundExtendTable
	SET NOCOUNT OFF;
END
	'
    EXEC(@sql)

	SET @process = 'K070051, K070208, K070219 - delete sp ccsp_RIAUpdateEspecConfig'
	SET @sql = '
	IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_RIAUpdateEspecConfig'')
	BEGIN
		DROP PROCEDURE dbo.ccsp_RIAUpdateEspecConfig
	END
	'
    EXEC(@sql)

	SET @process = 'K070051, K070208, K070219 - create sp ccsp_RIAUpdateEspecConfig'
	SET @sql = '
CREATE PROCEDURE ccsp_RIAUpdateEspecConfig
    @inbound_id              SMALLINT, 
    @descripcion             VARCHAR(50)  = NULL, 
    @Status                  TINYINT      = NULL, 
    @tNotas                  INT          = NULL, 
    @tMaxWaitCall            INT          = NULL, 
    @nMaxQue                 INT          = NULL, 
    @tel_maxwait             VARCHAR(15)  = NULL, 
    @tel_MaxQueue            VARCHAR(15)  = NULL, 
    @tel_outservice          VARCHAR(15)  = NULL, 
    @tel_noct                VARCHAR(15)  = NULL, 
    @ShowCalifWnd            BIT          = NULL, 
    @StartTimerOnHangUp      BIT          = NULL, 
    @editableCallKey         BIT          = NULL, 
    @queuePosition           BIT          = NULL, 
    @tMaxQueueCallBack       SMALLINT     = NULL, 
    @stopRecording           BIT          = NULL, 
    @dialPrefixOverflow      VARCHAR(10)  = NULL, 
    @OpriorityT              SMALLINT     = NULL, 
    @callerIdDesc            VARCHAR(15)  = NULL, 
    @chat                    TINYINT      = NULL, 
    @inactiveChatTime        SMALLINT     = NULL, 
    @maxChats                TINYINT      = NULL, 
    @chatDomain              VARCHAR(MAX) = NULL, 
    @chatQueue               SMALLINT     = NULL, 
    @chatTime                SMALLINT     = NULL, 
    @dRestrictPlay           BIT          = NULL, 
    @callBackSurveyAgent     BIT          = NULL, 
    @callBackSurveyClient    BIT          = NULL, 
    @agts_notavailable       VARCHAR(15)  = NULL, 
    @editableDtmf            BIT          = NULL, 
    @prefijo                 VARCHAR(MAX) = NULL, 
    @addDataCallBackReminder BIT          = NULL,
    @recordHold              BIT          = NULL,
    @editableContactData     BIT          = NULL,
    @userId                  SMALLINT     = NULL, 
    @idArea                  SMALLINT     = NULL, 
    @isCreating              BIT          = NULL
AS
SET NOCOUNT ON;

declare @domainInUse bit = 0
declare @returnValue int = 2

EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inbound_id, @userId= @userid

UPDATE ccInbound
SET 
    descripcion = ISNULL(@descripcion, descripcion), 
    STATUS = ISNULL(@status, STATUS), 
    tNotas = ISNULL(CASE WHEN @chat <> 5  OR @chat IS NULL THEN @tNotas ELSE 10 END, tNotas),
    tMaxWaitCall = ISNULL(@tMaxWaitCall, tMaxWaitCall), 
    nMaxQue = ISNULL(@nMaxQue, nMaxQue), 
    tel_maxwait = ISNULL(@tel_maxwait, tel_maxwait), 
    tel_MaxQueue = ISNULL(@tel_MaxQueue, tel_MaxQueue), 
    tel_outservice = ISNULL(@tel_outservice, tel_outservice), 
    tel_noct = ISNULL(@tel_noct, tel_noct), 
    bnocturno = CASE
                    WHEN ISNULL(@tel_noct, 0) = ''0''
                        OR @tel_noct = ''''
                    THEN ''0''
                    ELSE ''1''
                END, 
    StartTimerOnHangUp = ISNULL(@StartTimerOnHangUp, StartTimerOnHangUp), 
    editableCallKey = ISNULL(@editableCallKey, editableCallKey), 
    queuePosition = ISNULL(@queuePosition, queuePosition), 
    tMaxQueueCallBack = ISNULL(@tMaxQueueCallBack, tMaxQueueCallBack), 
    stopRecording = ISNULL(@stopRecording, stopRecording), 
    dialPrefixOverflow = ISNULL(@dialPrefixOverflow, dialPrefixOverflow), 
    OpriorityT = ISNULL(@OpriorityT, OpriorityT), 
    callerIdDesc = ISNULL(@callerIdDesc, callerIdDesc), 
    chat = ISNULL(@chat, chat), 
    inactiveChatTime = ISNULL(@inactiveChatTime, inactiveChatTime), 
    maxChats = ISNULL(@maxChats, maxChats), 
    chatQueueOverflow = ISNULL(@chatQueue, ISNULL(chatQueueOverflow, 15)), 
    chatTimeOverflow = ISNULL(@chatTime, ISNULL(chatTimeOverflow, 300)), 
    startStopRecording = ISNULL(@dRestrictPlay, startStopRecording), 
    callBackSurveyAgent = ISNULL(@callBackSurveyAgent, callBackSurveyAgent), 
    callBackSurveyClient = ISNULL(@callBackSurveyClient, callBackSurveyClient), 
    agts_notavailable = ISNULL(@agts_notavailable, agts_notavailable), 
    editableDtmf = ISNULL(@editableDtmf, editableDtmf), 
    prefijo = ISNULL(@prefijo, prefijo), 
    addDataCallBackReminder = ISNULL(@addDataCallBackReminder, addDataCallBackReminder),
    recordHold = ISNULL(@recordHold, recordHold),
    EditableContactData = ISNULL(@editableContactData, EditableContactData)
WHERE inbound_id = @inbound_id;


IF NOT EXISTS (SELECT inbound_id FROM ccinbound WHERE inbound_id <> @inbound_id AND chatDomain = @chatDomain AND chatDomain <> '''')
BEGIN
    IF @chatDomain IS NOT NULL
    BEGIN
        UPDATE ccinbound SET chatDomain = @chatDomain WHERE inbound_id = @inbound_id
    END
END
ELSE
BEGIN
    UPDATE ccinbound SET chatDomain = '''' WHERE inbound_id = @inbound_id
    set @domainInUse = 1
END


IF @ShowCalifWnd = 1
BEGIN
    IF EXISTS (SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inbound_id AND tipo = 0)
    BEGIN
        UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inbound_id;
        SET @returnValue = 1
    END
    ELSE
    BEGIN
        SET @returnValue = 0
    END
END;
ELSE
    UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inbound_id;



IF(@chat <> 5) 
BEGIN

	DECLARE @chatType INT;

	SELECT @chatType = chat FROM ccInbound WHERE Inbound_id = @inbound_id;

	DECLARE @operation SMALLINT;

	IF @chatType = 1
	BEGIN
			SET @operation = CASE 
							 WHEN @isCreating = 1 THEN 63  -- Crear campaña CHAT
							 ELSE 64                       -- Editar campaña CHAT
            END;
	END
	ELSE IF @chatType = 11
	BEGIN
		SET @operation = CASE 
							 WHEN @isCreating = 1 THEN 137  -- Crear campaña IA
							 ELSE 138                       -- Editar campaña IA
            END;
	END
	ELSE 
	BEGIN
			SET @operation = CASE 
							WHEN @isCreating = 1 THEN 60   -- Crear campaña normal
							ELSE 52                        -- Editar campaña normal
            END;
	END


    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable
    Create table #ccInboundTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )
    
    IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid, @tableTemp=''#ccInboundTable'';

    DELETE FROM #ccInboundTable WHERE columnInfo IN (''bnocturno'', ''cam'');
	IF(@chat = 11) DELETE FROM #ccInboundTable WHERE columnInfo IN (''chat'');

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        @operation,
        3, 
        CCIT.identifierInfo,
        CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
            CASE 
                WHEN CCIT.identifierInfo IN (''IN_DESTINATION_WAIT_TIME'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
                    CASE WHEN CCIT.dataInfo = ''VOICEMAIL'' 
                        THEN ''COMMON_VOICE_MAIL'' 
                        ELSE 
                            CASE WHEN CCIT.dataInfo IS NOT NULL 
								THEN (SELECT descripcion FROM ccInbound WHERE Inbound_id = (SELECT Value FROM dbo.fn_RIASplitDelimited(CCIT.dataInfo,''|'') WHERE Id = 2))
								ELSE ''T&COMMON_NONE'' 
							END
                        END
                WHEN CCIT.identifierInfo IN (''IN_RECORD_ON_HOLD'',''IN_PLAY_QUEUE_ORDER'', ''IN_STOP_RECORDING'', ''IN_SHOW_DISPOSITIONS'', ''IN_CALL_KEY'', ''IN_CONDUCT_CALLBACK_SURVEY'', ''IN_RECEIVE_DTMF_TONES'', ''IN_CALL_BACK'', ''EDIT_CALL_DATASET'') THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                WHEN CCIT.identifierInfo = ''IN_CONDUCT_SURVEY'' THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
                ELSE CCIT.dataInfo END
        ELSE '''' END, 
        (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inbound_id)
    FROM #ccInboundTable AS CCIT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid;

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable
END

IF @chat = 5 
BEGIN
    IF NOT EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
    BEGIN
        INSERT INTO contactMeanIn (meanContactTypeId, name, inboundId, isActive) values (@chat, @descripcion, @inbound_id, (select status from ccInbound where Inbound_id = @inbound_id));

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        VALUES (
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            40, 
            3,'''','''', 
            @descripcion);
    END
END;

if (@domainInUse = 1)
BEGIN
    RAISERROR(''Domain already in another ACD Group'', 15, 4)
END

if(@returnValue <> 2)
    SELECT @returnValue
ELSE
    SELECT 2
RETURN(0)

SET NOCOUNT OFF
	'
    EXEC(@sql)


	---------------------- END IGC ----------------------

    ---------------------- BEGIN Carlos Muñoz ----------------------

    SET @process = 'K0700118 - Creating a new table to store virtual agent voice data'
	SET @Sql='
		if  not exists(SELECT * FROM sysobjects WHERE name=''ccVirtualAgentVoices'') 
	
		begin 

            CREATE TABLE ccVirtualAgentVoices (
                ID INT IDENTITY(1,1) PRIMARY KEY,
                Name VARCHAR(100) NOT NULL,
                Gender VARCHAR(30) CHECK (gender IN (''Male'',''Female'')),
                FileName VARCHAR(500),
                IsDefault BIT DEFAULT 0,
                CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
            );
		end
		'	
	EXEC(@Sql)

    SET @process = 'K0700118 - Inserting default virtual agent voice records'
	SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ccVirtualAgentVoices WHERE ID = 1)
	BEGIN
        INSERT INTO ccVirtualAgentVoices (Name, Gender, FileName, IsDefault) VALUES(''Alma'', ''Female'', ''Alma.mp3'', 1);
	END'
    EXEC(@sql)

	SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ccVirtualAgentVoices WHERE ID = 2)
	BEGIN
        INSERT INTO ccVirtualAgentVoices (Name, Gender, FileName, IsDefault) VALUES(''Luis'', ''Male'', ''Luis.mp3'', 0);
	END'
    EXEC(@sql)


    SET @process = 'Adding two new columns to support new transfer types in AI Campaigns'
    SET @sql = '
            IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''idForSuccessfulTransaction'' AND Object_ID = Object_ID(N''ccInbound''))
            BEGIN
                ALTER TABLE ccInbound ADD idForSuccessfulTransaction SMALLINT
            END

            IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''idForNonComprehension'' AND Object_ID = Object_ID(N''ccInbound''))
            BEGIN
                ALTER TABLE ccInbound ADD idForNonComprehension SMALLINT
            END'
    EXEC(@sql)

    SET @process = 'K070066 - Adding option 19 to bring inbound campaigns from a certain workgroup or area and associated to the IA Campaign.'

    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_GalateaAdminCampaigns'')
        BEGIN
            DROP PROCEDURE dbo.ccsp_GalateaAdminCampaigns
        END'
    EXEC(@sql);


    SET @sql = '
    CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns]
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
					@multi_type     varchar(max) = null,
					@IsWhatsAppCampaign  bit = 0,
					@groupList as varchar (MAX) = NULL,
					@CampId AS      SMALLINT = 0
					AS
					BEGIN
						SET NOCOUNT ON;
					IF @Option = 1 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type     
						IF @WorkgroupId IS NOT NULL BEGIN
							SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId
							ORDER BY IdCampEsp ASC;
						END;
						ELSE BEGIN
							RAISERROR(''ERROR. No existe una lista de campañas con el id de grupo de trabajo especificado'', 18, 1);
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
								CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10  ELSE isnull(camps.CampType,0) END as OutboundType,
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

					ELSE IF @option = 10 BEGIN -- Get Agents States with totals per campaign by admin id and campaign type **********************
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
							camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), NumberOfVirtualAgents INT, PRIMARY KEY (camId
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

						IF @IsWhatsAppCampaign  = 1
						BEGIN
							INSERT INTO @tmpCamAgent --Obtiene las relaciones entre agentes y campañas
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
								AND (camps.CampType = 5 or inbound.chat = 5)
								AND campPerWg.Tipo = @CampType
								AND (
									@Id = 0
									OR campPerWg.IdCampEsp = @Id
									);
						END
						ELSE
						BEGIN
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
									);
						END;

						WITH lastState
						AS (
							SELECT A.user_id, MAX(A.fecha) AS fecha
							FROM ccLogAgentesDiaViewLast A
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
							WHERE multimediaType = 0
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

						;with stateDialog as(
						SELECT cast(value as int) as CurrentState FROM dbo.fn_RIASplitDelimited(@StateIds,'','')
					)
						INSERT INTO @AgentStatus
						SELECT A.camId, A.userId, B.CurrentState,
						(CASE
							WHEN @chatType = 1 THEN
								CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) THEN 1 ELSE 0 END
							ELSE
								CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN 1 ELSE 0
							END
						END) AS isCampDialog, B.camType

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
							SELECT A.camId, B.cam_descripcion AS campName, A.Total, C.AreaName AS Area, ISNULL(va.concurrentSessionsLimit,0) as NumberOfVirtualAgents 
							FROM campDataTotal A
							INNER JOIN ccCamps B ON A.camId = B.cam_id
							INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
                            LEFT JOIN ccVirtualAgent va ON B.cam_id = va.idCampaign AND va.campType = 1
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
							SELECT A.camId, B.descripcion AS campName, A.Total, C.AreaName AS Area, 0 as NumberOfVirtualAgents 
							FROM campDataTotal A
							INNER JOIN ccInbound B ON A.camId = B.Inbound_id
							INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
						END;

						WITH stateCamp
						AS (
							SELECT A.CampId, count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready, 
								count(CASE WHEN A.CurrentState NOT IN (- 2, - 1, 0, 3, 4, 5, 6, 9, 30, 34, 37
												) THEN 1 WHEN A.CurrentState IN (6, 4
												)
											AND (
												A.CampId != C.IdCampEsp
												OR A.campType != @CampType
												) THEN 1 ELSE NULL END) AS notReady,
												COUNT(CASE WHEN A.isCampDialog = 1 OR A.CurrentState = 34 THEN 1 ELSE NULL END) AS dialog, 
												COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected,
						COUNT(CASE WHEN A.CurrentState = 37 THEN 1 ELSE NULL END) AS auxiliaryReady
							FROM @AgentStatus A
							INNER JOIN @CurrentStatus C ON A.userId = C.userId
							GROUP BY A.CampId
							)
						SELECT A.camId, A.campName, (A.Total + A.NumberOfVirtualAgents) AS Total, ISNULL(B.ready, 0) AS Ready, ISNULL(B.notReady, 
								0) AS NotReady, ISNULL(B.dialog, 0) AS Dialog, CASE WHEN B.disconnected IS NULL 
									THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady - B.auxiliaryReady END 
							Disconnected, ISNULL(B.auxiliaryReady, 0) AS AuxiliaryReady, A.NumberOfVirtualAgents ,A.Area
						FROM @campDataTotal A
						LEFT JOIN stateCamp B ON A.camId = B.CampId
						ORDER BY A.campName

						RETURN 0;
					END; -- *****************************************************************************************
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
							INTO #tempIds
							FROM ccRIACampEspWG A WITH (NOLOCK)
							INNER JOIN wgId ON wgId.IDWG = A.IDWG
								AND A.Tipo = @CampType;
	
							IF(@CampType = 1)
							BEGIN
								SELECT Id FROM #tempIds ids
								INNER JOIN ccCamps c on c.cam_id = ids.Id
								WHERE (c.CampType = 5 AND @IsWhatsAppCampaign = 1) 
								OR (c.CampType <> 5 AND @IsWhatsAppCampaign = 0)
							END
							ELSE
							BEGIN
								SELECT Id FROM #tempIds ids
								INNER JOIN ccInbound c on c.Inbound_id = ids.Id
								WHERE (c.chat = 5 AND @IsWhatsAppCampaign = 1) 
								OR (c.chat <> 5 AND @IsWhatsAppCampaign = 0)
							END
							DROP TABLE #tempIds
						END;
						ELSE
						BEGIN
							--print ''xxxx Super''
							IF @CampType = 1
							BEGIN
								SELECT DISTINCT CAST(cam_id AS INT) AS Id
								FROM ccCamps WITH (NOLOCK)
								WHERE IDArea IS NOT NULL
								AND(CampType = 5 AND @IsWhatsAppCampaign = 1) 
								OR (CampType <> 5 AND @IsWhatsAppCampaign = 0)
							END
							ELSE
							BEGIN
								SELECT DISTINCT CAST(Inbound_id AS INT) AS Id
								FROM ccInbound WITH (NOLOCK)
								WHERE IDArea IS NOT NULL
								AND (chat = 5 AND @IsWhatsAppCampaign = 1) 
								OR (chat <> 5 AND @IsWhatsAppCampaign = 0)
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
										CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 when camps.CampType = 9 then 10 ELSE isnull(camps.CampType,0) END as OutboundType,
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
														CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
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
													CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
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
								FROM ccInbound NOLOCK where cam_id = @Id and chat IN (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))
					END
					ELSE IF  @Option=16
					begin
						DECLARE @from DATETIME = CAST(GETDATE() AS DATE);
						DECLARE @to DATETIME = DATEADD(MILLISECOND, -3, DATEADD(DAY, 1, @from));
						select @AreaId = IDArea from ccUsers where User_id = @Id
						declare @camps table (cam_id int)
						insert @camps	select cam_id  FROM  dbo.fGet_CampAcd_Area(@Id,5) group by cam_id
						if((select SUM(cam_id) from @camps) IS NULL)
							begin
								select '''' as CampName
								,0 as Conversations
								,0 as Assign
								,0 as OnQueu
								,0 AS FinishedBySystem
								,0 AS FinishedByAgent
								,'''' as AreaName
								,0 as IsAssignedCamps
							end
						else
							begin
								;with camDesc as(
								select 
								c.cam_id as cam_id
								,cam_descripcion as cam_desc
								,area.AreaName
								from ccCamps c with (nolock)
								inner join @camps id on c.cam_id = id.cam_id
								inner join ccRIACat_Areas area on area.IDArea = c.IDArea
								group by area.AreaName, c.cam_id, c.cam_descripcion
								)
								,
								currentConversationWa as (
								select conversationId, camId, assignDate, onQueue,finishedBy
								,case when conversationStatus = 2 then 1 else 0 end as assigned
								from ccWhatsAppConversationsOut with (nolock)
								where assignDate >= @from and assignDate <= @to
								)
								select 
								b.cam_desc as CampName
								,COALESCE(COUNT(ccw.conversationId), 0) AS Conversations
								,COALESCE(SUM(ccw.assigned), 0) AS Assign
								,COALESCE(count(ccw.onQueue),0) as OnQueu
								,SUM(CASE WHEN ccw.finishedBy = 1 THEN 1 ELSE 0 END) AS FinishedBySystem
								,SUM(CASE WHEN ccw.finishedBy = 2 THEN 1 ELSE 0 END) AS FinishedByAgent
								,b.AreaName as AreaName
								,1 as IsAssignedCamps
								from camDesc b
								left join currentConversationWa ccw on ccw.camId = b.cam_id
								group by b.cam_id, b.cam_desc, b.AreaName
							end
						end
					ELSE IF @Option = 17 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
							IF @groupList IS NOT NULL BEGIN
								IF OBJECT_ID(''tempdb..#WGDelete'') IS NOT NULL DROP TABLE #WGDelete;
								SELECT value As IDwg into #WGDelete FROM fn_RIASplitDelimited(@groupList, '','')
								SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type, IDWG AS IdWg FROM ccRIACampEspWG WHERE IDWG in (select IDwg from #WGDelete)
								ORDER BY IdCampEsp ASC;
							END;
							ELSE BEGIN
								RAISERROR(''ERROR. No existe una lista de campañas con los ids de grupo de trabajo especificados'', 18, 1);
							END;
							RETURN 0;
						END;

					ELSE IF @Option = 18 BEGIN -- Validar si la campaña fue eliminada del area 
							DECLARE @activo INT;

							IF @CampType = 0 BEGIN
								SELECT @activo = ISNULL(IDArea, 0) 
								FROM ccInbound
								WHERE Inbound_id = @Id;
							END; 

							ELSE BEGIN
							    SELECT @activo = ISNULL(IDArea, 0) 
								FROM ccCamps 
								WHERE cam_id = @Id;
							END;

							SELECT @activo;
						END;

					ELSE IF @Option = 19
						BEGIN

							DECLARE @SuccessId INT, @NonComprehensionId INT;
							DECLARE @IsSuperUser BIT = 0;
							DECLARE @wgId TABLE (IDWG INT);

							IF EXISTS (SELECT * FROM ccUsers_Roles NOLOCK WHERE User_id = @AdminId AND Rol_id = 7)
							BEGIN
								SET @IsSuperUser = 1;
							END
							ELSE
							BEGIN
								INSERT INTO @wgId (IDWG)
								SELECT IDWG
								FROM ccRIAWorkGroupUsers WITH (NOLOCK)
								WHERE user_id = @AdminId;
							END

							SELECT 
								@SuccessId = ISNULL(idForSuccessfulTransaction, -1),
								@NonComprehensionId = ISNULL(idForNonComprehension, -1)
							FROM ccInbound WITH (NOLOCK)
							WHERE Inbound_id = @CampId;

							WITH MainCampaigns AS (
								SELECT 
									CAST(cci.Inbound_id AS INT) AS CampId,
									cci.descripcion AS Description,
									ISNULL(cci.IDArea, -1) AS AreaID,
									CAST(cci.chat AS SMALLINT) AS CampaignType,
									CAST(0 AS BIT) AS IsSuccessTransfer,
									CAST(0 AS BIT) AS IsNonComprehensionTransfer
								FROM ccInbound cci WITH (NOLOCK)
								WHERE 
								(
									-- Superusuario: por Área
									(@IsSuperUser = 1 AND cci.IDArea = @AreaId)
									OR
									-- Usuario normal: por Workgroup
									(@IsSuperUser = 0 AND EXISTS (
										SELECT 1 FROM ccRIACampEspWG A WITH (NOLOCK)
										INNER JOIN @wgId wg ON wg.IDWG = A.IDWG
										WHERE A.Tipo = 0 AND A.IdCampEsp = cci.Inbound_id
									))
								)
								AND cci.chat = 0
								AND cci.IDArea = @AreaId
							),
							ReferencedCampaigns AS (
								SELECT 
									CAST(cci.Inbound_id AS INT) AS CampId,
									cci.descripcion AS Description,
									ISNULL(cci.IDArea, -1) AS AreaID,
									CAST(cci.chat AS SMALLINT) AS CampaignType,
									CASE WHEN cci.Inbound_id = @SuccessId THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsSuccessTransfer,
									CASE WHEN cci.Inbound_id = @NonComprehensionId THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsNonComprehensionTransfer
								FROM ccInbound cci WITH (NOLOCK)
								WHERE cci.Inbound_id IN (@SuccessId, @NonComprehensionId)
							)

							SELECT * FROM ReferencedCampaigns
							UNION ALL
							SELECT m.*
							FROM MainCampaigns m
							LEFT JOIN ReferencedCampaigns r
							  ON m.CampId = r.CampId
							WHERE r.CampId IS NULL;
						END;
					END;
    
    '
    EXEC(@Sql)

    SET @process = 'K070066 - Including new identifiers for the new transfer types'

	SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''ASSOCIATED_CAMP_XFER_IA'')
	BEGIN
        INSERT INTO ccGalateaIdentifiers VALUES (''ASSOCIATED_CAMP_XFER_IA'', ''Campaña asociada (transferencia a agentes humanos)'', ''Associated campaign (live agent transfer)'', ''Campanha associada (transferência para agentes humanos)'')
	END'
    EXEC(@sql)

    SET @sql = '
    IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''ASSOCIATED_CAMP_SUCCESSFUL_TRANSACTION'')
	BEGIN
        INSERT INTO ccGalateaIdentifiers VALUES (''ASSOCIATED_CAMP_SUCCESSFUL_TRANSACTION'', ''Campaña asociada (transferencia por gestión exitosa)'', ''Associated campaign (successful interaction transfer)'', ''Campanha associada (transferência de interação bem‑sucedida)'')
	END'
    EXEC(@sql)


    SET @process = 'K070066 - Adding a new option to associate new transfer types.'

    SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_GalateaAdminInbound'')
        BEGIN
            DROP PROCEDURE dbo.ccsp_GalateaAdminInbound
        END'
    EXEC(@sql);

    SET @sql = '
    CREATE PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT, 
                                            @InboundId AS SMALLINT = 0,
											@User_id AS SMALLINT = 0,
											@OutboundID AS SMALLINT = 0,
											@multi_cam as varchar(max) = null,
											@Module AS SMALLINT = 13,
											@Type AS SMALLINT = 0,
											@HistoryAction AS SMALLINT = 1,
											@AreaId AS SMALLINT = 0,
											@NonComprehensionId AS SMALLINT = -1,
											@SuccessfulTransactionCampaignId AS SMALLINT = -1,
											@CallBackCampaignId AS SMALLINT = -1,
											@IsEditing AS BIT = 0
		AS
		BEGIN
			set nocount on;

			DECLARE @idArea SMALLINT = NULL;
			DECLARE @operation INT = -1;
			DECLARE @mediaType INT = 0;

			IF(@Option IN (5, 6)) BEGIN
				IF(@Module IS NOT NULL AND @Module <> 13) BEGIN
				
					IF(@Type = 0)BEGIN
						
						IF(@multi_cam is not null) BEGIN
							SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
						END ELSE BEGIN
							SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id = @InboundId)
						END

						SET @operation = CASE WHEN @HistoryAction = 1 THEN 
																			CASE 
																					WHEN @mediaType = 1  THEN 63
																					WHEN @mediaType = 5  THEN 40
																					ELSE 60 END
																	  ELSE 
																			CASE 
																					WHEN @mediaType = 1  THEN 64
																					WHEN @mediaType = 5  THEN 53
																					ELSE 52 END
																	  END;
					END ELSE BEGIN

						SET @mediaType = (SELECT [CampType] FROM ccCamps WHERE cam_id = @OutboundID)

						SET @operation = CASE WHEN @HistoryAction = 1 THEN 
																			CASE 
																					WHEN @mediaType = 6  THEN 44
																					WHEN @mediaType = 5  THEN 46
																					WHEN @mediaType = 9  THEN 48
																					WHEN @mediaType = 7  THEN 50
																					ELSE 42 END
																	   ELSE 
																			CASE 
																					WHEN @mediaType = 6  THEN 55
																					WHEN @mediaType = 5  THEN 56
																					WHEN @mediaType = 9  THEN 57
																					WHEN @mediaType = 7  THEN 58
																					ELSE 54 END
																	    END;
					END

				END ELSE BEGIN
					SET @operation = CASE WHEN @Option = 5 THEN 93 ELSE 94 END;
				END
			END

			if(@Option = 1) -- Por campaña 
			begin
			    select 
			        ISNULL(count (*), 0) as Calls,
			        ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
			        ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
			        ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
			        ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
			        ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
			        ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
			        ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
			        ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
			        ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
			        THEN 1 ELSE NULL END), 0) AS Other
			    from ccCallsIn a (nolock)
			    where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) and a.inbound_id = @InboundId

			end

			if(@Option = 2) -- Todas las campañas 
			begin
			    select 
					inbound.Inbound_id as IDEspec,
					inbound.descripcion as Name,
			        ISNULL(count (*), 0) as Calls,
			        ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
			        ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
			        ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
			        ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
			        ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
			        ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
			        ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
			        ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
			        ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
			        THEN 1 ELSE NULL END), 0) AS Other
			    from ccCallsIn a (nolock)
				left join ccInbound inbound on a.inbound_id = inbound.Inbound_id
			    where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) 
				group by inbound.Inbound_id, inbound.descripcion
			end

			if(@Option = 3) -- Obtiene los datos de las llamadas de todos los ACD, datos que se muestran en el tablero de información del administrador 
			begin
				SELECT 
					a.inbound_id, calls = ISNULL(COUNT(*), 0), -- calls
					Dialogs = ISNULL(COUNT (CASE WHEN statusCall_id = 13 THEN 1 ELSE NULL END), 0), -- Answered
					DlgsAveTime =CONVERT(int, ISNULL(SUM (CASE WHEN statusCall_id = 13 THEN cal_tDialog + cal_tNotas ELSE 0 END), 0)),
					QueueAveTime =ISNULL( avg( CASE WHEN cal_que > 0 THEN cal_tWait ELSE NULL END), 0) ,
					abandon = ISNULL(COUNT(CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0), -- Abandoned
					OverFlowQueue = ISNULL(COUNT (CASE WHEN statusCall_id =8 THEN 1 ELSE NULL END), 0),
					OverFlowTimeOut = ISNULL(COUNT (CASE WHEN statusCall_id =7 THEN 1 ELSE NULL END), 0), -- OverFlowQueue+OverFlowTimeOut = not answered
					outOfSchedule = ISNULL(COUNT (CASE WHEN statusCall_id =2 THEN 1 ELSE NULL END), 0), -- fuera de horario
					outOfService = ISNULL(COUNT (CASE WHEN statusCall_id =3 THEN 1 ELSE NULL END), 0), -- fuera de servicio
					noAgentsLoggedIn = ISNULL(COUNT (CASE WHEN statusCall_id =4 THEN 1 ELSE NULL END), 0), -- sin agentes firmados
					assigned = ISNULL(COUNT (CASE WHEN statusCall_id =11 THEN 1 ELSE NULL END), 0), -- asignada
					--assignedAndNotAnswered = ISNULL(COUNT (CASE WHEN statusCall_id =15 THEN 1 ELSE NULL END), 0), -- asignada y no contestada
					--assignedAndTookLine = ISNULL(COUNT (CASE WHEN statusCall_id =16 THEN 1 ELSE NULL END), 0), -- asignada y toma linea
					callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0)
					--onQueue = ISNULL(COUNT(CASE WHEN statusCall_id = 5 THEN 1 ELSE NULL END), 0)
					--initCalls = CAST(ISNULL(COUNT(CASE WHEN statusCall_id = 1 THEN 1 ELSE NULL END), 0) AS varchar(7))+''|''+
					--			ISNULL((SELECT STUFF((SELECT ''|'' + cast(ci.cal_id AS varchar(7))
					--			FROM ccCallsin ci (nolock) WHERE cal_inicio > dateadd(mi,-5,getdate()) AND ci.inbound_id=a.inbound_id
					--			FOR XML PATH('''')) ,1,1,'''')),''0'')
				FROM ccCallsIn a (nolock)
				WHERE cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))
						--and a.inbound_id in (select cam_id from ccSupervisorCam where user_id = @User_id and tipo = 0)
				GROUP BY a.inbound_id
			--	SET nocount off
			--	return(0)
			end

			if(@Option = 4) -- Carga los ACD del administrador mandado
			begin
				SELECT cam_id 
				FROM ccSupervisorCam  nolock
				WHERE user_id = @User_id and tipo = 0
				SET nocount off
				return(0)
			end

			IF(@Option = 5) -- Relate the inbound campaign with the outbound campaign
			BEGIN
				IF(@idArea IS NULL OR @idArea = -1) SET @idArea = 
					CASE WHEN @Type = 0 
						THEN 
							CASE WHEN @multi_cam IS NULL
								THEN (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @InboundID) 
								ELSE (SELECT [IDArea] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
								END
						ELSE (SELECT [IDArea] FROM ccCamps WHERE cam_id = @OutboundID)
						END

				IF(@multi_cam is not null)
				BEGIN
					UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id IN (
						SELECT value from dbo.fn_RIASplitDelimited(@multi_cam,'',''))

					IF (@multi_cam <> '''' )
					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
					SELECT
						(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
						getDate(), 
						(SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
						@operation,
						@Module,
						CASE WHEN @Module = 13 THEN '''' ELSE ''ASSOCIATED_CAMP_CALLBACK'' END,
						CASE WHEN @Type = 0 THEN
												(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @OutboundID)
											ELSE 
												(SELECT [descripcion] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
											END,
						CASE WHEN @Type = 0 THEN
												(SELECT [descripcion] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
											ELSE 
												(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @OutboundID)
											END

					SELECT 1;
					RETURN 1;
				END
				IF((SELECT ISNULL(cam_id,-1) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId) != -1)
					BEGIN
						SELECT -1;
						RETURN -1;
					END;
				ELSE
					BEGIN
						UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id = @InboundID;
							
						IF(@Type <> 1 AND @InboundID <> 0)
						INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
						SELECT
							(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
							getDate(), 
							(SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
							@operation,
							@Module,
							CASE WHEN @Module = 13 THEN '''' ELSE ''ASSOCIATED_CAMP_CALLBACK'' END,
							(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [cam_id] FROM ccInbound WHERE Inbound_id = @InboundID)),
							(SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @InboundID)

						SELECT 1;
						RETURN 1;
					END;
			END;        
			IF(@Option = 6) -- Delete the relation between inbound and outbound campaigns
			BEGIN

			IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @InboundID)
							
				INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
				SELECT
					(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
					getDate(), 
					(SELECT [Login] FROM ccUsers WHERE User_id = @User_id), 
					@operation,
					@Module,
					CASE WHEN @Module = 13 THEN '''' ELSE ''DISASSOCIATED_CAMP_CALLBACK'' END,
					(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [cam_id] FROM ccInbound WHERE Inbound_id = @InboundID)),
					(SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @InboundID)

				UPDATE ccInbound SET cam_id = null WHERE Inbound_id = @InboundId;
				SELECT 1;
				RETURN 1;
			END;
			IF(@Option = 7) -- Check if the inbound Campaign is related
			BEGIN
				SELECT CAST(ISNULL(cam_id,-1) AS INT) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId;
			END
			IF(@Option = 8) -- Delete the relation between inbound campaings which are related to outdbound campaign
			BEGIN
				UPDATE ccInbound SET cam_id = null WHERE cam_id = @OutboundID;
				SELECT 1;
				RETURN 1;
			END
			IF(@Option = 9)
			BEGIN
				SET @Module = 3 --Corresponds to "Area", reference in ccGalateaModules
				SET @operation = CASE @IsEditing WHEN 1 THEN 138 ELSE 137 END -- Corresponds to edition and creation, reference ccGalateaOperations

				DECLARE @CurrentNonComprehensionId SMALLINT, 
						@CurrentCallbackId SMALLINT, 
						@CurrentSuccessfullTransactionId SMALLINT,
						@UserName VARCHAR(40),
						@AreaName VARCHAR(50),
						@CampaignName VARCHAR(40)

				SELECT @AreaName = AreaName  FROM ccRIACat_Areas WHERE IDArea = @AreaId
				SELECT @UserName = Login FROM ccUsers WHERE User_id = @User_id

				SELECT 
					@CurrentNonComprehensionId = ISNULL( idForNonComprehension , -1 ),
					@CurrentCallbackId = ISNULL( cam_id, -1 ),
					@CurrentSuccessfullTransactionId = ISNULL( idForSuccessfulTransaction, -1),
					@CampaignName = descripcion
				FROM ccInbound WHERE Inbound_id = @InboundId

				IF @CurrentCallbackId <> @CallBackCampaignId AND @CallBackCampaignId <> -1
				BEGIN
					UPDATE ccInbound
					SET cam_id = @CallBackCampaignId
					WHERE Inbound_id = @InboundId

					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@AreaName, 
							GETDATE(), 
							@UserName, 
							@operation, 
							@Module, 
							''ASSOCIATED_CAMP_CALLBACK'', 
							CASE @CallBackCampaignId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT cam_descripcion FROM ccCamps WHERE cam_id = @CallBackCampaignId) END,
							@CampaignName)
				END

				IF @CurrentNonComprehensionId <> @NonComprehensionId AND @NonComprehensionId <> -1
				BEGIN
					UPDATE ccInbound
					SET idForNonComprehension = @NonComprehensionId
					WHERE Inbound_id = @InboundId

					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@AreaName, 
							GETDATE(), 
							@UserName, 
							@operation, 
							@Module, 
							''ASSOCIATED_CAMP_XFER_IA'', 
							CASE @NonComprehensionId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT descripcion FROM ccInbound WHERE Inbound_id = @NonComprehensionId) END,
							@CampaignName)
				END

				IF @CurrentSuccessfullTransactionId <> @SuccessfulTransactionCampaignId AND @SuccessfulTransactionCampaignId <> -1
				BEGIN
					UPDATE ccInbound
					SET idForSuccessfulTransaction = @SuccessfulTransactionCampaignId
					WHERE Inbound_id = @InboundId

					INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
					VALUES (@AreaName, 
							GETDATE(), 
							@UserName, 
							@operation, 
							@Module, 
							''ASSOCIATED_CAMP_SUCCESSFUL_TRANSACTION'', 
							CASE @SuccessfulTransactionCampaignId WHEN 0 THEN ''COMMON_NONE_O'' ELSE (SELECT descripcion FROM ccInbound WHERE Inbound_id = @SuccessfulTransactionCampaignId) END,
							@CampaignName)
				END

				SELECT 1
			END
		END
    '
    EXEC(@sql);

	 SET @process = 'CW-9760 Drop sp ccsp_BaseXmngr'

    SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_BaseXmngr'')
    begin
        DROP PROCEDURE ccsp_BaseXmngr;
    end'
    EXEC(@sql);

	 SET @process = 'CW-9760 CREATE sp ccsp_BaseXmngr'

    SET @sql = '
	
    CREATE PROCEDURE ccsp_BaseXmngr
    @action int,
    @option tinyint = 0,
    @ids varchar(max)=null,
    @name varchar(25) = NULL,
    @top int = 0,
    @dateIni datetime =null,
    @dateEnd datetime =null,
    @dateStart dateTime= null,
    @userId int = 0,
    @node varchar(10) = null,
    @grabIds varchar(4000) = null
    AS

    declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
    declare @parameterDefinition nvarchar(max)
    declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
    declare @status tinyint
    declare @filterWg varchar(max)
    declare @len int
    declare @tipo int
    declare @serviceId varchar(10)

    set @sql = ''''

    select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=@option 

    if @action in (1,6) begin --obtiene los nodos a insertar en BX
        if @action = 1 set @status =0
        else if @action = 6 set @status = 2

        if @option <>2 begin

        declare @auxTag nvarchar(10)
                                
        select @auxTag =case when @option = 1 then ''@C09'' when @option in (3,4) then ''@C02''
        else ''@CDATE''   end
        set @parameterDefinition =N''@status int, @top int,@option int''
        set @sql=''declare @basexName varchar(max)
    select @basexName=Xname from ccBaseXDB where serviceId=@option and isFull=0;
        with node ( ''+@columnId+ '',xmlString,dateNode)
        AS(
            select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
            ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
            from ''+ @tableName + '' A with(rowlock)
            where A.status =@status
            union
            select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
            ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
            from ''+ @tableNameHistory + '' A with(rowlock)
            where A.status =@status  
        )

        select node.''+@columnId+ '',node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
        left join ccBaseXDB baseX on baseX.serviceId= @option and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
        order by Xname''
        --print(@sql)
        EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top,@option=@option
        end
    end
    else if @action in (2,7) begin--actualiza los nodos insertados en BX
        if @action = 2 set @status =0
        else if @action = 7 set @status = 2

        set @parameterDefinition =N''@status int''

        set @sql = ''update ''+@tableName+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
        select @tableName,@columnId,@ids,@sql
        EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
        set @sql = ''update ''+@tableNameHistory+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
        --print(@sql)
        EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status

    end
    else if @action = 3 --trae el nombre de la base de datos en BX
    begin
        select Xname from ccBaseXDB where serviceId = @option and isFull=0
    end
    else if @action = 4 --inserta el nombre del xml en BX
    begin
        insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option,@dateStart, @name,0)
    end
    else if @action = 5 begin --obtener servicios disponibles    
        select id, ref  from ccFinderServices where isActive=1
    end
    else if @action = 8 begin--trae la lista de las bases para la busqueda
        select Xname from ccBaseXDB where serviceId = @option
        and (

        @dateIni between dateStart and dateEnd
        or @dateEnd between dateStart and dateEnd
        or dateStart between @dateIni and @dateEnd
        )
        union
        select Xname from ccBaseXDB where serviceId = @option and isFull=0
        and (
            dateStart between @dateIni and @dateEnd
            or @dateIni>=dateStart

        )
    end
    else if @action = 9 begin--Cierra la base datos
        update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()), dateStart=isnull(@dateStart,dateStart) where serviceId= @option and  isfull = 0 and dateEnd is null
        and Xname=@name
    end

    else if @action = 10 begin
        
        set @tipo = CASE WHEN @node = ''R06'' THEN 1 ELSE 0 END
        set @filterWg=''''
        if @node is null or @node = ''R02''
        begin
            select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
            inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
            where Wguser.User_id=@userId
                            
        end
        else
        begin
        
        set @serviceId = (select convert(varchar(10), id) from ccFinderServices where ref = @node)
        select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+@serviceId+'') or '' from ccRIAWorkGroupUsers Wguser
            inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
            where Wguser.User_id=@userId and WGCam.Tipo=@tipo
        end


        set @len=len(@filterWg)- CHARINDEX(''ro )'', REVERSE(@filterWg))
        select SUBSTRING(@filterWg,0, @len)
        end


    else if @action = 11 begin--trae el nombre de la base de datos en BX

        set @sql=''
        declare @dateStart datetime
        set @dateStart= convert(datetime,convert(varchar(10),getdate(),121))
        SELECT isnull(min(dateIn),@dateStart) as node FROM ''+@tableName+'' where status = 0  ''
        EXECUTE sp_executesql  @sql

    end

    else if @action = 13 begin
        set @sql = ''''
        select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=5 
        select @tableName,@tableNameHistory,@columnId
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
        declare @CidNameOut varchar(100),@CidNameIn varchar(100)
        declare @filterCamId varchar(max), @filterInboundId varchar(max);
        declare @campType int
        declare @cidOut varchar(max)=''''
        declare @cidin varchar(max)=''''

        set @filterWg=''''
        if @node is null begin
            set @node=''R02''
        end

        set @CidNameOut=''$CID_OUT''
        set @CidNameIn=''$CID_IN''

        set @filterCamId=''''
        
        select @filterCamId=@filterCamId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
        from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        inner join ccCamps c on c.cam_id=WGCam.IdCampEsp --and c.CampType not in(5,7)
        where Wguser.User_id=@userId and WGCam.Tipo=1                               
        

        if @filterCamId<>'''' begin
            set @filterWg=''let ''+@CidNameOut+'':=(''

            set @filterCamId=SUBSTRING(@filterCamId,0,len(@filterCamId))
            set @filterCamId=@filterCamId+'')''+char(10)    

            set @filterWg=@filterWg+@filterCamId
            set @cidOut=''(exists(index-of($CID_OUT, $r/@CID)) and $r/@CType = CTYPE_REMPLACE)''
        end
        else begin 
         set @filterWg=''let ''+@CidNameOut+'':=(0)''
         set @filterCamId=0
        end

        SET @filterInboundId= ''''
                
        select @filterInboundId=@filterInboundId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
        from ccRIAWorkGroupUsers Wguser
            inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
            inner join ccInbound c on c.Inbound_id=WGCam.IdCampEsp
            where Wguser.User_id=@userId and WGCam.Tipo=0
        
        if @filterInboundId<>'''' begin
            set @filterInboundId=SUBSTRING(@filterInboundId,0,len(@filterInboundId))
            set @filterInboundId=@filterInboundId+'')''+char(10)    

            set @filterWg=@filterWg+''let ''+@CidNameIn+'':=(''+@filterInboundId
            set @cidin=''(exists(index-of($CID_IN, $r/@CID)) and $r/@CType = CTYPE_REMPLACE)''
        end
        else begin
          set @filterWg=@filterWg+''let ''+@CidNameIn+'':=(0)''
          set @filterInboundId=0
        end
        
        select @filterWg as VarCamInOut,@cidOut as CidOut,@cidin as CidIn
    end
    else if @action = 15 begin --Saber si hacer busqueda en basex
      select @tableName=tableName,@tableNameHistory=tableNameHistory from ccFinderServices where ref=@node
      if @node=''R02'' begin
        select 1
        return(0)
      end

      set @sql=''if exists(select * from ''+@tableName+'') begin
            select 1
        end
        else if exists(select * from ''+@tableNameHistory+'') begin
            select 1
        end
        select 0''
        exec (@sql)
        
    end
	else if @action = 16 begin
    select id,serviceId,dateStart,dateEnd,Xname,isFull
	FROM ccBaseXDB 
	WHERE serviceId=2
end'
    EXEC(@sql);


    ----------------------- END Carlos Muñoz -----------------------

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
