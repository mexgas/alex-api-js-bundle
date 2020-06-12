CREATE PROCEDURE CW_trsp_UpdateCustomText
					@newCustomText as nvarchar(255)
					AS
					update dbo.TREC_FORM_ARCHIVOSEXPORT set Campo=@newCustomText where Formato = 'PERSONALIZADO'