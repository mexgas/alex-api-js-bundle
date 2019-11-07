CREATE PROCEDURE [dbo].[trsp_GetFilesForBackupVal]
@start INT,
@end INT
AS
DECLARE @MinTime AS INT
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
	if @ExistHist = 1
	begin
		SELECT grab_id, finicio, fvalida FROM RIA_GRABACIONConsulta with (index(IX_RIA_GRABACIONCONSULTA_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end
		union
		SELECT grab_id, finicio, fvalida FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end
	end
	else
		SELECT grab_id, finicio, fvalida FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end
END