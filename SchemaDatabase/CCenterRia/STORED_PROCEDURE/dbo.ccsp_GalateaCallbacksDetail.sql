CREATE PROCEDURE [dbo].[ccsp_GalateaCallbacksDetail]
@userID int,
@dateCallBack datetime
AS
-- Returns data of callbacks made by an agent on specific day
SELECT	
		CAST(DATEPART(HOUR, cal_fusercallback)AS smallint) 'Hour',
		DATEPART(MINUTE, cal_fusercallback) 'Minute',
		cb.cal_telefono Telephone,
		cam_descripcion Campaign
FROM ccoCallBacks cb
	 join ccCamps c on cb.cam_id = c.cam_id
WHERE user_id = @userID 
		and DATEPART(YEAR, cal_fusercallback) = DATEPART(YEAR, @dateCallBack)
		and DATEPART(DAY, cal_fusercallback) = DATEPART(DAY, @dateCallBack)
		and DATEPART(MONTH, cal_fusercallback) = DATEPART(MONTH, @dateCallBack)