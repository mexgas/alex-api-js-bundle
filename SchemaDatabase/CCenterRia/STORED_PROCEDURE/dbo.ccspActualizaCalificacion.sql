CREATE   PROCEDURE [dbo].[ccspActualizaCalificacion]
@cal_id BIGINT,
@tipo_Llam TINYINT,
@new_calif_id INT
AS
-- Crea el SP para hacer la actualización de calificaciones de llamadas en la base de CW desde AVRS
DECLARE @timegroup VARCHAR(19),@cam_id INT,@user_id INT,@old_calif_id INT
DECLARE @query VARCHAR(2000), @camp_field VARCHAR(20), @tablaLlamadas VARCHAR(20), @tablaReportes VARCHAR(20)
DECLARE @eraVenta TINYINT, @esVenta TINYINT

IF @tipo_Llam = 1
BEGIN
	SET @camp_field = 'Inbound_id'
	SET @tablaLlamadas = 'ccCallsIn'
	SET @tablaReportes = 'ccGenInCalif'
	SELECT @timegroup = CONVERT(VARCHAR(14),cal_Inicio, 121)+'00:00', @cam_id = Inbound_id, @user_id = user_id, @old_calif_id = calif_id
	FROM ccCallsIn WHERE cal_id = @cal_id
END
ELSE
BEGIN
	SET @camp_field = 'cam_id'
	SET @tablaLlamadas = 'ccoCallsOut'
	SET @tablaReportes = 'ccGenOutCallCalif'
	SELECT @timegroup = CONVERT(VARCHAR(14),cal_Inicio, 121)+'00:00', @cam_id = cam_id, @user_id = user_id, @old_calif_id = calif_id
	FROM ccoCallsOut WHERE cal_id = @cal_id
END

--Actualiza tabla de llamadas
SET @query = 'UPDATE ' + @tablaLlamadas + ' SET calif_id = ' + CAST(@new_calif_id AS VARCHAR(6)) + ' WHERE cal_id = ' + CAST(@cal_id AS VARCHAR(15))
PRINT @query
EXEC (@query)

--Resta uno en la tabla de reportes para la calificación antigua especificada
SET @query = 'UPDATE ' + @tablaReportes + ' SET amount = CASE WHEN amount > 0 THEN amount - 1 ELSE 0 END WHERE timegroup = ''' + @timegroup +''' AND ' + @camp_field +
       ' = ' + CAST(@cam_id AS VARCHAR(6)) + ' AND user_id = ' + CAST(@user_id AS VARCHAR(6)) + ' AND calif_id = ' + CAST(@old_calif_id AS VARCHAR(6))
PRINT(@query)
EXEC(@query)

--Suma uno en la tabla de reportes para la calificación antigua especificada
SET @query = 'UPDATE ' + @tablaReportes + ' SET amount = amount + 1 WHERE timegroup = ''' + @timegroup +''' AND ' + @camp_field +
       ' = ' + CAST(@cam_id AS VARCHAR(6)) + ' AND user_id = ' + CAST(@user_id AS VARCHAR(6)) + ' AND calif_id = ' + CAST(@new_calif_id AS VARCHAR(6)) + CHAR(10)

--Si no existía un registro con esa calificación lo agrega en la tabla
SET @query = @query + 'IF @@ROWCOUNT = 0' + CHAR(10) + 'BEGIN' + CHAR(10)+ 'INSERT INTO ' + @tablaReportes +' (timegroup, ' + @camp_field +
             ', user_id, calif_id, amount) VALUES (''' + @timegroup + ''', ' + CAST(@cam_id AS VARCHAR(6)) + ', ' + CAST(@user_id AS VARCHAR(6)) + 
             ',' + CAST(@new_calif_id AS VARCHAR(6)) + ', 1)' + CHAR(10) + 'END'

PRINT(@query)
EXEC(@query)

SELECT CONVERT(VARCHAR,@timegroup,121) timegroup, CONVERT(VARCHAR,@cam_id) cam_id, CONVERT(VARCHAR,@user_id) user_id, CONVERT(VARCHAR,@old_calif_id) old_calif_id