CREATE PROCEDURE CW_trsp_GetExportFormats
					AS
					select ID,Formato,
					CASE 
					         WHEN TREC_FORM_ARCHIVOSEXPORT.formato  = 'PERSONALIZADO' THEN TREC_FORM_ARCHIVOSEXPORT.Campo
					         ELSE ''
					      END as Value
					from  TREC_FORM_ARCHIVOSEXPORT order by id