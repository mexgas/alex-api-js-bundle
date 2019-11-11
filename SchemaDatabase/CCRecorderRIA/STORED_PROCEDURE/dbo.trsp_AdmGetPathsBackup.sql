CREATE PROCEDURE [dbo].[trsp_AdmGetPathsBackup]
AS
BEGIN
	SET NOCOUNT ON;
select id_ruta_backup,ruta from TREC_RUTAS_BACKUP
END