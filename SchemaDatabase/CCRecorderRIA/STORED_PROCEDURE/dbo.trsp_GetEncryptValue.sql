CREATE PROCEDURE trsp_GetEncryptValue
AS 
BEGIN
	
	SELECT par_valor from TREC_PARAMETROS
	WHERE par_id = 15

END