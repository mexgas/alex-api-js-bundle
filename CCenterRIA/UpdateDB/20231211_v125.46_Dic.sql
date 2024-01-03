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

	    -----------------------------------------------------BEGIN K042023-Indicador de creditos Ivan Martin ----------------------------------------------------------------

        SET @process = 'K042023 Se crea setting 258 para creditos globales de SMS'
        SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 258)
                    BEGIN
                        INSERT INTO ccSettings2(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
                        VALUES(258, ''0'', ''Contador global de créditos para campañas SMS'', 1, ''ADM'', ''Contador global de créditos para campañas SMS'',
                                         ''SMS Campaigns credits global counter'',0,''.*'') 
                    END'
        EXEC(@sql);

        -----------------------------------------------------END K042023-Indicador de creditos Ivan Martin ----------------------------------------------------------------

        	    -----------------------------------------------------BEGIN fix JCL ----------------------------------------------------------------

        SET @process = 'fix historial de cambios identifier Idioma'
        SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''T&SET_TOOLSTRANSFER'')
                    BEGIN
                        insert into ccGalateaIdentifiers(Description,TagEs,TagEn,TagPt)
                        values(''T&SET_TOOLSTRANSFER'', ''Mostrar datos del contacto y controles de llamada en transferencias'', ''Show contact’s data and call controls on transfers'', ''Exibir dados do contato e controles de chamada em transferências'')          
                    END'
        EXEC(@sql);

        SET @process = 'fix historial de cambios relacion identifier'
        SET @sql = 'IF NOT EXISTS(SELECT 1 FROM relationTableColumnIdentifiers WHERE Identifiers = ''T&SET_TOOLSTRANSFER'')
                    BEGIN
                        insert into relationTableColumnIdentifiers(Identifiers,tableName,colunName)
                        values(''T&SET_TOOLSTRANSFER'', ''ccRIACat_Areas'', ''ToolsTransfer'')
                    END'
        EXEC(@sql);

        SET @process = 'fix historial de cambios tipo de dato'
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

        -----------------------------------------------------END fix JCL ----------------------------------------------------------------

		-----------------------------------------------------INICIO MACL-----------------------------------------------------------------
		SET @process = 'CW-8197 Actualiza SP ccsp_RIADNCList'
        SET @sql = '
		ALTER PROCEDURE [dbo].[ccsp_RIADNCList] @phoneNumber AS VARCHAR(30) = NULL, @idDNCList AS INTEGER, @tipoMov AS TINYINT, @calKey AS VARCHAR(40) = NULL
AS
DECLARE @hashCalKey bigint, @hashPhone BIGINT

IF @calKey IS NOT NULL
BEGIN
	SELECT @hashCalKey = dbo.hashList(@calKey)
END

IF @tipoMov = 1
BEGIN -- Inserta Lista Negra	
	EXEC ccsp_InsertDNCList @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null
	EXEC ccsp_InsertDNCListSms @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null
	
END

IF @tipoMov = 2
BEGIN -- Borra Lista Negra	
	SELECT @hashPhone = dbo.hashPhone(@phoneNumber)

	IF @hashCalKey IS NULL
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idDNCList
	END
	ELSE
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idDNCList
	END

	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	VALUES (@phoneNumber, 5, @idDNCList)
END

IF @tipoMov = 3
BEGIN -- Reemplaza Lista Negra
	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	SELECT telefono, ''4'', @idDNCList
	FROM cclistanegra
	WHERE idtipolista = @idDNCList

	DELETE
	FROM cclistanegra
	WHERE idtipolista = @idDNCList
END '
        EXEC(@sql);

		SET @process = 'CW-8197 Actualiza SP ccsp_InsertDNCList'
        SET @sql = '
		ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30)=null,
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL
WITH RECOMPILE
AS

PRINT(@ln_id)
declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)
,@tel10 as varchar(30),@tel11 as varchar(30), @sqlcmd varchar(max), @tmpTableName varchar(40), @sqlcmd_replace varchar(max),
@dropTmpPhone varchar(max) = null

SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));

if (@telephone is not null) -- Para insertar un solo numero cuando se manda a BL por calificación
BEGIN
	IF EXISTS (SELECT * from ccListaNegra where idtipolista = @ln_id and telefono = @telephone and HashKey = dbo.hashList(@calKey))
		RETURN 0;

	IF @calKey = ''''
		SET @calKey = ''''''''''''
	ELSE
		SET @calKey = '''''''' + @calKey + ''''''''

	set @tmpTableName = ''TMP_BLACKLIST_'' + @telephone;
	SET @dropTmpPhone = ''if exists (select * from sys.tables where name = N'''''' + @tmpTableName + '''''') drop table '' + @tmpTableName;

	SET @sqlcmd = ''CREATE TABLE '' + @tmpTableName + ''(
	[phoneNumber] VARCHAR(30),
	[calKey] VARCHAR(40)); 

	INSERT INTO '' + @tmpTableName + ''(phoneNumber, calKey) values(''+ @telephone +'', '' + ISNULL(@calKey, ''NULL'') + '');
	'';
	EXEC (@dropTmpPhone);
	EXEC (@sqlcmd);
END


select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

SET @sqlcmd =  ''
UPDATE '' + @tmpTableName + '' SET phoneNumber = dbo.completa(phoneNumber, '' + @pais + '',  '' + @ld + '');
DELETE '' + @tmpTableName + '' WHERE phoneNumber like ''''%E%'''';

INSERT INTO cclistanegra(telefono,idtipolista,HashKey, calKey)
SELECT phoneNumber, '' + CAST(@ln_id as varchar(10)) + '' as idtipolista, dbo.hashList(calKey) as HashKey, calkey 
FROM '' + @tmpTableName + '';

INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
SELECT phoneNumber as telefono, 7 as idtipomov, '' + CAST(@ln_id as varchar(10)) + '' as idtipolista 
FROM '' + @tmpTableName + '';''
EXEC(@sqlcmd);

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall


CREATE TABLE [dbo].[#mycamps] (	[campsid] [int] NULL)

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id and B.CampType not in(7,5)


CREATE TABLE [dbo].[#myprincipaltempCall](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE CLUSTERED INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltempCall]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltempCall]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltempCall]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltempCall]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltempCall]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltempCall]([cal_telefono5]) 

CREATE TABLE [dbo].[#helpTempCall](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE TABLE [dbo].[#mytempCall](
	[callout_id] [int] NULL, 
	[telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempCall]([callout_id]) 

declare @fech datetime = getdate()-30
	SET @sqlcmd = ''
	insert into [#helpTempCall]
	SELECT a.callout_id as callout_id, a.cam_id,3, '' +  CAST(@ln_id as varchar(10))+ ''  as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
	FROM [ccoCallsOutSource] as a with(nolock)
	inner join #mycamps as b  on a.cam_id = b.campsid
	inner join '' + @tmpTableName +'' t on 
	t.phoneNumber IN ([SPACE_TEL]) 	AND t.calKey IS NULL
	where  cal_fechadial > getdate()-30
	''

	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono'')
	exec (@sqlcmd_replace)
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono2'')
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono3'')
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono4'')
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono5'')
	EXEC(@sqlcmd_replace)


	SET @sqlcmd = ''insert into [#helpTempCall]
	SELECT a.callout_id as callout_id, a.cam_id,3, '' +  CAST(@ln_id as varchar(10))+ ''  as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
	FROM [ccoCallsOutSource] as a with(nolock)
	inner join #mycamps as b  on a.cam_id = b.campsid
	inner join '' + @tmpTableName +'' t on a.cal_Key=t.calKey
	where cal_fechadial > getdate()-30;
	'';
	print( @sqlcmd)
	EXEC(@sqlcmd)

	INSERT INTO #myprincipaltempCall
	SELECT * FROM #helpTempCall
	GROUP BY callout_id, cam_id, tipomov, idtipolista, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5

if EXISTS (select * from #myprincipaltempCall)
begin
	declare @column nvarchar(max), @sql nvarchar(max)
	,@sqlDeleteWorking nvarchar(max)
	,@sqlUpdateWorking nvarchar(max)
	,@sqlCaseWorking nvarchar(max)
	,@params nvarchar(max)
	,@phoneEmpty varchar(1)
	,@sqlWithReplace nvarchar(max)

	set @phoneEmpty=''''
	set @column=''cal_telefono''
	set @params=''@phoneEmpty varchar(1),@fech datetime''
	set @sqlDeleteWorking=''and cs.cal_telefono2=@phoneEmpty
	and cs.cal_telefono3=@phoneEmpty
	and cs.cal_telefono4=@phoneEmpty
	and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono2<>@phoneEmpty then cs.cal_telefono2 
	when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
	when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
	when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
	else @phoneEmpty end ''

	set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
	update wt 
	set cal_telefono = CASE_UPDATE_WT
	from ccoCallsOutSource cs 
	inner join ccoWOrkingTable wt on cs.callout_id = wt.callout_id
	inner join #mytempCall t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > @fech and cs.COLUMN_CHECK= wt.cal_telefono''

	set @sql=''
insert #mytempCall
select callout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempCall] as a with(nolock)
inner join '' + @tmpTableName + '' t on
t.phoneNumber = COLUMN_CHECK
where COLUMN_CHECK<>@phoneEmpty


if EXISTS (select * from #mytempCall)
begin		
	-- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
	delete wt with(rowlock)
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytempCall t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > @fech and
	cs.COLUMN_CHECK = wt.cal_telefono
	AND_DELETE_WT

	UPDATE_SMS_WT_QUERY

	--insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytempCall where [telefono]<>@phoneEmpty

	-- Eliminamos el telefono1 de CS
	update ccoCallsOutSource 
	set COLUMN_CHECK = @phoneEmpty
	from ccoCallsOutSource cs 
	inner join #mytempCall t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > @fech		

	truncate table #mytempCall
end''

	
	/******************/
	/*** Telefono 1 ***/
	/******************/
	
	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	print(@sqlWithReplace)	
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	

	/******************/
	/*** Telefono 2 ***/
	/******************/
	set @column=''cal_telefono2''
	
	set @sqlDeleteWorking='' and cs.cal_telefono3=@phoneEmpty
		and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
		when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	

	/******************/
	/*** Telefono 3 ***/
	/******************/
	set @column=''cal_telefono3''
	
	set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	
	
	/******************/
	/*** Telefono 4 ***/
	/******************/	
	
	set @column=''cal_telefono4''
	
	set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	
	
	/******************/
	/*** Telefono 5 ***/
	/******************/

	set @column=''cal_telefono5''	
	set @sqlDeleteWorking='' and cs.cal_telefono5=@phoneEmpty''	
	set @sqlCaseWorking=''''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',''''),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	

end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall
IF @dropTmpPhone IS NOT NULL EXEC (@dropTmpPhone);'
        EXEC(@sql);

		SET @process = 'CW-8197 Actualiza SP ccsp_InsertDNCListSms'
        SET @sql = '
		ALTER PROCEDURE [dbo].[ccsp_InsertDNCListSms]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL

AS
SET NOCOUNT ON;  


declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)
,@tel10 as varchar(30),@tel11 as varchar(30), @sqlcmd varchar(max), @tmpTableName varchar(40), @sqlcmd_replace varchar(max),
@dropTmpPhone varchar(max) = null

SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempSms'') IS NOT NULL drop table #myprincipaltempSms
IF OBJECT_ID(N''tempdb..#mytempSms'') IS NOT NULL drop table #mytempSms
IF OBJECT_ID(N''tempdb..#helpTempSms]'') IS NOT NULL drop table #helpTempSms


CREATE TABLE [dbo].[#mycamps] ([campsid] [int] NULL	)

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id And B.CampType=7



CREATE TABLE [dbo].[#myprincipaltempSms](
	[smsout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[sms_phoneNumber] [varchar] (15) NULL ,
	[sms_phoneNumber2] [varchar] (15) NULL ,
	[sms_phoneNumber3] [varchar] (15) NULL ,
	[sms_phoneNumber4] [varchar] (15) NULL ,
	[sms_phoneNumber5] [varchar] (15) NULL
	)

CREATE CLUSTERED INDEX [IX_myprincipaltempSms] ON [dbo].[#myprincipaltempSms]([smsout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms2] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms3] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms4] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms5] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms6] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber5])

CREATE TABLE [dbo].[#helpTempSms](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE TABLE [dbo].[#mytempSms](
	[smsout_id] [int] NULL, 
	[telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempSms]([smsout_id]) 

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

declare @fech datetime = getdate()-30

	SET @sqlcmd = ''
	insert into [#helpTempSms]
	SELECT a.smsout_id as smsout_id, a.cam_id,3, '' +  CAST(@ln_id as varchar(10))+ ''  as idtipolista ,  a.sms_phoneNumber , a.sms_phoneNumber2, a.sms_phoneNumber3, a.sms_phoneNumber4, a.sms_phoneNumber5 
	FROM [smsOutSource] as a 
	inner join #mycamps as b with(nolock) on a.cam_id = b.campsid
	inner join '' + @tmpTableName +'' t on 
	t.phoneNumber IN ([SPACE_TEL]) 	AND t.calKey IS NULL
	where  sms_dateDial > getdate()-30
	''

	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber'')
	exec (@sqlcmd_replace)
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber2'')
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber3'')
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber4'')
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber5'')
	EXEC(@sqlcmd_replace)


	SET @sqlcmd = ''insert into [#helpTempSms]
	SELECT a.smsout_id as smsout_id, a.cam_id,3, '' +  CAST(@ln_id as varchar(10))+ ''  as idtipolista ,  a.sms_phoneNumber , a.sms_phoneNumber2, a.sms_phoneNumber3, a.sms_phoneNumber4, a.sms_phoneNumber5 
	FROM [smsOutSource] as a
	inner join #mycamps as b with(nolock) on a.cam_id = b.campsid
	inner join '' + @tmpTableName +'' t on a.callKey=t.calKey
	where sms_dateDial > getdate()-30;
	'';
	print( @sqlcmd)
	EXEC(@sqlcmd)

	INSERT INTO #myprincipaltempSms
	SELECT * FROM #helpTempSms
	GROUP BY callout_id, cam_id, tipomov, idtipolista, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5
	
if EXISTS (select * from #myprincipaltempSms)
	begin
	
	declare @column nvarchar(max), @sql nvarchar(max)
	,@sqlDeleteWorking nvarchar(max)
	,@sqlUpdateWorking nvarchar(max)
	,@sqlCaseWorking nvarchar(max)
	,@params nvarchar(max)
	,@phoneEmpty varchar(1)
	,@sqlWithReplace nvarchar(max)

	set @phoneEmpty=''''
	set @column=''sms_phoneNumber''
	set @params=''@phoneEmpty varchar(1),@fech datetime''
	set @sqlDeleteWorking=''and cs.sms_phoneNumber2=@phoneEmpty
	and cs.sms_phoneNumber3=@phoneEmpty
	and cs.sms_phoneNumber4=@phoneEmpty
	and cs.sms_phoneNumber5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.sms_phoneNumber2<>@phoneEmpty then cs.sms_phoneNumber2 
	when cs.sms_phoneNumber3<>@phoneEmpty then cs.sms_phoneNumber3 
	when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
	when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
	else @phoneEmpty end ''

	set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
	update wt 
	set sms_phoneNumber = CASE_UPDATE_WT
	from smsOutSource cs 
	inner join smsWorkingTable wt on cs.smsout_id = wt.smsout_id
	inner join #mytempSms t on cs.smsout_id = t.smsout_id
	where cs.sms_dateDial > @fech and cs.COLUMN_CHECK= wt.sms_phoneNumber''

	set @sql=''insert #mytempSms
select smsout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempSms] with(nolock)
inner join '' + @tmpTableName + '' t on
t.phoneNumber = COLUMN_CHECK
where COLUMN_CHECK<>@phoneEmpty

if EXISTS (select * from #mytempSms)
begin
	-- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
	delete wt with(rowlock)
	from smsWorkingTable wt 
	inner join smsOutSource cs on wt.smsout_id = cs.smsout_id
	inner join #mytempSms t on wt.smsout_id = t.smsout_id
	where cs.sms_dateDial > @fech and
	cs.COLUMN_CHECK = wt.sms_phoneNumber
	AND_DELETE_WT

	UPDATE_SMS_WT_QUERY

	--insertar el historial
	insert ccHistoryBlacklistSms (smsout_id,Phone,cam_id,movTypeId,listTypeId)
	select * from #mytempSms

	-- Eliminamos el telefono1 de CS
	update smsOutSource 
	set COLUMN_CHECK = @phoneEmpty
	from smsOutSource cs 
	inner join #mytempSms t on cs.smsout_id = t.smsout_id
	where cs.sms_dateDial > @fech		

	truncate table #mytempSms
end''
	/******************/
	/*** Telefono 1 ***/
	/******************/
	
	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech	

	/******************/
	/*** Telefono 2 ***/
	/******************/
	set @column=''sms_phoneNumber2''
	
	set @sqlDeleteWorking='' and cs.sms_phoneNumber3=@phoneEmpty
		and cs.sms_phoneNumber4=@phoneEmpty
		and cs.sms_phoneNumber5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.sms_phoneNumber3<>@phoneEmpty then cs.sms_phoneNumber3 
		when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
		when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech

	/******************/
	/*** Telefono 3 ***/
	/******************/
	set @column=''sms_phoneNumber3''
	
	set @sqlDeleteWorking='' and cs.sms_phoneNumber4=@phoneEmpty
		and cs.sms_phoneNumber5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
		when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech	

	/******************/
	/*** Telefono 4 ***/
	/******************/	
	
	set @column=''sms_phoneNumber4''
	
	set @sqlDeleteWorking='' and cs.sms_phoneNumber4=@phoneEmpty
		and cs.sms_phoneNumber5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
		when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech
		

	/******************/
	/*** Telefono 5 ***/
	/******************/

	set @column=''sms_phoneNumber5''	
	set @sqlDeleteWorking='' and cs.sms_phoneNumber5=@phoneEmpty''	
	set @sqlCaseWorking=''''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',''''),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech
	
end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempSms'') IS NOT NULL drop table #myprincipaltempSms
IF OBJECT_ID(N''tempdb..#mytempSms'') IS NOT NULL drop table #mytempSms
IF OBJECT_ID(N''tempdb..#helpTempSms]'') IS NOT NULL drop table #helpTempSms
'
EXEC(@sql)
------------------------------------------------FIN MACL------------------------------------------------------
-------------------------------------Ulises-------------------------------------------------------------------
	SET @process = 'CW-8193 ALTER PROCEDURE ccsp_GalateaGetCampsNvosCB'
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
        if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
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
            if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
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

    if exists(select * from #Tcamps2) BEGIN

        if exists(select * from #Tcamps2 where campType=7) BEGIN
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
        else begin
			While exists(select 1 from #Tcamps2 where status = 0 and ( datediff(ss,dateUpdate,getdate())>60 or dateUpdate is null) and procesando = 1)  Begin
				set rowcount 1
				select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 and procesando = 1 order by cam_id
				set rowcount 0
				EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
				update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
			end
		end

        declare @TotalNew table(
            cam_id int primary key,
            OverallTotalNew int 
            )
        

        begin Tran updateccCampsNvosCB

            insert into @TotalNew
            select CampNvosCB.id,isnull(CASE WHEN CampNvosCB.OverallTotalNew = 0 THEN NULL ELSE CampNvosCB.OverallTotalNew END,CampNvosCB.new)  from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
            where CampNvosCB.id = tcamp.cam_id

            delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
            where CampNvosCB.id = tcamp.cam_id

            INSERT into ccCampsNvosCB 
            SELECT cams.cam_id, cams.cam_descripcion,
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

        COMMIT TRAN updateccCampsNvosCB
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
    EXEC(@sql)
------------------------------------------------------------------UlisesEnd-----------------------------------------------------------------

        -----------------------------------------------------BEGIN HOTFIX K042023-Indicador de creditos Ivan Martin ----------------------------------------------------------------
        SET @process = 'HOTFIX K042023 Se mejora accesos a ccSettings2.  Línea (1456). Y se hace merge con sql anterior (no hubo diferencia mas que una linea que yo puse que ya no va)'
        SET @sql = 'ALTER procedure [dbo].[ccspOutboundSmsMessage] 
                        @action int,
                        @camId int = null,
                        @SentMsg int=null,
                        @smsoutIds varchar(max)=null,
                        @SystemApiId varchar(100)=null,
                        @statusSystemsId int =null,
                        @InsufficientBalance int=null,
                        @date datetime =null,
                        @IsCharged BIT = null
                        as
                        declare @sql varchar(max)
                        if @action=1 begin
                            select cast(cam_id as int) as CamId,cam_descripcion as [Name],cam_procesando as [Start] 
                            from ccCamps where CampType=7 and IDArea is not null and( @camId is null or cam_id=@camId)
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
                                insert into ccSmsConversationsResult values(@camId,@SentMsg,0,0,0,0,@InsufficientBalance)
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
                            select top(1) @camId =cam_id,@statusSystemsIdOld=statusSystemsId from smsccoLogDial with(nolock) where SystemApiId=@SystemApiId
                            update smsccoLogDial set statusSystemsId=@statusSystemsId where SystemApiId=@SystemApiId
                            
                            insert into @ccSmsConversationsResult
                            select camId, ROW_NUMBER() OVER(ORDER BY camId ASC)-1 AS statusSystemsId, description,value
                            from ccSmsConversationsResult
                            unpivot
                            (
                                value
                                for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected,InsufficientBalance)
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
                            for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected,InsufficientBalance)
                            ) piv
                            )

                            update B 
                            set B.SentMsg=A.SentMsg
                            ,B.Delivered=A.Delivered
                            ,B.NotDelivered=A.NotDelivered
                            ,B.RecipientRejected=A.RecipientRejected
                            ,B.CarrierRejected=A.CarrierRejected
                            ,B.InsufficientBalance=A.InsufficientBalance
                            from
                            res A
                            inner join ccSmsConversationsResult B on A.camId=B.camId
                        end
                        else if @action=8 begin
                            update smsccoLogDial set Bill=0.70 where smsDate>=@date and statusSystemsId not in(4,5)
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
                            AND cco.smsout_id IS NULL;

                            UPDATE wt
                            SET wt.sms_status = 0
                            FROM smsWorkingTable wt
                            JOIN #TempSmsOutIds temp ON wt.smsout_id = temp.smsout_id;

                            DROP TABLE #TempSmsOutIds;
                        end

                        else if @action=10 begin
                            IF NOT EXISTS(SELECT 1 FROM smsWorkingTable WHERE cam_id = @camId)
                            BEGIN
                                UPDATE ccCamps SET cam_procesando = 0 WHERE cam_id = @camId
                                SELECT CAST(0 AS BIT) 
                            END
                            ELSE
                            BEGIN
                                SELECT CAST(1 AS BIT) -- Has unsent messages 
                            END
                        end'
        EXEC(@sql);

        SET @process = 'HOTFIX K042023 Se agrega útimo update para apagar la campaña cuando no hay creditos. Líneas 1595 a 1604'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_smsOUTResetJobs] 
                    @camid AS INT= 0
                    AS
                    BEGIN

                      CREATE TABLE #TempccoLogDials ( 
                        smsout_id INT, PRIMARY KEY (smsout_id)
                      );
                      DECLARE @today DATETIME;

                      SELECT @today = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 121), 121);
                      
                      IF @camid = 0
                      BEGIN
                        INSERT INTO #TempccoLogDials
                             SELECT smsout_id
                             FROM smsccoLogDial AS ld WITH(NOLOCK)
                             WHERE smsDate >= @today
                             GROUP BY smsout_id;
                      END;
                         ELSE
                        IF @camid > 0
                        BEGIN
                          INSERT INTO #TempccoLogDials
                               SELECT smsout_id
                               FROM smsccoLogDial AS ld WITH(NOLOCK)
                               WHERE cam_id = @camid AND 
                                 smsDate >= @today
                               GROUP BY smsout_id;
                        END;

                      -- CALLBACKS Se han marcado recientemente
                      UPDATE smsWorkingTable WITH(ROWLOCK)
                        SET sms_status = 1
                      FROM smsWorkingTable wt
                         INNER JOIN
                         #TempccoLogDials ld
                         ON wt.smsout_id = ld.smsout_id
                      WHERE wt.sms_status = 2   

                      IF @camid = 0
                      BEGIN
                        -- NUEVAS - Nunca se han marcado
                        UPDATE smsWorkingTable --WITH(ROWLOCK)
                          SET sms_status = 0
                        WHERE sms_status = 2;
                      END;
                         ELSE
                      BEGIN  
                        -- NUEVAS - Nunca se han marcado
                        UPDATE smsWorkingTable WITH(ROWLOCK)
                          SET sms_status = 0
                        WHERE sms_status = 2 AND 
                            cam_id = @camid;
                      END;

                      UPDATE c
                      SET c.cam_procesando = 0
                      FROM ccCamps c
                      WHERE c.cam_id = @camid
                      AND EXISTS (
                        SELECT 1
                        FROM ccSettings2
                        WHERE setting_id = 258
                          AND valor = 0
                      );

                      DROP TABLE #TempccoLogDials;
                    END;'
        EXEC(@sql);
        -----------------------------------------------------END HOTFIX K042023-Indicador de creditos Ivan Martin ----------------------------------------------------------------


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
