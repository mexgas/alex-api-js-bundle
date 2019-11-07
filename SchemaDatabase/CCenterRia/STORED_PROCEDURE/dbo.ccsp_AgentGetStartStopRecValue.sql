CREATE PROCEDURE [dbo].[ccsp_AgentGetStartStopRecValue]
@user_id int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
declare @user_ok int, @setting_ok int, @result int

set @user_ok = (select isnull(startStopRecording,0) from ccusers where [User_id] = @user_id)
set @setting_ok = (select valor from ccsettings where setting_id = 142)

IF @user_ok = 1 AND @setting_ok = 1
BEGIN
set @result = 1
END
else
BEGIN
set @result = 0
END

select @result


END