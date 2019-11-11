CREATE PROCEDURE [dbo].[trsp_GetAppParameters]
						  @app_id AS INT
						    AS
						    BEGIN
						    DECLARE  @avrs_enviroment AS INT
						    DECLARE @SQL AS NVARCHAR(MAX)

						    --AVRS Recordings Manager
						    IF @app_id = 1
						    BEGIN
						      SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

						        IF @avrs_enviroment = 2
						          BEGIN
						        
						            SET @SQL = 'SELECT par_valor,par_id 
						                  FROM TREC_PARAMETROS 
						                  WHERE par_id 
						                  IN (67,68,69,70)
						                  ORDER BY par_id'                      
						          END 
						        ELSE
						          BEGIN

						            SET @SQL = 'SELECT par_valor,par_id 
						                  FROM TREC_PARAMETROS 
						                  WHERE par_id 
						                  IN (82,83,84,85)
						                  ORDER BY par_id'  
						          END
						    END

						    EXEC sp_executesql @SQL

						    END