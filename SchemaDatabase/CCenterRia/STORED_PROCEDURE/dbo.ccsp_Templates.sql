CREATE PROCEDURE ccsp_Templates
@temid smallint,
@user smallint
AS
	if (select count (*) from ccCampsTemplates where template_id = @temid) > 0
	begin
	select  0 as tipo, inbound_id as cam, [User_id] as usuario, 0 AS movimiento, 1, 1 from ccInboundAgentes a where inbound_id in ( select cam_id from ccSupervisorCam where tipo = 0 and user_id = @user) and
	NOT EXISTS 
	(SELECT [user_id], cam_id FROM [ccCampsTemplates] b WHERE b.[template_id] = @temid  AND b.[tipo] = 0 AND a.[Inbound_id] = b.[cam_id] AND b.[user_id] = a.[User_id])
	UNION
	SELECT 0 as tipo, c.cam_id as cam, c.USER_ID as usuario, 1 as movimiento, [prioridad], [skill] FROM [ccCampsTemplates] c WHERE c.[template_id] = @temid AND c.[tipo] = 0
	AND NOT EXISTS 
	(SELECT inbound_id AS cam, [User_id] AS usuario from ccInboundAgentes b WHERE b.[User_id]=c.[user_id] AND b.[Inbound_id]=c.[cam_id])

	UNION 
	select  1 as tipo, cam_id as cam, [User_id] as usuario, 0 AS movimiento, 1, 1 from [ccCampsAgente] a where cam_id in ( select cam_id from ccSupervisorCam where tipo =1 and user_id = @user) and
	NOT EXISTS 
	(SELECT [user_id], cam_id FROM [ccCampsTemplates] b WHERE b.[template_id] =@temid AND b.[tipo] = 1 AND a.[cam_id] = b.[cam_id] AND b.[user_id] = a.[user_id])
	UNION 
	SELECT 1 as tipo, c.cam_id as cam, c.USER_ID as usuario, 1 as movimiento, [prioridad], [skill] FROM [ccCampsTemplates] c WHERE c.[template_id] = @temid AND c.[tipo] = 1
	AND NOT EXISTS 
	(SELECT [cam_id] AS cam, [User_id] AS usuario from [ccCampsAgente] b WHERE b.[User_id]=c.[user_id] AND b.[cam_id]=c.[cam_id])
	end
	else select 2