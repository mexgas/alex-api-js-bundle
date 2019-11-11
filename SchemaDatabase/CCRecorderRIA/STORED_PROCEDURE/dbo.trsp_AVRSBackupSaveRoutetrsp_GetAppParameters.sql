CREATE PROCEDURE trsp_AVRSBackupSaveRoutetrsp_GetAppParameters
	@grab_id int,
	@status_audio int,
	@status_video int,
	@id_ruta_backup int
	AS
	BEGIN
		
		INSERT INTO TREC_BACKUPS VALUES(@grab_id, @status_audio, @status_video, @id_ruta_backup)

	END