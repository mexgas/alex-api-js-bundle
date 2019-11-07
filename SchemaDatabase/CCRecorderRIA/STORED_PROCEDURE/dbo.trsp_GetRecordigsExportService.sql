CREATE PROCEDURE [dbo].[trsp_GetRecordigsExportService]
@grabId AS INT,
@integrated AS INT
AS
BEGIN
 DECLARE @SQL AS NVARCHAR(MAX)

   IF @integrated = 1
    BEGIN
	    SET @SQL = 'SELECT TOP 10000 * FROM(
	    SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local,t.finicio
	    FROM RIA_GRABACIONCONSULTA t INNER JOIN TREC_REPOSITORIOS r ON
	    t.id_repositorio = r.id_repositorio
	    UNION
	    SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local ,t.finicio
	    FROM RIA_GRABACION t INNER JOIN TREC_REPOSITORIOS r ON
	    t.id_repositorio = r.id_repositorio)x
	    WHERE x.grab_id >='+ CONVERT(VARCHAR(10), @grabId) +'AND x.finicio < GETDATE()
	    ORDER BY x.grab_id'
  	END
	ELSE IF @integrated = 0
	BEGIN

		SET @SQL = 'SELECT TOP 10000 * FROM(
		SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local,t.finicio
		FROM TREC_GRABACIONCONSULTA t INNER JOIN TREC_REPOSITORIOS r ON
		t.id_repositorio = r.id_repositorio
		UNION
		SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local ,t.finicio
		FROM TREC_GRABACION t INNER JOIN TREC_REPOSITORIOS r ON
		t.id_repositorio = r.id_repositorio)x
		WHERE x.grab_id >='+ CONVERT(VARCHAR(10), @grabId) +'AND x.finicio < GETDATE()
		ORDER BY x.grab_id'

	END
	EXEC SP_EXECUTESQL @SQL

END