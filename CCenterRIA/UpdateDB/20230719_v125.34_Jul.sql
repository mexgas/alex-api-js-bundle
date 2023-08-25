/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCenterRia
Required version: 125.33

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 34
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	---------------------------------------BEGIN Paco Cota DEV1-306 Carga solo celulares (para campañas de SMS)---------------------------------------------------------

SET @process = 'DEV1-306 Carga solo celulares (para SMS) ALTER dbo.Verifica2'
SET @sql = '
		ALTER FUNCTION [dbo].[Verifica2] (@tel VARCHAR(32), @pais TINYINT = 0, @cldLocal VARCHAR(7) = '''', @isForSMS bit = 0)
		RETURNS VARCHAR(32)
		AS
		BEGIN
			DECLARE @ld VARCHAR(7)
			DECLARE @lon TINYINT
			DECLARE @result TINYINT
			DECLARE @mod VARCHAR(10)
			DECLARE @tipo VARCHAR(10)
			DECLARE @Cadena VARCHAR(32)
			DECLARE @isLocal BIT
			declare @serie varchar(10)

			IF (@pais = 0 AND @cldLocal = '''')
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
				SELECT @lon = len(@tel), @mod = ''''

				IF @lon < 10
				BEGIN
					RETURN ''E_'' + @tel
				END

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
						RETURN ''E_'' + @tel

					SELECT TOP 1 @mod = modalidad, @tipo = [TIPO DE RED]
					FROM series NOLOCK
					WHERE cld = @ld AND serie = @serie AND right(@tel, 4) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

					IF @mod NOT IN (''FIJO'', ''MPP'', ''CPP'')
					BEGIN
						RETURN ''E_'' + @tel
					END

					IF @isForSMS = 1 AND @tipo <> ''MOVIL''
					BEGIN
						RETURN ''E_'' + @tel
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
						SELECT @tel = CASE WHEN @mod IN (''FIJO'', ''MPP'') THEN CASE WHEN @isLocal = 1 THEN @tel ELSE ''01'' + @tel END WHEN @mod = ''CPP'' THEN --Local y LD
										CASE WHEN @isLocal = 1 THEN ''044'' + @tel ELSE ''045'' + @tel END END --Celular
					END
					ELSE
					BEGIN
						--Number local 7 o 8 digit
						--Number LD 12 digit
						--Number Cell 13 digit
						SELECT @tel = CASE WHEN @mod IN (''FIJO'', ''MPP'') THEN CASE WHEN @isLocal = 1 THEN right(@tel, 10 - len(@ld)) ELSE ''01'' + @tel END WHEN @mod = ''CPP'' THEN --Local y LD
										CASE WHEN @isLocal = 1 THEN ''044'' + @tel ELSE ''045'' + @tel END END --Celular
					END
				END
				ELSE IF @lon > 0
				BEGIN
					SET @tel = ''E_'' + @tel
				END

				RETURN @tel
			END --Termina Mexico
					--------------------------- Empieza Argentina ---------------------------
			ELSE IF @pais = 2
			BEGIN
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) = ''E''
				BEGIN
					RETURN @tel
				END

				SELECT @lon = len(@tel)

				IF @lon IN (6, 7, 8) AND left(@tel, 2) <> ''15''
				BEGIN
					SET @tel = @cldLocal + @tel
				END

				IF @lon IN (8, 9, 10) AND left(@tel, 2) = ''15''
				BEGIN
					SET @tel = @cldLocal + substring(@tel, 3, @lon - 2)
				END

				--Buscamos el 15
				IF @lon = 13
				BEGIN
					DECLARE @index AS INT

					SELECT @index = charindex(''15'', @tel)

					--El unico caso en el que la lada tiene un 15 es con lada 3715
					IF @index < 2
					BEGIN
						SELECT @tel = ''E_'' + @tel

						RETURN @tel
					END
					ELSE
					BEGIN
						IF substring(@tel, @index - 2, 4) = ''3715''
						BEGIN
							SELECT @ld = ''3715''

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

					BEGIN
						-- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
						DECLARE @contLD AS INT
						DECLARE @cont AS INT

						SET @contLD = 4

						BuscaLada:

						IF isnull(@ld, '''') = '''' AND @contLD >= 2
						BEGIN
							SELECT @ld = cld
							FROM seriesArg
							WHERE cld = left(@tel, @contLD)

							IF isnull(@ld, '''') = ''''
							BEGIN
								SET @contLD = @contLD - 1

								GOTO BuscaLada
							END
						END
						ELSE
						BEGIN
							IF isnull(@ld, '''') = ''''
							BEGIN
								SELECT @tel = ''E_'' + @tel
							END
						END
					END

					-- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
					BEGIN
						IF len(@ld) = 2
						BEGIN
							SET @cont = 5

							buscaSerie2:

							IF isnull(@serie, '''') = '''' AND @cont >= 4
							BEGIN
								SELECT @serie = serie
								FROM seriesArg
								WHERE cld = @ld AND serie = substring(@tel, 3, @cont)

								IF isnull(@serie, '''') = ''''
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

								IF isnull(@serie, '''') = '''' AND @cont >= 3
								BEGIN
									SELECT @serie = serie
									FROM seriesArg
									WHERE cld = @ld AND serie = substring(@tel, 4, @cont)

									IF isnull(@serie, '''') = ''''
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

									IF isnull(@serie, '''') = '''' AND @cont >= 2
									BEGIN
										SELECT @serie = serie
										FROM seriesArg
										WHERE cld = @ld AND serie = substring(@tel, 5, @cont)

										IF isnull(@serie, '''') = ''''
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
					IF isNull(@serie, '''') = '''' AND @contLD > 1
					BEGIN
						SET @contLD = len(@ld) - 1
						SET @ld = NULL

						GOTO BuscaLada
					END

					SELECT @tel = CASE WHEN @mod IN (''BASICA'', ''MPP'') THEN CASE WHEN @ld = @cldLocal THEN right(@tel, 10 - len(@ld)) ELSE ''0'' + @tel END WHEN @mod = ''CPP'' THEN CASE WHEN @ld = @cldLocal THEN ''15'' + right(@tel, 10 - len(@ld)) ELSE ''0'' + @ld + ''15'' + right(@tel, 10 - len(@ld)) END ELSE ''E_'' + @tel END
				END
				ELSE
				BEGIN
					IF len(@tel) > 0
					BEGIN
						SELECT @tel = ''E_'' + @tel
					END
				END

				RETURN @tel
			END ------------------ Termina Argentina ------------------
			ELSE IF @pais = 3
			BEGIN --Empieza Colombia
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) = ''E''
				BEGIN
					RETURN @tel
				END

				IF len(@tel) NOT IN (7, 8, 10, 11)
				BEGIN
					RETURN ''E_'' + @tel
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
						RETURN ''E_'' + @tel
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
						RETURN ''E_'' + @tel
					END
				END

				IF len(@tel) = 10
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesCol
							WHERE serie = substring(@tel, 5, 3) AND (left(@tel, 3) + ''-'' + substring(@tel, 4, 1)) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END

				IF len(@tel) = 11
				BEGIN
					IF EXISTS (
							SELECT serie
							FROM seriesCol
							WHERE serie = substring(@tel, 6, 3) AND (substring(@tel, 2, 3) + ''-'' + substring(@tel, 5, 1)) = region AND (right(@tel, 3) BETWEEN numeracionInicial AND numeracionFinal)
							)
					BEGIN
						RETURN @tel
					END
					ELSE
					BEGIN
						RETURN ''E_'' + @tel
					END
				END
			END --Termina Colombia

			-- Empieza Chile
			IF @pais = 5
			BEGIN
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) = ''E''
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
						RETURN ''E_'' + @tel
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
							IF left(@tel, 3) = ''200'' AND EXISTS (
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
					IF left(@tel, 1) = ''2''
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
								RETURN ''E_'' + @tel
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
					IF left(@tel, 2) = ''09''
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
							RETURN ''E_'' + @tel
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

					IF @mod = ''CPP''
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
								SELECT @tel = ''0'' + @tel
							END
						END
						ELSE
						BEGIN
							SELECT @tel = ''E_'' + @tel
						END
					END
					ELSE
					BEGIN
						IF @mod = ''FIJO''
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
									SELECT @tel = ''0'' + @tel
								END
							END
							ELSE
							BEGIN
								SELECT @tel = ''E_'' + @tel
							END
						END
						ELSE
						BEGIN
							SELECT @tel = ''E_'' + @tel
						END
					END
				END
				ELSE
				BEGIN
					IF len(@tel) > 0
					BEGIN
						SELECT @tel = ''E_'' + @tel
					END
				END

				RETURN @tel
			END --Termina Venezuela

			IF @pais = 7
			BEGIN -- Empieza UK
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) = ''E''
				BEGIN -- regresa error por longitud
					RETURN @tel
				END

				SELECT @lon = len(@tel)

				--numeros no geograficos
				IF (left(@tel, 2) IN (''03'', ''07'', ''09'') AND @lon <> 11) OR (left(@tel, 3) IN (''055'', ''056'', ''070'') AND @lon <> 11)
				BEGIN
					RETURN ''E_'' + @tel --error por longitud con lada correcta
				END
				ELSE
				BEGIN
					IF left(@tel, 7) IN (''0845464'') OR left(@tel, 5) = ''07624'' OR left(@tel, 4) IN (''0500'', ''0800'') OR left(@tel, 3) IN (''055'', ''056'', ''070'', ''76'') OR left(@tel, 2) IN (''03'', ''07'', ''08'', ''09'')
					BEGIN
						RETURN @tel;--longitud correcta y numero no geografico
					END
				END

				--numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
				IF (left(@tel, 7) IN (''0159575'', ''0159576'')) OR (left(@tel, 5) IN (''02820'', ''02821'', ''02825'', ''02827'', ''02828'', ''02829'', ''02830'', ''02837'', ''02838'', ''02840'', ''02841'', ''02842'', ''02843'', ''02844'', ''02866'', ''02867'', ''02868'', ''02870'', ''02871'', ''02877'', ''02879'', ''02880'', ''02881'', ''02882'', ''02885'', ''02886'', ''02887'', ''02889'', ''02890'', ''02891'', ''02892'', ''02893'', ''02894'', ''02895'', ''02897'') AND @lon = 11) OR --claves 2xxx tienen formato 4-6
					(left(@tel, 4) IN (''0113'', ''0114'', ''0115'', ''0116'', ''0117'', ''0118'', ''0121'', ''0131'', ''0141'', ''0151'', ''0161'', ''0238'', ''0239'') AND @lon = 11) OR --3-digit area codes have 7-digit subscribers.
					(left(@tel, 3) IN (''020'', ''024'', ''029'') AND @lon = 11)
				BEGIN --2-digit area codes have 8-digit subscribers.
					RETURN @tel;
				END

				--numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
				IF left(@tel, 2) = ''01''
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

				RETURN ''E_'' + @tel
			END --Termina UK

			IF @pais = 8
			BEGIN --Empieza Arabia Saudita
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				SELECT @lon = len(@tel)

				IF @lon = 7
				BEGIN
					SET @tel = ''0'' + @cldLocal + @tel
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
						RETURN ''E_'' + @tel
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
						RETURN ''E_'' + @tel
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
						RETURN ''E_'' + @tel
					END
				END
			END --Termina Arabia Saudita

			IF @pais = 9
			BEGIN --Empieza Australia
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				SELECT @lon = len(@tel)

				IF left(@tel, 1) <> ''E''
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
						RETURN ''E_'' + @tel
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

				IF left(@tel, 1) <> ''E''
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
							RETURN ''E_'' + @tel
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
							RETURN ''E_'' + @tel
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

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF EXISTS (
							SELECT zonaGeografica
							FROM seriesGT(NOLOCK)
							WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
							)
						RETURN @tel
					ELSE
						RETURN ''E_'' + @tel
				END
				ELSE
					RETURN @tel
			END -- Termina Guatemala

			IF @pais = 12
			BEGIN -- Inicia Costa Rica
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF len(@tel) = 8
						IF EXISTS (
								SELECT zonaGeografica
								FROM seriesCR(NOLOCK)
								WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
								)
							RETURN @tel
						ELSE
							RETURN ''E_'' + @tel
					ELSE IF len(@tel) = 10
					BEGIN
						IF EXISTS (
								SELECT zonaGeografica
								FROM seriesCR(NOLOCK)
								WHERE indicativoDestino = substring(@tel, 1, 3) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
								)
							RETURN @tel
						ELSE
							RETURN ''E_'' + @tel
					END
					ELSE IF charindex(substring(@tel, 1, 2), ''00,08'') <= 0
						RETURN ''E_'' + @tel
					ELSE
						RETURN @tel
				END
			END -- Termina Costa Rica

			IF @pais = 13
			BEGIN -- Inicia Salvador
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF len(@tel) = 8
						IF EXISTS (
								SELECT zonaGeografica
								FROM seriesSV(NOLOCK)
								WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
								)
							RETURN @tel
						ELSE
							RETURN ''E_'' + @tel
					ELSE IF charindex(substring(@tel, 1, 2), ''00'') <= 0
						RETURN ''E_'' + @tel
					ELSE
						RETURN @tel
				END
			END -- Termina Salvador

			IF @pais = 14
			BEGIN -- Inicia Spain
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF len(@tel) = 9
						IF EXISTS (
								SELECT provincia
								FROM seriesEsp(NOLOCK)
								WHERE indicativo = substring(@tel, 1, 1) AND right(@tel, 8) BETWEEN numInicial AND numFinal
								)
							RETURN @tel
						ELSE
							RETURN ''E_'' + @tel
					ELSE IF charindex(substring(@tel, 1, 2), ''00'') <= 0
						RETURN ''E_'' + @tel
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

				IF left(@tel, 1) <> ''E''
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
							RETURN ''E_'' + @tel
					END
				END
			END --Termina Peru

			IF @pais = 16
			BEGIN --Panama
				SELECT @tel = dbo.completa(@tel, @pais, @cldLocal)

				IF left(@tel, 1) <> ''E''
				BEGIN
					IF len(@tel) = 7
					BEGIN -- Local
						IF (substring(@tel, 1, 1) != ''6'')
						BEGIN
							IF EXISTS (
									SELECT zonaGeografica
									FROM seriesPa(NOLOCK)
									WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
									)
								RETURN @tel
							ELSE
								RETURN ''E_'' + @tel
						END
						ELSE
							RETURN ''E_'' + @tel
					END

					IF len(@tel) = 8
					BEGIN --Celular
						IF (substring(@tel, 1, 1) = ''6'')
						BEGIN
							IF EXISTS (
									SELECT zonaGeografica
									FROM seriesPa(NOLOCK)
									WHERE indicativoDestino = substring(@tel, 1, 1) AND right(@tel, 7) BETWEEN rangoInicio AND rangoFinal
									)
								RETURN @tel
							ELSE
								RETURN ''E_'' + @tel
						END
						ELSE
							RETURN ''E_'' + @tel
					END
					ELSE
					BEGIN
						IF charindex(substring(@tel, 1, 2), ''00'') <= 0
							RETURN ''E_'' + @tel
						ELSE
							RETURN @tel
					END
				END
			END

			RETURN @tel
		END'
	EXEC(@sql)



SET @process = 'DEV1-306 Carga solo celulares (para SMS) ALTER dbo.Verifica'
SET @sql = '
ALTER FUNCTION [dbo].[Verifica](@tel varchar(32))
RETURNS varchar(32) AS
BEGIN
	
	declare @cldLocal varchar(7)
	declare @pais tinyint

	select @pais = valor from ccSettings with(nolock) where setting_id = 104
	select @cldLocal = valor from ccSettings with(nolock) where setting_id = 17

	return dbo.Verifica2(@tel,@pais,@cldLocal,DEFAULT)

END'
EXEC(@sql)

SET @process = 'DEV1-306 Carga solo celulares (para SMS) validacion ccsp_Limpia'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_Limpia'')
	BEGIN
	    DROP PROCEDURE ccsp_Limpia;
	END'
EXEC(@sql)

SET @process = 'DEV1-306 Carga solo celulares (para SMS) CREATE ccsp_Limpia, para agregar el nuevo parametro de dbo.Verifica2'
SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_Limpia] @tel VARCHAR(50), @Camp INT = 0, @calKey VARCHAR(20) = ''''
AS
SET NOCOUNT ON

DECLARE @lon TINYINT, @cldLocal VARCHAR(7), @pais VARCHAR(3), @extLen SMALLINT, @specialDialPlan SMALLINT, @validateTel SMALLINT, @ld VARCHAR(7)
DECLARE @checkLd_In_ANILst SMALLINT = 0
/***
 4  as res lista Negra
 2 as res Digitos incorrectos Prefijo Marcacion 01,044,045,001
 3 as res Number notExists
 1 as res Longitud invalida
 0 as res Numero correcto
 
***/
SELECT @tel = dbo.limpia(@tel)

SELECT @lon = len(@tel)

SELECT @pais = valor
FROM ccSettings WITH (NOLOCK)
WHERE setting_id = 104

SELECT @cldLocal = valor
FROM ccSettings WITH (NOLOCK)
WHERE setting_id = 17

SELECT @extLen = valor
FROM ccsettings WITH (NOLOCK)
WHERE setting_id = 108

SELECT @validateTel = valor
FROM ccsettings WITH (NOLOCK)
WHERE setting_id = 206

SELECT @checkLd_In_ANILst = valor FROM ccsettings WITH (NOLOCK) WHERE setting_id = 213


IF @lon > 1
BEGIN

	IF @validateTel = 2
		BEGIN --Setting 206 only validates blacklist
		
			IF (SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)) = 1
			BEGIN
				SELECT 4 AS res, @tel AS tel --blackList
				RETURN (0)
			END
			SELECT 0 AS res, @tel AS tel

			RETURN (0)
	
	END
	IF @validateTel = 1
	BEGIN --Setting 206 para no validar longitud ni listas negras
		SELECT 0 AS res, @tel AS tel

		RETURN (0)
	END

	IF @extLen = @lon
	BEGIN -- Setting 108 validar el tamaño longitud del telefono
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList

			RETURN (0)
		END

		SELECT 0 AS res, @tel AS tel -- Extension

		RETURN (0)
	END
END

DECLARE @telTemp AS VARCHAR(15)

SELECT @telTemp = @tel

IF @pais = 1
BEGIN ---Mexico
	IF @lon = 3 AND @tel = ''911''
	BEGIN
		SELECT 4 AS res, @tel AS tel --Lista Negra

		RETURN (0)
	END

	IF (@lon < 10)
	BEGIN
		SELECT 1 AS res, @tel AS tel --Longitud invalida

		RETURN (0)
	END

	IF @lon = 12 AND left(@tel, 2) <> ''01'' OR @lon = 13 AND left(@tel, 3) NOT IN (''044'', ''045'') AND left(@tel, 3) <> ''001''
	BEGIN
		SELECT 2 AS res, @tel AS tel --Digitos incorrectos

		RETURN (0)
	END

	IF left(@tel, 3) = ''001''
	BEGIN
		SELECT 0 AS res, @tel AS tel

		RETURN (0)
	END

	SELECT @tel = right(@tel, 10)

	IF (
			SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
			) = 1
	BEGIN
		SELECT 4 AS res, @tel AS tel --blackList

		RETURN (0)
	END
	
	If (@Camp > 0 AND @checkLd_In_ANILst = 1)
	BEGIN
		If(SELECT len(ani) FROM ccCamps WHERE cam_id = @Camp) > 0  --Permitir todos los telefonos a 10 digitos cuando existe un ani configurado en la campana.	
		BEGIN
			SELECT 0 AS res, @tel AS tel	
			RETURN (0)
		END

		IF exists (SELECT TOP 1 area FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
				  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
				  WHERE cam_id = @Camp and telAni <> '''' and area = left(@tel, 3))
		BEGIN
			SELECT 0 AS res, @tel AS tel
			RETURN (0)
		END
		ELSE IF exists (SELECT TOP 1 area FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
				  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
				  WHERE cam_id = @Camp and telAni <> '''' and area = left(@tel, 2))
		BEGIN
			SELECT 0 AS res, @tel AS tel
			RETURN (0)
		END
	END


	SELECT @tel = dbo.Verifica2(@tel, 1, @cldLocal, DEFAULT)

	IF LEFT(@tel, 1) = ''E''
	BEGIN
		SELECT 3 AS res, @telTemp AS tel --No encontrado

		RETURN (0)
	END

	SELECT 0 AS res, @tel AS tel

	RETURN (0)
END
ELSE IF @pais = 2
BEGIN --Argentina 
	SET @tel = dbo.completa(@tel, @pais, @cldLocal)

	IF left(@tel, 1) = ''E''
	BEGIN
		SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

		RETURN (0)
	END

	SELECT @tel = dbo.fnClearPhoneArg(@tel)

	IF (len(@tel) = 10 OR len(@cldLocal + @tel) = 10) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos      
	END

	RETURN (0)
END
ELSE IF @pais = 3
BEGIN --Colombia  
	IF @lon < 7 OR @lon = 9 OR (@lon = 10 AND left(@telTemp, 1) <> ''3'') OR (@lon = 11 AND left(@telTemp, 2) <> ''03'')
	BEGIN
		SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

		RETURN (0)
	END

	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (8, 10)) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 4
BEGIN --USA 
	EXEC ccsp_LimpiaUsa @tel, @Camp, @calKey

	RETURN (0)
END
ELSE IF @pais = 5
BEGIN --Chile  
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF len(@tel) IN (8, 9) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 6
BEGIN --Venezuela    
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF len(@tel) = 10 AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 7
BEGIN --Reino Unido
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (9, 10)) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 8
BEGIN --Arabia saudita   
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (9, 10, 11))
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais IN (9, 10, 11, 12, 13, 14, 15, 16)
BEGIN --9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador, 14:España 15:Peru, 16: Panama 
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF left(@tel, 1) = ''E''
	BEGIN
		SELECT 1 AS res, @telTemp --Longitud Invalida   
	END
	ELSE IF (
			SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
			) = 1
	BEGIN
		SELECT 4 AS res, @tel AS tel --blackList      
	END
	ELSE
	BEGIN
		SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT)

		IF left(@tel, 1) = ''E''
		BEGIN
			SELECT 2 AS res, @telTemp --Digitos Incorrectos ??? debe ser numero no existe
		END

		SELECT 0 AS res, @tel AS tel
	END

	RETURN (0)
END
'
EXEC(@sql)
	---------------------------------------END Paco Cota -----------------------------------------------------------

	-------------------------------------------- BEGIN IVAN MARTIN Errores de WhatsApp Version 2023.425.125.8------------------------------
	SET @process = 'Creacion de nueva columna en ccWhatsAppConversations para saber si el agente se deslogeo'
	SET @sql = 'if not exists (select * from sys.columns where name = N''IsAgentLoggingOut'' and Object_ID = Object_ID(N''ccWhatsAppConversations''))
				begin
				    ALTER TABLE ccWhatsAppConversations ADD IsAgentLoggingOut BIT NOT NULL DEFAULT(0)
				end'
	EXEC(@sql)

	SET @process = 'Se agrega el action 16 en ccsp_ConversationWASave para actualizar el valor de la nueva columna. Lineas (424-432)';
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
                                        , @conversationId     INT         = 0
                                        , @inboundId          SMALLINT    = NULL
                                        , @phoneACD           VARCHAR(50) = NULL
                                        , @clientId           VARCHAR(25) = NULL
                                        , @conversationStatus SMALLINT    = 0
                                        , @tChatting          FLOAT    = 0
                                        , @tWrapUp            SMALLINT    = 0
                                        , @finishedBy         TINYINT     = 0
                                        , @onQueue            BIT         = NULL
                                        , @tQueue             SMALLINT    = 0
                                        , @tTimeout           INT         = 0
                                        , @disposition        SMALLINT    = 0
                                        , @subDisposition     SMALLINT    = 0
                                        , @agentId            INT         = 0
                                        --VAR MESSAGES
                                        , @messageId          VARCHAR(50) = NULL
                                        , @messageIdUi        INT         = NULL
                                        , @clientNum          VARCHAR(15) = NULL
                                        , @vonageNum          VARCHAR(15) = NULL
                                        , @typeMessage        VARCHAR(25) = ''''
                                        , @content            NVARCHAR(MAX)= NULL
                                        , @timeStampMessage   DATETIME    = NULL
                                        , @timeStampMessageUTC DATETIME   = NULL
                                        , @originType         VARCHAR(15) = NULL
                                        , @currency           VARCHAR(10) = ''-''
                                        , @price              VARCHAR(10) = ''0.00''
                                        , @messageStatus      VARCHAR(15) = ''N/A''
                                        , @listConversationsIds   VARCHAR(MAX) = NULL
										, @IsAgentLoggingOut  BIT = 0
					AS
					BEGIN
					    DECLARE @isEndConversation BIT;
					    DECLARE @meanContactTypeId SMALLINT;
					    DECLARE @conversationIdNew INT;
					    SET @meanContactTypeId = 1;
					    SET NOCOUNT ON;

					    IF @action = 1
					    BEGIN --new Conversation
					        IF NOT EXISTS
					                        (SELECT A.conversationId conversationId FROM ccWhatsAppConversations A
					                        WHERE A.conversationId = @conversationId
					                        )
					        BEGIN
					            INSERT INTO [ccWhatsAppConversations]
					            (inboundId
					            , phoneACD
					            , clientId
					            , conversationStatus
					            , tChatting
					            , tWrapUp
					            , finishedBy
					            , onQueue
					            , tQueue
					            , tTimeout
					            , disposition
					            , subDisposition
					            , agentId
					            )
					            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);

					            IF NOT EXISTS (SELECT WhatsAppSpamId FROM ccWhatsAppSpam WHERE NumberClient = @clientId and InboundId = @inboundId) BEGIN
					                SELECT @conversationId = SCOPE_IDENTITY();
					                SELECT @conversationId AS ConversationId;
					            END
					            ELSE BEGIN

					                declare @conversationIdTemporal     INT;
					                SELECT @conversationIdTemporal = SCOPE_IDENTITY();
					                EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationIdTemporal, @conversationStatus = 13
					                SELECT 0 AS ConversationId;
					            END;

					            --Save new request
					            IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @inboundId)
					                BEGIN
					                    INSERT INTO ccWAOperatingSummary (InboundId, Request) VALUES (@inboundId, 1);
					                END
					            ELSE
					                BEGIN
					                    UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId
					                END



					            RETURN(0);
					        END
					        ELSE
					        BEGIN
					            DECLARE @conversationStatusTemp INT = @conversationStatus;
					            IF @conversationStatus in(17,18) BEGIN
					                SET @conversationStatusTemp = 1
					            END
					                INSERT INTO [ccWhatsAppConversations]
					            (inboundId
					            , phoneACD
					            , clientId
					            , conversationStatus
					            , tChatting
					            , tWrapUp
					            , finishedBy
					            , onQueue
					            , tQueue
					            , tTimeout
					            , disposition
					            , subDisposition
					            , agentId
					            )
					            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
					            SELECT @conversationIdNew = SCOPE_IDENTITY();

					            INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore
					                                                                , conversationIdAfter)
					                VALUES (@conversationId, @conversationIdNew);
					            --Save new request by reassign
					            UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId

					        EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

					        SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship where conversationIdBefore = @conversationId;
					        RETURN(0);
					    END;
					END;

					IF @action = 2
					BEGIN --save conversation Times
					    DECLARE @conversationIdTemp INT;
					    DECLARE @TablaTemp TABLE (conversationId INT, status bit);

					    IF @listConversationsIds IS NOT NULL begin
					        INSERT INTO @TablaTemp
					        SELECT value,0
					        FROM fn_RIASplitDelimited(@listConversationsIds, '','')
					        where value is not null and value<>''''
					    end
					    else begin
					        INSERT INTO @TablaTemp values(@conversationId,0)
					    end

					    UPDATE ccWhatsAppConversations
					    SET
					    conversationStatus = @conversationStatus
					    , finishedBy = case when @conversationStatus = 10 then 2
					        when @conversationStatus = 17 then 2
					        when @conversationStatus = 18 then 2
					        else 1 end
					    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
					    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
					    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
					    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

					        WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
					    BEGIN
					        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
					        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5

					        IF @conversationStatus in(13,10,17,18,11) BEGIN
					            DECLARE @conversationDateTemp INT;
					            select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end from ccWhatsAppConversations where conversationId = @conversationId;

					            IF @conversationStatus = 13 BEGIN
					                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
					                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
					                END
					            END
					            ELSE IF @conversationStatus in(10,17,18) BEGIN --Save conversation Ended by system
					                IF @conversationDateTemp > 0 BEGIN
					                    UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
					                END
					                ELSE BEGIN
					                        UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1) WHERE InboundId = @inboundId
					                END
					            END
					            ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
					                UPDATE ccWAOperatingSummary SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
					            END
					        END
					        update @TablaTemp set status=1 where conversationId=@conversationIdTemp
					    END

					END;

					IF @action = 3
					BEGIN --save conversation Status
					    UPDATE ccWhatsAppConversations
					            SET
					                --conversationDate = GETDATE(),
					                conversationStatus = @conversationStatus
					    WHERE conversationId = @conversationId;
					END;

					IF @action = 4 BEGIN --save messages from conversation
					    IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId)
					        AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversations A WHERE A.messageId=@messageId)
					    BEGIN
					        IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
					            (SELECT messageIdUi
					                FROM ccWAMessagesConversations
					                WHERE originType IN (''Agent'', ''Admin'')
					                AND conversationId = @conversationId)
					            BEGIN
					                UPDATE ccWhatsAppConversations
					                    SET FirstMessageAgent = @timeStampMessage
					                    WHERE conversationId = @conversationId;
					            END

					        INSERT INTO [ccWAMessagesConversations](
					                                            messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
					                                            (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
					        SELECT @messageId=SCOPE_IDENTITY()
					        SELECT @messageId as MessageId
					        RETURN (0)
					    END
					    ELSE BEGIN
					        SELECT 0 AS MessageId
					        RETURN (0)
					    END
					END;

					    IF @action = 5
					    BEGIN --save onQueue
					        UPDATE ccWhatsAppConversations
					                SET onQueue = 1,
					                conversationStatus = @conversationStatus
					        WHERE conversationId = @conversationId;
					        SELECT @inboundId = inboundId FROM ccWhatsAppConversations where conversationId=@conversationId;
					        UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue + 1) WHERE InboundId = @inboundId
					    END;

					IF @action = 6
					BEGIN --save agent, assigdate and tqueue
					    declare @agentIdTmp int
					    SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversations A where A.conversationId = @conversationId

					    IF (@agentIdTmp is null or @agentIdTmp=0)
					    BEGIN
					        UPDATE ccWhatsAppConversations
					                SET agentId = @agentId,
					                assignDate = getdate(),
					                conversationStatus = @conversationStatus
					                ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
					        WHERE conversationId = @conversationId;

					        SELECT @conversationId as conversationId
					    SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations where conversationId=@conversationId;

					    IF @onQueue = 1 BEGIN
					    UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1) WHERE InboundId = @inboundId
					    END
					    END
					END;

					    IF @action = 7
					    BEGIN --update price message
					        UPDATE ccWAMessagesConversations
					                SET price = @price,
					                    currency = @currency
					        WHERE messageId = @messageId;
					    END;

					    IF @action = 8
					    BEGIN --update status message
					        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
					            UPDATE ccWAMessagesConversations
					                    SET messageStatus = @messageStatus
					            WHERE messageId = @messageId;
					        END;
					    END;

					    IF @action = 9
					    BEGIN --Save last message time by conversationID
					        IF not exists(SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversation A WHERE A.conversationId=@conversationId) BEGIN
					            INSERT INTO ccLastMessageAgentByConversation (conversationId,timeStampLastMessageAgent) VALUES (@conversationId,getDate())
					        END;
					        ELSE
					            BEGIN
					                UPDATE ccLastMessageAgentByConversation
					                    SET timeStampLastMessageAgent = getDate()
					                WHERE conversationId = @conversationId;
					            END;
					    END;

					    IF @action = 10
					    BEGIN --drop and insert register by conversationID
					        DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
					    END;

					    IF @action = 11
					    BEGIN --register desconnection agent by conversationID
					        UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
					    END;

					    IF @action = 12
					    BEGIN --Obtain conversationsWA post MCS reset

					        declare @disconnectionIdTemp int = (select top 1 disconnectionId from ccDisconnectionMCS where timeStampConnection is null order by timeStampDisconnection desc);
					        UPDATE ccDisconnectionMCS SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

					        declare @from as datetime;-- = ''01-07-2022'';
					        select @from = convert(datetime,convert(varchar(11),getdate()))
					        set @from=DATEADD(dd,-1,@from);
					            select A.conversationId, A.inboundId, A.phoneACD, A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, A.onQueue, A.agentId, isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
					            ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
					            from ccWhatsAppConversations A
					            left join ccWAMessagesConversations B on A.conversationId = B.conversationId
					            left join ccDisconnectionMCS C on C.disconnectionId = @disconnectionIdTemp
					            --where B.conversationId is null
					            where A.requestDate >= @from 
					                and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
					            order by agentId desc, requestDate,timeStampMessage, inboundId, clientId 
					    END;
					    IF @action = 13
					    BEGIN ---Obtain agents ON STATUS READY
					        WITH agents
					        AS(
					            SELECT c.User_id, c.fecha, c.currentStatus
					            FROM ccLogAgentesDia c
					            INNER JOIN 
					            (
					                SELECT User_id, MAX(fecha) max_time
					                FROM ccLogAgentesDia
					                GROUP BY User_id
					            ) AS t
					            ON c.fecha = t.max_time
					            AND c.User_id=t.User_id AND currentStatus in (3,34)
					        ), usersByCampigns
					        AS (
					            select IdCampEsp, User_id from ccRIACampEspWG A
					            Inner join ccRIAWorkGroupUsers B
					            on A.IDWG = B.IDWG
					            Inner join contactMeanIn C
					            ON A.idCampEsp = C.inboundId
					            where A.IDWG = 1 and A.Tipo = 0
					            AND C.meanContactTypeId = 5
					        )

					        select DISTINCT A.User_Id from agents A
					        left join usersByCampigns B on A.User_Id = B.User_Id
					    END;

					    IF @action = 14
					    BEGIN --register desconnection MCS
					        INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
					    END;

						IF @action = 15
					    BEGIN --update content message
					        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
					            UPDATE ccWAMessagesConversations
					                    SET content = @content
					            WHERE messageId = @messageId;
					        END;
					    END;

						IF @action = 16
					    BEGIN --update agent status for reassigning error message
					        IF EXISTS(SELECT 0 FROM ccWhatsAppConversations WHERE conversationId = @conversationId)
							BEGIN
					            UPDATE ccWhatsAppConversations
					            SET IsAgentLoggingOut = @IsAgentLoggingOut
					            WHERE conversationId = @conversationId;
					        END;
					    END;
					END;';
		EXEC(@sql);

		SET @process = 'Se actualiza ccsp_MultimediaCommon para obtener el valor de la nueva columna. Linea (511)'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_MultimediaCommon]
				    @Option AS SMALLINT,
				    @inboundId AS SMALLINT = 0,
				    @conversationId AS INT = 0,
				    @ServiceType AS SMALLINT = 0,
				    @status as SMALLINT =0,
				    @messagesList as varchar(max) = '''',
				    @agentId AS SMALLINT = 0,
				    @CampType bit =0
				    AS
				    BEGIN
				        SET NOCOUNT ON;

				    IF @Option = 0 --  Get Campaigns Configuration List
				    BEGIN
				            SELECT CAST(campaign.cam_id AS INT) AS Id,
				                    campaign.cam_descripcion AS [Name],
				                    ISNULL(configuration.number, '''') AS Phone,
				                    CAST(graphics.graphic_id AS INT) AS GraphicId
				            FROM  ccCamps campaign 
				            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
				            INNER JOIN  ccWhatsAppNumbers configuration ON campaign.cam_id = configuration.camp_id where configuration.status != 0 AND campaign.CampType = 5
				                            
				    END

				    ELSE IF @Option = 1 --  Get Acds Configuration List
				    BEGIN
				                            
				        SELECT --inbound.chat AS ServiceType,
				        CAST(inbound.Inbound_id AS INT) AS Id,
				        inbound.descripcion AS [Name],
				        ISNULL(configuration.conexionInfo, '''') AS Phone,
				        CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
				        inbound.tNotas AS WrapUpTime,
				        CAST(graphics.graphic_id AS INT) AS GraphicId
				        FROM  ccInbound inbound
				        INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
				        INNER JOIN  contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId where inbound.Status != 0 
				                            
				    END

				    ELSE IF(@Option = 2)
				    BEGIN


				        DECLARE @OldAgentId INT = 0
				        DECLARE @OldConversationId INT = 0
				        if @campType =0 begin --ACD
				            SELECT  @OldAgentId = conv.agentId,
				                    @OldConversationId = rel.conversationIdBefore
				            FROM ccWhatsAppConversationsRelationship rel 
				            RIGHT JOIN ccWhatsAppConversations conv ON conv.conversationId = rel.conversationIdBefore
				            WHERE rel.conversationIdAfter = @conversationId

				        SELECT
				        cast(i.chat as int) AS ServiceType,
				        cast(c.conversationId as int) as ConversationID,
				        c.clientId as ClientId,
				        cm.conexionInfo as [To],
				        cast(i.Inbound_id as int) as ACDId,
				        i.descripcion as ACDName,
				        cast(g.graphic_id as int) as ACDGraphicId,
				        cast(cm.closeConversationTime as int) as [TimeOut],
				        cast(cm.answerTimeOut as int) as [TimeOutWarning],
				        i.ExitWrapUpDisposition as [ExitWrapUpDisposition],
				        i.tNotas as [WrapUpTime],
				        i.ShowCalifWnd,
				        cast(ISNULL(answerTimeoutClient, 30) AS int) as [AnswerTimeoutClient],
				        ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent),0) as [SecTimeOutLastMessageAgent],
				        isnull(permission.AllowUnassign,0) as AllowUnassign,
				        isnull(permission.AllowSpam,0) as AllowSpam,
				        ISNULL(@OldAgentId, 0) AS OldAgentId,
				        ISNULL(@OldConversationId, 0) AS OldConversationId,
				        c.agentId AS AgentId,
				        c.IsAgentLoggingOut AS IsAgentLoggingOut
				        from ccWhatsAppConversations c
				        left join ccInbound i on c.inboundId = i.Inbound_id 
				        left JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId    
				        LEFT JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
				        LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
				        LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId

				        where c.conversationId = @conversationId

				            
				        End
				        ELSE BEGIN --Camp
				            SELECT  @OldAgentId = conv.agentId,
				                    @OldConversationId = rel.conversationIdBefore
				            FROM ccWhatsAppConversationsRelationshipOut rel 
				            RIGHT JOIN ccWhatsAppConversationsOut conv ON conv.conversationId = rel.conversationIdBefore
				            WHERE rel.conversationIdAfter = @conversationId

				            SELECT
				            cast(i.CampType as int) AS ServiceType,
				            cast(c.conversationId as int) as ConversationID,
				            c.clientId as ClientId,
				            c.phoneCamp as [To],
				            cast(i.cam_id as int) as ACDId,
				            i.cam_descripcion as ACDName,
				            cast(g.graphic_id as int) as ACDGraphicId,
				            cast(cm.closeConversationTime as int) as [TimeOut],
				            cast(cm.answerTimeoutClient as int) as [TimeOutWarning],
				            i.exitAssisted as [ExitWrapUpDisposition],              
				            cast(i.cam_tnotas as int) [WrapUpTime],
				            i.cam_ShowCalifWnd as ShowCalifWnd, 
				            cast(ISNULL(answerTimeoutClient, 30) AS int) as [AnswerTimeoutClient],
				            ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent),0) as [SecTimeOutLastMessageAgent],
				            isnull(permission.AllowUnassign,0) as AllowUnassign,
				            isnull(permission.AllowSpam,0) as AllowSpam,
				            ISNULL(@OldAgentId, 0) AS OldAgentId,
				            ISNULL(@OldConversationId, 0) AS OldConversationId,
				            c.agentId AS AgentId
				            FROM  ccWhatsAppConversationsOut c
				            LEFT JOIN  ccCamps i ON c.camId = i.cam_id 
				            LEFT JOIN  contactMeanOut cm  ON c.camId = cm.camp_id
				            LEFT JOIN ccRIACampsGraph g on g.cam_id = c.camId
				            LEFT JOIN ccLastMessageAgentByConversationOut lm ON lm.conversationId = c.conversationId
				            LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId

				            where c.conversationId = @conversationId
				        END
				    END
				    ELSE IF(@Option = 3)
				    BEGIN
				        if @campType =0 begin --ACD
				            SELECT
				            CAST(inbound.Inbound_id AS INT) AS Id,
				            inbound.descripcion AS Name,
				            ISNULL(configuration.conexionInfo, '''') AS Phone,
				            CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
				            inbound.tNotas AS WrapUpTime,
				                CAST(graphics.graphic_id AS INT) AS GraphicId
				            FROM  ccInbound inbound
				            INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
				            INNER JOIN  contactMeanIn configuration ON (inbound.Inbound_id = configuration.inboundId and inbound.Inbound_id = @inboundId)
				        end
				        else begin
				        SELECT
				            CAST(campaign.cam_id AS INT) AS Id,
				            campaign.cam_descripcion AS Name,
				            ISNULL(configuration.conexionInfo, '''') AS Phone,
				            CAST(ISNULL(configuration.answerTimeoutClient, 0) AS int) AS TimeOut,
				            cast(campaign.cam_tnotas as int) AS WrapUpTime,
				            CAST(graphics.graphic_id AS INT) AS GraphicId
				            FROM  ccCamps campaign
				            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
				            INNER JOIN  contactMeanOut configuration ON (campaign.cam_id = configuration.camp_id and campaign.cam_id = @inboundId)
				        end
				    END
				    ELSE IF(@Option = 4)
				    Begin
				            declare @pathFile as varchar(max)
				            declare @filetype as varchar(5)
				            DECLARE @mensajes TABLE(idMessage VARCHAR(100));
				            DECLARE @tmpMessageConversations TABLE(
				                    [messageId] VARCHAR(75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
				                ,[conversationId] INT NOT NULL
				                ,[timeStampMessage] DATETIME NOT NULL
				                ,[originType] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
				                ,[price] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
				                ,[messageIdUi] INT NULL
				                ,[currency] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				                ,[typeMessage] VARCHAR(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				                ,[content] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				                ,[clientNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				                ,[vonageNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				                ,[timeStampMessageUTC] DATETIME NULL
				                ,[messageStatus] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
				            );

				        insert into @mensajes
				        select value from dbo.fn_RIASplitDelimited(@messagesList,'','')
				                        
				            if(@CampType = 0)
				            BEGIN
				                INSERT INTO @tmpMessageConversations(messageId, conversationId, timeStampMessage, originType
				                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
				                messageStatus) 
				                select messageId, conversationId, timeStampMessage, originType
				                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
				                messageStatus
				                FROM ccWAMessagesConversations  where messageId in (select idMessage from @mensajes)
				            END
				            if(@CampType = 1)
				            BEGIN
				                INSERT INTO @tmpMessageConversations(messageId, conversationId, timeStampMessage, originType
				                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
				                messageStatus) 
				                select messageId, conversationId, timeStampMessage, originType
				                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
				                messageStatus
				                FROM ccWAMessagesConversationsOut  where messageId in (select idMessage from @mensajes)
				            END
				            select @pathFile = valor from ccSettings where setting_id=230
				        select
				            messageId as MessageId,
				            messageStatus as Status,
				            originType as Origin,
				            case when originType =''Client'' then 3
				                    when originType =''Agent'' then 2
				                    when originType =''Admin'' then 1
				            else 0 end as OriginType,
				            timeStampMessage as [Timestamp],
				            case when typeMessage IN (''text'', ''template'')  then content else '''' end as Content,
				            typeMessage as Type,
				            case 
				                    when typeMessage not in( ''text'' ,''location'', ''file'', ''template'') then content
				                    else
				                        case
				                            when typeMessage = ''file'' then (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 1),'':'') where id=2) 
				                                    else '''' end
				                    end as Caption,
				            case 
				                    when originType = ''Client''
				                    then
				                        case
				                                when typeMessage = ''text'' or typeMessage = ''location''
				                                or (typeMessage = ''file'' and (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) = '''' )
				                            then ''''
				                                else char(92)+char(92)+''WhatsApp''+char(92)+char(92)+ CASE WHEN @CampType = 0 THEN ''INBOUND'' ELSE ''OUTBOUND'' END +char(92)+char(92)+cast(conversationId/1000 as varchar(30))+char(92)+char(92)+cast(conversationId as varchar(20))+char(92)+char(92)+ typeMessage + char(92)+char(92)+ messageId +
				                                case
				                                        when typeMessage = ''video'' then ''.mp4''
				                                        when typeMessage = ''image'' then ''.jpg''
				                                        when typeMessage = ''audio'' then ''.mp3''
				                                        when typeMessage = ''file''
				                                        then (select substring(content, LEN(content) - CHARINDEX(''.'',REVERSE(content))+1, len(content)))
				                                    else '''' end
				                        end
				                    else
				                        case
				                            when typeMessage = ''text'' or typeMessage = ''location'' OR typeMessage = ''template''
				                            then ''''
				                            else content
				                    end
				                end as [Url],
				                case when typeMessage = ''file'' 
				                then (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2)
				                else '''' end as [FileSize],
				                case when typeMessage = ''file'' 
				                then (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 4),'':'') where id=2)
				                else '''' end as [FileName],
				            case when typeMessage = ''location''
				            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 1),'':'') where id=2) else '''' end as [Address],
				            case when typeMessage = ''location''
				            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) else '''' end as [Lat],
				            case when typeMessage = ''location''
				            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [Long],
				            case when typeMessage = ''location''
				            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 4),'':'') where id=2) else '''' end as [Name],
				            case when typeMessage = ''location''
				            then ''https://www.google.com/maps/search/'' + (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) + '','' +
				                (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [LocationURL]
				                from @tmpMessageConversations
				            order by Timestamp asc

				    End
				                                            
				    ELSE IF(@Option = 5)
				    BEGIN
				        if @CampType =0 begin
				            SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
				                FROM contactMeanIn
				            WHERE inboundId = @inboundId
				        end 
				        else begin
				            SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
				                FROM contactMeanOut
				            WHERE camp_id = @inboundId
				        end 
				    END
				    ELSE IF(@Option = 6)
				    BEGIN
				        SELECT [Login] AS ''OriginName''
				            FROM [CCenterRIA].[dbo].[ccUsers]
				        WHERE [User_id] = @agentId
				    END
				    END'
		EXEC(@sql)

		-------------------------------------------- END IVAN MARTIN Errores de WhatsApp Version 2023.425.125.8------------------------------
		
		SET @process = 'Alter Sp ccsp_Skills @action = 1 se agrega inner join ccinbound inb on inb.Inbound_id=C.Inbound_id'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_Skills]
	@action int ,@userId int=null,@inboundId tinyint=null,@skill int =8,@idwg smallint=null
AS

if @action = 1 begin --lista acd de un admin
	select distinct i.Inbound_id, i.descripcion, g.frame,i.chat mode from ccRIACampEspWG wg
		inner join ccInbound i  ON wg.IdCampEsp=i.Inbound_id
		inner join ccRIAInboundGraph ig ON ig.Inbound_id = i.Inbound_id
		inner join ccRIAGraphics g ON g.graphic_id=ig.graphic_id
		inner join ccRIAWorkGroupUsers wgUser on WgUser.IDWG=wg.IDWG
		where wg.Tipo=0 and wgUser.User_id=@userId
end
else if @action=2 begin
	select distinct A.user_id,A.Nombres+'' '' +A.ApellidoPaterno+ '' '' +A.ApellidoMaterno name,isnull(B.Skill,8) skill
		from ccRIACampEspWG D
		inner join ccRIAWorkGroupUsers C on D.IDWG=C.IDWG
		inner join ccusers A on C.User_id=A.User_id
		left join ccSkills B on B.User_id= A.User_id and D.IdCampEsp= B.Inbound_id
		where D.IdCampEsp=@inboundId and A.TipoUser_id=1
end
else if @action =3 begin
	if @userId = 0 begin
		update ccSkills set Skill=@skill where Inbound_id=@inboundId
		select 1,''update All''
	end
	else begin
		if not exists(select * from ccSkills where Inbound_id= @inboundId and User_id=@userId) begin
			insert into ccSkills (Inbound_id,User_id,Skill) values (@inboundId,@userId,@skill)
			select 1,''insert''
			end
		else begin
			update ccSkills set Skill=@skill where Inbound_id=@inboundId and User_id=@userId
			select 1,''update''
		end
	end
end
else if @action = 4 begin --delete wg
	delete s from ccSkills S
inner join (select A.inboundId from
		(select distinct isnull(C.Inbound_id,B.IdCampEsp) inboundId from ccRIAWorkGroupUsers A inner join ccRIACampEspWG B on A.IDWG = B.IDWG and B.Tipo=0 left join ccSkills C on C.Inbound_id = B.IdCampEsp where A.User_id=@UserId and B.IDWG= @idwg) A
			left join
		(select distinct isnull(C.Inbound_id,B.IdCampEsp) inboundId from ccRIAWorkGroupUsers A inner join ccRIACampEspWG B on A.IDWG = B.IDWG and B.Tipo=0 left join ccSkills C on C.Inbound_id = B.IdCampEsp where A.User_id=@UserId and B.IDWG<> @idwg) B
			on A.inboundId=B.inboundId 	where B.inboundId is null) I
	on I.inboundId = S.Inbound_id where S.User_id=@UserId
end

else if @action = 5 begin --insert wg
	insert into ccSkills(Inbound_id,User_id,Skill)
select A.inboundId,@UserId,8 as Skill from (
(	select distinct isnull(C.Inbound_id,B.IdCampEsp) inboundId from ccRIAWorkGroupUsers A
	inner join ccRIACampEspWG B on A.IDWG = B.IDWG and B.Tipo=0 
	left join ccSkills C on C.Inbound_id = B.IdCampEsp 
	inner join ccinbound inb on inb.Inbound_id=C.Inbound_id
	where A.User_id=@UserId	
	) A
	left join (select Inbound_id as inboundId from ccSkills C where C.User_id=@UserId) B on A.inboundId=B.Inboundid) where B.inboundId is null

end'
		EXEC(@sql)


		/*Fix para la visualizción de los datos al cargar una base de datos a la campaña*/
		SET @process = 'DROP Sp ccsp_OUTGetNewJobs'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_OUTGetNewJobs'')
	BEGIN
	    DROP PROCEDURE ccsp_OUTGetNewJobs;
	END'
EXEC(@sql)

SET @process = 'CREATE Sp ccsp_OUTGetNewJobs se agrega condición para cuando sea @test = 2'
SET @sql = '
CREATE procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID INT,
@test INT=0,
@nAgentsLogin INT=1,
@iZonas INT = NULL,
@isDashboardApi BIT = 0
as
set nocount on
DECLARE @total INT
DECLARE @topCount smallINT, @bIsDaylight bit, @revHorario bit
DECLARE @country_id INT, @TipoJobs INT

DECLARE @sql nvarchar(MAX), @Order_Asc_Desc char(4)
declare @sqlInsertGeneric nvarchar(MAX)
declare @parameters nvarchar(MAX)
DECLARE @camSurvey INT, @campType INT;
SELECT @camSurvey = 0

SELECT @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0;
SELECT @campType = CampType FROM ccCamps WHERE cam_id =  @CAMPID;
		
-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
SELECT @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
SELECT @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

if @iZonas is null begin
	exec @iZonas= ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0		
--Checamos si la campaña tiene horarios configurados
	IF(@test <> 2)
	BEGIN
		if exists(SELECT cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
		begin
			if @iZonas = 0 begin
				SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
				return
			end
		end
		else begin
			if @camSurvey > 0
			begin
				SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
				return
			end
		END
	END
end

IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS
IF OBJECT_ID(N''tempdb..#AI_NEW_JOBS'') IS NOT NULL  DROP TABLE #AI_NEW_JOBS

CREATE TABLE #NEW_JOBS (
	callout_id INT
	,cam_id INT
	,cal_telefono VARCHAR(15) collate SQL_Latin1_General_CP1_CI_AS
	,cal_status TINYINT
	,cal_fechaDial DATETIME
	,user_id INT
	,tz INT
	,tz2 INT
	,tz3 INT
	,tz4 INT
	,tz5 INT
	,list_id INT
	,sequence SMALLINT
	,calkey VARCHAR(max)
	,nDescartes INT
	,name_agent VARCHAR(max)
	,status_for_ai TINYINT
	)
select * into #AI_NEW_JOBS from  #NEW_JOBS where 1=0


set @sql=''''

-------------------------- IA -------------------
DECLARE @IsCampAi BIT = 0;
DECLARE @new_calls_date VARCHAR(max) = '''';


SELECT @IsCampAi = CASE WHEN CampType = 4 THEN 1 ELSE 0 END FROM ccCamps where cam_id = @CAMPID 

DECLARE @select_table VARCHAR(50);
SET @select_table = (CASE WHEN @IsCampAi = 1 THEN ''#AI_NEW_JOBS'' ELSE ''#NEW_JOBS'' END);
		
-------------------------- IA -------------------

-- 0=Ambas, 1=CallBacks, 2=Nuevas
SELECT @topCount=valor from ccSettings where setting_id=94

if isnull(@topCount,0)=0
SELECT @topCount=case when @nAgentsLogin<3 then 30
		when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
		when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
		when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
		when @nAgentsLogin>=16 then 240 else 20 end
		
SELECT @sql=@sql+nchar(13) + ''DECLARE @topCountNewToday INT=0,@topCountNewLastDay INT=0,@topCountCb INT=0,@totalNewToday INT=0
,@totalNewLastDay INT=0,@totalCallbacks INT=0,@stateIa INT=0
DECLARE @newCallsPercentage FLOAT=0.7,@lastDayNewCallsPercentage FLOAT= 0.15,@callbacksPercentage FLOAT=0.15;
SELECT @topCountNewToday = CEILING(@topCount* @newCallsPercentage),
@topCountNewLastDay = CEILING(@topCount* @lastDayNewCallsPercentage), 
@topCountCb = CEILING(@topCount* @callbacksPercentage),@stateIa=0
,@topCountNewToday=case when @IsCampAi=1 then @topCountNewToday else  @topCount/2 end''

SELECT @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

DECLARE @isVerano varchar(max)
set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' END

IF(@campType = 7)
BEGIN
	set @isVerano = ''W.iTimeZone'' + case @bIsDaylight when 1 then ''_summer'' else '''' END

	select @sqlInsertGeneric=nchar(13)+ ''INSERT ''+@select_table+'' 
SELECT top(@topCount) W.smsout_id, W.cam_id, W.sms_phoneNumber, W.sms_status, W.sms_dateDial, W.user_id,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
W.list_id, isNull(R.sequence,0) as sequence,
sos.callkey+''''~''''+rtrim(data1)+''''~''''+rtrim(data2)+''''~''''+rtrim(data3)+''''~''''+rtrim(data4)+''''~''''+rtrim(data5) calkey, 0 AS nDescartes,
isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent
,@stateIa status_for_ai
FROM smsWorkingTable W 
left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
left join smsOutSource sos (nolock) on sos.smsout_id=W.smsout_id
left join ccUsers us (nolock) on us.User_id=w.user_id
WHERE STATUS_REPLACE_QUERY
and DATE_REPLACE_QUERY
and W.cam_id=@CAMPID
and (
   ( (''+@isVerano+''  & @iZonas)>0 or ''+@isVerano+''=0) 
or ( (''+@isVerano+''2 & @iZonas)>0 or ''+@isVerano+''2=0) 
or ( (''+@isVerano+''3 & @iZonas)>0 or ''+@isVerano+''3=0) 
or ( (''+@isVerano+''4 & @iZonas)>0 or ''+@isVerano+''4=0)
or ( (''+@isVerano+''5 & @iZonas)>0 or ''+@isVerano+''5=0)
)
and isnull(R.status,2) in(0,2)''

END
else begin
	select @sqlInsertGeneric=nchar(13)+ ''INSERT ''+@select_table+'' 
SELECT top(@topCountNewToday) W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
W.list_id, isNull(R.sequence,0) as sequence,
cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
,W.nDescartes,isnull(us.nombres, '''''''')+'''' ''''+isnull(us.ApellidoPaterno, '''''''')+'''' ''''+isnull(us.ApellidoMaterno, '''''''') Name_agent
,@stateIa status_for_ai
FROM ccoWorkingTable W 
left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
left join ccUsers us (nolock) on us.User_id=w.user_id
WHERE STATUS_REPLACE_QUERY
AND DATE_REPLACE_QUERY
and W.cam_id=@CAMPID
and (
   ( (''+@isVerano+''  & @iZonas)>0 or ''+@isVerano+''=0) 
or ( (''+@isVerano+''2 & @iZonas)>0 or ''+@isVerano+''2=0) 
or ( (''+@isVerano+''3 & @iZonas)>0 or ''+@isVerano+''3=0) 
or ( (''+@isVerano+''4 & @iZonas)>0 or ''+@isVerano+''4=0)
or ( (''+@isVerano+''5 & @iZonas)>0 or ''+@isVerano+''5=0)
)
and isnull(R.status,2) = 2''
end

if @TipoJobs in(0,2)--** INCLUIR LOS NUEVAS
begin			
	IF(@campType = 7)
	BEGIN

		select @sql=@sql+nchar(13)+''--INCLUIR LAS NUEVAS--''
		select @sql=@sql+REPLACE(
		REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.sms_dateDial < dateadd(mi, 5, getdate())'')
			,''STATUS_REPLACE_QUERY'',''W.sms_status=0'')
		select @sql=@sql+nchar(13)+'' order by R.sequence, W.sms_dateDial ''+ @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc
						
	END
	ELSE 
	BEGIN			

		SET @new_calls_date = (CASE WHEN @IsCampAi = 1
			THEN '' W.cal_fechaDial BETWEEN CONVERT(DATE, getdate()) AND DATEADD(mi, 5, getdate()) '' 
			ELSE '' W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora '' END);					
	
		select @sql=@sql+nchar(13)+''--INCLUIR LAS NUEVAS--''
		select @sql=@sql+REPLACE(
			REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',@new_calls_date)
				,''STATUS_REPLACE_QUERY'',''W.cal_status=0'')
		select @sql=@sql+nchar(13)+'' order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc
	END

end -- TOMA EN CUENTA LAS NUEVAS

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin
	IF(@campType = 7)
	BEGIN				
		select @sql=@sql+nchar(13)+''--INCLUIR LOS CALLBACKS--''
		select @sql=@sql+nchar(13)+REPLACE(
			REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.cal_fechaDial<dateadd(mi, 5, getdate())'')
		,''STATUS_REPLACE_QUERY'',''W.sms_status=1 -- CallBacks'')
		select @sql=@sql+nchar(13)+'' order by priority_cb desc, W.sms_dateDial ''  + @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
	END
	ELSE
	BEGIN
		select @sql=@sql+nchar(13)+''--INCLUIR LOS CALLBACKS--''
		select @sql=@sql+nchar(13)+REPLACE(
			REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.cal_fechaDial<dateadd(mi, 5, getdate())'')
		,''STATUS_REPLACE_QUERY'',''W.cal_status=1'')
		select @sql=@sql+nchar(13)+'' order by prioridad_cb desc, W.cal_fechaDial ''  + @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
	END
					
end -- TOMA EN CUENTA LOS CALLBACKS

IF @IsCampAi = 1 -- NUEVOS REZAGADOS
BEGIN	
	select @sql=@sql+nchar(13)+''--NUEVOS REZAGADOS--''
	select @sql=@sql+REPLACE(
		REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.cal_fechaDial<convert(date,getdate())'')
		,''STATUS_REPLACE_QUERY'',''W.cal_status=0'')
	select @sql=@sql+nchar(13)+'' order by prioridad_cb desc, W.cal_fechaDial ''  + @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
END -- TOMA EN CUENTA LOS NUEVOS REZAGADOS


		
----------------------- CASO DE IA------------------------------------------------------
IF @IsCampAi = 1 
BEGIN

SELECT @sql=@sql+nchar(13) + ''select @totalNewToday = count(*) from #AI_NEW_JOBS where status_for_ai = 0
select @totalCallbacks = count(*) from #AI_NEW_JOBS where status_for_ai = 1
select @totalNewLastDay = count(*) from #AI_NEW_JOBS where status_for_ai = 2	
insert into #NEW_JOBS
select top(@topCountNewToday) callout_id,cam_id,cal_telefono,cal_status,cal_fechaDial,user_id,tz,tz2,tz3,tz4,tz5,list_id,sequence,calkey,nDescartes,name_agent
,status_for_ai
from #AI_NEW_JOBS where status_for_ai=0
if @totalNewToday< @topCountNewToday begin
	set @topCountNewLastDay=@topCountNewLastDay+(@topCountNewToday-@totalNewToday)
end
insert into #NEW_JOBS
select top(@topCountNewLastDay) callout_id,cam_id,cal_telefono,cal_status,cal_fechaDial,user_id,tz,tz2,tz3,tz4,tz5
,list_id,sequence,calkey,nDescartes,name_agent
,status_for_ai
from #AI_NEW_JOBS where status_for_ai=2	
if @totalNewToday+@totalNewLastDay < @topCountNewToday+@topCountCb begin
	set @topCountCb=@topCountCb+@topCountNewToday+@topCountCb-@totalNewToday-@totalNewLastDay
end
insert into #NEW_JOBS
select top(@topCountCb) callout_id,cam_id,cal_telefono,cal_status,cal_fechaDial,user_id,tz,tz2,tz3,tz4,tz5
,list_id,sequence,calkey,nDescartes,name_agent
,status_for_ai
from #AI_NEW_JOBS where status_for_ai=1''

END
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
set @parameters=''@CAMPID int,@topCount int,@IsCampAi BIT,@iZonas int,@campType int''		

if @Test=0
begin
	IF(@campType = 7) begin
		SELECT @sql=@sql+nchar(13)+ ''UPDATE smsWorkingTable with (rowlock) SET sms_status=2 --CALLBACK IN PROGRESS
	WHERE smsout_id in(SELECT callout_id from '' + @select_table +'')''
	end
	else begin
		SELECT @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
	WHERE callout_id in(SELECT callout_id from '' + @select_table +'')''
	end
	
end

if @Test = 2
begin
	SELECT @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM '' + @select_table +'' where len(cal_telefono)>0''
	DECLARE @nSQL nvarchar(max)
	set @nSQL=cast(@sql as nvarchar(max))
	set @parameters=@parameters+N'',@outA int OUTPUT''

	exec sp_executesql @nSQL, @parameters
	,@CAMPID=@CAMPID
	,@topCount=@topCount
	,@IsCampAi=@IsCampAi
	,@iZonas=@iZonas
	,@campType=@campType
	,@outA=@total OUTPUT

	IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS
	IF OBJECT_ID(N''tempdb..#AI_NEW_JOBS'') IS NOT NULL  DROP TABLE #AI_NEW_JOBS

	--print (@sql)

		return(@total)
end
else
BEGIN
	IF(@isDashboardApi = 1)
	BEGIN
			
	-- TOMA EN CUENTA LOS REGISTROS PROCESANDOSE
	select @sql=@sql+nchar(13)+''--Procesando--''
	select @sql=@sql+REPLACE(
		REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora'')
		,''STATUS_REPLACE_QUERY'',''W.cal_status=2'')
	select @sql=@sql+nchar(13)+'' order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc

	END
		
	select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5,
case when tz is null then '''''''' else cal_telefono end as tel,
case when tz2 is null then '''''''' else cal_telefono end as tel2,
case when tz3 is null then '''''''' else cal_telefono end as tel3,
case when tz4 is null then '''''''' else cal_telefono end as tel4,
case when tz5 is null then '''''''' else cal_telefono end as tel5,
NULL as dialOrder, list_id, sequence, calkey,
0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type
FROM #NEW_JOBS where len(cal_telefono)>0

---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
if @campType<>7 and exists(SELECT * FROM #NEW_JOBS)
	exec ccsp_GetCampsNvosCB @cam_id=@CAMPID,@Tipo=0,@user_id=0
''
END

--print (@sql)

exec sp_executesql  @sql,@parameters,
@CAMPID=@CAMPID
,@topCount=@topCount
,@IsCampAi=@IsCampAi
,@iZonas=@iZonas
,@campType=@campType

IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS
IF OBJECT_ID(N''tempdb..#AI_NEW_JOBS'') IS NOT NULL  DROP TABLE #AI_NEW_JOBS


return(0)'

EXEC(@sql)

		/* End script release */		/* Upgrade database version (first and the last number of setting 77) */
		EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
