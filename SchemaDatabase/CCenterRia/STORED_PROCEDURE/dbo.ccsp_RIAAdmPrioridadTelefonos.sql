CREATE PROCEDURE dbo.ccsp_RIAAdmPrioridadTelefonos 
				@cam_id INT, @prioridad VARCHAR(8), @callbacks BIT= 0, @Type TINYINT
AS
BEGIN

	--Actualiza la prioridad en la tabla
	IF @Type = 3
	BEGIN
		INSERT INTO ccCampsPrioridadTel
		VALUES( @cam_id, '12345NNN' );
	END;

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
			VALUES( @cam_id, @prioridad );
		END;
			 ELSE
		BEGIN
			UPDATE ccCampsPrioridadTel
			  SET prioridad = @prioridad
			WHERE cam_id = @cam_id;
		END;

		IF @callbacks = 1
		BEGIN
			--Ahora cambia todos los registros en ccoCallsoutsource.  Solo nuevos
			UPDATE ccoCallsoutsource
			  SET dial_tels = @prioridad
			WHERE cam_id = @cam_id AND 
				  callout_id IN
			(
				SELECT callout_id
				FROM ccoWorkingTable
				WHERE cam_id = @cam_id AND 
					  cal_status = 0
			);
		END;
			 ELSE
		BEGIN
			UPDATE ccoCallsoutsource
			  SET dial_tels = @prioridad
			WHERE cam_id = @cam_id;
		END;
	END;
	IF @Type = 1
	BEGIN
		SELECT ccCamps.cam_id, Prioridad
		FROM ccCamps, ccCampsPrioridadTel
		WHERE ccCamps.cam_id = @cam_id AND 
			  ccCampsPrioridadTel.cam_id = @cam_id;
	END;
END;