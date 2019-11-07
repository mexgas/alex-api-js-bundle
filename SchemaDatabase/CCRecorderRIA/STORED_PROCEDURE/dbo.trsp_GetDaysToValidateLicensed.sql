CREATE PROCEDURE [dbo].[trsp_GetDaysToValidateLicensed]
AS
BEGIN
	DECLARE @isIntegrated AS INT

	-- 0 AVRS STANDALONE
	-- 1 AVRS CW INTEGRATED
	-- 2 AVRS RIA CW INTEGRATED
	SET @isIntegrated = (SELECT par_valor FROM TREC_PARAMETROS 
						WHERE par_id = 29)
	

	IF @isIntegrated = 2
		BEGIN
			SELECT datediff(dd, (select isnull(max(finicio), getdate()-1) FROM RIA_GRABACION), getdate()) as dias
		END
	ELSE
		BEGIN
			SELECT datediff(dd, (select isnull(max(finicio), getdate()-1) FROM TREC_GRABACION), getdate()) as dias			
		END
END