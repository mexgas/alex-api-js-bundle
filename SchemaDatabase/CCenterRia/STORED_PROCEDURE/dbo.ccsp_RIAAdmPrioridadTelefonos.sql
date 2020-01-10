CREATE PROCEDURE [dbo].[ccsp_RIAAdmPrioridadTelefonos]
  @cam_id int,
  @prioridad varchar(8),
  @callbacks bit = 0,
  @Type tinyint
AS


IF @Type = 3
    BEGIN
        INSERT INTO ccCampsPrioridadTel
        VALUES
        (@cam_id, 
         '12345NNN'
        )
END
IF @Type = 2
    BEGIN
        IF NOT EXISTS
        (
            SELECT *
            FROM ccCampsPrioridadTel
            WHERE cam_id = @cam_id
        )
            BEGIN
                INSERT INTO ccCampsPrioridadTel
                VALUES
                (@cam_id, 
                 '12345NNN'
                )
        END
        UPDATE ccCampsPrioridadTel
          SET 
              prioridad = @prioridad
        WHERE cam_id = @cam_id
        IF @callbacks = 1
            BEGIN
                --Ahora cambia todos los registros en ccCampsPrioridadTel.  Solo nuevos
                UPDATE ccCampsPrioridadTel
                  SET 
                      Prioridad = @prioridad
                WHERE cam_id = @cam_id
                      AND cam_id IN
                (
                    SELECT cam_id
                    FROM ccoWorkingTable
                    WHERE cam_id = @cam_id
                          AND cal_status = 0
                )
        END
END
IF @Type = 1
    BEGIN
        SELECT ccCamps.cam_id, 
               Prioridad
        FROM ccCamps, 
             ccCampsPrioridadTel
        WHERE ccCamps.cam_id = @cam_id
              AND ccCampsPrioridadTel.cam_id = @cam_id
END