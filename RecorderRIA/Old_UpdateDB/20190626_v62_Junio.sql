/*
Autor: Jesus Gallardo
Descripcion: CW-2926


Version requerida: 59
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 62
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try



	SET @process = 'CW-3045 Alter SP '
	SET @Sql = 'ALTER PROCEDURE [dbo].[trsp_GetFilesAnalisisGritos] @sExtension AS VARCHAR(10) = ''.vox''
AS
BEGIN
	DECLARE @Integrado AS INT;
	DECLARE @FInicio AS DATETIME;
	DECLARE @sSql1 AS NVARCHAR(MAX);
	DECLARE @sSql2 AS NVARCHAR(MAX);
	DECLARE @sSql3 AS NVARCHAR(MAX);
	DECLARE @sSql AS NVARCHAR(MAX);
	DECLARE @Encriptado AS INT;
	DECLARE @ENC AS VARCHAR(4);

	SET @FInicio = DATEADD(MINUTE, - 1, GETDATE());
	SET @sSql = N'''';
	SET @sSql3 = N'''';

	SELECT @sExtension = trec_parametros.par_valor
	FROM dbo.trec_parametros
	WHERE trec_parametros.par_id = 54

	SELECT @integrado = trec_parametros.par_valor
	FROM dbo.trec_parametros
	WHERE trec_parametros.par_id = 29;

	IF @integrado = 0
	BEGIN --AVRS Standalone;
		SET @sSql1 = ''Select top(1000) grab_id, grab_id, cast(grab_id as varchar(20))+'' + CHAR(0x27) + @sExtension + CHAR(0x27);
		SET @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from trec_grabacion NOLOCK where finicio < @fecInicio '';
		SET @sSql2 = @sSql2 + '' and (id_nivel_grito is NULL or id_nivel_grito=-1)'';
	END
	ELSE IF @integrado = 1 --AVRS Integrada
	BEGIN
		SET @sSql1 = ''Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20))+'' + CHAR(0x27) + @sExtension + CHAR(0x27);
		SET @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from trec_grabacion NOLOCK where finicio < @fecInicio '';
		SET @sSql2 = @sSql2 + '' and (id_nivel_grito is NULL or id_nivel_grito=-1)'';
	END
	ELSE IF @integrado = 2
	BEGIN
		SELECT @Encriptado = trec_parametros.par_valor
		FROM dbo.trec_parametros
		WHERE trec_parametros.par_id = 15;

		SET @ENC = CASE WHEN @Encriptado = 1 THEN ''.enc'' ELSE '''' END

		SELECT TOP (1000) grab_id, cal_id, CAST(cal_id AS VARCHAR(20)) + 
		CASE WHEN Prefijo is null or Prefijo = '''' THEN '''' ELSE ''_'' + Prefijo END + @sExtension + @ENC AS extension, 
		ISNULL(tipo_llamada, 0) AS tipo_llamada, id_repositorio, COALESCE(Prefijo, '''') AS Prefijo
		FROM ria_grabacion NOLOCK
		WHERE finicio < @FInicio AND (id_nivel_grito IS NULL OR id_nivel_grito = - 1)
		ORDER BY finicio ASC;

		RETURN (0);
	END;

	IF @Integrado IN (0, 1)
	BEGIN
		SET @sSql = @sSql1 + @sSql2 + N'' order by finicio asc'';

		EXEC sp_executesql @sSql, N''@fecInicio datetime'', @fecInicio = @FInicio;
	END
END
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
