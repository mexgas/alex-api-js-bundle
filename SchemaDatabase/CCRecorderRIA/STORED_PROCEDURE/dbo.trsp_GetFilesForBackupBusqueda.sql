CREATE PROCEDURE [dbo].[trsp_GetFilesForBackupBusqueda]
@start INT,
@end INT,
@valida BIT,
@valida2 BIT,
@paramBusqueda INT,
@cadParam VARCHAR(8000),
@info INT,
@cadInfo VARCHAR(8000),
@duracion INT
AS
DECLARE @MinTime AS INT
DECLARE @Sql as VARCHAR(8000)
DECLARE @SqlHist as VARCHAR(8000)
Declare @ExistHist as bit

BEGIN

	if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RIA_GRABACIONConsulta]'))
		set @ExistHist = 1
	else
		set @ExistHist = 0
	SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
	IF (@MinTime is NULL)
	BEGIN
		SELECT @MinTime=0
	END
	IF @duracion>0
	BEGIN
		SET @MinTime=@duracion
	END

	SET @Sql='SELECT grab_id'
	IF @valida=1
	BEGIN
		SET @Sql=@Sql + ', finicio, fvalida '
	END
	IF @valida2=1
	BEGIN
		SET @Sql=@Sql + ', finicio,fvalida2 '
	END
	
	SET  @Sql=@Sql + ' FROM RIA_GRABACION WHERE duracion >=' + CONVERT(varchar,@MinTime) + ' AND grab_id >= ' + CONVERT(varchar,@start) + '  AND grab_id <=' +CONVERT(varchar,@end)

	IF @paramBusqueda=1
	BEGIN
		SET @Sql=@Sql + ' AND age_id IN (' + @cadParam + ')'
	END
	IF @paramBusqueda=2
	BEGIN
		SET @Sql=@Sql + ' AND extension IN (' + @cadParam + ')'
	END	
	
	IF @info=1
	BEGIN
		SET @Sql=@Sql + ' AND info1 LIKE "%' + @cadInfo + '%"'
	END
	IF @info=2
	BEGIN
		SET @Sql=@Sql + ' AND info2 LIKE "%' + @cadInfo + '%"'
	END
	if @ExistHist = 1
		select @SqlHist = replace (@Sql, 'RIA_GRABACION', 'RIA_GRABACIONConsulta') +' union ' + @Sql
	--SELECT 'QRY'=@Sql
	exec(@SqlHist)
END