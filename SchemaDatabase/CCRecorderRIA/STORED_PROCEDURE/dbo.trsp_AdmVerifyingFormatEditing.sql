CREATE PROCEDURE [dbo].[trsp_AdmVerifyingFormatEditing]
			@cal_id int,
			@tipo_llamada int,
			@id_formato int


			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			declare @grab_id int,
			@id_forma int

			    -- Insert statements for procedure here

			set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)

			set @id_forma = (Select isnull(id_forma,0) from CCRecorderRIA.dbo.RIA_FORMACALIF where id_grabacion = @grab_id and id_formato = @id_formato and tipo=1)


			--Retrieving the id forma
			select isnull(@id_forma,0)

			END