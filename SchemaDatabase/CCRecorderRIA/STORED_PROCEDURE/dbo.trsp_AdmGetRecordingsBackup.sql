CREATE PROCEDURE [dbo].[trsp_AdmGetRecordingsBackup]
			@startDate datetime,
			@endDate datetime
			AS
			BEGIN
				
				SELECT grab_id, isnull(status_audio,0),isnull(status_video,0), isnull(id_ruta_backup,0) 
				FROM TREC_BACKUPS 
				WHERE grab_id in  (
								  SELECT *  FROM (SELECT grab_id
								  FROM RIA_GRABACION
								  WHERE finicio between @startDate and @endDate 
								  UNION
								  SELECT grab_id
								  FROM RIA_GRABACIONCONSULTA
								  WHERE finicio between @startDate and @endDate) AS t )
				
			END