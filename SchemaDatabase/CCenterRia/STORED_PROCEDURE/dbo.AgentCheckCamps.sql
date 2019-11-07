CREATE PROCEDURE [dbo].[AgentCheckCamps]
@cam_id as smallint,
@user_id as smallint,
@forceManualCall as tinyint = 0
AS

declare @isValidCall as int
declare @timeZoneRule as int

select @isValidCall = count(*) from ccCampsAgente with(nolock) where cam_id = @cam_id and user_id = @user_id
select @timeZoneRule = 0

if @isValidCall <> 0 and @forceManualCall = 0 begin
	select @isValidCall = cam_ModoManual, @timeZoneRule = timeZoneRule from ccCamps with(nolock) where cam_id = @cam_id
end

select @isValidCall as Validation, @timeZoneRule as TimeZoneRule