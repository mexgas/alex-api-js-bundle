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
SET @versionfix = 45
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

	-----------------------------------------------------BEGIN JCL ----------------------------------------------------------------
	SET @process = 'KR105000 agregar columna ToolsTransfer'
	SET @sql = 'if not exists (select * from sys.columns where name = N''ToolsTransfer'' and Object_ID = Object_ID(N''ccRIACat_Areas''))
		begin
			alter table ccRIACat_Areas add ToolsTransfer bit not null default 0
		end'
	EXEC(@sql);

	SET @process = 'KR105000 modificar SP para insercion'
	SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas]
@option smallint,
@IDArea smallint,
@Descripcion varchar(40),
@maxMails smallint = 3, 
@maxChats smallint = 3,
@maxTweets smallint = 3,
@defCampaing smallint = NULL, 
@isKolob bit = 0,
@toolsTransfer bit = 0
AS

set nocount on



if @option = 1 begin --Selected Area
 Select a.IDArea, AreaName, isnull(a.maxChats,0) as maxChats, isnull(maxMails,3) maxMails,
 isnull(users,0) users, isnull(admins,0) admins,
 isnull(camps,0) camps, isnull(acds,0) acds  ,isnull(a.maxTweets,3) as maxTweets, ToolsTransfer
 from ccRIACat_Areas a (nolock)
 left join (select IDArea , MAX(isnull(maxChats,0)) as maxChats from ccInbound GROUP BY IDArea) b on a.IDArea = b.IDArea
 left join (select IDArea,count(case when TipoUser_id = 1 AND (@isKolob = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= 60)  then 1 else null end) users, count(case when TipoUser_id > 1 AND (@isKolob = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= 60) then 1 else null end) admins from ccusers (nolock) where isnull(IDArea,0)=case isnull(0,0) when 0 then isnull(IDArea,0) else 0 end group by IDArea) userswg on userswg.IDArea=a.IDArea
 left join (select IDArea,count(*) acds from ccinbound (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) acdswg on acdswg.IDArea=a.IDArea
 left join (select IDArea,count(*) camps from cccamps (nolock) where isnull(IDArea,0)=case isnull(@IDArea,0) when 0 then isnull(IDArea,0) else @IDArea end group by IDArea) campswg on campswg.IDArea=a.IDArea
 where StatusArea=1 and isnull(a.IDArea,0)=case isnull(@IDArea,0)
 when 0 then isnull(a.IDArea,0) else @IDArea end
 order by AreaName
 return(0)
end
else if @option=2 begin --Insert Area
	 if exists(select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion) begin
	  select -1 as result,-1 as idAreas--, Nombre en Uso
	  return(0)
	 end
	Insert into ccRIACat_Areas (AreaName,maxMails,maxChats,maxTweets,defCampaing,CreateDate,ToolsTransfer) values (@Descripcion,@maxMails,@maxChats,@maxTweets,@defCampaing,Getdate(),@toolsTransfer)
	select 1 as result, scope_identity() as idAreas--, Area Insertada
	return(0)
end
else if @option=3 begin--Update Area
	if not exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
		Update ccRIACat_Areas set AreaName=@Descripcion,maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets,defCampaing=@defCampaing where IDArea=@IDArea
	else
		Update ccRIACat_Areas set maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets,defCampaing=@defCampaing where IDArea=@IDArea

	if (select max(maxChats) as maxChats from ccinbound where IDArea=@IDArea) <> @maxChats
		Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
 return(0)
end

else if @option=4 begin --Delete Area
 if (exists(select IDArea from ccUsers where IDArea=@IDArea) or exists(select IDArea from ccCamps where IDArea = @IDArea)
  or exists(select IDArea from ccInbound where IDArea=@IDArea)) and (select valor from ccSettings where setting_id=95)<>1
 begin
  select -1
  return(0)
 end

	declare @DWorkGroups as varchar(500)

	 insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
	 select user_id,cam_id,prioridad,skill,rel_id,IDWG
	 from ccCampsAgente
	 where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
	 select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
	 from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)
	 Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
	 select user_id,cam_id,tipo,IDWG,monitored
	 from ccSupervisorCam
	 where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea=@IDArea)

	 delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
	 delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea=@IDArea)
	 delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
	 where cam_id in (select cam_id from ccCamps where IDArea=@IDArea))

	 Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)
	 Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea=@IDArea)

	 Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
	 Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)
	 Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea = @IDArea)

	 select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea=@IDArea
	 Delete from ccRIAAreaWorkGroup where IDArea=@IDArea

	 if (select valor from ccSettings where setting_id=95)=1
	 begin
	  Update ccInbound set IDArea=NULL, status=0 where IDArea=@IDArea
	  Update ccCamps set IDArea=NULL where IDArea=@IDArea
	  Update ccUsers set IDArea=NULL where IDArea=@IDArea
	 end

	 Update ccRIACat_Areas set StatusArea=0 where IDArea=@IDArea

	 select @DWorkGroups

 return(0)
end
else if @option=5 begin -- Select Areas Campaings and show its default Campaing 
	select A.IDArea as IDArea, C.cam_id as campID, C.cam_descripcion as campName,
	case when A.defCampaing=C.cam_id then 1 else 0 end as isDefault
	from ccRIACat_Areas A (nolock)
	inner join ccCamps C on A.IDArea=C.IDArea
	order by IDArea asc, isDefault desc, campName
	return(0)
 end    
    '
	EXEC(@sql);       

	SET @process = 'KR105000 insertar y modificar setting transferencia'
	SET @sql = '
ALTER procedure [dbo].[ccsp_GalateaAreas] 
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
	@toolsTransfer bit = 0
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
			toolsTransfer bit
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

                update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),defCampaing=isnull(@defCampaing, 0), ToolsTransfer=isnull(@toolsTransfer, 0) where IDArea=@IDArea

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
SET NOCOUNT ON;
    '
	EXEC(@sql);

	-----------------------------------------------------END JCL ----------------------------------------------------------------
		-----------------------------------------------------BEGIN KR102000 Callback automatico para llamadas con encuestas asignadas ----------------------------------------------------------------

		-----------------------------------------------------BEGIN Jonathan Ramirez ----------------------------------------------------------------
		SET @process = 'KR102000 JR 1 - Se agrega columna SurveyCamId a tabla ccInboundExtend '
		SET @sql = '
		IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''SurveyCamId'' and Object_ID = Object_ID(N''ccInboundExtend''))
			BEGIN
				ALTER TABLE ccInboundExtend ADD SurveyCamId SMALLINT NOT NULL DEFAULT(0);
			END
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 2 - Se agrega extended.SurveyCamId>0 en linea 1058, se valida @realValue, se cambia tipo de join left join ccInboundExtend (Dev1-346)'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_LoadGraphics]
					@Id as smallint,
					@callType as smallint,
					@UserId as smallint,
					@phone varchar(50)=null
					AS
					BEGIN
					        
					    SET NOCOUNT ON  
					    DECLARE @realValue int      
					    exec @realValue= ccsp_AgentGetStartStopPermission @age_id=@UserId, @cam_id=@Id, @call_type=@callType,@phone=@phone
					    set @realValue=isnull(@realValue,0);

					    if (@callType=1)
					    begin
					        DECLARE @canReprogram bit  
					        create table #canReprogram (canReprogram bit)
					        insert into #canReprogram
					        exec ccsp_AgentGetCampReprogramData @Id, @callType
					        select @canReprogram = canReprogram from #canReprogram
					        drop table #canReprogram

					        select a1.Inbound_id id, a2.descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey, 0 as leaveRecMessage , a2.EditableContactData,
					        case when isnull(a4.callsBySurvey,0) > 0 or extended.SurveyCamId>0 then 1 else 0 end isRelationSurvey ,
					        isnull(a2.callBackSurveyAgent,1) callBackSurveyAgent,isnull(a2.callBackSurveyClient,1) callBackSurveyClient,
					        a2.ShowCalifWnd as ShowDisposition,
					        isnull(a2.startStopRecording,0) as StartStopRecording,
					        @realValue as IsStartStopRecording,
					        isnull(a2.editableDtmf, 0) as isEditDtmf,
					        @canReprogram  CanReprogram
					        from ccRIAInboundGraph a1 
					        inner join ccInbound a2 on (a1.inbound_id=a2.inbound_id)
					        inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id) 
					        left join ccCamps a4 on a4.cam_id=a2.cam_id 
							left join ccInboundExtend extended on extended.Inbound_id = a1.Inbound_id
							where a1.inbound_id=@Id and type_id in(1,2,3) order by type_id        
					     end    
					     else
					     begin
					        select a1.cam_id Id, a2.cam_descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey,
					        case when msgFile <> '''' and leaveRecMessage = 1 then 1 else 0 end as leaveRecMessage, 
					        case when isnull(a2.surveyCamId,0) >0 then 1 else 0 end isRelationSurvey ,
					        a2.cam_ShowCalifWnd as ShowDisposition,
					        a2.callBackSurveyAgent,a2.callBackSurveyClient,
					        isnull(a2.startStopRecording,0) as StartStopRecording,
					        @realValue as IsStartStopRecording,
					        isnull(a4.EditableContactData,0) as EditableContactData
					        from ccRIACampsGraph a1 
					        inner join ccCamps a2 on (a1.cam_id=a2.cam_id)
					        inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id)
					        left join ccCampsExtend a4 on (a1.cam_id = a4.cam_id)
					        left outer join (select top 1 M.cam_id, coalesce(msgFile+'''','''','''') as msgFile 
					        from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id 
					        where M.cam_id = @Id and type = 8) b 
					        on (a2.cam_id = b.cam_id) 
					        where a1.cam_id=@Id and type_id in(1,2,3) order by type_id
					     end    
					END'
		EXEC(@sql);

		SET @process = 'KR102000 JR 3 - Se agrega modulo 12 - Asociación para encuesta'
		SET @sql = '
		IF NOT EXISTS(SELECT * FROM ccGalateaModules WHERE ModuleId = 12) BEGIN
			INSERT INTO ccGalateaModules (ModuleId, MTagEs, MTagEn, MTagPt)
			VALUES (12, ''Asociación para encuesta'', ''Survey association'', ''Associação para pesquisa'');
		END;
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 4 - Se agrega modulo 13 - Asociación para devolución de llamada'
		SET @sql = '
		IF NOT EXISTS(SELECT * FROM ccGalateaModules WHERE ModuleId = 13) BEGIN
			INSERT INTO ccGalateaModules (ModuleId, MTagEs, MTagEn, MTagPt)
			VALUES (13, ''Asociación para devolución de llamada'', ''Callback association'', ''Associação para retorno de chamada'');
		END;

		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 5 - Se agrega operacion 93 - Asociar campaña'
		SET @sql = '
		IF NOT EXISTS (SELECT * FROM ccGalateaOperations WHERE OperationId = 93) BEGIN
			INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (93, ''Asociar campaña'', ''Associate campaign'', ''Associar campanha'');
		END;
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 6 - Se agrega operacion 94 - Desasociar campaña'
		SET @sql = '
		IF NOT EXISTS (SELECT * FROM ccGalateaOperations WHERE OperationId = 94) BEGIN
			INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
			VALUES (94, ''Desasociar campaña'', ''Disassociate campaign'', ''Desassociar campanha'');
		END;
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 7 - Se agrega relacion Modulo 12 - Operacion 93'
		SET @sql = '
		IF NOT EXISTS (SELECT * FROM ccGalateaModOpRelation WHERE ModuleId = 12 AND OperationId = 93) BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (12, 93)
		END
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 8 - Se agrega relacion Modulo 12 - Operacion 94'
		SET @sql = '
		IF NOT EXISTS (SELECT * FROM ccGalateaModOpRelation WHERE ModuleId = 12 AND OperationId = 94) BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (12, 94)
		END
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 9 - Se agrega relacion Modulo 13 - Operacion 93'
		SET @sql = '
		IF NOT EXISTS (SELECT * FROM ccGalateaModOpRelation WHERE ModuleId = 13 AND OperationId = 93) BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (13, 93)
		END
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 10 - Se agrega relacion Modulo 13 - Operacion 94'
		SET @sql = '
		IF NOT EXISTS (SELECT * FROM ccGalateaModOpRelation WHERE ModuleId = 13 AND OperationId = 94) BEGIN
			INSERT INTO ccGalateaModOpRelation (ModuleId, OperationId)
			VALUES (13, 94)
		END
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 11 - Se agrega identificador ASSOCIATED_CAMP_CALLBACK'
		SET @sql = '
		IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''ASSOCIATED_CAMP_CALLBACK'') BEGIN 
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''ASSOCIATED_CAMP_CALLBACK'',''Campaña asociada (devolución de llamada)'',''Associated campaign (callback)'',''Campanha associada (retorno de chamada)'')
		END
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 12 - Se agrega identificador DISASSOCIATED_CAMP_CALLBACK'
		SET @sql = '
		IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''DISASSOCIATED_CAMP_CALLBACK'') BEGIN 
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''DISASSOCIATED_CAMP_CALLBACK'',''Campaña desasociada (devolución de llamada)'',''Disassociated campaign (callback)'',''Campanha desassociada (retorno de chamada)'')
		END
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 13 - Se agrega identificador ASSOCIATED_CAMP_SURVEY'
		SET @sql = '
		IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''ASSOCIATED_CAMP_SURVEY'') BEGIN 
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''ASSOCIATED_CAMP_SURVEY'',''Campaña asociada (encuesta)'',''Associated campaign (survey)'',''Campanha associada (pesquisa)'')
		END
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 14 - Se agrega identificador DISASSOCIATED_CAMP_SURVEY'
		SET @sql = '
		IF NOT EXISTS (SELECT * FROM ccGalateaIdentifiers WHERE Description = ''DISASSOCIATED_CAMP_SURVEY'') BEGIN 
			INSERT INTO ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt)
			VALUES (''DISASSOCIATED_CAMP_SURVEY'',''Campaña desasociada (encuesta)'',''Disassociated campaign (survey)'',''Campanha desassociada (pesquisa)'')
		END
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 15.1 - DROP PROCEDURE ccsp_GalateaAdminCampaignsSurvey'
		SET @sql = '
		if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminCampaignsSurvey'')
	    begin
	        DROP PROCEDURE ccsp_GalateaAdminCampaignsSurvey;
	    end
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 15.2 - Create procedure ccsp_GalateaAdminCampaignsSurvey'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaignsSurvey] 
			@Option AS      INT, 
			@CampType AS    INT = 0,
			@AdminId AS     INT = 0,
			@CampId AS		INT = 0,
			@SurveyCampId   INT = 0,
			@Module AS SMALLINT = 12,
			@HistoryAction AS SMALLINT = 1

			AS
			BEGIN
				DECLARE @idArea SMALLINT = NULL;
				DECLARE @operation INT = -1;
				DECLARE @mediaType INT = 0;

				IF(@Option IN (3, 4)) BEGIN
					IF(@Module <> 12) BEGIN
						IF(@CampType = 0)BEGIN
							SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id = @CampId);
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
							SET @mediaType = (SELECT [CampType] FROM ccCamps WHERE cam_id = @CampId);
							SET @operation = CASE WHEN @HistoryAction = 1 THEN 
																				CASE 
																						WHEN @mediaType = 6  THEN 44
																						WHEN @mediaType = 5  THEN 46
																						WHEN @mediaType = 4  THEN 48
																						WHEN @mediaType = 7  THEN 50
																						ELSE 42 END
																				ELSE 
																					CASE 
																						WHEN @mediaType = 6  THEN 55
																						WHEN @mediaType = 5  THEN 56
																						WHEN @mediaType = 4  THEN 57
																						WHEN @mediaType = 7  THEN 58
																						ELSE 54 END
																				END;
						END
					END ELSE BEGIN
						SET @operation = CASE WHEN @Option = 3 THEN 93 ELSE 94 END;
					END
				END

				IF @Option = 1 -- Otption 1 - Get all campaigns
				BEGIN
				IF NOT EXISTS
						(
							SELECT *
							FROM ccUsers_Roles NOLOCK
							WHERE User_id = @AdminId
									AND Rol_id = 7
						)
						BEGIN
							IF @CampType = 1 BEGIN
								WITH wgId
									AS (SELECT IDWG
										FROM ccRIAWorkGroupUsers NOLOCK
										WHERE user_id = @AdminId)
									SELECT DISTINCT 
										CAST(IdCampEsp AS INT) AS CampId,
										cam_descripcion AS Description,
										CAST(isnull(IDArea, -1) AS INT) AS AreaID,
										CAST(CampType AS INT) AS Channel,
										CAST(surveyCamId AS INT) AS SurveyCamId,
										CAST(ccRCG.graphic_id AS INT) As Frame,
										CAST(1 AS INT) As CampType
									FROM ccRIACampEspWG A
										INNER JOIN wgId ON wgId.IDWG = A.IDWG AND A.Tipo = 1
										INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id AND ccc.CampType IN (0,4,6) AND ccc.ivrScript = 0 AND ccc.callsBySurvey = 0
										LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
							END ELSE BEGIN
								WITH wgId
									AS (SELECT IDWG
										FROM ccRIAWorkGroupUsers NOLOCK
										WHERE user_id = @AdminId)
									SELECT DISTINCT 
										CAST(IdCampEsp AS INT) AS CampId,
										descripcion AS Description,
										CAST(isnull(IDArea, -1) AS INT) AS AreaID,
										CAST(chat AS INT) AS Channel,
										CAST(isnull(ccie.SurveyCamId, 0) AS INT) AS SurveyCamId,
										CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
										CAST(0 AS INT) As CampType
									FROM ccRIACampEspWG A
										INNER JOIN wgId ON wgId.IDWG = A.IDWG AND A.Tipo = 0
										INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND cci.chat IN (0)
										LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
										LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
									ORDER BY CampId ASC
							END
						END ELSE BEGIN
							IF @CampType = 1 BEGIN
									SELECT DISTINCT 
										CAST(ccc.cam_id AS INT) AS CampId,
										cam_descripcion AS Description,
										CAST(isnull(IDArea, -1) AS INT) AS AreaID,
										CAST(CampType AS INT) AS Channel,
										CAST(surveyCamId AS INT) AS SurveyCamId,
										CAST(ccRCG.graphic_id AS INT) As Frame,
										CAST(1 AS INT) As CampType
									FROM ccCamps ccc (NOLOCK)
										LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
									WHERE ccc.CampType IN (0,4,6) AND ccc.ivrScript = 0 AND ccc.callsBySurvey = 0
							END ELSE BEGIN
									SELECT DISTINCT 
										CAST(cci.Inbound_id AS INT) AS CampId,
										descripcion AS Description,
										CAST(isnull(IDArea, -1) AS INT) AS AreaID,
										CAST(chat AS INT) AS Channel,
										CAST(isnull(ccie.SurveyCamId, 0) AS INT) AS SurveyCamId,
										CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
										CAST(0 AS INT) As CampType
									FROM ccInbound cci (NOLOCK)
										LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
										LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
									WHERE cci.chat = 0 
									ORDER BY CampId ASC
							END
						END
				END -- Option 1 - Get all campaigns
				IF @Option = 2 BEGIN -- Option 2 - Get all survey camps
					WITH wgId
							AS (SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT 
								CAST(IdCampEsp AS INT) AS CampId,
								cam_descripcion AS Description,
								CAST(isnull(IDArea, -1) AS INT) AS AreaID,
								CAST(8 AS INT) AS Channel,
								CAST(surveyCamId AS INT) AS SurveyCamId,
								CAST(ccRCG.graphic_id AS INT) As Frame,
								CAST(8 AS INT) As CampType
							FROM ccRIACampEspWG A
								INNER JOIN wgId ON wgId.IDWG = A.IDWG AND A.Tipo = 1
								INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id AND ccc.CampType IN (0) AND ccc.ivrScript <> 0 AND ccc.callsBySurvey <> 0
								LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
							ORDER BY CampId ASC
				END -- Option 2 - Get all survey camps
				IF(@Option = 3) BEGIN --Option 3 - Associate Survey Campaign to Campaign
					IF(@CampType = 0) BEGIN
						IF EXISTS(SELECT * FROM ccInbound WHERE Inbound_id = @CampId) BEGIN
							IF EXISTS(SELECT * FROM ccInboundExtend WHERE Inbound_id = @CampId) BEGIN
								UPDATE ccInboundExtend SET SurveyCamId = @SurveyCampId WHERE Inbound_id = @CampId;
							END ELSE BEGIN
								INSERT INTO ccInboundExtend (Inbound_id, SurveyCamId)
								VALUES(@CampId, @SurveyCampId);
							END

							IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @CampId)
								
							INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
							SELECT
								(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
								getDate(), 
								(SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
								@operation,
								@Module,
								CASE WHEN @Module = 12 THEN '''' ELSE ''ASSOCIATED_CAMP_SURVEY'' END,
								(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [surveyCamId] FROM ccInboundExtend WHERE Inbound_id = @CampId)),
								(SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @CampId)

							SELECT 1 AS Status
						END ELSE BEGIN
							SELECT -1 AS Status
						END
					END 
					ELSE BEGIN
						IF EXISTS(SELECT * FROM ccCamps WHERE cam_id = @CampId) BEGIN
							UPDATE ccCamps SET SurveyCamId = @SurveyCampId WHERE cam_id = @CampId;

							IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @CampId)

							INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
							SELECT
								(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
								getDate(), 
								(SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
								@operation,
								@Module,
								CASE WHEN @Module = 12 THEN '''' ELSE ''ASSOCIATED_CAMP_SURVEY'' END,
								(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [surveyCamId] FROM ccCamps WHERE cam_id = @CampId)),
								(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @CampId)
							SELECT 1 AS Status
						END ELSE BEGIN
							SELECT -1 AS Status
						END
					END
				END
				IF(@Option = 4) BEGIN --Option 4 - Disassociate Survey Campaign from Campaign
					IF(@CampType = 0) BEGIN
						IF EXISTS(SELECT * FROM ccInbound WHERE Inbound_id = @CampId) BEGIN
							IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccInbound WHERE Inbound_id = @CampId)

							INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
							SELECT
								(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
								getDate(), 
								(SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
								@operation,
								@Module,
								CASE WHEN @Module = 12 THEN '''' ELSE ''DISASSOCIATED_CAMP_SURVEY'' END,
								(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [surveyCamId] FROM ccInboundExtend WHERE Inbound_id = @CampId)),
								(SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @CampId)

							UPDATE ccInboundExtend SET SurveyCamId = 0 WHERE Inbound_id = @CampId;
							SELECT 1 AS Status
						END ELSE BEGIN
							SELECT -2 AS Status
						END			
					END 
					ELSE BEGIN
						IF EXISTS(SELECT * FROM ccCamps WHERE cam_id = @CampId) BEGIN
							IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @CampId)

							INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
							SELECT
								(SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idArea),
								getDate(), 
								(SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
								@operation,
								@Module,
								CASE WHEN @Module = 12 THEN '''' ELSE ''DISASSOCIATED_CAMP_SURVEY'' END,
								(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = (SELECT [surveyCamId] FROM ccCamps WHERE cam_id = @CampId)),
								(SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @CampId)

							UPDATE ccCamps SET SurveyCamId = 0 WHERE cam_id = @CampId;
							SELECT 1 AS Status
						END ELSE BEGIN
							SELECT -2 AS Status
						END
					END
				END
			END;

		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 16 - ALTER SP ccsp_GalateaAdminInbound - Se agrega en historial de actividad'
		SET @sql = '
		ALTER PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT, 
                                            @InboundId AS SMALLINT = 0,
											@User_id AS SMALLINT = 0,
											@OutboundID AS SMALLINT = 0,
											@multi_cam as varchar(max) = null,
											@Module AS SMALLINT = 13,
											@Type AS SMALLINT = 0,
											@HistoryAction AS SMALLINT = 1

		AS
		BEGIN
			set nocount on;

			DECLARE @idArea SMALLINT = NULL;
			DECLARE @operation INT = -1;
			DECLARE @mediaType INT = 0;

			IF(@Option IN (5, 6)) BEGIN
				IF(@Module IS NOT NULL AND @Module <> 13) BEGIN

					IF(@multi_cam is not null) BEGIN
						SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id IN (SELECT TOP 1 value from dbo.fn_RIASplitDelimited(@multi_cam,'','')))
					END ELSE BEGIN
						SET @mediaType = (SELECT [chat] FROM ccInbound WHERE Inbound_id = @InboundID)
					END

					IF(@Type = 0)BEGIN
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
						SET @operation = CASE WHEN @HistoryAction = 1 THEN 
																			CASE 
																					WHEN @mediaType = 6  THEN 44
																					WHEN @mediaType = 5  THEN 46
																					WHEN @mediaType = 4  THEN 48
																					WHEN @mediaType = 7  THEN 50
																					ELSE 42 END
																			ELSE 
																				CASE 
																					WHEN @mediaType = 6  THEN 55
																					WHEN @mediaType = 5  THEN 56
																					WHEN @mediaType = 4  THEN 57
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
		END
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 17 - ALTER SP ccsp_GalateaAdminCampaigns, cambiar campType por 8 en surveyCamps MERGE KR105000 agregar columna ToolsTransfer en cosultas de campañas in/out (JCL)'
		SET @sql = '
		ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] 
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
					RAISERROR(''ERROR. No existe una campaña con el id especificado'', 18, 1);
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
	DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT );
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

					INSERT INTO @tmpCamAgent SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id,
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
					  
	;WITH lastState AS (
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

	DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;
	IF @CampType = 1 BEGIN
	SELECT @MultimediaType = meanContactTypeId FROM contactMeanOut WHERE camp_id = @Id
	END
	ELSE BEGIN
		SELECT @chatType = ci.chat FROM dbo.ccInbound AS ci WHERE ci.Inbound_id = @Id;
		SELECT @MultimediaType = meanContactTypeId FROM contactMeanIn WHERE inboundId = @Id
	END 

	IF(@chatType = 1)
	BEGIN
		SET @MultimediaType = 1
	END
			
	DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN ''23'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes
			
	INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
	(CASE 
		WHEN @chatType = 1 THEN 
		CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'',''))  THEN @CampType 
		ELSE 
		CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN @CampType 
		ELSE null 
		END END END) AS isCampDialog, B.camType
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
					CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
					isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
					camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
					CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, 
					CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 ELSE isnull(camps.CampType,0) END as OutboundType,
					ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
					FROM ccCamps camps (NOLOCK)
					INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
					INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
					LEFT JOIN ccCampsExtend extended (NOLOCK) ON camps.cam_id = extended.cam_id
					ORDER BY camps.cam_descripcion ASC;
			END;
			ELSE
				BEGIN
					SELECT DISTINCT 
											CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId, inb.chat AS InboundType, 0 as OutboundType
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
								AS (SELECT IDWG
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
								FROM ccRIACampEspWG A (NOLOCK)
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 0
									INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id 
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
						FROM ccInbound cci (NOLOCK) 
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
		EXEC(@sql);

		SET @process = 'KR102000 JR 18 - ALTER SP ccsp_RIA_ABCCamps (DECLARE @CampTypeNormal INT = 0)'
		SET @sql = '
		ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
                    @option smallint,
                    @UserId int = null,
                    @Descripcion varchar(40) = null,
                    @Cam_id varchar(1000),
                    @Activa tinyint = null,
                    @IDArea smallint = null,
                    @frame tinyint = null, 
                    @MirrorInbound_Id smallint = null,
                    @Prefijo varchar(40) = null,
                    @MediaType int = null,
					@isCreating int = null,
					@module int = -1
                    as
                    set nocount on

                    if @option = 0
                        begin
                            select cam_id,ISNULL(cam_descripcion,'''''''') as cam_descripcion,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'''') as AreaName
                            from ccCamps as CAMP with(nolock) 
                            left join ccRIACat_Areas as AREas with(nolock) on CAMP.IDArea = AREas.IDArea
                            return(0)
                        end

                    if @option = 1 -- select Camp
                        begin
                            select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0) as Area_Id,
                            prefijo as Prefijo
                            from ccCamps a1 with(nolock) 
                            inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
                            inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
                            where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
                            return(0)
                        end

                    if @option = 4 --Delete
                        begin
                            if exists (select inbound_id from ccInbound with(nolock) where cam_id = @Cam_id)
                            begin
                            declare @error varchar(70)
                            Select @error=case valor when 0 then ''No es posible eliminar la campa?a, esta asociada a una especialidad''
                                else ''Campaign can not be deleted, it has an association with an ACD'' end
                            from ccsettings with(nolock) where setting_id = 27
                            raiserror (@error,18,1)     
                            return(0)
                            end

                            delete ccCampsHorarios with(rowlock) where cam_id = @Cam_id
                            insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id) Values(@Cam_id, 5, 0, 0, @UserId)
                            Delete ccCalifCamp with(rowlock) where cam_id = @Cam_id and tipo = 1
                            Delete ccRIACampsGraph with(rowlock) where cam_id = @Cam_id
                            delete ccHistorialListaNegra with(rowlock) where cam_id = @Cam_id
                            delete ccRIARegistryLists with(rowlock) where cam_id = @Cam_id  
							delete ccoCallsOut with(rowlock) where cam_id = @Cam_id
							delete ccoCallsOutSource with(rowlock) where cam_id = @Cam_id
							delete ccCampsAgente with(rowlock) where cam_id = @Cam_id
                            return(0)
                        end

                    if @option = 2 --Insert
                        begin
                        declare @new_cam_id smallint
                        declare @isAssingPortbyCam bit

                        DECLARE @CampTypeNormal INT = 0

                        if exists(select cam_descripcion from ccCamps with(nolock) where cam_descripcion = @Descripcion)
                            begin
                            select -1 --, ''Nombre en Uso''
                            return(0)  
                            end

                        -- ODC: la campa?a siempre esta activa
                        set @Activa = 1
                        declare @pref int
                        select  @pref = valor from ccSettings where setting_id = 201
                        if (@pref = 0)
                            set @Prefijo = ''''


                        Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd,prefijo, CampType)
                        select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
                        case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end, @Prefijo, @CampTypeNormal

                        if @@rowcount = 1 BEGIN
                        select @new_cam_id = scope_identity()

                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                        SELECT 
                            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
                            getDate(), 
                            (SELECT [Login] FROM ccUsers WHERE User_id = @UserId), 
                            CASE 
                                WHEN @MediaType = 6 THEN 44
                                WHEN @MediaType = 5 THEN 46
                                WHEN @MediaType = 4 THEN 48
                                WHEN @MediaType = 7 THEN 50
                                ELSE 42 END, 
                            3, 
                            '''',
                            '''', 
                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @new_cam_id);

                        END else
                            begin
                            select -2 --, ''Error al crear campa?a''
                            return(0)
                            end

                        if isnull(@MirrorInbound_Id, 0)<>0
                            begin
                            if not exists(select inbound_id from ccInbound with(nolock) where inbound_id=@MirrorInbound_Id)
                                begin
                                select -3 -- Error al asignar campa?a a ACD, el ACD no existe o no pertenece a la misma area
                                return(0)
                                end

                            update ccinbound with(rowlock) set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
                            update cccamps with(rowlock) set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
                            end
                        set @isAssingPortbyCam=1

                        select @isAssingPortbyCam=valor from ccSettings where setting_id=232

                        if @isAssingPortbyCam=1 begin
                            insert into ccoDialerCamp (dialer_id, cam_id) 
                            select dialer_id, @new_cam_id from ccoDialers with(nolock) where status = 1
                        end

                        insert into ccCalifCamp (calif_id, cam_id, tipo) 
                        select calif_id, @new_cam_id, 1 from ccTipoCalifOUT with(nolock) where CalifOut_Status = 1

                        update ccCamps set keepDial=dbo.fn_keepDial_Camps(@new_cam_id) where cam_id=@new_cam_id

                        If not exists (select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
                            begin
                            insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
                            end

                        insert into ccRIACampsGraph (cam_id, graphic_id)
                        select @new_cam_id, graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock)  where frame = @frame and type_id = 1

                        --inserta la lista negra por default
                        if (select valor from ccsettings with(nolock) where setting_id=152)=''1''
                        begin
                            declare @tempId as int = 0
                            select @tempId = idtipolista from cctiposlistanegra where Tipolista = ''defaultList/General''
                            exec ccsp_RIABlackListCamp 4, @IDArea, @new_cam_id, @tempId, null
                        end

                        --select * from cctiposlistanegra

                        select @new_cam_id
                        return(0)
                        end

                    if @option = 3 -- Update
                        begin
                            if not exists(select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
                            insert into ccRIAGraphics (frame,type_id) values (@frame,1)

                            Update ccCamps with(rowlock) set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id

                            DECLARE @PrevFrame SMALLINT = (SELECT [graphic_id] FROM ccRIACampsGraph WHERE cam_id = @Cam_id);

                            update ccRIACampsGraph with(rowlock)
                            set graphic_id = (select graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
                            where cam_id = @Cam_id

							IF(@isCreating IS NOT NULL AND @isCreating = 2 AND @PrevFrame <> (SELECT [graphic_id] FROM ccRIACampsGraph WHERE cam_id = @Cam_id) AND @module = 3) BEGIN
                                DECLARE @Media INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @Cam_id);

                                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                                SELECT 
                                    (SELECT CRA.[AreaName] FROM ccRIACat_Areas AS CRA, ccCamps AS CCC WHERE CRA.IDArea = CCC.IDArea AND CCC.cam_id = @Cam_id),
                                    getDate(), 
                                    (SELECT [Login] FROM ccUsers WHERE User_id = @UserId), 
                                    CASE
                                        WHEN @Media = 6 THEN 55
                                        WHEN @Media = 5 THEN 56
                                        WHEN @Media = 4 THEN 57
                                        WHEN @Media = 7 THEN 58
                                        ELSE 54 END, 
                                    3, 
                                    '''',
                                    ''OUT_CALL_EDIT_ICON'', 
                                    (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @Cam_id);
                            END

                            return(0)
                        end

                        if @option = 5 --Obtener relaciones de campa?as - campa?as
                        begin
                            if not exists (select cam_id from ccCamps with(nolock) where cam_id = @Cam_id) or
                            (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
                            not exists (select cam_id from ccCamps with(nolock) where cam_id=@descripcion))
                            begin
                            select -3 -- Campa?a invalida
                            return(0)
                            end
                                    
                        if @descripcion=0
                            set @descripcion = null

                        update ccCamps with(rowlock) set surveyCamId = @descripcion where cam_id = @Cam_id
                        if @@rowcount=0
                            select -4 -- Error al actualizar
                                        
                        else
                            begin
                            delete cccalifcamp with(rowlock) where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

                            end

                        return(0)
                        end

                    if @option = 6
                        begin
                            select cam_id, isnull(surveycamid,0)
                            from cccamps with(index(PK_ccCamps),nolock)
                            where cam_id = @Cam_id
                            return(0)
                        end

                    if @option = 7 -- Checa si la campa?a no tiene grabaciones y se puede modificar el prefijo
                        begin   
                            select count(*) as Grabaciones from ccoCallsOut where cam_id = @Cam_id
                            --select 0 as Grabaciones   
                        end

                    if @option = 8 -- Checa si la campa?a tiene asignada una campa?a tipo encuesta
                        begin   
                            SELECT CAST(CASE WHEN  isnull(surveycamid,0) != 0 THEN 1 ELSE 0 END AS bit)
                            from cccamps with(index(PK_ccCamps),nolock)
                            where cam_id = @Cam_id
                            return(0)
                        end

                    return(0)
                    set nocount off
		'
		EXEC(@sql);

		SET @process = 'KR102000 JR 19 - ALTER SP ccsp_GalateaUpdateVoiceConfiguration, Se agrega Identifier IN_CONDUCT_SURVEY'
		SET @sql = '
		ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateVoiceConfiguration]
    @inboundId              smallint,
    @frame                  smallint    = null,
    @description            varchar(50) = null,
    @mediaType              tinyint     = null,
    @status                 smallint    = null,
    @tNotas                 int         = null,
    @tMaxWaitCall           smallint    = null,
    @nMaxQue                smallint    = null,
    @tel_maxwait            varchar(15) = null,
    @tel_maxqueue           varchar(15) = null,
    @tel_outservice         varchar(15) = null,
    @tel_noct               varchar(15) = null,
    @showCalifWnd           bit         = null,
    @editableCallKey        bit         = null,
    @queuePosition          bit         = null,
    @tMaxQueueCallBack      smallint    = null,
    @stopRecording          bit         = null,
    @dialPrefixOverflow     varchar(10) = null,
    @callerIdDesc           varchar(15) = null,
    @startStopRecording     bit         = null,
    @callBackSurveyAgent    bit         = null,
    @callBackSurveyClient   bit         = null,
    @editableDtmf           bit         = null,
    @addDataCallBackReminder bit        = null,
    @recordHold             bit         = null,
    @editableContactData    bit         = null,
    @userId                 smallint    = null,
    @module                 int         = -1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @graph_id smallint


    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inboundId, @userId= @userId

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    Create table #ccInboundTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )
    
    DECLARE @PrevDesc VARCHAR(MAX) = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @inboundId);

    UPDATE ccInbound SET
        descripcion = ISNULL(@description, descripcion),
        chat = ISNULL(@mediaType, chat),
        Status = ISNULL(@status, Status),
        tNotas = ISNULL(@tNotas, tNotas),
        tMaxWaitCall = ISNULL(@tMaxWaitCall, tMaxWaitCall),
        nMaxQue = ISNULL(@nMaxQue, nMaxQue),
        tel_maxwait = ISNULL(@tel_maxwait, tel_maxwait),
        tel_maxqueue = ISNULL(@tel_maxqueue, tel_maxqueue),
        tel_outservice = ISNULL(@tel_outservice, tel_outservice),
        tel_noct = ISNULL(@tel_noct, tel_noct),
        bnocturno = CASE WHEN ISNULL(@tel_noct, 0) = ''0'' OR @tel_noct = '''' THEN ''0'' ELSE ''1'' END,
        editableCallKey = ISNULL(@editableCallKey, editableCallKey),
        queuePosition = ISNULL(@queuePosition, queuePosition),
        tMaxQueueCallBack = ISNULL(@tMaxQueueCallBack, tMaxQueueCallBack),
        stopRecording = ISNULL(@stopRecording, stopRecording),
        dialPrefixOverflow = ISNULL(@dialPrefixOverflow, dialPrefixOverflow),
        callerIdDesc = ISNULL(@callerIdDesc, callerIdDesc),
        startStopRecording = ISNULL(@startStopRecording, startStopRecording),
        callBackSurveyAgent = ISNULL(@callBackSurveyAgent, callBackSurveyAgent),
        callBackSurveyClient = ISNULL(@callBackSurveyClient, callBackSurveyClient),
        editableDtmf = ISNULL(@editableDtmf, editableDtmf),
        addDataCallBackReminder = ISNULL(@addDataCallBackReminder, addDataCallBackReminder),
        recordHold = ISNULL(@recordHold, recordHold),
        EditableContactData = ISNULL(@editableContactData, EditableContactData)
    WHERE Inbound_id = @inboundId

    IF(@module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId, @tableTemp=''#ccInboundTable'';    

    DELETE FROM #ccInboundTable WHERE columnInfo IN (''bnocturno'');

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        52, 
        @module,
        CASE WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
            CASE WHEN @mediaType = 5 THEN ''IN_SHOW_DISPOSITIONS_WHATS'' ELSE  CCIT.identifierInfo END
        ELSE
            CCIT.identifierInfo
        END,
        CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
            CASE 
                WHEN CCIT.identifierInfo IN (''IN_DESTINATION_WAIT_TIME'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
                        CASE WHEN CCIT.dataInfo = ''VOICEMAIL'' 
                            THEN ''COMMON_VOICE_MAIL'' 
                            ELSE 
                                CASE WHEN CCIT.dataInfo IS NOT NULL AND CCIT.dataInfo <> '''' THEN CCIT.dataInfo ELSE ''T&COMMON_NONE'' END 
                            END
                WHEN CCIT.identifierInfo IN (''IN_RECORD_ON_HOLD'',''IN_PLAY_QUEUE_ORDER'', ''IN_STOP_RECORDING'', ''IN_SHOW_DISPOSITIONS'', ''IN_CALL_KEY'', ''IN_CONDUCT_CALLBACK_SURVEY'', ''IN_RECEIVE_DTMF_TONES'', ''IN_CALL_BACK'', ''EDIT_CALL_DATASET'', ''IN_CONDUCT_SURVEY'') THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                ELSE CCIT.dataInfo END
        ELSE '''' END,
        CASE WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN @PrevDesc ELSE (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId) END
    FROM #ccInboundTable AS CCIT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId;

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    IF @frame IS NOT NULL
    BEGIN
        SELECT @graph_id = graphic_id from ccRIAGraphics where frame = @frame and [type_id] = 1
        UPDATE ccRIAInboundGraph set graphic_id = ISNULL(@graph_id, graphic_id) where inbound_id = @inboundId

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            CASE WHEN @mediaType = 5 THEN 40 ELSE 52 END, 
            3,
            '''',
            ''IN_CALL_EDIT_ICON'', 
            (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)

    END

    IF @showCalifWnd = 1
    BEGIN
        IF EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inboundId AND tipo = 0)
        BEGIN
            UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd)
            WHERE inbound_id = @inboundId
            SELECT 1 [Result]
            RETURN(0)
        END

        SELECT -1 [Result]
        RETURN(0)
     END
     ELSE
     BEGIN
        UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId;
     END

    SELECT 1 [Result]
    RETURN(0);

    SET NOCOUNT OFF;
END	
		'
		EXEC(@sql);


		-----------------------------------------------------END Jonathan Ramirez ----------------------------------------------------------------

		-----------------------------------------------------BEGIN Ivan Martin ----------------------------------------------------------------

		SET @process = 'KR102000 Se agrega relacion con nueva coluna para encuestas en campañas de entrada (lineas 2732 y 2738)'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetHangUpData]
					@cam_id int,
					@type int
					AS BEGIN
					IF(@type = 1)
					BEGIN
						SELECT  0 leaveRecMessage,
								CASE WHEN isnull(c.callsBySurvey,0) > 0 or ISNULL(extend.SurveyCamId,0) > 0 THEN 1 ELSE 0 END isRelationSurvey,
								isnull(i.callBackSurveyAgent,1) callBackSurveyAgent,
								isnull(i.callBackSurveyClient,1) callBackSurveyClient,
								I.ShowCalifWnd showDisposition
				       FROM ccInbound i
				       LEFT JOIN ccCamps c on c.cam_id=i.cam_id
					   LEFT JOIN ccInboundExtend extend ON extend.Inbound_id = i.Inbound_id 
				       WHERE i.inbound_id=@cam_id

					END
					ELSE
					BEGIN 
						SELECT
							   CASE WHEN msgFile <> '''' and leaveRecMessage = 1 THEN 1 ELSE 0 END leaveRecMessage,
							   CASE WHEN isnull(c.surveyCamId,0) >0 THEN 1 ELSE 0 END isRelationSurvey,
							   c.callBackSurveyAgent,c.callBackSurveyClient, c.cam_ShowCalifWnd showDisposition
						FROM ccCamps c
						LEFT OUTER JOIN (SELECT TOP 1 M.cam_id, coalesce(T.msgFile+'','','''')  msgFile
										 FROM ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id
										 WHERE M.cam_id =@cam_id and type = 8) b
						on (c.cam_id = b.cam_id)
						where c.cam_id=@cam_id
					END
				END'
		EXEC(@sql);

		SET @process = 'KR102000 Se agregan las lineas(2221 a 2223, 2218)'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetInboundConfiguration]
					@command int,
					@inboundId int
					AS
					BEGIN

					SET NOCOUNT ON;

					if @command=0
					begin
					select descripcion from ccInbound where Inbound_id = @inboundId
					end
					if @command=1 -- Voice campaign
					begin
						select 
						A.Inbound_id [InboundId],
						A.descripcion [Description],
						A.chat [MediaType],
						A.Status,
						isnull(gra.graphic_id,1) [Frame],
						A.tNotas,
						A.tMaxWaitCall,
						A.nMaxQue,
						A.tel_maxwait,
						A.tel_maxqueue,
						A.tel_outservice,
						A.tel_noct,
						A.ShowCalifWnd,
						A.editableCallKey [EditableCallKey],
						A.queuePosition [QueuePosition],
						A.tMaxQueueCallBack,
						A.stopRecording [StopRecording],
						A.dialPrefixOverflow [DialPrefixOverflow],
						AE.SurveyCamId [SurveyCamId],
						isnull(A.callerIdDesc, '''') [CallerIdDesc],
						isnull(A.startStopRecording,0) [StartStopRecording],
						case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then A.callBackSurveyAgent  else cast(0 as bit) end [CallBackSurveyAgent],
						case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then A.callBackSurveyClient else cast(0 as bit) end [CallBackSurveyClient],
						case when (A.cam_id > 0 and C.callsBySurvey>0) or AE.SurveyCamId>0 then cast(1 as bit) else cast(0 as bit) end [IsRelationSurvey],
						isnull(A.editableDtmf,0) [EditableDtmf],
						isnull(A.addDataCallBackReminder,0) [AddDataCallBackReminder],
						isnull(A.recordHold, 0) [RecordHold],
						isnull(AE.RecordCalls, 1) [RecordCalls],
						isnull(A.EditableContactData, 0) [EditableContactData]
						from ccInbound A
						left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
						left join ccInboundExtend AE on AE.Inbound_id = @inboundId
						left join ccCamps C on C.cam_id=A.cam_id
						where A.Inbound_id=@inboundId
					end
					if @command=2 -- WhatsApp campaign
					begin
						declare @numbers varchar(max)
						select @numbers=COALESCE(@numbers + '','', '''') + number from ccWhatsAppNumbers where inboundId = 0 and status = 1

						select i.Inbound_id [InboundId], i.descripcion [Description], i.chat [MediaType], i.Status, isnull(g.graphic_id,1) [Frame],
						ISNULL(c.conexionInfo,'''') [Number],
						ISNULL(@numbers,'''') [FreeNumbersStr],
						CAST(ISNULL(c.closeConversationTime, 0) AS INT) [MaxAnswerTime],
						ISNULL(c.answerTimeoutClient, 30) [MUTimeOutClient],
						ISNULL(c.allowFileAttachments, 0) [AllowFileAttachments],
						i.tNotas [tNotas],
						i.ExitWrapUpDisposition,
						i.ShowCalifWnd
						from ccInbound i left join ccRIAInboundGraph g on i.Inbound_id = g.Inbound_id
						left join contactMeanIn c on i.Inbound_id = c.inboundId and i.chat = 5 and c.meanContactTypeId = 5
						where i.Inbound_id=@inboundId
					end
					if @command=3 -- Email campaign
					begin
						select 
						A.Inbound_id [InboundId],
						A.descripcion [Description],
						A.chat [MediaType],
						A.Status,
						isnull(gra.graphic_id,1) [Frame],
						A.tNotas,
						A.ShowCalifWnd,
						C.conexionInfo [ConnInfo],
						C.connUser  [ConnUserName],
						C.ConnPass [ConnPwd],
						C.isActive [IsActive],
						C.timeAlertMessage,
						C.closeConversationTime [CloseConversationTime],
						C.answerTimeOut [AnswerTimeOut],
						C.name [SenderName]
						from ccInbound A
						left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
						left join contactMeanIn C on A.Inbound_id = C.inboundId and C.meanContactTypeId=1
						where A.Inbound_id=@inboundId
					end
					if @command=4 -- Chat campaign
					begin
						select 
						i.Inbound_id [InboundId],
						i.descripcion [Description],
						i.chat [MediaType],
						i.Status,
						isnull(ig.graphic_id,1) [Frame],
						i.tNotas,
						i.ShowCalifWnd,
						i.inactiveChatTime [InactiveChatTime],
						i.chatDomain [ChatDomain],
						i.chatTimeOverflow [ChatTimeOverflow],
						i.chatQueueOverflow [ChatQueueOverflow]
						from ccInbound i
						left join ccRIAInboundGraph ig on ig.Inbound_id=i.Inbound_id
						where i.Inbound_id =@inboundId
					end

					RETURN(0)

					SET NOCOUNT OFF;    
					END'
		EXEC(@sql);

		SET @process = 'KR102000 Se agregan lineas 2988 y 2990'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_IVRChecaInboundHorario]
					@inbound_id int
					AS
					set nocount on
					declare @fecha datetime
					declare @dia smallint
					declare @hora smallint
					declare @minuto smallint
					declare @Cuantos smallint
					declare @bnocturno smallint
					declare @tel_noct varchar(14)
					declare @tel_maxqueue varchar(14)
					declare @tel_maxwait varchar(14)
					declare @tel_outservice varchar(14)
					declare @tHoldCall int
					declare @OutOFService tinyint
					declare @Active tinyint
					declare @stopRecording bit
					declare @MohFiles varchar(8000)
					declare @ivr_script smallint, @surveycamid int
					declare @callBackCustomPhone tinyint
					declare @callBackCustomKey bit

						SET DATEFIRST 1

						select @fecha =  getdate()
						select @surveycamid = 0, @ivr_script = 0
						select @dia = datepart(dw,@fecha), @hora = datepart(hh,@fecha), @minuto = datepart(mi,@fecha)
						if ( @dia=1 )     --LUNES
						begin
							  select @Cuantos = count(*)
							  from ccInbound I join ccInboundHorarios IH
							  on I.Inbound_id = IH.Inbound_id
							  join ccHorarios H on IH.horario_id = H.Horario_id
							  Where I.Inbound_id = @inbound_id
							  AND LUNES = 1
							  AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							  AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
						end
						if @dia=2   --MARTES
						begin
							  select @Cuantos = count(*)
							  from ccInbound I join ccInboundHorarios IH
							  on I.Inbound_id = IH.Inbound_id
							  join ccHorarios H on IH.horario_id = H.Horario_id
							  Where I.Inbound_id = @inbound_id
							  AND MARTES = 1
							  AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							  AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
						end
						if @dia=3   --MIERCOLES
						begin
							  select @Cuantos = count(*)
							  from ccInbound I join ccInboundHorarios IH
							  on I.Inbound_id = IH.Inbound_id
							  join ccHorarios H on IH.horario_id = H.Horario_id
							  Where I.Inbound_id = @inbound_id
							  AND MIERCOLES = 1
							  AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							  AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
						end
						if @dia=4   --JUEVES
						begin
							  select @Cuantos = count(*)
							  from ccInbound I join ccInboundHorarios IH
							  on I.Inbound_id = IH.Inbound_id
							  join ccHorarios H on IH.horario_id = H.Horario_id
							  Where I.Inbound_id = @inbound_id
							  AND JUEVES = 1
							  AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							  AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
						end
						if @dia=5   --VIERNES
						begin
							  select @Cuantos = count(*)
							  from ccInbound I join ccInboundHorarios IH
							  on I.Inbound_id = IH.Inbound_id
							  join ccHorarios H on IH.horario_id = H.Horario_id
							  Where I.Inbound_id = @inbound_id
							  AND VIERNES = 1
							  AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							  AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
						end
						if @dia=6   --SABADO
						begin
							  select @Cuantos = count(*)
							  from ccInbound I join ccInboundHorarios IH
							  on I.Inbound_id = IH.Inbound_id
							  join ccHorarios H on IH.horario_id = H.Horario_id
							  Where I.Inbound_id = @inbound_id
							  AND SABADO = 1
							  AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							  AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
						end
						if @dia=7   --DOMINGO
						begin
							  select @Cuantos = count(*)
							  from ccInbound I join ccInboundHorarios IH
							  on I.Inbound_id = IH.Inbound_id
							  join ccHorarios H on IH.horario_id = H.Horario_id
							  Where I.Inbound_id = @inbound_id
							  AND DOMINGO = 1
							  AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							  AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
						end

						select @Active=0, @OutOFService=0
						select 
						@Active=case when status=1 then 1 else 0 end, --Activa
						@OutOFService=case when standby=0 then 1 else 0 end , --En operacion
						@tHoldCall = tMaxWaitCall, @bnocturno =bnocturno, @stopRecording=stopRecording, 
						@callBackCustomPhone=callBackCustomPhone, @callBackCustomKey=callBackCustomKey,
						@tel_noct=tel_noct, @tel_maxqueue=tel_maxqueue, @tel_maxwait=tel_maxwait, @tel_outservice=tel_outservice, @surveycamid = isnull(extend.SurveyCamId,0)
						from ccInbound i  
						left join ccInboundExtend extend on extend.Inbound_id = i.Inbound_id
						where i.Inbound_id=@inbound_id

						IF ( @OutOFService =1 AND @Active=1 and (select valor from ccsettings where setting_id = 4) = 1)
						BEGIN
					--        SI ESTA EN SERVICO
							  if @surveycamid > 0
									select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

							  --Custom MOH Files
							  SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
							  FROM ccInboundMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE Inbound_id = @Inbound_ID and TYPE = 15 ORDER BY orden
						END
						ELSE
						BEGIN
							  IF ( @OutOFService = 0 and (select valor from ccsettings where setting_id = 4) = 1)
							  BEGIN -- ESPECIALIDAD NO ACTIVA
									select @Cuantos= -1, @tHoldCall=0, @bnocturno='''', @tel_noct='''', @tel_maxqueue='''', @tel_maxwait='''', @tel_outservice='''', @MohFiles=''''
							  END
							  IF ( @Active = 0 )
							  BEGIN -- ESPECIALIDAD FUERA DE SERVICIO TEMPORAL
									select @Cuantos= -2, @tHoldCall=0, @bnocturno='''', @tel_noct='''', @tel_maxqueue='''', @tel_maxwait='''', @MohFiles=''''
							  END 
						END
						SET DATEFIRST 7

						select ''Cuantos''=@Cuantos, ''tHoldCall''=@tHoldCall, ''bNocturno''=1, ''tel_MaxWait''=@tel_maxwait, ''tel_MaxQueue''=@tel_maxqueue, ''tel_Noct''=@tel_noct, ''tel_outservice''=@tel_outservice, ''stopRecording''=@stopRecording, ''mohFiles''=isnull(@MohFiles,''''), ''ivrScript''=@ivr_script, isnull(@callBackCustomPhone,0) cbCustomPhone, isnull(@callBackCustomKey,0) cbCustomKey
					set nocount off'
		EXEC(@sql);

		SET @process = 'KR102000 Se quita doble acceso a cccallsin y se cambia linea 2459'
		SET @sql = 'ALTER procedure [dbo].[ccsp_RIAUpdateCallBack_Abandon]
                    @cal_id int,
                    @nStatus tinyint,
                    @cbPhone varchar(20) = NULL
                    as
                    set nocount on
                    declare @ANI varchar(13), @cam_id int, @inbound_id int, @fechadial varchar(40), @callout_id int, 
                     @statuscall_id_Array varchar(1000), @minCallBackAbandon smallint, @pais varchar(2), @ld varchar(5), @telFormat tinyint

                    declare @lenExt int

                    select @ANI=C.cal_ANI, 
                           @cam_id = CASE WHEN @nStatus IN(11,13) AND ((C.cal_whoHung = 2 AND ISNULL(extend.SurveyCamId,0) > 0) OR (C.cal_whoHung = 0 AND ISNULL(i.callBackSurveyClient,0) > 0)) THEN extend.SurveyCamId ELSE I.cam_id END,
                           @inbound_id=I.inbound_id, 
                    @statuscall_id_Array=statuscall_id_Array, @minCallBackAbandon=minCallBackAbandon,@telFormat = I.telFormato
                    from cccallsin C 
                    join ccInbound I on I.Inbound_id=C.Inbound_id
                    left join ccInboundExtend extend on extend.Inbound_id = I.Inbound_id
                    where cal_id=@cal_id

                    if datalength(isnull(@cbPhone,'''')) > 0
                    begin
                        set @ANI=@cbPhone
                    end

                    select @fechadial=convert(varchar(16), dateadd(minute, @minCallBackAbandon, getdate()), 121)

                    select @pais = valor from ccSettings with(nolock) where setting_id = 104
                    select @ld = valor from ccSettings with(nolock) where setting_id = 17
                    select @lenExt = case when valor=''''then 0 else valor end from ccSettings with(nolock) where setting_id = 108
                    if @nStatus not in (select value from dbo.fn_RIASplitDelimited(@statuscall_id_Array, '','')) or isnull(@cal_id,0)=0
                     return(0)
             
                    if isnull(@cam_id, 0)=0
                      return(0)

              
                    --set @ANI =dbo.Limpia(@ANI)
                    --if @lenExt<>len(@ANI)
                    --  select @ANI = dbo.completa(@ANI, @pais, @ld)

                      if @telFormat = 0
                      set @ANI =dbo.Limpia(@ANI)
                      else if @telFormat = 1
                      select @ANI = dbo.completa(@ANI, @pais, @ld)

                    if (select substring(@ANI,1,1))= ''E''
                      return(0)

                    if exists (select cal_ANI from ccRIAUpdateCallBack_Abandon where cal_ANI=@ANI)
                      return(0)

                     begin try
                      insert ccRIAUpdateCallBack_Abandon (cal_id, cal_ANI, cam_id, callout_id, inbound_id, minCallBackAbandon)
                      select @cal_id, @ANI, @cam_id, @callout_id, @inbound_id, @fechadial
                      declare @dato1 varchar (max),  @dato2 varchar (max), @dato3 varchar (max), @dato4 varchar (max), @dato5 varchar (max)
                      set @dato1 = '''' set @dato2 = '''' set @dato3 = '''' set @dato4 = '''' set @dato5 = ''''
              
                      declare @datosToAgent varchar(max)
                      select @datosToAgent= addDataCallBackReminder from ccInbound where Inbound_id = @inbound_id
              
                      if(@datosToAgent = 1)
                      begin
                        select @dato1 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 1''
                        select @dato2 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 2''
                        select @dato3 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 3''
                        select @dato4 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 4''
                        select @dato5 = Isnull(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 5''
                      end 
                      exec ccsp_INInsertaCallBack @cal_id, @cam_id, @ANI, @fechadial, @dato1,@dato2,@dato3,@dato4,@dato5, 1, 0, 1

                      select top 1 @callout_id=callout_id from ccoWorkingTable WITH(INDEX(PK_ccoWorkingTable)) WHERE cal_telefono=@ANI
                      select @fechadial=dateadd(minute, minCallBackAbandonXpire, @fechadial) from ccInbound where Inbound_id=@inbound_id
                      update ccRIAUpdateCallBack_Abandon set callout_id=@callout_id, minCallBackAbandonXpire=@fechadial where cal_id=@cal_id
                      return(0)
                     end try

                     begin catch
                      return(0)
                     end catch
                    set nocount off'
		EXEC(@sql);

		SET @process = 'KR102000 Se agrega logica para recibir errores de la ejecucion de ccsp_RIAManageAreas lineas (3114, 3182, 2607 - 2612)'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_UnassignedElementsInAreas]   
                    @Action INT,   
                    @AreaId INT = 0,
                    @Ids VARCHAR(MAX) = ''''
                    AS    
                    BEGIN
                        DECLARE @IdsTemp TABLE (Id INT);
                        DECLARE @Id VARCHAR(MAX);
                        DECLARE @Result VARCHAR(MAX);
                        INSERT INTO @IdsTemp SELECT VALUE FROM dbo.fn_RIASplitDelimited(@Ids,'','')

                        -- Return results 
                        IF @Action IN (0, 3, 6) -- User names 
                        BEGIN 
                            SET @Result = (SELECT ISNULL(login,'''')  AS ElementNames
                            FROM @IdsTemp ids
                            INNER JOIN ccUsers users ON users.User_id = ids.Id)
                        END

                        IF @Action IN (1, 4, 7) -- Campaign names
                        BEGIN 
                            SET @Result = (SELECT ISNULL(cam_descripcion,'''')  AS ElementNames
                            FROM @IdsTemp ids
                            INNER JOIN ccCamps campaign ON campaign.cam_id = ids.Id)
                        END

                        IF @Action IN (2, 5, 8) -- Acd names
                        BEGIN 
                            SET @Result = (SELECT ISNULL(descripcion,'''') AS ElementNames
                            FROM @IdsTemp ids
                            INNER JOIN ccInbound acd ON acd.Inbound_id = ids.Id)
                        END
                        -------------------------------------------------------
                        IF @Action = 0 -- Assign Users to Unassigned area 
                        BEGIN
                            UPDATE ccUsers
                            SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END,
                                status = 1
                            FROM @IdsTemp ids
                            WHERE ccUsers.User_id = ids.Id
                            AND NOT EXISTS (SELECT 1 FROM ccUsers WHERE IDArea = @AreaId AND User_id = ids.Id)
                        END

                        IF @Action = 1 -- Assign Users to Campaigns area 
                        BEGIN
                            UPDATE ccCamps
                            SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END
                            FROM @IdsTemp ids
                            WHERE ccCamps.cam_id = ids.Id
                            AND NOT EXISTS (SELECT 1 FROM ccCamps WHERE IDArea = @AreaId AND cam_id = ids.Id)
                        END

                        IF @Action = 2 -- Assign Users to Acds area 
                        BEGIN       
                            UPDATE ccInbound
                            SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END,
                                status = 1
                            FROM @IdsTemp ids
                            WHERE ccInbound.Inbound_id = ids.Id
                            AND NOT EXISTS (SELECT 1 FROM ccInbound WHERE IDArea = @AreaId AND Inbound_Id = ids.Id)
                        END

                        IF @Action in (3, 4, 5, 6, 7, 8)
                        BEGIN 
                            SET @Id = ''0''
                            WHILE EXISTS( SELECT Id FROM @IdsTemp ) 
                            BEGIN
                                SELECT TOP 1 @Id =Id FROM @IdsTemp 

                                IF @Action = 3 -- Unassign Users from area 
                                BEGIN
                                    EXEC ccsp_RIAManageAreas @option = 2, @DeleteUserId = @Id
                                END

                                IF @Action = 4 -- Unassign Campaigns from area 
                                BEGIN
                                    DECLARE @TempResult INT;
                                    EXEC @TempResult = ccsp_RIAManageAreas @option=4, @DeleteCamId = @Id;
                                    IF @TempResult = -4 
                                    BEGIN
                                        SET @Result = ''-1'';
                                    END
                                END 

                                IF @Action = 5 -- Unassign Acds from area 
                                BEGIN
                                    EXEC ccsp_RIAManageAreas @option = 6, @DeleteACDGroupId = @Id
                                END

                                IF @Action = 6 -- Delete Users from area 
                                BEGIN
                                    EXEC ccsp_RIA_ABCAgents @option=4, @UserId = @Id, @Login = '''', @Nombres='''',@ApellidoPaterno='''',@ApellidoMaterno='''',@Password='''',@Sexo=0,@canChangeStatus=0,@AreaId=0,@UserType=0,@IDWG=0
                                END

                                IF @Action = 7 -- Delete Campaigns from area 
                                BEGIN
                                    EXEC ccsp_RIA_ABCCamps @option = 4, @UserId = 0, @Descripcion = '''', @Cam_id = @Id, @Activa = 0, @IDArea = 0, @frame = 0
                                    delete ccCamps with(rowlock) where cam_id = @Id
                                    delete ccCampsExtend with(rowlock) where cam_id = @Id
                                END

                                IF @Action = 8 -- Delete Acds from area 
                                BEGIN
                                    EXEC ccsp_RIA_ABCACDGroups @option = 4, @UserId = 0, @Descripcion = '''', @Inbound_id = @Id, @IDArea = 0, @frame = 0
                                    delete ccInbound with(rowlock) where Inbound_id = @Id
                                    delete ccInboundExtend with(rowlock) where Inbound_Id = @Id
                                END

                                DELETE FROM @IdsTemp WHERE Id = @Id
                            END
                        END

                        SELECT @Result
                    END'
		EXEC(@sql);

		-----------------------------------------------------END Ivan Martin ----------------------------------------------------------------
		-----------------------------------------------------BEGIN Uriel Cabrera  ----------------------------------------------------------------
		SET @process = 'KR102000 Se agrega nueva operacion para el historial de eliminacion'
		SET @sql = ' if not exists (SELECT * FROM ccGalateaOperations WHERE OperationId = 92)
						BEGIN
							INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) 
							VALUES (92,''Eliminar campaña (llamada de salida encuesta)'',''Delete campaign (survey outbound call)'',''Delete campaign (survey outbound call)'');
						END'
		EXEC(@sql);
		SET @process = 'KR102000 Se modifica la opción 2 para evaluar si una campaña es de encuesta (Linea 3253)'
		SET @sql = ' ALTER PROCEDURE [dbo].[ccsp_RIALoadCamps] @option SMALLINT, @AreaId SMALLINT = NULL, @Sup SMALLINT = NULL, @WGID SMALLINT = NULL
							AS
							SET NOCOUNT ON

							DECLARE @loginDays INT

							SET @loginDays = 0

							IF @option = 1 -- Todas las campa?as
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

							IF @option = 2 -- Campa?as de un Area
							BEGIN
								SELECT DISTINCT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG, CASE WHEN a1.ivrScript <> 0 AND a1.callsBySurvey <> 0 THEN 8 ELSE ISNULL(a1.CampType, 0) END as mode
								FROM ccCamps a1
								JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
								JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
								WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
								ORDER BY cam_descripcion

								RETURN (0)
							END

							IF @option = 3 -- Campa?as por Supervisor
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

							IF @option = 5 -- Campa?as por Supervisor
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

							IF @option = 8 -- Campa?as de un Agente
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
							IF @option = 9 -- Campa?as de un Area
							BEGIN
								(SELECT DISTINCT a1.cam_id as CamID, cam_descripcion as CamDescription, frame as Frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) as RelationsWG,1 CamType, 
								ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 1 and IdCampEsp = a1.cam_id and IDWG = @WGID group by IdCampEsp),0) IsAssignedToCurrentWG,
								CAST(CASE WHEN a1.progDial = 3 THEN 6 WHEN a1.CampType = 5 THEN 5 WHEN a1.CampType=7 THEN 7 WHEN a1.ivrScript <> 0 AND a1.callsBySurvey <> 0 THEN 8 ELSE 0 END as [tinyint]) [MediaType]
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

							SET NOCOUNT OFF
								'
		EXEC(@sql);
		SET @process = 'KR102000 Se agrega el surveyCamId a la obtencion (Linea 3513)'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp] @User_id SMALLINT, @campID INT = NULL
						AS
						SET NOCOUNT ON

						DECLARE @tableExistsRec TABLE (
							camId INT PRIMARY KEY
							,existRec BIT
							)
						DECLARE @camByUser TABLE (
							camId INT PRIMARY KEY
							,isCheck BIT
							)
						DECLARE @camId INT
							,@id INT;

						IF NOT EXISTS (
								SELECT *
								FROM ccUsers_Roles
								WHERE User_id = @User_id
									AND Rol_id = 7
								)
						BEGIN
							INSERT INTO @camByUser
							SELECT *
								,0
							FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
							WHERE @campID IS NULL
								OR cam_id = @campID
						END
						ELSE
						BEGIN
							INSERT INTO @camByUser
							SELECT cam_id
								,0
							FROM ccCamps
							WHERE (
									IDArea > 0
									OR IDArea IS NULL
									)
								AND (
									@campID IS NULL
									OR cam_id = @campID
									)
						END

						WHILE EXISTS (
								SELECT *
								FROM @camByUser
								WHERE isCheck = 0
								)
						BEGIN
							SELECT TOP 1 @camId = camId
							FROM @camByUser
							WHERE isCheck = 0

							IF EXISTS (
									SELECT cam_id
									FROM ccoCallsOut
									WHERE cam_id = @camId
									)
							BEGIN
								INSERT INTO @tableExistsRec
								VALUES (
									@camId
									,1
									)
							END
							ELSE
							BEGIN
								INSERT INTO @tableExistsRec
								VALUES (
									@camId
									,0
									)
							END

							UPDATE @camByUser
							SET isCheck = 1
							WHERE camId = @camId
						END

						SELECT a1.cam_id
							,cam_Descripcion
							,cam_tNotas
							,cast(cam_ocupado AS INT) AS cam_ocupado
							,cam_noInt_ocupado
							,cam_inter_ocupado
							,cast(cam_nocontesto AS INT) AS cam_nocontesto
							,cam_noInt_nocontesto
							,cam_inter_nocontesto
							,cast(cam_fax AS INT) AS cam_fax
							,cam_noInt_fax
							,cam_inter_fax
							,cast(cam_modomanual AS INT) AS cam_modomanual
							,ANI
							,cam_ShowCalifWnd
							,cam_StartTimerOnHangUp
							,editableCallKey
							,cam_tNoContesta
							,iTipoDial
							,detectAnswerMachine
							,detectVoiceMail
							,compliance
							,cam_inter_graba
							,cam_noint_graba
							,cast(progDial AS TINYINT) progDial
							,cast(excCallBack AS TINYINT) excCallBack
							,dialOrder
							,dialPrefix
							,dialPrefixMan
							,dialPrefixXfe
							,listenManualCall
							,stopRecording
							,cast(abandonCallback AS TINYINT) abandonCallback
							,a3.frame
							,a1.t_autoCB
							,a1.id_anilist
							,a1.tDialonWrapUp
							,dbo.fn_viewMode(@User_id, 10) viewMode
							,cam_maxqueue AS queSize
							,DNCScrub
							,callerIdDesc
							,timeZoneRule
							,callsBySurvey
							,ivrScript
							,surveyPctg
							,isnull(a1.call_record, 1) AS call_record
							,cast(startStopRecording AS TINYINT) startStopRecording
							,leaveRecMessage
							,manualCallOnChat
							,callBackSurveyAgent
							,surveyCamId
							,callBackSurveyClient
							,CASE 
								WHEN surveycamid IS NULL
									OR surveycamid = 0
									THEN 0
								ELSE 1
								END isRelationSurvey
							,isnull(a1.funcEspDtmf, 0)
							,isnull(sipHdrFormat, '''') sipHdrFormat
							,cam_inter_cancelled
							,prefijo
							,enbleprefix = CASE 
								WHEN existRec = 0
									THEN 1
								ELSE 0
								END
							,isnull(exitAssisted, 0) exitAssisted
							,isnull(previewDiscard, 0) PreviewDiscard	
							,isnull(CampType, 0) CampType
							,isnull(contact.conexionInfo, '''') conexionInfo
							,isnull(contact.connUser, '''') connUser
							,isnull(contact.closeConversationTime, 0) closeConversationTime
							,isnull(contact.answerTimeoutClient, 0) answerTimeoutClient
							,isnull(contact.allowFileAttachments, 0) allowFileAttachments
							,isnull(selectRotativeANI, 0) selectRotativeANI
							,ISNULL(rotativeAlgo, 0) rotativeAlgo
							,isnull(autoStart, 0) autoStart
							,isnull(messagingOrder, 0) messagingOrder
							,ISNULL(cam_tPreview, 0) AS CamTPreview
							,ISNULL(timesPreview, 0) AS TimesPreview
							,isnull(timesDiscard, 0) TimesDiscard
							,ISNULL(recordHold, 0) recordHold
							,isnull(campsExtention.zipCodeSchedule, 0) ZipCodeSchedule
							,isnull(campsExtention.RecordCalls, 1) RecordCalls
							,isnull(campsExtention.simultaneousRecs, 1) simultaneousRecs
							,isnull(campsExtention.EditableContactData, 0) EditableContactData
						FROM ccCamps a1
						INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
						INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
						INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
						LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
						LEFT JOIN ccCampsExtend campsExtention ON a1.cam_id = campsExtention.cam_id
						ORDER BY cam_descripcion

						RETURN (0)

						SET NOCOUNT OFF
						'
		EXEC(@sql);
		SET @process = 'KR102000 Se agrega evaluacion para el tipo de campaña (Linea 3583)'
		SET @sql = '			ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall]
			@option int,
			@UserID int = 0,
			@onChat int = 0,
			@campId int = 0
			AS
			set nocount on
			if(@option = 1)
			begin
				if (@onChat = 0)
				begin
					declare @mod smallint
					declare @IdArea smallint
					declare @DialingMode tinyint
					select @IdArea = IDArea, @DialingMode = DialingMode from ccUsers where User_id = @UserID
					select @mod = defCampaing from ccRIACat_Areas A
					where A.IDArea = @IdArea 
					select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [isDefault],  g.graphic_id, c.cam_ModoManual, 
					isnull(c.selectRotativeANI, 0) selectRotativeANI
					, CASE WHEN c.ivrScript <> 0 AND c.callsBySurvey <> 0 THEN 8 ELSE isnull(c.CampType,0) END as CampType,
					CASE WHEN @DialingMode = 1 THEN (select count(1) from ccoWorkingTable nolock where cam_id = c.cam_id) ELSE 0 END AS countJobs,
					isnull(c.timesPreview, 0) timesPreview
					from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id and c.IDArea = @IdArea
					join ccRIACampsGraph g ON g.cam_id = c.cam_id
					where ca.user_id = @UserID  
						and cam_ModoManual = case when @DialingMode = 1 OR (@DialingMode = 0 AND cam_ModoManual in (1,3)) then cam_ModoManual else -1 end AND CampType = CASE WHEN @DialingMode = 1 THEN 6 ELSE CampType END
					order by cam_descripcion
				end
				else 
				begin 
					select distinct c.cam_id, c.cam_descripcion,  g.graphic_id,  c.cam_ModoManual
					, isnull(c.CampType,0) as CampType
					from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
					join ccRIACampsGraph g ON g.cam_id = c.cam_id
					where ca.user_id = @UserID and manualCallOnChat = 1
					order by cam_descripcion
					SET NOCOUNT OFF;
				end
			end
			if(@option = 2)
			begin
				declare @aniList int 
				declare @rotativeAniListId int
				select @aniList = id_anilist, @rotativeAniListId  = rotativeAlgo from ccCamps where cam_id = @campId
				if @rotativeAniListId >0 begin
					select telAni from ccRotativeANIListDetail where id_RAniList = @aniList
				end
				else begin
					select top 0 '''' telAni 
				end					
			end'
		EXEC(@sql);
		SET @process = 'KR102000 Se agrega el surveycamId para la obtencion (Linea 3674, 3734)'
		SET @sql = ' 
	ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT
			,@campID INT
			AS
			BEGIN
			DECLARE @AllCampaigns TABLE (
			cam_id SMALLINT
			,cam_Descripcion VARCHAR(60)
			,cam_tNotas SMALLINT
			,cam_ocupado SMALLINT
			,cam_noInt_ocupado SMALLINT
			,cam_inter_ocupado SMALLINT
			,cam_nocontesto SMALLINT
			,cam_noInt_nocontesto SMALLINT
			,cam_inter_nocontesto SMALLINT
			,cam_fax SMALLINT
			,cam_noInt_fax SMALLINT
			,cam_inter_fax SMALLINT
			,cam_modomanual SMALLINT
			,ANI VARCHAR(15)
			,cam_ShowCalifWnd BIT
			,cam_StartTimerOnHangUp BIT
			,editableCallKey BIT
			,cam_tNoContesta SMALLINT
			,iTipoDial SMALLINT
			,detectAnswerMachine SMALLINT
			,detectVoiceMail SMALLINT
			,compliance SMALLINT
			,cam_inter_graba SMALLINT
			,cam_noint_graba SMALLINT
			,progDial SMALLINT
			,excCallBack SMALLINT
			,dialOrder SMALLINT
			,dialPrefix VARCHAR(10)
			,dialPrefixMan VARCHAR(10)
			,dialPrefixXfe VARCHAR(10)
			,listenManualCall BIT
			,stopRecording BIT
			,abandonCallback BIT
			,frame SMALLINT
			,t_autoCB SMALLINT
			,id_anilist INT
			,tDialonWrapUp SMALLINT
			,viewMode TINYINT
			,queSize SMALLINT
			,DNCScrub INT
			,callerIdDesc VARCHAR(15)
			,timeZoneRule INT
			,callsBySurvey INT
			,ivrScript INT
			,surveyPctg INT
			,call_record SMALLINT
			,startStopRecording BIT
			,leaveRecMessage BIT
			,manualCallOnChat BIT
			,callBackSurveyAgent BIT
			,surveyCamId INT
			,callBackSurveyClient BIT
			,isRelationSurvey BIT
			,funcEspDtmf INT
			,sipHdrFormat VARCHAR(255)
			,cam_inter_cancelled SMALLINT
			,prefijo VARCHAR(40)
			,enbleprefix BIT
			,exitAssisted BIT
			,previewDiscard BIT
			,CampType INT
			,conexionInfo VARCHAR(50)
			,connUser VARCHAR(15)
			,closeConversationTime INT
			,answerTimeoutClient INT
			,allowFileAttachments BIT
			,selectRotativeANI INT
			,rotativeAlgo TINYINT
			,autoStart BIT
			,messagingOrder BIT
			,CamTPreview SMALLINT
			,TimesPreview TINYINT
			,timesDiscard TINYINT
			,recordHold BIT
			,zipCodeSchedule BIT
			,RecordCalls tinyint
			,simultaneousRecs smallint
				,EditableContactData bit
			)
			DECLARE @numbers VARCHAR(max)

			SELECT @numbers = COALESCE(@numbers + '''', '''', '''''''') + number
			FROM ccWhatsAppNumbers
			WHERE camp_id = 0
			AND STATUS = 1

			INSERT INTO @AllCampaigns
			EXEC ccsp_RIAConfCamp @adminID
			,@campID

			SELECT dialPrefixMan DialPrefixMan
			,dialPrefixXfe DialPrefixXfe
			,listenManualCall ListenManualCall
			,stopRecording StopRecording
			,abandonCallback AbandonCallBack
			,t_autoCB AutoCB
			,id_anilist IdIstANI
			,tDialonWrapUp TDialOnWrapup
			,queSize Quesize
			,DNCScrub
			,callerIdDesc CallerIdDesc
			,timeZoneRule TimeZoneRule
			,callsBySurvey CallsBySurvey
			,ivrScript IvrScript
			,surveyPctg SurveyPctg
			,call_record CallRecord
			,startStopRecording StartStopRecording
			,leaveRecMessage LeaveRecMessage
			,manualCallOnChat ManualCallOnChat
			,callBackSurveyClient CallBackSurveyClient
			,callBackSurveyAgent CallBackSurveyAgent
			,surveyCamId SurveyCamId
			,funcEspDtmf FuncEspDtmf
			,sipHdrFormat SipHdrsCfg
			,dialPrefix DialPrefix
			,prefijo Prefix
			,dialOrder DialOrder
			,progDial ProgDial
			,cam_Descripcion CamDescription
			,cam_tNotas CamTnotas
			,cam_ocupado CamBusy
			,cam_noInt_ocupado CamNoIntBusy
			,cam_inter_ocupado CamInterBusy
			,cam_nocontesto CamNoAnswer
			,cam_noInt_nocontesto CamNoIntNoAnswer
			,cam_inter_nocontesto CamInterNoAnswer
			,(cam_inter_cancelled / 60) CamInterCancelled
			,cam_fax CamFax
			,cam_noInt_fax CamNoIntFax
			,cam_inter_fax CamInterFax
			,cam_modomanual CamModoManual
			,ANI
			,cam_StartTimerOnHangUp CamStartTimerOnHangUp
			,editableCallKey EditableCallKey
			,cam_tNoContesta CamTNoAnswer
			,iTipoDial CamIntensiveDialing
			,detectAnswerMachine DetectAnswerMachine
			,detectVoiceMail DetectVoiceMail
			,compliance Compliance
			,cam_inter_graba CamInterRecord
			,cam_noint_graba CamNoIntRecord
			,excCallBack ExcCallBack
			,cam_ShowCalifWnd CamShowCalifWnd
			,frame Frame
			,exitAssisted ExitAssistedDialMode
			,previewDiscard PreviewDiscard
			,CampType
			,conexionInfo ConexionInfo
			,connUser ConnUser
			,closeConversationTime CloseConversationTime
			,answerTimeoutClient MUTimeOutClient
			,allowFileAttachments AllowFileAttachments
			,CamTPreview
			,CAST(TimesPreview AS SMALLINT) TimesPreview
			,@numbers AS FreeNumbers
			,selectRotativeANI SelectRotativeANIManualCall
			,rotativeAlgo RotativeAlgo
			,autoStart AutoStart
			,messagingOrder MessagingOrder
			,timesDiscard TimesDiscard
			,recordHold RecordHold
			,zipCodeSchedule ZipCodeSchedule
			,RecordCalls RecordCalls
			,simultaneousRecs SimultaneousRecs
			,EditableContactData EditableContactData
			FROM @AllCampaigns
			WHERE cam_id = @campID
			END
				'
		EXEC(@sql);
		-----------------------------------------------------END Uriel Cabrera  ----------------------------------------------------------------

        -----------------------------------------------------BEGIN Ivan Martin   ----------------------------------------------------------------
        SET @process = 'KR102000 Se cambian lineas 3340 para sacar el surveycamid de la tabla de extend y se agrega liinea 3342 '
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
                    @User_id smallint,
                    @TipoStatusAge_id tinyint,
                    @TipoNotReady tinyint,
                    @tStatus float,
                    @TipoCall  tinyint,
                    @Camp smallint,
                    --@isTransferSurvey bit=0, --0 Callback, 1 Realiza Transferencia inmediata
                    @callout_id int=0,
                    @call_id int=0,
                    @isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
                    @tDialog float =0 ,
                    @currentStatus int =-2,--NUEVO PAR?METRO PARA LA NUEVA COLUMNA
                    @Fecha4 datetime=null,
                    @tMusicHold int =0,
                    @isTransferEngine bit = 0
                    AS

                    if @Fecha4 is null set @Fecha4 = getdate()

                    if @TipoCall > 0 set @TipoCall = @TipoCall - 1

                    if (@User_id > 0 ) begin

                    declare @cam_id int,@surveycamId int
                    declare @cal_telefono varchar(30)
                    declare @cal_key varchar(40)
                    declare @inbound_id int
                    declare @callBackSurveyClients bit
                    declare @cal_whoHung tinyint
                    declare @cal_tDialog int
                    declare @cal_tNotas float
                    declare @cal_tNotaOri int
                    declare @tMinAVRS smallint
                    declare @calInicio datetime
                    declare @sumCall float
                    declare @cal_manual int 

                    set @cal_tNotas =0
                    set @cal_tNotaOri=0

                    if @TipoStatusAge_id=32 set @tStatus=CONVERT(DECIMAL(10,2), ROUND(@tStatus, 0, 1))
                    --4 Dialog,6 Notas, 27 Notas Fallida
                    if @TipoStatusAge_id in (4,6,27) and @call_id>0 begin
                    if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
                    if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas


                    set @cal_manual =0

                    if @TipoCall = 0 begin --IN

                    select @calInicio=cal_Xfer,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas, @Camp=Inbound_id, @cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas, @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani ,@cal_whoHung=cal_whoHung
                            from ccCallsIN with(index(IX_ccCallsIn_6),nolock) where cal_id = @call_id and statusCall_id = 13

                    if @cal_tDialog = 0 and @tDialog >0  and @isLogout=1  begin
                        if @Fecha4<DATEADD(ms,( @sumCall+@tDialog+@cal_tNotas)*1000,@calInicio) begin
                        set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
                        if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
                        if @TipoStatusAge_id=6  begin
                            if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
                            else  set @tDialog=@tDialog-1
                        end
                        end
                        update ccCallsIN with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas,cal_tMoh=@tMusicHold where cal_id = @call_id and statusCall_id = 13
                    end
                    end
                    else begin --OUT
                    select @calInicio=cal_inicio,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,
                    @cam_id = cam_id,@cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas from ccoCallsOut where cal_id = @call_id
                    set @Camp=@cam_id

                    if @cal_tDialog = 0 and @tDialog>0 and @isLogout=1  begin
                        if @Fecha4<DATEADD(ms,( @sumCall+@tDialog+@cal_tNotas)*1000,@calInicio) begin
                        set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
                        if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
                        if @TipoStatusAge_id=6  begin
                            if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
                            else  set @tDialog=@tDialog-1
                        end
                        end

                        update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog, cal_tNotas=@cal_tNotas,cal_tMoh=@tMusicHold where cal_id = @call_id and statusCall_id = 13
                    end
                    else if @TipoStatusAge_id=4 and @cal_tDialog = 0 and @tDialog>0
                        update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog  where cal_id = @call_id
                    else if @TipoStatusAge_id=6 and @cal_tNotas>0 and (@cal_tNotaOri = 0 or @cal_tNotas>@cal_tNotaOri)
                        update ccoCallsOut with(rowlock) set cal_tNotas=@cal_tNotas where cal_id = @call_id
                    end

                    select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

                    if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1 and @cal_manual<>1 begin
                        insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
                    end

                    if @TipoStatusAge_id in(6,27)  and @isLogout=1  begin
                    --Valida que el agente no pudo guardar el status antes de desloguear
                    if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4) and @Fecha4 )
                        INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
                    end


                    end


                    if (@TipoStatusAge_id=4) begin-- 4 = Dialogo
                    declare @tStatus3 float, @Fecha3 datetime
                    select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia with(nolock) where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
                    insert into ccLogAgentesDia_Dialog (User_id,Cam_id,fecha_Calc_ms,tStatus_Dispo,fecha_Dispo,tStatus_Dialog,fecha_Dialog)
                    select @User_id, cam_id, datediff(ms, dateadd(ms, -(@tStatus3*1000), @Fecha3), dateadd(ms, -(@tStatus3*1000), @Fecha4)), @tStatus3, @Fecha3, @tStatus, @Fecha4
                    from cccampsagente where user_id = @User_id


                    ---Agregar callback en caso de este activo setting en campa?as o acd y tenga relacion de campa?a de encuesta
                    if @call_id>0 begin
                    if @TipoCall = 0 begin --IN

                        select @surveycamid = isnull(extend.SurveyCamId,0), @callBackSurveyClients = i.callBackSurveyClient  
                        from ccinbound i
                        left join ccInboundExtend extend on i.inbound_id = extend.inbound_id
                        where i.inbound_id = @inbound_id

                        if @surveycamId>0  and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
                            if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
                            begin
                                if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100
                                begin
                                insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
                                values(right((cast(@call_id as varchar) + '''' + @cal_Key),40),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()) )
                                end
                            end
                        end
                    end --@TipoCall = 0
                    else begin  --OUT



                        select @surveycamId = isnull(surveycamid,0),@callBackSurveyClients= callBackSurveyClient from cccamps where cam_id = @cam_id
                        select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono,@cal_whoHung=cal_whoHung
                        from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
                        where callout_id = @callout_id and statusCall_id = 13 and cal_id = @call_id

                        if @surveycamId>0 and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
                        if (select surveyPctg from ccCamps where cam_id = @surveycamId) >= rand() *100
                        begin
                            insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
                            values(right((cast(@call_id as varchar) + '''' + @cal_Key),40),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()))
                        end
                        end
                    end
                    end--@isTransferSurvey = 0 and @callout_id>0


                    end

                    if @TipoCall = 0 and @isLogout = 1  and @isTransferEngine = 1 begin --IN
                    declare @minimoDialogo tinyint 
                    select  @minimoDialogo = valor from ccSettings where setting_id = 13
                    if @cal_tDialog < @minimoDialogo
                        begin
                        --el status 18 es para llamada cortada con transferencia en Reminder
                        exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @call_id, @nStatus = 18
                    end

                    end 

                    if @TipoStatusAge_id =6  and @isLogout=0
                    begin
                    --Valida que el ccserver no haya guardado antes el status antes al desloguear
                    if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-10,@Fecha4) and @Fecha4 and tStatus = @tStatus+1)
                        INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )
                    end
                    else
                    INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )

                    if ( @TipoStatusAge_id = 2 )   -- 2 = No Disponible
                    begin
                    INSERT ccLogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha, IdCampEsp, Tipo )
                    VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4, @Camp, @TipoCall )

                    ---Para Agente RIA: OAYC
                    INSERT ccRIALogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha )
                    VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4 )
                    end

                    -- Actualiza para reporte de tiempos especiales (Boan)
                    if @Camp > 0
                    begin
                    if exists (select * from ccLogAgentesDia with(index(IX_ccLogAgentesDia_5),nolock)
                            where IdCampEsp = 0 and user_id = @User_id)
                        begin
                        update ccLogAgentesDia with(rowlock)
                        set IdCampEsp = @Camp, Tipo = @TipoCall
                        where IdCampEsp = 0
                        and user_id = @User_id
                        end

                    if exists (select * from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_4),nolock)
                            where IdCampEsp = 0 and user_id = @User_id)
                        begin
                        update ccLogAgentesNotReady with(rowlock)
                        set IdCampEsp = @Camp, Tipo = @TipoCall
                        where IdCampEsp = 0
                        and user_id = @User_id
                        end
                    end

                    if ( @TipoStatusAge_id = 34  and @call_id > 0) -- Dialogo WhatsApp
                    begin
                        if @TipoCall=0 begin
                            update ccWhatsAppConversations set tChatting = (tChatting + @tStatus) where conversationId = @call_id;
                            set @Camp = (select inboundId from ccWhatsAppConversations  where conversationId = @call_id);
                            EXEC ccsp_WhatsAppInformation @Option = 2, @InboundId = @Camp
                        end
                        else begin
                            update ccWhatsAppConversationsOut set tChatting = (tChatting + @tStatus) where conversationId = @call_id;
                            set @Camp = (select camId from ccWhatsAppConversationsOut  where conversationId = @call_id);
                            EXEC ccsp_WhatsAppInformationOut @Option = 2, @camId = @Camp
                        end
                    end
                    end'
        EXEC(@sql);

        set @process = 'Se agrega cast en ultimo select para ahora el tipo de dato smallint'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminSettings]
                    AS
                    BEGIN
                        CREATE TABLE #Settings (setting_id tinyint , valor varchar(300), ip_host tinyint)

                        INSERT INTO #Settings 
                        EXEC  ccsp_RIAADMLoadSettings @ip_admin =''''

                        INSERT INTO #Settings (setting_id,valor) 
                        SELECT setting_id, valor 
                        FROM ccSettings
                        WHERE setting_id in(160, 199, 53, 63, 64)
                     
                        SELECT distinct cast(setting_id as smallint) setting_id, valor from #Settings ORDER BY setting_id 

                        DROP TABLE #Settings;
                    END'
        EXEC(@sql);

        -----------------------------------------------------BEGIN Ivan Martin ----------------------------------------------------------------


		-----------------------------------------------------END KR102000 Callback automatico para llamadas con encuestas asignadas ----------------------------------------------------------------

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
