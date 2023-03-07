/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/05/23
Description: Archivo julio 2022, cambios preview
Date: 2022/02/15
Description: Merge con los cambios de sorteos

Database: CCenterRia
Required version: 124.13

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
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 1
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF (@actualVersion =@version-1 and @actualVersionFix >= 53) or  (@actualVersion =@version and @actualVersionFix =@versionfix)
BEGIN
	BEGIN TRAN

	BEGIN TRY	
	-------------------------------Preview K004009 DetalleMarcación --------------------------------

	set @process = 'Alter column reg_date from RegProcessPreviewRecord'
    set @sql = '
		if ( exists (select * from sys.columns where name = N''reg_date'' and Object_ID = Object_ID(N''RegProcessPreviewRecord'') )and 
			(select DATA_TYPE from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME=''RegProcessPreviewRecord''and COLUMN_NAME=''reg_date'') != ''datetime'')
		begin
			ALTER TABLE RegProcessPreviewRecord ALTER COLUMN reg_date datetime
		end
	'
    EXEC(@sql)

	set @process = 'Add columns CallId and tPreview to RegProcessPreviewRecord'
    set @sql = '
		if not exists (select * from sys.columns where name = N''tPreview'' and Object_ID = Object_ID(N''RegProcessPreviewRecord''))
		begin
			alter table RegProcessPreviewRecord add tPreview smallint not null default 0
		end

		if not exists (select * from sys.columns where name = N''callId'' and Object_ID = Object_ID(N''RegProcessPreviewRecord''))
		begin
			alter table RegProcessPreviewRecord add callId int not null default 0
		end
	'
    EXEC(@sql)

    set @process = 'Alter table ccsp_RegProcessPreviewRecord'
    set @sql = '
		ALTER PROCEDURE [dbo].[ccsp_RegProcessPreviewRecord](
        @process smallint,
        @callout_id int,
        @agent_id smallint,
        @camId int,
		@previewTime smallint,
		@callId int)
        AS
        DECLARE @result_callout_id INT
        if(exists(select top 1 1 from ccoWorkingTable nolock where callout_id = @callout_id)) begin
            set @result_callout_id =1
        end
        IF (@result_callout_id > 0 or @process in (4,7))
        BEGIN
            INSERT INTO RegProcessPreviewRecord(userId,process,callout_id,camId,reg_date,tPreview, callID) VALUES (@agent_id,@process,@callout_id,@camId,SYSDATETIME(),@previewTime,@callId)
		END
        IF (@process=1 AND @result_callout_id > 0)
        BEGIN
            DELETE ccoWorkingTable WHERE callout_id = @callout_id
        END
	'
    EXEC(@sql)

    set @process = 'SPEC-72 Alter column descripcion from ccTipoResultadoDial'
    set @sql = '
		ALTER TABLE ccTipoResultadoDial ALTER COLUMN descripcion varchar(50);
	'
    EXEC(@sql)

	set @process = 'Create table ccTypeProcessPreview'
    set @sql = '
		if not exists (select * from sys.tables where name = N''ccTypeProcessPreview'')
		begin
			create table ccTypeProcessPreview(
			typeProcess_id tinyint primary key not null,
			descripcion varchar (20) not null,
			translatedDesc varchar (50) not null)
		end
	'
    EXEC(@sql)

    set @process = 'SPEC-72 Inserta ccTIpoResultadoDial catalogo'
    set @sql = '
		--Paso 2 actualizar catalogo

declare @idioma tinyint
select @idioma =valor from ccSettings where setting_id=27

delete from [ccTipoResultadoDial]

if @idioma = 0
begin
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, convert(text, N''Contestan'' collate SQL_Latin1_General_CP1_CI_AS))
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, convert(text, N''Ocupado'' collate SQL_Latin1_General_CP1_CI_AS))
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, convert(text, N''No Contesta'' collate SQL_Latin1_General_CP1_CI_AS))
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, convert(text, N''Fax/Modem'' collate SQL_Latin1_General_CP1_CI_AS))
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, convert(text, N''NoDialTone'' collate SQL_Latin1_General_CP1_CI_AS))
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, convert(text, N''NoService'' collate SQL_Latin1_General_CP1_CI_AS))
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, convert(text, N''Buzon/Maquina'' collate SQL_Latin1_General_CP1_CI_AS))
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, convert(text, N''Congestion'' collate SQL_Latin1_General_CP1_CI_AS))
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, convert(text, N''Cancelado'' collate SQL_Latin1_General_CP1_CI_AS))
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (90, convert(text, N''Rechazada por proveedor'' collate SQL_Latin1_General_CP1_CI_AS))
end

if @idioma = 1
begin
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Answer'')
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Busy'')
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Not Answer'')
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax/Modem'')
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Other'')
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, ''NoService'')
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, ''VoiceMail/Machine'')
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, ''Circuit busy'')
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, ''Cancelled'')
	INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (90, ''Rejected by carrier'')
end
if @idioma = 2
begin
	INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Resposta'')
	INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Ocupado'')
	INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Não resposta'')
	INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax / Modem'')
	INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
	INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Outros'')
	INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10,''NOservice'')
	INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11,''Correio de Voz/Máquina'')
	INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12,''Circuito ocupado'')
	INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13,''Cancelado'')
	INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (90, ''Rejeitada pela operadora'')
end
	'
    EXEC(@sql)

	set @process = 'Add data to ccTypeProcessPreview'
    set @sql = '		
		if not exists(select typeProcess_id from ccTypeProcessPreview where typeProcess_id = 0)
			begin
			insert into  ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (0, ''Discard'',''systemTranslated_Discard'')
			end
		 if not exists(select typeProcess_id from ccTypeProcessPreview where typeProcess_id = 1)
			begin
			insert into  ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (1, ''Delete'',''systemTranslated_DeletePreview'')
			end
		 if not exists(select typeProcess_id from ccTypeProcessPreview where typeProcess_id = 2)
			begin
			insert into  ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (2, ''DiscardByTime'',''systemTranslated_DiscardByTime'')
			end
		 if not exists(select typeProcess_id from ccTypeProcessPreview where typeProcess_id = 3)
			begin
			insert into  ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (3, ''DiscardByND'',''systemTranslated_DiscardByND'')
			end
		 if not exists(select typeProcess_id from ccTypeProcessPreview where typeProcess_id = 4)
			begin
			insert into  ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (4, ''DiscardByXfer'',''systemTranslated_DiscardByXfer'')
			end
		 if not exists(select typeProcess_id from ccTypeProcessPreview where typeProcess_id = 7)
			begin
			insert into  ccTypeProcessPreview (typeProcess_id,descripcion,translatedDesc) values (7, ''WithDialResult'','''')
			end		
	'   
	EXEC(@sql)
	-------------------------------BEGIN MENUS --------------------------------

	set @process = 'K002056 se agregan menus'
    set @sql = 'if not exists( select * from ccmenus where type=3 and menu_id=12000)
begin
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
	values(12000,''WhatsApp|WhatsApp'',12000,''A'',7,3,'''',''9f1901c17c425d0a50eb4ef481632d34b736aa1dae75e5134dd5c15d4dde150d'')

	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
	values(12010,''Detalle de conversaciones|Conversations Detail'',12000,''B'',7,3,'''',''accb20a46285ea9856ace61e5e3ffd452de1f55f20c7a005ce8e05a503060fb18beee994719b6abd36ad36efaffd0370'')

	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
	values(12020,''Conversaciones por campaña|Conversations by Campaign'',12000,''B'',7,3,'''',''2605c8244920fb599fb936a4bf94521a7284d5e414815e8ef15fa8f6b0040db16a54ce29b02250a22a8cb87c41c6f3b30e3860a31b59d733442bb174a555b7b2'')

end'
	EXEC(@sql)

    set @process = 'K002056 se actualiza el orden de los menus'
    set @sql = '
    update ccMenus set ordengral = 8 where type = 3 and parent = 6000
update ccMenus set ordengral = 9 where type = 3 and parent = 8000
update ccMenus set ordengral = 10 where type = 3 and parent in  (8050,8060,8080)
update ccMenus set ordengral = 11 where type = 3 and parent = 7000
update ccMenus set ordengral = 12 where type = 3 and parent = 9000'
    EXEC(@sql)

    set @process = 'K002056 Se altera ccsp_RIACATMenu'
    set @sql = 'ALTER procedure [dbo].[ccsp_RIACATMenu]
@id_User varchar(2000),
@id_Menu int,
@Type tinyint,
@ReportRol tinyint = 1,
@CM tinyint = 1,
@AE tinyint = 1
as
set nocount on
Declare @NRS tinyint
Declare @AVRS tinyint
Declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenusChat tinyint
Declare @MenuMail tinyint
Declare @MenuCRM tinyint
Declare @monitorPortMenu tinyint

set @MenuMail=0
set @MenuCRM = 0
set @monitorPortMenu =0

select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
select @AVRS = valor from ccSettings where setting_id = 124
select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
select @IVRScripting = valor from ccsettings where setting_id = 125
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155
select @MenuCRM = valor from ccsettings where setting_id = 168
select @monitorPortMenu = case when valor=''1'' then 1 else 0 end from ccsettings where setting_id = 186

---Mail MenuId (81)
if @Type=1
begin
	if @ReportRol = 1
	begin
		Select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus)) where type = 1
		and (
		(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82,83,84,85,69))
		or (menu_id = 41 and @CM = 1)
		or (menu_id = 42 and @AE > 0)
		or (menu_id = 53 and @NRS = 1)
		or (menu_id in (71,72) and @IVRScripting = 1)
		or (menu_id in (73,74,75,76) and @AVRS = 1)
		or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
		or (menu_id = 79 and @MenusChat > 0)
		or (menu_id in (81,82,84,85) and @MenuMail = 1)--Mail
		or (menu_id = 83 and @MenuCRM > 0)
		or (menu_id = 69 and @monitorPortMenu > 0)--Monitoreo de puertos
		)
		order by ordengral asc
		return(0)

	end
	else if @ReportRol = 3 begin
		select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) and menu_id not in (select distinct Parent from ccMenus where menu_id >= 2000 and type = 3)
		and (menu_id not in (3131,3132,3133,3134,3135,3136,8061,8062,8063,8071,8072,8080,10000,10010,10020,10030,10040))
		or  (menu_id     in (3131,3132,3133,3134,3135,3136) and @MenusChat > 0 )
		or  (menu_id     in (8061,8062,8063,8071,8072,8080) and @AVRS > 0)
		or  (menu_id     in (9000,9010) and @MenuCRM > 0 )
		or  (menu_id     in (10000,10010,10020,10030,10040) and @MenuMail > 0 )
		order by ordengral asc,menu_id
		return(0)
	end
	else begin
		select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
		return(0)
	end

end

if @Type=2
begin
	delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu and type = @ReportRol
	return(0)
end

if @Type=3
begin
	insert into ccMenuUser(id_User,id_Menu,type) values (@id_User, @id_Menu,@ReportRol)
	return(0)
end

if @Type=4
begin
	declare @lan varchar(3), @page varchar(200)
	select @page = ''http://''+valor+''/'' from ccSettings where setting_id = 58
	select @lan = case valor when 0 then ''ES'' else ''EN'' end from ccSettings where setting_id = 27

	select ''Help/''+@lan+''/''+ cast(@id_Menu as varchar)+''.swf'' HelpSWF, @page page, @lan lang
	return(0)
end

set nocount off'
    EXEC(@sql)
	-------------------------------END MENUS --------------------------------

	 -------------------------  Start CCC --------------------------------------------------
	 set @process = 'K002124-Mensajes recibidos en conversación al existir una desconexión en el servicio MultimediaCommon'
     set @sql = 'ALTER PROCEDURE [dbo].[ccsp_Multimedia2] @action INT, @inboundId INT = NULL, @userId INT = NULL, @senderId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	IF @action = 1
	BEGIN --Lista  ACD
		SELECT DISTINCT A.inbound_id AS Id, A.chat AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets,
		cast(isnull(C.maxWhats, 3) AS TINYINT) AS MaxWhats, A.IDArea AS AreaId
		FROM ccInbound A
		INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
		WHERE @inboundId IS NULL OR @inboundId = A.Inbound_id
	END
	ELSE IF @action = 2
	BEGIN --Lista Agentes
		SELECT DISTINCT A.User_id AS [Id], C.idCampEsp AcdId, isnull(skill, 8) Skill
		FROM ccRIAWorkGroupUsers A
		INNER JOIN ccusers B ON A.User_id = B.User_id
		INNER JOIN ccRIACampEspWG C ON C.IDWG = A.IDWG AND C.Tipo = 0
		INNER JOIN ccInbound D ON C.idCampEsp = D.inbound_id
		LEFT JOIN ccskills S ON S.inbound_id = D.inbound_id AND S.user_id = B.user_id
		WHERE B.TipoUser_id = 1 AND (@userId IS NULL OR @userId = A.User_id)
		ORDER BY A.User_id
	END
	ELSE IF @action = 3
	BEGIN --List Sender Mail
		SELECT A.contactMeanOutId AS Id, ISNULL(R.inboundId, 0) AS AcdId, A.isActive AS IsActive
		FROM contactMeanOut A
		LEFT JOIN relationContactMeanOutInbound R ON A.contactMeanOutId = R.contactMeanOutId
		WHERE @senderId IS NULL OR @senderId = A.contactMeanOutId
	END
	ELSE IF @action = 4
	BEGIN --List ACD Whatsapp
		SELECT  inboundId AS Id
		FROM contactMeanIn
		WHERE meanContactTypeId = 5
	END
END'
	 EXEC(@sql)

	-------------------------  END CCC --------------------------------------------------

-------------------------------START CAPACITACION --------------------------------
set @process = 'Correcion ALter SP ccsp_GalateaAdminANIListLD Capacitacion'
        set @sql='ALTER PROCEDURE [dbo].[ccsp_GalateaAdminANIListLD]
@type as tinyint,
@idArea as smallint,
@descriptionList as varchar(40) = NULL,
@idAniList as smallint = NULL,
@cld as varchar(max)= NULL,
@aniTel as varchar(30)= NULL,
@edo as varchar(350) = NULL
AS
set nocount on
declare @pais tinyint, @listEdos varchar(4000), @idLista as integer, @sql as varchar(500)
select @pais = valor from ccsettings where setting_id = 104

select @listEdos = ''select distinct '' + case @type when 1 then
case @pais  when 1  then ''estado as [state] ''
            when 2  then ''estado as [state] ''
            when 3  then ''municipio as [state] ''
            when 4  then ''location as [state] ''
            when 5  then ''cld as [state] ''
            when 6  then ''region as [state] ''
            when 7  then ''region as [state] ''
            when 8  then ''Regiones as [state] ''
            when 9  then ''Regiones as [state] ''
            when 10 then ''Regiones as [state] ''
            when 11 then ''zonaGeografica as [state] ''
            when 12 then ''zonaGeografica as [state] ''
            when 13 then ''zonaGeografica as [state] ''
            when 14 then ''provincia as [state] ''
            else '''' end
when 4 then
case @pais  when 1  then ''estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 2  then ''estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 3  then ''municipio as estado, region +''''''''+ serie as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 4  then ''location as estado, area, @id_anilist as id_anilist, '''''''' as telani ''
            when 5  then ''cld as estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 6  then ''region as estado, LD as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 7  then ''region as estado, CLD as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 8  then ''Regiones as estado, cld +''''-''''+ [serie inicio] as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 9  then ''Regiones as estado, LD + AreaCode as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 10 then ''Regiones as estado, AreaCode as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 11 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 12 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 13 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
            when 14 then ''provincia as estado, indicativoProvincia as area, @id_anilist as id_anilist, '''''''' as telani ''
            else '''' end
end + ''from '' +
case @pais  when 1  then ''series''
            when 2  then ''seriesarg where estado <> ''''''''''
            when 3  then ''seriescol''
            when 4  then ''ccTimeZoneArea where id_country = '' + convert(varchar(5),@pais) + ''''
            when 5  then ''serieschi''
            when 6  then ''SeriesVen''
            when 7  then ''SeriesUK''
            when 8  then ''SeriesSA''
            when 9  then ''SeriesAU''
            when 10 then ''SeriesBR''
            when 11 then ''SeriesGT''
            when 12 then ''SeriesCR''
            when 13 then ''SeriesSV''
            when 14 then ''SeriesEsp''
            else '''' end + ''''

if @type=1
begin   --Get locations / states
    print (@listEdos + '' order by [state]'')
    exec(@listEdos + '' order by [state]'')
    return(0)
end

if @type=2
begin
    select @sql = ''select id_AniList, description from ccEdoAniList where idArea = '' + convert(varchar(5),@idArea) +
    case when isnull(@idAniList,'''') <> '''' then '' and id_AniList = '' + convert(varchar(5),@idAniList) else '''' end
    exec(@sql)
    return(0)
end

if @type=3
begin   -- Get Outbound telAni with Area Codes
    select @sql = ''select id_AniList, Estado, telAni, area from ccEstadosAni where id_AniList = '' + convert(varchar(5),@idAniList) +
    '' and estado like ''''%'' + @edo + ''%'''' and id_AniList in (select id_AniList from ccEdoAniList where idArea = '' +
     convert(varchar(5),@idArea) + '') order by estado''
    exec(@sql)
    --print(@sql)
    return(0)
end

if @type=4
begin  --Insert new aniList
    if @descriptionList <> '''' begin
        select @idAniList=id_AniList from dbo.ccEdoAniList where [description]=@descriptionList
        if @idAniList is not null and @idAniList>0
        begin
            select cast(2 as int) [result],cast(@idAniList as int) as id_AniList,@descriptionList as[description]
            return(0)
        end
        insert into ccEdoAniList values(@descriptionList, @idArea)
        select @idLista = id_anilist from ccEdoAniList where [description] = @descriptionList
        set @listEdos = ''insert into ccEstadosAni (estado, area, id_anilist, telani) '' + @listEdos
        set @listEdos = replace(@listEdos, ''@id_anilist'', convert(varchar(6),@idLista))
        exec(@listEdos)
        print(@listEdos)
        select @idAniList=Scope_identity()
        select cast(1 as int) [result],cast(@idAniList as int) as id_AniList,@descriptionList as[description]
        return(0)
    end
    set @idAniList=0
    select cast(0 as int) [result] ,cast(@idAniList as int) as id_AniList,@descriptionList as[description]
    return(0)
end

if @type=5
begin --Save ANI number

    select @descriptionList=[description] from dbo.ccEdoAniList where id_anilist = @idAniList

    update ccEstadosAni set telani= ISNULL(@aniTel, TELANI) WHERE id_anilist = @idAniList
    and area in (select value from dbo.fn_RIASplitDelimited(@cld, '',''))

    select cast(1 as int) [result],cast(@idAniList as int) as id_AniList,@descriptionList as[description]
    return(0)
end

if @type=6
begin --Delete ANI list
    if not exists(select id_anilist from ccEdoAniList WHERE id_anilist = @idAniList  )
     begin
        select cast(-1 as int) [result],cast(@idAniList as int) as id_AniList,@descriptionList as[description]
        return(0)
     end

     select @descriptionList=[description] from dbo.ccEdoAniList where id_anilist = @idAniList and idarea = @idArea

    delete from ccEstadosAni where id_anilist = @idAniList
    delete from ccEdoAniList WHERE id_anilist = @idAniList

    select cast(1 as int) [result],cast(@idAniList as int) as id_AniList,@descriptionList as[description]
    return(0)
end

if @type=7
begin --Update ANI list name
    if(exists(select [description] from ccEdoAniList where [description]=@descriptionList and id_AniList<>@idAniList))
    begin
        select cast(2 as int) [result],cast(@idAniList as int) as id_AniList,@descriptionList as[description]
        return(0)
    end

    update ccEdoAniList set [description]=@descriptionList where id_AniList=@idAniList
    select cast(1 as int) [result],cast(@idAniList as int) as id_AniList,@descriptionList as[description]
    return(0)
end
'
        EXEC(@sql)

-------------------------------END CAPACITACION --------------------------------

	set @process = 'CW-6949 ST_2022_05_301 alter configuraIdiomaCatalogosEspañol'
    set @sql='ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEspañol] AS
SET NOCOUNT ON

Print ''Iniciando proceso de configuracion en Español''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Semana'' collate SQL_Latin1_General_CP1_CI_AS), 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Nocturno'' collate SQL_Latin1_General_CP1_CI_AS), 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady]
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''No Clasificado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Break'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Tocador'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Con Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Aclaracion'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Junta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Comida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Sistemas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))

DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
delete from [dbo].[ccStatusLLamada]

INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, convert(text, N''Inicial'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, convert(text, N''Fuera de Horario'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, convert(text, N''Fuera de Servicio'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, convert(text, N''Sin Agentes Firmados'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, convert(text, N''En espera'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, convert(text, N''Colgada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, convert(text, N''Desborde por Tiempo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, convert(text, N''Desborde por Cantidad'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, convert(text, N''Con Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, convert(text, N''Asignada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, convert(text, N''Asignada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, convert(text, N''Atendida Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, convert(text, N''Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, convert(text, N''Cancelada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, convert(text, N''Asignada y No Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, convert(text, N''Asignada y Toma Linea'' collate SQL_Latin1_General_CP1_CI_AS))
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
truncate table [dbo].[ccTipoDias]
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo resultados de marcacion''
delete from [dbo].[ccTipoResultadoDial]

INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, convert(text, N''Contestan'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, convert(text, N''Ocupado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, convert(text, N''No Contesta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, convert(text, N''Fax/Modem'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, convert(text, N''NoDialTone'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, convert(text, N''NoService'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, convert(text, N''Buzon/Maquina'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, convert(text, N''Congestion'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, convert(text, N''Cancelado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (90, convert(text, N''Rechazada por proveedor'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de estado de los agentes''
Delete [dbo].[ccTipoStatusAgente]

INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, convert(text, N''LogOut'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, convert(text, N''Desconocido'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, convert(text, N''No Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, convert(text, N''Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, convert(text, N''Dialogo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, convert(text, N''Transferencia'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, convert(text, N''Notas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, convert(text, N''Otra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, convert(text, N''Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, convert(text, N''Ringing'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, convert(text, N''Problema'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, convert(text, N''Espera llamada manual'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N''ChatReq'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N''Chatting'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, convert(text, N''Transferencia Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, convert(text, N''Ringing Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (30, convert(text, N''ReconnectKolob'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, convert(text, N''Ready PreviewPro'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (32, convert(text, N''Preview'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (33, convert(text, N''Asistida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (35, convert(text, N''Inactivo'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, convert(text, N''Agente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, convert(text, N''AVRS Calidad'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
DBCC CHECKIDENT (''[ccDias]'', RESEED, 0)
SET IDENTITY_INSERT [ccDias] ON
INSERT [ccDias] ([dia_id], [Name]) VALUES (1, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (2, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (3, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (4, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (5, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (6, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (7, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccDias] OFF

Print ''Estableciendo los tipos de llamada''
delete from [dbo].cstoTarifa
delete cstoTipoLlamada

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''LD nacional'',''12'',''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Cel'',''13'',''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''Cel LD'',''13'',''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''LD USA'',''13'',''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''LD inter'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''LADA local 2 dígitos'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''Local lada 3 digitos'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''Local lada 4 digitos'',''6'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''Cel LADA local 2 dígitos'',''10'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''Cel LADA local 3 dígitos'',''9'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''Cel LADA local 4 dígitos'',''8'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Larga distancia'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Cel larga distancia'',''13'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Celular'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''LD Nacional'',''11'',''1%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''LD Nacional'',''10'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Celular'',''11'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Cel'',''11'',''07%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''LD inter'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''LD anterior'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Cel'',''10'',''05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''LD actual'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''LD inter'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''LD inter'',''0'',''0011%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Cel'',''10'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Movil '',''8'',''6%|7%|8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''Celular 9 dígitos '',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''LD Nacional'',''10'',''02%|03%|04%|05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''Cel LD nacional'',''10'',''06%|07%|08%|09%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''Cel LD nacional 9 dígitos'',''11'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''LD internacional'',''19'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Movil'',''8'',''3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''LD Nacional'',''8'',''7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''LD internacional'',''8'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''Telefonía SIP'',''8'',''4%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Telefonía móvil'',''8'',''5%|6%|7%|8%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Cobro Revertido'',''10'',''800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Tarifa Prima'',''10'',''90%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Acceso Internet'',''10'',''900%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Especial'',''0'',''08%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Fijo'',''8'',''2%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Movil'',''8'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Celular'',''9'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Servicios web'',''9'',''5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''LD nacional'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Cel'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''LD inter'',''0'',''00%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, convert(text, N''Carga Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, convert(text, N''Lista Negra en Carga de Registros'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, convert(text, N''Eliminado por Aplicar Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, convert(text, N''Eliminado de Lista Negra por Remplazo '' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, convert(text, N''Borrado de Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, convert(text, N''Agregado por calificación por campaña'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, convert(text, N''Carga Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, convert(text, N''Carga Registro Cliente Lista Negra''collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (9, convert(text, N''Agregado por calificación por ACD'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, convert(text, N''Solicita información general'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, convert(text, N''Se cortó la llamada'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, convert(text, N''Número equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, convert(text, N''Gestión Efectiva'' collate SQL_Latin1_General_CP1_CI_AS), 0, 0, 1)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, convert(text, N''Se deja recado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 2)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, convert(text, N''Numero Equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [dbo].[cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telmex'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Maxcom'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Avantel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''AT&T'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telnor'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Axtel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telular'')

Print ''Mensajes voz default''
DELETE [dbo].[ccMsgFiles]
DBCC CHECKIDENT (''[ccMsgFiles]'', RESEED, 0)
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default5'', ''Mensaje Bienvenida'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default4'', ''Mensaje Transferencia'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default3'', ''Mensaje Fuera de servicio'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default2'', ''Mensaje Fuera de horario'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default1'', ''Mensaje En espera'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default7'', ''Mensaje Sin agentes firmados'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default9'', ''Mensaje VoiceMail'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default10'', ''Mensaje Desborde'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default11'', ''Lista Negra'')


Print ''Mensajes default chat''
DELETE [dbo].[ccRIAChatInboundMsgs]
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default5'', ''!Bienvenido!'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default3'', ''El servicio no se encuentra disponible'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default2'', ''Nuestro horario de atención ha terminado'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default1'', ''Por favor espere mientras uno de nuestros agentes se encuentra disponible'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default7'', ''No hay agentes disponibles'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default10'', ''No podemos tomar su solicitud'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default12'', ''La sesión de chat ha estado inactiva mucho tiempo'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default13'', ''La sesión de chat ha concluido'')
				'
	EXEC(@sql)

	set @process = 'CW-6949 ST_2022_05_301 alter configuraIdiomaCatalogosEnglish'
    set @sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEnglish]
	AS
Print ''Iniciando proceso de configuracion en Ingles''

Print ''Estableciendo Horarios''
Delete [ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Week'', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Night shift'', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Saturday'', 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Sunday'', 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [ccTipoNotReady]
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Not Clasified'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Break'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Bathroom'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''With client'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Supervisor'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Clarification'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Meeting'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Lunch'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Systems'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Other'')


DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
delete from [ccStatusLLamada]

INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, ''Initial'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Out of Schedule'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Out of Service'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''No Agents Logged in'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''On Hold'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandoned'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Time overflow'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Queue size overflow'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''With Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, ''Assigned Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, ''Assigned'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, ''Attended Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, ''Answered'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, ''Canceled Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, ''Assigned and Not Answered'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, ''Assigned and took line'')
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [ccTipoDias]
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, ''Monday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, ''Tuesday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, ''Wednesday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, ''Thursday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, ''Friday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, ''Saturday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, ''Sunday'')

Print ''Estableciendo resultados de marcacion''
delete from [ccTipoResultadoDial]

INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Answer'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Busy'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Not Answer'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax/Modem'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Other'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, ''NoService'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, ''VoiceMail/Machine'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, ''Circuit busy'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, ''Cancelled'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (90, ''Rejected by carrier'')

Print ''Estableciendo los tipos de estado de los agentes''
DELETE [ccTipoStatusAgente]

INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, ''LogOut'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, ''Unknown'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, ''Not Ready'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, ''Ready'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, ''Talking'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, ''Transfer'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, ''Wrapup'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, ''Other'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, ''Client'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, ''Ringing'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, ''Problem'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, ''Wait for manual call'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N''ChatReq'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N''Chatting'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, ''Xfer Fail'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, ''Ringing Fail'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (30, ''ReconnectKolob'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, ''Ready PreviewPro'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (32, ''Preview'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (33, convert(text, N''Assisted'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (35, convert(text, N''Idle'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de usuario''
Delete [ccTipoUsers]
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, ''Agent'')
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, ''Supervisor'')
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, ''AVRS Access'')

Print ''Estableciendo los dias''
Delete [ccDias]
DBCC CHECKIDENT (''[ccDias]'', RESEED, 0)
SET IDENTITY_INSERT [ccDias] ON
INSERT [ccDias] ([dia_id], [Name]) VALUES (1, ''Sunday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (2, ''Monday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (3, ''Tuesday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (4, ''Wednesday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (5, ''Thursday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (6, ''Friday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (7, ''Saturday'')
SET IDENTITY_INSERT [ccDias] OFF

Print ''Estableciendo los tipos de llamada''
delete from cstoTarifa
delete cstoTipoLlamada

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''National LD'',''12'',''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Mobile'',''13'',''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''LD Mobile'',''13'',''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''USA LD'',''13'',''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''Inter LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''2-digit Local Area Code'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''3-digit Local Area Code'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''4-digit Local Area Code'',''6'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''2-digit Local Mobile Area Code'',''10'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''3-digit Local Mobile Area Code'',''9'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''4-digit Local Mobile Area Code'',''8'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Long Distance'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Long Distance Mobile'',''13'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Mobile'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''National LD'',''11'',''1%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''National LD'',''10'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Mobile'',''11'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Mobile'',''11'',''07%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''Inter LD'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''Old LD'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Mobile'',''10'',''05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''New LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''Inter LD'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''Inter LD'',''0'',''0011%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Mobile'',''10'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Mobile '',''8'',''6%|7%|8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''9-digit Mobile'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''National LD'',''10'',''02%|03%|04%|05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''National Mobile LD'',''10'',''06%|07%|08%|09%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''9-digit National Mobile LD'',''11'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''International LD'',''19'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Mobile'',''8'',''3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''National LD'',''8'',''7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''International LD'',''8'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''SIP Telephony'',''8'',''4%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Mobile Telephony'',''8'',''5%|6%|7%|8%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Reverse Charge'',''10'',''800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Premium Rate'',''10'',''90%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Internet Access'',''10'',''900%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Special'',''0'',''08%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Landline'',''8'',''2%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Mobile'',''8'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Mobile'',''9'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Webservices'',''9'',''5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''National LD'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Mobile'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''Inter LD'',''0'',''00%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [ccTipoMovsListaNegra]
SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Added to black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Blocked on loading'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Removed from campaign'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Replaced from black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Deleted from black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Added by Disposition'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, ''Load black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, ''Load customer black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (9, ''Added by Inbound Disposition'')
SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [ccTipoCalif]
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, ''Wrong area'', 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, ''Disconnected call'', 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, ''Wrong number'', 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [ccTipoCalifOUT]
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, ''Effective call'', 0, 0, 1)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, ''Leave a message'', 0, 1, 2)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, ''Wrong number'', 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [cstoProvedor] ([descrip]) VALUES (''Carrier 1'')

Print ''Tipo Msg ChatLog'' -- No se hace delete ni truncate ya que se perderia la integridad si ya hay registros, los id ya deberian estar creados por lo cual se genera el update
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes an individual message to agent'' where TipoMsgChat=1
Update ccRIAChat_TipoMsg set MsgDetalle=''Agent writes a message to Administrator'' where TipoMsgChat=2
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes a global message'' where TipoMsgChat=3

Print ''Mensajes default''
DELETE [ccMsgFiles]
DBCC CHECKIDENT (''[ccMsgFiles]'', RESEED, 0)
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default5'', ''Welcome message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default4'', ''Transfer message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default3'', ''Out of service message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default2'', ''After hours message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default1'', ''In queue message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default7'', ''No agents signed in message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default9'', ''VoiceMail message'')
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default10'', ''Overflow message'')
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default11'', ''DNC list'')

Print ''Mensajes default chat''
DELETE [ccRIAChatInboundMsgs]
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default5'', ''Welcome!'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default3'', ''Service currently unavailable'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default2'', ''Our schedule service has finished'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default1'', ''Please hold while one of our agents is available'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default7'', ''There are not available agents'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default10'', ''Your request can not be processed'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default12'', ''Chat session has been inactive for too long'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default13'', ''Chat session has finished'')
'
    EXEC(@sql)


	set @process = 'CW-6949 ST_2022_05_301 Completar catalogo ccTipoMovsListaNegra '
	set @sql='DECLARE @valorLang INT;
select @valorLang = valor from ccSettings where setting_id = 27;
SET IDENTITY_INSERT ccTipoMovsListaNegra ON;
if @valorLang = 0
begin
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 1) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Carga Registro Lista Negra'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 2) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Lista Negra en Carga de Registros'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 3) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Eliminado por Aplicar Lista Negra'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 4) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Eliminado de Lista Negra por Remplazo '');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 5) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Borrado de Lista Negra'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 6) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Agregado por calificación por campaña'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 7) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, ''Carga Lista Negra'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 8) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, ''Carga Registro Cliente Lista Negra'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 9) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (9, ''Agregado por calificación por ACD'');
end
else begin
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 1) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Added to black list'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 2) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Blocked on loading'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 3) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Removed from campaign'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 4) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Replaced from black list'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 5) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Deleted from black list'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 6) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Added by Disposition'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 7) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, ''Load black list'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 8) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, ''Load customer black list'');
	if not exists (select * from ccTipoMovsListaNegra where idtipomov = 9) INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (9, ''Added by Inbound Disposition'');
end
SET IDENTITY_INSERT ccTipoMovsListaNegra OFF;
'
		EXEC(@sql)

	SET @process = 'CW-6672 Creacion de setting 233'

	SET @sql = '
	if not exists (select * from ccsettings where setting_id = 233)
	begin
		insert into ccsettings (setting_id, valor, descripcion, status, tipo, detalle, description, bloadSettings, validate) values
		(233, ''30|10'', ''Parametros que el servicio NuxibaMangementRecordsRepository tomará'', 1, ''GRL'', ''Tiempo en días maximo de antiguedad de una grabacion|Tiempo en minutos para hacer copia las grabaciones de servidor local a repositorios principal y secundario'', ''Time in days maximum age of a recording|Time in minutes to make a copy of the recordings from the local server to the main and secondary repositories'', 1, ''.*'')
	end '

	EXEC(@sql)

	SET @process = 'CW-6672 validación de sp ccsp_RecordsManagement'

	SET @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_RecordsManagement'')
	begin
		DROP PROCEDURE ccsp_RecordsManagement;
	end
	'

	EXEC(@sql)

	SET @process = 'CW-6672 Creacion de sp ccsp_RecordsManagement'

	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_RecordsManagement]
	@action as tinyint,
	@type as int = null,
	@initialPort as int = null,
	@finalPort as int = null,
	@maxOldDays as int = null,
	@callId as int = null,
	@fileMoved as int = null

	AS

	declare @maxDays as int

	SET NOCOUNT ON

	if @action = 1
	begin
		set @maxDays = @maxOldDays * -1

		if @type = 0
		begin
			select cast(cal_id as int) as cal_id from ccoCallsOut with(nolock) where cal_Inicio < DATEADD(DAY, @maxDays, getDate()) and cal_puerto between @initialPort and @finalPort
		end

		else if @type = 1
		begin
			select cast(cal_id as int) as cal_id from ccCallsIn with(nolock) where cal_Inicio < DATEADD(DAY, @maxDays, getDate()) and cal_puerto between @initialPort and @finalPort
		end

	end

	if @action = 2
	begin
		declare @time int
		if @type=0
		begin
			select @time=cal_tDialog from ccoCallsOut with(nolock) where cal_id=@callId
		end
		else
		begin
			select @time=cal_tDialog from ccCallsIn with(nolock) where cal_id=@callId
		end

		select case when @time > 0 then 1 else 0 end as result
	end

	if @action = 3
	begin
		if @type=0
		begin
			update ccoCallsOut set file_moved=@fileMoved where cal_id=@callId
		end
		else
		begin
			update ccCallsIn set file_moved=@fileMoved where cal_id=@callId
		end
	end

	if @action = 4
	begin
		declare @result as int = 0
		if @type = 0
		begin
			if exists (select * from ccoCallsOut with(nolock) where cal_id = @callId and cal_puerto between @initialPort and @finalPort)
			begin
				set @result = 1
			end
		end

		else if @type = 1
		begin
			if exists (select * from cccallsin with(nolock) where cal_id = @callId and cal_puerto between @initialPort and @finalPort)
			begin
				set @result = 1
			end
		end

		select @result as result
	end'

	EXEC(@sql)


		set @process = 'CW-7116 Estado inactivo'
	    set @sql = '
			if not exists(select top 1 1 from cctipostatusagente nolock where tipostatusage_id=33)
			begin
				insert cctipostatusagente values (33,''Assisted'')
			end
			if not exists(select top 1 1 from cctipostatusagente nolock where tipostatusage_id=35)
			begin
				insert cctipostatusagente values (35,''Idle'')
			end'
	    EXEC(@sql)

-------------------------------START RESUMEN OPERATIVO --------------------------------
	 set @process = 'K002107-ResumenOperativo se crea tabla'
     set @sql = 'if not exists (select * from sys.tables where name = N''ccWAOperatingSummary'')
begin
    CREATE TABLE [dbo].[ccWAOperatingSummary](
	[Inboundid] [INT] NOT NULL,
	[Attended] [INT] DEFAULT 0,
	[OnQueue] [INT] DEFAULT 0,
	[Assigned] [INT] DEFAULT 0,
	[Request] [INT] DEFAULT 0,
	[EndedBySystem] [INT] DEFAULT 0,
	[Available] [INT] DEFAULT 0)
end'
	 EXEC(@sql)

     set @process = 'K002107-ResumenOperativo se altera el sp ccsp_WhatsAppInformation || se corrige fix TT1966'
     set @sql = 'ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformation]
@Option SMALLINT,
@InboundId SMALLINT = 0,
@ConversationId INT = 0,
@AgentsAvailables INT = 0,
@IncreaseDecreaseAgent BIT = NULL

AS
SET NOCOUNT ON

IF @InboundId IS NOT NULL BEGIN
    IF EXISTS (SELECT * FROM ccInbound WHERE Inbound_id = @InboundId AND chat = 5) BEGIN
        DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
        --DECLARE @Today SMALLDATETIME = ''2022-03-24''
        IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
            BEGIN
                IF EXISTS (SELECT * FROM ccWAAverageConversations
                           WHERE InboundId = @InboundId
                           AND (LastUpdate IS NULL
                           OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
                           OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
                BEGIN
                    -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

                    DECLARE @AverageConversationTime INT = 0;
                    DECLARE @AverageDialogTime INT = 0;
                    DECLARE @AverageWaitingTime INT = 0;
                    DECLARE @MaximumWaitingTime INT = 0;
                    DECLARE @DefaultValue INT = (SELECT CASE 
                                                        WHEN defaultServiceLevelParameter IS NULL THEN 2 
                                                        WHEN defaultServiceLevelParameter = 0 THEN 2
                                                        ELSE defaultServiceLevelParameter END
                                                    FROM contactMeanIn WHERE inboundId = @InboundId);
                    SET @DefaultValue = @DefaultValue * 60;
                    DECLARE @LessThanDefault INT = 0;
                    DECLARE @ReceivedConversations INT = 0;
                    DECLARE @ServiceLevel SMALLINT = 0;

                    --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

                    SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
                           @AverageDialogTime = ROUND(AVG(tChatting), 4),
                           @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
                           @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
                           @ReceivedConversations = COUNT(conversationDate),
                           @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
                    FROM ccWhatsAppConversations WHERE inboundId = @InboundId
                    AND requestDate >= @Today

                    SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

                    ----------------------------------------------------- Update table --------------------------------------------------------

                    IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
                    BEGIN
                        UPDATE ccWAAverageConversations
                        SET AverageConversationTime = @AverageConversationTime,
                            AverageDialogTime = @AverageDialogTime,
                            AverageWaitingTime = @AverageWaitingTime,
                            MaximumWaitingTime = @MaximumWaitingTime,
                            ServiceLevel = @ServiceLevel,
                            StatusUpdate = 0,
                            LastUpdate = GETDATE()
                        WHERE InboundId = @InboundId
                    END
                    ELSE
                    BEGIN
                        INSERT INTO ccWAAverageConversations (InboundId, AverageConversationTime, AverageDialogTime,
                                                              AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
                        VALUES(@InboundId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
                               @ServiceLevel, 0 , GETDATE())
                    END
                END
                --------------------------------- Results -----------------------------------

                SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
                       ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
                       ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
                       ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
                       ISNULL(ServiceLevel, 0) AS ServiceLevel,
                       ISNULL(Attended, 0) AS Attended,
                       ISNULL(Assigned, 0) AS Assigned,
                       ISNULL(OnQueue, 0) AS OnQueue,
                       ISNULL(EndedBySystem, 0) AS EndedBySystem,
                       ISNULL(Available, 0) AS Available,
                       ISNULL(Request, 0) AS Request
                FROM ccWAAverageConversations conv
                RIGHT JOIN ccWAOperatingSummary summary ON conv.InboundId = summary.InboundId
                WHERE conv.inboundId = @InboundId OR summary.InboundId = @InboundId
            END
        IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
                       -- Average Queue/Waiting Time, and Service Level)
        BEGIN
            IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
                BEGIN
                    UPDATE ccWAAverageConversations SET StatusUpdate = 1
                    WHERE InboundId = @InboundId
                END
                ELSE
                BEGIN
                    INSERT INTO ccWAAverageConversations (InboundId, StatusUpdate)
                    VALUES(@InboundId, 1)
                END
        END
        IF @Option = 3 -- Save time from accepted conversation by agent
        BEGIN
            IF @ConversationId IS NOT NULL
            BEGIN
                UPDATE ccWhatsAppConversations SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
                --Save Conversation Assigned
                SELECT @inboundId = inboundId FROM ccWhatsAppConversations where conversationId=@conversationId;
                UPDATE ccWAOperatingSummary SET Assigned = (Assigned + 1) WHERE InboundId = @inboundId
                --EXEC ccsp_WhatsAppOperatingSummary @Option = 2, @InboundId = @CampIdTemp;
            END
        END
        IF @Option = 4 -- Get Disposition Information
        BEGIN
            declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
            select @nIdioma = case valor when 0 then ''Sin calificación'' else ''No disposition'' end
            from ccsettings where setting_id = 27 -- 0esp
            SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
                    ISNULL(disposition.calif_id, 0) AS DispositionId,
                   COUNT(whatsConv.disposition) AS Total,
                    ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
                   COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
            FROM ccWhatsAppConversations whatsConv
            LEFT JOIN cctipocalif disposition ON disposition.calif_id = whatsConv.disposition
            WHERE inboundId = @InboundId AND assignDate >= @Today
                and whatsConv.conversationStatus != 2
            GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
        END
        IF @Option = 5 -- Get Subdisposition Information
        BEGIN
            SELECT relation.calif_id AS DispositionId,
                   subDispositions.califSubDesc AS SubDispositionsName,
                   COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
            FROM cctipoSubCalifRel relation
            INNER JOIN ccTipoCalifSub subDispositions ON subDispositions.califSub_id = relation.califSub_id
            INNER JOIN ccWhatsAppConversations whatsConv ON whatsConv.subDisposition = subDispositions.califSub_id
            WHERE whatsConv.inboundId = @InboundId AND
                  whatsConv.assignDate >= @Today AND
                  relation.tipoSubRel = 1
            GROUP BY subDispositions.califSubDesc, relation.calif_id
        END
        IF @Option = 6 -- Agents Availables
        BEGIN
            IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @InboundId)
                BEGIN
                    INSERT INTO ccWAOperatingSummary (InboundId, Available) VALUES (@InboundId, @AgentsAvailables);
                END
            ELSE
                BEGIN
                    UPDATE ccWAOperatingSummary SET Available = @AgentsAvailables WHERE InboundId = @InboundId
                END
        END

    END
END
IF @Option = 0 BEGIN-- Reset TABLES
    TRUNCATE TABLE ccWAOperatingSummary;
    TRUNCATE TABLE ccWAAverageConversations;
    TRUNCATE TABLE ccLastMessageAgentByConversation;
END
ELSE IF @Option = 7 -- Reset attended and OnQueue from OperatingSummary
BEGIN
    UPDATE ccWAOperatingSummary SET Assigned = 0, OnQueue = 0
END
RETURN(0)
SET NOCOUNT OFF'
     EXEC(@sql)

     set @process = 'K002107-ResumenOperativo se altera sp ccsp_ConversationWASave'
     set @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
                                              , @conversationId     INT         = 0
                                              , @inboundId          SMALLINT    = NULL
                                              , @phoneACD           VARCHAR(50) = NULL
                                              , @clientId           VARCHAR(25) = NULL
                                              , @conversationStatus SMALLINT    = 0
                                              , @tChatting          FLOAT    = 0
                                              , @tWrapUp            SMALLINT    = 0
                                              , @finishedBy         TINYINT     = 0
                                              , @onQueue            BIT         = NULL
                                              , @tQueue             SMALLINT    = 0
                                              , @tTimeout           INT         = 0
                                              , @disposition        SMALLINT    = 0
                                              , @subDisposition     SMALLINT    = 0
                                              , @agentId            INT         = 0
											  --VAR MESSAGES
											  , @messageId          VARCHAR(50) = NULL
											  , @messageIdUi        INT			= NULL
											  , @clientNum			VARCHAR(15) = NULL
											  , @vonageNum			VARCHAR(15) = NULL
											  , @typeMessage		VARCHAR(25) = ''''
											  , @content			NVARCHAR(MAX)= NULL
											  , @timeStampMessage   DATETIME	= NULL
											  , @timeStampMessageUTC DATETIME	= NULL
											  , @originType         VARCHAR(15) = NULL
											  , @currency			VARCHAR(10) = ''-''
											  ,	@price				VARCHAR(10) = ''0.00''
											  , @messageStatus		VARCHAR(15) = ''N/A''
											  , @listConversationsIds	VARCHAR(MAX) = NULL
	AS
	BEGIN
	    DECLARE @isEndConversation BIT;
	    DECLARE @meanContactTypeId SMALLINT;
		DECLARE @conversationIdNew INT;
	    SET @meanContactTypeId = 1;
	    SET NOCOUNT ON;

	    IF @action = 1
	    BEGIN --new Conversation
	        IF NOT EXISTS
	                      (SELECT A.conversationId conversationId FROM ccWhatsAppConversations A
	                       WHERE A.conversationId = @conversationId
	                      )
	        BEGIN
	            INSERT INTO [ccWhatsAppConversations]
	            (inboundId
	           , phoneACD
	           , clientId
	           , conversationStatus
	           , tChatting
	           , tWrapUp
	           , finishedBy
	           , onQueue
	           , tQueue
	           , tTimeout
	           , disposition
	           , subDisposition
	           , agentId
	            )
	            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);

				IF NOT EXISTS (SELECT WhatsAppSpamId FROM ccWhatsAppSpam WHERE NumberClient = @clientId and InboundId = @inboundId) BEGIN
					SELECT @conversationId = SCOPE_IDENTITY();
					SELECT @conversationId AS ConversationId;
				END
				ELSE BEGIN

					declare @conversationIdTemporal     INT;
					SELECT @conversationIdTemporal = SCOPE_IDENTITY();
					EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationIdTemporal, @conversationStatus = 13
					SELECT 0 AS ConversationId;
				END;

				--Save new request
				IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @inboundId)
					BEGIN
						INSERT INTO ccWAOperatingSummary (InboundId, Request) VALUES (@inboundId, 1);
					END
				ELSE
					BEGIN
						UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId
					END



	            RETURN(0);
	        END
	        ELSE
	        BEGIN
				DECLARE @conversationStatusTemp INT = @conversationStatus;
				IF @conversationStatus in(17,18) BEGIN
					SET @conversationStatusTemp = 1
				END
				 INSERT INTO [ccWhatsAppConversations]
	            (inboundId
	           , phoneACD
	           , clientId
	           , conversationStatus
	           , tChatting
	           , tWrapUp
	           , finishedBy
	           , onQueue
	           , tQueue
	           , tTimeout
	           , disposition
	           , subDisposition
	           , agentId
	            )
	            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
	            SELECT @conversationIdNew = SCOPE_IDENTITY();

				INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore
																 , conversationIdAfter)
					VALUES (@conversationId, @conversationIdNew);
				--Save new request by reassign
				UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId

            EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

            SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship where conversationIdBefore = @conversationId;
            RETURN(0);
        END;
    END;

    IF @action = 2
    BEGIN --save conversation Times
		DECLARE @conversationIdTemp INT;
		DECLARE @TablaTemp TABLE (conversationId INT, status bit);

		IF @listConversationsIds IS NOT NULL begin
			INSERT INTO @TablaTemp
			SELECT value,0
			FROM fn_RIASplitDelimited(@listConversationsIds, '','')
			where value is not null and value<>''''
		end
		else begin
			INSERT INTO @TablaTemp values(@conversationId,0)
		end

		UPDATE ccWhatsAppConversations
		SET
		conversationStatus = @conversationStatus
		, finishedBy = case when @conversationStatus = 10 then 2
			when @conversationStatus = 17 then 2
			when @conversationStatus = 18 then 2
			else 1 end
		, tConversation =  case when @conversationStatus = 17 then 0 else DATEDIFF(ss, requestDate, GETDATE()) end
		,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else tQueue end
		,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
		WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

		 WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
		BEGIN
			select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
			exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5

            IF @conversationStatus in(13,10,17,18,11) BEGIN
				DECLARE @conversationDateTemp INT;
                select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end from ccWhatsAppConversations where conversationId = @conversationId; 

    			IF @conversationStatus = 13 BEGIN
    				IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
    					INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
    				END
    			END
                ELSE IF @conversationStatus in(10,17,18) BEGIN --Save conversation Ended by system
					IF @conversationDateTemp > 0 BEGIN
						UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
					END
					ELSE BEGIN
						 UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1) WHERE InboundId = @inboundId
					END
                END
                ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
                    UPDATE ccWAOperatingSummary SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
                END
            END
			update @TablaTemp set status=1 where conversationId=@conversationIdTemp
		END

    END;

    IF @action = 3
    BEGIN --save conversation Status
        UPDATE ccWhatsAppConversations
               SET
                   --conversationDate = GETDATE(),
                   conversationStatus = @conversationStatus
        WHERE conversationId = @conversationId;
    END;

    IF @action = 4 BEGIN --save messages from conversation
        IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId)
            AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversations A WHERE A.messageId=@messageId)
        BEGIN
            IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
                (SELECT messageIdUi
                  FROM ccWAMessagesConversations
                 WHERE originType IN (''Agent'', ''Admin'')
                   AND conversationId = @conversationId)
                BEGIN
                    UPDATE ccWhatsAppConversations
                       SET FirstMessageAgent = @timeStampMessage
                     WHERE conversationId = @conversationId;
                END

            INSERT INTO [ccWAMessagesConversations](
                                                messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
                                               (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
            SELECT @messageId=SCOPE_IDENTITY()
            SELECT @messageId as MessageId
            RETURN (0)
        END
        ELSE BEGIN
            SELECT 0 AS MessageId
            RETURN (0)
        END
    END;

		IF @action = 5
	    BEGIN --save onQueue
	        UPDATE ccWhatsAppConversations
	               SET onQueue = 1
	        WHERE conversationId = @conversationId;
			SELECT @inboundId = inboundId FROM ccWhatsAppConversations where conversationId=@conversationId;
			UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue + 1) WHERE InboundId = @inboundId
	    END;

    IF @action = 6
    BEGIN --save agent, assigdate and tqueue
		declare @agentIdTmp int
		SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversations A where A.conversationId = @conversationId

        IF (@agentIdTmp is null or @agentIdTmp=0)
        BEGIN
            UPDATE ccWhatsAppConversations
                   SET agentId = @agentId,
                   assignDate = getdate(),
                   conversationStatus = @conversationStatus
				   ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
            WHERE conversationId = @conversationId;

            SELECT @conversationId as conversationId
	    SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations where conversationId=@conversationId;

	    IF @onQueue = 1 BEGIN
		UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1) WHERE InboundId = @inboundId
	    END
        END
    END;

		IF @action = 7
	    BEGIN --update price message
	        UPDATE ccWAMessagesConversations
	               SET price = @price,
					   currency = @currency
	        WHERE messageId = @messageId;
	    END;

		IF @action = 8
	    BEGIN --update status message
			IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
				UPDATE ccWAMessagesConversations
					   SET messageStatus = @messageStatus
				WHERE messageId = @messageId;
			END;
	    END;

		IF @action = 9
	    BEGIN --Save last message time by conversationID
			IF (SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversation A WHERE A.conversationId=@conversationId) IS NULL BEGIN
				INSERT INTO ccLastMessageAgentByConversation (conversationId) VALUES (@conversationId)
			END;
			ELSE
				BEGIN
					UPDATE ccLastMessageAgentByConversation
					   SET timeStampLastMessageAgent = getDate()
					WHERE conversationId = @conversationId;
				END;
	    END;

		IF @action = 10
	    BEGIN --drop register by conversationID
			DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
	    END;

		IF @action = 11
	    BEGIN --register desconnection by conversationID
			UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
	    END;
	END;'
     EXEC(@sql)

     set @process = 'K002107-ResumenOperativo se altera ccsp_GalateaDeleteCampaignAndACD -- Se agregan cambios para el ticket TT3587'
     set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaDeleteCampaignAndACD]
        --declare
        @userId           SMALLINT,
        @DeleteCamId      VARCHAR(MAX),
        @DeleteACDGroupId VARCHAR(MAX),
        @moduleId         SMALLINT = 49
    AS
    BEGIN

        IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
            SELECT value As DeleteCamId, c.IDArea AS IDAreaCamp, 1 AS CampTypeCamp
            INTO #CampsDelete
            FROM fn_RIASplitDelimited(@DeleteCamId, '','') a
            inner join ccCamps c on  a.value = c.cam_id and c.IDArea IS NOT NULL
        IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
            SELECT value As DeleteACDId, c.IDArea AS IDAreaACD, 0 AS CampTypeACD
            INTO #ACDDelete
            FROM fn_RIASplitDelimited(@DeleteACDGroupId, '','') a
            inner join ccInbound c on  a.value = c.Inbound_id and c.IDArea IS NOT NULL

        IF  not Exists (select * from #CampsDelete union select * from #ACDDelete )
        begin
            select ''-1'' AS Result
            return
        end

        IF datalength(@DeleteCamId) > 0
            BEGIN

            if exists(select cam_id from ccInbound where cam_id in (select DeleteCamId from #CampsDelete)) begin
                --Borra las calificacion con reprogramacion
                delete ccCalifCamp from ccInbound A
                inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
                inner join ccTipoCalif C on B.calif_id=C.calif_id and C.CanReprogram=1
                where A.cam_id in (select DeleteCamId from #CampsDelete)
                --Borra las subcalificacion con reprogramacion
                delete rel from ccInbound A
                inner join ccCalifCamp B on A.Inbound_id=B.cam_id and  B.tipo=0
                inner join ccTipoCalif C on B.calif_id=C.calif_id
                inner join cctipoSubCalifRel rel on rel.calif_id=C.calif_id and rel.tipoSubRel=1
                inner join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
                where A.cam_id in (select DeleteCamId from #CampsDelete) and sb.canReprogram=1

                update ccInbound set cam_id = null where cam_id in (select DeleteCamId from #CampsDelete)

            end

            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
            select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete)

            delete from ccCampsAgente where cam_id in (select DeleteCamId from #CampsDelete)
            insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
            select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id in (select DeleteCamId from #CampsDelete) and A.tipo = 1

            delete from ccSupervisorCam where cam_id in (select DeleteCamId from #CampsDelete) and tipo = 1
            delete from ccRIACampEspWG where IdCampEsp in (select DeleteCamId from #CampsDelete) and tipo = 1

            IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
            SELECT ca.AreaName,
                   GETDATE() operationDate,
                   27 operationType,
                   (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                   @moduleId module_id,
                   c.cam_descripcion value,
                   ca.AreaName AS target
            INTO #CampLog
            FROM ccRIACat_Areas ca
            Inner join ccCamps c with(nolock) on ca.IDArea = c.IDArea
            WHERE c.cam_id in (select DeleteCamId from #CampsDelete)

            Update ccCamps set IDArea = null where cam_id in (select DeleteCamId from #CampsDelete)

        END
        IF datalength(@DeleteACDGroupId) > 0
            BEGIN

            if exists(select top 1 cam_id from ccInbound where Inbound_id in (select DeleteACDId from #ACDDelete))
                begin
                    update ccInbound set cam_id = null where Inbound_id in (select DeleteACDId from #ACDDelete)
            end

            IF OBJECT_ID(''tempdb..#AllWGACD'') IS NOT NULL DROP TABLE #AllWGACD
            SELECT DISTINCT(IDWG)
            INTO #AllWGACD
            FROM ccRIACampEspWG ce
            WHERE IDCampEsp in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0

            insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
            select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG
            from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id
            where B.User_id is null and A.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

            delete ccInboundHorarios Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
            delete ccInboundMsgs Where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
            select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG
            from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id
            where B.User_id is null and A.cam_id in (SELECT DeleteACDId FROM #ACDDelete)

            delete ccSupervisorCam where cam_id in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0
            delete ccInboundAgentes where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
            delete ccRIACampEspWG where IdCampEsp  in (SELECT DeleteACDId FROM #ACDDelete) and tipo = 0


            IF OBJECT_ID(''tempdb..#ACDLog'') IS NOT NULL DROP TABLE #ACDLog
            SELECT ca.AreaName,
                    GETDATE() operationDate,
                    28 operationType,
                    (SELECT Login FROM ccUsers WHERE User_Id = @userId) login,
                    @moduleId module_id,
                    i.descripcion value,
                    ca.AreaName AS target
            INTO #ACDLog
            FROM ccRIACat_Areas ca
            inner join ccInbound i with(nolock) on ca.IDArea = i.IDArea
            WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

            Update ccInbound set IDArea = null, status = 0 where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)
			delete from ccInboundDnis where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

            if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
                begin
                    update ContactMeanIn set name = '''', conexionInfo = ''usuarioID|token|tokenSecret|1|0'', connUser = '''', isActive = 0
                    where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=2
            end
            if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
                begin
                    update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=1
            end
            update ccinbound set chatDomain = '''' where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)--para desasociar el dominio del chat

            if exists (SELECT inboundId FROM contactMeanIn WHERE inboundId in (select DeleteACDId from #ACDDelete))
                begin
                    update contactMeanIn set isActive = 0 where inboundId in (select DeleteACDId from #ACDDelete)
            end

			if exists (SELECT inboundId FROM ccWhatsAppNumbers WHERE inboundId in (select DeleteACDId from #ACDDelete))
				begin
					update ccWhatsAppNumbers set inboundId = 0 where inboundId in (select DeleteACDId from #ACDDelete)
			end
        END

        IF datalength(@DeleteCamId) > 0
            Insert into ccRIALog Select * from #CampLog
        IF datalength(@DeleteACDGroupId) > 0
            Insert into ccRIALog Select * from #ACDLog

        SELECT DeleteCamId AS DeleteId,IDAreaCamp AS IDArea,CampTypeCamp AS CampType,''1'' AS Result, CAST(0 AS SMALLINT) as IDWG FROM #CampsDelete
        UNION
        SELECT DeleteACDId,IDAreaACD,CampTypeACD,''1'' AS Result, (select CAST(IDWG AS SMALLINT) from #AllWGACD)  FROM #ACDDelete


        IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
        IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
    END'
     EXEC(@sql)

	 set @process = 'CW-Roles se quita relacion permiso-rol Solo monitoreo'
    set @sql = 'if exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10017)
    begin
        DELETE FROM ccRoles_Permissions where Rol_Id = 1 AND Permissions_Id = 10017
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Areas'
    set @sql = 'if exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10007)
    begin
        DELETE FROM ccRoles_Permissions where Rol_Id = 1 AND Permissions_Id = 10007
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se quita relacion permiso-rol Gestion de Campañas eliminar,agregar, etc'
    set @sql = 'if exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10013)
    begin
        DELETE FROM ccRoles_Permissions where Rol_Id = 1 AND Permissions_Id = 10013
    end'
    EXEC(@sql)

	/* Supervisor */
    set @process = 'CW-Roles se quita relacion permiso-rol CenterScript|CenterScript'
    set @sql = 'if exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10003)
    begin
        DELETE FROM ccRoles_Permissions where Rol_Id = 6 AND Permissions_Id = 10003
    end'
    EXEC(@sql)
    /************************/
    set @process = 'CW-Roles se agrega  relacion permiso-rol Iniciar y detener campañas|Start and stop Campaign'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10001)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10001)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se agrega  relacion permiso-rol Carga de base de datos|Data Import'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10002)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10002)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se agrega  relacion permiso-rol Eliminar nuevos registros|Delete new records'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10005)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10005)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se agrega  relacion permiso-rol Devolucion de llamada|CallBacks'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10006)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10006)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se agrega  relacion permiso-rol Gestionar de areas'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10008)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10008)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se agrega  relacion permiso-rol Gestionar tipos de no disponible'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10009)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10009)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se agrega  relacion permiso-rol Gestionar permisos de agente'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10010)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10010)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se agrega  relacion permiso-rol Gestionar campañas'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10011)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10011)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se agrega  relacion permiso-rol Gestionar horarios'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10014)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10014)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se agrega  relacion permiso-rol Gestionar chat con agentes'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10015)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10015)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se agrega  relacion permiso-rol Gestionar monitoreo de llamada'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10016)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10016)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se agrega  relacion permiso-rol Gestionar inicio automático'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10020)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10020)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se agrega  relacion permiso-rol Gestionar calificaciones'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10021)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10021)
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se agrega  relacion permiso-rol Gestionar listas negras'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10025)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10025)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega  relacion permiso-rol Acceder a reporteador'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10026)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10026)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega  relacion permiso-rol Acceder a buscador'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=6 and Permissions_Id=10027)
    begin
        INSERT INTO ccRoles_Permissions VALUES(6,10027)
    end'
    EXEC(@sql)

    /*  Calidad */

    set @process = 'CW-Roles se agrega el rol calidad'
    set @sql = 'if not exists (select * from ccRoles where Level=8 and Active=1)
    begin	
        INSERT ccRoles (Description,KeyJson,CreateDate,Active,Level) 
        VALUES (''Calidad'',''translate_quality'',CURRENT_TIMESTAMP ,1,8 )

		
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol Monitoreo de llamadas'
    set @sql = 'declare @rolId int 
	select @rolId=Rol_id from ccRoles where Level=8

	if not exists (select * from ccRoles_Permissions where Rol_Id=@rolId and Permissions_Id=10016)
    begin
			
        INSERT INTO ccRoles_Permissions VALUES(@rolId, 10016) 
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol Gestion de areas '
    set @sql = 'declare @rolId int 
	select @rolId=Rol_id from ccRoles where Level=8

	if not exists (select * from ccRoles_Permissions where Rol_Id=@rolId and Permissions_Id=10008)
    begin
        INSERT INTO ccRoles_Permissions VALUES(@rolId, 10008) 
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol Acceder a buscador '
    set @sql = '
	declare @rolId int 
	select @rolId=Rol_id from ccRoles where Level=8

	if not exists (select * from ccRoles_Permissions where Rol_Id=@rolId and Permissions_Id=10027)
    begin
        INSERT INTO ccRoles_Permissions VALUES(@rolId, 10027) 
    end'
    EXEC(@sql)
    set @process = 'CW-Roles se agrega relacion permiso-rol Reporteador'
    set @sql = '
	declare @rolId int 
	select @rolId=Rol_id from ccRoles where Level=8
	if not exists (select * from ccRoles_Permissions where Rol_Id=@rolId and Permissions_Id=10026)
    begin
        INSERT INTO ccRoles_Permissions VALUES(@rolId, 10026) 
    end'
    EXEC(@sql)

     /*  Monitor */

    set @process = 'CW-Roles se agrega el rol Monitor'
    set @sql = 'if not exists (select * from ccRoles where Level=9 and Active=1)
    begin
        INSERT ccRoles (Description,KeyJson,CreateDate,Active,Level) 
    VALUES (''Monitor'',''translate_monitor'',CURRENT_TIMESTAMP ,1,9)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol Solo Monitoreo'
    set @sql = 'declare @rolId int 
	select @rolId=Rol_id from ccRoles where Level=9

	if not exists (select * from ccRoles_Permissions where Rol_Id=@rolId and Permissions_Id=10017)
    begin
        INSERT INTO ccRoles_Permissions VALUES(@rolId, 10017) 
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol Monitorear areas'
    set @sql = 'declare @rolId int 
	select @rolId=Rol_id from ccRoles where Level=9

	if not exists (select * from ccRoles_Permissions where Rol_Id=@rolId and Permissions_Id=10007)
    begin
        INSERT INTO ccRoles_Permissions VALUES(@rolId, 10007) 
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol Reporteador'
    set @sql = '
	declare @rolId int 
	select @rolId=Rol_id from ccRoles where Level=9

	if not exists (select * from ccRoles_Permissions where Rol_Id=@rolId and Permissions_Id=10026)
    begin
        INSERT INTO ccRoles_Permissions VALUES(@rolId, 10026) 
    end'
    EXEC(@sql)

    /*  Eliminar Administrador */
    
    set @process = 'CW-Roles se eliminan permisos del rol Administrador'
    set @sql = 'if  exists (select * from ccRoles_Permissions WHERE Rol_Id = 2 )
    begin
        DELETE FROM ccRoles_Permissions WHERE Rol_Id = 2
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se eliminan user_id del rol Administrador'
    set @sql = 'if  exists (select * from ccUsers_Roles WHERE Rol_Id = 2)
    begin
        DELETE FROM ccUsers_Roles WHERE Rol_Id = 2
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se eliminan el rol Administrador'
    set @sql = 'if  exists (select * from ccRoles WHERE Rol_id = 2 AND Description=''Admin'' AND Level=2)
    begin
		DELETE FROM ccRoles WHERE Rol_id = 2 AND Description=''Admin'' AND Level=2
    end'
    EXEC(@sql)

    /* Eliminar Sistemas */
    
    set @process = 'CW-Roles se eliminan permisos del rol Sistemas'
    set @sql = 'if  exists (select * from ccRoles_Permissions WHERE Rol_Id = 3 )
    begin
        DELETE FROM ccRoles_Permissions WHERE Rol_Id = 3
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se eliminan user_id del rol Sistemas'
    set @sql = 'if  exists (select * from ccUsers_Roles WHERE Rol_Id = 3)
    begin
        DELETE FROM ccUsers_Roles WHERE Rol_Id = 3

    end'
    EXEC(@sql)

    set @process = 'CW-Roles se eliminan el rol Sistemas'
    set @sql = 'if  exists (select * from ccRoles WHERE Rol_id = 3 AND Description=''It Manager'' AND Level=3)
    begin
		DELETE FROM ccRoles WHERE Rol_id = 3 AND Description=''It Manager'' AND Level=3
    end'
    EXEC(@sql)

    /* Eliminar Gerente  */
    
    set @process = 'CW-Roles se eliminan permisos del rol Gerente'
    set @sql = 'if  exists (select * from ccRoles_Permissions WHERE Rol_Id = 4 )
    begin
        DELETE FROM ccRoles_Permissions WHERE Rol_Id = 4
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se eliminan user_id del rol Gerente'
    set @sql = 'if  exists (select * from ccUsers_Roles WHERE Rol_Id = 4)
    begin
        DELETE FROM ccUsers_Roles WHERE Rol_Id = 4

    end'
    EXEC(@sql)

    set @process = 'CW-Roles se eliminan el rol Gerente'
    set @sql = 'if  exists (select * from ccRoles WHERE Rol_id = 4 AND Description=''Manager'' AND Level=4)
    begin
		DELETE FROM ccRoles WHERE Rol_id = 4 AND Description=''Manager'' AND Level=4
    end'
    EXEC(@sql)
    /* Eliminar Gestion de salas  */
    
    set @process = 'CW-Roles se eliminan permisos del Gestion de salas'
    set @sql = 'if  exists (select * from ccRoles_Permissions WHERE Rol_Id = 5 )
    begin
        DELETE FROM ccRoles_Permissions WHERE Rol_Id = 5
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se eliminan user_id del Gestion de salas'
    set @sql = 'if  exists (select * from ccUsers_Roles WHERE Rol_Id = 5)
    begin
        DELETE FROM ccUsers_Roles WHERE Rol_Id = 5

    end'
    EXEC(@sql)

    set @process = 'CW-Roles se eliminan el Gestion de salas'
    set @sql = 'if  exists (select * from ccRoles WHERE Rol_id = 5 AND Description=''Room Manager'' AND Level=5)
    begin
		DELETE FROM ccRoles WHERE Rol_id = 5 AND Description=''Room Manager'' AND Level=5
    end'
    EXEC(@sql)

    set @process = 'Roles-Permission campaign association'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10028)
    begin
      insert into ccPermissions values (10028,''Gestionar Asociacion de campaña'',''RolesPermissionCampaignAssociation'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'Roles-Permission automatic messages'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10029)
    begin
      insert into ccPermissions values (10029,''Gestionar Mensajes Automaticos'',''RolesPermissionAutomaticMessages'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'Roles-Permission root-campaign association'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10028)
    begin
      insert into ccRoles_Permissions values(1,10028)
    end'
    EXEC(@sql)

    set @process = 'Roles-Permission root-automatic messages'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10029)
    begin
      insert into ccRoles_Permissions values(1,10029)
    end'
    EXEC(@sql)
    set @process = 'K004016-Agente-Poder recibir transferencias entre Agentes, se altera el sp ccsp_AgentTransfLstArea para el listado de agentes en blended y normal'
set @sql = '
ALTER PROCEDURE [dbo].[ccsp_AgentTransfLstArea]
@userID INT,
@current INTEGER = 0
AS
set nocount on

BEGIN
declare @value int
declare @valueDialingMode int 
set @value = 0
set @valueDialingMode=0
select @value = case when valor=''1'' then 1 else 0 end from ccSettings (nolock) where setting_id = 191
select @valueDialingMode = case when DialingMode= 1 then 1 else 0 end from ccusers  (nolock) where user_id = @userID
    IF @value = 0
        begin
            select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name,login from ccusers cu (nolock) join
            (
                select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp (nolock)
                join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
            )
            x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID and cu.DialingMode=@valueDialingMode
            Order by name asc
        end

    if @value = 1
        begin
            if (@current <> 0)
                begin
                    select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name,login from ccusers cu (nolock) join
                    (
                        select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp (nolock)
                        join ccmonitorext ce (nolock) on cp.ext_id = ce.ext_id where user_id > 0
                    )
                    x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
                    and IDArea in (select cu.IDArea from ccUsers cu join ccInbound ci (nolock) on cu.IDArea = ci.IDArea where inbound_id =  @current)
                    Order by name asc
                end
            else
                begin
                    select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name,login from ccusers cu (nolock) join
                    (
                        select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp (nolock)
                        join ccmonitorext ce (nolock) on cp.ext_id = ce.ext_id where user_id > 0
                    )
                    x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID and cu.DialingMode=@valueDialingMode
                    and IDArea in (select IDArea from ccUsers (nolock) where User_id = @userID)
                    Order by name asc
                end
        end
END
       '
EXEC(@sql)
-------------------------------END RESUMEN OPERATIVO --------------------------------

    set @process = 'CW-PREVIEW se agrega campo para permiso eliminar registro en campa?s preview'
    set @sql = 'IF not exists(SELECT top 1 1
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE COLUMN_NAME = ''AllowDeleteRecord'' AND TABLE_NAME = ''ccUsers'')
		BEGIN
			ALTER TABLE ccUsers ADD AllowDeleteRecord bit not null DEFAULT(0)
		END'
	EXEC(@sql)

    set @process = 'CW-PREVIEW se agrega SP ccsp_GalateaAdminSetPermissions'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
    @adminId SMALLINT,
    @areaId SMALLINT,
    @agentsIds VARCHAR(MAX),
    @allAgentsSelected BIT, 
    @permissionName VARCHAR(255),
    @permissionValue INT
AS
SET NOCOUNT ON


declare @changeBitTable table(permissionName VARCHAR(255), valueBit int)

insert into @changeBitTable values(''AllowCellPhoneCalls'',1)
insert into @changeBitTable values(''startStopRecording'',1)
insert into @changeBitTable values(''XferManual'',1)
insert into @changeBitTable values(''AllowTransferCalls'',1)
insert into @changeBitTable values(''AgentPermissionDailing'',1)
insert into @changeBitTable values(''DailingMode'',1)
insert into @changeBitTable values(''AgentPermissionDelete'',1)


insert into @changeBitTable values(''AllowLongDistanceCalls'',2)
insert into @changeBitTable values(''XferExt'',2)

insert into @changeBitTable values(''AllowLocalCalls'',4)
insert into @changeBitTable values(''XferCamps'',4)

insert into @changeBitTable values(''XferAgents'',8)

DECLARE @changeBit INT

set @changeBit=0

select @changeBit=valueBit from @changeBitTable where permissionName=@permissionName

--print(@changeBit)
IF @agentsIds IS NOT NULL
BEGIN
    DECLARE @AgentIdsTemp TABLE (AgentId INT, Status BIT)
    INSERT INTO @AgentIdsTemp SELECT VALUE, 0 FROM dbo.fn_RIASplitDelimited(@agentsIds,'','')

    IF @permissionName = ''AllowUnassign'' 
    BEGIN                       
        UPDATE permissions SET permissions.AllowUnassign = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAMultimediaUsersPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAMultimediaUsersPermissions(AgentId, AllowUnassign, AllowSpam)
        SELECT agentIds.AgentId , @permissionValue, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAMultimediaUsersPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END
    IF @permissionName = ''AllowSpam''
    BEGIN 
        UPDATE permissions SET permissions.AllowSpam = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAMultimediaUsersPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAMultimediaUsersPermissions(AgentId, AllowSpam, AllowUnassign)
        SELECT agentIds.AgentId , @permissionValue, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAMultimediaUsersPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END

    UPDATE
        ccUsers
    SET DialMask =
        CASE
        WHEN @permissionName = ''AllowCellPhoneCalls''
        OR @permissionName = ''AllowLongDistanceCalls''
        OR @permissionName = ''AllowLocalCalls''
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (DialMask & @changeBit) <> @changeBit
                THEN DialMask ^ @changeBit
                ELSE DialMask
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (DialMask & @changeBit) = @changeBit
                THEN DialMask ^ @changeBit
                ELSE DialMask
                END
            END 
        ELSE DialMask
        END,
                            
        XferMask =
        CASE
        WHEN @permissionName = ''AllowTransferCalls''
        THEN
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (XferMask & @changeBit) <> @changeBit
                THEN XferMask ^ @changeBit
                ELSE XferMask
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (XferMask & @changeBit) = @changeBit
                THEN XferMask ^ @changeBit
                ELSE XferMask
                END
            END
        ELSE XferMask
        END,

        XferAgents =
        CASE
        WHEN @permissionName = ''XferAgents''
        OR @permissionName = ''XferCamps'' 
        OR @permissionName = ''XferExt'' 
        OR @permissionName = ''XferManual'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (XferAgents & @changeBit) <> @changeBit
                THEN XferAgents ^ @changeBit
                ELSE XferAgents
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (XferAgents & @changeBit) = @changeBit
                THEN XferAgents ^ @changeBit
                ELSE XferAgents
                END
            END
        ELSE XferAgents
        END,

        startStopRecording =
        CASE
        WHEN @permissionName = ''startStopRecording'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN 1
            WHEN @permissionValue = 0
            THEN 0
            END
        ELSE startStopRecording
        END,

        DialingMode = 
        CASE
        WHEN @permissionName = ''DailingMode'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (DialingMode & @changeBit) <> @changeBit
                THEN DialingMode ^ @changeBit
                ELSE DialingMode
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (DialingMode & @changeBit) = @changeBit
                THEN DialingMode ^ @changeBit
                ELSE DialingMode
                END
            END 
        ELSE DialingMode
        END,
        AllowChangeDialingMode = 
        CASE
        WHEN @permissionName = ''AgentPermissionDailing'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN 1
            WHEN @permissionValue = 0
            THEN 0
            END
        ELSE AllowChangeDialingMode
        END,
        AllowDeleteRecord= 
        CASE
        WHEN @permissionName = ''AgentPermissionDelete'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN 1
            WHEN @permissionValue = 0
            THEN 0
            END
        ELSE AllowDeleteRecord
        END
    WHERE User_id IN (SELECT AgentId FROM @AgentIdsTemp)

                    
    DECLARE @Login VARCHAR(20) = (SELECT Login FROM ccUsers WHERE User_id = @adminId)
    DECLARE @AreaName VARCHAR(50) = (SELECT AreaName FROM ccRIACat_Areas WHERE IDArea = @areaId)
    DECLARE @OperationType TINYINT = (SELECT CASE WHEN @permissionValue = 1 THEN 33 ELSE 35 END)
    DECLARE @Language TINYINT = (SELECT valor FROM ccSettings WHERE setting_id = 27)
    DECLARE @Tag varchar(100) = (SELECT PermissionTag FROM ccRIAUsersPermissions WHERE PermissionName = @permissionName)        
    DECLARE @Value VARCHAR(250) = (SELECT permissions.Value 
                                    FROM  dbo.fn_RIASplitDelimited(@Tag,''|'') permissions
                                    WHERE permissions.Id = @Language + 1)

    DECLARE @AgentId INT = 0
    DECLARE @AgentName VARCHAR(20) = ''''

    set @Value=isnull(@Value,@permissionName)

    IF @allAgentsSelected = 0
    BEGIN
        WHILE EXISTS(SELECT * FROM @AgentIdsTemp WHERE Status = 0)
        BEGIN 
            SELECT TOP 1 @AgentId = AgentId FROM @AgentIdsTemp WHERE Status = 0
            SET @AgentName = (SELECT Login FROM ccUsers WHERE User_id = @AgentId)
                        
            EXEC ccsp_RIA_ABCLog @option = 2, @areaName = @AreaName, @operationType = @OperationType, 
            @login = @Login, @moduleId = 4, @value = @permissionName , @target = @AgentName
                            
            UPDATE @AgentIdsTemp SET Status = 1 WHERE AgentId = @AgentId
        END
    END
    ELSE
    BEGIN
        SET @AgentName = (SELECT AllAgentsTag FROM ccRIAUserPermissionsStatusTags WHERE Language = @Language)
                        
        EXEC ccsp_RIA_ABCLog @option = 2, @areaName = @AreaName, @operationType = @OperationType, 
        @login = @Login, @moduleId = 4, @value = @Value , @target = @AgentName
                            
        UPDATE @AgentIdsTemp SET Status = 1
    END


END

SET NOCOUNT OFF'
    EXEC(@sql)

    set @process = 'CW-PREVIEW agregar sp ccsp_GalateaAdminGetPermissions'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
    @user_id varchar(255),
    @Type int
AS
set nocount on

declare @isRoot int;

if exists (Select Rol_id from ccUsers A join ccUsers_Roles B on A.User_id = B.User_id where A.User_id = @user_id and rol_id = 7) set @isRoot = 1 else set @isRoot = 0;
print @isRoot

IF @isRoot = 1
BEGIN
    Select 
    User_id as AgentId, 
    Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
    cast(dialMask & 1 as int) as AllowCellPhoneCalls,
    cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
    cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
    cast( xfermask as int) as AllowTransferCalls, 
    cast(CanChangeStatus as tinyint) CanChangeStatus,
    cast(XferAgents as tinyint) XferAgents,
    ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
    cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
    ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
    ISNULL(multimediaPermissions.AllowUnassign, 0) AS AllowUnassign,
    ISNULL(multimediaPermissions.AllowSpam, 0 ) AS AllowSpam,
    cast(AllowDeleteRecord as int) as AgentPermissionDelete
from 
    ccUsers users
left join ccRIAMultimediaUsersPermissions multimediaPermissions on
    users.User_id = multimediaPermissions.AgentId
where 
   tipoUser_id = 1
return(0)
END
ELSE
BEGIN
    Select distinct 
    A.User_id as AgentId, 
    Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
    cast(dialMask & 1 as int) as AllowCellPhoneCalls,
    cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
    cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
    cast( xfermask as int) as AllowTransferCalls, 
    cast(CanChangeStatus as tinyint) CanChangeStatus,
    cast(XferAgents as tinyint) XferAgents,
    ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
    cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
    ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
    ISNULL(multimediaPermissions.AllowUnassign, 0) AS AllowUnassign,
    ISNULL(multimediaPermissions.AllowSpam, 0 ) AS AllowSpam,
    cast(AllowDeleteRecord as int) as AgentPermissionDelete
from 
    ccUsers A
join ccRIAWorkGroupUsers B on 
    A.user_id = B.user_id
left join ccRIAMultimediaUsersPermissions multimediaPermissions on
    A.User_id = multimediaPermissions.AgentId
where 
    tipoUser_id = 1 and 
    IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
return(0)
END
set nocount off'
    EXEC(@sql)

    set @process = 'CW-PREVIEW eliminar sp ccsp_GalateaGetPreviewData'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetPreviewData'')
    begin
        DROP PROCEDURE ccsp_GalateaGetPreviewData;
    end'
    EXEC(@sql)

    set @process = 'CW-PREVIEW agregar sp ccsp_GalateaGetPreviewData'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaGetPreviewData]
        @callout_id int,
        @user_id smallint

        AS
        set nocount on

        select''previewData''=
         case when U.AllowDeleteRecord=1 then ''true'' else ''false'' end +''~''+
         ISNULL(P.Headers,'''')+''~''+
         ISNULL(O.Dato1,'''')+''~''+
         ISNULL(O.Dato2,'''')+''~''+
         ISNULL(O.Dato3,'''')+''~''+
         ISNULL(O.Dato4,'''')+''~''+
         ISNULL(O.Dato5,'''')+''~''+
         ISNULL(P.Dato6,'''')+''~''+
         ISNULL(P.Dato7,'''')+''~''+
         ISNULL(P.Dato8,'''')+''~''+
         ISNULL(P.Dato9,'''')+''~''+
         ISNULL(P.Dato10,'''')+''~''+
         ISNULL(P.Dato11,'''')+''~''+
         ISNULL(P.Dato12,'''')+''~''+
         ISNULL(P.Dato13,'''')+''~''+
         ISNULL(P.Dato14,'''')+''~''+
         ISNULL(P.Dato15,'''')+''~''+
         ISNULL(O.cal_telefono2,'''')+''~''+
         ISNULL(O.cal_telefono3,'''')+''~''+
         ISNULL(O.cal_telefono4,'''')+''~''+
         ISNULL(O.cal_telefono5,'''')+''~''
               from ccUsers U,ccoCallsOutSource O (nolock)
        INNER JOIN ccoCallsPreviewData P (nolock) on O.cal_Key=P.Cal_key and O.cam_id=P.cam_id
        Where callout_id=@callout_id and U.User_id=@user_id

        set nocount off'
    EXEC(@sql)

        SET @process = 'CW-7659 ALter SP ccsp_GalateaAdminCampaigns Relaciones de campañas'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS      SMALLINT, 
                                       @CampType AS    SMALLINT = 0, 
                                       @WorkgroupId AS INT      = 0, 
                                       @Id AS          INT      = 0, 
                                       @AdminId AS     SMALLINT = 0, 
                                       @PinUpdate AS   SMALLINT = 0, 
                                       @LoadId AS      INT      = 0, 
                                               @Type AS        SMALLINT = 0,
											   @InboundType	   SMALLINT = 0,
											   @AreaId		   SMALLINT = 0,
											   @multi_type     varchar(max) = null
AS
BEGIN
    SET NOCOUNT ON;
    IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                        BEGIN
                            SELECT CAST(IdCampEsp AS INT) AS Id
                            FROM ccRIACampEspWG
                            WHERE IDWG = @WorkgroupId
                                  AND Tipo = 1
                                   ORDER BY IdCampEsp ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe una lista de campañas de salida con el id de grupo de trabajo especificado'', 18, 1);
                    END;
            END;
            IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                        BEGIN
                            SELECT CAST(IdCampEsp AS INT) AS Id
                            FROM ccRIACampEspWG
                            WHERE IDWG = @WorkgroupId
                                  AND Tipo = 0
                                   ORDER BY IdCampEsp ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe una lista de campañas de entrada con el id de grupo de trabajo especificado'', 18, 1);
                    END;
            END;
            RETURN 0;
    END;
    IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            SELECT DISTINCT 
                                   CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area,  
                                        CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType
                            FROM ccCamps camps
                                 LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                                 LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
                            WHERE camps.cam_id = @Id
                                   ORDER BY camps.cam_descripcion ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
                    END;
            END;
            IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            SELECT DISTINCT 
                                   CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType
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
    IF @Option = 3   -- Update OverallTotalNew By Campaign
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    UPDATE ccCampsNvosCB
                      SET 
                          OverallTotalNew = ccCampsNvosCB.new
                    WHERE id = @Id;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 4   -- Update Pin from Campaign per Admin
        BEGIN
            IF @Id IS NOT NULL
               AND @AdminId IS NOT NULL
                BEGIN
                    IF @PinUpdate = 1
                        BEGIN
                            INSERT INTO PinedCampaigns(CampId, AdminId, Type)
                        VALUES(@Id, @AdminId, @Type);
                    END;
                    IF @PinUpdate = 0
                        BEGIN
                            DELETE FROM PinedCampaigns
                            WHERE CampId = @Id
                                  AND AdminId = @AdminId
                                  AND Type = @Type;
                    END;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. La campañas o administrador no existen'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 5   -- Get Pin from Campaign Ids per Admin
        BEGIN
            IF @AdminId IS NOT NULL
                BEGIN
                    SELECT CampId AS Id
                    FROM PinedCampaigns
                    WHERE AdminId = @AdminId
                          AND Type = @Type
                           ORDER BY Id ASC;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 6   -- Get Blacklist Ids by Campaign Id
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    DECLARE @BlackListIds VARCHAR(MAX);
                    SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
                    FROM Camplistanegra
                    WHERE cam_id = @Id
                          AND STATUS = 1;
                    SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 7   -- Get RegistryListIds Ids by Campaign Id
        BEGIN
            IF(@Id IS NOT NULL
               AND EXISTS
            (
                SELECT *
                FROM cccamps
                WHERE cam_id = @Id
            ))
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
                    RAISERROR(''ERROR. No existe una campa?a con el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 8   -- Delete RegistryListIds Ids by LoadId
        BEGIN
            IF(@LoadId IS NOT NULL
               AND EXISTS
            (
                SELECT *
                FROM ccRIARegistryLists
                WHERE list_id = @loadID
                      AND STATUS <> 0
            ))
                BEGIN
                    UPDATE ccoCallsOutSource
                      SET 
                          cal_status = ''5''
                    WHERE list_id = @loadID;
                    DELETE FROM ccoWorkingTable
                    WHERE list_id = @LoadId;
                    EXEC ccsp_RIARegistryLists 
                         @action = 6, 
                         @list_id = @LoadId;
            END;
            ELSE
                BEGIN
                    --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                    RAISERROR(''ERROR. No existe una carga el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @option = 9   -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
        BEGIN
            DECLARE @table TABLE
            (camId    INT, 
             campType TINYINT, 
             PRIMARY KEY(camId, campType)
            );
            INSERT INTO @table
                   SELECT DISTINCT 
                          IdCampEsp, Tipo
                   FROM ccRIACampEspWG wg
                   WHERE wg.IDWG IN
                   (
                       SELECT IDWG
                       FROM ccRIAWorkGroupUsers
                       WHERE IDWG <> @WorkgroupId
                             AND User_id = @AdminId
                   );
            SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
            FROM @table A
                 RIGHT JOIN
            (
                SELECT wg.IdCampEsp, wg.Tipo
                FROM ccRIACampEspWG wg
                WHERE wg.IDWG = @WorkgroupId
            ) B ON A.camId = B.IdCampEsp
                   AND A.campType = B.Tipo
            WHERE A.camId IS NULL
                   ORDER BY IdCampEsp;
            RETURN 0;
    END;
    IF @option = 10  -- Get Agents States with totals per campaign by admin id and campaign type
    BEGIN
  DECLARE @date DATETIME= CONVERT(DATE, DATEADD(hh, -3, GETDATE()));
  DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY(id));
  DECLARE @AgentsList TABLE(id INT, PRIMARY KEY(id));
  DECLARE @tmpCamAgent TABLE(camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY(camId, userId));
  DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT);
  DECLARE @CurrentStatus TABLE(userId INT, CurrentState INT, IdCampEsp INT, camType INT);
  DECLARE @campDataTotal TABLE(camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY(camId));

  INSERT INTO @AdminWorkgroups SELECT DISTINCT IDWG
  FROM ccRIAWorkGroupUsers WG, 
     ccUsers_Roles R
  WHERE WG.User_id = @AdminId
  OR (R.User_id = @AdminId
  AND R.Rol_id = 7);
    	
  INSERT INTO @AgentsList SELECT DISTINCT A.User_id
  FROM ccRIAWorkGroupUsers A
  INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
  INNER JOIN ccUsers C ON A.User_id = C.User_id 
  AND C.TipoUser_id = 1
    ORDER BY A.User_id;


	

  INSERT INTO @tmpCamAgent 
  SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id,
  CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
  FROM ccRIACampEspWG campPerWg
  INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
  INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
  INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
  left JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp and @CampType = 0
  left JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp and @CampType = 1
  where C.TipoUser_id = 1
  AND campPerWg.Tipo = @CampType
  AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
  
  WITH lastState AS (
  SELECT A.user_id, MAX(A.fecha) AS fecha
  FROM ccLogAgentesDia A
  INNER JOIN @AgentsList B ON A.User_id = B.id
  WHERE fecha >= @date
  GROUP BY user_id)

    INSERT INTO @CurrentStatus 
  SELECT B.User_id,
  CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS currentStatus,
  B.IdCampEsp,
  B.Tipo
  FROM lastState A
  INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
  AND A.fecha = B.fecha;

  IF @Id = 0 AND @CampType = 0 
  BEGIN
    DELETE FROM @tmpCamAgent WHERE multimediaType = 5
  END

  DECLARE @MultimediaType SMALLINT = (SELECT CASE WHEN @CampType = 1 THEN -1 ELSE meanContactTypeId END
                    FROM contactMeanIn WHERE inboundId = @Id)

  DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes

  INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
  (CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = @CampType
   THEN @CampType ELSE null END) AS isCampDialog,
   B.camType
  FROM @tmpCamAgent A
  INNER JOIN @CurrentStatus B ON A.userId = B.userId
  WHERE (@Id = 0 or A.camId = @Id)

  IF @CampType = 1
    BEGIN
    ;with  campDataTotal as(
      select camId,count(*) total from @tmpCamAgent A group by camId
    )

    insert into @campDataTotal
    select 
      A.camId,
      B.cam_descripcion as campName 
      ,A.Total
      ,C.AreaName as Area
      from campDataTotal A
      INNER JOIN ccCamps B ON A.camId= B.cam_id 
      INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END
  ELSE
    BEGIN    
    ;with  campDataTotal as(
      select camId,count(*) total from @tmpCamAgent A group by camId
    )

    insert into @campDataTotal
    select 
      A.camId,
      B.descripcion as campName 
      ,A.Total
      ,C.AreaName as Area
      from campDataTotal A
        INNER JOIN ccInbound B ON A.camId = B.Inbound_id 
      INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END 


  ;WITH stateCamp AS(
    SELECT A.CampId,
    count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready,
    count(CASE WHEN A.CurrentState NOT IN(-2, -1, 0, 3, 4, 5, 6, 9, 30, 34) THEN 1 
           WHEN A.CurrentState IN (6, 34, 4) AND (A.CampId != C.IdCampEsp OR A.campType != @CampType) THEN 1 ELSE NULL END) AS notReady,
    COUNT(isCampDialog) AS dialog,
    COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected 
    FROM @AgentStatus A
    INNER JOIN @CurrentStatus C ON A.userId = C.userId
    GROUP BY A.CampId
  )

  SELECT 
    A.camId,
    A.campName,
    A.Total,
      ISNULL(B.ready, 0) AS Ready,
    ISNULL(B.notReady, 0 ) AS NotReady, 
    ISNULL(B.dialog, 0) AS Dialog,
    CASE WHEN B.disconnected IS NULL THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END Disconnected,
    A.Area
  FROM @campDataTotal A
  LEFT JOIN stateCamp B ON A.camId = B.CampId
  ORDER BY A.CampName;

        RETURN 0;
    END;
    IF @Option = 11  -- Get Campaigns Ids List Per Workgroup and Campaign Type
        BEGIN                
            IF Not EXISTS
            (
                SELECT *
                FROM ccUsers_Roles NOLOCK
                WHERE User_id = @AdminId
                      AND Rol_id = 7
            )
                BEGIN
        print ''xxxx SIn Super''
                    ;WITH wgId
                         AS (SELECT IDWG
                             FROM ccRIAWorkGroupUsers NOLOCK
                             WHERE user_id = @AdminId)
                         SELECT DISTINCT 
                                CAST(IdCampEsp AS INT) AS Id
                         FROM ccRIACampEspWG A (NOLOCK)
                              INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                 AND A.Tipo = @CampType;
            END;
            ELSE
                BEGIN
      --print ''xxxx Super''
      IF @CampType = 1
        BEGIN
          SELECT DISTINCT 
               CAST(cam_id AS INT) AS Id
                        FROM ccCamps (NOLOCK) where IDArea IS NOT NULL
        END
      ELSE
        BEGIN 
          SELECT DISTINCT 
               CAST(Inbound_id AS INT) AS Id
                        FROM ccInbound (NOLOCK) where IDArea IS NOT NULL
        END
            END;
            RETURN 0;
    END;
    IF @Option = 12  -- Get All Campaigns complete information per Campaign Type and Campaign Id
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    SELECT DISTINCT 
                           CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area,  
                           CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType
                    FROM ccCamps camps (NOLOCK)
                         INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
                         INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
                           --WHERE camps.cam_id = @Id
                           ORDER BY camps.cam_descripcion ASC;
            END;
            ELSE
                BEGIN
                    SELECT DISTINCT 
                           CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType
                    FROM ccInbound inb (NOLOCK)
                         INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
                         INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = inb.IDArea
                           ORDER BY inb.descripcion ASC;
            END;
            RETURN 0;
    END;
	IF @Option = 13
	BEGIN
		BEGIN                
			IF NOT EXISTS
			(
				SELECT *
				FROM ccUsers_Roles NOLOCK
				WHERE User_id = @AdminId
						AND Rol_id = 7
			)
				BEGIN
					IF @CampType = 1
						BEGIN
							WITH wgId
								AS (SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT 
									CAST(IdCampEsp AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,CAST(-1 AS INT) AS RelatedCampId
								FROM ccRIACampEspWG A
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 1
									INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id;
						END
					ELSE
						BEGIN
							WITH wgId
								AS (SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT 
									CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
								FROM ccRIACampEspWG A (NOLOCK)
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 0
									INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id 
									AND ((@multi_type is null AND cci.chat = @InboundType)
										OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
						END
			END;
			ELSE
				BEGIN
				IF @CampType = 1
					BEGIN
						SELECT DISTINCT 
								CAST(cam_id AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,-1 AS RelatedCampId
						FROM ccCamps NOLOCK where IDArea = @AreaId
					END
				ELSE
					BEGIN 
						SELECT DISTINCT 
								CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
						FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
						AND ((@multi_type is null AND cci.chat = @InboundType)
							OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

					END
			END;
			RETURN 0;
		END;
	END;

	IF @Option = 14
		BEGIN
			IF NOT EXISTS
			(
					SELECT *
					FROM ccUsers_Roles NOLOCK
					WHERE User_id = @AdminId
							AND Rol_id = 7
			)
				BEGIN
					WITH wgId
							AS (SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT 
								CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
							FROM ccRIACampEspWG A (NOLOCK)
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
    IF @Option = 15
        BEGIN
            SELECT DISTINCT 
            CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
            FROM ccInbound NOLOCK where cam_id = @Id
        END
END;
        '
        EXEC(@sql)

        SET @process = 'ALter SP ccsp_GalateaAdminDispositions Relaciones de campañas'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
@command int,
@calif_id smallint = null,
@califIdLst varchar(8000) = null,
@description varchar(60)=null,
@order tinyint=null,
@canReprogram bit = null,
@graphColor varchar(15) = null,
@endConversation bit=null,
@keepDial bit=null,
@autoCB bit=null,
@contactOwner bit=null,
@finishPreview bit = 0,
@allNumbersToBlacklist bit = 0
AS
set nocount on
declare @inserted table (ID smallint)

if @command=1 -- Load Inbound Dispositions
begin
  Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner, 
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd, graphColor
  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
  where C.Calif_Status=1
  group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation, graphColor
  order by 2
  return(0)
end

If @command=2 -- Load Outbound Dispositions
begin
  Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,  
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner, 
  IsNull(C.finishPreview,0) as finishPreview, graphColor, allNumbersToBlacklist
  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
  where C.CalifOut_Status=1
  group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
  C.contactOwner, C.finishPreview, graphColor, allNumbersToBlacklist
  order by 2
  return(0)
end

If @command=3 -- New ccTipoCalif
begin
  If exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@description)
    begin
      select cast(-1 as smallint) [result]	-- Disposition already exists
      return(0)
    end

  If exists(select calif_id from ccTipoCalif where Calif_Status=0 and description=@description)
  begin
	select top 1 @calif_id = calif_id from ccTipoCalif where Calif_Status=0 and description=@description order by calif_id desc
    update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0), 
	graphColor=isnull(@graphColor, ''1DB4E2''), Calif_Status=1
	output inserted.calif_id into @inserted
    where calif_id=@calif_id
	select ID [result] from @inserted 
    return(0)
  end

  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , graphColor)
  output inserted.calif_id into @inserted
  select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalif
  select ID [result] from @inserted
  return(0)
end

If @command=4 -- New ccTipoCalifOUT
begin
  If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
  begin
  select cast(-1 as smallint) [result]	-- Disposition already exists
  return(0)
  end

 If exists(select calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
 begin
	select top 1 @calif_id = calif_id from ccTipoCalifOut where CalifOut_Status=0 and description=@description order by calif_id desc
	update ccTipoCalifOut set autoTime=0, orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), idTipoLista=0,
	Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), 
	finishPreview=isnull(@finishPreview,0), graphColor=isnull(@graphColor, ''1DB4E2'')
	output inserted.calif_id into @inserted
	where calif_id=@calif_id
	select ID [result] from @inserted 
	return(0)
 end

 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, graphColor, allNumbersToBlacklist)
 output inserted.calif_id into @inserted
 select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, isnull(@canReprogram,0), isnull(@keepDial,0), 
 isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, ''1DB4E2''), ISNULL(@allNumbersToBlacklist,0) from ccTipoCalifOut
 select ID [result] from @inserted 
 return(0)
end
If @command=5 -- Delete Inbound Dispositions
begin
    delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    return(0)
end
if @command=6 -- Delete Outbound Disposition
begin
	delete from ccCalifCamp where tipo=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	delete from cctipoSubCalifRel where tipoSubRel=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	update ccTipoCalifOUT set CalifOut_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	return(0)
end
if @command=7 -- Update Inbound Disposition
begin
	if(exists(select calif_id from ccTipoCalif where Calif_Status=1 and description=@Description and calif_id<>@calif_id))
	begin
		select cast(-1 as smallint) [result]	-- Disposition already exists
		return(0)
	end

    UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
    canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  
	EndConversation=isnull(@endConversation,EndConversation)
	output inserted.calif_id into @inserted
    where calif_id=@calif_id

    delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

	select ID [result] from @inserted
    return(0)
end
if @command=8 -- Update Outbound Disposition
begin
	if(exists(select calif_id from ccTipoCalifOUT where CalifOut_Status=1 and Description=@description and calif_id<>@calif_id))
	begin
		select cast(-1 as smallint) [result]	-- Disposition already exists
		return(0)
	end

	UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
	canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  keepDial=isnull(@keepDial,keepDial), 
	autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner), 
	finishPreview = isnull(@finishPreview,finishPreview), allNumbersToBlacklist = isnull(@allNumbersToBlacklist, allNumbersToBlacklist)
	output inserted.calif_id into @inserted
	where calif_id=@calif_id

	if @keepDial is not null
	begin
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	end

	select ID [result] from @inserted
	return(0) 
	end

set nocount off'
        EXEC(@sql)

        SET @process = 'ALter SP ccsp_GalateaAdminInbound Relaciones de campañas'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT, 
                                                @InboundId AS SMALLINT = 0,
												@User_id AS SMALLINT = 0,
												@OutboundID AS SMALLINT = 0,
												@multi_cam as varchar(max) = null
	AS
	BEGIN
	    set nocount on;

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
				DlgsAveTime = ISNULL(SUM (CASE WHEN statusCall_id = 13 THEN cal_tDialog + cal_tNotas ELSE 0 END), 0),
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
			IF(@multi_cam is not null)
			BEGIN
				UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id IN (
					SELECT value from dbo.fn_RIASplitDelimited(@multi_cam,'',''))
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
					SELECT 1;
					RETURN 1;
				END;
		END;        
		IF(@Option = 6) -- Delete the relation between inbound and outbound campaigns
		BEGIN
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
	END'
        EXEC(@sql)

		SET @process = 'ALter SP ccsp_GalateaAdminDispositionRelations Relaciones de campañas'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminDispositionRelations]
@command int,
@type tinyint = null, --0=In, 1=Out
@cam_id smallint = null,
@califIdLst varchar(8000) = null
AS
set nocount on
declare @sql as nvarchar(max)

If @command = 1
begin
	select 
		cast (0 as int) [type], 
		i.inbound_id as cam_id, 
		c.calif_id 
	from ccInbound i inner join ccCalifCamp c on i.inbound_id = c.cam_id and c.tipo = 0
	inner join ccTipoCalif t on c.calif_id = t.calif_id
	UNION
	select 
		cast (1 as int) [type], 
		o.cam_id, 
		c.calif_id 
	from ccCamps o inner join ccCalifCamp c on o.cam_id = c.cam_id and c.tipo = 1
	inner join ccTipoCalifOUT co on c.calif_id = co.calif_id
	order by [type], cam_id, calif_id
end
If @command=2  --Asignar calificacion(es) a una campaña de entrada o salida
 begin 
	if @Type=0 
	begin	
		set @sql = ''declare @NotAssigned table(NotAssigned int); 
		declare @Assigned table(Assigned int);

		insert into @NotAssigned (NotAssigned)
		select calif_id from ccTipoCalif where CanReprogram=1 and calif_id in ('' + @califIdLst + '')
		and exists(select inbound_id from ccInbound where cam_id is null and Inbound_id= '' + cast(@cam_id as varchar(10)) + '')

		insert into ccCalifCamp(calif_id,cam_id,tipo) 
		select f.calif_id, e.inbound_id, 0 
		from ccInbound e, cctipoCalif f 
		where f.Calif_Status=1 and f.calif_id in ('' + @califIdLst + '') and f.calif_id not in (select NotAssigned from @NotAssigned)
		and Inbound_id = '' + cast(@cam_id as varchar(10)) + ''
		and not exists(
			select a.calif_id,c.inbound_id,0 from cctipoCalif a
			join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 0
			join ccInbound c on c.inbound_id = b.cam_id
			where f.calif_id = a.calif_id and e.inbound_id = c.inbound_id
			and c.Inbound_id = '' + cast(@cam_id as varchar(10)) + '')

		insert into @Assigned (Assigned)
		select calif_id from ccTipoCalif where calif_id in ('' + @califIdLst + '') and calif_id not in (select NotAssigned from @NotAssigned)

		declare @NotAssignedStr varchar(8000), @AssignedStr varchar(8000)
		SELECT @AssignedStr = COALESCE(@AssignedStr + '''','''', '''''''') + cast(Assigned as varchar(10)) from @Assigned
		select @NotAssignedStr = coalesce(@NotAssignedStr + '''','''', '''''''') + cast(NotAssigned as varchar(10)) from @NotAssigned

		select @AssignedStr [Assigned], @NotAssignedStr [NotAssigned]''
		execute sp_executesql @sql
	end
	else
	begin
		set @sql = ''insert into ccCalifCamp(calif_id,cam_id,tipo) 
		select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalifOUT f where 
		f.CalifOut_Status=1 and f.calif_id in ('' + @califIdLst + '') and cam_id = '' + cast(@cam_id as varchar(10)) + ''
		and not exists(
		select a.calif_id,c.cam_id, 1 from cctipoCalifOUT a
		join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 1
		join ccCamps c on c.cam_id = b.cam_id
		where f.calif_id = a.calif_id and e.cam_id = c.cam_id
		and b.cam_id = '' + cast(@cam_id as varchar(10)) + '')''
		execute sp_executesql @sql
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(@cam_id) where cam_id=@cam_id	
		return(0)
	end
 end
 If @command=3 -- Desasignar calificacion de campaña de entrada o salida
 begin
	delete ccCalifCamp where cam_id=@cam_id and tipo=@type and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(@cam_id) where cam_id=@cam_id
	return(0)
 end

set nocount off'
		EXEC(@sql)

------------------------- BEGIN Mensajes Automaticos ---------------------------------------------------------

-------------------------------------- AUTOMATIC MESSAGES  |  CW-7126 VARIABLE CREATION  |  IVAN    --------------------------------------

set @process = 'CW-7126 Create table ccRIA_AutamaticMessages_VariableDataTags'
set @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N''ccRIA_AutamaticMessages_VariableDataTags'')
			BEGIN
			    CREATE TABLE ccRIA_AutamaticMessages_VariableDataTags 
				(   LanguageId TINYINT NOT NULL,
					VariableDataTag VARCHAR(10) NOT NULL
					PRIMARY KEY (LanguageId)
				);
			END'
EXEC(@sql)

set @process = 'CW-7126 Add tags to ccRIA_AutamaticMessages_VariableDataTags'
set @sql = 'IF not EXISTS (SELECT * FROM ccRIA_AutamaticMessages_VariableDataTags)
			
			BEGIN
				INSERT INTO ccRIA_AutamaticMessages_VariableDataTags (LanguageId, VariableDataTag)
				VALUES (0,''Dato '')
				INSERT INTO ccRIA_AutamaticMessages_VariableDataTags (LanguageId, VariableDataTag)
				VALUES (1,''Data'')
				INSERT INTO ccRIA_AutamaticMessages_VariableDataTags (LanguageId, VariableDataTag)
				VALUES (2,''Dado '')
			END'
EXEC(@sql)

set @process = 'CW-7126 Create table ccRIA_AutamaticMessages_TtsTypesTags'
set @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N''ccRIA_AutamaticMessages_TtsTypesTags'')
			BEGIN
			    CREATE TABLE ccRIA_AutamaticMessages_TtsTypesTags 
				(	Id TINYINT NOT NULL,
					TtsTypesTagsSpanish VARCHAR(10) NOT NULL,
					TtsTypesTagsEnglish VARCHAR(10) NOT NULL,
					TtsTypesTagsPortuguese VARCHAR(10) NOT NULL
					PRIMARY KEY (Id)
				);
			END'
EXEC(@sql)

set @process = 'CW-7126 Add tags to ccRIA_AutamaticMessages_TtsTypesTags'
set @sql = 'IF not EXISTS (SELECT * FROM ccRIA_AutamaticMessages_TtsTypesTags)
			BEGIN
				INSERT INTO ccRIA_AutamaticMessages_TtsTypesTags (Id, TtsTypesTagsEnglish, TtsTypesTagsSpanish, TtsTypesTagsPortuguese)
				VALUES (0,''Spelling'', ''Deletreo'', ''Soletração'')
				INSERT INTO ccRIA_AutamaticMessages_TtsTypesTags (Id, TtsTypesTagsEnglish, TtsTypesTagsSpanish, TtsTypesTagsPortuguese)
				VALUES (1,''Date'', ''Fecha'', ''Data'')
				INSERT INTO ccRIA_AutamaticMessages_TtsTypesTags (Id, TtsTypesTagsEnglish, TtsTypesTagsSpanish, TtsTypesTagsPortuguese)
				VALUES (2,''Time'', ''Hora'', ''Hora'')
				INSERT INTO ccRIA_AutamaticMessages_TtsTypesTags (Id, TtsTypesTagsEnglish, TtsTypesTagsSpanish, TtsTypesTagsPortuguese)
				VALUES (3,''Currency'', ''Moneda'', ''Moeda'')
				INSERT INTO ccRIA_AutamaticMessages_TtsTypesTags (Id, TtsTypesTagsEnglish, TtsTypesTagsSpanish, TtsTypesTagsPortuguese)
				VALUES (4,''Number'', ''Número'', ''Número'')
				INSERT INTO ccRIA_AutamaticMessages_TtsTypesTags (Id, TtsTypesTagsEnglish, TtsTypesTagsSpanish, TtsTypesTagsPortuguese)
				VALUES (5,''General'', ''General'', ''Geral'')
			END'
EXEC(@sql)




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

declare @maxOrden int, @campName varchar(max), @num int
declare @T_all as table (id int, msg_id int)

if @campType=0
    set @campName = (select descripcion from ccInbound where Inbound_id=@campIO_id)
else
    set @campName = (select cam_descripcion from ccCamps where cam_id=@campIO_id)

    If @command=1
     begin
        if @campType=0 
         begin
            select @maxOrden = max(orden) from ccInboundMsgs where Inbound_id=@campIO_id and type=@type

            select @num = case when @maxOrden is null then 1 else 0 end
            set @maxOrden =ISNULL(@maxOrden,0)

            insert @T_all 
            select ROW_NUMBER() OVER(ORDER BY A.id ASC)-@num AS Row#,
            A.value from dbo.fn_RIASplitDelimited(@msg_id, '','') A
            left join ccInboundMsgs B on A.Value=B.Msg_id and B.Inbound_id=@campIO_id and B.Type=@type
            where B.Inbound_id  is null

            insert into ccInboundMsgs (msg_id, inbound_id, orden, type)
            select B.msg_id, @campIO_id as inbound_id, @maxOrden+B.id as orden,@type as type 
            from  @T_all B
            where msg_id not in(select Msg_id from ccInboundMsgs where Inbound_id=@campIO_id and Type=@type)

            select @campName
         end

        if @campType=1 
         begin
            select @maxOrden = max(orden) from ccCampsMsgs where cam_id=@campIO_id and type=@type

            select @num = case when @maxOrden is null then 1 else 0 end
            set @maxOrden =ISNULL(@maxOrden,0)

            insert @T_all 
            select ROW_NUMBER() OVER(ORDER BY A.id ASC)-@num AS Row#,
            A.value from dbo.fn_RIASplitDelimited(@msg_id, '','') A
            left join ccCampsMsgs B on A.Value=B.Msg_id and B.cam_id=@campIO_id and B.Type=@type
            where B.cam_id  is null

            insert into ccCampsMsgs(msg_id, cam_id, orden, type)
            select B.msg_id, @campIO_id as cam_id, @maxOrden+B.id as orden,@type as type 
            from  @T_all B
            where msg_id not in(select Msg_id from ccCampsMsgs where cam_id=@campIO_id and Type=@type)

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
    select ISNULL(msgName, msgFile) [MsgName], Descripcion [MsgDescription], msgFile [MsgFile], msg_id [MsgId] from ccMsgFiles
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
            update ccMsgFiles set Descripcion = @Description, msgName = @msgName, msgFile = @msgFile, length = @length where msg_id = @msg_id
        END
END 

if @action = 7
BEGIN
	select msg_id as MsgId, msgName as MsgName, Descripcion as MsgDescription, MsgFile as MsgFile from ccMsgFiles where msg_id = @msg_id
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

    IF @msg_id = 0
    BEGIN
    EXEC ccsp_RIAADMCampMsgs @Command = 3, @cam_id = @CampId, @order = @VariableOrder,@type=8,@msgFile=@TempMsgFile,@description=@Description   
    END
    ELSE
    BEGIN
        UPDATE ccMsgFiles SET msgFile = @TempMsgFile, Descripcion = @Description where msg_id = @msg_id
    END
    
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



set @process = 'CW-7321 No se cargan mas de 5 datos en Campañas recién creadas'
set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIALoadCamps] @option SMALLINT, @AreaId SMALLINT = NULL, @Sup SMALLINT = NULL, @WGID SMALLINT = NULL
AS
SET NOCOUNT ON

DECLARE @loginDays INT

SET @loginDays = 0

IF @option = 1 -- Todas las campañas
BEGIN
    SELECT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0), isnull(DNCscrub, 0)
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    WHERE a3.type_id = 1 AND a1.cam_id IN (
            SELECT cam_id
            FROM dbo.fGet_CampAcd_Area(@Sup, 1)
            )
    ORDER BY 5, 2

    RETURN (0)
END

IF @option = 2 -- Campañas de un Area
BEGIN
    SELECT DISTINCT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
    ORDER BY cam_descripcion

    RETURN (0)
END

IF @option = 3 -- Campañas por Supervisor
BEGIN
    SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(a1.IDArea, 0) IDArea
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    JOIN ccSupervisorCam a4 ON a1.cam_id = a4.cam_id
    WHERE a3.type_id = 1 AND a4.tipo = 1 AND a4.user_id = @Sup
    ORDER BY 5, 2

    RETURN (0)
END

IF @option = 4 -- Rels Camps-Agents
BEGIN
    SELECT @loginDays = valor
    FROM ccSettings
    WHERE setting_id = 211 --Numero dias que cargara las relaciones

    SELECT LOGIN, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea, min(rel_id) rel_id
    FROM (
        SELECT A.LOGIN, A.User_id, Prioridad, Skill, C.cam_id, C.cam_descripcion, isnull(C.IDArea, 0) IDArea, CA.rel_id
        FROM ccCamps C
        JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id
        JOIN ccRIACampsGraph a2 ON C.cam_id = a2.cam_id
        JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
        JOIN ccUsers A ON A.User_id = CA.User_id AND A.TipoUser_id = 1 AND A.STATUS = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays)
        WHERE C.cam_id IN (
                SELECT cam_id
                FROM ccsupervisorcam
                WHERE user_id = CASE isnull(@Sup, 0) WHEN 0 THEN user_id ELSE @Sup END AND tipo = 1
                )
        ) Relations
    GROUP BY LOGIN, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea
    ORDER BY User_id, cam_descripcion, cam_id, Prioridad

    RETURN (0)
END

IF @option = 5 -- Campañas por Supervisor
BEGIN
    SELECT @AreaId = IDArea
    FROM ccUsers
    WHERE User_id = @sup

    SELECT DISTINCT Camps.cam_id, Camps.cam_descripcion, a3.frame, Camps.cam_procesando, isnull(Camps.IDArea, 0) IDArea, IsNull(CN.New, 0) AS New, IsNull(CN.CB, 0) AS CB, IsNull(CN.Pro, 0) AS Pro, IsNull(CN.pen, 0) AS Pen, cast(Camps.cam_procesando AS INT) AS St, Camps.cam_TipoJobs AS Job, isnull(CN.Fin, 0) Fin, isnull(CP.prioridad, ''12345NNN'') prioridad, cast(camps.dialorder AS TINYINT) dialorder, cast(camps.progDial AS TINYINT) progDial, U.monitored, Camps.aggressionFactor
    FROM ccCamps Camps
    LEFT JOIN ccCampsPrioridadTel CP ON CP.cam_id = Camps.cam_id
    LEFT JOIN ccCampsNvosCB CN ON CN.id = Camps.cam_id
    JOIN ccRIACampsGraph a2 ON (Camps.cam_id = a2.cam_id)
    JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
    JOIN ccSupervisorCam U ON Camps.cam_id = U.cam_id
    WHERE U.user_id = @sup AND tipo = 1 AND a3.type_id = 1 AND Camps.cam_id IN (
            SELECT cam_id
            FROM ccSupervisorCam
            WHERE tipo = 1 AND user_id = @sup
            ) AND Camps.IDArea = @AreaId
    ORDER BY 5, cam_procesando DESC, cam_descripcion

    RETURN (0)
END

IF @option = 7 -- Una sola
BEGIN
    SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(IDArea, 0) IDArea, isnull(DNCscrub, 0) DNCScrub
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    WHERE a3.type_id = 1 AND isnull(a1.cam_id, 0) = isnull(@AreaId, 0)
    ORDER BY 5, 2

    RETURN (0)
END

IF @option = 8 -- Campañas de un Agente
BEGIN
    SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    JOIN ccCampsAgente a4 ON a1.cam_id = a4.cam_id
    WHERE a3.type_id = 1 AND a4.user_id = @Sup
    ORDER BY 2

    RETURN (0)
END
IF @option = 9 -- Campañas de un Area
BEGIN
    (SELECT DISTINCT a1.cam_id as CamID, cam_descripcion as CamDescription, frame as Frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) as RelationsWG,1 CamType, 
    ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 1 and IdCampEsp = a1.cam_id and IDWG = @WGID group by IdCampEsp),0) IsAssignedToCurrentWG,
    CAST(CASE WHEN a1.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) [MediaType]
    FROM ccCamps a1
    JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
    JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
    WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
    UNION
    SELECT DISTINCT b1.inbound_id, descripcion, frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(b1.inbound_id, 2) relationsWG, 0 CampType, 
    ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 0 and IdCampEsp = b1.inbound_id and IDWG = @WGID group by IdCampEsp),0) isAssignedToCurrentWG,
    b1.chat [MediaType]
    FROM ccinbound b1
    JOIN ccRIAinboundGraph b2 ON b1.inbound_id = b2.inbound_id
    INNER JOIN ccRIAGraphics b3 ON b2.graphic_id = b3.graphic_id
    LEFT JOIN (
        SELECT inbound_id, CASE WHEN (sum(skill) / count(user_id)) = max(skill) THEN 0 ELSE 1 END skillDif
        FROM ccSkills
        GROUP BY inbound_id
        ) S ON S.Inbound_id = b1.inbound_id
    WHERE b3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
    ) ORDER BY camtype desc,cam_descripcion

    RETURN (0)
END

RETURN (0)

SET NOCOUNT OFF'
EXEC(@sql)

    set @process = 'CW-7457 Se elimina SP ccsp_ccActivityDataQuery si existe'
    set @sql = 'if exists (select * from sys.procedures where name =''ccsp_ccActivityDataQuery'')
    begin
        DROP PROCEDURE ccsp_ccActivityDataQuery
    end'
    EXEC(@sql)

    set @process = 'CW-7457 Se crea SP ccsp_ccActivityDataQuery'
    set @sql = '
	CREATE PROCEDURE [dbo].[ccsp_ccActivityDataQuery]
	@action int,@userId int=0,@camId int=0,@dnisId int=0,@WgId int=0,@tipo int =null
	,@camIdOuts varchar(1000)='''',@camIdIns varchar(1000)=''''
	AS
	set nocount on

	declare @valdiate int
	declare @packageData varchar(8000)
	declare @nTipoCallTotal int
	set @packageData =''''
	set @valdiate=0
	set @nTipoCallTotal=0

	if @action=1 begin	
		if exists(select * from cccamps nolock where cam_bNew=1) begin
			set @valdiate=1
			Update ccCamps SET cam_bNew=0 Where cam_bNew=2
			Update ccCamps SET cam_bNew=2 Where cam_bNew=1
		end	
		select @valdiate as isUpdate
	end
	else if @action=2 begin		
		if exists(select * from cccamps nolock where cam_bNew=3) begin
		set @valdiate=1
			Update ccCamps SET cam_bNew=0 Where cam_bNew=4
			Update ccCamps SET cam_bNew=4 Where cam_bNew=3
		end
		select @valdiate as isUpdate
	end
	else if @action=3 begin		
	SELECT User_id, TipoLlamadas FROM ccUsers WHERE User_ID = @userId
	end
	else if @action=4 begin	
	SELECT A.Login, A.User_id, prioridad, skill, A.TipoLlamadas, C.cam_id, C.cam_descripcion, C.cli_id 
	FROM ccCamps C JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id 
	JOIN ccUsers A  ON A.User_id = CA.User_id 
	AND A.TipoUser_Id =1 AND C.cam_id =  @camId
	order by A.Login, A.User_id, CA.prioridad, CA.skill, C.cam_id
	end
	else if @action=5 begin	
	SELECT Login, TipoLlamadas, User_id, password, Nombres +'' ''+ ApellidoPaterno FROM ccUsers nolock WHERE User_id = @userId
	end
	else if @action=6 begin	
	SELECT Inbound_id, descripcion, cli_id FROM ccInbound nolock WHERE Inbound_id =@camId
	end
	else if @action=7 begin	
	SELECT Inbound_id, descripcion, cli_id, tnotas, nMaxQue FROM ccInbound WHERE Inbound_id = @camId
	end
	else if @action=8 begin	
	SELECT dni_id, dni_numero, T.tipodni_id, prioridad, dni_tpoMaxEspera 
	FROM ccDNIS D join ccTipoDNIS T on D.tipodni_id = T.tipodni_id 
	WHERE dni_id = @dnisId and dni_tipo=2
	end
	else if @action=9 begin	
	SELECT dni_id, dni_numero, dni_tipo, prioridad, dni_tpoMaxEspera 
	FROM ccDNIS D join ccTipoDNIS T on D.tipodni_id=T.tipodni_id 
	WHERE dni_id = @dnisId and dni_tipo=2
	end
	else if @action=10 begin	
	SELECT dni_id, dni_numero, D.tipodni_id, prioridad, dni_tpoMaxEspera 
	FROM ccDNIS D join cctipoDnis TD on D.tipodni_id = TD.tipodni_id
	WHERE dni_tipo=2
	end
	else if @action=11 begin	
	SELECT Inbound_id, descripcion, tNotas, nMaxQue FROM ccInbound
	end
	else if @action = 12 begin 
		; with WgUser AS(
		select 
		WG.IDWG,A.IdCampEsp,A.Tipo from ccRIAWorkGroupUsers WG
		inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
		inner join ccRIACampEspWG A on A.IDWG=WG.IDWG	
		where WG.IDWG<>@WgId
		)
		, wGCamp AS(
		select IDWG, IdCampEsp,Tipo from ccRIACampEspWG A
		where A.IDWG in(select IDWG from WgUser) or A.IDWG=@WgId
		), dataDiferent as
		(
		select distinct	
		convert(varchar, A.IdCampEsp)+''-''+convert(varchar,A.Tipo+1)  
		+''-''+convert(varchar,COALESCE (campAgent.prioridad ,inboundAgent.prioridad,1)) 
		+''-''+convert(varchar,COALESCE (campAgent.skill ,inboundAgent.skill,1))
		as CampAndType
		from wGCamp A
		left join WgUser B on A.IdCampEsp=B.IdCampEsp and A.Tipo=B.Tipo	
		left join ccCampsAgente campAgent on A.IdCampEsp = campAgent.cam_id and A.Tipo=1
		left join ccInboundAgentes inboundAgent on A.IdCampEsp = inboundAgent.inbound_id and A.Tipo=0
		where B.IdCampEsp is null
		)
		select @packageData=CampAndType+'',''+@packageData from dataDiferent	
		
		select  @nTipoCallTotal = A.Tipo+1 +@nTipoCallTotal 
		from ccRIAWorkGroupUsers WG
		inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
		inner join ccRIACampEspWG A on A.IDWG=WG.IDWG	
		where WG.User_id=@userId
		group by A.Tipo 

		select @packageData as packageData, @nTipoCallTotal as nTipoCallTotal

	end

	else if @action = 13 begin 
		; with WgCamp As(
		select IDWG,IdCampEsp,tipo from ccRIACampEspWG A
		where tipo=@tipo and IdCampEsp=@camId and IDWG<>@WgId
		)
		, WgUserCamp as(
		select C.Login,WGUser.User_id,WgCamp.* from ccRIAWorkGroupUsers WGUser
		inner join WgCamp on WGUser.IDWG=WgCamp.IDWG 
		inner join ccUsers C on WGUser.User_id=C.User_id and C.TipoUser_id=1
		), dataDiferent as(	
	
		select distinct convert(varchar, WG.User_id)
		+''-''+convert(varchar,COALESCE (campAgent.prioridad ,inboundAgent.prioridad,1))
		+''-''+convert(varchar,COALESCE (campAgent.skill ,inboundAgent.skill,1))	CampAndType
		from ccRIAWorkGroupUsers WG	
		inner join ccUsers C on WG.User_id=C.User_id and C.TipoUser_id=1
		left join ccCampsAgente campAgent on campAgent.user_id=c.User_id
		left join ccInboundAgentes inboundAgent on inboundAgent.User_id=c.User_id
		where Wg.IDWG=@WgId and Wg.User_id not in(select User_id from WgUserCamp)
		)

		select @packageData=CampAndType+'',''+@packageData from dataDiferent 

		select @packageData  as packageData order by 1 desc
	end
	else if @action = 14 begin --Delete WG
		; with wgCam as (
		select Value as camId,1 calltype from dbo.fn_RIASplitDelimited(@camIdOuts,'','')
		union
		select Value as camId,0 calltype from dbo.fn_RIASplitDelimited(@camIdIns,'','')
		)
		, relationUser as(

		select campWg.IdCampEsp as camId,campWg.Tipo from ccRIAWorkGroupUsers WG
		inner join ccRIACampEspWG campWg on campWg.IDWG=Wg.IDWG 	
		where WG.User_id=@userId
		)
		, dataDiferent  as
		(	
		select distinct convert(varchar, wgCam.camId)+''-''+convert(varchar,wgCam.callType+1)   as CampAndType
		from wgCam
		left join relationUser A on wgCam.camId=A.camId and wgCam.calltype=A.Tipo
		where A.camId is null
		)

		select @packageData=CampAndType+'',''+@packageData from dataDiferent

		select  @nTipoCallTotal = A.Tipo+1 +@nTipoCallTotal 
		from ccRIAWorkGroupUsers WG
		inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
		inner join ccRIACampEspWG A on A.IDWG=WG.IDWG	
		where WG.User_id=@userId
		group by A.Tipo 

		select @packageData  as packageData, @nTipoCallTotal as nTipoCallTotal
	end
	'
    EXEC(@sql)
	
	set @process = 'Se elimina SP ccspAgent_GetLastCalls si existe'
    set @sql = 'if exists (select * from sys.procedures where name =''ccspAgent_GetLastCalls'')
    begin
        DROP PROCEDURE ccspAgent_GetLastCalls
    end'
    EXEC(@sql)
	
	set @process = 'Se crea SP ccspAgent_GetLastCalls,se hace modificacion en la llave primaria para evitar problemas al traer callid iguales pero de diferente tipo'
    set @sql = '
	CREATE PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
	AS
     SET NOCOUNT ON;
     DECLARE @lastCallAgt TABLE(id           INT NOT NULL
                              , tipo         VARCHAR(10) NOT NULL
                              , Hora         DATETIME NOT NULL --VARCHAR(19) NOT NULL, 
                              , Telefono     VARCHAR(55) NOT NULL
                              , EspCamp      VARCHAR(55) NOT NULL
                              , Calificacion VARCHAR(60)
                              , Duracion     VARCHAR(10) NOT NULL
                              , CallBack     DATETIME
                              , cal_key      VARCHAR(40)
                              , IDCampEsp    SMALLINT NOT NULL
                              , prefijo      VARCHAR(255) NULL
                              , GraphicID    INT
                              , PRIMARY KEY(id,tipo)
     );

     DECLARE @pais TINYINT;
     DECLARE @maxHours SMALLINT;
     DECLARE @topRows INT;
     DECLARE @setting VARCHAR(6);
     DECLARE @hidePhone BIT;
     DECLARE @dateStart DATETIME;

     SET @hidePhone = 1;

     SELECT @setting = valor FROM ccSettings WHERE setting_id = 255;

     SET @maxHours = CAST(SUBSTRING(@setting, 1, (SELECT PATINDEX(''%|%'', @setting)) - 1) AS SMALLINT);
     SET @topRows = CAST(SUBSTRING(@setting, (SELECT PATINDEX(''%|%'', @setting)) + 1, LEN(@setting)) AS INT);

     IF @maxHours = 0
     BEGIN
         SELECT Id
              , tipo
              , (CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) AS Hora
              , Telefono
              , EspCamp
              , Calificacion
              , CallBack
              , Duracion
              , '''' AS CallBack
              , cal_key
              , IDCampEsp
              , prefijo
              , GraphicID
              , @hidePhone AS HidePhone FROM @lastCallAgt;

         RETURN 0;
     END;

     SELECT @pais = valor FROM ccSettings WHERE setting_id = 104;

     SELECT @hidePhone = CASE WHEN valor = ''0''
                         THEN 0 ELSE 1
                         END FROM ccSettings WHERE setting_id = 223;

     IF @topRows = 0
     BEGIN
         SET @topRows = 10000;
     END;

     SET @dateStart = DATEADD(hh, -@maxHours, GETDATE());

     WITH timeTransfer
          AS (SELECT cal_id
                   , tipo
                   , SUM(tAntesXfer) AS tAntesXfer
                   , SUM(tDespuesXfer) AS tDespuesXfer FROM ccLogTransfers
              WHERE fechaFin > @dateStart
              GROUP BY cal_id
                     , tipo)

          INSERT INTO @lastCallAgt
                 ---Insert OUT
                 SELECT TOP (@topRows) c.cal_id AS id
                                     , ''OUT'' AS Tipo
                                     , cal_inicio
                                     , cal_telefono AS Telefono
                                     , cam_descripcion AS EspCamp
                                     , ISNULL(cal.Description, '''') AS Calificacion
                                     , CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
                                                                                                THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
                                                                                                END, 0), 114) AS Duracion
                                     , cal_fcallback AS CallBack
                                     , cal_key
                                     , c.cam_id AS IDCampEsp
                                     , ISNULL(ccCamps.prefijo, '''') Prefijo
                                     , graph.graphic_id GraphicID FROM ccoCallsOut c
                                                                       INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
                                                                       LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
                                                                       LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
                                                                       LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
                                                                                                   AND t.tipo = 2
                 WHERE user_id = @user_id
                       AND cal_inicio > @dateStart
                 UNION
                 --- IN
                 SELECT TOP (@topRows) c.cal_id AS id
                                     , ''IN'' AS Tipo
                                     , cal_inicio
                                     , cal_ani AS Telefono
                                     , descripcion AS EspCamp
                                     , ISNULL(cal.Description, '''') AS Calificacion
                                     , CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0
                                                                                                     THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
                                                                                                     END, 0), 108) Duracion
                                     , NULL AS CallBack
                                     , cal_key
                                     , c.inbound_id AS IDCampEsp
                                     , ISNULL(ccInbound.prefijo, '''') Prefijo
                                     , graph.graphic_id GraphicID FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
                                                                       JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
                                                                       INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
                                                                       LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
                                                                       LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
                                                                                                   AND t.tipo = 1
                 WHERE user_id = @user_id
                       AND cal_inicio > @dateStart;

     SELECT Id
          , tipo
          , CASE WHEN @pais = 4
            THEN(CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) ELSE(CONVERT(VARCHAR(10), Hora, 103) + '' '' + CONVERT(VARCHAR(8), Hora, 14))
            END AS Hora
          , Telefono
          , EspCamp
          , Calificacion
          , ISNULL(CONVERT(VARCHAR(16), CallBack, 121), '''') AS CallBack
          , Duracion
          , CallBack
          , cal_key
          , IDCampEsp
          , prefijo
          , GraphicID
          , @hidePhone AS HidePhone FROM @lastCallAgt
     ORDER BY hora DESC;
     SET NOCOUNT OFF;'
    EXEC(@sql)

------------------------- END Mensajes Automaticos ---------------------------------------------------------

------------------------- BEGIN Capacitacion ---------------------------------------------------------

set @process = 'DEV1-81 ALter ccsp_GalateaDnis Correcion de dnis'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaDnis]
@User varchar(10),
@Tipo tinyint,
@Dnis varchar(40) = null,
@Inbound_id smallint = null,
@dni_id as smallint = null,
@dnis_ids as varchar(MAX) = null,
@dni_description as varchar(40) = null,
@dni_isBlock as bit = null
as
set nocount on


if @Tipo = 1 -- carga dnis
 begin
    select dni_id, dni_numero as dni_number, dni_descripcion as dni_description, case when dni_id in(select dni_id from ccInboundDnis) then 1 else 0 end dni_isRelated
    from ccDnis where dni_Status=1 order by 2
    return(0)
 end

if @Tipo = 2 -- carga relaciones de dnis
 begin
    declare @UserId int=cast(@user as smallint)
    declare @isSuperUser bit=0

    if @UserId > 0 and exists (
        select * from ccUsers_Roles A
        inner join ccRoles R on A.Rol_id=R.Rol_id and R.Level=7
            where User_id = @UserId
        ) begin
            set @isSuperUser =1
        end

    ;with relationDnis as(
        select a1.Inbound_id, cast(0 as smallint) dni_id, a1.descripcion as description,'''' as dni_number,'''' as dni_description, cast(0 as tinyint) dni_isBlock
        from ccInbound a1
        inner join ccRIAInboundGraph a2 on (a1.Inbound_id = a2.Inbound_id)
        inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
        where a3.type_id = 1 and IDArea is not null 
        and a1.Inbound_id not in (select Inbound_id from ccInboundDnis)
        union
        select ci.inbound_id, cid.dni_id, ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock
        from ccInboundDnis cid 
        inner join ccInbound ci on ci.inbound_id = cid.inbound_id 
        join ccDnis cd on cd.dni_id = cid.dni_id 
        where cd.dni_Status=1
    )

    select * from relationDnis a1
    where @isSuperUser=1 or a1.Inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@UserId, 2))
    order by 3,4

    return(0)
 end

if @Tipo = 3 -- Agrega Dnis
 begin
    if not exists(select dni_numero from ccDnis where dni_Status=1 and dni_numero like @Dnis)
     begin
        insert into ccDnis (dni_id, dni_numero, dni_tpoMaxEspera, tipodni_id, dni_Descripcion, dni_tipo)
        select isNull(max(dni_id), 0) + 1, @Dnis , 0, 1, @dni_description, 2 from ccDnis
        select top(1) dni_id from ccDNIS order by dni_id desc
        return(0)
     end
     
    select cast(-1 as smallint)
 end

if @Tipo = 4 -- Elimina Dnis
 begin
    delete from ccInboundDnis where inbound_id = @Inbound_Id and dni_id = @dni_id
    
    select ci.inbound_id, cd.dni_id, ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock
    from ccInbound ci , ccDNIS cd
    where ci.Inbound_id=@Inbound_id and dni_id=@dni_id
 end

if @Tipo = 5 -- Agrega Relacion
 begin
    insert into ccInboundDnis (Inbound_id, dni_id)
    select @Inbound_Id,B.Value from  dbo.fn_RIASplitDelimited (@dnis_Ids, '','') B
    left join ccInboundDnis A on A.dni_id=B.Value 
    where  A.dni_id is null

    select cast(@Inbound_Id as smallint) inbound_id,cast(B.Value as smallint) dni_id, 
    ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock        
    ,case when cid.Inbound_id is null then 0 else 1 end isAssigned
    from  dbo.fn_RIASplitDelimited (@dnis_Ids, '','') B
    left join ccInboundDnis cid on cid.dni_id=B.Value and cid.Inbound_id=@Inbound_Id
    left join ccInbound ci on ci.inbound_id = @Inbound_Id
    inner join ccDnis cd on cd.dni_id = B.Value
    order by 3,4
 end

if @Tipo = 6 -- Elimina Dnis sin pedir inbound_id
 begin
    if exists(select dni_id from ccInboundDnis where dni_id in (select value from dbo.fn_RIASplitDelimited (@dnis_Ids, '','')) and isnull(inbound_id, 0) <> 0)
        select -1

    else begin
        update ccDNIS set dni_Status=0 where dni_id in (select value from dbo.fn_RIASplitDelimited (@dnis_Ids, '',''))--= @dni_id -- delete from ccdnis where dni_id = @dni_id
        select 1
    end
 end

if @tipo = 7
 begin
    if @Dnis = (select dni_numero from ccDNIS where dni_id=@dni_id) begin
        update ccDnis set 
        dni_Descripcion=isnull(@dni_description,dni_Descripcion)
        where dni_id = @dni_id 
        
        select 1
        return(0)
    end

    if not exists(select dni_numero from ccDnis where dni_Status=1 and dni_numero like @Dnis) begin
        update ccDnis set 
        dni_numero=case when @Dnis <> ''0'' then @Dnis else dni_numero end,
        dni_Descripcion=isnull(@dni_description,dni_Descripcion),
        dni_isBlock = isnull(@dni_isBlock,dni_isBlock)
        where dni_id = @dni_id 

        select 1
        --select dni_id,dni_numero as dni_number, dni_Descripcion as dni_Descriptiondni_id, dni_isBlock from ccDNIS where dni_id=@
        return(0)
    end
    
    select -1
 end

set nocount off'
    EXEC(@sql)

set @process = 'DEV1-81 Alter SP ccsp_GalateaAdminCampaigns Correcion Option=10 para tomar encuneta salida y entrada'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS      SMALLINT, 
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
    IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                        BEGIN
                            SELECT CAST(IdCampEsp AS INT) AS Id
                            FROM ccRIACampEspWG
                            WHERE IDWG = @WorkgroupId
                                  AND Tipo = 1
                                   ORDER BY IdCampEsp ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe una lista de campañas de salida con el id de grupo de trabajo especificado'', 18, 1);
                    END;
            END;
            IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @WorkgroupId IS NOT NULL
                        BEGIN
                            SELECT CAST(IdCampEsp AS INT) AS Id
                            FROM ccRIACampEspWG
                            WHERE IDWG = @WorkgroupId
                                  AND Tipo = 0
                                   ORDER BY IdCampEsp ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe una lista de campañas de entrada con el id de grupo de trabajo especificado'', 18, 1);
                    END;
            END;
            RETURN 0;
    END;
    IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            SELECT DISTINCT 
                                   CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area,  
                                        CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType
                            FROM ccCamps camps
                                 LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
                                 LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
                            WHERE camps.cam_id = @Id
                                   ORDER BY camps.cam_descripcion ASC;
                    END;
                    ELSE
                        BEGIN
                            RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
                    END;
            END;
            IF @CampType = 0 -- Campaigns In (ACD)
                BEGIN
                    IF @Id IS NOT NULL
                        BEGIN
                            SELECT DISTINCT 
                                   CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType
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
    IF @Option = 3   -- Update OverallTotalNew By Campaign
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    UPDATE ccCampsNvosCB
                      SET 
                          OverallTotalNew = ccCampsNvosCB.new
                    WHERE id = @Id;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 4   -- Update Pin from Campaign per Admin
        BEGIN
            IF @Id IS NOT NULL
               AND @AdminId IS NOT NULL
                BEGIN
                    IF @PinUpdate = 1
                        BEGIN
                            INSERT INTO PinedCampaigns(CampId, AdminId, Type)
                        VALUES(@Id, @AdminId, @Type);
                    END;
                    IF @PinUpdate = 0
                        BEGIN
                            DELETE FROM PinedCampaigns
                            WHERE CampId = @Id
                                  AND AdminId = @AdminId
                                  AND Type = @Type;
                    END;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. La campañas o administrador no existen'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 5   -- Get Pin from Campaign Ids per Admin
        BEGIN
            IF @AdminId IS NOT NULL
                BEGIN
                    SELECT CampId AS Id
                    FROM PinedCampaigns
                    WHERE AdminId = @AdminId
                          AND Type = @Type
                           ORDER BY Id ASC;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 6   -- Get Blacklist Ids by Campaign Id
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    DECLARE @BlackListIds VARCHAR(MAX);
                    SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
                    FROM Camplistanegra
                    WHERE cam_id = @Id
                          AND STATUS = 1;
                    SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 7   -- Get RegistryListIds Ids by Campaign Id
        BEGIN
            IF(@Id IS NOT NULL
               AND EXISTS
            (
                SELECT *
                FROM cccamps
                WHERE cam_id = @Id
            ))
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
                    RAISERROR(''ERROR. No existe una campa?a con el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @Option = 8   -- Delete RegistryListIds Ids by LoadId
        BEGIN
            IF(@LoadId IS NOT NULL
               AND EXISTS
            (
                SELECT *
                FROM ccRIARegistryLists
                WHERE list_id = @loadID
                      AND STATUS <> 0
            ))
                BEGIN
                    UPDATE ccoCallsOutSource
                      SET 
                          cal_status = ''5''
                    WHERE list_id = @loadID;
                    DELETE FROM ccoWorkingTable
                    WHERE list_id = @LoadId;
                    EXEC ccsp_RIARegistryLists 
                         @action = 6, 
                         @list_id = @LoadId;
            END;
            ELSE
                BEGIN
                    --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
                    RAISERROR(''ERROR. No existe una carga el id especificado'', 18, 1);
            END;
            RETURN 0;
    END;
    IF @option = 9   -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
        BEGIN
            DECLARE @table TABLE
            (camId    INT, 
             campType TINYINT, 
             PRIMARY KEY(camId, campType)
            );
            INSERT INTO @table
                   SELECT DISTINCT 
                          IdCampEsp, Tipo
                   FROM ccRIACampEspWG wg
                   WHERE wg.IDWG IN
                   (
                       SELECT IDWG
                       FROM ccRIAWorkGroupUsers
                       WHERE IDWG <> @WorkgroupId
                             AND User_id = @AdminId
                   );
            SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
            FROM @table A
                 RIGHT JOIN
            (
                SELECT wg.IdCampEsp, wg.Tipo
                FROM ccRIACampEspWG wg
                WHERE wg.IDWG = @WorkgroupId
            ) B ON A.camId = B.IdCampEsp
                   AND A.campType = B.Tipo
            WHERE A.camId IS NULL
                   ORDER BY IdCampEsp;
            RETURN 0;
    END;
    IF @option = 10  -- Get Agents States with totals per campaign by admin id and campaign type
    BEGIN
  DECLARE @date DATETIME= CONVERT(DATE, DATEADD(hh, -3, GETDATE()));
  DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY(id));
  DECLARE @AgentsList TABLE(id INT, PRIMARY KEY(id));
  DECLARE @tmpCamAgent TABLE(camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY(camId, userId));
  DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT);
  DECLARE @CurrentStatus TABLE(userId INT, CurrentState INT, IdCampEsp INT, camType INT);
  DECLARE @campDataTotal TABLE(camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY(camId));

  INSERT INTO @AdminWorkgroups SELECT DISTINCT IDWG
  FROM ccRIAWorkGroupUsers WG, 
     ccUsers_Roles R
  WHERE WG.User_id = @AdminId
  OR (R.User_id = @AdminId
  AND R.Rol_id = 7);
        
  INSERT INTO @AgentsList SELECT DISTINCT A.User_id
  FROM ccRIAWorkGroupUsers A
  INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
  INNER JOIN ccUsers C ON A.User_id = C.User_id 
  AND C.TipoUser_id = 1
    ORDER BY A.User_id;


    

  INSERT INTO @tmpCamAgent 
  SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id,
  CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
  FROM ccRIACampEspWG campPerWg
  INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
  INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
  INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
  left JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp and @CampType = 0
  left JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp and @CampType = 1
  where C.TipoUser_id = 1
  AND campPerWg.Tipo = @CampType
  AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
  
  WITH lastState AS (
  SELECT A.user_id, MAX(A.fecha) AS fecha
  FROM ccLogAgentesDia A
  INNER JOIN @AgentsList B ON A.User_id = B.id
  WHERE fecha >= @date
  GROUP BY user_id)

    INSERT INTO @CurrentStatus 
  SELECT B.User_id,
  CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS currentStatus,
  B.IdCampEsp,
  B.Tipo
  FROM lastState A
  INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
  AND A.fecha = B.fecha;

  IF @Id = 0 AND @CampType = 0 
  BEGIN
    DELETE FROM @tmpCamAgent WHERE multimediaType = 5
  END

  DECLARE @MultimediaType SMALLINT = (SELECT CASE WHEN @CampType = 1 THEN -1 ELSE meanContactTypeId END
                    FROM contactMeanIn WHERE inboundId = @Id)

  DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes

  INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
  (CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = @CampType
   THEN @CampType ELSE null END) AS isCampDialog 
  FROM @tmpCamAgent A
  INNER JOIN @CurrentStatus B ON A.userId = B.userId
  WHERE (@Id = 0 or A.camId = @Id)

  IF @CampType = 1
    BEGIN
    ;with  campDataTotal as(
      select camId,count(*) total from @tmpCamAgent A group by camId
    )

    insert into @campDataTotal
    select 
      A.camId,
      B.cam_descripcion as campName 
      ,A.Total
      ,C.AreaName as Area
      from campDataTotal A
      INNER JOIN ccCamps B ON A.camId= B.cam_id 
      INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END
  ELSE
    BEGIN    
    ;with  campDataTotal as(
      select camId,count(*) total from @tmpCamAgent A group by camId
    )

    insert into @campDataTotal
    select 
      A.camId,
      B.descripcion as campName 
      ,A.Total
      ,C.AreaName as Area
      from campDataTotal A
        INNER JOIN ccInbound B ON A.camId = B.Inbound_id 
      INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END 


  ;WITH stateCamp AS(
    SELECT A.CampId,
    count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready,
    count(CASE WHEN A.CurrentState NOT IN(-2, -1, 0, 3, 4, 5, 6, 9, 30, 34) THEN 1 
           WHEN A.CurrentState IN (6, 34) AND A.CampId != C.IdCampEsp THEN 1 ELSE NULL END) AS notReady,
    COUNT(isCampDialog) AS dialog,
    COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected 
    FROM @AgentStatus A
    INNER JOIN @CurrentStatus C ON A.userId = C.userId
    GROUP BY A.CampId
  )

  SELECT 
    A.camId,
    A.campName,
    A.Total,
      ISNULL(B.ready, 0) AS Ready,
    ISNULL(B.notReady, 0 ) AS NotReady, 
    ISNULL(B.dialog, 0) AS Dialog,
    CASE WHEN B.disconnected IS NULL THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END Disconnected,
    A.Area
  FROM @campDataTotal A
  LEFT JOIN stateCamp B ON A.camId = B.CampId
  ORDER BY A.campName

        RETURN 0;
    END;
    IF @Option = 11  -- Get Campaigns Ids List Per Workgroup and Campaign Type
        BEGIN                
            IF Not EXISTS
            (
                SELECT *
                FROM ccUsers_Roles NOLOCK
                WHERE User_id = @AdminId
                      AND Rol_id = 7
            )
                BEGIN
        print ''xxxx SIn Super''
                    ;WITH wgId
                         AS (SELECT IDWG
                             FROM ccRIAWorkGroupUsers NOLOCK
                             WHERE user_id = @AdminId)
                         SELECT DISTINCT 
                                CAST(IdCampEsp AS INT) AS Id
                         FROM ccRIACampEspWG A (NOLOCK)
                              INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                 AND A.Tipo = @CampType;
            END;
            ELSE
                BEGIN
      --print ''xxxx Super''
      IF @CampType = 1
        BEGIN
          SELECT DISTINCT 
               CAST(cam_id AS INT) AS Id
                        FROM ccCamps (NOLOCK) where IDArea IS NOT NULL
        END
      ELSE
        BEGIN 
          SELECT DISTINCT 
               CAST(Inbound_id AS INT) AS Id
                        FROM ccInbound (NOLOCK) where IDArea IS NOT NULL
        END
            END;
            RETURN 0;
    END;
    IF @Option = 12  -- Get All Campaigns complete information per Campaign Type and Campaign Id
        BEGIN
            IF @CampType = 1 -- Campaigns Out
                BEGIN
                    SELECT DISTINCT 
                           CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type, camps.cam_procesando IsStarted, a.AreaName AS Area,  
                           CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType
                    FROM ccCamps camps (NOLOCK)
                         INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
                         INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
                           --WHERE camps.cam_id = @Id
                           ORDER BY camps.cam_descripcion ASC;
            END;
            ELSE
                BEGIN
                    SELECT DISTINCT 
                           CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType
                    FROM ccInbound inb (NOLOCK)
                         INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
                         INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = inb.IDArea
                           ORDER BY inb.descripcion ASC;
            END;
            RETURN 0;
    END;
    IF @Option = 13
    BEGIN
        BEGIN                
            IF NOT EXISTS
            (
                SELECT *
                FROM ccUsers_Roles NOLOCK
                WHERE User_id = @AdminId
                        AND Rol_id = 7
            )
                BEGIN
                    IF @CampType = 1
                        BEGIN
                            WITH wgId
                                AS (SELECT IDWG
                                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT 
                                    CAST(IdCampEsp AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,CAST(-1 AS INT) AS RelatedCampId
                                FROM ccRIACampEspWG A
                                    INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                        AND A.Tipo = 1
                                    INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id;
                        END
                    ELSE
                        BEGIN
                            WITH wgId
                                AS (SELECT IDWG
                                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT 
                                    CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                                FROM ccRIACampEspWG A (NOLOCK)
                                    INNER JOIN wgId ON wgId.IDWG = A.IDWG
                                                        AND A.Tipo = 0
                                    INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id 
                                    AND ((@multi_type is null AND cci.chat = @InboundType)
                                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
                        END
            END;
            ELSE
                BEGIN
                IF @CampType = 1
                    BEGIN
                        SELECT DISTINCT 
                                CAST(cam_id AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,-1 AS RelatedCampId
                        FROM ccCamps NOLOCK where IDArea = @AreaId
                    END
                ELSE
                    BEGIN 
                        SELECT DISTINCT 
                                CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                        FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
                        AND ((@multi_type is null AND cci.chat = @InboundType)
                            OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

                    END
            END;
            RETURN 0;
        END;
    END;

    IF @Option = 14
        BEGIN
            IF NOT EXISTS
            (
                    SELECT *
                    FROM ccUsers_Roles NOLOCK
                    WHERE User_id = @AdminId
                            AND Rol_id = 7
            )
                BEGIN
                    WITH wgId
                            AS (SELECT IDWG
                                FROM ccRIAWorkGroupUsers NOLOCK
                                WHERE user_id = @AdminId)
                            SELECT DISTINCT 
                                CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                            FROM ccRIACampEspWG A (NOLOCK)
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
    IF @Option = 15
        BEGIN
            SELECT DISTINCT 
            CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
            FROM ccInbound NOLOCK where cam_id = @Id
        END
END;
        '
    EXEC(@sql)    

set @process = 'ccsp_CreateNodeMultimedia(DEV1-91) @type = 1 tConversation salia en cero'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_CreateNodeMultimedia] @conversationId BIGINT
                            , @supervisor     VARCHAR(255) = ''''
                            , @template       VARCHAR(255) = ''''
                            , @ScoreTemplate  INT          = 0
                            , @type           INT                                                
AS
BEGIN

    DECLARE @xml XML, @dateStart DATETIME;
    DECLARE @info VARCHAR(255);
    DECLARE @infoEscape VARCHAR(MAX);
    DECLARE @charEscape VARCHAR(255), @charReplace VARCHAR(MAX);
    SET @charEscape = ''"|''''''''|<|>|&'';
    SET @charReplace = ''&quot;|&apos;|&lt;|&gt;|&amp;'';

    DECLARE @existAttached BIT, @numInteracion SMALLINT;
    IF @type = 1
    BEGIN--CHAT
        SELECT @xml = CONVERT(XML, ''<R01 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126))) 
            + ''" CID="'' + CONVERT(VARCHAR(MAX), ccRIAChats.inboundid) 
        + ''" CType="1'' 
        + ''" C01="'' + CONVERT(VARCHAR(MAX), chatId) 
        + ''" C02="'' + CONVERT(VARCHAR(MAX), ISNULL(ccinbound.descripcion, '''')) 
        + ''" C03="'' + CONVERT(VARCHAR(MAX), domain) 
        + ''" C04="'' + CONVERT(VARCHAR(MAX), ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'')) 
        + ''" C05="'' + CONVERT(VARCHAR(MAX), tchatting) 
        + ''" C06="'' + CONVERT(VARCHAR(MAX), ISNULL(cctipocalif.[Description], ''N/A'')) 
        + ''" C07="'' + CONVERT(VARCHAR(MAX), ISNULL(cctipocalifsub.califSubdesc, ''N/A'')) 
        + ''" C08="'' + CONVERT(VARCHAR(MAX), clientname) 
        + ''" C09="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126))) 
        + ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
        + ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
        + ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
        + ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(ccusers.[Login], '''')) 
        + ''"/>'')
             , @dateStart = ISNULL(chatDate, requestDate) FROM ccRIAChats
                                                               LEFT OUTER JOIN ccinbound ON ccinbound.inbound_id = ccRIAChats.inboundid
                                                               LEFT OUTER JOIN ccusers ON ccusers.user_id = ccRIAChats.userid
                                                               LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = ccRIAChats.disposition
                                                               LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = ccRIAChats.subdisposition
                                                                                                 AND ccRIAChats.subdisposition <> 0
        WHERE chatId = @conversationId
              AND chatStatus = 4              

    END;
    ELSE
        IF @type = 3
        BEGIN--EMAIL
            SELECT @existAttached = CASE WHEN COUNT(*) > 0
                                    THEN 1 ELSE 0
                                    END FROM attached
            WHERE messageId IN(SELECT messageId FROM message WHERE conversationId = @conversationId);
            SELECT @numInteracion = COUNT(*) FROM message WHERE conversationId = @conversationId;
            --Replaza los caracteres por los comunes
            SELECT @info = info FROM conversation WHERE conversationId = @conversationId;
            SELECT @info = replace(@info, A.Value, B.Value) FROM dbo.fn_RIASplitDelimited(@charEscape, ''|'') A
                                                                 INNER JOIN dbo.fn_RIASplitDelimited(@charReplace, ''|'') B ON A.Id = B.Id;

            SELECT @xml = CONVERT(XML, ''<R03 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126))) 
                + ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid) 
            + ''" CType="1'' 
            + ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationId) 
            + ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126))) 
            + ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion)) 
            + ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''''))) 
            + ''" C05="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalif.[Description], ''N/A''))) 
            + ''" C06="'' + CONVERT(VARCHAR, MAX(replace(replace(a.mailClient, ''<'', '' ''), ''>'', '' ''))) 
            + ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup)) 
            + ''" C08="'' + CONVERT(VARCHAR(MAX), MIN(ISNULL(@info, ''''))) 
            + ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid)) 
            + ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0)) 
            + ''" C11="'' + CONVERT(VARCHAR(MAX), @existAttached) 
            + ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
            + ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
            + ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
            + ''" C15="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalifsub.califSubdesc, ''N/A''))) 
            + ''" C16="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), '''')) 
            + ''"/>'')
                 , @dateStart = ISNULL(MAX(b.tsend), GETDATE()) FROM conversation a
                                                                     INNER JOIN message b ON a.conversationid = b.conversationid
                                                                     LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
                                                                     LEFT OUTER JOIN ccusers d ON d.user_id = b.userid
                                                                     LEFT OUTER JOIN relationmessageDisposition e ON e.messageId = b.messageId
                                                                     LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = e.dispositionId
                                                                     LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = e.subdispositionId
                                                                                                       AND e.subdispositionId <> 0
            WHERE a.conversationId = @conversationId
            GROUP BY a.conversationId
                   , a.inboundid;

        END;
        ELSE
            IF @type = 4
            BEGIN--Twitter
                SELECT @numInteracion = SUM(ninteration) FROM messageOutTwitter
                WHERE conversationTwitterId = @conversationId;

                SELECT @xml = CONVERT(XML, ''<R04 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), MIN(b.date), 126))) 
                    + ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid) 
                + ''" CType="1'' 
                + ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationTwitterId) 
                + ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), MIN(b.date), 126))) 
                + ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion)) 
                + ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''''))) 
                + ''" C05="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalif.[Description], ''N/A''))) 
                + ''" C06="'' + MAX(a.screenNameClient) 
                + ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup)) 
                + ''" C08="'' + MAX(a.screenNameInbound) 
                + ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid)) 
                + ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0)) 
                + ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
                + ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
                + ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
                + ''" C14="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalifsub.califSubdesc, ''N/A''))) 
                + ''" C15="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), '''')) 
                + ''"/>'')
                     , @dateStart = ISNULL(MIN(b.date), GETDATE()) FROM conversationTwitter a
                                                                        INNER JOIN messageOutTwitter b ON a.conversationTwitterId = b.conversationTwitterId
                                                                        LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
                                                                        LEFT OUTER JOIN ccusers d ON d.user_id = b.userid
                                                                        LEFT OUTER JOIN relationMessageDispositionTwit e ON e.messageOutTwitterId = b.messageOutTwitterId
                                                                        LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = e.dispositionId
                                                                        LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = e.subdispositionId
                                                                                                          AND e.subdispositionId <> 0
                WHERE a.conversationTwitterId = @conversationId
                GROUP BY a.conversationTwitterId
                       , a.inboundid;
            END;
            ELSE
                IF @type = 5
                BEGIN --WhatsApp
                    SELECT @xml = CONVERT(XML, ''<R05 CDATE="'' + CONVERT(VARCHAR(23), ISNULL(conversationDate, requestDate), 126) 
                        + ''" CID="'' + CONVERT(VARCHAR(MAX), A.inboundid) 
                    + ''" CType="5'' 
                    + ''" C01="'' + CONVERT(VARCHAR(MAX), A.conversationId) 
                    + ''" C02="'' + ISNULL(inbound.descripcion, '''') 
                    + ''" C03="'' + ISNULL(ccusers.[Login], '''') 
                    + ''" C04="'' + ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'') 
                    + ''" C05="'' + clientId 
                    + ''" C06="'' + CONVERT(VARCHAR(MAX), tConversation) 
                    + ''" C07="'' + ISNULL(cctipocalif.[Description], ''N/A'') 
                    + ''" C08="'' + ISNULL(cctipocalifsub.califSubdesc, ''N/A'') 
                    + ''" C09="'' + CONVERT(VARCHAR(MAX), A.agentId) 
                    + ''" C10="'' + phoneACD 
                    + ''" C11="'' + CONVERT(VARCHAR(MAX), A.agentId) 
                    + ''" C12="'' + ISNULL(@supervisor, '''') 
                    + ''" C13="'' + ISNULL(@template, '''') 
                    + ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
                    + ''"/>'')
                         , @dateStart = ISNULL(conversationDate, requestDate) FROM ccWhatsAppConversations A
                                                                                   LEFT OUTER JOIN ccinbound inbound ON inbound.inbound_id = A.inboundid
                                                                                   LEFT OUTER JOIN ccusers ON ccusers.user_id = A.agentId
                                                                                   LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
                                                                                   LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
                    WHERE A.conversationId = @conversationId;

                END;

    DECLARE @sql NVARCHAR(MAX), @tableName NVARCHAR(MAX), @columnId NVARCHAR(MAX), @tableNameHistory NVARCHAR(MAX);
    DECLARE @parameterDefinition NVARCHAR(MAX);

    SELECT @tableName = tableName
         , @tableNameHistory = tableNameHistory
         , @columnId = columnId FROM ccFinderServices
    WHERE id = @type;

    SET @parameterDefinition = N''@conversationId bigint,@xml xml,@dateStart datetime'';

    IF @xml IS NOT NULL
    BEGIN        

        SET @sql = ''IF EXISTS(SELECT * FROM '' + @tableNameHistory + '' WHERE ''+@columnId+'' = @conversationId)
        BEGIN
            UPDATE '' + @tableNameHistory + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
        END
        else IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
        BEGIN
            UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
        END
        else begin
            INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, 0);
        end     
        '';
        
    END
    else begin
         SET @sql ='' IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
        BEGIN
            UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = -1 WHERE ''+@columnId+'' = @conversationId;
        END
        else begin
            INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, -1);
        end '';
    end

     EXECUTE sp_executesql
                @sql
              , @parameterDefinition
              , @conversationId = @conversationId
              , @xml = @xml
              , @dateStart = @dateStart;

END;'
    EXEC(@sql)

    set @process = 'SPEC-72 -- Alter SP configuraIdiomaCatalogosPortugues'
    	set @Sql= 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosPortugues]
AS
Print ''Iniciando proceso de configuracion en Portugues''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Semana'', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Noite'', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Sabado'', 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Domingo'', 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady] 
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Não Clasified'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Pausa'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Casa de banho'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Com o cliente'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Supervisor'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Esclarecimento'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Reunião'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Almoço'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Sistemas'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Outros '')

--EXEC sp_generate_inserts ''ccRIANotReadyGraph''
DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
TRUNCATE TABLE [dbo].[ccStatusLLamada]
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, ''Inicial'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Fora da agenda'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Fora de serviço'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''Não há agentes conectados'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''Em espera'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandonado'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Tempo de transbordo'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Tamanho da fila de transbordo'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''Com Mensagem'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10,''Mensagem atribuída'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11,''Atribuído'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12,''Mensagem compareceram'')
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [dbo].[ccTipoDias]
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (1, ''segunda-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (2, ''terça-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (3, ''quarta-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (4, ''quinta-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (5, ''sexta-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (6, ''sábado'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (7, ''domingo'')

Print ''Estableciendo resultados de marcacion''
TRUNCATE TABLE [dbo].[ccTipoResultadoDial]
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Resposta'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Ocupado'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Não resposta'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax / Modem'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Outros'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10,''NOservice'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11,''Correio de Voz/Máquina'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12,''Circuito ocupado'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13,''Cancelado'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (90, ''Rejeitada pela operadora'')

Print ''Estableciendo los tipos de estado de los agentes''
DELETE [dbo].[ccTipoStatusAgente]
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, ''LogOut'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, ''Desconhecido'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, ''Not Ready'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, ''Pronto'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, ''Conversando'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, ''Transferência'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, ''Wrapup'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, ''Outros'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, ''Cliente'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, ''Tocando'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11,''Problema'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21,''Espere por chamada manualmente'')

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, ''Agente'')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, ''Supervisor'')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, ''Acesso AVRS'')

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
SET IDENTITY_INSERT [dbo].[ccDias] ON
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (1, ''domingo'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (2, ''segunda-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (3, ''terça-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (4, ''quarta-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (5, ''quinta-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (6, ''sexta-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (7, ''sábado'')
SET IDENTITY_INSERT [dbo].[ccDias] OFF

truncate table cstoTarifa

Print ''Estableciendo los tipos de llamada''
delete cstoTipoLlamada

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''National LD'',''12'',''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Mobile'',''13'',''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''LD Mobile'',''13'',''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''USA LD'',''13'',''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''Inter LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''2-digit Local Area Code'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''3-digit Local Area Code'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''4-digit Local Area Code'',''6'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''2-digit Local Mobile Area Code'',''10'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''3-digit Local Mobile Area Code'',''9'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''4-digit Local Mobile Area Code'',''8'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Long Distance'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Long Distance Mobile'',''13'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Mobile'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''National LD'',''11'',''1%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''National LD'',''10'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Mobile'',''11'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Mobile'',''11'',''07%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''Inter LD'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''Old LD'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Mobile'',''10'',''05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''New LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''Inter LD'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''Inter LD'',''0'',''0011%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Mobile'',''10'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Mobile '',''8'',''6%|7%|8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''9-digit Mobile'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''National LD'',''10'',''02%|03%|04%|05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''National Mobile LD'',''10'',''06%|07%|08%|09%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''9-digit National Mobile LD'',''11'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''International LD'',''19'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Mobile'',''8'',''3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''National LD'',''8'',''7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''International LD'',''8'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''SIP Telephony'',''8'',''4%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Mobile Telephony'',''8'',''5%|6%|7%|8%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Reverse Charge'',''10'',''800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Premium Rate'',''10'',''90%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Internet Access'',''10'',''900%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Special'',''0'',''08%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Landline'',''8'',''2%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Mobile'',''8'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Mobile'',''9'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Webservices'',''9'',''5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''National LD'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Mobile'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''Inter LD'',''0'',''00%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] ON
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Adicionado à lista negra'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Bloqueado no carregamento'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Removido da campanha'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Substituído da lista negra'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Excluído da lista negra'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Adicionado por Disposição'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, ''Carregar lista negra'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, ''Carga cliente lista negra'')
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, ''Peça informações Geral'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, ''Chame hung'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, ''Wrong Number'', 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, ''Chamada eficaz'' , 0, 0, 1)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, ''Deixe um recado '', 0, 1, 2)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, ''Wrong Number'', 0, 1, 3)

--Pendiente validar rpoveedores portugal
--Print ''Estableciendo proveedores''
--Delete [dbo].[cstoProvedor]
--DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
--INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Carrier 1'')

Print ''Tipo Msg ChatLog'' -- No se hace delete ni truncate ya que se perderia la integridad si ya hay registros, los id ya deberian estar creados por lo cual se genera el update
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrador escreve única mensagem para um agente'' where TipoMsgChat=1
Update ccRIAChat_TipoMsg set MsgDetalle=''Agente escreve uma mensagem para o Administrador'' where TipoMsgChat=2
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrador escreve uma mensagem global'' where TipoMsgChat=3

Print ''Mensajes defualt''
DELETE [dbo].[ccMsgFiles]
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default5'', ''Mensagem de boas vindas'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default4'', ''Mensagem de transferência'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default3'', ''Mensagem de falta de serviço'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default2'', ''Depois de horas de mensagens'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default1'', ''Na fila de mensagens'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default7'', ''Nenhum agente assinado em mensagem'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default9'', ''Mensagem de voz'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default10'', ''Mensagem de Overflow'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default11'', ''Lista DNC'')

Print ''Mensajes default chat''
DELETE [dbo].[ccRIAChatInboundMsgs]
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default5'', ''Bem-vindo!'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default3'', ''Serviço está disponível no momento'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default2'', ''Nosso horário de serviço terminou'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default1'', ''Por favor aguarde enquanto um dos nossos agentes está disponível'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default7'', ''Há agentes não disponíveis'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default10'', ''Sua solicitação não pode ser processada'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default12'', ''Sessão de chat foi-inativo por muito tempo'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default13'', ''Sessão de chat terminou'')'
    	EXEC(@Sql)   

------------------------- END Capacitacion ---------------------------------------------------------
	 

	set @process = 'TT2904 -adminKolob -No se muestran agentes ccsp_GalateaLoadUsersForManagement 
	-- AND DATEDIFF(dd, LastLoginAttempt, getdate()) < 60'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]
 @option SMALLINT,
 @AreaId SMALLINT,
 @UserType INT,
 @Username VARCHAR(200)=null,
 @userId INT =0
as

--Obtiene el idioma de de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

IF @option = 1 --Agentes/supervisores de un Area
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE isnull(IDArea, 0) = isnull(@AreaId, 0) AND TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS = 1
	AND DATEDIFF(dd, LastLoginAttempt, getdate()) < 60
  ORDER BY LOGIN, Nombres, ApellidoPaterno,Sexo, User_id

  RETURN (0)
END

IF @option = 2 -- obtiene Agente o supervisor en base a su nombre de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE Login=@Username

  RETURN (0)
END

IF @option = 3 -- obtiene Agente o supervisor en base a su ID de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE user_id=@userId

  RETURN (0)
END


IF @option = 4 -- supervisores en Area/Sistema
BEGIN
	DECLARE @Admins TABLE (UserId smallint, Username varchar(50), Names varchar(50), LastName varchar(50), OptionalExtraName varchar(50), AreaId smallint, primary key(UserId))
	INSERT INTO @Admins
	SELECT User_id as UserId,
	LOGIN as Username,
	Nombres as Names,
	CASE
	  WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
	  ELSE isnull(ApellidoPaterno, '''')
	END as LastName,

	CASE
	  WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
	  ELSE isnull(ApellidoMaterno, '''')
	END as OptionalExtraName,

	isnull(IDArea, 0) as AreaId
	FROM ccusers
	WHERE TipoUser_id = 2 AND STATUS = 1


	IF NOT EXISTS(SELECT * FROM ccUsers_Roles WHERE User_id=@userId and Rol_id=7) BEGIN
		SELECT UserId, Username, Names, LastName, OptionalExtraName
		FROM @Admins
		WHERE AreaId = (SELECT IDArea FROM ccUsers WHERE User_id=@userId)
		ORDER BY Username, Names, LastName, UserId
	END
	ELSE BEGIN
		SELECT UserId, Username, Names, LastName, OptionalExtraName
		FROM @Admins
		ORDER BY Username, Names, LastName, UserId
	END

  RETURN (0)
END'
 	EXEC(@sql)    




		SET @process = 'TT2571 drop ccsp_IVRAfterXferAge'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_IVRAfterXferAge'')
		begin
			DROP PROCEDURE ccsp_IVRAfterXferAge;
		end'
		EXEC(@sql)

		SET @process = 'TT2571 create ccsp_IVRAfterXferAge'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_IVRAfterXferAge]
		@cal_id int,
		@User_id smallint,
		@cal_extension varchar(7),
		@tWait smallint
		AS
		set nocount on
		Update ccCallsIn SET 
			user_id= case when user_id=0 and @User_id>0 then @User_id else user_id end, 
			cal_extension= case when len(cal_extension)=0 and len(@cal_extension)>0 then @cal_extension else cal_extension end,
			cal_xfer=getdate(), statusCall_id=11  -- 11=Assigned
		where cal_id=@cal_id

		update ccRIAWorkGroup_Calid set user_id=@User_id where cal_id = @cal_id and tipo = 0

		return(0)
		set nocount off'
		EXEC(@sql)

		SET @process = 'TT2571 drop ccsp_IVRUpdateCallEndNew'
		SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_IVRUpdateCallEndNew'')
		begin
			DROP PROCEDURE ccsp_IVRUpdateCallEndNew;
		end'
		EXEC(@sql)

		SET @process = 'TT2571 create ccsp_IVRUpdateCallEndNew'
		SET @sql = 'CREATE procEDURE [dbo].[ccsp_IVRUpdateCallEndNew]
		@cal_id int,
		@cal_tIVRCallDuration smallint,
		@statuscal_id tinyint, 
		@cal_opciones varchar(10),
		@cal_colgada tinyint,
		@User_id smallint,
		@cal_extension varchar(7),
		@tWait smallint,
		@cbPhone varchar(20)
		AS
		set nocount on

		Update ccCallsIn SET statusCall_id = case when @statuscal_id in (2, 3, 4, 7, 8) then @statuscal_id else case when statusCall_id = 5 then 6 else statuscall_id end end, 
		 user_id= case when user_id=0 and @User_id>0 then @User_id else user_id end, 
		 cal_extension= case when len(cal_extension)=0 and len(@cal_extension)>0 then @cal_extension else cal_extension end, 
		 cal_tWait=@tWait where cal_id=@cal_id

		exec ccsp_RIAUpdateCallBack_Abandon @cal_id, @statuscal_id, @cbPhone
		exec ccsp_EngineLogTransfers 2, @cal_id, 2, 2, null, @tWait, @cal_tIVRCallDuration

		set nocount off'
		EXEC(@sql)

			----------------------------- BEGIN TT3147 - AdminKolob - Error al cargar registros Marco Garcia -------------------------------------------------

		SET @process = 'TT3147 - AdminKolob - Error al cargar registros delete function Verifica2'
		SET @sql = ' IF EXISTS (SELECT * FROM   sys.objects WHERE  object_id = OBJECT_ID(N''[dbo].[Verifica2]'')
						  AND type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
			BEGIN
				DROP FUNCTION [dbo].[Verifica2];
			END';
		EXEC(@sql);

		SET @process = 'TT3147 - AdminKolob - Error al cargar registros create function Verifica2'
		SET @sql = '
		CREATE FUNCTION [dbo].[Verifica2] (@tel VARCHAR(32), @pais TINYINT = 0, @cldLocal VARCHAR(7) = '''')
		RETURNS VARCHAR(32)
		AS
		BEGIN
			DECLARE @ld VARCHAR(7)
			DECLARE @lon TINYINT
			DECLARE @result TINYINT
			DECLARE @mod VARCHAR(10)
			DECLARE @Cadena VARCHAR(32)
			DECLARE @isLocal BIT
			declare @serie varchar(10)

			IF (@pais = 0 AND @cldLocal = '''')
			BEGIN
				SELECT @pais = valor
				FROM ccSettings WITH (NOLOCK)
				WHERE setting_id = 104

				SELECT @cldLocal = valor
				FROM ccSettings WITH (NOLOCK)
				WHERE setting_id = 17
			END

			SELECT @tel = dbo.limpia(@tel)

			IF @pais = 1
			BEGIN --Empieza Mexico
				SELECT @lon = len(@tel), @mod = ''''

				IF @lon < 10
				BEGIN
					RETURN ''E_'' + @tel
				END

				SELECT @tel = right(@tel, 10)

				SELECT @lon = len(@tel)

				IF @lon = 10
				BEGIN
					IF EXISTS (
							SELECT TOP 1 cld
							FROM series NOLOCK
							WHERE cld = left(@tel, 3)
							and serie=SUBSTRING(@tel,4,3)
							)
						SELECT @ld = left(@tel, 3),@serie=SUBSTRING(@tel,4,3)
					ELSE IF EXISTS (
							SELECT TOP 1 cld
							FROM series NOLOCK
							WHERE cld = left(@tel, 2)
							and serie=SUBSTRING(@tel,3,4)
							)
						SELECT @ld = left(@tel, 2),@serie=SUBSTRING(@tel,3,4)
					ELSE
						RETURN ''E_'' + @tel

					SELECT TOP 1 @mod = modalidad
					FROM series NOLOCK
					WHERE cld = @ld AND serie = @serie AND right(@tel, 4) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

					IF @mod NOT IN (''FIJO'', ''MPP'', ''CPP'')
					BEGIN
						RETURN ''E_'' + @tel
					END

					DECLARE @specialDialPlan TINYINT

					SELECT @specialDialPlan = valor
					FROM ccsettings WITH (NOLOCK)
					WHERE setting_id = 195

					IF @specialDialPlan = 2
					BEGIN --Number 10 digits
						RETURN @tel
					END

					SET @isLocal = 0

					IF EXISTS (
							SELECT *
							FROM ccRiaArecode
							WHERE area = @ld
							)
					BEGIN
						SET @isLocal = 1
					END
					ELSE IF @cldLocal = @ld
					BEGIN
						SET @isLocal = 1
					END

					IF @specialDialPlan = 1
					BEGIN
						--Number local 10 digit
						--Number LD 12 digit
						--Number Cell 13 digit
						SELECT @tel = CASE WHEN @mod IN (''FIJO'', ''MPP'') THEN CASE WHEN @isLocal = 1 THEN @tel ELSE ''01'' + @tel END WHEN @mod = ''CPP'' THEN --Local y LD
										CASE WHEN @isLocal = 1 THEN ''044'' + @tel ELSE ''045'' + @tel END END --Celular
					END
					ELSE
					BEGIN
						--Number local 7 o 8 digit
						--Number LD 12 digit
						--Number Cell 13 digit
						SELECT @tel = CASE WHEN @mod IN (''FIJO'', ''MPP'') THEN CASE WHEN @isLocal = 1 THEN right(@tel, 10 - len(@ld)) ELSE ''01'' + @tel END WHEN @mod = ''CPP'' THEN --Local y LD
										CASE WHEN @isLocal = 1 THEN ''044'' + @tel ELSE ''045'' + @tel END END --Celular
					END
				END
				ELSE IF @lon > 0
				BEGIN
					SET @tel = ''E_'' + @tel
				END

				RETURN @tel
			END --Termina Mexico
					--------------------------- Empieza Argentina ---------------------------
			ELSE IF @pais = 2
			BEGIN
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) = ''E''
				BEGIN
					RETURN @tel
				END

				SELECT @lon = len(@tel)

				IF @lon IN (6, 7, 8) AND left(@tel, 2) <> ''15''
				BEGIN
					SET @tel = @cldLocal + @tel
				END

				IF @lon IN (8, 9, 10) AND left(@tel, 2) = ''15''
				BEGIN
					SET @tel = @cldLocal + substring(@tel, 3, @lon - 2)
				END

				--Buscamos el 15
				IF @lon = 13
				BEGIN
					DECLARE @index AS INT

					SELECT @index = charindex(''15'', @tel)

					--El unico caso en el que la lada tiene un 15 es con lada 3715
					IF @index < 2
					BEGIN
						SELECT @tel = ''E_'' + @tel

						RETURN @tel
					END
					ELSE
					BEGIN
						IF substring(@tel, @index - 2, 4) = ''3715''
						BEGIN
							SELECT @ld = ''3715''

							SET @tel = @ld + right(@tel, 6)
						END
						ELSE
						BEGIN
							SELECT @ld = substring(@tel, 2, @index - 2)

							SET @tel = @ld + right(@tel, 13 - (@index + 1))
						END
					END
				END

				SELECT @tel = right(@tel, 10)

				IF len(@tel) = 10
				BEGIN			

					BEGIN
						-- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
						DECLARE @contLD AS INT
						DECLARE @cont AS INT

						SET @contLD = 4

						BuscaLada:

						IF isnull(@ld, '''') = '''' AND @contLD >= 2
						BEGIN
							SELECT @ld = cld
							FROM seriesArg
							WHERE cld = left(@tel, @contLD)

							IF isnull(@ld, '''') = ''''
							BEGIN
								SET @contLD = @contLD - 1

								GOTO BuscaLada
							END
						END
						ELSE
						BEGIN
							IF isnull(@ld, '''') = ''''
							BEGIN
								SELECT @tel = ''E_'' + @tel
							END
						END
					END

					-- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
					BEGIN
						IF len(@ld) = 2
						BEGIN
							SET @cont = 5

							buscaSerie2:

							IF isnull(@serie, '''') = '''' AND @cont >= 4
							BEGIN
								SELECT @serie = serie
								FROM seriesArg
								WHERE cld = @ld AND serie = substring(@tel, 3, @cont)

								IF isnull(@serie, '''') = ''''
								BEGIN
									SET @cont = @cont - 1

									GOTO buscaSerie2
								END
							END
						END
						ELSE
						BEGIN
							IF len(@ld) = 3
							BEGIN
								SET @cont = 4

								buscaSerie3:

								IF isnull(@serie, '''') = '''' AND @cont >= 3
								BEGIN
									SELECT @serie = serie
									FROM seriesArg
									WHERE cld = @ld AND serie = substring(@tel, 4, @cont)

									IF isnull(@serie, '''') = ''''
									BEGIN
										SET @cont = @cont - 1

										GOTO buscaSerie3
									END
								END
							END
							ELSE
							BEGIN
								IF len(@ld) = 4
								BEGIN
									SET @cont = 3

									buscaSerie4:

									IF isnull(@serie, '''') = '''' AND @cont >= 2
									BEGIN
										SELECT @serie = serie
										FROM seriesArg
										WHERE cld = @ld AND serie = substring(@tel, 5, @cont)

										IF isnull(@serie, '''') = ''''
										BEGIN
											SET @cont = @cont - 1

											GOTO buscaSerie4
										END
									END
								END
							END
						END
					END

					SELECT @mod = modalidad
					FROM seriesArg
					WHERE cld = @ld AND serie = @serie AND right(@tel, 10 - len(@ld) - len(@serie)) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

					-- Si la serie es nula, existe una posibilidad de que la lada este mal, asi que se quita un numero de la lada y se vuelve a buscar la serie			
					IF isNull(@serie, '''') = '''' AND @contLD > 1
					BEGIN
						SET @contLD = len(@ld) - 1
						SET @ld = NULL

						GOTO BuscaLada
					END

					SELECT @tel = CASE WHEN @mod IN (''BASICA'', ''MPP'') THEN CASE WHEN @ld = @cldLocal THEN right(@tel, 10 - len(@ld)) ELSE ''0'' + @tel END WHEN @mod = ''CPP'' THEN CASE WHEN @ld = @cldLocal THEN ''15'' + right(@tel, 10 - len(@ld)) ELSE ''0'' + @ld + ''15'' + right(@tel, 10 - len(@ld)) END ELSE ''E_'' + @tel END
				END
				ELSE
				BEGIN
					IF len(@tel) > 0
					BEGIN
						SELECT @tel = ''E_'' + @tel
					END
				END

				RETURN @tel
			END ------------------ Termina Argentina ------------------
			ELSE IF @pais = 3
			BEGIN --Empieza Colombia
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) = ''E''
				BEGIN
					RETURN @tel
				END

				IF len(@tel) NOT IN (7, 8, 10, 11)
				BEGIN
					RETURN ''E_'' + @tel
				END

				IF len(@tel) = 7
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesCol
							WHERE serie = left(@tel, 4) AND @cldLocal = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END

				IF len(@tel) = 8
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesCol
							WHERE serie = substring(@tel, 2, 4) AND left(@tel, 1) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END

				IF len(@tel) = 10
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesCol
							WHERE serie = substring(@tel, 5, 3) AND (left(@tel, 3) + ''-'' + substring(@tel, 4, 1)) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END

				IF len(@tel) = 11
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesCol
							WHERE serie = substring(@tel, 6, 3) AND (substring(@tel, 2, 3) + ''-'' + substring(@tel, 5, 1)) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END
			END --Termina Colombia

			-- Empieza Chile
			IF @pais = 5
			BEGIN
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) = ''E''
				BEGIN
					RETURN @tel
				END

				IF len(@tel) = 6 AND len(@cldLocal) = 2
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesChi
							WHERE cld = @cldLocal AND left(@tel, 3) = serie AND right(@tel, 3) BETWEEN numeracioninicial AND numeracionFinal
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END

				IF len(@tel) = 7
				BEGIN
					IF @cldLocal IN (2, 41, 44, 32)
					BEGIN
						IF EXISTS (
								SELECT serie
								FROM serieschi
								WHERE serie = left(@tel, 4)
								)
						BEGIN
							RETURN @tel
						END
						ELSE
						BEGIN
							IF left(@tel, 3) = ''200'' AND EXISTS (
									SELECT serie
									FROM serieschi
									WHERE serie = left(@tel, 3)
									)
							BEGIN
								RETURN @tel
							END
						END
					END
				END

				IF len(@tel) = 8
				BEGIN
					IF left(@tel, 1) = ''2''
					BEGIN
						IF EXISTS (
								SELECT serie
								FROM serieschi
								WHERE serie = substring(@tel, 2, 4)
								)
						BEGIN
							RETURN @tel
						END
						ELSE
						BEGIN
							IF EXISTS (
									SELECT serie
									FROM serieschi
									WHERE serie = substring(@tel, 2, 5)
									)
							BEGIN
								RETURN @tel
							END
							ELSE
							BEGIN
								RETURN ''E_'' + @tel
							END
						END
					END
					ELSE
					BEGIN
						RETURN @tel
					END
				END

				IF len(@tel) = 10
				BEGIN
					IF left(@tel, 2) = ''09''
					BEGIN
						IF EXISTS (
								SELECT serie
								FROM serieschi
								WHERE cld = substring(@tel, 3, 1) AND serie = substring(@tel, 5, 3)
								)
						BEGIN
							RETURN @tel
						END
						ELSE
						BEGIN
							RETURN ''E_'' + @tel
						END
					END
				END
			END

			--Termina Chile
			IF @pais = 6
			BEGIN --Empieza Venezuela
				SELECT @lon = len(@tel)

				IF @lon = 7
				BEGIN
					SET @tel = @cldLocal + @tel
				END

				SELECT @tel = right(@tel, 10)

				IF len(@tel) = 10
				BEGIN
					SELECT @ld = left(@tel, 3)

					SELECT @mod = tipo
					FROM seriesVen
					WHERE left(@tel, 3) = LD

					IF @mod = ''CPP''
					BEGIN
						IF EXISTS (
								SELECT *
								FROM seriesVen
								WHERE LD = @ld
								)
						BEGIN
							IF @ld = @cldLocal
							BEGIN
								SELECT @tel = right(@tel, 7)
							END
							ELSE
							BEGIN
								SELECT @tel = ''0'' + @tel
							END
						END
						ELSE
						BEGIN
							SELECT @tel = ''E_'' + @tel
						END
					END
					ELSE
					BEGIN
						IF @mod = ''FIJO''
						BEGIN
							IF EXISTS (
									SELECT serie
									FROM seriesVen
									WHERE serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) AND right(@tel, 4) BETWEEN [Inicio] AND [Fin]
									)
							BEGIN
								IF @ld = @cldLocal
								BEGIN
									SELECT @tel = right(@tel, 7)
								END
								ELSE
								BEGIN
									SELECT @tel = ''0'' + @tel
								END
							END
							ELSE
							BEGIN
								SELECT @tel = ''E_'' + @tel
							END
						END
						ELSE
						BEGIN
							SELECT @tel = ''E_'' + @tel
						END
					END
				END
				ELSE
				BEGIN
					IF len(@tel) > 0
					BEGIN
						SELECT @tel = ''E_'' + @tel
					END
				END

				RETURN @tel
			END --Termina Venezuela

			IF @pais = 7
			BEGIN -- Empieza UK
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) = ''E''
				BEGIN -- regresa error por longitud
					RETURN @tel
				END

				SELECT @lon = len(@tel)

				--numeros no geograficos
				IF (left(@tel, 2) IN (''03'', ''07'', ''09'') AND @lon <> 11) OR (left(@tel, 3) IN (''055'', ''056'', ''070'') AND @lon <> 11)
				BEGIN
					RETURN ''E_'' + @tel --error por longitud con lada correcta
				END
				ELSE
				BEGIN
					IF left(@tel, 7) IN (''0845464'') OR left(@tel, 5) = ''07624'' OR left(@tel, 4) IN (''0500'', ''0800'') OR left(@tel, 3) IN (''055'', ''056'', ''070'', ''76'') OR left(@tel, 2) IN (''03'', ''07'', ''08'', ''09'')
					BEGIN
						RETURN @tel;--longitud correcta y numero no geografico
					END
				END

				--numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
				IF (left(@tel, 7) IN (''0159575'', ''0159576'')) OR (left(@tel, 5) IN (''02820'', ''02821'', ''02825'', ''02827'', ''02828'', ''02829'', ''02830'', ''02837'', ''02838'', ''02840'', ''02841'', ''02842'', ''02843'', ''02844'', ''02866'', ''02867'', ''02868'', ''02870'', ''02871'', ''02877'', ''02879'', ''02880'', ''02881'', ''02882'', ''02885'', ''02886'', ''02887'', ''02889'', ''02890'', ''02891'', ''02892'', ''02893'', ''02894'', ''02895'', ''02897'') AND @lon = 11) OR --claves 2xxx tienen formato 4-6
					(left(@tel, 4) IN (''0113'', ''0114'', ''0115'', ''0116'', ''0117'', ''0118'', ''0121'', ''0131'', ''0141'', ''0151'', ''0161'', ''0238'', ''0239'') AND @lon = 11) OR --3-digit area codes have 7-digit subscribers.
					(left(@tel, 3) IN (''020'', ''024'', ''029'') AND @lon = 11)
				BEGIN --2-digit area codes have 8-digit subscribers.
					RETURN @tel;
				END

				--numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
				IF left(@tel, 2) = ''01''
				BEGIN
					SELECT @ld = count(cld)
					FROM seriesuk
					WHERE cld = substring(@tel, 2, 4) --mayor numero de ladas (va primero por ser mas probable)

					IF @ld > 0
					BEGIN
						RETURN @tel;
					END
					ELSE
					BEGIN
						SELECT @ld = count(cld)
						FROM seriesuk
						WHERE cld = substring(@tel, 2, 5) --ladas restantes

						IF @ld > 0
						BEGIN
							RETURN @tel;
						END
					END
				END --si no encontro ni error ni coincidencia entonces esta mal

				RETURN ''E_'' + @tel
			END --Termina UK

			IF @pais = 8
			BEGIN --Empieza Arabia Saudita
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				SELECT @lon = len(@tel)

				IF @lon = 7
				BEGIN
					SET @tel = ''0'' + @cldLocal + @tel
				END

				SELECT @lon = len(@tel)

				IF @lon = 9
				BEGIN
					IF EXISTS (
							SELECT regiones
							FROM seriesSA
							WHERE right(@tel, 4) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 3, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 4 AND left(@tel, 2) = cld
							)
					BEGIN
						IF (substring(@tel, 2, 1) = @cldLocal)
						BEGIN
							RETURN right(@tel, 7)
						END
						ELSE
						BEGIN
							RETURN @tel
						END
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END

				IF @lon = 10
				BEGIN
					IF EXISTS (
							SELECT regiones
							FROM seriesSA
							WHERE right(@tel, 4) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 4, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 4 AND left(@tel, 3) = cld
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END

				IF @lon = 11
				BEGIN
					IF EXISTS (
							SELECT regiones, *
							FROM seriesSA
							WHERE right(@tel, 6) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 3, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 6 AND left(@tel, 2) = cld
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END
			END --Termina Arabia Saudita

			IF @pais = 9
			BEGIN --Empieza Australia
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				SELECT @lon = len(@tel)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF EXISTS (
							SELECT Regiones
							FROM SeriesAU
							WHERE convert(INT, LD) = convert(INT, substring(@tel, 1, 2)) AND convert(INT, AreaCode) = convert(INT, substring(@tel, 3, 2)) AND convert(INT, substring(@tel, 5, 6)) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END
				ELSE
				BEGIN
					RETURN @tel
				END
			END --Termina Australia

			IF @pais = 10
			BEGIN -- Inicia Brasil
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				SELECT @lon = len(@tel)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF @lon IN (8, 9)
					BEGIN --numero local
						IF EXISTS (
								SELECT Regiones
								FROM seriesBR
								WHERE convert(INT, AreaCode) = convert(INT, @cldLocal) AND convert(INT, @tel) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
								)
						BEGIN
							RETURN @tel
						END
						ELSE
						BEGIN
							RETURN ''E_'' + @tel
						END
					END

					IF @lon IN (10, 11)
					BEGIN --numero nacional
						IF EXISTS (
								SELECT Regiones
								FROM seriesBR
								WHERE convert(INT, AreaCode) = convert(INT, left(@tel, 2)) AND convert(INT, right(@tel, @lon - 2)) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
								)
						BEGIN
							RETURN @tel
						END
						ELSE
						BEGIN
							RETURN ''E_'' + @tel
						END
					END
				END
				ELSE
				BEGIN
					RETURN @tel
				END
			END -- Termina Brasil

			IF @pais = 11
			BEGIN -- Inicia Guatemala
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF EXISTS (
							SELECT zonaGeografica
							FROM seriesGT(NOLOCK)
							WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
							)
						RETURN @tel
					ELSE
						RETURN ''E_'' + @tel
				END
				ELSE
					RETURN @tel
			END -- Termina Guatemala

			IF @pais = 12
			BEGIN -- Inicia Costa Rica
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF len(@tel) = 8
						IF EXISTS (
								SELECT zonaGeografica
								FROM seriesCR(NOLOCK)
								WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
								)
							RETURN @tel
						ELSE
							RETURN ''E_'' + @tel
					ELSE IF len(@tel) = 10
					BEGIN
						IF EXISTS (
								SELECT zonaGeografica
								FROM seriesCR(NOLOCK)
								WHERE indicativoDestino = substring(@tel, 1, 3) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
								)
							RETURN @tel
						ELSE
							RETURN ''E_'' + @tel
					END
					ELSE IF charindex(substring(@tel, 1, 2), ''00,08'') <= 0
						RETURN ''E_'' + @tel
					ELSE
						RETURN @tel
				END
			END -- Termina Costa Rica

			IF @pais = 13
			BEGIN -- Inicia Salvador
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF len(@tel) = 8
						IF EXISTS (
								SELECT zonaGeografica
								FROM seriesSV(NOLOCK)
								WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
								)
							RETURN @tel
						ELSE
							RETURN ''E_'' + @tel
					ELSE IF charindex(substring(@tel, 1, 2), ''00'') <= 0
						RETURN ''E_'' + @tel
					ELSE
						RETURN @tel
				END
			END -- Termina Salvador

			IF @pais = 14
			BEGIN -- Inicia Spain
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF len(@tel) = 9
						IF EXISTS (
								SELECT provincia
								FROM seriesEsp(NOLOCK)
								WHERE indicativo = substring(@tel, 1, 1) AND right(@tel, 8) BETWEEN numInicial AND numFinal
								)
							RETURN @tel
						ELSE
							RETURN ''E_'' + @tel
					ELSE IF charindex(substring(@tel, 1, 2), ''00'') <= 0
						RETURN ''E_'' + @tel
					ELSE
						RETURN @tel
				END
			END -- Termina Espa?a

			IF @pais = 15
			BEGIN --Inicia Peru
				SELECT @tel = dbo.Completa(@tel, @pais, @cldLocal)

				SELECT @lon = len(@tel)

				IF @lon BETWEEN 6 AND 7
				BEGIN
					SET @tel = @cldLocal + @tel
				END

				SELECT @tel = right(@tel, 9)

				SELECT @lon = len(@tel)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF @lon = 9
					BEGIN
						IF EXISTS (
								SELECT zonaGeografica
								FROM seriesPE(NOLOCK)
								WHERE left(@tel, 1) = 9 OR substring(@tel, 2, 1) = 1 AND areaNumeracion = 1 AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal OR substring(@tel, 2, 1) <> 1 AND left(@tel, 2) = areaNumeracion AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
								)
							RETURN @tel
						ELSE
							RETURN ''E_'' + @tel
					END
				END
			END --Termina Peru

			IF @pais = 16
			BEGIN --Panama
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF len(@tel) = 7
					BEGIN -- Local
						IF (substring(@tel, 1, 1) != ''6'')
						BEGIN
							IF EXISTS (
									SELECT zonaGeografica
									FROM seriesPa(NOLOCK)
									WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
									)
								RETURN @tel
							ELSE
								RETURN ''E_'' + @tel
						END
						ELSE
							RETURN ''E_'' + @tel
					END

					IF len(@tel) = 8
					BEGIN --Celular
						IF (substring(@tel, 1, 1) = ''6'')
						BEGIN
							IF EXISTS (
									SELECT zonaGeografica
									FROM seriesPa(NOLOCK)
									WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
									)
								RETURN @tel
							ELSE
								RETURN ''E_'' + @tel
						END
						ELSE
							RETURN ''E_'' + @tel
					END
					ELSE
					BEGIN
						IF charindex(substring(@tel, 1, 2), ''00'') <= 0
							RETURN ''E_'' + @tel
						ELSE
							RETURN @tel
					END
				END
			END

			RETURN @tel
		END
		';

		EXEC(@sql);

		----------------------------- END TT3147 - AdminKolob - Error al cargar registros Marco Garcia -------------------------------------------------


	 		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
