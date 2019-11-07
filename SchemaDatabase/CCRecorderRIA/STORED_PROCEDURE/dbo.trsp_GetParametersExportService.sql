CREATE PROCEDURE [dbo].[trsp_GetParametersExportService]
AS
BEGIN

DECLARE  @avrs_enviroment AS INT

SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

IF @avrs_enviroment = 2
	BEGIN
		SELECT * FROM
		(
			SELECT par_valor,par_id,par_descripcion FROM TREC_PARAMETROS
			WHERE par_id in (2,15,29,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,62,63,65,67)
			Union
			SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66,'' FROM RIA_GRABACION
			union
			select @@Servername+'|'+valor as par_valor,66 as par_id,descripcion as par_descripcion from ccsettings where setting_id=8
		)x
		ORDER BY x.par_id
	END
ELSE
	BEGIN
		SELECT * FROM
		(
			SELECT par_valor,par_id FROM TREC_PARAMETROS
			WHERE par_id in (2,15,29,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,62,63,65,66,67)
			UNION
			SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
			FROM TREC_GRABACION)x
			ORDER BY x.par_id
	END	
END