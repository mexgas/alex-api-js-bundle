CREATE PROCEDURE [dbo].[trsp_AdmUpdateSaveScores]
			 -- Add the parameters for the stored procedure here

			@id_forma int,
			@cal_id int,
			@tipo_llamada int,
			@id_calificador int,
			@id_supervisor int,
			@id_formato int,
			@total_forma int,
			@version int


			AS
			BEGIN
			 -- SET NOCOUNT ON added to prevent extra result sets from
			 -- interfering with SELECT statements.
			 SET NOCOUNT ON;

			    -- Insert statements for procedure here


			declare @grab_id int

			set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)

			Delete from CCRecorderRIA.dbo.RIA_RESULTADOSFORMA where id_forma = @id_forma

			Update CCRecorderRIA.dbo.RIA_FORMACALIF 
			set fecha_calif = GetDate(), id_calificador=@id_calificador,id_supervisor=@id_supervisor,total_forma=@total_forma, version=@version 
			where id_forma=@id_forma and id_grabacion=@grab_id and id_formato=@id_formato

			exec trsp_InsertRecNode @grab_id,1

			select @id_forma

			END