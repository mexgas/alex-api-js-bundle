CREATE PROCEDURE [dbo].[ccsp_PhoneInBL]
	@action as tinyint,
	@cam_id as smallint,
	@telefono as varchar(20),
	@cal_key as varchar(40) = null
	AS
	if @action = 1 begin	
		if (select dbo.ValidateBlackListPhone(@telefono,@cam_id,@cal_key)) = 1 begin
			select 1 as IsBlackList
		end
		else begin
			select 0 as IsBlackList
		end
	end