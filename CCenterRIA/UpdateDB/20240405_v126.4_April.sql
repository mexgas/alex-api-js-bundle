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
SET @version = 126 --**********actualizar a 124 sin fix
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

        ----------------------------------------------------- BEGIN KR123000 ----------------------------------------------------------------

SET @process = 'KR123000 Se creo la tabla tipoReadyAuxiliar para guardar los auxiliares'
SET @sql = 'if not exists (select * from sys.tables where name = N''TipoReadyAuxiliar'')
				begin
				CREATE TABLE [dbo].[TipoReadyAuxiliar](
				[TipoReadyAuxiliar_Id] [int] NOT NULL,
				[Description] [varchar](max) NOT NULL,
				[Color] [int] NULL,
				[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
				[AdminPasswordRequired] [bit] NULL,
				[StatusAux] [bit] NULL,
			 CONSTRAINT [PK_TipoReadyAuxiliar_Id] PRIMARY KEY CLUSTERED 
			(
				[TipoReadyAuxiliar_Id] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

			ALTER TABLE [dbo].[TipoReadyAuxiliar] ADD  CONSTRAINT [MSmerge_df_rowguid_04AC7A2EC00F44B4B3AD3DE5C4FA9CFC]  DEFAULT (newsequentialid()) FOR [rowguid]
		end'

EXEC(@sql)

SET @process = 'KR123000 Se creo la tabla tipoReadyAuxiliar para guardar los auxiliares'
SET @sql = 'if not exists (select * from sys.columns where name = N''AdminPasswordRequired'' and Object_ID = Object_ID(N''TipoReadyAuxiliar''))
		begin
				ALTER TABLE TipoReadyAuxiliar
				ADD AdminPasswordRequired BIT,
				StatusAux BIT;

				ALTER TABLE [dbo].[TipoReadyAuxiliar] 
				ADD CONSTRAINT PK_TipoReadyAuxiliar_Id PRIMARY KEY (TipoReadyAuxiliar_Id);
		end'

EXEC(@sql)

SET @process = 'KR123000 Se creo la tabla tipoReadyAuxiliar para guardar los auxiliares'
SET @sql = '
if not exists (select * from sys.columns where name = N''Color'' and Object_ID = Object_ID(N''TipoReadyAuxiliar''))
		begin
				ALTER TABLE TipoReadyAuxiliar
				ALTER COLUMN Color INT NULL;
		end'

EXEC(@sql)
------- Cambios en ccsp_GalateaDeleteCampaignAndACD para eliminacion de relaciones entre auxiliares y casmpañas  -------

	set @process = 'se agregarn dos deletes para borrar las relaciones entre auxiliares y campañas para tablas ccCampaignsOut_Aux y ccCampaignsIn_Aux'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaDeleteCampaignAndACD]
            @userId           SMALLINT,
            @DeleteCamId      VARCHAR(MAX),
            @DeleteACDGroupId VARCHAR(MAX),
            @moduleId         SMALLINT = 49
        AS
        BEGIN

            IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
				SELECT value As DeleteCamId, c.IDArea AS IDAreaCamp, 1 AS CampTypeCamp, ISNULL(wg.IDWG,0) as IDWG, ISNULL(c.CampType, 0) AS MediaType
                INTO #CampsDelete
                FROM fn_RIASplitDelimited(@DeleteCamId, '','') a
                inner join ccCamps c on  a.value = c.cam_id and c.IDArea IS NOT NULL
                left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=1
            IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
				SELECT value As DeleteACDId, c.IDArea AS IDAreaACD, 0 AS CampTypeACD, ISNULL(wg.IDWG,0) as IDWG, cast(ISNULL(chat, 0) as int) AS MediaType
                INTO #ACDDelete
                FROM fn_RIASplitDelimited(@DeleteACDGroupId, '','') a
                inner join ccInbound c on  a.value = c.Inbound_id and c.IDArea IS NOT NULL
                left join ccRIACampEspWG wg on a.Value = wg.IdCampEsp and wg.Tipo=0

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

				--Borra las la relaciónd de auxiliares con campañas de salida 
				delete from ccCampaignsOut_Aux where cam_id in (select DeleteCamId from #CampsDelete)

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

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
				SELECT A.AreaName, GETDATE(), (SELECT [Login] FROM ccUsers WHERE User_id = @userid),
				CASE 
					WHEN CampType = 6 THEN 45
					WHEN CampType = 5 THEN 47
					WHEN CampType = 4 THEN 49
					WHEN CampType = 7 THEN 51
				ELSE 43 END, 
				3, 
				'''',
				'''', 
				c.cam_descripcion
				FROM ccRIACat_Areas A INNER JOIN ccCamps c on A.IDArea = c.IDArea
				where c.cam_id in (select DeleteCamId from #CampsDelete)

                Update ccCamps set IDArea = null where cam_id in (select DeleteCamId from #CampsDelete)
        
                update contactMeanOut set name = '''', conexionInfo = '''', connUser = '''', isActive = 0
                where camp_id in (SELECT DeleteCamId FROM #CampsDelete) and meanContactTypeId=5
        
                update ccWhatsAppNumbers set camp_id = 0 where camp_id in (select DeleteCamId from #CampsDelete)
        

            END
            IF datalength(@DeleteACDGroupId) > 0
                BEGIN

				--Borra las la relaciónd de auxiliares con campañas de entrada 
				delete from ccCampaignsIn_Aux where Inbound_id in (select DeleteACDId from #ACDDelete) 

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
                delete ccInboundDnis where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

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

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
				SELECT a.AreaName, GETDATE(), (SELECT [Login] FROM ccUsers WHERE User_id = @userId),
				CASE 
					WHEN chat = 5 THEN 41
					WHEN chat = 1 THEN 65
					ELSE 61 END, 
				3, 
				'''', 
				'''', 
				i.descripcion
				FROM ccRIACat_Areas a inner join ccInbound i on a.IDArea = i.IDArea
				WHERE i.Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                Update ccInbound set IDArea = null, status = 0 where Inbound_id in (SELECT DeleteACDId FROM #ACDDelete)

                if exists(select * from ContactMeanIn where meanContactTypeId=2 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo twitter asociado al ACD
                    begin
                        update ContactMeanIn set name = '''', conexionInfo = ''usuarioID|token|tokenSecret|1|0'', connUser = '''', isActive = 0
                        where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=2
                end
                if exists(select * from ContactMeanIn where meanContactTypeId=1 and inboundId in (SELECT DeleteACDId FROM #ACDDelete))--Si encuentra un registro en contactMeanIn de tipo email asociado al ACD
                    begin
                        update ContactMeanIn set name = '''', conexionInfo = '''', connUser = '''', connpass='''', isActive = 0 where inboundId in (SELECT DeleteACDId FROM #ACDDelete) and meanContactTypeId=1
                end
                update ccinbound set chatDomain = '''' where inbound_id in (SELECT DeleteACDId FROM #ACDDelete)--para desasociar el dominio del chat

                if exists (SELECT inboundId FROM contactMeanIn WHERE inboundId in (select DeleteACDId from #ACDDelete))
                    begin
                        update contactMeanIn set isActive = 0 where inboundId in (select DeleteACDId from #ACDDelete)
                end            
                update ccWhatsAppNumbers set inboundId = 0 where inboundId in (select DeleteACDId from #ACDDelete)
        
            END

            IF datalength(@DeleteCamId) > 0
                Insert into ccRIALog Select * from #CampLog
            IF datalength(@DeleteACDGroupId) > 0
                Insert into ccRIALog Select * from #ACDLog

            SELECT DeleteCamId AS DeleteId,IDAreaCamp AS IDArea,CampTypeCamp AS CampType,''1'' AS Result, cast(IDWG as smallint) IDWG, MediaType FROM #CampsDelete
            UNION
            SELECT DeleteACDId,IDAreaACD,CampTypeACD,''1'' AS Result, cast(IDWG as smallint) IDWG, MediaType FROM #ACDDelete
            IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
            IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
            IF OBJECT_ID(''tempdb..#CampLog'') IS NOT NULL DROP TABLE #CampLog
        END'
	EXEC(@sql)

-------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------- Begin Ulises  ------------------------------------------------------------

	set @process = ''
	set @sql = 'IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ''ccLogAgentesAuxiliarReady'')
	BEGIN
		CREATE TABLE [dbo].[ccLogAgentesAuxiliarReady]
        (
              [User_id] SMALLINT NOT NULL
            , [TipoAuxiliarReady_id] SMALLINT NOT NULL DEFAULT((0))
            , [tStatus] FLOAT NULL
            , [fecha] DATETIME NULL DEFAULT(getdate())
        )
	END'
	EXEC(@sql)

	set @process = 'Se agrega el estatus Disponible Auxiliar'
	set @sql = 'if not exists (select 1 from ccTipoStatusAgente where TipoStatusAge_id = 37)
	begin
		insert into ccTipoStatusAgente values (37, ''Disponible auxiliar'')
	end'
	EXEC(@sql)

----------------------------------------------------- End Ulises  ------------------------------------------------------------		

SET @process = 'KR123000 Se creo la tabla ccAdmin_Aux para la relación del auxiliar con el administrador'
SET @sql = '
if not exists (select * from sys.tables where name = N''ccAdmin_Aux'')
begin
CREATE TABLE ccAdmin_Aux (
    User_id SMALLINT,
    TipoReadyAuxiliar_Id INT,
    FOREIGN KEY (User_id) REFERENCES ccUsers(User_id) ON DELETE CASCADE,
    FOREIGN KEY (TipoReadyAuxiliar_Id) REFERENCES TipoReadyAuxiliar(TipoReadyAuxiliar_Id),
    PRIMARY KEY (User_id, TipoReadyAuxiliar_Id)
);
end'

EXEC(@sql)

SET @process = 'KR123000 Se creo la tabla ccCampaignsIn_AUx para la relación del auxiliar con la campaña de entrada'
SET @sql = '
if not exists (select * from sys.tables where name = N''ccCampaignsIn_Aux'')
begin
create table ccCampaignsIn_Aux(
    Inbound_id SMALLINT,
    TipoReadyAuxiliar_Id INT,
    FOREIGN KEY (Inbound_id) REFERENCES ccInbound(Inbound_id),
    FOREIGN KEY (TipoReadyAuxiliar_Id) REFERENCES TipoReadyAuxiliar(TipoReadyAuxiliar_Id),
    PRIMARY KEY (Inbound_id, TipoReadyAuxiliar_Id)
); 
end'

EXEC(@sql)

SET @process = 'KR123000  Se creo la tabla ccCampaignsOut_Aux para la relación del auxiliar con la campaña de salida'
SET @sql = '
if not exists (select * from sys.tables where name = N''ccCampaignsOut_Aux'')
begin
create table ccCampaignsOut_Aux(
    cam_id SMALLINT,
    TipoReadyAuxiliar_Id INT,
    FOREIGN KEY (cam_id) REFERENCES ccCamps(cam_id),
    FOREIGN KEY (TipoReadyAuxiliar_Id) REFERENCES TipoReadyAuxiliar(TipoReadyAuxiliar_Id),
    PRIMARY KEY (cam_id, TipoReadyAuxiliar_Id)
);
end'

EXEC(@sql)

-- KR1230022 ----
set @process = 'KR123022 - Habilitar y deshabilitar uso de auxiliares al agente alter table ccusers add column AuxiliaryRestricted'
set @sql = 'if not exists (select * from sys.columns where name = N''AuxiliaryRestricted'' and Object_ID = Object_ID(N''ccusers''))
begin
	alter table ccusers add AuxiliaryRestricted bit not null DEFAULT(0)
end'
EXEC(@sql)


set @process = 'KR123022 - Habilitar y deshabilitar uso de auxiliares al agente delete ccsp_RecycleByDispositionOrResult'
set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_RIA_ABCAgents'')
        BEGIN
            DROP PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
        END'
EXEC(@sql)


SET @process = 'KR123022 - Habilitar y deshabilitar uso de auxiliares al agente action 10 added to update AuxiliaryRestricted column'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
    @option smallint,
    @UserId int,
    @Login varchar(40)='''',
    @Nombres varchar(25)=null,
    @ApellidoPaterno varchar(25)='''',
    @ApellidoMaterno varchar(25)='''',
    @Password varchar(33)='''',
    @Sexo bit=null,
    @canChangeStatus bit=null,
    @AreaId int=null,
    @UserType tinyint=1,
    @IDWG int=0,
    @DeleteUsers int=1,
    @inOut int=null,
    @IDCampEsp int=null,
    @multipleUsers varchar(1000)=null
    as
    set nocount on

    if @option=0--All Users
      begin
      select User_id,Login,ISnull(AREas.AreaName,'''')as AreaName

    from ccusers as users with(nolock)
        left join ccRIACat_Areas as areas with(nolock)
        on users.IDArea=areas.IDArea
      return(0)
      end

    if @option=1--selected User
      begin
      select User_id,Login,Nombres,isnull(apellidoPaterno,''''),
        isnull(ApellidoMaterno,''''),Sexo,canChangeStatus,isnull(IDArea,0),tipouser_id
      from ccusers where User_id=@UserId
      order by IDArea,Nombres,ApellidoPaterno,User_id
      return(0)
      end

    if @option=2--insert
      begin
      if exists(select Login from ccUsers where Login=@Login)
        begin
        select -1--,''Login en Uso''
        return(0)
        end

      if exists(select Login from ccUsers_Consulta where Login = @Login)
      begin
        select -4 -- ''Login habia estado en Uso''
        return(0)
      end

      if exists(select Nombres from ccUsers where Nombres=@Nombres
      and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
        begin
        select -2--,''Nombre en Uso''
        return(0)
        end

    IF( select isnull(max(user_id),0) from ccusers) > 32700
    BEGIN
      set @UserId = null
      SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID
      FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
      LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
      INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
      FROM ccusers) AS w ON w.recID = d.recID

      if @UserId is null
      begin
        select -2--insert Error
        return(0)
      end

      set identity_insert ccusers on
      insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
        Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
      select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
        1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
      set identity_insert ccusers off

      delete ccMenuUser where id_User = @UserId
      delete ccRIAUserRole where user_id = @UserId

      exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

    END
    ELSE
    BEGIN
      insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
        Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
      select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
        1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end

      if @@rowcount=1
        select @UserId=scope_identity()
      else
        begin
        select -2--insert Error
        return(0)
        end
    END
      insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
      insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
      insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
      --Menu para roles RepotsRia
      exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

      select @UserId,'' Usuario '' + @Login + '' Dado de Alta''
      return(0)
      end

    if @option=3--Update
      begin
      if @Login='''' and @Password <> ''''
        begin
        Update ccUsers set Password=@Password, LastPasswordChange = GETDATE() where User_id=@UserId
        return(0)
        end

      Update ccUsers
      set Login= case when @Login <> '''' then @Login else Login end,
      Nombres=@Nombres,
      ApellidoPaterno=@ApellidoPaterno,ApellidoMaterno=@ApellidoMaterno,
      Password=case when @Password <> '''' then @Password else Password end,
      Sexo=@Sexo,canChangeStatus=@canChangeStatus
      where User_id=@UserId
      return(0)
      end

    if @option=4--Delete
      begin
      delete from ccSkills where user_id =@UserId
      delete from ccMenu_ViewsUser where user_id =@UserId
      delete from dbo.ccRIAWorkGroupUsers where user_id =@UserId
delete from ccRIAAgentsPermissions where AgentId=@UserId
      delete from ccUsers where user_id=@UserId
      return(0)
      end

    declare @Type tinyint, @users int,@sql varchar(8000), @NinOut nvarchar(10)

    if @option=5--insert Agente-Supervisor in WorkGroup
      begin
      select @Type=TipoUser_id from ccUsers where User_id=@UserId

      if @Type not in(1,2,6)
        return(0)

      if @Type=1 and((select count(User_id)from ccRIAWorkGroupUsers where User_id=@UserId)>=(select valor from ccSettings where setting_id=63))
        begin
        select 3
        return(0)
        end

      if exists(select @UserId from ccRIAWorkGroupUsers where User_id=@UserId and IDWG=@IDWG)
        begin
        select 1
        return(0)
        end

      insert into ccRIAWorkGroupUsers(IDWG,User_id)values(@IDWG,@UserId)

      if @Type=1
        begin

        if @IDWG is null or @IDWG = 0
          begin
          select 28
          return(0)
          end
        insert into cccampsAgente(user_id,cam_id,prioridad,skill,IDWG)

        select @UserId,idCampEsp,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
        from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
          and idCampEsp not in(select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

        insert into ccinboundAgentes(User_id,Inbound_id,cli_id,prioridad,skill,IDWG)
        select @UserId,idCampEsp,0,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
        from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
          and idCampEsp not in(select inbound_id from ccinboundAgentes where user_id=@UserId and IDWG=@IDWG)

        return(0)
        end

    --else @Type=2 or @Type=6--Supervisor
      insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
      select @UserId,idCampEsp,0,@IDWG
      from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
        and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

      insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
      select @UserId,idCampEsp,1,@IDWG
      from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
        and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
      return(0)
      end

    if @option=6--Delete Agent-Supervisor from WorkGroup
      begin
      if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)=0
        select @UserId = @multipleUsers

            else if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)>0
              select @UserId = cast(substring(@multipleUsers, 1,
              CHARINDEX('','', @multipleUsers)-1) as int)

        select @Type=case when @UserType <> 0 then @UserType else TipoUser_id end,
        @multipleUsers=isnull(@multipleUsers,cast(@Userid as varchar(10)))
      from ccUsers where User_id=@UserId

      Declare @sqlDelete nvarchar(4000)
      if @Type in(1,2,6)--1:Agente / 2,6:Supervisor
        begin
        set @sqlDelete=N''Delete from '' + case @Type when 1 then ''cccampsagente where '' else ''ccSupervisorCam where tipo=0 and '' end
        + ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
        + '' Delete from '' + case @Type when 1 then ''ccinboundagentes where '' else ''ccSupervisorCam where tipo=1 and '' end
        + ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
        exec(@sqlDelete)
        end

      if isnull(@UserId, 0) = 0 or isnull(@multipleUsers, ''0'') = ''0''
        begin
        select -9 -- Se ingreso mal el id del usuario
        --delete ccinboundagentes where idwg=@IDWG
        --delete cccampsagente where idwg=@IDWG
        --delete ccSupervisorCam where idwg=@IDWG
        end

      if @DeleteUsers=1
        Delete ccRIAWorkGroupUsers where IDWG=@IDWG and User_id=@UserId

      return(0)
      end

    if @option=7--Delete Agent from WorkGroup
      begin
      select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end
      set @sql=''delete '' + case @NinOut when ''1'' then ''ccCampsAgente'' else ''ccInboundAgentes'' end +
        '' where user_id in('' + isnull(@multipleUsers, ''0'') +'') and '' + case @NinOut when ''1'' then ''cam_id'' else ''inbound_id'' end +
        ''='' + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' + cast(@IDWG as varchar(10)) +
        '' delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
      exec(@sql)
      --update preview permission
      set @sql = ''update ccusers set 
          AllowChangeDialingMode=(case when assigned is null then 0 else 1 end),
          DialingMode=(case when assigned is null then 0 else 1 end) from ccusers us (nolock) left join (
          select count(1) assigned,user_id from ccCampsAgente ca (nolock) join ccCamps cc (nolock) on cc.cam_id=ca.cam_id
          where progDial=3 and user_id in ('' + isnull(@multipleUsers, ''0'') +'') group by user_id)c on us.User_id=c.user_id
          where us.user_id in ('' + isnull(@multipleUsers, ''0'') +'')''
      exec(@sql)
    return(0)
      end

    if @option=8--Delete Supervisor from WorkGroup
      begin
      select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end

            set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and user_id in('' + isnull(@multipleUsers, ''0'') + '') and cam_id=''
              + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' +cast(@IDWG as varchar(10)) + ''
              delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
            exec(@sql)

      set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and cam_id='' + cast(@IDCampEsp as varchar(10)) + ''and '' +
        ''user_id in ('' + isnull(@multipleUsers, ''0'') + '') and IDWG='' + cast(@IDWG as varchar(10))
      exec(@sql)
      return(0)
      end

    if @option=9
      begin
      update ccusers set NotReadyRestricted=@canChangeStatus where [User_id]=@UserId
	  SELECT Login from ccUsers where [User_id]=@UserId
	  RETURN(0)
	END
    IF @option = 10
	BEGIN	
		UPDATE dbo.ccUsers SET AuxiliaryRestricted=@canChangeStatus WHERE [User_id] = @UserId
		SELECT Login from ccUsers where [User_id]=@UserId
		 RETURN(0)
	END
set nocount off';

EXEC(@sql);

set @process = 'KR123006 - Auxiliar - Detalles Dashboard delete ccsp_GetAuxiliaryReadyHistoryToAdmin '
set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_GetAuxiliaryReadyHistoryToAdmin'')
        BEGIN
            DROP PROCEDURE [dbo].[ccsp_GetAuxiliaryReadyHistoryToAdmin]
        END'
EXEC(@sql)


SET @process = 'KR123006 - Auxiliar - Detalles Dashboard getting historical custom ready'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GetAuxiliaryReadyHistoryToAdmin]
		@action INT = 0,
		@userId INT = 0
		AS
		SET NOCOUNT ON
		-- Para horarios depues de las 12 de la noche
		DECLARE @fStart DATETIME, @fEnd DATETIME
		DECLARE @inicioTurno INT, @AcumTime INT
		DECLARE @fecha SMALLDATETIME

		SET @inicioTurno = 2 --Cambio de dia a las 2 de la mañana
		SET @fecha = getdate()

		IF datepart(hh,@fecha)>@inicioTurno-1
		 BEGIN	
			SET @fStart=CONVERT(DATETIME, CONVERT(VARCHAR(11), @fecha, 121) + CAST(@inicioTurno AS VARCHAR) +'':00'', 121)
			SET @fEnd=DATEADD(d,1,@fstart)
		 END

		ELSE
		 BEGIN
			SET @fEnd=CONVERT(DATETIME, CONVERT(VARCHAR(11), @fecha, 121) + CAST(@inicioTurno AS VARCHAR) +'':00'', 121)
			SET @fStart=DATEADD(d,-1,@fEnd)
		 END

		IF @action = 1
			BEGIN
				SELECT  claar.User_id AS [AgentID],
					claar.TipoAuxiliarReady_id AS [AuxiliaryReadyType_Id],
					tra.Description AS[Description],
					CONVERT(CHAR(8), DATEADD(SECOND, SUM(claar.tStatus),0),108) AS [Time],
					COUNT(tra.TipoReadyAuxiliar_Id) AS [Times]
					FROM dbo.ccLogAgentesAuxiliarReady AS claar
					INNER JOIN dbo.TipoReadyAuxiliar AS tra 
					ON claar.TipoAuxiliarReady_id = tra.TipoReadyAuxiliar_Id
					WHERE claar.fecha BETWEEN @fStart AND @fEnd 
					GROUP BY claar.User_id, tra.Description, claar.TipoAuxiliarReady_id
				END
		ELSE IF @action = 2 and @userId > 0
			BEGIN
				SELECT  claar.User_id AS [AgentID],
					claar.TipoAuxiliarReady_id AS [AuxiliaryReadyType_Id],
					tra.Description AS[Description],
					CONVERT(CHAR(8), DATEADD(SECOND, SUM(claar.tStatus),0),108) AS [Time],
					COUNT(tra.TipoReadyAuxiliar_Id) AS [Times]
					FROM dbo.ccLogAgentesAuxiliarReady AS claar
					INNER JOIN dbo.TipoReadyAuxiliar AS tra 
					ON claar.TipoAuxiliarReady_id = tra.TipoReadyAuxiliar_Id
					WHERE claar.fecha BETWEEN @fStart AND @fEnd AND claar.User_id = @userId
					GROUP BY claar.User_id, tra.Description, claar.TipoAuxiliarReady_id
			END

		SET NOCOUNT OFF';
EXEC(@sql);

set @process = 'KR123006 - Auxiliar - Detalles Dashboard - delete ccsp_GetAgentIndividualCounters'
set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_GetAgentIndividualCounters'')
        BEGIN
            DROP PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters]
        END'
EXEC(@sql)

SET @process = 'KR123006 - Auxiliar - Detalles Dashboard - Action five was modify'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters]
@type as int, @sup_id as int = 0 as
set nocount on

declare @fecha_ini datetime
select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

if @type = 1 --Session time
    begin
        SELECT User_id, case
            WHEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0
                THEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))
            ELSE sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) +
                convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14)))
            END as logintime
        FROM ccLogLogin a with(nolock,index(IX_ccLogLogin_4)), ccGenViewRelsSupsAgent b
        where fecha >= @fecha_ini
        and a.User_id = b.agt
        and b.sup = @sup_id
        GROUP BY User_id
    end

else if @type = 2 begin--Status agent
    
    ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login 
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where 
        wgAdmin.User_id=@sup_id
    )

    select User_id,TipoStatusAge_id,sum(segundos) as segundos from (
    SELECT User_id, TipoStatusAge_id, tStatus As segundos
    FROM ccLogAgentesDia a with(nolock,index(IX_ccLogAgentesDia_4))
    inner join TableUserAgent b  on  a.User_id = b.userId   
    WHERE fecha >= @fecha_ini   
    union all   
    select A.User_id,
    case when A.TipoStatusAge_id in(0,1) then 3
    when A.currentStatus in (21,5,9) then 4
    else A.currentStatus end as TipoStatusAge_id,
    DATEDIFF(ss,A.fecha,getdate()) as seconds   
    from ccLogAgentesDia A with(nolock)
    inner join
    (select max(fecha) fecha,USER_ID from ccLogAgentesDia D with(nolock,index(IX_ccLogAgentesDia_4))
    inner join TableUserAgent C on D.User_id=C.userId
    where fecha >= @fecha_ini    
        group by User_id) B
    on A.User_id=B.User_id and A.fecha=B.fecha and A.currentStatus not in (0,-2)

    )x
    group by User_id,TipoStatusAge_id
    ORDER BY User_id

end

else if @type = 3 begin

    ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login 
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where 
        wgAdmin.User_id=@sup_id
    )

    select calls.user_id, calls.total_calls, calls.type_calls, users.login, calls.nCalls, calls.tDialog, calls.tWrapup, calls.tHold 
    from ccusers As users ,
        (
            select calls.User_id, count(*) AS ''total_calls'',
            CASE
            WHEN statuscall_id = 15 THEN 5  --OutBound Asignada pero no contestada
            WHEN cal_manual = 2 THEN 3      --OutBound llamada manual
            ELSE 2                          --Llamada de OutBound
            END AS ''type_calls'',      
            count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
            convert(int,sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end)) tDialog,
            convert(int,sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end)) tWrapup,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold
            from TableUserAgent as tAgent
            inner join ccoCallsOut calls WITH (NOLOCK index(IX_ccoCallsOut_10))   
            on tAgent.userId=calls.User_id
            WHERE statuscall_id <> 11  --OutBound sin estado definitivo
            AND cal_inicio >= @fecha_ini
            GROUP BY User_id, statuscall_id, cal_manual--,tAgent.login
        
            union

            select calls.User_id, count(*) AS ''total_calls'',
            CASE
            WHEN statuscall_id = 15 THEN 4  --InBound Asignada pero no contestada
            ELSE 1                          --Llamada de InBound
            END AS ''type_calls'',      
            count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
            convert(int,sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end)) tDialog,
            convert(int,sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end)) tWrapup,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold

            from TableUserAgent as tAgent
            inner join ccCallsIn calls WITH (NOLOCK index(IX_ccCallsIn_5)) 
            on tAgent.userId=calls.User_id
            WHERE statuscall_id <> 11  --OutBound sin estado definitivo
            AND cal_inicio >= @fecha_ini
            GROUP BY User_id, statuscall_id--,tAgent.login
        ) AS calls
        where users.user_id = calls.user_id     

    end

else if @type = 4
    begin
        
        ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login 
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where 
        wgAdmin.User_id=@sup_id
    )


        select a.user_id, a.login
        from ccusers a (nolock)--, ccGenViewRelsSupsAgent b
        inner join TableUserAgent b on a.User_id=b.userId       
    end
else if @type = 5
    begin          
	declare @users table(userId int primary key)


	if exists(select * from ccUsers_Roles where User_id=@sup_id and Rol_id=1 ) begin
		insert into @users
		select user_id from ccUsers where TipoUser_id=1
	end
	else begin
		
		insert into @users
		select distinct wgAgt.User_id as userId --,usr.login 
		from ccriaworkgroupusers wgAdmin
		inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
		inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
		where 
		wgAdmin.User_id=@sup_id 
	end

	SELECT cast(User_id AS INT) UserId
		,sum(CASE WHEN TipoStatusAge_id = 2 THEN tStatus ELSE 0 END) NotReady
		,sum(CASE WHEN TipoStatusAge_id = 3 THEN tStatus ELSE 0 END) Ready
		,sum(CASE WHEN TipoStatusAge_id = 4 THEN tStatus ELSE 0 END) Dialog
		,sum(CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE 0 END) XFer
		,sum(CASE WHEN TipoStatusAge_id = 6 THEN tStatus ELSE 0 END) Wrapup
		,sum(CASE WHEN TipoStatusAge_id = 7 THEN tStatus ELSE 0 END) Other
		,sum(CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE 0 END) Ringing
		,sum(CASE WHEN TipoStatusAge_id = 11 THEN tStatus ELSE 0 END) Problem
		,sum(CASE WHEN TipoStatusAge_id = 37 THEN A.tStatus ELSE 0 END) AuxiliaryReady
		FROM ccLogAgentesDia A with(nolock)
		inner join @users B on A.User_id=B.userId
		WHERE fecha >= @fecha_ini
			AND TipoStatusAge_id > 0
		GROUP BY User_id 

  
    end
set nocount on'

EXEC(@sql)


set @process = 'KR123007 - Auxiliar - Tablero de control - Campañas de salida y KR123008 - Auxiliar - Tablero de control - Campañas de entrada delete ccsp_GalateaAdminCampaigns'
set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_GalateaAdminCampaigns'')
        BEGIN
            DROP PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns]
        END'
EXEC(@sql)

SET  @process = 'KR123007 - Auxiliar - Tablero de control - Campañas de salida y KR123008 - Auxiliar - Tablero de control - Campañas de entrada, Action 10 was modified to add agents number in custom ready'
SET  @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] 
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
            count(CASE WHEN A.CurrentState NOT IN (- 2, - 1, 0, 3, 4, 5, 6, 9, 30, 34, 37
                            ) THEN 1 WHEN A.CurrentState IN (6, 34, 4
                            )
                        AND (
                            A.CampId != C.IdCampEsp
                            OR A.campType != @CampType
                            ) THEN 1 ELSE NULL END) AS notReady,
                            COUNT(CASE WHEN A.isCampDialog = 1 THEN 1 ELSE NULL END) AS dialog, 
                            COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected,
	COUNT(CASE WHEN A.CurrentState = 37 THEN 1 ELSE NULL END) AS auxiliaryReady
        FROM @AgentStatus A
        INNER JOIN @CurrentStatus C ON A.userId = C.userId
        GROUP BY A.CampId
        )
    SELECT A.camId, A.campName, A.Total, ISNULL(B.ready, 0) AS Ready, ISNULL(B.notReady, 
            0) AS NotReady, ISNULL(B.dialog, 0) AS Dialog, CASE WHEN B.disconnected IS NULL 
                THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady - B.auxiliaryReady END 
        Disconnected, ISNULL(B.auxiliaryReady, 0) AS AuxiliaryReady,A.Area
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
            FROM ccInbound NOLOCK where cam_id = @Id
END

END;'

EXEC(@sql)

SET @sql = 'IF NOT EXISTS( SELECT * FROM ccGalateaModules WHERE ModuleId = 17)
	BEGIN
		insert into ccGalateaModules (ModuleId, MTagEs, MTagEn, MTagPt)
		values (17, ''Estados de Disponible especial'', ''Custom ready options'', ''Tipos de Disponível especial'');
	END';
EXEC(@sql);

SET @sql = 'IF NOT EXISTS( SELECT * FROM ccGalateaModules WHERE ModuleId = 18)
	BEGIN
		insert into ccGalateaModules (ModuleId, MTagEs, MTagEn, MTagPt)
		values (18, ''Estados de Disponible especial por administrador'', ''Custom ready options by administrator'', ''Tipos de Disponível especial por administrador'');
	END';
EXEC(@sql);

SET @sql = 'IF NOT EXISTS( SELECT * FROM ccGalateaModules WHERE ModuleId = 19)
	BEGIN
		insert into ccGalateaModules (ModuleId, MTagEs, MTagEn, MTagPt)
		values (19, ''Estados de Disponible especial por campaña'', ''Custom ready options by campaign'', ''Tipos de Disponível especial por campanha'');
	END';
EXEC(@sql);

SET @sql = 'IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 98)
	BEGIN
		insert into ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
		values (98, ''Crear estado Disponible especial'', ''Create custom ready option'', ''Criar tipo de Disponível especial'');

		INSERT INTO ccGalateaModOpRelation values(17,98)
	END';

EXEC(@sql);

SET @sql = 'IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 99)
	BEGIN
		insert into ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
		values (99, ''Editar estado Disponible especial'', ''Edit custom ready option'', ''Editar tipo de Disponível especial'');

		INSERT INTO ccGalateaModOpRelation values(17,99)
	END';

EXEC(@sql);

SET @sql = 'IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 100)
	BEGIN
		insert into ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
		values (100, ''Eliminar estado Disponible especial'', ''Delete custom ready option'', ''Excluir tipo de Disponível especial'');

		INSERT INTO ccGalateaModOpRelation values(17,100)
	END';

EXEC(@sql);

SET @sql = 'IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 101)
	BEGIN
		insert into ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
		values (101, ''Asignar estado Disponible especial'', ''Assign custom ready option'', ''Atribuir tipo de Disponível especial'');

		INSERT INTO ccGalateaModOpRelation values(18,101)
		INSERT INTO ccGalateaModOpRelation values(19,101)
	END';

EXEC(@sql);

SET @sql = 'IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 102)
	BEGIN
		insert into ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt)
		values (102, ''Desasignar estado Disponible especial'', ''Unassign custom ready option'', ''Cancelar atribuição de tipo de Disponível especial'');

		INSERT INTO ccGalateaModOpRelation values(18,102)
		INSERT INTO ccGalateaModOpRelation values(19,102)
	END';

EXEC(@sql);

SET @sql = 'IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 103)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) 
		VALUES (103,''Habilitar uso de disponible especial'',''Allow use of custom ready options'',''Ativar o uso de status disponível especial'');

		INSERT INTO ccGalateaModOpRelation values(2,103)
	END';

EXEC(@sql);

SET @sql = 'IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 104)
	BEGIN
		INSERT INTO ccGalateaOperations (OperationId, OpTagEs, OpTagEn, OpTagPt) 
		VALUES (104,''Deshabilitar uso de disponible especial'',''Deny use of custom ready options'',''Desativar o uso de status disponível especial'');

		INSERT INTO ccGalateaModOpRelation values(2,104)
	END';

EXEC(@sql);

SET @sql = 'IF NOT EXISTS( SELECT * FROM ccGalateaOperations WHERE OperationId = 105)
	BEGIN
		INSERT INTO ccGalateaOperations(OperationId, OpTagEs, OpTagEn, OpTagPt)
		VALUES (105, ''Cambiar a disponible especial'', ''Set agent to custom ready'', ''Alterar status para disponível especial'')

		INSERT INTO ccGalateaModOpRelation values(2,105)
	END';

EXEC(@sql);

set @process = 'KR123000 delete ccsp_GalateaReadyAuxiliar'
set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_GalateaReadyAuxiliar'')
        BEGIN
            DROP PROCEDURE [dbo].[ccsp_GalateaReadyAuxiliar]
        END'
EXEC(@sql)

SET  @process = 'KR123000 se creo el sp para las consultas de los auxiliares'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaReadyAuxiliar]
        @action int,
        @tipoReadyId int = 0,
        @userId int = 0,
		@timeStatus float = 0

        AS

        declare @currentDate datetime
        declare @seconds FLOAT        
		declare @AuxiliaryReadyRestricted BIT
        
		set @AuxiliaryReadyRestricted = 0
		select @AuxiliaryReadyRestricted = AuxiliaryRestricted from ccUsers where User_id = @userId

        set @currentDate = GETDATE();

        create table #temp (
            userId int not null,
            TipoAuxiliarReady_id smallint not null,
            tStatus int,
            fecha datetime
        )

        if @action = 1 
        BEGIN
        DECLARE @settingValue TINYINT = 0;

		SELECT @settingValue = cs.valor FROM dbo.ccSettings2 AS cs WHERE cs.setting_id = 266;
		IF (@settingValue = 0)
		BEGIN
			select TipoReadyAuxiliar_Id, Description, isnull(Color,0) as Color, AdminPasswordRequired, @AuxiliaryReadyRestricted AS AuxiliaryRestricted  from TipoReadyAuxiliar where StatusAux=1
		END
		ELSE IF(@settingValue = 1)
		BEGIN
		select	t.TipoReadyAuxiliar_Id    ,
				t.Description             ,
				ISNULL(t.Color,0) AS Color,  
				t.AdminPasswordRequired   ,
				@AuxiliaryReadyRestricted AS AuxiliaryRestricted 
				from ccCampsAgente ca 
				inner join ccCampaignsOut_Aux coa on ca.cam_id =  coa.cam_id
				inner join TipoReadyAuxiliar t on t.TipoReadyAuxiliar_Id = coa.TipoReadyAuxiliar_Id
				where ca.user_id = @userId and t.StatusAux = 1
				union
		select	t.TipoReadyAuxiliar_Id    ,
				t.Description             ,
				ISNULL(t.Color,0) AS Color,
				t.AdminPasswordRequired   ,
				@AuxiliaryReadyRestricted AS AuxiliaryRestricted 
				from ccInboundAgentes ia 
				inner join ccCampaignsIn_Aux cia on ia.Inbound_id =  cia.Inbound_id
				inner join TipoReadyAuxiliar t on t.TipoReadyAuxiliar_Id = cia.TipoReadyAuxiliar_Id
				where ia.user_id = @userId and t.StatusAux = 1 
		END
        end

        if @action = 2 AND @tipoReadyId > 0 -- inicia tiempo en este estado
        begin
            insert into ccLogAgentesAuxiliarReady (User_id, TipoAuxiliarReady_id, tStatus, fecha) values (@userId, @tipoReadyId, @timeStatus, @currentDate)
			RETURN 0;
        end 

        if @action = 3 -- sale del estado
        begin 
			if(@tipoReadyId>0)
			begin
				insert into #temp
				SELECT TOP 1 User_id,TipoAuxiliarReady_id,tStatus,fecha
				FROM ccLogAgentesAuxiliarReady
				where User_id = @userId and TipoAuxiliarReady_id = @tipoReadyId and tStatus = 0
				ORDER BY fecha DESC;
			end
			else
			begin
				insert into #temp
				SELECT TOP 1 User_id,TipoAuxiliarReady_id,tStatus,fecha
				FROM ccLogAgentesAuxiliarReady
				where User_id = @userId and tStatus = 0
				ORDER BY fecha DESC;
			end
            

            if exists (select 1 from #temp where tStatus = 0 and userId = @userId )
            begin
                select @seconds = (DATEDIFF(MILlISECOND, fecha, @currentDate) / 1000.0) FROM #temp

                update a
                set tStatus = @seconds
                from ccLogAgentesAuxiliarReady a
                left join #temp b on a.fecha = b.fecha and a.User_id = b.userId
                where a.tStatus = 0 and a.user_id = @userId
            end

        end 
		IF @action = 4 --obtener el auxiliar al que iniciara el agente
		BEGIN
			DECLARE @LastAuxiliaryDate DATETIME = NULL;
			SELECT  @LastAuxiliaryDate = MAX(claar.fecha) FROM dbo.ccLogAgentesAuxiliarReady AS claar WHERE claar.User_id = @userId
			SELECT  CAST(claar.TipoAuxiliarReady_id AS INT) AS TipoAuxiliarReady_id FROM dbo.ccLogAgentesAuxiliarReady AS claar WHERE claar.User_id = @userId
			AND claar.fecha = @LastAuxiliaryDate
			RETURN(0)
		END
		IF @action = 5 --saber si el agente estaba en auxiliar antes de cerrar sesión
		BEGIN
			DECLARE @LastLogoutDate DATETIME = NULL;
			SELECT  @LastLogoutDate = MAX(claar.fecha) FROM dbo.ccLogAgentesDia AS claar WHERE claar.User_id = @userId AND claar.currentStatus = -2
			SELECT CASE WHEN clad.TipoStatusAge_id = 37 THEN CONVERT(BIT, 1) ELSE CONVERT(BIT, 0) END AS AuxiliarBefore FROM dbo.ccLogAgentesDia AS clad WHERE clad.User_id = @userId AND clad.currentStatus = -2
			AND clad.fecha = @LastLogoutDate
			RETURN(0)
		END

        drop table #temp';
EXEC(@sql);


set @process = 'KR123004 - delete ccsp_SaveStatusAgent'
set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_SaveStatusAgent'')
        BEGIN
            DROP PROCEDURE [dbo].[ccsp_SaveStatusAgent]
        END'
EXEC(@sql)

SET @process = 'KR123004 - cambios para guardar estado del agente'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_SaveStatusAgent]
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
@isTransferEngine bit = 0,
@TypeAuxiliar int = 0
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


--Agregar callback en caso de este activo setting en campa?as o acd y tenga relacion de campa?a de encuesta
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

if ( @TipoStatusAge_id = 37 ) begin
	EXEC ccsp_GalateaReadyAuxiliar @action = 2, @tipoReadyId = @TypeAuxiliar, @userId = @User_id, @timeStatus= @tStatus
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
EXEC(@sql)


set @process = 'KR123004 - delete ccsp_SaveLogoutLastState'
set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_SaveLogoutLastState'')
        BEGIN
            DROP PROCEDURE [dbo].[ccsp_SaveLogoutLastState]
        END'
EXEC(@sql)

SET @process = 'KR123004 - cambios para guardar estado del agente al cerrar sesión repentinamente'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_SaveLogoutLastState]
@UserID smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus float,
@TipoCall  tinyint,
@call_id int=0,
@tDialog int =0 ,
@Extension varchar(7)=null,
@Computer varchar(20)=null,
@fecha datetime=null,
@tMusicHold int=0,
@TypeAuxiliar int = 0
AS
set nocount on

if @fecha is null set @fecha=getdate()

exec ccsp_AgentLogINOUT @UserID=@UserID,@Extension=@Extension,@Computer=@Computer,@TipoMov=0,@fecha=@fecha
exec ccsp_SaveStatusAgent @User_id=@UserID,@TipoStatusAge_id=@TipoStatusAge_id,@TipoNotReady=@TipoNotReady,@tStatus=@tStatus,@TipoCall=@TipoCall,@Camp=0,@callout_id=0,@call_id=@call_id,@isLogout=1,@tDialog =@tDialog,@Fecha4=@fecha,@tMusicHold=@tMusicHold,@TypeAuxiliar=@TypeAuxiliar'
EXEC(@sql)


-----------------KR123023
SET @process = 'KR123023 - Setting para desactivar menú de estado disponible especial en administrador y Agente Se crea setting 263 para desactivar menu de estados disponibles especial en admiministrador y Agente'
SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 263)
            BEGIN
                INSERT INTO ccSettings2(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
                VALUES(263, ''0'', ''Mostrar menús y botones para gestión del estado disponible especial'', 1, ''GRL'', ''Mostrar menús y botones para gestión del estado disponible especial (0: deshabilitado/1: habilitado)'',
                                    ''Show menus and buttons for custom ready options management (0: disabled/1: enabled)'',1,''^[0-1]$'') 
            END'
EXEC(@sql);

--KR123033 - Auxiliar - Settings para cambiar a auxiliar desde Administrador
SET @process = 'KR123033 - Auxiliar - Settings para cambiar a auxiliar desde Administrador Se crea setting 265 para mostrar todos o solo los auxiliares asignados al admistrador'
SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 265)
            BEGIN
                INSERT INTO ccSettings2(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
                VALUES(265, ''2'', ''Mostrar estados de disponible especial en tablero de control de administrador'', 1, ''ADM'', ''Mostrar estados de disponible especial en tablero de control de administrador (1: todos los estados/2: estados por administrador/0: ningún estado)'',
                                    ''Show custom ready options in administrator dashboard (1: all options/2: options by administrator/0: none)'',1,''^[1-2]$'') 
            END'
EXEC(@sql);

--KR123034 - Auxiliar - Settings para auxiliares disponibles en Agente
SET @process = 'KR123034 - Auxiliar - Settings para auxiliares disponibles en Agente. Se crea setting 266 para mostrar todos o solo los auxiliares asignados a la campaña'
SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 266)
            BEGIN
                INSERT INTO ccSettings2(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
                VALUES(266, ''1'', ''Mostrar estados de disponible especial en menú de agente'', 1, ''AGT'', ''Mostrar estados de disponible especial en menú de agente (0: todos los estados/1: estados por campaña/2: ningún estado)'',
                                    ''Show custom ready options in agent menu (0: all options/1: options by campaign/2: none)'',1,''^[0-1]$'') 
            END'
EXEC(@sql);

SET @process = 'KR123034 - Auxiliar - Settings para auxiliares disponibles en Agente. Se crea setting 267 para poner al agente al estado auxiliar que tenia antes de cerrar sesión'
SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 267)
            BEGIN
                INSERT INTO ccSettings2(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
                VALUES(267, ''0'', ''Mantener estado de disponible especial en reconexión del agente'', 1, ''AGT'', ''Mantener estado de disponible especial en reconexión del agente (0: deshabilitado/1: habilitado)'',
                                    ''Keep agents set to the custom ready status upon reconnection (0: disabled/1: enabled)'',1,''^[0-1]$'') 
            END'
EXEC(@sql);


set @process = 'KR123034 - Auxiliar - Settings para auxiliares disponibles en Agente -> delete ccsp_GalateaAdminSettings'
set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_GalateaAdminSettings'')
        BEGIN
            DROP PROCEDURE [dbo].[ccsp_GalateaAdminSettings]
        END'
EXEC(@sql)

SET @process = 'KR123034 - Auxiliar - Settings para auxiliares disponibles en Agente -> table structure of #settings, it was modify'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSettings]
AS
BEGIN
	CREATE TABLE #Settings (setting_id SMALLINT , valor varchar(300), ip_host tinyint)

	INSERT INTO #Settings 
	EXEC  ccsp_RIAADMLoadSettings @ip_admin =''''

	INSERT INTO #Settings (setting_id,valor) 
	SELECT setting_id, valor 
	FROM ccSettings
	WHERE setting_id in(160, 199, 53, 63, 64)
 
	SELECT distinct cast(setting_id as smallint) setting_id, valor from #Settings ORDER BY setting_id 

	DROP TABLE #Settings;
END'

EXEC(@sql)


set @process = 'KR123034 - Auxiliar - Settings para auxiliares disponibles en Agente delete ccsp_RIAADMLoadSettings'
set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_RIAADMLoadSettings'')
        BEGIN
            DROP PROCEDURE [dbo].[ccsp_RIAADMLoadSettings]
        END'
EXEC(@sql)

SET @process = 'KR123034 - Auxiliar - Settings para auxiliares disponibles en Agente it changed ccsettings to VIEW_SETTINGS'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAADMLoadSettings]
@setting_id as tinyint = 0,
@type as tinyint = null,
@ip_admin as varchar(15)=''''
AS

declare @bremlog as tinyint
set nocount on
if @type is null
 begin
	select @bremlog = case when ip = @ip_admin then 1 else 0 end from ccriaremotelog where ip = @ip_admin
	IF @setting_id=0
 		select setting_id, valor, isnull(@bremlog,0) ip_host from dbo.VIEW_SETTINGS AS vs where Status=''1'' and bLoadSettings = 1 order by setting_id
	ELSE
		select setting_id, valor, isnull(@bremlog,0) ip_host from dbo.VIEW_SETTINGS AS vs where Status=''1'' and setting_id  = @setting_id
	return(0)
 end

if @type=1 -- Settings de paises
 begin
	select CtyCode, minPhoneLength, maxPhoneLength, CtyID from ccRIACat_Country
	where CtyID in (select valor from ccSettings where setting_id=104)
	return(0)
 end

set nocount OFF'

EXEC(@sql)


-----

set @process = 'KR123000 delete ccsp_AuxiliarReadyManagement'
set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_AuxiliarReadyManagement'')
        BEGIN
            DROP PROCEDURE [dbo].[ccsp_AuxiliarReadyManagement]
        END'
EXEC(@sql)

SET @process = 'KR123000 se creo el store procedure ccsp_AuxiliarReadyManagement para administrar los auxiliares '
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_AuxiliarReadyManagement]
@type int,
@camId smallint = null,
@camType smallint = null,
@auxiliarIds varchar(max) = null,
@adminId smallint = null,
@name varchar(50) = '''',
@AdminPasswordRequired bit = 0,
@TipoReadyAuxiliar_Id int = null,
@StatusAux bit = 1
AS

set nocount on

if @Type=2 --Read auxiliar states
begin
	select TipoReadyAuxiliar_Id as AuxiliarReadyId, Description as Name, AdminPasswordRequired from TipoReadyAuxiliar where StatusAux=1 
	return(0)
end


if @type=3 --Create auciliar state
begin 
	declare @NextTipoReadyAuxiliar_Id int;
    select @NextTipoReadyAuxiliar_Id = ISNULL(MAX(TipoReadyAuxiliar_Id), 0) + 1 from TipoReadyAuxiliar;

	 if exists(select LTRIM(RTRIM(Description)) from TipoReadyAuxiliar where StatusAux=1 and Description=LTRIM(RTRIM(@name))) begin
	  select -1 as result
	  return(0)
	 end
	insert into TipoReadyAuxiliar(TipoReadyAuxiliar_Id, Description,AdminPasswordRequired,StatusAux) values (@NextTipoReadyAuxiliar_Id,@name,@adminPasswordRequired,@StatusAux)
	select @NextTipoReadyAuxiliar_Id as result
	return(0)
end


if @Type=4 --Update auxiliar state
begin
	if not exists(select 1 from TipoReadyAuxiliar where TipoReadyAuxiliar_Id = @TipoReadyAuxiliar_Id and StatusAux = 1) begin
	 select -2 as RESULT
	 return(0)
	end
	if not exists(select LTRIM(RTRIM(Description)) from TipoReadyAuxiliar where StatusAux=1 and Description=LTRIM(RTRIM(@name)) and TipoReadyAuxiliar_Id <> @TipoReadyAuxiliar_Id) begin
	 update TipoReadyAuxiliar set Description = @name, AdminPasswordRequired = @AdminPasswordRequired where TipoReadyAuxiliar_Id = @TipoReadyAuxiliar_Id  
	 select 1 as RESULT
	 return(0)
	end
	else begin
	 select -1 as result
	 return(0)
	end
end


if @Type=5 --Delete auxiliar state
begin
    IF OBJECT_ID(''tempdb..#TmpDAux'') IS NOT NULL DROP TABLE #TmpDAux
    create table #TmpDAux (Id int) 
    insert into #TmpDAux (Id)
 select CAST(value AS int) from fn_RIASplitDelimited(@auxiliarIds, '','') 
	IF not EXISTS ( SELECT TipoReadyAuxiliar_Id FROM TipoReadyAuxiliar tr INNER JOIN #TmpDAux t ON tr.TipoReadyAuxiliar_Id = t.Id where tr.StatusAux = 1) begin
	 select -1 as result 
	 return(0)
	end 
	else begin 
     update TipoReadyAuxiliar set StatusAux=0 where TipoReadyAuxiliar_Id IN (select Id from #TmpDAux)  
     delete from ccCampaignsIn_Aux where TipoReadyAuxiliar_Id IN (select Id from #TmpDAux)
     delete from ccCampaignsOut_Aux where TipoReadyAuxiliar_Id IN (select Id from #TmpDAux)
	 delete from ccAdmin_Aux where TipoReadyAuxiliar_Id IN (select Id from #TmpDAux)
     select 1 as result
	 return(0)
	end
	IF OBJECT_ID(''tempdb..#TmpDAux'') IS NOT NULL DROP TABLE #TmpDAux
end


if @Type=6 --Read all admins 
begin
	select User_id as AdminId, Login as AdminName from ccUsers where Status = 1 and TipoUser_id = 2 and User_id <> 1
	return(0)
end


IF @type = 7 --Assign auxiliar states to admin
BEGIN
    IF OBJECT_ID(''tempdb..#TmpAuxAdmin'') IS NOT NULL DROP TABLE #TmpAuxAdmin
    CREATE TABLE #TmpAuxAdmin (Id INT)

    INSERT INTO #TmpAuxAdmin (Id)

    SELECT CAST(value AS INT)
    FROM fn_RIASplitDelimited(@auxiliarIds, '','')

    INSERT INTO ccAdmin_Aux (User_id, TipoReadyAuxiliar_Id)
    SELECT @adminId, Tmp.Id
    FROM #TmpAuxAdmin AS Tmp
    LEFT JOIN ccAdmin_Aux AS C
    ON Tmp.Id = C.TipoReadyAuxiliar_Id AND C.User_id = @adminId
	LEFT JOIN ccUsers AS U
	ON @adminId = U.User_id
    LEFT JOIN TipoReadyAuxiliar AS TRA
    ON Tmp.Id = TRA.TipoReadyAuxiliar_Id
    WHERE C.User_id IS NULL AND TRA.StatusAux = 1

	select 1 as result

    IF OBJECT_ID(''tempdb..#TmpAuxAdmin'') IS NOT NULL DROP TABLE #TmpAuxAdmin
END


IF @type = 8 -- Unassign auxiliar state to admin
BEGIN
    IF OBJECT_ID(''tempdb..#TmpAuxAdminDelete'') IS NOT NULL DROP TABLE #TmpAuxAdminDelete
    CREATE TABLE #TmpAuxAdminDelete (Id INT)

    INSERT INTO #TmpAuxAdminDelete (Id)

    SELECT CAST(value AS INT)
    FROM fn_RIASplitDelimited(@auxiliarIds, '','')

    DELETE C
    FROM ccAdmin_Aux AS C
    JOIN #TmpAuxAdminDelete AS Tmp
    ON C.TipoReadyAuxiliar_Id = Tmp.Id
	where C.User_id = @adminId

	select 1 as result

    IF OBJECT_ID(''tempdb..#TmpAuxAdminDelete'') IS NOT NULL DROP TABLE #TmpAuxAdminDelete
END


if @Type=9 --Read auxiliar states assigned to admins
BEGIN
	DECLARE @settingValue TINYINT = 0;

	SELECT @settingValue = cs.valor FROM dbo.ccSettings2 AS cs WHERE cs.setting_id = 265;
	IF (@settingValue = 1)
	BEGIN
		SELECT @adminId  as AdminId, tra.TipoReadyAuxiliar_Id as AuxiliarID, tra.[Description] FROM dbo.TipoReadyAuxiliar AS tra WHERE tra.StatusAux = 1;
	END
	ELSE IF(@settingValue = 2)
	BEGIN
		select a.USER_ID as AdminId, a.TipoReadyAuxiliar_Id as AuxiliarID, tr.[Description]
		from ccAdmin_Aux a
		inner join TipoReadyAuxiliar tr on a.TipoReadyAuxiliar_Id = tr.TipoReadyAuxiliar_Id
		where User_ID = @adminId and tr.StatusAux = 1
	END
	return(0)
end


if @Type=10 -- Assign auxiliar states to campaigns
begin 
    IF OBJECT_ID(''tempdb..#TmpAuxCam'') IS NOT NULL DROP TABLE #TmpAuxCam
    CREATE TABLE #TmpAuxCam (Id INT)

    INSERT INTO #TmpAuxCam (Id)

    SELECT CAST(value AS INT)
    FROM fn_RIASplitDelimited(@auxiliarIds, '','')

	if @camType=0 begin
		INSERT INTO ccCampaignsIn_Aux (Inbound_Id, TipoReadyAuxiliar_Id)
		SELECT @camId, Tmp.Id
		FROM #TmpAuxCam AS Tmp
		LEFT JOIN ccCampaignsIn_Aux AS C
		ON Tmp.Id = C.TipoReadyAuxiliar_Id AND C.Inbound_Id = @camId
		LEFT JOIN ccInbound AS I
		ON @camId = I.Inbound_id
		LEFT JOIN TipoReadyAuxiliar AS TRA
        ON Tmp.Id = TRA.TipoReadyAuxiliar_Id
		WHERE C.Inbound_id IS NULL AND I.Status=1 and TRA.StatusAux = 1
		select 1 as result
	end

	if @camType=1 begin
		INSERT INTO ccCampaignsOut_Aux(cam_id, TipoReadyAuxiliar_Id)
		SELECT @camId, Tmp.Id
		FROM #TmpAuxCam AS Tmp
		LEFT JOIN ccCampaignsOut_Aux AS C
		ON Tmp.Id = C.TipoReadyAuxiliar_Id AND C.cam_id = @camId
		LEFT JOIN ccCamps AS O
		ON @camId = O.cam_id
		LEFT JOIN TipoReadyAuxiliar AS TRA
        ON Tmp.Id = TRA.TipoReadyAuxiliar_Id
		WHERE C.cam_id IS NULL AND O.IDArea is not null and TRA.StatusAux = 1
		select 1 as result
	end

    IF OBJECT_ID(''tempdb..#TmpAuxCam'') IS NOT NULL DROP TABLE #TmpAuxCam
end 


IF @type =11 -- Unassign auxiliar states to campaign
BEGIN
    IF OBJECT_ID(''tempdb..#TmpAuxCampDelete'') IS NOT NULL DROP TABLE #TmpAuxCampDelete
    CREATE TABLE #TmpAuxCampDelete (Id INT)

    INSERT INTO #TmpAuxCampDelete (Id)

    SELECT CAST(value AS INT)
    FROM fn_RIASplitDelimited(@auxiliarIds, '','')

	if @camType=0 begin
	    DELETE C
		FROM ccCampaignsIn_Aux AS C
		JOIN #TmpAuxCampDelete AS Tmp
		ON C.TipoReadyAuxiliar_Id = Tmp.Id
		WHERE C.Inbound_id = @camId

		select 1 as result
	end

	if @camType=1 begin
	    DELETE C
		FROM ccCampaignsOut_Aux AS C
		JOIN #TmpAuxCampDelete AS Tmp
		ON C.TipoReadyAuxiliar_Id = Tmp.Id
		where C.cam_id = @camId

		select 1 as result
	end

    IF OBJECT_ID(''tempdb..#TmpAuxCampDelete'') IS NOT NULL DROP TABLE #TmpAuxCampDelete
END


if @Type=12 --Read auxiliar states assigned to campaigns
begin
	if @camType=0 begin
		select Inbound_id as CamId, CAST(0 AS SMALLINT) as CamType, TipoReadyAuxiliar_Id as AuxiliarID from ccCampaignsIn_Aux where Inbound_id = @camId
		return(0)
	end
	if @camType=1 begin
		select cam_id as CamId, CAST(1 AS SMALLINT) as CamType, TipoReadyAuxiliar_Id as AuxiliarID from ccCampaignsOut_Aux where cam_id = @camId
		return(0)
	end
end

if @type=13
BEGIN
	SELECT TipoReadyAuxiliar_Id as notReadyId, [description], 0 as [time], 
	ISNULL(AdminPasswordRequired, 0) as requieredPassAdmin
	from TipoReadyAuxiliar WHERE TipoReadyAuxiliar_Id = @TipoReadyAuxiliar_Id
END

if @type=14
BEGIN
	DECLARE @permission bit = 0
	DECLARE @setting TINYINT = 0;
	SELECT @setting = cs.valor FROM dbo.ccSettings2 AS cs WHERE cs.setting_id = 265;
	IF (@setting = 1)
	BEGIN
		IF EXISTS(SELECT 1 FROM TipoReadyAuxiliar WHERE StatusAux = 1 and @TipoReadyAuxiliar_Id = TipoReadyAuxiliar_Id)
		BEGIN
			SET @permission = 1;
		END
	END
	ELSE IF(@setting = 2)
	BEGIN
		IF EXISTS ( select 1 from ccAdmin_Aux a
					inner join TipoReadyAuxiliar tr on a.TipoReadyAuxiliar_Id = tr.TipoReadyAuxiliar_Id
					where User_ID = @adminId and tr.StatusAux = 1)
		BEGIN
			SET @permission = 1;
		END
	END
	SELECT @permission;
	return(0)
END

IF @type = 15
BEGIN
	select AuxiliaryRestricted from ccUsers where User_id=@adminId
	RETURN(0)
END

if @type=16
BEGIN
	SELECT [Description] FROM TipoReadyAuxiliar
	WHERE TipoReadyAuxiliar_Id = @TipoReadyAuxiliar_Id
	return(0)
END

if @Type=17 
begin
	if not exists(select 1 from TipoReadyAuxiliar where TipoReadyAuxiliar_Id = @TipoReadyAuxiliar_Id and StatusAux = 1) begin
	select 0 as RESULT
	return(0)
	end
	else begin
	 select 1 as result
	 return(0)
	end
end'
EXEC(@sql)


set @process = 'KR123000 delete ccsp_GalateaSettingsById'
set @sql = 'IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = ''ccsp_GalateaSettingsById'')
        BEGIN
            DROP PROCEDURE [dbo].[ccsp_GalateaSettingsById]
        END'
EXEC(@sql)

SET @process = 'KR123000 Se modifico la consulta se cambio de ccsetting a VIEW_SETTINGS para obtener todos los settings'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaSettingsById]
			@Id SMALLINT = NULL
		AS
		BEGIN

			SET NOCOUNT ON;

				SELECT [setting_id]
					,[valor]
					,[Status]
					,[Tipo]
					,[bLoadSettings] FROM [dbo].[VIEW_SETTINGS] WITH(NOLOCK)
				WHERE (@Id IS NULL OR [setting_id]=@Id)
		END'
EXEC(@sql);

SET @process = 'KR123016 - Se agrega menu para reporte'
SET @sql = 'IF NOT EXISTS (SELECT 1 FROM ccMenus where menu_id = 2130)
BEGIN
	INSERT INTO ccMenus (menu_id, menu_descrip, parent, nivel, ordengral, [type], HelpSWF, release)
	VALUES(2130, ''Detalle de Especial (Auxiliar)|Special Detail (Auxiliary)'',2000, ''B'', 2, 3, '''', '''' )

	INSERT INTO ccMenuUser(id_User, id_Menu, type) VALUES (1, 2130,3)
END
'
EXEC(@sql);


SET @process = 'KR123015 - Se agrega menu para reporte'
SET @sql = 'IF NOT EXISTS (SELECT 1 FROM ccMenus where menu_id = 2120)
BEGIN
	INSERT INTO ccMenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
	VALUES(2120, ''Detalle auxiliares por agente|Auxiliary details by agent'',2100, ''B'', 2, 3, '''', '''' )

	INSERT INTO ccMenuUser(id_User, id_Menu, type) VALUES (1, 2120,3)
END
'
EXEC(@sql);

		----------------------------------------------------- END----------------------------------------------------------------	
	  
        

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