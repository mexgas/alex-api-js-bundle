CREATE FUNCTION [dbo].[GetCarrierByTel] (@tel VARCHAR(32))
			RETURNS VARCHAR(255)
			AS
			BEGIN
				DECLARE @ld VARCHAR(7), @cldLocal VARCHAR(7)
				DECLARE @lon TINYINT
				DECLARE @mod VARCHAR(10)
				DECLARE @serie VARCHAR(10)
				DECLARE @carrier VARCHAR(255)

				SELECT @lon = len(@tel), @mod = '', @carrier = ''

				IF @lon < 10
				BEGIN
					RETURN ''
				END

				SELECT @cldLocal = valor
				FROM ccSettings WITH (NOLOCK)
				WHERE setting_id = 17

				SELECT @tel = right(@tel, 10)

				SELECT @lon = len(@tel)

				IF @lon = 10
				BEGIN
					IF EXISTS (
								SELECT TOP 1 cld
								FROM series NOLOCK
								WHERE cld = left(@tel, 3)
								and serie=SUBSTRING(@tel,4,3)
								)
							SELECT @ld = left(@tel, 3),@serie=SUBSTRING(@tel,4,3)
						ELSE IF EXISTS (
								SELECT TOP 1 cld
								FROM series NOLOCK
								WHERE cld = left(@tel, 2)
								and serie=SUBSTRING(@tel,3,4)
								)
							SELECT @ld = left(@tel, 2),@serie=SUBSTRING(@tel,3,4)
						ELSE
						BEGIN
							RETURN ''
						END

					SELECT TOP 1 @mod = modalidad, @carrier= [RAZON SOCIAL]
					FROM series NOLOCK
					WHERE cld = @ld AND serie = @serie AND right(@tel, 4) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

				END

				RETURN @carrier
			END