/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:
Date: 2024/06/13
Description: K064000
Database: CCenterRia
Required version: 126.6
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
SET @version = 126 --**********actualizar a 124 sin fix
SET @versionfix = 11
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
    	
-------------------------------------------------- Begin David Medina -----------------------------------------------------------------------------------
--------------------------------------------------------- DDL -------------------------------------------------------------------------------------------
---------------------------------------------------- k064001|k064003 ------------------------------------------------------------------------------------
-------------------------------------------------------- Tablas -----------------------------------------------------------------------------------------
SET @process = 'k064001|k064003 se añade columna callWhileChat a tabla ccRIACat_Areas'
SET @sql = '
	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''callWhileChat'' AND Object_ID = Object_ID(N''dbo.ccRIACat_Areas''))
	BEGIN
		ALTER TABLE ccRIACat_Areas ADD callWhileChat BIT NOT NULL DEFAULT 0;
	END'
EXEC(@sql)

SET @process = 'k064001|k064003 se añade columna callWhileEmail a tabla ccRIACat_Areas'
SET @sql = '
	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''callWhileEmail'' AND Object_ID = Object_ID(N''dbo.ccRIACat_Areas''))
	BEGIN
		ALTER TABLE ccRIACat_Areas ADD callWhileEmail BIT NOT NULL DEFAULT 0;
	END'
EXEC(@sql)

SET @process = 'k064001|k064003 se añade columna callWhileTwitter a tabla ccRIACat_Areas'
SET @sql = '
	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''callWhileTwitter'' AND Object_ID = Object_ID(N''dbo.ccRIACat_Areas''))
	BEGIN
		ALTER TABLE ccRIACat_Areas ADD callWhileTwitter BIT NOT NULL DEFAULT 0;
	END'
EXEC(@sql)

SET @process = 'k064001|k064003 se añade columna callWhileWhats a tabla ccRIACat_Areas'
SET @sql = '
	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N''callWhileWhats'' AND Object_ID = Object_ID(N''dbo.ccRIACat_Areas''))
	BEGIN
		ALTER TABLE ccRIACat_Areas ADD callWhileWhats BIT NOT NULL DEFAULT 0;
	END'
EXEC(@sql)

---------------------------------------------------------- SPs ------------------------------------------------------------------------------------------
SET @process = 'K064001|K064003 se modifica SP ccsp_GalateaAreas añadiendo variables @maxWhats @callWhileChat @callWhileEmail @callWhileTwitter @callWhileWhats 
		y modificando flujos en lectura, escritura y actualización de datos añadiendo esas variables'
SET @sql = '
				ALTER procedure [dbo].[ccsp_GalateaAreas] 
		@option int = 2,
		@IDArea smallint = 0,
		@Descripcion varchar(40) = NULL,
		@maxMails smallint = 3,
		@maxChats smallint = 3,
		@maxTweets smallint = 3,
		@maxWhats smallint = 3,
		@callWhileChat bit = 0,
		@callWhileEmail bit = 0,
		@callWhileTwitter bit = 0,
		@callWhileWhats bit = 0,
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
				a.maxWhats Whats,
				a.callWhileChat callChat,
				a.callWhileEmail callEmail,
				a.callWhileTwitter callTwitter,
				a.callWhileWhats callWhats,
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
				maxWhats tinyint ,
				callWhileChat bit, 
				callWhileEmail bit,
				callWhileTwitter bit,
				callWhileWhats bit,
				users int,
				admins int,
				camps int,
				acds int,
				maxTweets tinyint,
				toolsTransfer tinyint
			)
			insert into #Areas
			EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@maxWhats=@maxWhats,@callWhileChat=@callWhileChat,@callWhileEmail=@callWhileEmail,@callWhileTwitter=@callWhileTwitter,@callWhileWhats=@callWhileWhats,@defCampaing=@defCampaing, @isKolob=1
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
				@maxWhats=@maxWhats,
				@callWhileChat=@callWhileChat,
				@callWhileEmail=@callWhileEmail,
				@callWhileTwitter=@callWhileTwitter,
				@callWhileWhats=@callWhileWhats,
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

					update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),maxWhats=isnull(@maxWhats,maxWhats),callWhileChat=isnull(@callWhileChat,callWhileChat),callWhileEmail=isnull(@callWhileEmail,callWhileEmail),callWhileTwitter=isnull(@callWhileTwitter,callWhileTwitter),callWhileWhats=isnull(@callWhileWhats,callWhileWhats),defCampaing=isnull(@defCampaing, 0), ToolsTransfer=case when @toolsTransfer = 3 then ToolsTransfer else @toolsTransfer end where IDArea=@IDArea

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
								when at.identifierInfo = ''T&SET_CALL_WHILE_CHAT'' then 
									case 
										when @callWhileChat = 1 then ''COMMON_ENABLED''
										else ''COMMON_DISABLED'' end
								when at.identifierInfo = ''T&SET_CALL_WHILE_EMAIL'' then 
									case 
										when @callWhileEmail = 1 then ''COMMON_ENABLED''
											else ''COMMON_DISABLED'' end
								when at.identifierInfo = ''T&SET_CALL_WHILE_TWITTER'' then 
									case 
										when @callWhileTwitter = 1 then ''COMMON_ENABLED''
											else ''COMMON_DISABLED'' end
								when at.identifierInfo = ''T&SET_CALL_WHILE_WHATS'' then 
									case 
										when @callWhileWhats = 1 then ''COMMON_ENABLED''
											else ''COMMON_DISABLED'' end
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
EXEC(@sql)

SET @process = 'K064001|K064003 se modifica SP ccsp_RIA_ABCAreas añadiendo variables @maxWhats @callWhileChat @callWhileEmail @callWhileTwitter @callWhileWhats 
				y modificando flujos en lectura, escritura y actualización de datos añadiendo esas variables'
SET @sql = '
	ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAreas]
	@option smallint,
	@IDArea smallint,
	@Descripcion varchar(40),
	@maxMails smallint = 3, 
	@maxChats smallint = 3,
	@maxTweets smallint = 3,
	@maxWhats smallint = 3,
	@callWhileChat bit = 0,
	@callWhileEmail bit = 0,
	@callWhileTwitter bit = 0,
	@callWhileWhats bit = 0,
	@defCampaing smallint = NULL, 
	@isKolob bit = 0,
	@toolsTransfer bit = 0
	AS

	set nocount on



	if @option = 1 begin --Selected Area
	 Select a.IDArea, AreaName, isnull(a.maxChats,0) as maxChats, isnull(maxMails,3) maxMails,
	 isnull(a.maxWhats,3) as maxWhats, a.callWhileChat, 
	 a.callWhileEmail, a.callWhileTwitter, a.callWhileWhats,
	 isnull(users,0) users, isnull(admins,0) admins, 
	 isnull(camps,0) camps, isnull(acds,0) acds  ,isnull(a.maxTweets,3) as maxTweets , ToolsTransfer
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
		Insert into ccRIACat_Areas (AreaName,maxMails,maxChats,maxTweets,maxWhats,callWhileChat,callWhileEmail,callWhileTwitter,callWhileWhats,defCampaing,CreateDate,ToolsTransfer) values (@Descripcion,@maxMails,@maxChats,@maxTweets,@maxWhats,@callWhileChat,@callWhileEmail,@callWhileTwitter,@callWhileWhats,@defCampaing,Getdate(),@toolsTransfer)
		select 1 as result, scope_identity() as idAreas--, Area Insertada
		return(0)
	end
	else if @option=3 begin--Update Area
		if not exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
			Update ccRIACat_Areas set AreaName=@Descripcion,maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets,maxWhats=@maxWhats,callWhileChat=@callWhileChat,callWhileEmail=@callWhileEmail,callWhileTwitter=@callWhileTwitter,callWhileWhats=@callWhileWhats,defCampaing=@defCampaing where IDArea=@IDArea
		else
			Update ccRIACat_Areas set maxMails=@maxMails,maxChats=@maxChats,maxTweets=@maxTweets,maxWhats=@maxWhats,callWhileChat=@callWhileChat,callWhileEmail=@callWhileEmail,callWhileTwitter=@callWhileTwitter,callWhileWhats=@callWhileWhats,defCampaing=@defCampaing where IDArea=@IDArea

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
	 end'
EXEC(@sql)

--------------------------------------------------------- DML -------------------------------------------------------------------------------------------
------------------------------------------------------- k064033 -----------------------------------------------------------------------------------------
SET @process = 'K064033-Setting realizar marcación manual teniendo conversación en diálogo'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM ccSettings2 WHERE setting_id = 260)
	BEGIN
		INSERT INTO ccSettings2 
			(setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate) 
			VALUES (260, ''1'', ''Permite realizar marcación manual estando en diálogo o programar la llamada para que sea realizada cuando el agente pase a estado disponible'', 1, ''AGT'', ''0 Desactivado|1 Habilitado'', ''Allows manual dialing while in dialogue with some unified media or scheduling the call to be made when the agent becomes available'', 1, ''^[0-1]$'');
	END'
EXEC(@sql)
---------------------------------------------------- k064001|k064003 -------------------------------------------------------------------------------------
SET @process = 'Se insertan identificadores de relación en tabla relationTableColumnIdentifiers'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM relationTableColumnIdentifiers WHERE colunName = ''maxWhats'')
	BEGIN
		INSERT INTO relationTableColumnIdentifiers(identifiers, tableName, colunName)
		VALUES (''T&SET_MAX_WHATS'', ''ccRIACat_Areas'', ''maxWhats'');
	END'
EXEC(@sql)

SET @process = 'Se insertan identificadores de relación en tabla relationTableColumnIdentifiers'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM relationTableColumnIdentifiers WHERE colunName = ''callWhileChat'')
	BEGIN
		INSERT INTO relationTableColumnIdentifiers(identifiers, tableName, colunName)
		VALUES (''T&SET_CALL_WHILE_CHAT'', ''ccRIACat_Areas'', ''callWhileChat'');
	END'
EXEC(@sql)

SET @process = 'Se insertan identificadores de relación en tabla relationTableColumnIdentifiers'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM relationTableColumnIdentifiers WHERE colunName = ''callWhileEmail'')
	BEGIN
		INSERT INTO relationTableColumnIdentifiers(identifiers, tableName, colunName)
		VALUES (''T&SET_CALL_WHILE_EMAIL'', ''ccRIACat_Areas'', ''callWhileEmail'');
	END'
EXEC(@sql)

SET @process = 'Se insertan identificadores de relación en tabla relationTableColumnIdentifiers'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM relationTableColumnIdentifiers WHERE colunName = ''callWhileTwitter'')
	BEGIN
		INSERT INTO relationTableColumnIdentifiers(identifiers, tableName, colunName)
		VALUES (''T&SET_CALL_WHILE_TWITTER'', ''ccRIACat_Areas'', ''callWhileTwitter'');
	END'
EXEC(@sql)

SET @process = 'Se insertan identificadores de relación en tabla relationTableColumnIdentifiers'
SET @sql = '
	IF NOT EXISTS (SELECT 1 FROM relationTableColumnIdentifiers WHERE colunName = ''callWhileWhats'')
	BEGIN
		INSERT INTO relationTableColumnIdentifiers(identifiers, tableName, colunName)
		VALUES (''T&SET_CALL_WHILE_WHATS'', ''ccRIACat_Areas'', ''callWhileWhats'');
	END'
EXEC(@sql)

SET @process = 'Se insertan identificadores para mostrar etiquetas en historial de actividad al editar areas'
SET @sql = '	
	IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''T&SET_CALL_WHILE_CHAT'')
	BEGIN
		insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
		values (''T&SET_CALL_WHILE_CHAT'', ''Aceptar llamadas en estado de diálogo de chat'', ''Accept calls on engaged status (chat)'', ''Aceitar chamadas no status de diálogo de chat'')
	END'
EXEC(@sql)

SET @process = 'Se insertan identificadores para mostrar etiquetas en historial de actividad al editar areas'
SET @sql = '	
	IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''T&SET_CALL_WHILE_EMAIL'')
	BEGIN
		insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
		values (''T&SET_CALL_WHILE_EMAIL'', ''Aceptar llamadas en estado de diálogo de correo'', ''Accept calls on engaged status (email)'', ''Aceitar chamadas no status de diálogo de e-mail'')
	END'
EXEC(@sql)

SET @process = 'Se insertan identificadores para mostrar etiquetas en historial de actividad al editar areas'
SET @sql = '	
	IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''T&SET_CALL_WHILE_TWITTER'')
	BEGIN
		insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
		values (''T&SET_CALL_WHILE_TWITTER'', ''Aceptar llamadas en estado de diálogo de Twitter'', ''Accept calls on engaged status (Twitter)'', ''Aceitar chamadas no status de diálogo de Twitter'')
	END'
EXEC(@sql)

SET @process = 'Se insertan identificadores para mostrar etiquetas en historial de actividad al editar areas'
SET @sql = '	
	IF NOT EXISTS (SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''T&SET_CALL_WHILE_WHATS'')
	BEGIN
		insert into ccGalateaIdentifiers (Description, TagEs, TagEn, TagPt) 
		values (''T&SET_CALL_WHILE_WHATS'', ''Aceptar llamadas en estado de diálogo de WhatsApp'', ''Accept calls on engaged status (WhatsApp)'', ''Aceitar chamadas no status de diálogo de WhatsApp'')
	END'
EXEC(@sql)
------------------------------------------------------ End David Medina ---------------------------------------------------------------------------------

-------------------------------------------------------BEGIN MACL---------------------------------------------------
SET @process = 'K064010 - Se elimina sp ccsp_ValidateWrapUp en caso de existir'
SET @sql = 'IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_ValidateWrapUp'') 
BEGIN
	DROP PROCEDURE dbo.ccsp_ValidateWrapUp
END'
EXEC(@sql)

SET @process = 'K064010 - Se crea sp ccsp_ValidateWrapUp para validar el setting 99'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_ValidateWrapUp] @callId INT AS
BEGIN
	DECLARE @cam_id int;
	DECLARE @valor VARCHAR(max)
	select @valor = valor from ccSettings where setting_id = 99

	if @valor = 1
	BEGIN
		select @cam_id = cam_id from ccoCallsOut where cal_manual = 1 and cal_id = @callId
		SELECT cam_ShowCalifWnd as showWrapUp, cam_tnotas as wrapUpTime, cam_id from ccCamps where @cam_id = cam_id;
	END
END'
EXEC(@sql)
--------------------------------------------------------END MACL----------------------------------------------------
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
