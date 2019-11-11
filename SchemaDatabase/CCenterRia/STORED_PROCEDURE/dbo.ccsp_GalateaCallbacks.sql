CREATE PROCEDURE [dbo].[ccsp_GalateaCallbacks]
@dateCallBack datetime
AS
-- Returns the total of callbacks by hour on especific day
IF OBJECT_ID('tempdb..#CallBackHours') IS NOT NULL
BEGIN
	DROP TABLE #CallBackHours
END

CREATE TABLE #CallBackHours (Hour int, callback int )

INSERT INTO #CallBackHours
select  DATEPART(HOUR, cal_fcallback) 'Hour', 1
from ccoCallsOut
where convert(datetime,convert(varchar(10),cal_fcallback,121))  = convert(datetime,convert(varchar(10),@dateCallBack,121))

SELECT  CAST(Hour AS smallint) Hour, SUM(callback) 'CallBacks' FROM #CallBackHours
GROUP BY Hour
ORDER BY Hour