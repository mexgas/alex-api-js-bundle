CREATE PROCEDURE [dbo].[AgentCheckCampsActive]
					@cam_id as smallint,
					@user_id as smallint,
					@forceManualCall as tinyint = 0
					AS

					declare @isValidCall as int
					declare @timeZoneRule as int
					declare @idArea as int

					select @isValidCall = count(*)from ccCampsAgente with(nolock) where cam_id = @cam_id and user_id = @user_id
					select @idArea = IDArea from ccCamps with(nolock) where cam_id = @cam_id
					select @timeZoneRule = 0
					if @idArea is not NULL
						begin
							select @isValidCall = cam_ModoManual, @timeZoneRule = timeZoneRule, @idArea = 1
							from ccCamps with(nolock) where cam_id = @cam_id
							end

							else if @idArea is null
							begin
							select  @isValidCall = cam_ModoManual, @timeZoneRule = timeZoneRule, @idArea = 0
							from ccCamps with(nolock) where cam_id = @cam_id
							end

						select @isValidCall as Validation, @timeZoneRule as TimeZoneRule, @idArea as Active