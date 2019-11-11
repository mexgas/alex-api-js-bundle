CREATE FUNCTION [dbo].[fnGetCstoTarifa](
		@tipoLlamada_id TINYINT, 
		@provedor_id SMALLINT, 
		@callTime INT,
		@country_id smallint = null)
	RETURNS DECIMAL(10,3)  
	AS
	BEGIN

		DECLARE @minutouno DECIMAL(10,3)  
		DECLARE @minutoadicional DECIMAL(10,3)
		DECLARE  @costo DECIMAL(10,3)
		IF @provedor_id IS NOT NULL
			BEGIN
			SELECT @minutouno = minutouno, 
				@minutoadicional = minutoadicional
				FROM cstoTarifa 
				WHERE tipollamada_id =  @tipoLlamada_id and @provedor_id = provedor_id
			SELECT @costo = @MinutoUno + CASE WHEN ISNULL(@callTime,0) > 0 
				THEN((CEILING(( ISNULL(@callTime,0) ) / 60.0 )- 1) * @MinutoAdicional ) 
				ELSE 0 
				END
		END
		ELSE
			BEGIN
				SELECT @minutouno = cost_per_min, 
					@minutoadicional = additional_min
					FROM ccCallCost_RIA 
					WHERE tipollamada_id =  @tipoLlamada_id AND country_id = @country_id
				SELECT @costo = @MinutoUno + CASE WHEN ISNULL(@callTime,0) > 0 
					THEN((CEILING(( ISNULL(@callTime,0) ) / 60.0 )- 1) * @MinutoAdicional ) 
					ELSE 0 
					END
			END
		RETURN ISNULL(@costo, 0)
	END