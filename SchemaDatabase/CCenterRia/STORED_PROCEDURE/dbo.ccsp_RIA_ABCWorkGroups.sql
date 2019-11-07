CREATE PROCEDURE [dbo].[ccsp_RIA_ABCWorkGroups]
		@option smallint,
		@IDWG smallint,
		@user_Id smallint = 0,
		@Descripcion varchar(45) = null,
		@IDArea smallint = null,
		@IDCampEsp varchar(2000),
		@Type smallint
		as
		set nocount on
		if @option = 0 -- All WokGroup
		 begin
			if(@IDArea = 0 or @IDArea is null)
				select IDWG, WGName from ccRIACat_WorkGroup with(readpast) where StatusWorkGroup=1
			else
				select IDWG, WGName from ccRIACat_WorkGroup with(readpast) where StatusWorkGroup=1 and IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea=@IDArea)
			
			return(0)
		 end

		if @option = 1 -- Selected WokGroup
		 begin
			if @type = 0
			begin
				select IDWG, WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and IDWG=@IDWG
			end
			else if @type = 1
			begin
				select w.IDWG, w.WGName, a.IDArea
				from ccRIACat_WorkGroup w
				join ccRIAAreaWorkGroup aw on aw.idwg = w.idwg
				join ccRIACat_Areas a on a.IDArea = aw.IDArea
				where w.StatusWorkGroup=1
			end
			else if @type = 2
			begin
				select w.WGName, a.IDArea, a.AreaName
				from ccRIACat_WorkGroup w
				join ccRIAAreaWorkGroup aw on aw.idwg = w.idwg
				join ccRIACat_Areas a on a.IDArea = aw.IDArea
				where w.StatusWorkGroup=1 and w.IDWG=@IDWG
			end
			else if @type = 3
			begin
				select count(*)
				from ccRIAWorkGroupUsers
				where idwg=@IDWG
				and user_id=@user_Id
			end

			return(0)
		 end

		if @option = 2 -- insert WorkGroup
		 begin
			if exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
			 begin
				select -1 --, Nombre en Uso
				return(0)
			 end
			
			insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
			if @@rowcount = 1
				select @IDWG = scope_identity()

			else 
			 begin
				select -2 --, No se inserto correctamente
				return(0)
			 end

			insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@IDWG, @IDArea)
			select 1 --, WG insertado
			return(0)
		 end

		if @option = 3 -- UpdateWokGroup
		 begin
			Update ccRIACat_WorkGroup set WGName=@Descripcion where StatusWorkGroup=1 and IDWG=@IDWG
			return(0)
		 end

		if @option in (4,8) -- Delete WorkGroup (4:all / 8:only from acd/camps)
		 begin

		 	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.IDWG = @IDWG
			insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.IDWG = @IDWG
		 	
			Delete from ccCampsAgente where IDWG = @IDWG
			Delete from ccInboundAgentes where IDWG = @IDWG

			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.IDWG = @IDWG

			Delete from ccSupervisorCam where IDWG = @IDWG
			Delete from ccRIACampEspWG where IDWG = @IDWG
			
			if @option=4
			 begin
				Delete from ccRIAAreaWorkGroup where IDWG = @IDWG 
				Delete from ccRIAWorkGroupUsers where IDWG = @IDWG
				Update ccRIACat_WorkGroup set StatusWorkGroup=0 where IDWG=@IDWG
			 end
			return(0)
		 end

		if @option = 5 -- Insert WorkGroup in Camp or ACDGroup	
		 begin
		 if (select count(IdCampEsp) from ccRIACampEspWG where IdCampEsp=@IDCampEsp and Tipo=@Type) >= (select valor from ccSettings where setting_id=180) -- limit
			 begin
				select 3
				return(0)
			 end

			if (select count(IDWG) from ccRIACampEspWG where IDWG=@IDWG) >= (select valor from ccSettings where setting_id=64) -- limit
			 begin
				select 2
				return(0)
			 end					

			if exists (select IDWG from ccRIACampEspWG where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) -- Ya existe el grupo en el ACD o Especialidad
			 begin
				select 1
				return(0)
			 end

			insert into ccRIACampEspWG (IDWG, Tipo, IdCampEsp, priority) values (@IDWG, @Type, @IDCampEsp, 1)
			if not exists(select * from ccRIACampEspWGConsulta where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) begin
				insert into ccRIACampEspWGConsulta (IDWG, Tipo, IdCampEsp) values (@IDWG, @Type, @IDCampEsp)
			end
				

			exec ccsp_RIACalcula_WGPriority @IDWG, @IDCampEsp, @Type
			if @Type not in (0, 1) -- ACDGroup
				return(0)
				
			if @Type=0 --ACDGroup
			begin

				if @IDWG is null or @IDWG = 0
				 begin
					select 48
					return(0)
				 end
				 
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
			 
				return(0)
			end
			
			if @IDWG is null or @IDWG = 0
			 begin
				select 18
				return(0)
			 end

			-- if @Type = 1 -- Camp
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

			return(0)
		 end

		if @option = 6 -- Verifica si existe el grupo
		 begin
		  	select @IDWG = case when exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
			 then 1 else 0 end
		 
		 	if isnull(@IDArea,0)=0
			 begin
				select @IDWG
				return(0)
			 end

		 	if @IDWG=1
			 begin
				select '-1'
				return(0)
			 end

			insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
			if @@rowcount = 1
				select @IDWG = scope_identity()

			insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@IDWG, @IDArea)
			select @IDWG
			return(0)
		 end

		if @option = 7 -- Delete WokGroup from ACD or Camp
		 begin
			if @Type = 1
				begin
					insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.IDWG=@IDWG and A.cam_id=@IDCampEsp
					Delete from ccCampsAgente where IDWG=@IDWG and cam_id=@IDCampEsp
				end
			else if @Type = 0 
				begin
					insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.IDWG=@IDWG and A.inbound_id=@IDCampEsp
					Delete from ccInboundAgentes where IDWG=@IDWG and inbound_id=@IDCampEsp
				end

			Delete from ccRIACampEspWG where IDWG=@IDWG and IdCampEsp=@IDCampEsp and Tipo=@Type

			return(0)
		 end
		 
		return(0)
		set nocount off