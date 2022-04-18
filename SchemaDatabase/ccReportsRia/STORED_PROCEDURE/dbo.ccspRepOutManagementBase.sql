CREATE PROCEDURE [dbo].[ccspRepOutManagementBase] @action AS TINYINT
	,@from AS DATETIME = NULL
	,@to AS DATETIME = NULL
AS
SET NOCOUNT ON

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	DELETE
	FROM RepOutManagementBase
	WHERE [date] >= @from
		AND [date] < @to

	INSERT INTO RepOutManagementBase (
		DATE
		,dialResultCode
		,dialResultId
		,dialResult
		,dispositionId
		,disposition
		,subDispositionId
		,subDisposition
		,total
		,Agent
		,Campaigns
		,year
		,month
		,day
		,hour
		,minutes
		,calKey
		,telephone
		)
	SELECT fecha AS [date]
		,logdial.callout_id AS dialResultCode
		,logdial.tipoResDial_id AS dialResultId
		,ISNULL(resdial.descripcion, '') AS dialResult
		,ISNULL(tipocal.calif_id, 0) AS dispositionId
		,ISNULL(tipocal.Description, '') AS disposition
		,ISNULL(tiposubcal.califSub_id, 0) AS subDispositionId
		,ISNULL(tiposubcal.califSubDesc, '') AS subDisposition
		,1 AS Total
		,ISNULL(cUser.LOGIN, '') AS Agent
		,ISNULL(ccCamps.cam_descripcion, '') AS Campaigns
		,DATEPART(yyyy, fecha) AS [year]
		,DATEPART(mm, fecha) AS [month]
		,DATEPART(dd, fecha) AS [day]
		,DATEPART(hh, fecha) AS [hour]
		,DATEPART(mi, fecha) AS [minutes]
		,ISNULL(logdial.cal_Key, '') AS cal_key
		,ISNULL(logdial.Telefono, '') AS cal_telefono
	FROM ccoLogDials logdial WITH (NOLOCK)
	LEFT JOIN cctipoResultadodial resdial ON logdial.tipoResDial_id = resdial.tipoResDial_id
	LEFT JOIN ccoCallsOut cout ON cout.cal_id = logdial.cal_id
	LEFT JOIN cctipocalifout tipocal ON cout.calif_id = tipocal.calif_id
	LEFT JOIN cctipocalifsubout tiposubcal ON cout.califSub_id = tiposubcal.califSub_id
	LEFT JOIN ccUserView cUser ON cUser.User_id = cout.User_id
	LEFT JOIN ccCamps ON ccCamps.cam_id = logdial.cam_id
	WHERE fecha BETWEEN @from
			AND @to
END