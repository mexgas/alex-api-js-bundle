CREATE PROCEDURE [dbo].[trsp_ConsultaTemplate]
@tpl_id int
AS
BEGIN
	SELECT     tpl_id,tpl_nombre
	FROM       TREC_TEMPLATES
	WHERE      tpl_id = @tpl_id
END