CREATE procedure [dbo].[ccsp_RIA_ConfigMonitoredCampAndAcd]
@option smallint,
@user_id smallint,
@cam_id varchar(1000),
@inbound_id varchar(1000),
@viewAgents int
as
set nocount on

if @option = 1
	begin
		if @cam_id <> ''
			begin
				update ccSupervisorCam
				set monitored = 1
				where user_id = @user_id
				and tipo = 1

				update ccSupervisorCam
				set monitored = 0
				where cam_id not in (select value from fn_RIASplitDelimited(@cam_id,','))
				and tipo = 1
				and user_id = @user_id
			end
		else
			begin
				update ccSupervisorCam
				set monitored = 0
				where user_id = @user_id
				and tipo = 1
			end

		if @inbound_id <> ''
			begin
				update ccSupervisorCam
				set monitored = 1
				where user_id = @user_id
				and tipo = 0
				
				update ccSupervisorCam
				set monitored = 0
				where cam_id not in (select value from fn_RIASplitDelimited(@inbound_id,','))
				and tipo = 0
				and user_id = @user_id
			end
		else
			begin
				update ccSupervisorCam
				set monitored = 0
				where user_id = @user_id
				and tipo = 0
			end
	
	end

if @option = 2
	begin
		update ccusers
		set viewAgents = @viewAgents
		where user_id = @user_id
	end

set nocount off