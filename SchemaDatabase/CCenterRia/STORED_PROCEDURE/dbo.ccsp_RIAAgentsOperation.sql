CREATE PROCEDURE [dbo].[ccsp_RIAAgentsOperation]
@Type tinyint,
@newState as tinyint
AS

	If ( @Type = 1 )
	begin
		select valor from ccsettings where setting_id=11
	end
	If ( @Type = 2 )
	begin
		UPDATE ccSettings SET Valor = 11
    		WHERE setting_id = @newState
	end