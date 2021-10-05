CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetCampaignsPerAgent]
				@agent_id INT
				AS
				BEGIN
				SELECT DISTINCT 0 CampType, a1.inbound_id AS CampId, a1.descripcion AS Description, a3.frame AS Frame
					FROM ccinbound a1
					JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					JOIN ccInboundAgentes a4 ON a1.inbound_id = a4.inbound_id
					WHERE a3.type_id = 1 AND a4.user_id = @agent_id

					union

				SELECT DISTINCT 1 CampType, a1.cam_id AS CampId, a1.cam_descripcion AS Description, a3.frame AS Frame
					FROM ccCamps a1
					JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
					JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
					JOIN ccCampsAgente a4 ON a1.cam_id = a4.cam_id
					WHERE a3.type_id = 1 AND a4.user_id = @agent_id
				END