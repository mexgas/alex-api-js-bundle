CREATE PROCEDURE [dbo].[trsp_AdmGetExportCamp]
			-- Add the parameters for the stored procedure here
			@id int
			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

			select Campo from CCRecorderRIA.dbo.TREC_FORM_ARCHIVOSEXPORT where id = @id

			END