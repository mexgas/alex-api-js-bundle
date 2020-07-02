CREATE PROCEDURE [dbo].[CofetelSettingsData]
		@type tinyint
		as
		if @type = 1
		begin
			select valor from ccsettings where setting_id = 172
		end