CREATE PROCEDURE [dbo].[trsp_AVRSBackup]

@option INT,
@grab_id INT,
@id_ruta_backup INT,
@status INT,
@ruta VARCHAR(50)

AS
BEGIN

    SET NOCOUNT ON;
    IF @option=1
        BEGIN
          SELECT MAX(id_ruta_backup) AS id_ruta_backup FROM TREC_RUTAS_BACKUP
    END
    IF @option=2
        BEGIN
            INSERT INTO TREC_RUTAS_BACKUP(ruta)VALUES(@ruta)
    END
   IF @option=3
        BEGIN
          SELECT grab_id FROM TREC_BACKUPS WHERE grab_id = @grab_id
    END
    IF @option=4
    BEGIN
            UPDATE TREC_BACKUPS SET status_audio=@status, id_ruta_backup=@id_ruta_backup WHERE grab_id=@grab_id
    END
    IF @option=5
        BEGIN
        IF @status = 3
        begin
            INSERT INTO TREC_BACKUPS (grab_id,status_audio,status_video,id_ruta_backup)VALUES(@grab_id,@status,3,@id_ruta_backup)
        end
        ELSE
        begin
            INSERT INTO TREC_BACKUPS (grab_id,status_audio,status_video,id_ruta_backup)VALUES(@grab_id,@status,0,@id_ruta_backup)
        end
    END
   IF @option=6
        BEGIN
        select * from TREC_LISTA_MAIL where nivel_id=1 or nivel_id=3
    END
   IF @option=7
        BEGIN
        select * from TREC_PARAMETROS where par_id=24
    END
    IF @option=8
        BEGIN
        select * from TREC_PARAMMAIL where MailType=4
    END

    IF @option=9
        BEGIN
         SELECT grab_id FROM TREC_BACKUPS WHERE grab_id = @grab_id
    END
    IF @option=10
        BEGIN
        UPDATE TREC_BACKUPS SET status_video=@status, id_ruta_backup=@id_ruta_backup WHERE grab_id=@grab_id
    END
   IF @option=11
        BEGIN
        INSERT INTO TREC_BACKUPS (grab_id,status_audio,status_video,id_ruta_backup)VALUES(@grab_id,0,@status,@id_ruta_backup)
    END
END