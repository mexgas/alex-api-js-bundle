CREATE PROCEDURE [dbo].[trsp_AdmCheckForMarks]
	-- Add the parameters for the stored procedure here
	@cal_id int,
	@tipo_llamada int

	AS
	BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;

	    -- Insert statements for procedure here

	declare @grab_id int


	--set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)


	select count(*) from CCRecorderRIA.dbo.RIA_MARCAS where call_id = @cal_id and tipo_llamada = @tipo_llamada

	END