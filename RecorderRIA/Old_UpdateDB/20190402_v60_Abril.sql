/*
Autor: Daniel Vega
Descripcion: Se agrega columna prefijo grabacion


Version requerida: 59
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 60
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try



	SET @process = 'CW-2357 Alter SP trspAdmRecordingsOfDay add Column Prefix'
	SET @Sql = 'ALTER PROCEDURE dbo.trspAdmRecordingsOfDay @idAgent AS INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @CallType AS INT;

	BEGIN
		(
				SELECT a.grab_id, a.cal_id, a.tipo_llamada, a.calif_id, a.cal_key, a.finicio, a.ani, a.dni, a.cal_manual, a.id_repositorio, CASE 
						WHEN a.tipo_llamada = 2
							THEN a.ani
						ELSE a.ani
						END AS Expr1, b.cam_descripcion AS Expr2, CASE 
						WHEN duracion / 3600 < 10
							THEN ''0''
						ELSE ''''
						END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS Expr3, CASE 
						WHEN a.tipo_llamada = 2
							THEN d.description
						ELSE e.description
						END AS Expr4, ISNULL(a.id_nivel_grito, - 1), @idAgent AS age_id, ISNULL(i.total_forma, 0) AS rating, j.Computer, k.Nombres AS Agente, a.cam_id, ISNULL(a.Prefijo, '''') AS Prefix
				FROM RIA_GRABACION AS a
				INNER JOIN ccCamps AS b ON a.cam_id = b.cam_id
				LEFT OUTER JOIN ccTipoCalifOUT AS d ON a.calif_id = d.calif_id
				LEFT OUTER JOIN ccTipoCalif AS e ON a.calif_id = e.calif_id
				LEFT OUTER JOIN RIA_TIPO_GRITOS AS f ON a.id_nivel_grito = f.id_nivel_grito
				LEFT OUTER JOIN RIA_FORMACALIF AS i ON i.id_grabacion = a.grab_id
				LEFT JOIN ccPosicion AS j ON j.pos_id = a.cal_extension * - 1
				LEFT JOIN ccUsers AS k ON k.User_id = @idAgent
				WHERE a.age_id = @idAgent AND a.tipo_llamada = 2 AND DATEADD(dd, 0, DATEDIFF(dd, 0, a.finicio)) = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))
				)
		
		UNION ALL
		
		(
			SELECT a.grab_id, a.cal_id, a.tipo_llamada, a.calif_id, a.cal_key, a.finicio, a.ani, a.dni, a.cal_manual, a.id_repositorio, CASE 
					WHEN a.tipo_llamada = 2
						THEN a.ani
					ELSE a.ani
					END AS Expr1, c.descripcion AS Expr2, CASE 
					WHEN duracion / 3600 < 10
						THEN ''0''
					ELSE ''''
					END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS Expr3, CASE 
					WHEN a.tipo_llamada = 2
						THEN d.description
					ELSE e.description
					END AS Expr4, ISNULL(a.id_nivel_grito, - 1), @idAgent AS age_id, ISNULL(i.total_forma, 0) AS rating, j.Computer, k.Nombres AS Agente, a.cam_id, ISNULL(a.Prefijo, '''') AS Prefix
			FROM RIA_GRABACION AS a
			INNER JOIN ccInbound AS c ON a.cam_id = c.Inbound_id
			LEFT OUTER JOIN ccTipoCalifOUT AS d ON a.calif_id = d.calif_id
			LEFT OUTER JOIN ccTipoCalif AS e ON a.calif_id = e.calif_id
			LEFT OUTER JOIN RIA_TIPO_GRITOS AS f ON a.id_nivel_grito = f.id_nivel_grito
			LEFT OUTER JOIN RIA_FORMACALIF AS i ON i.id_grabacion = a.grab_id
			LEFT JOIN ccPosicion AS j ON j.pos_id = a.cal_extension * - 1
			LEFT JOIN ccUsers AS k ON k.User_id = @idAgent
			WHERE a.age_id = @idAgent AND a.tipo_llamada = 1 AND DATEADD(dd, 0, DATEDIFF(dd, 0, a.finicio)) = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))
			);
	END;
END;
'
	EXEC (@Sql)

		
	------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	select par_valor from trec_parametros where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end
 else begin
	select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
