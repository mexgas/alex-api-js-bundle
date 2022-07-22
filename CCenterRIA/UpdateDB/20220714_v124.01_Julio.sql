/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/02/15
Description: Merge con los cambios de sorteos

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
			select @time=cal_tDialog from ccoCallsOut with(nolock) where cal_id=@callId and file_moved is null
		end
		else 
		begin
			select @time=cal_tDialog from ccCallsIn with(nolock) where cal_id=@callId and file_moved is null 
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

	 		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
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
