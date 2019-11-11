CREATE PROCEDURE [dbo].[ccsp_ExtAppsCamList] @action SMALLINT, @area INT = 0
AS
SET NOCOUNT ON

IF @action = 1
BEGIN
    IF @area = 0
	   SELECT a1.inbound_id, descripcion, a1.STATUS
	   FROM ccinbound a1
	   JOIN ccRIAinboundGraph a2 ON (a1.inbound_id = a2.inbound_id)
	   JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
	   WHERE a3.type_id = 1
	   ORDER BY descripcion
    ELSE
	   SELECT DISTINCT a1.inbound_id, descripcion, a1.STATUS
	   FROM ccinbound a1
	   JOIN ccRIAinboundGraph a2 ON a1.inbound_id = a2.inbound_id
	   JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	   WHERE a3.type_id = 1 AND (@area IS NULL OR IDArea = @area)
	   ORDER BY descripcion

    RETURN (0)
END

IF @action = 2
BEGIN
    IF @area = 0
	   SELECT a1.cam_id, cam_descripcion, cam_activo
	   FROM ccCamps a1
	   JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
	   JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	   WHERE a3.type_id = 1
	   ORDER BY cam_descripcion
    ELSE
	   SELECT DISTINCT a1.cam_id, cam_descripcion, cam_activo
	   FROM ccCamps a1
	   JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
	   JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
	   WHERE a3.type_id = 1 AND (@area IS NULL OR IDArea = @area)
	   ORDER BY cam_descripcion

    RETURN (0)
END

SET NOCOUNT OFF