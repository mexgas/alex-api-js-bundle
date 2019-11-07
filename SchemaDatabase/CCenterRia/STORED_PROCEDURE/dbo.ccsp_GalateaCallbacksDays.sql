CREATE PROCEDURE [dbo].[ccsp_GalateaCallbacksDays]--[dbo].[ccsp_GalateaCallbacksDays] 40
@userID int
AS
declare @currentDay datetime,@rangeDays int 

set @currentDay =getdate()

select @rangeDays=valor from ccSettings where setting_id=35

-- Returns days with callbacks made by an agent
SELECT cal_fusercallback Day
FROM ccoCallBacks cb
WHERE user_id = @userID
and cal_fusercallback between @currentDay and dateadd(dd,@rangeDays,getdate())
order by Day