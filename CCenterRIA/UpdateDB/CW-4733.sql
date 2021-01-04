/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/11/10
Description:

Database: CCenterRia
Required version: 123.12

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
SET @versionfix = 13
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
