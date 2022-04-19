CREATE PROCEDURE [dbo].[ccspRepSpecialCallKeyHistory] @action AS TINYINT
	,@from AS DATETIME = NULL
	,@to AS DATETIME = NULL
AS
SET NOCOUNT ON

IF @action = 1
BEGIN
	IF @from IS NULL
		SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

	IF @to IS NULL
		SELECT @to = getdate()

	DELETE RepSpecialCallKeyHistory
	WHERE [date] BETWEEN @from
			AND @to

	INSERT RepSpecialCallKeyHistory
	SELECT CONVERT(VARCHAR(16), fecha, 121) [date]
		,ISNULL(ld.cam_id, 0) campaignId
		,ISNULL(cam_descripcion, 'systemTranslated_NoCampaign') campaign
		,ld.cal_Key callKey
		,ld.Telefono telephone
		,ISNULL(rd.descripcion, 'systemTranslated_NoStatus') dialResult
		,ISNULL(cal.Description, 'systemTranslated_Dispositionless') disposition
		,ISNULL(cal_tdialog, 0) dialogTime
		,ISNULL(convert(VARCHAR(30), cal_fcallback, 121), 'systemTranslated_NoCallback') CallBacks
		,isNull(us.LOGIN, 'systemTranslated_NoUserName') [login]
		,isNull(us.ApellidoPaterno + ' ' + us.ApellidoMaterno + ' ' + us.Nombres, 'systemTranslated_NoName') AS [user]
	FROM ccoLogDials ld WITH (NOLOCK)
	LEFT JOIN ccoCallsOut co(NOLOCK) ON co.cal_id = ld.cal_id
	LEFT JOIN ccTipoResultadoDial rd ON rd.tipoResDial_id = ld.tipoResDial_id
	LEFT JOIN ccCamps ca ON ca.cam_id = ld.cam_id
	LEFT JOIN ccTipoCalifOUT cal ON cal.calif_id = co.calif_id
	LEFT JOIN ccUserView us ON us.User_id = co.User_id
	WHERE ld.fecha BETWEEN @from
			AND @to
		AND len(ld.cal_key) > 0
END