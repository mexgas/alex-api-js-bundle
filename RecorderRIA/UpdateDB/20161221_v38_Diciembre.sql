/*
Autor: Erick Muñoz
Fecha: 2016/12/21
Descripcion:

	SP trsp_GetParametersExportService se modifica
Version requerida: 35
*/
USE [CCRecorderRIA]
GO
/****** Object:  StoredProcedure [dbo].[trsp_GetParametersExportService]    Script Date: 11/25/2016 13:45:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[trsp_GetParametersExportService]
				AS
				BEGIN

				DECLARE  @avrs_enviroment AS INT
				DECLARE @SQL AS NVARCHAR(MAX)

				SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

				IF @avrs_enviroment = 2
					BEGIN
						SET @SQL = 'SELECT * FROM
						(SELECT par_valor,par_id,par_descripcion FROM TREC_PARAMETROS
						WHERE par_id in (2,15,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,62,63,65,66,67)
						UNION
						SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66,''''
						FROM RIA_GRABACION)x
						ORDER BY x.par_id'
					END
				ELSE
					BEGIN

						SET @SQL = 'SELECT * FROM
						(SELECT par_valor,par_id FROM TREC_PARAMETROS
						WHERE par_id in (2,15,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,62,63,65,66,67)
						UNION
						SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
						FROM TREC_GRABACION)x
						ORDER BY x.par_id'
					END

					EXEC sp_executesql @SQL
			END