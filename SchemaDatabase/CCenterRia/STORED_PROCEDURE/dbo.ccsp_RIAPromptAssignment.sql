CREATE PROCEDURE [dbo].[ccsp_RIAPromptAssignment]
@User varchar(4),
@name varchar(50),
@Inbound_id int,
@tipomsg_id smallint,
@Type tinyint 
AS
	if(@Type=1) -- LoadEspecs
		begin
 			Select inbound_id, Descripcion from ccInbound where status = 1 
 			and inbound_id in (select cam_id from ccSupervisorCam 
 			where user_id = @User and tipo = 0) 
 			order by inbound_id
		end

	If(@Type=2) --Load Message/Espec
		begin
			SELECT R.orden, M.msgFile, R.Msg_id
			FROM ccInboundMsgs R join ccMsgFiles M on R.Msg_id=M.Msg_id
			WHERE Inbound_id =  @Inbound_Id
			AND type = @tipomsg_id
			ORDER BY  R.orden
		end