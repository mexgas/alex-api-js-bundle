CREATE PROCEDURE [dbo].[trsp_GetFilesToDelete]
@finicio as datetime,
@ffin as datetime,
@sinLimite as bit,
@duracion as int
 AS
IF @sinLimite=1
BEGIN
	SELECT grab_id FROM RIA_GRABACION with (index(IX_RIA_GRABACION_3)) WHERE finicio BETWEEN @finicio AND @ffin
END
ELSE
BEGIN
	SELECT grab_id FROM RIA_GRABACION with (index(IX_RIA_GRABACION_6)) WHERE finicio BETWEEN @finicio AND @ffin AND duracion<@duracion
END