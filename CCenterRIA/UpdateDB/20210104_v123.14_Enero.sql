/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/15/10
Description:

Database: CCenterRia
Required version: 123.14

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
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 14
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

  set @process = 'CW-4739 Se elimina si existe ccsp_GalateaAdminSchedulesManagement'
  set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSchedulesManagement'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminSchedulesManagement;
            end'
  exec (@sql)

  set @process = 'CW-4739 Se agrega sp ccsp_GalateaAdminSchedulesManagement'
  set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSchedulesManagement]
	@option smallint = -1,
	@camId int = -1,
	@camType smallint = -1,
	@scheduleId int = -1,
	@areaId smallint = -1,
	@moduleId tinyint = 0,
	@userId smallint = -1,
	@operationType tinyint = 0
AS
SET NOCOUNT ON;
DECLARE @transtate BIT
IF @@TRANCOUNT = 0
BEGIN
	SET @transtate = 1
	BEGIN TRANSACTION transtate
	END
	BEGIN TRY
		IF @option = 1 --Obtener horarios
		BEGIN
			SELECT horario_id as ScheduleId, Descripcion as [Description],
			HoraInicio as StartHour, MinInicio as StartMinute, HoraFin as EndHour,
			MinFin as EndMinute, Lunes as Monday, Martes as Tuesday, Miercoles as Wednesday,
			Jueves as Thursday, Viernes as Friday, Sabado as Saturday, Domingo as Sunday FROM ccHorarios
		END
		IF @option = 2 --Obtener relaciones de horarios y campañas
		BEGIN
			IF(@camType=1)
			BEGIN
				SELECT cam_id as CampId, Horario_id as ScheduleId FROM ccCampsHorarios WHERE cam_id = @camId
			END
			IF(@camType=0)--campañas de entrada
			BEGIN
				SELECT Inbound_id as CampId, Horario_id as ScheduleId FROM ccInboundHorarios WHERE Inbound_id = @camId
			END
		END
		IF @option =3--agregar la relación de horarios con campañas de salida y entrada
		BEGIN
			IF(@camType =1)
			BEGIN
				IF NOT EXISTs (SELECT cam_id, Horario_id FROM ccCampsHorarios WHERE cam_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					INSERT INTO [CCenterRia].[dbo].[ccCampsHorarios](cam_id, Horario_id)
						VALUES (@camId, @scheduleId)
					SELECT 1
				END
				SELECT 0
			END
			IF(@camType = 0)
			BEGIN
				IF NOT EXISTs (SELECT Inbound_id, Horario_id FROM ccInboundHorarios WHERE Inbound_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					INSERT INTO [CCenterRia].[dbo].ccInboundHorarios(Inbound_id, Horario_id)
						VALUES (@camId, @scheduleId)
					SELECT 1
				END
				SELECT 0
			END
		END
		IF @option = 4 --eliminar relación del horario
		BEGIN
			IF(@camType = 1)
			BEGIN
				IF EXISTs (SELECT cam_id, Horario_id FROM ccCampsHorarios WHERE cam_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					DELETE ccCampsHorarios where cam_id=@camId and horario_id=@scheduleId
					SELECT 1
				END
				SELECT 0
			END
			IF(@camType = 0)
			BEGIN
				IF EXISTs (SELECT Inbound_id, Horario_id FROM ccInboundHorarios WHERE Inbound_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					DELETE ccInboundHorarios where inbound_id=@camId and horario_id=@scheduleId
					SELECT 1
				END
				SELECT 0
			END
		END
		IF @option = 5
		BEGIN
			IF (EXISTS(SELECT Horario_id FROM ccInboundHorarios WHERE horario_id = @scheduleId) OR EXISTS(SELECT Horario_id FROM ccCampsHorarios WHERE Horario_id = @scheduleId))
			BEGIN
				SELECT 1
			END
			ELSE
			BEGIN
				SELECT 0
			END
		END
		IF @option = 7 --insetar log
		BEGIN
			DECLARE @area nvarchar(max) = (SELECT AreaName FROM [CCenterRia].[dbo].[ccRIACat_Areas] where IDArea = @areaId)
			DECLARE @userName nvarchar(max) = (SELECT [Login] FROM [CCenterRia].[dbo].[ccUsers] where [User_id] = @userId)
			DECLARE @campDescription nvarchar(max) 
			DECLARE @scheduleName nvarchar(max)
			IF(@camType = 1)
			BEGIN
				SET @campDescription = (SELECT cam_descripcion FROM [CCenterRia].[dbo].[ccCamps] WHERE cam_id = @camId)
			END
			IF(@camType = 0)
			BEGIN
				SET @campDescription = (SELECT descripcion FROM [CCenterRia].[dbo].[ccInbound] WHERE Inbound_id = @camId)
			END
			IF(@camType = 2)--actualizar horarios
			BEGIN
				IF (@scheduleId = 0)
				BEGIN
					SET @campDescription = ''''
					DECLARE @MAXID INT = (SELECT MAX(horario_id) FROM ccHorarios)
					SET @scheduleName = (SELECT Descripcion FROM [CCenterRia].[dbo].[ccHorarios] WHERE horario_id = @MAXID)
				END
				ELSE
				BEGIN
					SET @campDescription = (SELECT Descripcion FROM [CCenterRia].[dbo].ccHorarios where horario_id = @scheduleId)
					SET @scheduleName = ''''
				END
			END
			ELSE
			BEGIN
				SET @scheduleName = (SELECT Descripcion FROM [CCenterRia].[dbo].[ccHorarios] WHERE horario_id = @scheduleId)
			END
			INSERT INTO [CCenterRia].[dbo].[ccRIALog](areaName, operationDate, operationType, login, module_id, value, target)
				VALUES (@area, GETDATE(), @operationType, @userName, @moduleId, @scheduleName, @campDescription)
		END
		IF @option = 8 --obtener los ids de las campañas con el horario asignado
		BEGIN
			SELECT cam_id FROM ccCampsHorarios WHERE Horario_id=@scheduleId
		END
		IF @option = 9
		BEGIN
			SELECT Descripcion FROM ccHorarios
		END
		IF @option = 10
		BEGIN
			SELECT MAX(horario_id) FROM ccHorarios
		END
		IF @transtate = 1 AND XACT_STATE() = 1
		BEGIN
			COMMIT TRANSACTION transtate
		END;
	END TRY
	BEGIN CATCH
		DECLARE @error INT, @message VARCHAR(4000), @xstate INT;
		SELECT @error = ERROR_NUMBER(), @message = ERROR_MESSAGE(), @xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			ROLLBACK
		IF @xstate = 1
			ROLLBACK TRANSACTION ccsp_GalateaAdminPortsManagement;
		RAISERROR (''ccsp_GalateaAdminSchedulesManagement: %d: %s'', 16, 1, @error, @message) ;
	END CATCH;'
		exec (@sql)
		
		
		set @process = 'CW-4733 DROP PROCEDURE [dbo].[ccsp_GalateaManageWG]'
set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaManageWG'')
    begin
        DROP PROCEDURE ccsp_GalateaManageWG;
    end'
EXEC(@sql)
     
		set @process = 'CW-4733 CREATE PROCEDURE [dbo].ccsp_GalateaManageWG'
        set @sql = '
CREATE PROCedure [dbo].[ccsp_GalateaManageWG]
@option smallint,
@IDWG smallint,
@Type smallint = 0,
@usersList varchar(max) ='''',
@ListCampsIn varchar(max) = '''',
@ListCampsOut varchar(max) =''''
as
set nocount on
declare @count int
declare @id int
declare @user int
declare @IDCampEsp varchar(max)
declare @Assigned  varchar(max)
declare @AssignedCampsIn  varchar(max)
declare @AssignedCampsOut  varchar(max)

set @id = 1
set @Assigned = ''''
set @AssignedCampsIn = ''''
set @AssignedCampsOut = ''''


IF OBJECT_ID(''tempdb..#UsersList'') IS NOT NULL DROP TABLE #UsersList;
IF OBJECT_ID(''tempdb..#CampsInOutList'') IS NOT NULL DROP TABLE #CampsInOutList;

select *  into #CampsInOutList from (
select ROW_NUMBER() OVER(ORDER BY [CampEsp] ASC) AS Row, [CampEsp], [Type] from (
	select 0 as [Type],
	[value] As [CampEsp]
	FROM fn_RIASplitDelimited(@ListCampsIn, '','') where [value] > 0
	union
	select 1 as [Type],
	[value] As [CampEsp]
	FROM fn_RIASplitDelimited(@ListCampsOut, '','') where [value] > 0
	) as Camps ) as CampsInOut


select ROW_NUMBER() OVER(ORDER BY value ASC) AS Row,
	value As user_id
	into #UsersList
	FROM fn_RIASplitDelimited(@usersList, '','')

select @count = count(user_id) from #UsersList

if @option = 1 -- Insert Agente-Supervisor in WorkGroup
 begin

	while @id<=@count
	begin
		select @user = user_id from #UsersList where Row= @id
		select @Type = tipoUser_id from ccUsers where user_id = @user

		if @Type in(1, 2, 6)
		begin

			if not exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @user)
			begin
			

				If @Type = 1
				 begin

						If (select count(User_id) from ccRIAWorkGroupUsers where User_id = @user) < (select valor from ccSettings where setting_id = 63)
						 begin
							insert into ccRIAWorkGroupUsers(IDWG, User_id) values(@IDWG,@user)
							select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
							--insert skill media
							exec ccsp_Skills @action= 5,@userId=@user

							insert into cccampsAgente (user_id, cam_id, prioridad, skill, IDWG)
							select @user, idCampEsp, dbo.fn_Calcula_UsrPriority(@user,0), 1, @IDWG
							from ccRIACampEspWG where tipo = 1 and IDWG = @IDWG and
							 idCampEsp not in (select cam_id from cccampsAgente where user_id=@user and IDWG=@IDWG)

							insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, IDWG)
							select @user, idCampEsp, 0, dbo.fn_Calcula_UsrPriority(@user,0), 1, @IDWG
							from ccRIACampEspWG where tipo = 0 and IDWG = @IDWG and
							idCampEsp not in (select inbound_id from ccInboundAgentes where user_id=@user and IDWG=@IDWG)

							if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
								insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
							end
						end
				 end
				 else if @Type in(2, 6)
				 begin
					-- -Supervisor	@Type in (2,6)
					insert into ccRIAWorkGroupUsers(IDWG, User_id) values (@IDWG, @user)
					select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
					if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
						insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
					end

					insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
					select @user, idCampEsp, 0, @IDWG
					from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
					 and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@user and tipo=0 and IDWG=@IDWG)

					update ccSupervisorCam
					set monitored = 1
					where user_id = @user
					and cam_id in (select cam_id from ccSupervisorCam where user_id=@user and tipo=0 and IDWG=@IDWG)
					and tipo = 0
					and IDWG <> @IDWG
					and monitored = 0

					insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
					select @user, idCampEsp, 1, @IDWG
					from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
					 and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@user and tipo=1 and IDWG=@IDWG)

					update ccSupervisorCam
					set monitored = 1
					where user_id = @user
					and cam_id in (select cam_id from ccSupervisorCam where user_id=@user and tipo=1 and IDWG=@IDWG)
					and tipo = 1
					and IDWG <> @IDWG
					and monitored = 0
				end
				
			end
		end
		set @id = @id+1
	end
end




if @option = 2 -- Delete Agent-Supervisor from WorkGroup
 begin

	while @id<=@count
	begin
		select @user = user_id from #UsersList where Row= @id
		select @Type = tipoUser_id from ccUsers where user_id = @user
		
		if @Type = 1 --delete skill media
		exec ccsp_Skills @action= 4,@userId=@user,@idwg=@IDWG
		
		if exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @user)
		begin
		
			Delete ccRIAWorkGroupUsers where IDWG = @IDWG and User_id = @user
		
			if @Type = 1 -- Agente
			 begin
				select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
	 			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 	from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
				insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG

	 			delete from cccampsagente where user_id=@user and IDWG=@IDWG
				delete from ccInboundagentes where user_id=@user and IDWG=@IDWG
				--select @Type
			 end
			 else if @Type in(2, 6) -- Supervisor
			 begin
				select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
				insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
				delete ccSupervisorCam where user_id=@user and IDWG=@IDWG
				--select @Type
			end
		end
		set @id = @id+1
	end
end
if @option in (1,2)
begin
	if LEN(@Assigned) > 0
		select SUBSTRING(@Assigned,0,Len(@Assigned))
	else
		select @Assigned

	return(0)
end

if @option = 3 -- Insert WorkGroup in Camp or ACDGroup	
  begin
    select @count = count(CampEsp) from #CampsInOutList

    while @id<=@count
	begin
		 select @IDCampEsp = CampEsp, @Type = Type from #CampsInOutList where Row= @id
		 

		 if (select count(IdCampEsp) from ccRIACampEspWG where IdCampEsp=@IDCampEsp and Tipo=@Type) < (select valor from ccSettings where setting_id=180) -- limit
			 begin

				if (select count(IDWG) from ccRIACampEspWG where IDWG=@IDWG) < (select valor from ccSettings where setting_id=64) -- limit
					begin

						if not exists (select IDWG from ccRIACampEspWG where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) -- No existe el grupo en el ACD o Especialidad
						begin

							insert into ccRIACampEspWG (IDWG, Tipo, IdCampEsp, priority) values (@IDWG, @Type, @IDCampEsp, 1)
							if not exists(select * from ccRIACampEspWGConsulta where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) begin
								insert into ccRIACampEspWGConsulta (IDWG, Tipo, IdCampEsp) values (@IDWG, @Type, @IDCampEsp)
							end
				

							exec ccsp_RIACalcula_WGPriority @IDWG, @IDCampEsp, @Type
							if @Type in (0, 1) -- ACDGroup
							begin

								if @IDWG is not null or @IDWG = 0
								begin
									if @Type=0 --ACDGroup
									begin
										select @AssignedCampsIn = @AssignedCampsIn+ cast(@IDCampEsp as varchar(5))+'',''
										insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
										SELECT distinct u.user_id, @IDCampEsp, 0 cli_id, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG 
										FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
											join ccusers s on u.user_id = s.user_id
										WHERE c.tipo=0 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and c.IDWG=@IDWG 
										and u.User_id not in (select User_id from ccInboundAgentes where Inbound_id=@IDCampEsp and IDWG=@IDWG)

										insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
										select b.user_id, @IDCampEsp, 0, @IDWG
										from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
											join ccusers s on b.user_id = s.user_id
										where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=0
											and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=0 and IDWG=@IDWG)
			 
										--return(0)
									end

									else if @Type = 1 -- Camp
									begin
										select @AssignedCampsOut = @AssignedCampsOut+ cast(@IDCampEsp as varchar(5))+'',''
										insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
										SELECT distinct u.user_id, @IDCampEsp, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG
										FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
										join ccusers s on u.user_id = s.user_id
										WHERE c.tipo=1 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and u.IDWG=@IDWG 
											and u.User_id not in (select User_id from ccCampsAgente where cam_id=@IDCampEsp and IDWG=@IDWG)
			
										insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
										select b.user_id, @IDCampEsp, 1, @IDWG
										from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
											join ccusers s on b.user_id = s.user_id
										where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=1
											and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=1 and IDWG=@IDWG)
									end
							end
						end
					end
				end
			end
		set @id = @id + 1
   end
end

if @option = 3
begin
	
if LEN(@AssignedCampsIn) > 0 or LEN(@AssignedCampsOut) > 0
		select SUBSTRING(@AssignedCampsIn,0,Len(@AssignedCampsIn)) as CampsInAssigned, SUBSTRING(@AssignedCampsOut,0,Len(@AssignedCampsOut)) as CampsOutAssigned 
	else
		select @AssignedCampsIn as CampsInAssigned, @AssignedCampsOut as CampsOutAssigned

	return(0)
end

if @option = 4  --Delete relatoion Camp with WG
begin
declare @multipleAgents varchar(1000)
declare @multipleAdmins varchar(2000)
declare @sql varchar(max)

select @count = count(CampEsp) from #CampsInOutList
 while @id<=@count
  begin

		select @IDCampEsp = CampEsp, @Type = Type from #CampsInOutList where Row= @id

		SELECT @multipleAgents = coalesce(@multipleAgents + '','', '''') + CAST(A.user_id AS VARCHAR(40))
		FROM ccRIAWorkGroupUsers A
		JOIN ccUsers B ON A.user_id = B.user_id
		WHERE IDWG = @IDWG AND TipoUser_id = 1

		SELECT @multipleAdmins = coalesce(@multipleAdmins + '','', '''') + CAST(A.user_id AS VARCHAR(40))
		FROM ccRIAWorkGroupUsers A
		JOIN ccUsers B ON A.user_id = B.user_id
		WHERE IDWG = @IDWG AND TipoUser_id = 2

		--Delete Agent from WorkGroup
		   set @sql = ''ccsp_RIA_ABCAgents @option=7,@UserId=''''0'''',@Login='''''''',@Nombres='''''''',@ApellidoPaterno='''''''',@ApellidoMaterno='''''''',@Password='''''''',@Sexo=0,@canChangeStatus=0,
					@AreaId=0,@UserType=0,@IDWG=''+cast(@IDWG as varchar(4))+'',@DeleteUsers=0,@InOut=''+cast(@Type as varchar(4))+'',@IDCampEsp=''+cast(@IDCampEsp as varchar(4))+'',@multipleUsers=''''''+@multipleAgents+''''''''
		   exec(@sql)

		 --Delete Supervisor from WorkGroup

		 set @sql = ''ccsp_RIA_ABCAgents @option=8,@UserId=''''0'''',@Login='''''''',@Nombres='''''''',@ApellidoPaterno='''''''',@ApellidoMaterno='''''''',@Password='''''''',@Sexo=0,@canChangeStatus=0,
					@AreaId=0,@UserType=0,@IDWG=''+cast(@IDWG as varchar(4))+'',@DeleteUsers=0,@InOut=''+cast(@Type as varchar(4))+'',@IDCampEsp=''+cast(@IDCampEsp as varchar(4))+'',@multipleUsers=''''''+@multipleAdmins+''''''''
		   exec(@sql)

		--Delete WokGroup from ACD or Camp 

		 set @sql = ''exec ccsp_RIA_ABCWorkGroups @option=7,@IDWG=''+cast(@IDWG as varchar(4))+'',@IDCampEsp=''''''+cast(@IDCampEsp as varchar(4))+'''''',@Type=''+cast(@Type as varchar(4))+''''
		 exec(@sql)
		set @id = @id + 1
	
	end

	select 1
end

'
        EXEC(@sql)

	set @process = 'CW-4658 Se modifica sp ccsp_GalateaAdminGetAgentCounters para agregar nueva consulta | CW-4804 para agregar consulta de información de agentes por grupo de trabajo y id de administrador'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminGetAgentCounters] @type AS     INT, 
                                                    @sup_id AS   INT = 0, 
                                                    @agent_id AS INT = 0, 
                                                    @WG AS       INT = 0,
													@campId AS INT = 0
	 AS
     SET NOCOUNT ON;
     IF @type = 1
         BEGIN
             WITH TableUserAgent(userId)
                  AS (SELECT DISTINCT 
                           wgAgt.User_id  AS Id --,usr.login 
                      FROM ccriaworkgroupusers wgAdmin
                           INNER JOIN ccriaworkgroupusers wgAgt ON wgAdmin.IDWG = wgAgt.IDWG
                           INNER JOIN ccUsers usr ON usr.User_id = wgAgt.User_id
                                                     AND usr.TipoUser_id = 1
                      WHERE wgAdmin.User_id = @sup_id)
                  SELECT CAST(a.User_id AS INT) Id, 
                         a.login AS Username, 
                         a.Nombres + '' '' + a.ApellidoPaterno + '' '' + a.ApellidoMaterno AS Name
                  FROM ccusers a(NOLOCK)--, ccGenViewRelsSupsAgent b
                       INNER JOIN TableUserAgent b ON a.User_id = b.userId
                  ORDER BY a.Login ASC;
     END;
     IF @type = 2
         BEGIN
             SELECT CAST(User_id AS INT) Id,
					Login Username, 
                    Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno Name
             FROM ccUsers
             WHERE User_id = @agent_id;
     END;
     IF @type = 3 --Agents by supervisor and WG
         BEGIN
             DECLARE @table2 TABLE
             (userId INT
              PRIMARY KEY NOT NULL
             );
             INSERT INTO @table2
                    SELECT DISTINCT 
                           wg.User_id
                    FROM ccRIAWorkGroupUsers wg
                         LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                    WHERE us.TipoUser_id = 1
                          AND wg.IDWG IN
                    (
                        SELECT IDWG
                        FROM ccRIAWorkGroupUsers
                        WHERE User_id = @sup_id
                              AND IDWG <> @WG
                    );
             SELECT CAST(B.User_id AS int) AS Id
             FROM @table2 A
                  RIGHT JOIN
             (
                 SELECT DISTINCT 
                        wg.User_id
                 FROM ccRIAWorkGroupUsers wg
                      LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                 WHERE wg.IDWG = @WG
                       AND us.TipoUser_id = 1
             ) B ON A.userId = B.User_id
             WHERE A.userId IS NULL;
     END;

	 IF @type = 4 --Agents IDs by WG
     BEGIN
		SELECT  CAST(wg.User_id AS INT) Id  
		FROM ccRIAWorkGroupUsers wg
		JOIN CCUsers u on u.user_id = wg.user_id AND u.TipoUser_id = 1
		where IDWG = @WG
     END;

	 IF @type = 5 --Agents IDs by Campaign
     BEGIN
		SELECT Distinct(CAST(U.User_id AS INT)) Id FROM ccRIACampEspWG camp
		JOIN ccRIAWorkGroupUsers wg ON camp.IDWG = wg.IDWG
		JOIN ccUsers U ON U.User_id = WG.User_id AND U.TipoUser_id = 1
		WHERE IdCampEsp = @campId AND TIPO = 1
     END;

	  IF @type = 6 -- Get Agent current state
	 BEGIN
		WITH UserMaxFecha(User_id,fecha) as(
			SELECT User_id,max(fecha) as fecha from ccLogAgentesDia where fecha>=convert(date,getdate()) group by User_id
		)

		SELECT CASE WHEN CurrentState.currentStatus is null or  CurrentState.currentStatus<0 
					then 0 else CAST(CurrentState.currentStatus as int) end CurrentState
		from ccUsers u
		left join 
		(
		select A.User_id,B.currentStatus from UserMaxFecha A 
		inner join ccLogAgentesDia  B on A.User_id=B.User_id and A.fecha=B.fecha
		) CurrentState on u.User_id=CurrentState.User_id
		where u.TipoUser_id=1 and u.User_id = @agent_id
	 END

	 IF @type = 7 -- Get superuser id''s except root
	 BEGIN
		declare @superuserId as int
		set @superuserId = (select Rol_id from ccRoles where Level = 7) -- obtenemos el id del rol superusuario

		select CAST(cr.User_id AS INT) User_id 
		from ccUsers_Roles cr
		where Rol_id = @superuserId
		and cr.User_id not in (1) 
	 END

	 IF @type = 8 -- Get all Agent''s ID, Login and Full Names related to an Administrator and workgroup
			 BEGIN
				DECLARE @table3 TABLE
					(userId INT
					PRIMARY KEY NOT NULL
					);
				INSERT INTO @table3
					SELECT DISTINCT 
							wg.User_id
					FROM ccRIAWorkGroupUsers wg
							LEFT JOIN ccUsers us ON wg.User_id = us.User_id
					WHERE us.TipoUser_id = 1
							AND wg.IDWG IN
					(
						SELECT IDWG
						FROM ccRIAWorkGroupUsers
						WHERE User_id = @sup_id
								AND IDWG <> @WG
					);
				SELECT CAST(B.User_id AS int) AS Id,
				B.username,
				B.Name
				FROM @table3 A
					RIGHT JOIN
				(
					SELECT DISTINCT 
						wg.User_id,
						us.Login as Username,
						us.Nombres + '' '' + us.ApellidoPaterno + '' '' + us.ApellidoMaterno Name
					FROM ccRIAWorkGroupUsers wg
						LEFT JOIN ccUsers us ON wg.User_id = us.User_id
					WHERE wg.IDWG = @WG
						AND us.TipoUser_id = 1
				) B ON A.userId = B.User_id
				WHERE A.userId IS NULL;
			 END

     SET NOCOUNT ON;'
	exec (@sql)

	set @process = 'CW-4377 Alter sp ccsp_RIAvoiceMail'
	set @sql='
		ALTER procedure [dbo].[ccsp_RIAvoiceMail]
		@type as tinyint,
		@msgId int=null,
		@bSent int=null,
		@mailType int = 0 -- Other=0; ChatMailAdmin=1; ChatMailClient=2
		as
		set nocount on
		if @type=1 -- getSettings
		 begin
			declare @SMTP_setting varchar(255)
			declare @svr as varchar(50), @usr as varchar(50), @pwd as varchar(50), @ssl as bit, @typeSend as bit
			declare @smtpPort as integer

			select @SMTP_setting=valor from ccsettings where setting_id=98
			select @svr = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 1
			select @usr = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 2
			select @pwd = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 3	
			select @smtpPort = cast(value as integer) from  dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 4
			select @ssl = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 5
			select @typeSend = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 6
			if isnull(@smtpPort,0)=0 set @smtpPort=25
			if isnull(@ssl,0)=0 set @ssl=0
			if isnull(@typeSend,0)=0 set @typeSend=0
	
			select isNull(@svr,'''')  as svr, isNull(@usr,'''') as usr, isNull(@pwd,'''') as pwd, @smtpPort as smtpPt, @ssl as [ssl], @typeSend as [typeSend]
			return(0)
		 end

		else if @type=2 begin-- getMailBoxes 
			if isnull(@msgId,0)=0
			 begin
				raiserror(''Missing msgId'', 18, 1)
				return(0)
			 end

			declare @inbound_id int, @calid int, @acdName varchar(50)

			if @mailType = 0 begin
				select @calid=cal_id from ccRIA_vmMessages where vmID=@msgId
				select @inbound_id=inbound_id from ccCallsIn where cal_id=@calid
			end
			else begin
				select @calid=chatId from ccRIAChatMailbox where ID=@msgId
				select @inbound_id=inboundId from ccRIAChats where chatId=@calid
			end
	
			select @acdName = descripcion from ccInbound where Inbound_id = @inbound_id
	
			if @mailType = 2 begin
				select '''', @acdName as acdName
				return(0)
			end

			select mailbox, @acdName as acdName from ccRIA_vmMailBoxes M join ccRIA_vmACDMailBoxes A on M.vmID = A.vmID
			where A.inbound_id in (0,@inbound_id)
			return(0)
		 end

		else if @type=3 begin-- getNext
 
		 declare @mailBySend table(
			idm int,
			nameFile varchar(256),
			[type] int,
			Inbound_id int,
			acdName varchar(100),
			phone varchar(13)
			)

			insert into @mailBySend
			select top 30  * from (
			select vmID, archivo, 1 as [type],C.Inbound_id,ISNULL(I.descripcion,'''') as acdName, C.cal_ANI as phone from ccRIA_vmMessages M
			inner join ccCallsIn C on M.cal_id=C.cal_id
			left join ccInbound I on C.Inbound_id=I.Inbound_id
			where vmStatus=0  
			union
			select M.ID, M.[file] as [file],2 as [type],C.inboundId,ISNULL(I.descripcion,'''') as acdName, ''0'' as phone from ccRIAChatMailbox M
			inner join ccRIAChats C on M.chatID=C.chatID
			left join ccInbound I on C.inboundId=I.Inbound_id
			where M.[status] = 0 
			)x
			where 
			Inbound_id in(

			select distinct A.inbound_id  from ccRIA_vmMailBoxes M 
			inner join ccRIA_vmACDMailBoxes A on M.vmID = A.vmID 
			)

	

			update A set vmintentos=vmintentos+1 from ccRIA_vmMessages A 
			inner join @mailBySend B on A.vmID=B.idm and B.type=1

			update A set tries=tries+1 from ccRIAChatMailbox A 
			inner join @mailBySend B on A.ID=B.idm and B.type=2
	
			select * from @mailBySend

			return(0)
		 end

		else if @type=4 begin-- setResult 
			if @bSent is null or isnull(@msgId,0)=0
			 begin
				raiserror(''Missing data'', 18, 1)
				return(0)
			 end

 			if @bSent=1  begin
				if @mailType = 0 begin
					update ccRIA_vmMessages set vmStatus=1 where vmID=@msgId			
				end
				else begin
					update ccRIAChatMailbox set [status] = 1 where ID = @msgId						
				end
				return(0)
			 end

			if @mailType = 0  begin
				update ccRIA_vmMessages set vmStatus=case when vmintentos<10 then vmStatus else 2 end where vmID=@msgId 
			end
			else begin
				update ccRIAChatMailbox set [status]=case when tries<10 then [status] else 2 end where ID=@msgId 
			end		
			return(0)	
	
	
			 end
			else if @type=5  begin-- reset vmintentos
				if @mailType = 0 begin
					update ccRIA_vmMessages set vmintentos=case when vmintentos>1 then vmintentos-1 else 0 end where vmID=@msgId		
				end
				else begin
					update ccRIAChatMailbox set tries=case when tries>1 then tries-1 else 0 end where [ID]=@msgId		
				end
			 end
	'
	exec (@sql)

		set @process = 'CW-4739 Se elimina si existe ccsp_GalateaAdminCampaigns'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminCampaigns'')
            begin		 
                DROP PROCEDURE ccsp_GalateaAdminCampaigns; 
		    end'
		exec (@sql)

		set @process = 'CW-4744 Se agrega InboundType para Obtener y mandar diferencia de tipos de ACD'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS SMALLINT, 
												   @CampType AS SMALLINT = 0, 
												   @WorkgroupId AS INT = 0, 
												   @Id AS INT = 0,
												   @AdminId AS SMALLINT = 0, 
												   @PinUpdate AS SMALLINT = 0, 
												   @LoadId AS INT = 0,
												   @Type AS SMALLINT = 0
		AS
		BEGIN
			set nocount on
			IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type 
			BEGIN
				IF @CampType = 1 -- Campaigns Out 
				BEGIN
					IF @WorkgroupId IS NOT NULL
					BEGIN
						SELECT CAST(IdCampEsp AS INT) AS Id 
						FROM ccRIACampEspWG 
						WHERE IDWG = @WorkgroupId AND Tipo=1
						ORDER BY IdCampEsp ASC
					END
					ELSE
					BEGIN
						raiserror(''ERROR. No existe una lista de campa?as de salida con el id de grupo de trabajo especificado'', 18, 1)
					END	
				END
				IF @CampType = 0 -- Campaigns In (ACD)
				BEGIN
					IF @WorkgroupId IS NOT NULL
					BEGIN
						SELECT CAST(IdCampEsp AS INT) AS Id 
						FROM ccRIACampEspWG 
						WHERE IDWG = @WorkgroupId AND Tipo=0
						ORDER BY IdCampEsp ASC
					END
					ELSE
					BEGIN
						raiserror(''ERROR. No existe una lista de campa?as de entrada con el id de grupo de trabajo especificado'', 18, 1)
					END	
				END
			END
			
			IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id 
				BEGIN
					IF @CampType = 1 -- Campaigns Out 
						BEGIN
							IF @Id IS NOT NULL
								BEGIN
									SELECT DISTINCT 
										camps.cam_id AS Id, 
										camps.cam_descripcion AS Name, 
										CAST(graph.graphic_id AS INT) AS Frame, 
										CAST(1 AS SMALLINT) AS Type,
										camps.cam_procesando IsStarted,
										a.AreaName as Area
									FROM ccCamps camps 
									LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
									left join ccRIACat_Areas a on a.IDArea = camps.IDArea
									WHERE camps.cam_id = @Id 
									ORDER BY camps.cam_descripcion ASC;
								END
							ELSE
							BEGIN
								raiserror(''ERROR. No existe campa?as de salida con el id especificado'', 18, 1)
							END	
						END
					IF @CampType = 0 -- Campaigns In (ACD)
						BEGIN
							IF @Id IS NOT NULL
								BEGIN
									SELECT DISTINCT 
										inb.Inbound_id AS Id, 
										inb.descripcion AS Name, 
										CAST(graph.graphic_id AS INT) AS Frame,
										CAST(0 AS SMALLINT) AS Type,
										CAST(inb.Status AS BIT) IsStarted,
										a.AreaName AS Area,
										inb.chat AS InboundType
									FROM ccInbound inb
									LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
									left join ccRIACat_Areas a on a.IDArea = inb.IDArea
									WHERE inb.Inbound_id = @Id 
									ORDER BY inb.descripcion ASC;
								END
							ELSE
								BEGIN
									raiserror(''ERROR. No existe campa?as de entrada con el id especificado'', 18, 1)
								END	
						END
				END

			IF @Option = 3   -- Update OverallTotalNew By Campaign 
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							UPDATE ccCampsNvosCB SET OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id
						END
					ELSE
						BEGIN
							raiserror(''ERROR. No existe la campa?as de entrada con el id especificado'', 18, 1)
						END	
				END

			IF @Option = 4	 -- Update Pin from Campaign per Admin
				BEGIN
					IF @Id IS NOT NULL AND @AdminId IS NOT NULL
						BEGIN
							IF @PinUpdate = 1
								BEGIN
									INSERT INTO PinedCampaigns (CampId, AdminId, Type)
										   VALUES (@Id, @AdminId, @Type);
								END;
							IF @PinUpdate = 0
								BEGIN
									DELETE FROM PinedCampaigns
									WHERE CampId = @Id AND AdminId = @AdminId AND Type = @Type;
								END;
						END
					ELSE
						BEGIN
							raiserror(''ERROR. La campa?as o administrador no existen'', 18, 1)
						END	
				END
			
			IF @Option = 5	 -- Get Pin from Campaign Ids per Admin
				BEGIN
					IF @AdminId IS NOT NULL
						BEGIN
							SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
							ORDER BY Id ASC
						END
					ELSE
						BEGIN
							raiserror(''ERROR. El administrador con el id seleccionado no existe'', 18, 1)
						END	
				END

			IF @Option = 6	 -- Get Blacklist Ids by Campaign Id
			BEGIN
				IF @Id IS NOT NULL
					BEGIN
			            DECLARE @BlackListIds VARCHAR(MAX);
			            SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
			            FROM Camplistanegra
			            WHERE cam_id = @Id AND STATUS = 1;
			            SELECT isnull(@BlackListIds,''0'') AS BlackListIds;
					END
				ELSE
					BEGIN
						raiserror(''ERROR. La campa?as con el id seleccionado no existe'', 18, 1)
					END	
			END

			IF @Option = 7	 -- Get RegistryListIds Ids by Campaign Id
			BEGIN
				IF (@Id IS NOT NULL AND EXISTS(SELECT * FROM cccamps WHERE cam_id = @Id))
					BEGIN
						SELECT TOP 1 list_id FROM ccRIARegistryLists WHERE cam_id = @Id AND status = 2 ORDER BY list_id DESC
					END
				ELSE
					BEGIN
						--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
						raiserror(''ERROR. No existe una campa?a con el id especificado'', 18, 1)			
					END	
			END

			IF @Option = 8	 -- Delete RegistryListIds Ids by LoadId
			BEGIN
				IF (@LoadId IS NOT NULL AND EXISTS(SELECT * FROM ccRIARegistryLists WHERE list_id = @loadID and status <> 0))
					BEGIN
						UPDATE ccoCallsOutSource SET cal_status = ''5'' WHERE list_id = @loadID
						DELETE FROM ccoWorkingTable WHERE list_id = @LoadId 
						exec ccsp_RIARegistryLists @action=6, @list_id = @LoadId 
					END
				ELSE
					BEGIN
						--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
						raiserror(''ERROR. No existe una carga el id especificado'', 18, 1)
					END		
			END

			 IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
		         BEGIN
		             DECLARE @table TABLE
		             (camId    INT, 
		              campType TINYINT,
		              PRIMARY KEY(camId, campType)
		             );
		             INSERT INTO @table
		                    SELECT DISTINCT 
		                           IdCampEsp, 
		                           Tipo
		                    FROM ccRIACampEspWG wg
		                    WHERE wg.IDWG IN
		                    (
		                        SELECT IDWG
		                        FROM ccRIAWorkGroupUsers
		                        WHERE IDWG <> @WorkgroupId
		                        AND User_id = @AdminId
		                    );
		             SELECT CAST(B.IdCampEsp AS INT) AS Id, 
		                    B.Tipo AS Type
		             FROM @table A
		                  RIGHT JOIN
		             (
		                 SELECT wg.IdCampEsp, 
		                        wg.Tipo
		                 FROM ccRIACampEspWG wg
		                 WHERE wg.IDWG = @WorkgroupId
		             ) B ON A.camId = B.IdCampEsp
		                    AND A.campType = B.Tipo
		             WHERE A.camId IS NULL
		             ORDER BY IdCampEsp;
		     END;
		END'
		exec (@sql)

		set @process = 'CW-4748 Eliminar sp ccsp_GalateaDeleteWorkingTable'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaDeleteWorkingTable'')
				    begin
						DROP PROCEDURE ccsp_GalateaDeleteWorkingTable;
				    end'
		EXEC(@sql)

		set @process = 'CW-4748 Creacion del sp ccsp_GalateaDeleteWorkingTable'
		set @sql = '-- =============================================
-- Author:		UEspinosa
-- Create date: 03/12/20
-- Description:	Eliminacion de registros de WorkingTable
-- =============================================
CREATE PROCEDURE ccsp_GalateaDeleteWorkingTable
	@DeleteCamId	  VARCHAR(MAX) = ''158''
AS
BEGIN
	IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
		SELECT value As DeleteCamId into #CampsDelete FROM fn_RIASplitDelimited(@DeleteCamId, '','')

	delete TOP(3000) from ccoWorkingTable where cam_id in (select DeleteCamId from #CampsDelete)

	SELECT COUNT(callout_id) FROM ccoWorkingTable WHERE cam_id in (select DeleteCamId from #CampsDelete)
END'
		EXEC(@sql)

		set @process = 'CW-4748 Eliminar sp ccsp_GalateaDeleteCampaignAndACD'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaDeleteCampaignAndACD'')
				    begin
						DROP PROCEDURE ccsp_GalateaDeleteCampaignAndACD;
				    end'
		EXEC(@sql)

		set @process = 'CW-4748 Creacion del sp ccsp_GalateaDeleteCampaignAndACD'
		set @sql = '-- =============================================
-- Author:		UEspinosa
-- Create date: 03/12/2020
-- Description:	Eliminacion logica de las campañas y ACD
-- =============================================
CREATE PROCEDURE [dbo].[ccsp_GalateaDeleteCampaignAndACD]
	--declare
	@userId           SMALLINT,
	@DeleteCamId	  VARCHAR(MAX),
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

	END

	IF datalength(@DeleteCamId) > 0
		Insert into ccRIALog Select * from #CampLog
	IF datalength(@DeleteACDGroupId) > 0
		Insert into ccRIALog Select * from #ACDLog
	
	SELECT DeleteCamId AS DeleteId,IDAreaCamp AS IDArea,CampTypeCamp AS CampType,''1'' AS Result FROM #CampsDelete
	UNION
	SELECT DeleteACDId,IDAreaACD,CampTypeACD,''1'' AS Result FROM #ACDDelete
	IF OBJECT_ID(''tempdb..#CampsDelete'') IS NOT NULL DROP TABLE #CampsDelete
	IF OBJECT_ID(''tempdb..#ACDDelete'') IS NOT NULL DROP TABLE #ACDDelete
END
'
		EXEC(@sql)

		 set @process = 'Show Phone Call Agent'
  		set @sql = 'update ccsettings set valor=''0'' where setting_id=223'
 	 exec (@sql)

		set @process = 'Agregar permiso para la gestion de campañas'
		set @sql = 'if not exists(select * from ccPermissions where KeyJson = ''PermissionCampaignManagement'')
begin
	insert into ccPermissions values (10013,''Gestion de Campañas eliminar,agregar, etc'',''PermissionCampaignManagement'',0,0,0,''N/A'',1)
end

if not exists(select * from ccRoles_Permissions where Rol_Id = 1 and Permissions_Id = 10013)
begin
	insert into ccRoles_Permissions values (1,10013)
end'
		EXEC(@sql)
		set @process = 'CW-4810 Se insertan permisos de horarios en ccPermissions'
		set @sql = 'if not exists (select * from  [CCenterRia].[dbo].[ccPermissions] where Permissions_Id = 10014) 
		begin
			INSERT INTO [CCenterRia].[dbo].[ccPermissions]([Permissions_Id], [Description], [KeyJson], [Parent], [Type], [OrderGrl] ,[Release] ,[Active])
			VALUES	(10014,''Gestionar horarios'',''RolesPermissionSchedulesManagment'',0,0,0,''N/A'',1)
		end'
		exec(@sql)
		set @process = 'CW-4810 Se inserta permiso en super usuario'
		set @sql = ' if not exists ( select * from ccRoles_Permissions where Rol_Id = 1 and Permissions_Id = 10014)
				begin
					INSERT INTO [CCenterRia].[dbo].[ccRoles_Permissions]([Rol_Id], [Permissions_Id]) VALUES	(1,10014)
				end'
	exec(@sql)
	
	
	
		set @process = 'CW-4796 DROP PROCEDURE [dbo].[ccsp_GalateaManageWG]'
set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaManageWG'')
    begin
        DROP PROCEDURE ccsp_GalateaManageWG;
    end'
EXEC(@sql)
     
		set @process = 'CW-4796 CREATE PROCEDURE [dbo].ccsp_GalateaManageWG'
        set @sql = '

CREATE PROCedure [dbo].[ccsp_GalateaManageWG]
@option smallint,
@IDWG smallint,
@Type smallint = 0,
@usersList varchar(max) ='''',
@ListCampsIn varchar(max) = '''',
@ListCampsOut varchar(max) ='''',
@idNewArea int = 0
as
set nocount on
declare @count int
declare @id int
declare @user int
declare @IDCampEsp varchar(max)
declare @Assigned  varchar(max)
declare @AssignedCampsIn  varchar(max)
declare @AssignedCampsOut  varchar(max)

set @id = 1
set @Assigned = ''''
set @AssignedCampsIn = ''''
set @AssignedCampsOut = ''''


IF OBJECT_ID(''tempdb..#UsersList'') IS NOT NULL DROP TABLE #UsersList;
IF OBJECT_ID(''tempdb..#CampsInOutList'') IS NOT NULL DROP TABLE #CampsInOutList;

select *  into #CampsInOutList from (
select ROW_NUMBER() OVER(ORDER BY [CampEsp] ASC) AS Row, [CampEsp], [Type] from (
	select 0 as [Type],
	[value] As [CampEsp]
	FROM fn_RIASplitDelimited(@ListCampsIn, '','') where [value] > 0
	union
	select 1 as [Type],
	[value] As [CampEsp]
	FROM fn_RIASplitDelimited(@ListCampsOut, '','') where [value] > 0
	) as Camps ) as CampsInOut


select ROW_NUMBER() OVER(ORDER BY value ASC) AS Row,
	value As user_id
	into #UsersList
	FROM fn_RIASplitDelimited(@usersList, '','')

select @count = count(user_id) from #UsersList

if @option = 1 -- Insert Agente-Supervisor in WorkGroup
 begin

	while @id<=@count
	begin
		select @user = user_id from #UsersList where Row= @id
		select @Type = tipoUser_id from ccUsers where user_id = @user

		if @Type in(1, 2, 6)
		begin

			if not exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @user)
			begin
			

				If @Type = 1
				 begin

						If (select count(User_id) from ccRIAWorkGroupUsers where User_id = @user) < (select valor from ccSettings where setting_id = 63)
						 begin
							insert into ccRIAWorkGroupUsers(IDWG, User_id) values(@IDWG,@user)
							select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
							--insert skill media
							exec ccsp_Skills @action= 5,@userId=@user

							insert into cccampsAgente (user_id, cam_id, prioridad, skill, IDWG)
							select @user, idCampEsp, dbo.fn_Calcula_UsrPriority(@user,0), 1, @IDWG
							from ccRIACampEspWG where tipo = 1 and IDWG = @IDWG and
							 idCampEsp not in (select cam_id from cccampsAgente where user_id=@user and IDWG=@IDWG)

							insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, IDWG)
							select @user, idCampEsp, 0, dbo.fn_Calcula_UsrPriority(@user,0), 1, @IDWG
							from ccRIACampEspWG where tipo = 0 and IDWG = @IDWG and
							idCampEsp not in (select inbound_id from ccInboundAgentes where user_id=@user and IDWG=@IDWG)

							if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
								insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
							end
						end
				 end
				 else if @Type in(2, 6)
				 begin
					-- -Supervisor	@Type in (2,6)
					insert into ccRIAWorkGroupUsers(IDWG, User_id) values (@IDWG, @user)
					select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
					if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
						insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
					end

					insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
					select @user, idCampEsp, 0, @IDWG
					from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
					 and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@user and tipo=0 and IDWG=@IDWG)

					update ccSupervisorCam
					set monitored = 1
					where user_id = @user
					and cam_id in (select cam_id from ccSupervisorCam where user_id=@user and tipo=0 and IDWG=@IDWG)
					and tipo = 0
					and IDWG <> @IDWG
					and monitored = 0

					insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
					select @user, idCampEsp, 1, @IDWG
					from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
					 and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@user and tipo=1 and IDWG=@IDWG)

					update ccSupervisorCam
					set monitored = 1
					where user_id = @user
					and cam_id in (select cam_id from ccSupervisorCam where user_id=@user and tipo=1 and IDWG=@IDWG)
					and tipo = 1
					and IDWG <> @IDWG
					and monitored = 0
				end
				
			end
		end
		set @id = @id+1
	end
end




if @option = 2 -- Delete Agent-Supervisor from WorkGroup
 begin

	while @id<=@count
	begin
		select @user = user_id from #UsersList where Row= @id
		select @Type = tipoUser_id from ccUsers where user_id = @user
		
		if @Type = 1 --delete skill media
		exec ccsp_Skills @action= 4,@userId=@user,@idwg=@IDWG
		
		if exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @user)
		begin
		
			Delete ccRIAWorkGroupUsers where IDWG = @IDWG and User_id = @user
		
			if @Type = 1 -- Agente
			 begin
				select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
	 			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 	from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
				insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG

	 			delete from cccampsagente where user_id=@user and IDWG=@IDWG
				delete from ccInboundagentes where user_id=@user and IDWG=@IDWG
				--select @Type
			 end
			 else if @Type in(2, 6) -- Supervisor
			 begin
				select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
				insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
				delete ccSupervisorCam where user_id=@user and IDWG=@IDWG
				--select @Type
			end
		end
		set @id = @id+1
	end
end
if @option in (1,2)
begin
	if LEN(@Assigned) > 0
		select SUBSTRING(@Assigned,0,Len(@Assigned))
	else
		select @Assigned

	return(0)
end

if @option = 3 -- Insert WorkGroup in Camp or ACDGroup	
  begin
    select @count = count(CampEsp) from #CampsInOutList

    while @id<=@count
	begin
		 select @IDCampEsp = CampEsp, @Type = Type from #CampsInOutList where Row= @id
		 

		 if (select count(IdCampEsp) from ccRIACampEspWG where IdCampEsp=@IDCampEsp and Tipo=@Type) < (select valor from ccSettings where setting_id=180) -- limit
			 begin

				if (select count(IDWG) from ccRIACampEspWG where IDWG=@IDWG) < (select valor from ccSettings where setting_id=64) -- limit
					begin

						if not exists (select IDWG from ccRIACampEspWG where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) -- No existe el grupo en el ACD o Especialidad
						begin

							insert into ccRIACampEspWG (IDWG, Tipo, IdCampEsp, priority) values (@IDWG, @Type, @IDCampEsp, 1)
							if not exists(select * from ccRIACampEspWGConsulta where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) begin
								insert into ccRIACampEspWGConsulta (IDWG, Tipo, IdCampEsp) values (@IDWG, @Type, @IDCampEsp)
							end
				

							exec ccsp_RIACalcula_WGPriority @IDWG, @IDCampEsp, @Type
							if @Type in (0, 1) -- ACDGroup
							begin

								if @IDWG is not null or @IDWG = 0
								begin
									if @Type=0 --ACDGroup
									begin
										select @AssignedCampsIn = @AssignedCampsIn+ cast(@IDCampEsp as varchar(5))+'',''
										insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
										SELECT distinct u.user_id, @IDCampEsp, 0 cli_id, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG 
										FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
											join ccusers s on u.user_id = s.user_id
										WHERE c.tipo=0 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and c.IDWG=@IDWG 
										and u.User_id not in (select User_id from ccInboundAgentes where Inbound_id=@IDCampEsp and IDWG=@IDWG)

										insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
										select b.user_id, @IDCampEsp, 0, @IDWG
										from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
											join ccusers s on b.user_id = s.user_id
										where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=0
											and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=0 and IDWG=@IDWG)
			 
										--return(0)
									end

									else if @Type = 1 -- Camp
									begin
										select @AssignedCampsOut = @AssignedCampsOut+ cast(@IDCampEsp as varchar(5))+'',''
										insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
										SELECT distinct u.user_id, @IDCampEsp, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG
										FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
										join ccusers s on u.user_id = s.user_id
										WHERE c.tipo=1 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and u.IDWG=@IDWG 
											and u.User_id not in (select User_id from ccCampsAgente where cam_id=@IDCampEsp and IDWG=@IDWG)
			
										insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
										select b.user_id, @IDCampEsp, 1, @IDWG
										from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
											join ccusers s on b.user_id = s.user_id
										where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=1
											and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=1 and IDWG=@IDWG)
									end
							end
						end
					end
				end
			end
		set @id = @id + 1
   end
end

if @option = 3
begin
	
if LEN(@AssignedCampsIn) > 0 or LEN(@AssignedCampsOut) > 0
		select SUBSTRING(@AssignedCampsIn,0,Len(@AssignedCampsIn)) as CampsInAssigned, SUBSTRING(@AssignedCampsOut,0,Len(@AssignedCampsOut)) as CampsOutAssigned 
	else
		select @AssignedCampsIn as CampsInAssigned, @AssignedCampsOut as CampsOutAssigned

	return(0)
end

if @option = 4  --Delete relatoion Camp with WG
begin
declare @multipleAgents varchar(1000)
declare @multipleAdmins varchar(2000)
declare @sql varchar(max)

select @count = count(CampEsp) from #CampsInOutList
 while @id<=@count
  begin

		select @IDCampEsp = CampEsp, @Type = Type from #CampsInOutList where Row= @id

		SELECT @multipleAgents = coalesce(@multipleAgents + '','', '''') + CAST(A.user_id AS VARCHAR(40))
		FROM ccRIAWorkGroupUsers A
		JOIN ccUsers B ON A.user_id = B.user_id
		WHERE IDWG = @IDWG AND TipoUser_id = 1

		SELECT @multipleAdmins = coalesce(@multipleAdmins + '','', '''') + CAST(A.user_id AS VARCHAR(40))
		FROM ccRIAWorkGroupUsers A
		JOIN ccUsers B ON A.user_id = B.user_id
		WHERE IDWG = @IDWG AND TipoUser_id = 2

		--Delete Agent from WorkGroup
		   set @sql = ''ccsp_RIA_ABCAgents @option=7,@UserId=''''0'''',@Login='''''''',@Nombres='''''''',@ApellidoPaterno='''''''',@ApellidoMaterno='''''''',@Password='''''''',@Sexo=0,@canChangeStatus=0,
					@AreaId=0,@UserType=0,@IDWG=''+cast(@IDWG as varchar(4))+'',@DeleteUsers=0,@InOut=''+cast(@Type as varchar(4))+'',@IDCampEsp=''+cast(@IDCampEsp as varchar(4))+'',@multipleUsers=''''''+@multipleAgents+''''''''
		   exec(@sql)

		 --Delete Supervisor from WorkGroup

		 set @sql = ''ccsp_RIA_ABCAgents @option=8,@UserId=''''0'''',@Login='''''''',@Nombres='''''''',@ApellidoPaterno='''''''',@ApellidoMaterno='''''''',@Password='''''''',@Sexo=0,@canChangeStatus=0,
					@AreaId=0,@UserType=0,@IDWG=''+cast(@IDWG as varchar(4))+'',@DeleteUsers=0,@InOut=''+cast(@Type as varchar(4))+'',@IDCampEsp=''+cast(@IDCampEsp as varchar(4))+'',@multipleUsers=''''''+@multipleAdmins+''''''''
		   exec(@sql)

		--Delete WokGroup from ACD or Camp 

		 set @sql = ''exec ccsp_RIA_ABCWorkGroups @option=7,@IDWG=''+cast(@IDWG as varchar(4))+'',@IDCampEsp=''''''+cast(@IDCampEsp as varchar(4))+'''''',@Type=''+cast(@Type as varchar(4))+''''
		 exec(@sql)
		set @id = @id + 1
	
	end

	select 1
	return 0
end

if @option = 5  --Change Admin Administrator.
begin
declare @user_id int
select @user_id = value FROM fn_RIASplitDelimited(@usersList, '','')
select @Type = TipoUser_id from ccUsers where User_id = @user_id

		if @Type = 1 -- Agente
        begin

			if(select count(user_id) from ccCampsAgente where user_id = @user_id) >0 or 
			(select count(user_id) from ccInboundAgentes where user_id = @user_id) >0 or
			(select count(user_id) from ccRIAWorkGroupUsers where user_id = @user_id) > 0
			begin
				select -1
				return 0
			end
			else
				update ccUsers set IDArea = @idNewArea where user_id = @user_id
		end

        
    if @Type in (2, 6) -- Supervisor
    begin

        if(select count(user_id) from ccSupervisorCam where user_id = @user_id) > 0 or
		(select count(user_id) from ccRIAWorkGroupUsers where user_id = @user_id) > 0
		begin
			select -1
			return 0
		end
		else
			update ccUsers set IDArea = @idNewArea where user_id = @user_id
    end

	update ccPosicion set user_id = 0 where user_id = @user_id

	select 1

end

set nocount off


'
        EXEC(@sql)



		set @process = 'CW-4796 DROP PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]'
set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaLoadUsersForManagement'')
    begin
        DROP PROCEDURE ccsp_GalateaLoadUsersForManagement;
    end'
EXEC(@sql)
     
		set @process = 'CW-4796 CREATE PROCEDURE [dbo].ccsp_GalateaLoadUsersForManagement'
        set @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]
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
		'

 EXEC(@sql)


	set @process = 'CW-4797 ALTER PROCEDURE [dbo].[ccspGalatea_Finder]'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspGalatea_Finder]
@action int,
@userId int = 0
AS
if @action = 1 begin--trae el nombre de la base de datos en BX
	select cast( WGCam.IdCampEsp as int) as [Value], cast(WGCam.Tipo as int)+1 as callType, c.cam_descripcion as label
		from ccRIAWorkGroupUsers Wguser
		inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
		inner join ccCamps c on  WGCam.IdCampEsp=c.cam_id and WGCam.Tipo=1		
		where Wguser.User_id=@userId
	union
	select cast( WGCam.IdCampEsp as int) as [Value], cast(WGCam.Tipo as int)+1 as callType, inb.descripcion as label
		from ccRIAWorkGroupUsers Wguser
		inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
		inner join ccInbound inb on  WGCam.IdCampEsp=inb.Inbound_id and WGCam.Tipo=0
		where Wguser.User_id=@userId
end
else if @action = 2 begin--trae el nombre de la base de datos en BX
	;
	with WgId as(select IDWG from ccRIAWorkGroupUsers Wguser where Wguser.User_id=@userId)

	select distinct cast(Wguser.User_id as int) as [Value],ccUsers.Login as label from ccRIAWorkGroupUsers  Wguser
	inner join WgId on Wguser.IDWG=WgId.IDWG
	inner join ccUsers on ccUsers.User_id =Wguser.User_id and TipoUser_id=1
end'
	EXEC(@sql)
	
	
  set @process = 'CW-4815 create table contactMeanInAzure'
  set @sql = 'if not exists (select * from sys.tables where name = N''contactMeanInAzure'')
begin
	CREATE TABLE [dbo].[contactMeanInAzure](
	[inboundId] [int] NOT NULL,
	[tenantId] [varchar](100) NOT NULL,
	[clientId] [varchar](100) NOT NULL,
	[clientSecret] [varchar](100) NOT NULL,
	[instance] [varchar](100) NOT NULL,
	[apiUrl] [varchar](100) NOT NULL,
	CONSTRAINT [PK_contactMeanInAzure] PRIMARY KEY CLUSTERED 
	(
		[inboundId] ASC
	)) ON [PRIMARY]
end'
  exec(@sql)
  
  set @process = 'CW-4815 create table contactMeanOutAzure'
  set @sql = 'if not exists (select * from sys.tables where name = N''contactMeanOutAzure'')
begin
	CREATE TABLE [dbo].[contactMeanOutAzure](
	[contactMeanOutId] [int] NOT NULL,
	[tenantId] [varchar](100) NOT NULL,
	[clientId] [varchar](100) NOT NULL,
	[clientSecret] [varchar](100) NOT NULL,
	[instance] [varchar](100) NOT NULL,
	[apiUrl] [varchar](100) NOT NULL,
	CONSTRAINT [PK_contactMeanOutAzure] PRIMARY KEY CLUSTERED 
	(
		[contactMeanOutId] ASC
	)) ON [PRIMARY]
end'
  exec(@sql)

  set @process = 'CW-4815 alter table messageMail'
  set @sql = 'if exists (select column_name from information_schema.columns  
	where table_name = ''messageMail'' and COLUMN_NAME = ''uid'' and character_maximum_length < 500)
begin
	declare @nSQL varchar(max)
	declare @PK_Name varchar(500)

	SELECT @PK_Name=name  
	FROM sys.key_constraints  
	WHERE type = ''PK'' AND OBJECT_NAME(parent_object_id) = N''messageMail''

	set @nSQL = ''alter table messageMail drop constraint ''+ @PK_Name
	execute(@nSQL)

	ALTER TABLE messageMail 
	ALTER COLUMN [uid] [varchar](500) Not NULL;

	set @nSQL= ''
	ALTER TABLE messageMail
	ADD CONSTRAINT ''+@PK_Name+'' PRIMARY KEY CLUSTERED ([messageId] ASC,[uid] ASC);''
	execute(@nSQL)
end'
  exec (@sql)

  set @process = 'CW-4816 drop procedure ccsp_MailAdminAccount'
  set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_MailAdminAccount'')
            begin
          DROP PROCEDURE ccsp_MailAdminAccount;
            end'
  exec (@sql)

  set @process = 'CW-4816 Se agrega sp ccsp_MailAdminAccount'
  set @sql = 'CREATE PROCEDURE [dbo].[ccsp_MailAdminAccount]
@action int,
@meanContactTypeId smallint = 1,
@contactMeanId int=0,
@name   varchar(30)=null,
@conexionInfo   varchar(255)=null,
@inboundId  int=0,
@connUser   varchar(60)=null,
@ConnPass   varchar(30)=null,
@numMessages    tinyint=null,
@timeAlertMessage   tinyint=null,
@isActive bit =null,
@UserId int =null,
@idArea smallint =null,
@maxMails tinyint =3,
@answerTimeOut tinyint=null,
@revisionTime varchar(10)=null,
@daysTwitterRecord varchar(10)=null,
@closeConversationTime varchar(10)=null
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

SET NOCOUNT ON;
/****
Conexion Info Email In
    protocol|server|ssl|port|cleanMail|revisionTime
Conexion Info Email Out
    serverOut|portOut|tls|sslOut
Conexion Info Twitter
    usuarioID|token|tokenSecret|time|daysTwitterRecord
***/


declare @isActiveMail bit
set @isActiveMail=0

if @action = 1 begin --checha si esta activo el servicio
    select @isActiveMail = valor from ccSettings where setting_id=152
    if @isActiveMail = 1 begin
        select @isActiveMail=(case when isActive = 1 and @isActiveMail = 1 then 1 else 0 end) from meanContactType where meanContactTypeId = 1
    end
    select @isActiveMail as isActiveMail
    return (0)
end
else if @action = 2 begin --Obsoleto para email - actualizado en case 23
    select A.inboundId as IdIn,A.conexionInfo as ConexionInfo,A.connUser as [Username],A.connPass as [Password], A.isActive as IsActive
        from ContactMeanIn A
            inner join ccInbound B on A.inboundId=B.Inbound_Id
        where meanContactTypeId = @meanContactTypeId and B.Status=1 and A.isActive=1
end
else if @action = 3 begin   --
    select name,conexionInfo,connUser,ConnPass,numMessages,timeAlertMessage,answerTimeOut from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 4 begin--insert or update relation mail whit ACD by in
    ---Es necesario cambiar [ccsp_NetworkSocialAdminAccount] por que tambien se ocupa aqui
    DECLARE @tableConexionInfo TABLE(  id int, value varchar(255))
    if @connUser=''''   set @connUser=''nuxiba@nuxiba.com''
    if not exists(select * from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId) begin
        if not exists(select * from ContactMeanIn where connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin
        if @name is null set @name=''''
        if @conexionInfo is null and @meanContactTypeId=1  set @conexionInfo=''''
        if @connUser is null set @connUser=''''
        if @connPass is null set @connPass=''''
        if @numMessages is null set @numMessages=3
        if @timeAlertMessage is null set @timeAlertMessage=5
        if @isActive is null set @isActive=0
        if @answerTimeOut is null set @answerTimeOut=0
        if @closeConversationTime is null set @closeConversationTime=3

        --Twitter deja los token
        --conexion Info usuarioID|token|tokenSecret|time|daysTwitterRecord
        if @meanContactTypeId= 2 begin

            if @conexionInfo is null begin
                set @conexionInfo=''usuarioID|token|tokenSecret''
                set @revisionTime=isnull(@revisionTime,''1'')
                set @daysTwitterRecord=isnull(@daysTwitterRecord,''0'')
            end
            else begin
            select @conexionInfo
                insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
                set @conexionInfo=null

                SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

                SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
                SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
            end
            set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
        end



        insert into ContactMeanIn (meanContactTypeId,name,conexionInfo,inboundId,connUser,ConnPass,numMessages,timeAlertMessage,isActive,answerTimeOut,closeConversationTime)
                values (@meanContactTypeId,@name,@conexionInfo,@inboundId,@connUser,@connPass,@numMessages,@timeAlertMessage,@isActive,@answerTimeOut,@closeConversationTime)
        select 1,''insert''
    end
        else select -1,''insert''
    end
    else begin
        if not exists(select * from ContactMeanIn where inboundId<>@inboundId and connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin

            select @name=isnull(@name,name), @conexionInfo = isnull(@conexionInfo,conexionInfo),@connUser= isnull(@connUser,connUser),@connPass= isnull(@connPass,ConnPass),
                @numMessages= isnull(@numMessages,numMessages),@timeAlertMessage= isnull(@timeAlertMessage,timeAlertMessage),@isActive= isnull(@isActive,isActive),
                @answerTimeOut= isnull(@answerTimeOut,answerTimeOut),@closeConversationTime=isnull(@closeConversationTime,closeConversationTime)
            from ContactMeanIn where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId


            --Twitter deja los token
            if @meanContactTypeId= 2 begin
                --usuarioID|token|tokenSecret|time|daysTwitterRecord
                insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
                set @conexionInfo=null

                SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

                SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
                SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
                set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
            end


            update ContactMeanIn set name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,
                numMessages=@numMessages,timeAlertMessage=@timeAlertMessage,isActive=@isActive,answerTimeOut=@answerTimeOut,
                closeConversationTime=@closeConversationTime
                where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
            select 1,''update''
        end
        else select -1,''update''
    end
    return (0)
end

else if @action = 5 begin--parameters check conection Mail In
    select conexionInfo,connUser,connPass from ContactMeanIn with(nolock) where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 6 begin--parameters check conection Mail Out
    select conexionInfo as ConexionInfo,connUser as UserName,connPass as Password, isActive as IsActive, contactMeanOutId as IdOut
        from ContactMeanOut with(nolock) where contactMeanOutId  = @contactMeanId
end
else if @action = 7 begin--list mail out by ACD
    select A.contactMeanOutId,A.name, A.conexionInfo,A.connUser,A.connPass,A.isActive
        from ContactMeanOut A with(nolock)

end
else if @action = 8 begin--insert account mail out
    if not exists(select * from ContactMeanOut where connUser=@connUser) begin
        insert into ContactMeanOut (meanContactTypeId,name,conexionInfo,connUser,ConnPass,isActive)
            values (@meanContactTypeId,@name,@conexionInfo,@connUser,@connPass,@isActive)
        select 1
        return(0)
    end
    else select -1
end
else if @action = 9 begin--update account mail out
    if not exists(select * from ContactMeanOut where contactMeanOutId <> @contactMeanId  and connUser=@connUser) begin

        select  @meanContactTypeId=isnull(@meanContactTypeId,meanContactTypeId),@name=isnull(@name,name),
            @conexionInfo=isnull(@conexionInfo,conexionInfo),@connUser=isnull(@connUser,connUser),
            @connPass=isnull(@connPass,ConnPass),@isActive=isnull(@isActive,isActive)
            from ContactMeanOut where contactMeanOutId = @contactMeanId

        update ContactMeanOut set meanContactTypeId=@meanContactTypeId,name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,isActive=@isActive
         where contactMeanOutId = @contactMeanId
         select 1,''update ''
    end
    else select -1
end
else if @action = 10 begin  --insert relation mail out and ACD
    if not exists(select * from relationContactMeanOutInbound where contactMeanOutId=@contactMeanId) begin
        insert into relationContactMeanOutInbound(contactMeanOutId,inboundId) values (@contactMeanId,@inboundId)
    end
end
else if @action = 11 begin --delete relation mail out and ACD
    delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId and inboundId=@inboundId
end
else if @action = 12 begin --delete mail out
    delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId
    delete ContactMeanOut where contactMeanOutId=@contactMeanId
end
else if @action = 13 begin --delete mail out
    if not exists(select * from ContactMeanOut where contactMeanOutId=@contactMeanId) begin
        update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
        select 1
    end
    else select -1
end
else if @action = 14 begin
    select * from relationContactMeanOutInbound
end
else if @action = 15 begin
    select * from relationContactMeanOutInbound where inboundId=@inboundId
end
--else if @action = 16 begin
--  update ccRIACat_Areas set maxMails = @maxMails where IDArea=@idArea
--end
else if @action = 17 begin  --
    select A.conexionInfo as ConexionInfo,A.connUser as UserName,A.connPass as Password,A.isActive as IsActive,inboundId as IdIn  from ContactMeanIn A where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
End
else if @action = 18 begin   --Obsoleto para email - actualizado en case 24
    select A.contactMeanOutId as IdOut,A.conexionInfo as ConexionInfo ,A.connUser as UserName,A.connPass as [Password],isActive as IsActive from contactMeanOut A where isActive=1
end
else if @action = 19 begin   --relation MailOut and ACD
    select contactMeanOutId as Id,inboundId as AcdId from relationContactMeanOutInbound where inboundId = @inboundId or @inboundId = 0 order by inboundId
end
else if @action = 20 begin --relation MailOut and ACD
    select B.inboundId,A.conexionInfo,A.connUser,A.connPass
    from ContactMeanOut A
    inner join relationContactMeanOutInbound B on B.contactMeanOutId=A.contactMeanOutId
    where B.inboundId = @inboundId or @inboundId = 0
end
else if @action = 21 begin --relation MailOut and ACD
    update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
end
else if @action = 22 begin --Update type
    if @meanContactTypeId = 2 --Twitter
        set @conexionInfo=''usuarioID|token|tokenSecret|1|0''
    else
        set @conexionInfo=''''
    update ContactMeanIn set name = '''', conexionInfo = @conexionInfo, connUser = '''', isActive = 0 where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
    select 1,''unAssigned''
end
else if @action = 23 begin -- carga la relacion de especialidades y cuentas de email de entrada
		 select A.inboundId as IdIn,A.conexionInfo as ConexionInfo,A.connUser as [Username],A.connPass as [Password], A.isActive as IsActive,
		cast(case when A.inboundId = C.inboundId then 1 else 0 end as bit) as IsAzure,
		tenantId [TenantId], clientId [ClientId], clientSecret [ClientSecret], instance [Instance], apiUrl [ApiUrl]
        from ContactMeanIn A inner join ccInbound B on A.inboundId=B.Inbound_Id
		left join contactMeanInAzure C on B.Inbound_id = C.inboundId
        where meanContactTypeId = @meanContactTypeId and B.Status=1 and A.isActive=1
end
else if @action = 24  begin  --Carga cuentas de salida
 	select A.contactMeanOutId as IdOut,A.conexionInfo as ConexionInfo ,A.connUser as UserName,A.connPass as [Password],isActive as IsActive, 
	cast(case when A.contactMeanOutId = B.contactMeanOutId then 1 else 0 end as bit) as IsAzure,
	tenantId [TenantId], clientId [ClientId], clientSecret [ClientSecret], instance [Instance], apiUrl [ApiUrl]
	from contactMeanOut A left join contactMeanOutAzure B on A.contactMeanOutId = B.contactMeanOutId
	where isActive=1
end
else if @action = 25 begin
	select count(*) [ConnectionExists] from contactMeanInAzure where inboundId = @inboundId
end
END'
		exec (@sql)	

		SET @process = 'CW-4824 Drop Stored procedure ccsp_GalateaAdminInbound'
		SET @sql = '
			if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminInbound'')
			begin
				DROP PROCEDURE ccsp_GalateaAdminInbound;
			end'
		EXEC(@sql)

		SET @process = 'CW-4857 Create Stored procedure ccsp_GalateaAdminInbound (se agregan ultimos cambios)'
		SET @sql = '
			CREATE PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT, 
												 @InboundId AS SMALLINT
			AS
			BEGIN
				set nocount on;

				if(@Option = 1)
				begin
					select 
						ISNULL(count (*), 0) as Calls,
						ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
						ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
						ISNULL(count (case when statusCall_id = 7 then 1 else null end), 0) as OverflowedCalls,
						ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
						ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
						ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
						ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
						ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer
					from ccCallsIn a (nolock)
					where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) and a.inbound_id = @InboundId
		
				end
				
			END'

		EXEC(@sql)

		SET @process = 'CW-4847 Alter Stored procedure ccsp_GalateaAdminSchedulesManagement para horarios'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminSchedulesManagement]
	@option smallint = -1,
	@camId int = -1,
	@camType smallint = -1,
	@scheduleId int = -1,
	@areaId smallint = -1,
	@moduleId tinyint = 0,
	@userId smallint = -1,
	@operationType tinyint = 0
AS
SET NOCOUNT ON;
DECLARE @transtate BIT
IF @@TRANCOUNT = 0
BEGIN
	SET @transtate = 1
	BEGIN TRANSACTION transtate
	END
	BEGIN TRY
		IF @option = 1 --Obtener horarios
		BEGIN
			SELECT horario_id as ScheduleId, Descripcion as [Description],
			HoraInicio as StartHour, MinInicio as StartMinute, HoraFin as EndHour,
			MinFin as EndMinute, Lunes as Monday, Martes as Tuesday, Miercoles as Wednesday,
			Jueves as Thursday, Viernes as Friday, Sabado as Saturday, Domingo as Sunday FROM ccHorarios
		END
		IF @option = 2 --Obtener relaciones de horarios y campañas
		BEGIN
			IF(@camType=1)
			BEGIN
				SELECT cam_id as CampId, Horario_id as ScheduleId FROM ccCampsHorarios WHERE cam_id = @camId
			END
			IF(@camType=0)--campañas de entrada
			BEGIN
				SELECT CONVERT(INT, Inbound_id) as CampId, Horario_id as ScheduleId FROM ccInboundHorarios WHERE Inbound_id = CONVERT(SMALLINT, @camId)
			END
		END
		IF @option =3--agregar la relación de horarios con campañas de salida y entrada
		BEGIN
			IF(@camType =1)
			BEGIN
				IF NOT EXISTs (SELECT cam_id, Horario_id FROM ccCampsHorarios WHERE cam_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					INSERT INTO [CCenterRia].[dbo].[ccCampsHorarios](cam_id, Horario_id)
						VALUES (@camId, @scheduleId)
					SELECT 1
				END
				SELECT 0
			END
			IF(@camType = 0)
			BEGIN
				IF NOT EXISTs (SELECT Inbound_id, Horario_id FROM ccInboundHorarios WHERE Inbound_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					INSERT INTO [CCenterRia].[dbo].ccInboundHorarios(Inbound_id, Horario_id)
						VALUES (@camId, @scheduleId)
					SELECT 1
				END
				SELECT 0
			END
		END
		IF @option = 4 --eliminar relación del horario
		BEGIN
			IF(@camType = 1)
			BEGIN
				IF EXISTs (SELECT cam_id, Horario_id FROM ccCampsHorarios WHERE cam_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					DELETE ccCampsHorarios where cam_id=@camId and horario_id=@scheduleId
					SELECT 1
				END
				SELECT 0
			END
			IF(@camType = 0)
			BEGIN
				IF EXISTs (SELECT Inbound_id, Horario_id FROM ccInboundHorarios WHERE Inbound_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					DELETE ccInboundHorarios where inbound_id=@camId and horario_id=@scheduleId
					SELECT 1
				END
				SELECT 0
			END
		END
		IF @option = 5
		BEGIN
			IF (EXISTS(SELECT Horario_id FROM ccInboundHorarios WHERE horario_id = @scheduleId) OR EXISTS(SELECT Horario_id FROM ccCampsHorarios WHERE Horario_id = @scheduleId))
			BEGIN
				SELECT 1
			END
			ELSE
			BEGIN
				SELECT 0
			END
		END
		IF @option = 7 --insetar log
		BEGIN
			DECLARE @area nvarchar(max) = (SELECT AreaName FROM [CCenterRia].[dbo].[ccRIACat_Areas] where IDArea = @areaId)
			DECLARE @userName nvarchar(max) = (SELECT [Login] FROM [CCenterRia].[dbo].[ccUsers] where [User_id] = @userId)
			DECLARE @campDescription nvarchar(max) 
			DECLARE @scheduleName nvarchar(max)
			IF(@camType = 1)
			BEGIN
				SET @campDescription = (SELECT cam_descripcion FROM [CCenterRia].[dbo].[ccCamps] WHERE cam_id = @camId)
			END
			IF(@camType = 0)
			BEGIN
				SET @campDescription = (SELECT descripcion FROM [CCenterRia].[dbo].[ccInbound] WHERE Inbound_id = @camId)
			END
			IF(@camType = 2)--actualizar horarios
			BEGIN
				IF (@scheduleId = 0)
				BEGIN
					SET @campDescription = ''''
					DECLARE @MAXID INT = (SELECT MAX(horario_id) FROM ccHorarios)
					SET @scheduleName = (SELECT Descripcion FROM [CCenterRia].[dbo].[ccHorarios] WHERE horario_id = @MAXID)
				END
				ELSE
				BEGIN
					SET @campDescription = (SELECT Descripcion FROM [CCenterRia].[dbo].ccHorarios where horario_id = @scheduleId)
					SET @scheduleName = ''''
				END
			END
			ELSE
			BEGIN
				SET @scheduleName = (SELECT Descripcion FROM [CCenterRia].[dbo].[ccHorarios] WHERE horario_id = @scheduleId)
			END
			INSERT INTO [CCenterRia].[dbo].[ccRIALog](areaName, operationDate, operationType, login, module_id, value, target)
				VALUES (@area, GETDATE(), @operationType, @userName, @moduleId, @scheduleName, @campDescription)
		END
		IF @option = 8 --obtener los ids de las campañas con el horario asignado
		BEGIN
			SELECT cam_id FROM ccCampsHorarios WHERE Horario_id=@scheduleId
		END
		IF @option = 9
		BEGIN
			SELECT Descripcion FROM ccHorarios
		END
		IF @option = 10
		BEGIN
			SELECT MAX(horario_id) FROM ccHorarios
		END
		IF @transtate = 1 AND XACT_STATE() = 1
		BEGIN
			COMMIT TRANSACTION transtate
		END;
	END TRY
	BEGIN CATCH
		DECLARE @error INT, @message VARCHAR(4000), @xstate INT;
		SELECT @error = ERROR_NUMBER(), @message = ERROR_MESSAGE(), @xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			ROLLBACK
		IF @xstate = 1
			ROLLBACK TRANSACTION ccsp_GalateaAdminPortsManagement;
		RAISERROR (''ccsp_GalateaAdminSchedulesManagement: %d: %s'', 16, 1, @error, @message) ;
	END CATCH;'

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
