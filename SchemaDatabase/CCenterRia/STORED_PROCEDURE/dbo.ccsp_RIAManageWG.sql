CREATE PROCedure [dbo].[ccsp_RIAManageWG]
@option smallint,
@IDWG smallint,
@Type smallint,
@UserId smallint,
@Descripcion varchar(25),
@IDArea as int
as
set nocount on

if @option = 3 -- Insert WokGroup
 begin
	Insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
	select @IDWG = scope_identity()

	Insert into ccRIAAreaWorkGroup(IDWG, IDArea) values(@IDWG, @IDArea)
	select @IDWG
	return(0)
 end

select @Type = TipoUser_id from ccUsers where User_id = @UserId

if @option = 1 -- Insert Agente-Supervisor in WorkGroup
 begin
	if @Type not in(1, 2, 6)
		return(0)

	if exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @UserId)
	 begin
		 select 1
		 return(0)
	 end

	If @Type = 1
	 begin

		If (select count(User_id) from ccRIAWorkGroupUsers where User_id = @UserId) > = (select valor from ccSettings where setting_id = 63)
		 begin
			select 3
			return(0)
		 end

		insert into ccRIAWorkGroupUsers(IDWG, User_id) values(@IDWG,@UserId)

		--insert skill media
		exec ccsp_Skills @action= 5,@userId=@UserId


		if @IDWG is null or @IDWG = 0
		 begin
			select 38
			return(0)
		 end

		insert into cccampsAgente (user_id, cam_id, prioridad, skill, IDWG)
		select @UserId, idCampEsp, dbo.fn_Calcula_UsrPriority(@UserId,0), 1, @IDWG
		from ccRIACampEspWG where tipo = 1 and IDWG = @IDWG and
		 idCampEsp not in (select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

		insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, IDWG)
		select @UserId, idCampEsp, 0, dbo.fn_Calcula_UsrPriority(@UserId,0), 1, @IDWG
		from ccRIACampEspWG where tipo = 0 and IDWG = @IDWG and
		 idCampEsp not in (select inbound_id from ccInboundAgentes where user_id=@UserId and IDWG=@IDWG)

		if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@UserId) begin
			insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@UserId)
		end
		return(0)
	 end

	-- -Supervisor	@Type in (2,6)
	insert into ccRIAWorkGroupUsers(IDWG, User_id) values (@IDWG, @UserId)
	if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@UserId) begin
		insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@UserId)
	end

	insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
	select @UserId, idCampEsp, 0, @IDWG
	from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
	 and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

	update ccSupervisorCam
	set monitored = 1
	where user_id = @UserId
	and cam_id in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)
	and tipo = 0
	and IDWG <> @IDWG
	and monitored = 0

	insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
	select @UserId, idCampEsp, 1, @IDWG
	from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
	 and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)

	update ccSupervisorCam
	set monitored = 1
	where user_id = @UserId
	and cam_id in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
	and tipo = 1
	and IDWG <> @IDWG
	and monitored = 0

	return(0)
 end

if @option = 2 -- Delete Agent-Supervisor from WorkGroup
 begin

	if @Type = 1 --delete skill media
	exec ccsp_Skills @action= 4,@userId=@UserId,@idwg=@IDWG

	Delete ccRIAWorkGroupUsers where IDWG = @IDWG and User_id = @UserId

	if @Type = 1 -- Agente
	 begin
	 	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 	from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@UserId and A.IDWG=@IDWG
		insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id=@UserId and A.IDWG=@IDWG

	 	delete from cccampsagente where user_id=@UserId and IDWG=@IDWG
		delete from ccInboundagentes where user_id=@UserId and IDWG=@IDWG
		select @Type
		return(0)
	 end

	--else if @Type in(2, 6) -- Supervisor
	insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@UserId and A.IDWG=@IDWG
	delete ccSupervisorCam where user_id=@UserId and IDWG=@IDWG
	select @Type
	return(0)
end
return(0)
set nocount off