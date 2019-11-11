CREATE PROCEDURE [dbo].[ccsp_ADMEspec]
		@Descripcion varchar(40),
		@Inbound_id smallint,
		@cli_id smallint,
		@Tipo tinyint, -- 1=ALTA, 2=Modificacion
		@Show tinyint = 2,
		@Timer tinyint = 2,
		@user_id int = 0
		AS
		set nocount on
		declare @new_Inbound_id smallint
		declare @idioma as bit
		Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

		if @Tipo=1
		 begin
			if exists(select Descripcion from ccInbound where Descripcion = @Descripcion)
			 begin
				select 0, case @idioma when 1 then 'The ACD group already exists'
				else 'La especialidad ya existe' end
				return(0)
			 end

			Insert ccInbound (Descripcion, cli_id, ShowCalifWnd, StartTimerOnHangUp)
			 Values(@Descripcion, @cli_id, @Show, @Timer)
			select @new_Inbound_id = SCOPE_IDENTITY()
			
			insert into ccCalifCamp (calif_id, cam_id, tipo)
			 select calif_id, @new_Inbound_id as cam_id, 0 as tipo from ccTipoCalif

			if @user_id > 1 and exists (select IDWG from ccRIAWorkGroupUsers where User_id=@user_id)
			 begin
				Insert ccSupervisorCam (user_id, cam_id, tipo, IDWG)
				select @user_id, @new_Inbound_id, 0, IDWG from ccRIAWorkGroupUsers where User_id=@user_id
			 end

			else if @user_id > 1 and not exists (select IDWG from ccRIAWorkGroupUsers where User_id=@user_id)
			 begin
				Insert ccSupervisorCam (user_id, cam_id, tipo, IDWG)
				select @user_id, @new_Inbound_id, 0, 0
			 end
			 
			select -1, case @idioma when 1 then 'ACD group : ' + upper(@Descripcion) + ' added succesfully'
			else 'Especialidad: ' + upper(@Descripcion) + ' dada de alta' end
			return(0)
		 end

		if @Tipo=2
		 begin
			--Update ccInbound set Descripcion= @Descripcion, ShowCalifWnd=@Show,  StartTimerOnHangUp=@Timer where Inbound_id = @Inbound_id
			Update ccInbound set Descripcion= @Descripcion where Inbound_id = @Inbound_id
			if @Show <> 2 Update ccInbound set ShowCalifWnd=@Show where Inbound_id = @Inbound_id
			if @Timer <> 2 Update ccInbound set StartTimerOnHangUp = @Timer  where Inbound_id = @Inbound_id

			select -1, case @idioma when 1 then 'ACD group : ' + upper(@Descripcion) + ' updated'
			else 'Especialidad: ' + upper(@Descripcion) + ' modificada' end
			return(0)
		 end

		if @Tipo=3
		 begin
			if exists(select Inbound_id from ccInboundAgentes where Inbound_id = @Inbound_id)
			 begin
				select 0, case @idioma when 1 then 'There are Agents Related to this ACD group '
				else 'Existen Agentes Relacionados con esta Especialidad' end
				return(0)
			 end

			if exists( select Inbound_id from ccCallsIN where Inbound_id = @Inbound_id)
			 begin
				select 0, case @idioma when 1 then 'There are Call Registries Related to this ACD group '
				else 'Existen Registros de Llamadas Relacionados con esta Especialidad' end
				return(0)
			 end

			Delete ccInbound Where Inbound_id = @Inbound_id
			Delete ccInboundHorarios Where Inbound_id = @Inbound_id
			Delete ccInboundMsgs Where Inbound_id = @Inbound_id
			
			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) 
			select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 	from ccCampsAgente A 
				left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and  A.cam_id  = @Inbound_id
				

			Delete ccSupervisorCam where cam_id  = @Inbound_id and tipo = 0

			select -1, case @idioma when 1 then 'ACD group : ' + upper(@Descripcion) + ' deleted'
			else 'Especialidad: ' + upper(@Descripcion) + ' Eliminada' end
			return(0)
		 end

		set nocount off