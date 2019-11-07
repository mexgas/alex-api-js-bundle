CREATE FUNCTION [dbo].[Verifica2] (@tel VARCHAR(32), @pais TINYINT = 0, @cldLocal VARCHAR(7) = '')
RETURNS VARCHAR(32)
AS
BEGIN
	DECLARE @ld VARCHAR(7)
	DECLARE @lon TINYINT
	DECLARE @result TINYINT
	DECLARE @mod VARCHAR(10)
	DECLARE @Cadena VARCHAR(32)
	DECLARE @isLocal BIT

	IF (@pais = 0 AND @cldLocal = '')
	BEGIN
		SELECT @pais = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 104

		SELECT @cldLocal = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 17
	END

	SELECT @tel = dbo.limpia(@tel)

	IF @pais = 1
	BEGIN --Empieza Mexico
		SELECT @lon = len(@tel), @mod = ''

		IF @lon < 10
		BEGIN
			RETURN 'E_' + @tel
		END

		SELECT @tel = right(@tel, 10)

		SELECT @lon = len(@tel)

		IF @lon = 10
		BEGIN
			IF EXISTS (
					SELECT TOP 1 cld
					FROM series NOLOCK
					WHERE cld = left(@tel, 3)
					)
				SELECT @ld = left(@tel, 3)
			ELSE IF EXISTS (
					SELECT TOP 1 cld
					FROM series NOLOCK
					WHERE cld = left(@tel, 2)
					)
				SELECT @ld = left(@tel, 2)
			ELSE
				RETURN 'E_' + @tel

			SELECT TOP 1 @mod = modalidad
			FROM series NOLOCK
			WHERE cld = @ld AND serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) AND right(@tel, 4) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

			IF @mod NOT IN ('FIJO', 'MPP', 'CPP')
			BEGIN
				RETURN 'E_' + @tel
			END

			DECLARE @specialDialPlan TINYINT

			SELECT @specialDialPlan = valor
			FROM ccsettings WITH (NOLOCK)
			WHERE setting_id = 195

			IF @specialDialPlan = 2
			BEGIN --Number 10 digits
				RETURN @tel
			END

			SET @isLocal = 0

			IF EXISTS (
					SELECT *
					FROM ccRiaArecode
					WHERE area = @ld
					)
			BEGIN
				SET @isLocal = 1
			END
			ELSE IF @cldLocal = @ld
			BEGIN
				SET @isLocal = 1
			END

			IF @specialDialPlan = 1
			BEGIN
				--Number local 10 digit
				--Number LD 12 digit
				--Number Cell 13 digit
				SELECT @tel = CASE WHEN @mod IN ('FIJO', 'MPP') THEN CASE WHEN @isLocal = 1 THEN @tel ELSE '01' + @tel END WHEN @mod = 'CPP' THEN --Local y LD
								CASE WHEN @isLocal = 1 THEN '044' + @tel ELSE '045' + @tel END END --Celular
			END
			ELSE
			BEGIN
				--Number local 7 o 8 digit
				--Number LD 12 digit
				--Number Cell 13 digit
				SELECT @tel = CASE WHEN @mod IN ('FIJO', 'MPP') THEN CASE WHEN @isLocal = 1 THEN right(@tel, 10 - len(@ld)) ELSE '01' + @tel END WHEN @mod = 'CPP' THEN --Local y LD
								CASE WHEN @isLocal = 1 THEN '044' + @tel ELSE '045' + @tel END END --Celular
			END
		END
		ELSE IF @lon > 0
		BEGIN
			SET @tel = 'E_' + @tel
		END

		RETURN @tel
	END --Termina Mexico
			--------------------------- Empieza Argentina ---------------------------
	ELSE IF @pais = 2
	BEGIN
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = 'E'
		BEGIN
			RETURN @tel
		END

		SELECT @lon = len(@tel)

		IF @lon IN (6, 7, 8) AND left(@tel, 2) <> '15'
		BEGIN
			SET @tel = @cldLocal + @tel
		END

		IF @lon IN (8, 9, 10) AND left(@tel, 2) = '15'
		BEGIN
			SET @tel = @cldLocal + substring(@tel, 3, @lon - 2)
		END

		--Buscamos el 15
		IF @lon = 13
		BEGIN
			DECLARE @index AS INT

			SELECT @index = charindex('15', @tel)

			--El unico caso en el que la lada tiene un 15 es con lada 3715
			IF @index < 2
			BEGIN
				SELECT @tel = 'E_' + @tel

				RETURN @tel
			END
			ELSE
			BEGIN
				IF substring(@tel, @index - 2, 4) = '3715'
				BEGIN
					SELECT @ld = '3715'

					SET @tel = @ld + right(@tel, 6)
				END
				ELSE
				BEGIN
					SELECT @ld = substring(@tel, 2, @index - 2)

					SET @tel = @ld + right(@tel, 13 - (@index + 1))
				END
			END
		END

		SELECT @tel = right(@tel, 10)

		IF len(@tel) = 10
		BEGIN
			DECLARE @serie AS VARCHAR(5)

			BEGIN
				-- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
				DECLARE @contLD AS INT
				DECLARE @cont AS INT

				SET @contLD = 4

				BuscaLada:

				IF isnull(@ld, '') = '' AND @contLD >= 2
				BEGIN
					SELECT @ld = cld
					FROM seriesArg
					WHERE cld = left(@tel, @contLD)

					IF isnull(@ld, '') = ''
					BEGIN
						SET @contLD = @contLD - 1

						GOTO BuscaLada
					END
				END
				ELSE
				BEGIN
					IF isnull(@ld, '') = ''
					BEGIN
						SELECT @tel = 'E_' + @tel
					END
				END
			END

			-- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
			BEGIN
				IF len(@ld) = 2
				BEGIN
					SET @cont = 5

					buscaSerie2:

					IF isnull(@serie, '') = '' AND @cont >= 4
					BEGIN
						SELECT @serie = serie
						FROM seriesArg
						WHERE cld = @ld AND serie = substring(@tel, 3, @cont)

						IF isnull(@serie, '') = ''
						BEGIN
							SET @cont = @cont - 1

							GOTO buscaSerie2
						END
					END
				END
				ELSE
				BEGIN
					IF len(@ld) = 3
					BEGIN
						SET @cont = 4

						buscaSerie3:

						IF isnull(@serie, '') = '' AND @cont >= 3
						BEGIN
							SELECT @serie = serie
							FROM seriesArg
							WHERE cld = @ld AND serie = substring(@tel, 4, @cont)

							IF isnull(@serie, '') = ''
							BEGIN
								SET @cont = @cont - 1

								GOTO buscaSerie3
							END
						END
					END
					ELSE
					BEGIN
						IF len(@ld) = 4
						BEGIN
							SET @cont = 3

							buscaSerie4:

							IF isnull(@serie, '') = '' AND @cont >= 2
							BEGIN
								SELECT @serie = serie
								FROM seriesArg
								WHERE cld = @ld AND serie = substring(@tel, 5, @cont)

								IF isnull(@serie, '') = ''
								BEGIN
									SET @cont = @cont - 1

									GOTO buscaSerie4
								END
							END
						END
					END
				END
			END

			SELECT @mod = modalidad
			FROM seriesArg
			WHERE cld = @ld AND serie = @serie AND right(@tel, 10 - len(@ld) - len(@serie)) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

			-- Si la serie es nula, existe una posibilidad de que la lada este mal, asi que se quita un numero de la lada y se vuelve a buscar la serie			
			IF isNull(@serie, '') = '' AND @contLD > 1
			BEGIN
				SET @contLD = len(@ld) - 1
				SET @ld = NULL

				GOTO BuscaLada
			END

			SELECT @tel = CASE WHEN @mod IN ('BASICA', 'MPP') THEN CASE WHEN @ld = @cldLocal THEN right(@tel, 10 - len(@ld)) ELSE '0' + @tel END WHEN @mod = 'CPP' THEN CASE WHEN @ld = @cldLocal THEN '15' + right(@tel, 10 - len(@ld)) ELSE '0' + @ld + '15' + right(@tel, 10 - len(@ld)) END ELSE 'E_' + @tel END
		END
		ELSE
		BEGIN
			IF len(@tel) > 0
			BEGIN
				SELECT @tel = 'E_' + @tel
			END
		END

		RETURN @tel
	END ------------------ Termina Argentina ------------------
	ELSE IF @pais = 3
	BEGIN --Empieza Colombia
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = 'E'
		BEGIN
			RETURN @tel
		END

		IF len(@tel) NOT IN (7, 8, 10, 11)
		BEGIN
			RETURN 'E_' + @tel
		END

		IF len(@tel) = 7
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesCol
					WHERE serie = left(@tel, 4) AND @cldLocal = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN 'E_' + @tel
			END
		END

		IF len(@tel) = 8
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesCol
					WHERE serie = substring(@tel, 2, 4) AND left(@tel, 1) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN 'E_' + @tel
			END
		END

		IF len(@tel) = 10
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesCol
					WHERE serie = substring(@tel, 5, 3) AND (left(@tel, 3) + '-' + substring(@tel, 4, 1)) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN 'E_' + @tel
			END
		END

		IF len(@tel) = 11
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesCol
					WHERE serie = substring(@tel, 6, 3) AND (substring(@tel, 2, 3) + '-' + substring(@tel, 5, 1)) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN 'E_' + @tel
			END
		END
	END --Termina Colombia

	-- Empieza Chile
	IF @pais = 5
	BEGIN
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = 'E'
		BEGIN
			RETURN @tel
		END

		IF len(@tel) = 6 AND len(@cldLocal) = 2
		BEGIN
			IF EXISTS (
					SELECT serie
					FROM seriesChi
					WHERE cld = @cldLocal AND left(@tel, 3) = serie AND right(@tel, 3) BETWEEN numeracioninicial AND numeracionFinal
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN 'E_' + @tel
			END
		END

		IF len(@tel) = 7
		BEGIN
			IF @cldLocal IN (2, 41, 44, 32)
			BEGIN
				IF EXISTS (
						SELECT serie
						FROM serieschi
						WHERE serie = left(@tel, 4)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					IF left(@tel, 3) = '200' AND EXISTS (
							SELECT serie
							FROM serieschi
							WHERE serie = left(@tel, 3)
							)
					BEGIN
						RETURN @tel
					END
				END
			END
		END

		IF len(@tel) = 8
		BEGIN
			IF left(@tel, 1) = '2'
			BEGIN
				IF EXISTS (
						SELECT serie
						FROM serieschi
						WHERE serie = substring(@tel, 2, 4)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM serieschi
							WHERE serie = substring(@tel, 2, 5)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN 'E_' + @tel
					END
				END
			END
			ELSE
			BEGIN
				RETURN @tel
			END
		END

		IF len(@tel) = 10
		BEGIN
			IF left(@tel, 2) = '09'
			BEGIN
				IF EXISTS (
						SELECT serie
						FROM serieschi
						WHERE cld = substring(@tel, 3, 1) AND serie = substring(@tel, 5, 3)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					RETURN 'E_' + @tel
				END
			END
		END
	END

	--Termina Chile
	IF @pais = 6
	BEGIN --Empieza Venezuela
		SELECT @lon = len(@tel)

		IF @lon = 7
		BEGIN
			SET @tel = @cldLocal + @tel
		END

		SELECT @tel = right(@tel, 10)

		IF len(@tel) = 10
		BEGIN
			SELECT @ld = left(@tel, 3)

			SELECT @mod = tipo
			FROM seriesVen
			WHERE left(@tel, 3) = LD

			IF @mod = 'CPP'
			BEGIN
				IF EXISTS (
						SELECT *
						FROM seriesVen
						WHERE LD = @ld
						)
				BEGIN
					IF @ld = @cldLocal
					BEGIN
						SELECT @tel = right(@tel, 7)
					END
					ELSE
					BEGIN
						SELECT @tel = '0' + @tel
					END
				END
				ELSE
				BEGIN
					SELECT @tel = 'E_' + @tel
				END
			END
			ELSE
			BEGIN
				IF @mod = 'FIJO'
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesVen
							WHERE serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) AND right(@tel, 4) BETWEEN [Inicio] AND [Fin]
							)
					BEGIN
						IF @ld = @cldLocal
						BEGIN
							SELECT @tel = right(@tel, 7)
						END
						ELSE
						BEGIN
							SELECT @tel = '0' + @tel
						END
					END
					ELSE
					BEGIN
						SELECT @tel = 'E_' + @tel
					END
				END
				ELSE
				BEGIN
					SELECT @tel = 'E_' + @tel
				END
			END
		END
		ELSE
		BEGIN
			IF len(@tel) > 0
			BEGIN
				SELECT @tel = 'E_' + @tel
			END
		END

		RETURN @tel
	END --Termina Venezuela

	IF @pais = 7
	BEGIN -- Empieza UK
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = 'E'
		BEGIN -- regresa error por longitud
			RETURN @tel
		END

		SELECT @lon = len(@tel)

		--numeros no geograficos
		IF (left(@tel, 2) IN ('03', '07', '09') AND @lon <> 11) OR (left(@tel, 3) IN ('055', '056', '070') AND @lon <> 11)
		BEGIN
			RETURN 'E_' + @tel --error por longitud con lada correcta
		END
		ELSE
		BEGIN
			IF left(@tel, 7) IN ('0845464') OR left(@tel, 5) = '07624' OR left(@tel, 4) IN ('0500', '0800') OR left(@tel, 3) IN ('055', '056', '070', '76') OR left(@tel, 2) IN ('03', '07', '08', '09')
			BEGIN
				RETURN @tel;--longitud correcta y numero no geografico
			END
		END

		--numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
		IF (left(@tel, 7) IN ('0159575', '0159576')) OR (left(@tel, 5) IN ('02820', '02821', '02825', '02827', '02828', '02829', '02830', '02837', '02838', '02840', '02841', '02842', '02843', '02844', '02866', '02867', '02868', '02870', '02871', '02877', '02879', '02880', '02881', '02882', '02885', '02886', '02887', '02889', '02890', '02891', '02892', '02893', '02894', '02895', '02897') AND @lon = 11) OR --claves 2xxx tienen formato 4-6
			(left(@tel, 4) IN ('0113', '0114', '0115', '0116', '0117', '0118', '0121', '0131', '0141', '0151', '0161', '0238', '0239') AND @lon = 11) OR --3-digit area codes have 7-digit subscribers.
			(left(@tel, 3) IN ('020', '024', '029') AND @lon = 11)
		BEGIN --2-digit area codes have 8-digit subscribers.
			RETURN @tel;
		END

		--numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
		IF left(@tel, 2) = '01'
		BEGIN
			SELECT @ld = count(cld)
			FROM seriesuk
			WHERE cld = substring(@tel, 2, 4) --mayor numero de ladas (va primero por ser mas probable)

			IF @ld > 0
			BEGIN
				RETURN @tel;
			END
			ELSE
			BEGIN
				SELECT @ld = count(cld)
				FROM seriesuk
				WHERE cld = substring(@tel, 2, 5) --ladas restantes

				IF @ld > 0
				BEGIN
					RETURN @tel;
				END
			END
		END --si no encontro ni error ni coincidencia entonces esta mal

		RETURN 'E_' + @tel
	END --Termina UK

	IF @pais = 8
	BEGIN --Empieza Arabia Saudita
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		SELECT @lon = len(@tel)

		IF @lon = 7
		BEGIN
			SET @tel = '0' + @cldLocal + @tel
		END

		SELECT @lon = len(@tel)

		IF @lon = 9
		BEGIN
			IF EXISTS (
					SELECT regiones
					FROM seriesSA
					WHERE right(@tel, 4) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 3, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 4 AND left(@tel, 2) = cld
					)
			BEGIN
				IF (substring(@tel, 2, 1) = @cldLocal)
				BEGIN
					RETURN right(@tel, 7)
				END
				ELSE
				BEGIN
					RETURN @tel
				END
			END
			ELSE
			BEGIN
				RETURN 'E_' + @tel
			END
		END

		IF @lon = 10
		BEGIN
			IF EXISTS (
					SELECT regiones
					FROM seriesSA
					WHERE right(@tel, 4) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 4, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 4 AND left(@tel, 3) = cld
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN 'E_' + @tel
			END
		END

		IF @lon = 11
		BEGIN
			IF EXISTS (
					SELECT regiones, *
					FROM seriesSA
					WHERE right(@tel, 6) BETWEEN [numeracion inicial] AND [numeracion final] AND substring(@tel, 3, 3) BETWEEN [serie inicio] AND [serie fin] AND len([numeracion inicial]) = 6 AND left(@tel, 2) = cld
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN 'E_' + @tel
			END
		END
	END --Termina Arabia Saudita

	IF @pais = 9
	BEGIN --Empieza Australia
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		SELECT @lon = len(@tel)

		IF left(@tel, 1) <> 'E'
		BEGIN
			IF EXISTS (
					SELECT Regiones
					FROM SeriesAU
					WHERE convert(INT, LD) = convert(INT, substring(@tel, 1, 2)) AND convert(INT, AreaCode) = convert(INT, substring(@tel, 3, 2)) AND convert(INT, substring(@tel, 5, 6)) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
					)
			BEGIN
				RETURN @tel
			END
			ELSE
			BEGIN
				RETURN 'E_' + @tel
			END
		END
		ELSE
		BEGIN
			RETURN @tel
		END
	END --Termina Australia

	IF @pais = 10
	BEGIN -- Inicia Brasil
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		SELECT @lon = len(@tel)

		IF left(@tel, 1) <> 'E'
		BEGIN
			IF @lon IN (8, 9)
			BEGIN --numero local
				IF EXISTS (
						SELECT Regiones
						FROM seriesBR
						WHERE convert(INT, AreaCode) = convert(INT, @cldLocal) AND convert(INT, @tel) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					RETURN 'E_' + @tel
				END
			END

			IF @lon IN (10, 11)
			BEGIN --numero nacional
				IF EXISTS (
						SELECT Regiones
						FROM seriesBR
						WHERE convert(INT, AreaCode) = convert(INT, left(@tel, 2)) AND convert(INT, right(@tel, @lon - 2)) BETWEEN convert(INT, SerieInicio) AND convert(INT, SerieFin)
						)
				BEGIN
					RETURN @tel
				END
				ELSE
				BEGIN
					RETURN 'E_' + @tel
				END
			END
		END
		ELSE
		BEGIN
			RETURN @tel
		END
	END -- Termina Brasil

	IF @pais = 11
	BEGIN -- Inicia Guatemala
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> 'E'
		BEGIN
			IF EXISTS (
					SELECT zonaGeografica
					FROM seriesGT(NOLOCK)
					WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
					)
				RETURN @tel
			ELSE
				RETURN 'E_' + @tel
		END
		ELSE
			RETURN @tel
	END -- Termina Guatemala

	IF @pais = 12
	BEGIN -- Inicia Costa Rica
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> 'E'
		BEGIN
			IF len(@tel) = 8
				IF EXISTS (
						SELECT zonaGeografica
						FROM seriesCR(NOLOCK)
						WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
						)
					RETURN @tel
				ELSE
					RETURN 'E_' + @tel
			ELSE IF len(@tel) = 10
			BEGIN
				IF EXISTS (
						SELECT zonaGeografica
						FROM seriesCR(NOLOCK)
						WHERE indicativoDestino = substring(@tel, 1, 3) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
						)
					RETURN @tel
				ELSE
					RETURN 'E_' + @tel
			END
			ELSE IF charindex(substring(@tel, 1, 2), '00,08') <= 0
				RETURN 'E_' + @tel
			ELSE
				RETURN @tel
		END
	END -- Termina Costa Rica

	IF @pais = 13
	BEGIN -- Inicia Salvador
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> 'E'
		BEGIN
			IF len(@tel) = 8
				IF EXISTS (
						SELECT zonaGeografica
						FROM seriesSV(NOLOCK)
						WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
						)
					RETURN @tel
				ELSE
					RETURN 'E_' + @tel
			ELSE IF charindex(substring(@tel, 1, 2), '00') <= 0
				RETURN 'E_' + @tel
			ELSE
				RETURN @tel
		END
	END -- Termina Salvador

	IF @pais = 14
	BEGIN -- Inicia Spain
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> 'E'
		BEGIN
			IF len(@tel) = 9
				IF EXISTS (
						SELECT provincia
						FROM seriesEsp(NOLOCK)
						WHERE indicativo = substring(@tel, 1, 1) AND right(@tel, 8) BETWEEN numInicial AND numFinal
						)
					RETURN @tel
				ELSE
					RETURN 'E_' + @tel
			ELSE IF charindex(substring(@tel, 1, 2), '00') <= 0
				RETURN 'E_' + @tel
			ELSE
				RETURN @tel
		END
	END -- Termina Espa?a

	IF @pais = 15
	BEGIN --Inicia Peru
		SELECT @tel = dbo.Completa(@tel, @pais, @cldLocal)

		SELECT @lon = len(@tel)

		IF @lon BETWEEN 6 AND 7
		BEGIN
			SET @tel = @cldLocal + @tel
		END

		SELECT @tel = right(@tel, 9)

		SELECT @lon = len(@tel)

		IF left(@tel, 1) <> 'E'
		BEGIN
			IF @lon = 9
			BEGIN
				IF EXISTS (
						SELECT zonaGeografica
						FROM seriesPE(NOLOCK)
						WHERE left(@tel, 1) = 9 OR substring(@tel, 2, 1) = 1 AND areaNumeracion = 1 AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal OR substring(@tel, 2, 1) <> 1 AND left(@tel, 2) = areaNumeracion AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
						)
					RETURN @tel
				ELSE
					RETURN 'E_' + @tel
			END
		END
	END --Termina Peru

	IF @pais = 16
	BEGIN --Panama
		SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

		IF left(@tel, 1) <> 'E'
		BEGIN
			IF len(@tel) = 7
			BEGIN -- Local
				IF (substring(@tel, 1, 1) != '6')
				BEGIN
					IF EXISTS (
							SELECT zonaGeografica
							FROM seriesPa(NOLOCK)
							WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
							)
						RETURN @tel
					ELSE
						RETURN 'E_' + @tel
				END
				ELSE
					RETURN 'E_' + @tel
			END

			IF len(@tel) = 8
			BEGIN --Celular
				IF (substring(@tel, 1, 1) = '6')
				BEGIN
					IF EXISTS (
							SELECT zonaGeografica
							FROM seriesPa(NOLOCK)
							WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
							)
						RETURN @tel
					ELSE
						RETURN 'E_' + @tel
				END
				ELSE
					RETURN 'E_' + @tel
			END
			ELSE
			BEGIN
				IF charindex(substring(@tel, 1, 2), '00') <= 0
					RETURN 'E_' + @tel
				ELSE
					RETURN @tel
			END
		END
	END

	RETURN @tel
END