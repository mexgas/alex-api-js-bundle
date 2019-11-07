CREATE PROCEDURE [dbo].[trsp_FinderCRMNode] @cal_id INT, @type INT, @node XML
AS
BEGIN
	IF NOT EXISTS (
			SELECT *
			FROM ccCRMNodes
			WHERE cal_id = @cal_id AND type = @type
			)
		INSERT INTO ccCRMNodes (cal_id, type, node)
		VALUES (@cal_id, @type, @node)
	ELSE
		UPDATE ccCRMNodes
		SET node = @node
		WHERE cal_id = @cal_id AND type = @type
END