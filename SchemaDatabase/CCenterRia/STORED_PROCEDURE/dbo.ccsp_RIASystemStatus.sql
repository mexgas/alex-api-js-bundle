CREATE PROCEDURE [dbo].[ccsp_RIASystemStatus]
@Type tinyint,
@newState as tinyint
AS

	If ( @Type = 1 )
	begin
		select valor from ccsettings where setting_id=3
	end
	If ( @Type = 2 )
	begin
		UPDATE ccSettings SET Valor= @newState
    		WHERE setting_id = 3
	end