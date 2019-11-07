CREATE PROCEDURE [dbo].[ccsp_ADMdelAgent]
		@user_id int
		AS
		insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and  A.user_id = @user_id

		delete from ccSupervisorCam where user_id = @user_id
		delete from ccMenuUser where id_User = @user_id
		delete from ccCampsAgente where user_id = @user_id
		delete from ccInboundAgentes where user_id = @user_id

		insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user_id 
		insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentesBackup A left join ccInboundAgentes B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id=@user_id

		update ccPosicion set user_id = 0 where user_id = @user_id

		update ccUsers set status = 0 where user_id = @user_id