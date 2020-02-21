CREATE PROCEDURE [dbo].[cs_GetACDCampaignList] @action AS SMALLINT
AS
IF (@action = 1)
BEGIN
	SELECT cam_id AS [cam_id]
		,cam_descripcion AS [name]
	FROM ccCamps
	WHERE cam_activo = 1
		AND cam_id NOT IN (
			SELECT Cam_id
			FROM CW_CenterScript..Campaign
			)
		AND IDArea > 0 
END

IF (@action = 2)
BEGIN
	SELECT inbound_id
		,descripcion AS [name]
	FROM ccInbound
	WHERE STATUS = 1
		AND Inbound_id NOT IN (
			SELECT Inbound_id
			FROM CW_CenterScript..Inbound_Campaign

			)
		AND IDArea > 0 and chat = 0
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
		AND chat = 0
END