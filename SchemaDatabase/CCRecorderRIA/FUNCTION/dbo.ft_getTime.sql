CREATE FUNCTION [dbo].[ft_getTime]
(
    @segundos INT,
    @type varchar(max)  -- Forma en la que se va a transformar
)                       -- 1: Formato String x horas x minutos x segundos
                        -- 2: Formato Number HH:MM:SS
--Llamada a la función
--DECLARE @format varchar(255)
--SET @format = (SELECT dbo.myfn_sla_get_format_HMS(8500,1))
--PRINT @format
RETURNS VARCHAR(MAX)
AS 
BEGIN
    DECLARE @temp VARCHAR(100)
    DECLARE @horas INT
    DECLARE @minutos INT
    DECLARE @tempMINUTOS INT
	DECLARE @sSegundos VARCHAR(100)
	DECLARE @sMinutos VARCHAR(100)
	DECLARE @sHoras VARCHAR(100)

 
    SET @temp ='...'
 
    IF (@segundos < 3600 AND @segundos >= 60) BEGIN
        SET @minutos =  FLOOR(@segundos / 60)
        SET @segundos = @segundos % 60
            --Según el tipo recibido lo formateo de una forma u otra
			IF @minutos > 9
				BEGIN
					set @sMinutos = CONVERT(VARCHAR, @minutos)						
				END
			ELSE
				BEGIN
					set @sMinutos = '0' + CONVERT(VARCHAR, @minutos)
				END 
					
			IF @segundos > 9
				BEGIN
					set  @sSegundos = CONVERT(VARCHAR, @segundos)
				END
			ELSE
				BEGIN
					set @sSegundos = '0' + CONVERT(VARCHAR, @segundos)
				END

            IF @type = 1
                SET @temp = '0 Horas ' + CONVERT(VARCHAR, @minutos) + ' Minutos ' + CONVERT(VARCHAR, @segundos) + ' Segundos'
            ELSE	           
                SET @temp = '00:' + @sMinutos + ':' +  @sSegundos

    END ELSE IF(@segundos < 60)
	BEGIN
		SET @minutos =  0
        SET @segundos = @segundos
            --Según el tipo recibido lo formateo de una forma u otra
			IF @segundos > 9
				BEGIN
					set  @sSegundos = CONVERT(VARCHAR, @segundos)
				END
			ELSE
				BEGIN
					set @sSegundos = '0' + CONVERT(VARCHAR, @segundos)
				END

            IF @type = 1
                SET @temp = '0 Horas ' + CONVERT(VARCHAR, @minutos) + ' Minutos ' + CONVERT(VARCHAR, @segundos) + ' Segundos'
            ELSE
				SET @temp = '00:' + '00' + ':' + @sSegundos

	END ELSE
BEGIN 
    SET @horas = FLOOR(@segundos / 3600)
    SET @tempMINUTOS = @segundos % 3600
    SET @minutos = FLOOR(@tempMINUTOS / 60) --MINUTOS FINALES
    SET @segundos = @tempMINUTOS % 60
        --Según el tipo recibido lo formateo de una forma u otra

		IF @horas > 9
			BEGIN
				set @sHoras = CONVERT(VARCHAR, @horas) 
			END
		ELSE
			BEGIN
				set @sHoras = '0' + CONVERT(VARCHAR, @horas) 
			END

		IF @minutos > 9
			BEGIN
				set @sMinutos = CONVERT(VARCHAR, @minutos)				
			END
		ELSE
			BEGIN
				set @sMinutos = '0' + CONVERT(VARCHAR, @minutos)						
			END 
					
		IF @segundos > 9
			BEGIN
				set  @sSegundos = CONVERT(VARCHAR, @segundos)
			END
		ELSE
			BEGIN
				set @sSegundos = '0' + CONVERT(VARCHAR, @segundos)
			END

        IF @type = 1
            SET @temp = CONVERT(VARCHAR, @horas) + ' Horas ' + CONVERT(VARCHAR, @minutos) + ' Minutos ' + CONVERT(VARCHAR, @segundos) + ' Segundos'
        ELSE            
            SET @temp = @sHoras + ':' + @sMinutos + ':' + @sSegundos
END 
    RETURN @temp
END