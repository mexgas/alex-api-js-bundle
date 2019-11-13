CREATE PROCEDURE [dbo].[cs_GetACDCampaignList] @action AS SMALLINT
AS
IF (@action = 1)
BEGIN
	SELECT cam_id AS [cam_id]
		,cam_descripcion AS [name]
	FROM ccCamps
	WHERE cam_activo = 1 and cam_id not in (select Cam_id from CW_CenterScript..Campaign )
		AND IDArea > 0
END

IF (@action = 2)
BEGIN
	SELECT inbound_id
		,descripcion AS [name]
	FROM ccInbound
	WHERE STATUS = 1 and Inbound_id not in (select Inbound_id from CW_CenterScript..ACD)
		AND IDArea > 0
END

IF (@action = 3)
BEGIN
	SELECT cam_id AS [cam_id]
		,cam_descripcion AS [name]
	FROM ccCamps
	WHERE cam_activo = 1 
		AND IDArea > 0
END

IF (@action = 4)
BEGIN
	SELECT inbound_id
		,descripcion AS [name]
	FROM ccInbound
	WHERE STATUS = 1 
		AND IDArea > 0
END