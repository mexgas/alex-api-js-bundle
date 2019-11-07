CREATE  PROCEDURE [dbo].[trsp_GetExportFormats]
				AS
				BEGIN
				SET NOCOUNT ON;
						select id,formato from  TREC_FORM_ARCHIVOSEXPORT order by id
				END