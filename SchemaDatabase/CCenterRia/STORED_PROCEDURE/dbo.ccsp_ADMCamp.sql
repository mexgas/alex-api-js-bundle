CREATE PROCEDURE [dbo].[ccsp_ADMCamp]
		@Descripcion varchar(40),
		@cam_id smallint,
		@cli_id smallint=1,
		@Tipo tinyint, -- 1=ALTA, 2=Modificacion, 2=Eliminar
		@ventana tinyint = 2, -- 0 Falso, 1 Verdadero, 2 Sin Cambio
		@timer int = 2,
		@Activa tinyint = 2,
		@user_id int=0
		AS
		set nocount on
		--ccsp_ADMCamp 'ABCD', 1, 0, 2, 1 , 1 , 1
		declare @new_cam_id smallint
		declare @idioma as bit

		Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

		--HLAS no crear campa±as sin cliente asignado 20050104
		if not exists(select cli_id from ccClientes where cli_id = @cli_id)
			return(0)

		select @cli_id = max(cli_id) from ccClientes
		if isnull(@cli_id,0)=0 
		 begin
			select 0, case @idioma when 1 then 'Please check Clients Catalogue and make sure there is at least one client'
			else 'Favor de revisar el Catálogo de Clientes y verificar que exista alguno' end
			return(0)
		 end 

		if @Tipo in(1,4)
		begin
			if exists (select cam_descripcion from ccCamps where cam_descripcion = @Descripcion)
			 begin
				select 0, case @idioma when 1 then 'Name in Use' else 'Nombre en Uso' end
				return(0)
			 end

			Insert ccCamps (cam_descripcion, cli_id, cam_ShowCalifWnd, cam_StartTimerOnHangUp)
			 Values(@Descripcion, @cli_id, @ventana, @timer)
			select @new_cam_id = SCOPE_IDENTITY()
			
			if @new_cam_id is null and @Tipo=4
			 begin
				select 0, case @idioma when 1 then 'Error creating campaign' else 'Error al crear campaña' end
				return(0)
			 end

			insert into ccoDialerCamp (dialer_id, cam_id)
			 select dialer_id, @new_cam_id as cam_id from ccoDialers where status=1

			insert into ccCalifCamp (calif_id, cam_id, tipo)
			 select calif_id, @new_cam_id as cam_id, 1 as tipo from ccTipoCalifOUT

			if @user_id > 1 and exists (select IDWG from ccRIAWorkGroupUsers where User_id=@user_id)
			 begin
				Insert ccSupervisorCam (user_id, cam_id, tipo, IDWG)
				select @user_id, @new_cam_id, 1, IDWG from ccRIAWorkGroupUsers where User_id=@user_id
			 end

			else if @user_id > 1 and not exists (select IDWG from ccRIAWorkGroupUsers where User_id=@user_id)
			 begin
				Insert ccSupervisorCam (user_id, cam_id, tipo, IDWG)
				select @user_id, @new_cam_id, 1, 0
			 end

			select -1, case @idioma when 1 then 'Campaign: ' + upper(@Descripcion) + ' Added Succesfully'
			else 'Campaña: ' + upper(@Descripcion) + ' Dada de Alta' end
			return(0)
		 end

		if @Tipo=2
		 begin
			Update ccCamps set cam_descripcion= @Descripcion where cam_id = @cam_id
			if @ventana <> 2 Update ccCamps set cam_ShowCalifWnd=@ventana where cam_id = @cam_id
			if @timer <> 2 	Update ccCamps set cam_StartTimerOnHangUp=@timer where cam_id = @cam_id
			if @Activa <> 2 Update ccCamps set cam_activo=@Activa where cam_id = @cam_id

			select -1, case @idioma when 1 then 'Campaign: ' + upper(@Descripcion) + ' Modified'
			else 'Campaña: ' + upper(@Descripcion) + ' Modificada' end
			return(0)
		 end

		if @Tipo=3
		 begin
		 	insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @cam_id

			delete from ccCampsAgente where cam_id = @cam_id
			delete from ccoDialerCamp where cam_id = @cam_id
			delete from ccoWorkingTable where cam_id = @cam_id
			delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @cam_id)
			delete from ccoLogDials where cam_id = @cam_id
			delete from ccoCallsOut where cam_id = @cam_id
			delete ccoCallsOut where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @cam_id)
			delete from ccoCallsOutSource where cam_id = @cam_id

			insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCamBackup B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @cam_id and A.tipo = 1
			
			Delete ccSupervisorCam where cam_id  = @cam_id and tipo = 1
			
			if exists(select cam_id from ccCampsAgente where cam_id = @cam_id)
			 begin
				select 0, case @idioma when 1 then 'There are Agents Related to this Campaign'
				else 'Existen Agentes Relacionados con esta Campaña' end
				return(0)
			 end
			
			if exists(select cam_id from ccoCallsOut where cam_id = @cam_id)
			 begin
				select 0, case @idioma when 1 then 'There are Call Registries Related with this Campaign'
				else 'Existen Registros de Llamadas Relacionados con esta Campaña' end
				return(0)
			 end

			insert ccCampsMovs (cam_id, TipoMov, NewRecords,  CBRecords, user_id) 
			 Values(@cam_id, 5, 0,0,@user_id)
			Delete ccCamps Where cam_id = @cam_id

			select -1, case @idioma when 1 then 'Campaign: ' + upper(@Descripcion) + ' Deleted'
			else 'Campaa: ' + upper(@Descripcion) + ' Eliminada' end
			return(0)
		 end

		set nocount off