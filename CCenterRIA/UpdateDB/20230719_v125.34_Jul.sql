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

	---------------------------------------BEGIN Paco Cota DEV1-306 Carga solo celulares (para campa�as de SMS)---------------------------------------------------------

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
	BEGIN -- Setting 108 validar el tama�o longitud del telefono
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
BEGIN --9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador, 14:Espa�a 15:Peru, 16: Panama 
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

		SET @process = 'Se actualiza ccsp_MultimediaCommon para obtener el valor de la nueva columna. Linea (511) y timeStampMessageUTC timeStampMessage se cambia para obtener UTC'
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
			select messageId, conversationId,timeStampMessageUTC timeStampMessage, originType
			,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
			messageStatus
		
			FROM ccWAMessagesConversations  where messageId in (select idMessage from @mensajes)
		END
		if(@CampType = 1)
		BEGIN
			INSERT INTO @tmpMessageConversations(messageId, conversationId, timeStampMessage, originType
			,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
			messageStatus) 
			select messageId, conversationId,timeStampMessageUTC timeStampMessage, originType
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


		/*Fix para la visualizci�n de los datos al cargar una base de datos a la campa�a*/
		SET @process = 'DROP Sp ccsp_OUTGetNewJobs'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_OUTGetNewJobs'')
	BEGIN
	    DROP PROCEDURE ccsp_OUTGetNewJobs;
	END'
EXEC(@sql)

SET @process = 'CREATE Sp ccsp_OUTGetNewJobs se agrega condici�n para cuando sea @test diferente a  2'
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
--Checamos si la campa�a tiene horarios configurados
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
-------------------------------------------BEGIN MACL CW-8033------------------------------------------------
SET @process = 'hotfix/125.20230719.0.2 Se inserta etiquetas faltantes a la tabla tableLangueDbLoader'
SET @sql = 'if not exists (select 1 from tableLangueDbLoader where [translate] = ''Registro actualizado'')
BEGIN
	insert into tableLangueDbLoader values(0,''type-updated-records'',''Registro actualizado'')
END
if not exists (select 1 from tableLangueDbLoader where [translate] = ''Updated record'')
BEGIN
	insert into tableLangueDbLoader values(1,''type-updated-records'',''Updated record'')
END
if not exists (select 1 from tableLangueDbLoader where [translate] = ''Registro atualizado'')
BEGIN
	insert into tableLangueDbLoader values(2,''type-updated-records'',''Registro atualizado'')
END'

EXEC(@sql)

SET @process = 'hotfix/125.20230719.0.2 ALTER Sp ccsp_RIALogPhones se agrega condici�n para cuando sea tipoMov = 2'
SET @sql = 'ALTER procedure [dbo].[ccsp_RIALogPhones]
@load_id int,
@Type smallint,
@GenCSV bit = 1, -- 0:100 / 1:todos
@isKolob bit = 0,
@PageIndex      INT = 0,
@PageSize       INT = 0,
@option SMALLINT = NULL
as
set nocount ON

declare @CaseType varchar(2000), @sql nvarchar(MAX), @nType char(5), @MovType SMALLINT, @language int
SELECT @language = cs.valor FROM dbo.ccSettings AS cs WHERE cs.setting_id = 27;
declare @PageStart int,@PageEnd int

select @CaseType = '''', @nType = right(''0000''+cast(@Type as varchar(5)), 5)

if @nType like ''%____1%''
	select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 0 
	''

if @nType like ''%___1_%''
	select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov in(-1,0) 
	''

if @nType like ''%__1__%''
	select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 1 
	''

if @nType like ''%_1___%''
	select @CaseType = @CaseType + '' or isnull(telefono,'''''''')<>'''''''' and crlp.tipoMov = 1 
	''

if @nType like ''%1____%''
	select @CaseType = @CaseType + '' or isnull(telefono,'''''''')='''''''' and crlp.tipoMov = 2 ''

if @CaseType = '''' and @nType <> 0
	return(0)


		
IF(@option = 1)
BEGIN	
	SET @sql = ''SELECT count(*) AS listSize FROM (
select crlp.load_id
from ccRIALogPhones AS crlp 
where crlp.load_id = @load_id'' 
+ @CaseType +'') tmp '' +
case @GenCSV when 0 then ''WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd'' else '''' end
			--EXEC(@sql);
			select @PageStart=@PageSize*(@PageIndex-1),@PageEnd=@PageSize*@PageIndex
		Exec sp_executesql @sql
                 , N''@PageStart int,@PageEnd int,@language int,@load_id int''
                 , @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id
			RETURN (0);
		END
		ELSE 
		BEGIN
				IF(@isKolob = 1)
				BEGIN

				declare @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200), @typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @typeUpdatedRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200)
, @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max);


select @typeDescriptionPhoneBlocked=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-num''
select @typeDescriptionPhoneUpdated=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-num''
select @typeIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-incorrect-records''
select @typeBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-blocked-records''
select @typeDescriptionPhoneNotLoaded=translate from tableLangueDbLoader where languageId=@language and tag=''type-not-loaded-num''

select @typeDescriptionPhoneBlackList=translate from tableLangueDbLoader where languageId=@language and tag=''description-dnc-list''
select @descriptionIncorrectRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-incorrect-records''
select @descriptionBlockedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''description-blocked-records''
select @typeUpdatedRecords=translate from tableLangueDbLoader where languageId=@language and tag=''type-updated-records''

select @column=translate from tableLangueDbLoader where languageId=@language and tag=''column-file-field''

select @headerPhone=header_phone,@headerPhone2=header_phone2,@headerPhone3=header_phone3,@headerPhone4=header_phone4 
,@headerPhone5=header_phone5
from fileHeadersPhoneLoad where load_id=@load_id
			
					set @CaseType=case when @CaseType <> '''' then '' and ('' + substring(@CaseType, 5, len(@CaseType)) + '')'' else '''' END
					SET @sql = '';with result as(
SELECT * FROM (select  
ROW_NUMBER() OVER(ORDER BY crlp.cal_key ASC) AS RowNum,
crlp.load_id,
crlp.cal_key, 
crlp.telefono AS phone,
CASE
	WHEN crlp.tipoMov in (1,4)  THEN @typeDescriptionPhoneBlocked  
	WHEN crlp.tipoMov = 2 THEN @typeUpdatedRecords	
	WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @typeIncorrectRecords
	WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @typeBlockedRecords
	WHEN crlp.tipoMov in(-1,0) THEN @typeDescriptionPhoneNotLoaded
	WHEN crlp.keyTranslate is not null THEN isnull(tlan.translate,crlp2.descTipoMov)
ELSE 
	crlp2.descTipoMov  
END AS Tipo,
case when CHARINDEX('''':'''',crlp.motivo)=0 then 0 else
	convert(int,substring(crlp.motivo ,CHARINDEX('''':'''',crlp.motivo)-1 ,1))
end
 AS ColumnFile, 
CASE  WHEN crlp.tipoMov = 2 THEN ''''N/A'''' 
		WHEN crlp.tipoMov in (1,4) THEN @typeDescriptionPhoneBlackList							  
		WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-incorrect-records'''') THEN @descriptionIncorrectRecords
		WHEN crlp.motivo in (select translate from tableLangueDbLoader where tag=''''type-blocked-records'''') THEN @descriptionBlockedRecords
		WHEN crlp.keyTranslate is not null THEN tlan.translate 
ELSE crlp.motivo END AS motivo
from ccRIALogPhones AS crlp 
INNER JOIN dbo.ccRIACATLogPhones AS  crlp2 ON crlp.tipoMov = crlp2.tipoMov
left join tableLangueDbLoader tlan on tlan.tag=crlp.keyTranslate and tlan.languageId=@language
where crlp.load_id = @load_id '' 				
+ @CaseType +'') tmp '' +
case @GenCSV when 0 then '' WHERE tmp.RowNum > @PageStart AND tmp.RowNum <= @PageEnd '' else '''' end +'' 
) 
select  crlp.RowNum,
crlp.load_id,
crlp.cal_key, 
crlp.phone,
crlp.Tipo,
case when crlp.ColumnFile=1 then @column+ '''' ''''+@headerPhone
when crlp.ColumnFile=2 then @column+ '''' ''''+@headerPhone2
when crlp.ColumnFile=3 then @column+ '''' ''''+@headerPhone3
when crlp.ColumnFile=4 then @column+ '''' ''''+@headerPhone4
when crlp.ColumnFile=5 then @column+ '''' ''''+@headerPhone5
else '''''''' end ColumnFile,
crlp.motivo
from result crlp ''
	END
	ELSE
	BEGIN
		set @sql = ''select '' + case @GenCSV when 0 then ''top 100 '' else '''' end 
		+ ''load_id, cal_key, telefono, tipoMov, motivo from ccRIALogPhones AS crlp where load_id = @load_id '' 
		+ @CaseType
	END  
	PRINT(@sql);

	select @PageStart=@PageSize*(@PageIndex-1),@PageEnd=@PageSize*@PageIndex
	Exec sp_executesql @sql
    , N''@PageStart int,@PageEnd int,@language int,@load_id int, @column VARCHAR(100), @typeDescriptionPhoneNotLoaded VARCHAR(200), @typeDescriptionPhoneBlocked VARCHAR(200),
	@typeDescriptionPhoneUpdated VARCHAR(200), @typeDescriptionPhoneBlackList VARCHAR(200),
@typeBlockedRecords VARCHAR(200), @typeIncorrectRecords VARCHAR(200), @descriptionBlockedRecords VARCHAR(200), @descriptionIncorrectRecords VARCHAR(200)
, @headerPhone VARCHAR(max), @headerPhone2 VARCHAR(max), @headerPhone3 VARCHAR(max), @headerPhone4 VARCHAR(max), @headerPhone5 VARCHAR(max), @typeUpdatedRecords varchar(200)''
    , @PageStart=@PageStart,@PageEnd=@PageEnd,@language=@language,@load_id=@load_id,@column=@column,@typeDescriptionPhoneNotLoaded=@typeDescriptionPhoneNotLoaded
	,@typeDescriptionPhoneBlocked=@typeDescriptionPhoneBlocked,@typeDescriptionPhoneUpdated=@typeDescriptionPhoneUpdated,@typeDescriptionPhoneBlackList=@typeDescriptionPhoneBlackList
	,@typeBlockedRecords=@typeBlockedRecords,@typeIncorrectRecords=@typeIncorrectRecords,@descriptionBlockedRecords=@descriptionBlockedRecords,@descriptionIncorrectRecords=@descriptionIncorrectRecords
	,@headerPhone=@headerPhone,@headerPhone2=@headerPhone2,@headerPhone3=@headerPhone3,@headerPhone4=@headerPhone4,@headerPhone5=@headerPhone5,@typeUpdatedRecords=@typeUpdatedRecords
	
return(0)
END
set nocount OFF'

EXEC(@sql)



-----------------------------------------------END MACL------------------------------------------------------


-----------------------------------------------------BEGIN Jesus Gallardo hotfix/125.20230719.0.2-----------------------------------------------------------------

	set @process = 'hotfix/125.20230719.0.2 Alter SP ccsp_smsCampSchedule correcion rango de fechas dateadd(ss,-(2*@timeMaxContestacion), dateadd(mi,(horaFin*60)+MinFin ,fDate)) [End]'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_smsCampSchedule]
@camId as int
AS

declare @horaUniversal datetime
declare @hourStart int,@hourEnd int,@minStart int,@minEnd int
declare @timeMaxContestacion tinyint

set @timeMaxContestacion=30

select @timeMaxContestacion=cam_tNoContesta from cccamps where cam_id=@camId
declare @schLaw table (hourStart int not null,minStart int not null,hourEnd int not null,minEnd int not null)

insert into @schLaw
exec ccsp_GetHourLaw
SELECT @hourStart = hourStart, @minStart = minStart, @hourEnd = hourEnd, @minEnd = minEnd from @schLaw

SET DATEFIRST 1
set @horaUniversal = getutcdate()

;with camSch as(
select ROW_NUMBER() OVER(ORDER BY idate DESC) AS id
,DATEPART(hh,idate) HoraInicio, DATEPART(mi,idate) as MinInicio
,DATEPART(hh,fDate) horaFin, DATEPART(mi,fDate) as MinFin
,idate,fDate
from ccSmsSchedules where cam_id= @camId 
) 
, camSchLaw as(
select id,
case when HoraInicio>@hourStart then HoraInicio else @hourStart end HoraInicio,
 case when (horaInicio>@hourStart or (horaInicio=@hourStart and MinInicio>=@minStart) ) then MinInicio  else @minStart end MinInicio,
 case when horaFin<@hourEnd then horaFin else @hourEnd end HoraFin,
 case when ((horaFin < @hourEnd or (horaFin=@hourEnd and MinFin<=@minEnd) )) then MinFin  else @minEnd end MinFin
 ,convert(datetime, CONVERT(date, idate)) as idate,convert(datetime,convert(date,fDate)) as fDate
 ,@hourStart hourStart
from camSch
), timeZone as(
 select tz_id,
 dateadd(mi, tz_offset*60, @horaUniversal) as fecha
 from ccTimeZones
)

select distinct
 dateadd(mi,(HoraInicio*60)+MinInicio ,idate) [Start]
, dateadd(ss,-(2*@timeMaxContestacion), dateadd(mi,(horaFin*60)+MinFin ,fDate)) [End]
from camSchLaw Sch
inner join timeZone t on 
t.fecha between dateadd(mi,(HoraInicio*60)+MinInicio ,idate)  and dateadd(mi,(horaFin*60)+MinFin ,fDate)

'
	EXEC(@Sql)	

-----------------------------------------------------END Jesus Gallardo hotfix/125.20230719.0.2-----------------------------------------------------------------

---------------------------------------BEGIN Enrique Ruiz  hotfix/125.20230719.0.2---------------------------------------------------------
	SET @process = 'hotfix/125.20230719.0.2 CW-TT6327 ALTER SP ccsp_RIAUpdateCamConfig actualizar cam_ShowCalifWnd solo si tiene calificaciones asignadas, de lo contrario termina'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
@cam_id smallint,
@cam_descripcion varchar(40) = null,
@cam_tnotas smallint = null,
@cam_ocupado tinyint = null,
@cam_NoInt_ocupado tinyint = null,
@cam_inter_ocupado smallint = null,
@cam_nocontesto tinyint = null,
@cam_NoInt_nocontesto tinyint = null,
@cam_inter_nocontesto smallint = null,
@cam_fax tinyint = null,
@cam_NoInt_fax tinyint = null,
@cam_inter_fax smallint = null,
@cam_ModoManual tinyint= null,
@ANI varchar(15) = null,
@cam_ShowCalifWnd bit = null,
@cam_StartTimerOnHangUp bit = null,
@editableCallKey bit = null,
@cam_tNoContesta tinyint = null,
@cam_intensive_dialing tinyint = null,
@detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
@detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
@compliance TinyInt = null,
@cam_inter_graba smallint = null,
@cam_NoInt_graba tinyint = null,
@progDial smallint = null,
@excCallBack Tinyint = null,
@dialOrder Tinyint = null,
@dialPrefix varchar(10) = null,
@dialPrefixMan varchar(10) = null,
@dialPrefixXfe varchar(10) = null,
@listenManualCall bit = null,
@stopRecording bit = null,
@abandonCallback bit = null,
@autoCB smallint = null,
@id_listAni int = null,
@tDialonWrapUp smallint = null,
@quesize smallint=null,
@DNCScrub int=null,
@callerIdDesc varchar(15)=null,
@timeZoneRule int=null,
@callsBySurvey int=null,
@ivrScript int=null,
@surveyPctg int=null,
@call_record tinyint=null,
@dRestrictPlay bit = null,
@leaveRecMessage bit = null,
@manualCallOnChat bit = null,
@callBackSurveyClient bit = null,
@callBackSurveyAgent bit = null,
@funcEspDtmf int =null,
@sipHdrsCfg varchar(255) = null,
@cam_inter_cancelled smallint = null,
@prefijo varchar(max) = null,
@exitAssisted bit = null,
@previewDiscard bit = null,
@rotativeAlgo tinyint = null,
@timesPreview tinyint = null,
@cam_tPreview smallint = null,
@timesDiscard tinyint = null,
@CampType int = null,
@agentCloseConversationTime SMALLINT = NULL,
@adminCloseConversationTime INT = NULL,
@ConexionInfo VARCHAR(400) = NULL,
@allowFileAttachments BIT = NULL,
@selectRotativeANI int = null,
@messagingOrder bit = null,
@autoStart bit = null,
@recordHold bit = null,
@userId                SMALLINT     = NULL, 
@idArea                SMALLINT     = NULL, 
@isCreating            SMALLINT          = NULL,
@module INT = -1
as
set nocount on
DECLARE @timesDiscardActual int = (SELECT timesDiscard FROM ccCamps WHERE cam_id = @cam_id)
DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)
    DECLARE @PrevName VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

UPDATE ccCamps SET
 cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
 cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
 cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
 cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
 cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
 cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
 cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
 cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
 cam_inter_cancelled = isnull(@cam_inter_cancelled,cam_inter_cancelled),
 cam_fax = isnull(@cam_fax,cam_fax),
 cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
 cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
 cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
 ANI = isnull(@ANI,ANI),
 cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
 editableCallKey = isnull(@editableCallKey, editableCallKey),
 cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
 iTipoDial = isnull(@cam_intensive_dialing, iTipoDial),
 detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine),
 detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
 compliance = isnull(@compliance, compliance),
 cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
 cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
 cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
 progDial = isnull(@progDial, progDial),
 excCallBack = isnull(@excCallBack,excCallBack),
 dialOrder = isnull(@dialOrder, dialOrder),
 dialPrefix = isnull(@dialPrefix, dialPrefix),
 dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
 dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
 listenManualCall = isnull(@listenManualCall, listenManualCall),
 stopRecording = isnull(@stopRecording, stopRecording),
 abandonCallback = isnull(@abandonCallback, abandonCallback),
 t_autoCB = isnull(@autoCB,t_autoCB),
 id_anilist = isnull(@id_listAni,id_anilist),
 tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
 cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
 cam_maxqueue = isnull(@quesize,cam_maxqueue),
 DNCScrub = isnull(@DNCScrub,DNCScrub),
 callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
 timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
 callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
 ivrScript = isnull(@ivrScript,ivrScript),
 surveyPctg = isnull(@surveyPctg,surveyPctg),
 call_record = isnull(@call_record,call_record),
 startStopRecording = isnull(@dRestrictPlay, startStopRecording),
 leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
 manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
 callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
 callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
 funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf ),
 sipHdrFormat = isnull(@sipHdrsCfg, sipHdrFormat),
 prefijo = isnull(@prefijo, prefijo),
 exitAssisted = isnull(@exitAssisted, exitAssisted),
 previewDiscard = isnull(@previewDiscard, previewDiscard),
 rotativeAlgo = isnull(@rotativeAlgo, rotativeAlgo),
 timesPreview = isnull(@timesPreview, timesPreview),
 cam_tPreview = isnull(@cam_tPreview,cam_tPreview),
 timesDiscard = isnull(@timesDiscard, timesDiscard),
 CampType = (CASE  WHEN @CampType is not null THEN @CampType WHEN @progDial = 2 THEN 6 WHEN @progDial IS NOT NULL AND @progDial <> 2 THEN 0 WHEN CampType is not null THEN CampType ELSE 0 END),
 selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
 messagingOrder = isnull(@messagingorder, messagingOrder),
 autoStart = isnull(@autoStart,autoStart),
 recordHold = isnull(@recordHold, recordHold)

Where cam_id = @cam_id

        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

        Create table #ccCampsTable 
        (
            columnInfo VARCHAR(255),
            dataInfo VARCHAR(255),
            identifierInfo VARCHAR(255)
        )

        DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN 
                                                                    CASE 
                                                                        WHEN @Camptype = 6  THEN 44
                                                                        WHEN @Camptype = 5  THEN 46
                                                                        WHEN @Camptype = 4  THEN 48
                                                                        WHEN @Camptype = 7  THEN 50
                                                                        ELSE 42 END
                                                                ELSE 
                                                                    CASE 
                                                                        WHEN @Camptype = 6  THEN 55
                                                                        WHEN @Camptype = 5  THEN 56
                                                                        WHEN @Camptype = 4  THEN 57
                                                                        WHEN @Camptype = 7  THEN 58
                                                                        ELSE 54 END
                                                                END;
    
		IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

        IF(@isCreating = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
        
        DELETE FROM #ccCampsTable WHERE columnInfo IN (''startStopRecording'');
        DELETE FROM #ccCampsTable WHERE dataInfo = '''''''';
        
        IF(@CampType = 6) DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'', ''cam_fDialOnWU'', ''ProgDial'');
        ELSE IF(@CampType = 5 AND @isCreating = 2) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'', ''cam_descripcion'', ''exitAssisted'');
        ELSE IF(@CampType = 5) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'');
        ELSE IF(@CampType = 7) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''messagingOrder'', ''autoStart'', ''rotativeAlgo'', ''id_anilist'', ''cam_descripcion'');
        ELSE DELETE FROM #ccCampsTable WHERE columnInfo IN (''previewDiscard'', ''CampType'', ''cam_fDialOnWU'', ''ProgDial'');

        IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            @operation, 
			@module,
            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> ''''
                THEN
                    CASE
                        WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN
                            CASE WHEN @isCreating = 1 THEN '''' ELSE CCCT.identifierInfo END
                        WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN 
                            CASE WHEN @CampType = 5 THEN ''OUT_WHATS_EXIT_ASSISTED'' ELSE CCCT.identifierInfo END
						WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
							CASE WHEN @Camptype = 5 THEN ''OUT_MANUAL_DIALING_WHATS'' ELSE CCCT.identifierInfo END
                        ELSE
                            CCCT.identifierInfo
                        END
                ELSE
                ''''
                END,
            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
                CASE 
                    WHEN CCCT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
                        CASE WHEN CCCT.dataInfo = ''VOICEMAIL'' 
                            THEN ''COMMON_VOICE_MAIL'' 
                            ELSE 
                                CASE WHEN CCCT.dataInfo IS NOT NULL THEN CCCT.dataInfo ELSE ''T&COMMON_NONE'' END 
                            END
                    WHEN CCCT.identifierInfo = ''OUT_DIALING_ORDER'' THEN 
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_DESCENDING'' ELSE ''COMMON_ASCENDING'' END

                    WHEN CCCT.identifierInfo = ''OUT_SMS_MESSAGING_ORDER'' THEN 
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ASCENDING'' ELSE ''COMMON_DESCENDING'' END

                    WHEN CCCT.identifierInfo = ''OUT_ANSWER_MACHINE_DETC'' THEN 
                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_BASIC'' 
                             WHEN CCCT.dataInfo = 1 THEN ''COMMON_LIGHT''
                             WHEN CCCT.dataInfo = 2 THEN ''COMMON_MODERATE''
                             WHEN CCCT.dataInfo = 3 THEN ''COMMON_HIGH''
                             ELSE ''T&COMMON_NONE'' END

                    WHEN CCCT.identifierInfo = ''OUT_ANI_MODE'' THEN 
                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ANI_LOCAL'' 
                             WHEN CCCT.dataInfo = 1 THEN ''COMMON_ANI_ROTATIVE''
                             WHEN CCCT.dataInfo = 2 THEN ''COMMON_ANI_ROTATIVE_REG''
                             WHEN CCCT.dataInfo = 3 THEN ''COMMON_ANI_ROTATIVE_SMART''
                             ELSE ''T&COMMON_NONE'' END

                    WHEN CCCT.identifierInfo = ''OUT_DIALING_MODE'' THEN 
                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_PREDICTIVE'' 
                             WHEN CCCT.dataInfo = 1 THEN ''COMMON_PROGRESIVE''
                             ELSE ''COMMON_ASSISTED'' END

                    WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
                        CASE WHEN  @CampType = 5 THEN 
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                        ELSE
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_VIA_KEYPAD_LOG''
                                 WHEN CCCT.dataInfo = 2 THEN ''COMMON_VIA_CALLS_LOG''
                                 WHEN CCCT.dataInfo = 3 THEN ''COMMON_VIA_CALLS_LOG''
                                 ELSE ''T&COMMON_NONE'' END
                        END

                    WHEN CCCT.identifierInfo = ''OUT_ANI_LIST'' THEN
                                ISNULL((SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo), CCCT.dataInfo)

                    WHEN CCCT.identifierInfo = ''OUT_CONDUCT_SURVEY'' THEN
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
                    WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING_ON_CHAT'', ''OUT_TIME_ZONE_VALIDATION_MANUAL'', ''OUT_INTENSIVE_DIALING'', ''OUT_CALLBACK_EXCLUSIVE_AGENT'', ''OUT_VOIEMAIL_DETECTION'',
                                                 ''OUT_CALLBACK_FAILED'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'', ''OUT_EDIT_CALL_KEY'', ''OUT_STOP_RECORDING'', ''OUT_LEAVE_PRERECORDED'',
                                                 ''OUT_CONDUCT_CALLBACK_SURVEY'', ''OUT_RECEIVE_DTMF'', ''OUT_SELECT_ANI_ON_DIALING'', ''OUT_SMS_START_CAMP_AUTO'', ''OUT_RECORD_ON_HOLD'', ''OUT_LISTEN_TONE'', ''OUT_UNASSIGN_RECORDS'') THEN
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    
                    ELSE CCCT.dataInfo END
            ELSE '''' END, 
            CASE WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN @PrevName ELSE (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id) END
        FROM #ccCampsTable AS CCCT;

        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
begin
    EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
end

IF (@CampType IS NOT NULL AND @CampType IN (3, 5))
BEGIN
    IF NOT EXISTS(SELECT camp_id FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id)
    BEGIN
        SELECT 0
        RETURN(0)
    END

    IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

    Create table #contactMeanOutTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )

    EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @cam_id, @userId= @userid

    DECLARE @PrevConexionInfo VARCHAR(MAX) = (SELECT [conexionInfo] FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id);

    set @ConexionInfo = case when  @ConexionInfo is null or @ConexionInfo in('''',''0'',''None'',''Ninguno'') then CASE WHEN @isCreating > 0 AND @PrevConexionInfo <> '''' THEN ''Ninguno'' ELSE '''' END else @ConexionInfo end
    UPDATE contactMeanOut SET conexionInfo = @ConexionInfo, ConnPass = @ConexionInfo, connUser = @ConexionInfo,
                              closeConversationTime = @agentCloseConversationTime, answerTimeoutClient = @adminCloseConversationTime,
                              allowFileAttachments = @allowFileAttachments
    WHERE @CampType = meanContactTypeId AND camp_id = @cam_id

    
	IF(@isCreating > 0 AND @module > -1) BEGIN 
        EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';
        IF(@ConexionInfo IS NULL OR @ConexionInfo IN ('''',''0'',''None'',''Ninguno'') AND @PrevConexionInfo <> @ConexionInfo) UPDATE contactMeanOut SET conexionInfo = '''' WHERE @CampType = meanContactTypeId AND camp_id = @cam_id
    END

    DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''conexionInfo'') AND  dataInfo = '''''''';
    DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''ConnPass'', ''connUser'') ;

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        @operation, 
		@module, 
        CMOT.identifierInfo,
        CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
            CASE
                WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
                    CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                WHEN CMOT.identifierInfo = ''OUT_WHATS_ASSOCIATED_PHONE'' THEN
                    CASE WHEN CMOT.dataInfo = ''Ninguno'' THEN ''COMMON_NONE_O'' ELSE CMOT.dataInfo END
                ELSE CMOT.dataInfo END
        ELSE '''' END, 
        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
    FROM #contactMeanOutTable AS CMOT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid;
    IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

    IF @CampType = 5 BEGIN
        update ccWhatsAppNumbers set camp_id=0 where camp_id=@cam_id
        IF(@ConexionInfo <> '''')
        BEGIN 
            UPDATE ccWhatsAppNumbers SET camp_id = @cam_id WHERE number = @ConexionInfo
        END
    END
END 
DECLARE @prevCalif BIT = (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id);

if @cam_ShowCalifWnd = 1 begin
	If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1) begin
		select 0
		return(0)
	end
	ELSE BEGIN
		UPDATE ccCamps SET cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd, cam_ShowCalifWnd)
		where cam_id = @cam_id
		select 1
		return(0)
	end
  
UPDATE ccCamps SET
cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
where cam_id = @cam_id


 IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        @operation, 
        3, 
        ''OUT_SHOW_DISPOSITIONS'',
        CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
 END

 select 1
 return(0)
end

 IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        @operation, 
        3, 
        ''OUT_SHOW_DISPOSITIONS'',
        CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
 END

select 2
return(0)

set nocount off'
	EXEC(@sql)
	---------------------------------------END Enrique Ruiz-----------------------------------------------------------

	---------------------------------------------------------------------- BEGIN IVAN MARTIN hotfix/IM-CW-8012_Wrong_Datatype_in_WhatsApp_Config_Release_Branch ----------------------------------------------------------------------
	SET @process = 'CW-8012 Cambio de tipo de dato en contactMeanOut para closeConversationTime'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.columns WHERE name = N''closeConversationTime'' AND Object_ID = Object_ID(N''contactMeanOut''))
				BEGIN
					ALTER TABLE contactMeanOut ALTER COLUMN closeConversationTime INT;
				END'
	EXEC(@sql)

	SET @process = 'CW-8012 Cambio de tipo de dato en contactMeanOut para answerTimeoutClient'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.columns WHERE name = N''answerTimeoutClient'' AND Object_ID = Object_ID(N''contactMeanOut''))
				BEGIN
					ALTER TABLE contactMeanOut ALTER COLUMN answerTimeoutClient INT;
				END'
	EXEC(@sql)

	SET @process = 'CW-8012 Cambio de tipo de dato en línea 84'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT
				,@campID INT
				AS
				BEGIN
				DECLARE @AllCampaigns TABLE (
				cam_id SMALLINT
				,cam_Descripcion VARCHAR(60)
				,cam_tNotas SMALLINT
				,cam_ocupado SMALLINT
				,cam_noInt_ocupado SMALLINT
				,cam_inter_ocupado SMALLINT
				,cam_nocontesto SMALLINT
				,cam_noInt_nocontesto SMALLINT
				,cam_inter_nocontesto SMALLINT
				,cam_fax SMALLINT
				,cam_noInt_fax SMALLINT
				,cam_inter_fax SMALLINT
				,cam_modomanual SMALLINT
				,ANI VARCHAR(15)
				,cam_ShowCalifWnd BIT
				,cam_StartTimerOnHangUp BIT
				,editableCallKey BIT
				,cam_tNoContesta SMALLINT
				,iTipoDial SMALLINT
				,detectAnswerMachine SMALLINT
				,detectVoiceMail SMALLINT
				,compliance SMALLINT
				,cam_inter_graba SMALLINT
				,cam_noint_graba SMALLINT
				,progDial SMALLINT
				,excCallBack SMALLINT
				,dialOrder SMALLINT
				,dialPrefix VARCHAR(10)
				,dialPrefixMan VARCHAR(10)
				,dialPrefixXfe VARCHAR(10)
				,listenManualCall BIT
				,stopRecording BIT
				,abandonCallback BIT
				,frame SMALLINT
				,t_autoCB SMALLINT
				,id_anilist INT
				,tDialonWrapUp SMALLINT
				,viewMode TINYINT
				,queSize SMALLINT
				,DNCScrub INT
				,callerIdDesc VARCHAR(15)
				,timeZoneRule INT
				,callsBySurvey INT
				,ivrScript INT
				,surveyPctg INT
				,call_record SMALLINT
				,startStopRecording BIT
				,leaveRecMessage BIT
				,manualCallOnChat BIT
				,callBackSurveyAgent BIT
				,callBackSurveyClient BIT
				,isRelationSurvey BIT
				,funcEspDtmf INT
				,sipHdrFormat VARCHAR(255)
				,cam_inter_cancelled SMALLINT
				,prefijo VARCHAR(40)
				,enbleprefix BIT
				,exitAssisted BIT
				,previewDiscard BIT
				,CampType INT
				,conexionInfo VARCHAR(50)
				,connUser VARCHAR(15)
				,closeConversationTime INT
				,answerTimeoutClient INT
				,allowFileAttachments BIT
				,selectRotativeANI INT
				,rotativeAlgo TINYINT
				,autoStart BIT
				,messagingOrder BIT
				,CamTPreview SMALLINT
				,TimesPreview TINYINT
				,timesDiscard TINYINT
				,recordHold BIT
				,zipCodeSchedule BIT
				,simultaneousRecs smallint
				)
				DECLARE @numbers VARCHAR(max)

				SELECT @numbers = COALESCE(@numbers + '''', '''', '''''''') + number
				FROM ccWhatsAppNumbers
				WHERE camp_id = 0
				AND STATUS = 1

				INSERT INTO @AllCampaigns
				EXEC ccsp_RIAConfCamp @adminID
				,@campID

				SELECT dialPrefixMan DialPrefixMan
				,dialPrefixXfe DialPrefixXfe
				,listenManualCall ListenManualCall
				,stopRecording StopRecording
				,abandonCallback AbandonCallBack
				,t_autoCB AutoCB
				,id_anilist IdIstANI
				,tDialonWrapUp TDialOnWrapup
				,queSize Quesize
				,DNCScrub
				,callerIdDesc CallerIdDesc
				,timeZoneRule TimeZoneRule
				,callsBySurvey CallsBySurvey
				,ivrScript IvrScript
				,surveyPctg SurveyPctg
				,call_record CallRecord
				,startStopRecording StartStopRecording
				,leaveRecMessage LeaveRecMessage
				,manualCallOnChat ManualCallOnChat
				,callBackSurveyClient CallBackSurveyClient
				,callBackSurveyAgent CallBackSurveyAgent
				,funcEspDtmf FuncEspDtmf
				,sipHdrFormat SipHdrsCfg
				,dialPrefix DialPrefix
				,prefijo Prefix
				,dialOrder DialOrder
				,progDial ProgDial
				,cam_Descripcion CamDescription
				,cam_tNotas CamTnotas
				,cam_ocupado CamBusy
				,cam_noInt_ocupado CamNoIntBusy
				,cam_inter_ocupado CamInterBusy
				,cam_nocontesto CamNoAnswer
				,cam_noInt_nocontesto CamNoIntNoAnswer
				,cam_inter_nocontesto CamInterNoAnswer
				,(cam_inter_cancelled / 60) CamInterCancelled
				,cam_fax CamFax
				,cam_noInt_fax CamNoIntFax
				,cam_inter_fax CamInterFax
				,cam_modomanual CamModoManual
				,ANI
				,cam_StartTimerOnHangUp CamStartTimerOnHangUp
				,editableCallKey EditableCallKey
				,cam_tNoContesta CamTNoAnswer
				,iTipoDial CamIntensiveDialing
				,detectAnswerMachine DetectAnswerMachine
				,detectVoiceMail DetectVoiceMail
				,compliance Compliance
				,cam_inter_graba CamInterRecord
				,cam_noint_graba CamNoIntRecord
				,excCallBack ExcCallBack
				,cam_ShowCalifWnd CamShowCalifWnd
				,frame Frame
				,exitAssisted ExitAssistedDialMode
				,previewDiscard PreviewDiscard
				,CampType
				,conexionInfo ConexionInfo
				,connUser ConnUser
				,closeConversationTime CloseConversationTime
				,answerTimeoutClient MUTimeOutClient
				,allowFileAttachments AllowFileAttachments
				,CamTPreview
				,CAST(TimesPreview AS SMALLINT) TimesPreview
				,@numbers AS FreeNumbers
				,selectRotativeANI SelectRotativeANIManualCall
				,rotativeAlgo RotativeAlgo
				,autoStart AutoStart
				,messagingOrder MessagingOrder
				,timesDiscard TimesDiscard
				,recordHold RecordHold
				,zipCodeSchedule ZipCodeSchedule
				,simultaneousRecs SimultaneousRecs
				FROM @AllCampaigns
				WHERE cam_id = @campID
				END'
	EXEC(@sql)

	SET @process = 'CW-8012 Cambio de tipo de dato en línea 194'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateWhatsAppConfiguration]
		        @inboundId        smallint,
		        @frame          smallint  = null,
		        @description      varchar(50) = null,
		        @mediaType        tinyint   = null,
		        @status         smallint  = null,
		        @number         varchar(400)= null,
		        @maxAnswerTime      int   = null,
		        @muTimeOutClient    int     = null,
		        @tNotas         int     = null,
		        @exitWrapUpDisposition  bit     = null,
		        @showCalifWnd     bit     = null,
		        @allowFileAttachments bit    = null,
				@userId 				smallint	= null,
				@module			int = -1

		      AS
		      BEGIN
		        SET NOCOUNT ON;
		        DECLARE @graph_id smallint

		        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inboundId, @userId= @userId

		        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

		        Create table #ccInboundTable 
		        (
		            columnInfo VARCHAR(255),
		            dataInfo VARCHAR(255),
		            identifierInfo VARCHAR(255)
		        )
		    
		        DECLARE @PrevDesc VARCHAR(MAX) = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @inboundId);

		        UPDATE ccInbound SET
		          descripcion = ISNULL(@description, descripcion),
		          chat = ISNULL(@mediaType, chat),
		          Status = ISNULL(@status, Status),
		          tNotas = ISNULL(@tNotas, tNotas),
		          ExitWrapUpDisposition = ISNULL(@exitWrapUpDisposition, ExitWrapUpDisposition)
		        WHERE Inbound_id = @inboundId

				IF(@module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId, @tableTemp=''#ccInboundTable'';	

		        DELETE FROM #ccInboundTable WHERE columnInfo IN (''tel_maxwait'', ''tel_maxqueue'', ''tel_outservice'', ''tel_noct'');

		        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		        SELECT 
		            (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
		            getDate(), 
		            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
		            53, 
					@module,
		            CASE WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
		                CASE WHEN @mediaType = 5 THEN ''IN_SHOW_DISPOSITIONS_WHATS'' ELSE  CCIT.identifierInfo END
		            ELSE
		                CCIT.identifierInfo
		            END,
		            CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
		                CASE 
		                    WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_WRAP_ON_DIPOSITION_WHATS'') THEN
		                        CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
		                    ELSE CCIT.dataInfo END
		            ELSE '''' END, 
		            CASE WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN @PrevDesc ELSE (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId) END
		        FROM #ccInboundTable AS CCIT;

		        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inboundId, @userId = @userId;

		        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

		        DECLARE @descUpdate varchar(50)
		        DECLARE @statusCCInbound smallint
		        select @descUpdate = ISNULL(@description, descripcion), @statusCCInbound = status from ccInbound where Inbound_id =@inboundId

		        IF NOT EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId=@inboundId) 
		          BEGIN
		              INSERT INTO contactMeanIn (meanContactTypeId, name, inboundId, isActive) 
		          values (5, @descUpdate, @inboundId, @statusCCInbound);
		          END

		        IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inboundId) 
		          BEGIN
		          DECLARE @PrevConexion VARCHAR(MAX) = (SELECT [conexionInfo] FROM contactMeanIn WHERE inboundId = @inboundId);
		          
				  set @number = case when  @number is null or @number in('''',''0'', ''Ninguno'') then ''Ninguno'' else @number end

		          EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanIn'', @columnNameId=''inboundId'', @valueId= @inboundId, @userId= @userId

		            IF OBJECT_ID(N''tempdb..#contactMeanInTable'') IS NOT NULL DROP TABLE #contactMeanInTable

		            Create table #contactMeanInTable 
		            (
		                columnInfo VARCHAR(255),
		                dataInfo VARCHAR(255),
		                identifierInfo VARCHAR(255)
		            )


		          UPDATE contactMeanIn set name=@descUpdate, conexionInfo=ISNULL(@number, conexionInfo)
		          ,connUser=ISNULL(@number, connUser)
		          ,ConnPass=ISNULL(@number, ConnPass) 
		          ,closeConversationTime = ISNULL(@maxAnswerTime, closeConversationTime),
		          answerTimeoutClient = ISNULL(@muTimeOutClient, answerTimeoutClient),
		          allowFileAttachments = ISNULL(@allowFileAttachments, allowFileAttachments)
		          where inboundId = @inboundId;

				IF(@module > -1) BEGIN
		        EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inboundId, @userId = @userId, @tableTemp=''#contactMeanInTable'';  
				END

		        IF(@number=''Ninguno'' AND @PrevConexion='''')UPDATE contactMeanIn SET conexionInfo = '''' WHERE inboundId = @inboundId;
		        DELETE FROM #contactMeanInTable WHERE columnInfo IN (''name'',''connUser'',''ConnPass'');

		            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		            SELECT 
		                (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
		                getDate(), 
		                (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
		                53, 
						@module, 
		                CMIT.identifierInfo,
		                CASE WHEN CMIT.identifierInfo IS NOT NULL AND CMIT.identifierInfo <> '''' THEN
		                    CASE
		                        WHEN CMIT.identifierInfo IN (''IN_ATTACH_FILES_WHATS'') THEN
		                            CASE WHEN CMIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
		                        WHEN CMIT.identifierInfo IN (''IN_ASSOCIATED_PHONE_WHATS'') THEN
		                            CASE WHEN CMIT.dataInfo = ''Ninguno'' THEN ''COMMON_NONE_O'' ELSE CMIT.dataInfo END
		                        ELSE CMIT.dataInfo END
		                ELSE '''' END, 
		                (SELECT [name] FROM contactMeanIn WHERE inboundId = @inboundId)
		            FROM #contactMeanInTable AS CMIT;

		            EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inboundId, @userId = @userId;

		            IF OBJECT_ID(N''tempdb..#contactMeanInTable'') IS NOT NULL DROP TABLE #contactMeanInTable

		          update ccWhatsAppNumbers set inboundId=0 where inboundId=@inboundId
		          if @number <> '''' begin
		            update ccWhatsAppNumbers set inboundId=@inboundId where inboundId=0 and number=@number
		          end

		          END

		        IF @frame IS NOT NULL
		        BEGIN
		          SELECT @graph_id = graphic_id from ccRIAGraphics where frame = @frame and [type_id] = 1
		          UPDATE ccRIAInboundGraph set graphic_id = ISNULL(@graph_id, graphic_id) where inbound_id = @inboundId

		          INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		          SELECT 
		                (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
		                getDate(), 
		                (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
		                53, 
		                3,
		                '''',
		                ''IN_CALL_EDIT_ICON'', 
		                (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)
		        END

		        DECLARE @prevCalif BIT = (SELECT [ShowCalifWnd] FROM ccInbound WHERE inbound_id = @inboundId);

		        IF @showCalifWnd = 1
		          BEGIN
		          IF EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inboundId AND tipo = 0)
		              BEGIN

		            UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd)
		                  WHERE inbound_id = @inboundId

		            IF(@prevCalif <> @showCalifWnd) BEGIN
		                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		                SELECT 
		                    (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
		                    getDate(), 
		                    (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
		                    53, 
		                    3,
		                    ''IN_SHOW_DISPOSITIONS'',
		                    CASE WHEN (SELECT [ShowCalifWnd] FROM ccInbound WHERE inbound_id = @inboundId) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END,
		                    (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)
		            END

		            SELECT 1 [Result]
		            RETURN(0)
		              END

		              SELECT -1 [Result]
		              RETURN(0)
		           END
		           ELSE
		         BEGIN
		          UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId;

		          IF(@prevCalif <> @showCalifWnd) BEGIN
		                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
		                SELECT 
		                    (SELECT CCRCA.[AreaName] FROM ccRIACat_Areas AS CCRCA, ccInbound AS CCI WHERE CCRCA.IDArea = CCI.IDArea AND CCI.Inbound_id = @inboundId),
		                    getDate(), 
		                    (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
		                    53, 
		                    3,
		                    ''IN_SHOW_DISPOSITIONS'',
		                    CASE WHEN (SELECT [ShowCalifWnd] FROM ccInbound WHERE inbound_id = @inboundId) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END,
		                    (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inboundId)
		            END
		         END

		         SELECT 1 [Result]
		         RETURN(0)

		        SET NOCOUNT OFF;
		      END'
	EXEC(@sql)

	SET @process = 'CW-8012 Cambio de tipo de dato en línea 703 para agentCloseConversationTime'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
				@cam_id smallint,
				@cam_descripcion varchar(40) = null,
				@cam_tnotas smallint = null,
				@cam_ocupado tinyint = null,
				@cam_NoInt_ocupado tinyint = null,
				@cam_inter_ocupado smallint = null,
				@cam_nocontesto tinyint = null,
				@cam_NoInt_nocontesto tinyint = null,
				@cam_inter_nocontesto smallint = null,
				@cam_fax tinyint = null,
				@cam_NoInt_fax tinyint = null,
				@cam_inter_fax smallint = null,
				@cam_ModoManual tinyint= null,
				@ANI varchar(15) = null,
				@cam_ShowCalifWnd bit = null,
				@cam_StartTimerOnHangUp bit = null,
				@editableCallKey bit = null,
				@cam_tNoContesta tinyint = null,
				@cam_intensive_dialing tinyint = null,
				@detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
				@detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
				@compliance TinyInt = null,
				@cam_inter_graba smallint = null,
				@cam_NoInt_graba tinyint = null,
				@progDial smallint = null,
				@excCallBack Tinyint = null,
				@dialOrder Tinyint = null,
				@dialPrefix varchar(10) = null,
				@dialPrefixMan varchar(10) = null,
				@dialPrefixXfe varchar(10) = null,
				@listenManualCall bit = null,
				@stopRecording bit = null,
				@abandonCallback bit = null,
				@autoCB smallint = null,
				@id_listAni int = null,
				@tDialonWrapUp smallint = null,
				@quesize smallint=null,
				@DNCScrub int=null,
				@callerIdDesc varchar(15)=null,
				@timeZoneRule int=null,
				@callsBySurvey int=null,
				@ivrScript int=null,
				@surveyPctg int=null,
				@call_record tinyint=null,
				@dRestrictPlay bit = null,
				@leaveRecMessage bit = null,
				@manualCallOnChat bit = null,
				@callBackSurveyClient bit = null,
				@callBackSurveyAgent bit = null,
				@funcEspDtmf int =null,
				@sipHdrsCfg varchar(255) = null,
				@cam_inter_cancelled smallint = null,
				@prefijo varchar(max) = null,
				@exitAssisted bit = null,
				@previewDiscard bit = null,
				@rotativeAlgo tinyint = null,
				@timesPreview tinyint = null,
				@cam_tPreview smallint = null,
				@timesDiscard tinyint = null,
				@CampType int = null,
				@agentCloseConversationTime SMALLINT = NULL,
				@adminCloseConversationTime INT = NULL,
				@ConexionInfo VARCHAR(400) = NULL,
				@allowFileAttachments BIT = NULL,
				@selectRotativeANI int = null,
				@messagingOrder bit = null,
				@autoStart bit = null,
				@recordHold bit = null,
				@userId                SMALLINT     = NULL, 
				@idArea                SMALLINT     = NULL, 
				@isCreating            SMALLINT          = NULL,
				@module INT = -1
				as
				set nocount on
				DECLARE @timesDiscardActual int = (SELECT timesDiscard FROM ccCamps WHERE cam_id = @cam_id)
				DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)
				    DECLARE @PrevName VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
				    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

				UPDATE ccCamps SET
				 cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
				 cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
				 cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
				 cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
				 cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
				 cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
				 cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
				 cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
				 cam_inter_cancelled = isnull(@cam_inter_cancelled,cam_inter_cancelled),
				 cam_fax = isnull(@cam_fax,cam_fax),
				 cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
				 cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
				 cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
				 ANI = isnull(@ANI,ANI),
				 cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
				 editableCallKey = isnull(@editableCallKey, editableCallKey),
				 cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
				 iTipoDial = isnull(@cam_intensive_dialing, iTipoDial),
				 detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine),
				 detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
				 compliance = isnull(@compliance, compliance),
				 cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
				 cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
				 cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
				 progDial = isnull(@progDial, progDial),
				 excCallBack = isnull(@excCallBack,excCallBack),
				 dialOrder = isnull(@dialOrder, dialOrder),
				 dialPrefix = isnull(@dialPrefix, dialPrefix),
				 dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
				 dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
				 listenManualCall = isnull(@listenManualCall, listenManualCall),
				 stopRecording = isnull(@stopRecording, stopRecording),
				 abandonCallback = isnull(@abandonCallback, abandonCallback),
				 t_autoCB = isnull(@autoCB,t_autoCB),
				 id_anilist = isnull(@id_listAni,id_anilist),
				 tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
				 cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
				 cam_maxqueue = isnull(@quesize,cam_maxqueue),
				 DNCScrub = isnull(@DNCScrub,DNCScrub),
				 callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
				 timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
				 callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
				 ivrScript = isnull(@ivrScript,ivrScript),
				 surveyPctg = isnull(@surveyPctg,surveyPctg),
				 call_record = isnull(@call_record,call_record),
				 startStopRecording = isnull(@dRestrictPlay, startStopRecording),
				 leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
				 manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
				 callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
				 callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
				 funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf ),
				 sipHdrFormat = isnull(@sipHdrsCfg, sipHdrFormat),
				 prefijo = isnull(@prefijo, prefijo),
				 exitAssisted = isnull(@exitAssisted, exitAssisted),
				 previewDiscard = isnull(@previewDiscard, previewDiscard),
				 rotativeAlgo = isnull(@rotativeAlgo, rotativeAlgo),
				 timesPreview = isnull(@timesPreview, timesPreview),
				 cam_tPreview = isnull(@cam_tPreview,cam_tPreview),
				 timesDiscard = isnull(@timesDiscard, timesDiscard),
				 CampType = (CASE  WHEN @CampType is not null THEN @CampType WHEN @progDial = 2 THEN 6 WHEN @progDial IS NOT NULL AND @progDial <> 2 THEN 0 WHEN CampType is not null THEN CampType ELSE 0 END),
				 selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
				 messagingOrder = isnull(@messagingorder, messagingOrder),
				 autoStart = isnull(@autoStart,autoStart),
				 recordHold = isnull(@recordHold, recordHold)

				Where cam_id = @cam_id

				        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

				        Create table #ccCampsTable 
				        (
				            columnInfo VARCHAR(255),
				            dataInfo VARCHAR(255),
				            identifierInfo VARCHAR(255)
				        )

				        DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN 
				                                                                    CASE 
				                                                                        WHEN @Camptype = 6  THEN 44
				                                                                        WHEN @Camptype = 5  THEN 46
				                                                                        WHEN @Camptype = 4  THEN 48
				                                                                        WHEN @Camptype = 7  THEN 50
				                                                                        ELSE 42 END
				                                                                ELSE 
				                                                                    CASE 
				                                                                        WHEN @Camptype = 6  THEN 55
				                                                                        WHEN @Camptype = 5  THEN 56
				                                                                        WHEN @Camptype = 4  THEN 57
				                                                                        WHEN @Camptype = 7  THEN 58
				                                                                        ELSE 54 END
				                                                                END;
				    
						IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

				        IF(@isCreating = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
				        
				        DELETE FROM #ccCampsTable WHERE columnInfo IN (''startStopRecording'');
				        DELETE FROM #ccCampsTable WHERE dataInfo = '''''''';
				        
				        IF(@CampType = 6) DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'', ''cam_fDialOnWU'', ''ProgDial'');
				        ELSE IF(@CampType = 5 AND @isCreating = 2) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'', ''cam_descripcion'', ''exitAssisted'');
				        ELSE IF(@CampType = 5) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'');
				        ELSE IF(@CampType = 7) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''messagingOrder'', ''autoStart'', ''rotativeAlgo'', ''id_anilist'', ''cam_descripcion'');
				        ELSE DELETE FROM #ccCampsTable WHERE columnInfo IN (''previewDiscard'', ''CampType'', ''cam_fDialOnWU'', ''ProgDial'');

				        IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

				        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
				        SELECT 
				            (SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
				            getDate(), 
				            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
				            @operation, 
							@module,
				            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> ''''
				                THEN
				                    CASE
				                        WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN
				                            CASE WHEN @isCreating = 1 THEN '''' ELSE CCCT.identifierInfo END
				                        WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN 
				                            CASE WHEN @CampType = 5 THEN ''OUT_WHATS_EXIT_ASSISTED'' ELSE CCCT.identifierInfo END
										WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
											CASE WHEN @Camptype = 5 THEN ''OUT_MANUAL_DIALING_WHATS'' ELSE CCCT.identifierInfo END
				                        ELSE
				                            CCCT.identifierInfo
				                        END
				                ELSE
				                ''''
				                END,
				            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
				                CASE 
				                    WHEN CCCT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
				                        CASE WHEN CCCT.dataInfo = ''VOICEMAIL'' 
				                            THEN ''COMMON_VOICE_MAIL'' 
				                            ELSE 
				                                CASE WHEN CCCT.dataInfo IS NOT NULL THEN CCCT.dataInfo ELSE ''T&COMMON_NONE'' END 
				                            END
				                    WHEN CCCT.identifierInfo = ''OUT_DIALING_ORDER'' THEN 
				                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_DESCENDING'' ELSE ''COMMON_ASCENDING'' END

				                    WHEN CCCT.identifierInfo = ''OUT_SMS_MESSAGING_ORDER'' THEN 
				                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ASCENDING'' ELSE ''COMMON_DESCENDING'' END

				                    WHEN CCCT.identifierInfo = ''OUT_ANSWER_MACHINE_DETC'' THEN 
				                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_BASIC'' 
				                             WHEN CCCT.dataInfo = 1 THEN ''COMMON_LIGHT''
				                             WHEN CCCT.dataInfo = 2 THEN ''COMMON_MODERATE''
				                             WHEN CCCT.dataInfo = 3 THEN ''COMMON_HIGH''
				                             ELSE ''T&COMMON_NONE'' END

				                    WHEN CCCT.identifierInfo = ''OUT_ANI_MODE'' THEN 
				                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ANI_LOCAL'' 
				                             WHEN CCCT.dataInfo = 1 THEN ''COMMON_ANI_ROTATIVE''
				                             WHEN CCCT.dataInfo = 2 THEN ''COMMON_ANI_ROTATIVE_REG''
				                             WHEN CCCT.dataInfo = 3 THEN ''COMMON_ANI_ROTATIVE_SMART''
				                             ELSE ''T&COMMON_NONE'' END

				                    WHEN CCCT.identifierInfo = ''OUT_DIALING_MODE'' THEN 
				                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_PREDICTIVE'' 
				                             WHEN CCCT.dataInfo = 1 THEN ''COMMON_PROGRESIVE''
				                             ELSE ''COMMON_ASSISTED'' END

				                    WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
				                        CASE WHEN  @CampType = 5 THEN 
				                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
				                        ELSE
				                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_VIA_KEYPAD_LOG''
				                                 WHEN CCCT.dataInfo = 2 THEN ''COMMON_VIA_CALLS_LOG''
				                                 WHEN CCCT.dataInfo = 3 THEN ''COMMON_VIA_CALLS_LOG''
				                                 ELSE ''T&COMMON_NONE'' END
				                        END

				                    WHEN CCCT.identifierInfo = ''OUT_ANI_LIST'' THEN
				                                ISNULL((SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo), CCCT.dataInfo)

				                    WHEN CCCT.identifierInfo = ''OUT_CONDUCT_SURVEY'' THEN
				                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
				                    WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING_ON_CHAT'', ''OUT_TIME_ZONE_VALIDATION_MANUAL'', ''OUT_INTENSIVE_DIALING'', ''OUT_CALLBACK_EXCLUSIVE_AGENT'', ''OUT_VOIEMAIL_DETECTION'',
				                                                 ''OUT_CALLBACK_FAILED'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'', ''OUT_EDIT_CALL_KEY'', ''OUT_STOP_RECORDING'', ''OUT_LEAVE_PRERECORDED'',
				                                                 ''OUT_CONDUCT_CALLBACK_SURVEY'', ''OUT_RECEIVE_DTMF'', ''OUT_SELECT_ANI_ON_DIALING'', ''OUT_SMS_START_CAMP_AUTO'', ''OUT_RECORD_ON_HOLD'', ''OUT_LISTEN_TONE'', ''OUT_UNASSIGN_RECORDS'') THEN
				                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
				                    
				                    ELSE CCCT.dataInfo END
				            ELSE '''' END, 
				            CASE WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN @PrevName ELSE (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id) END
				        FROM #ccCampsTable AS CCCT;

				        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
				        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

				if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
				begin
				    EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
				end

				IF (@CampType IS NOT NULL AND @CampType IN (3, 5))
				BEGIN
				    IF NOT EXISTS(SELECT camp_id FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id)
				    BEGIN
				        SELECT 0
				        RETURN(0)
				    END

				    IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

				    Create table #contactMeanOutTable 
				    (
				        columnInfo VARCHAR(255),
				        dataInfo VARCHAR(255),
				        identifierInfo VARCHAR(255)
				    )

				    EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @cam_id, @userId= @userid

				    DECLARE @PrevConexionInfo VARCHAR(MAX) = (SELECT [conexionInfo] FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id);

				    set @ConexionInfo = case when  @ConexionInfo is null or @ConexionInfo in('''',''0'',''None'',''Ninguno'') then CASE WHEN @isCreating > 0 AND @PrevConexionInfo <> '''' THEN ''Ninguno'' ELSE '''' END else @ConexionInfo end
				    UPDATE contactMeanOut SET conexionInfo = @ConexionInfo, ConnPass = @ConexionInfo, connUser = @ConexionInfo,
				                              closeConversationTime = CAST(@agentCloseConversationTime AS INT), answerTimeoutClient = @adminCloseConversationTime,
				                              allowFileAttachments = @allowFileAttachments
				    WHERE @CampType = meanContactTypeId AND camp_id = @cam_id

				    
					IF(@isCreating > 0 AND @module > -1) BEGIN 
				        EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';
				        IF(@ConexionInfo IS NULL OR @ConexionInfo IN ('''',''0'',''None'',''Ninguno'') AND @PrevConexionInfo <> @ConexionInfo) UPDATE contactMeanOut SET conexionInfo = '''' WHERE @CampType = meanContactTypeId AND camp_id = @cam_id
				    END

				    DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''conexionInfo'') AND  dataInfo = '''''''';
				    DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''ConnPass'', ''connUser'') ;

				    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
				    SELECT 
				        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
				        getDate(), 
				        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
				        @operation, 
						@module, 
				        CMOT.identifierInfo,
				        CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
				            CASE
				                WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
				                    CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
				                WHEN CMOT.identifierInfo = ''OUT_WHATS_ASSOCIATED_PHONE'' THEN
				                    CASE WHEN CMOT.dataInfo = ''Ninguno'' THEN ''COMMON_NONE_O'' ELSE CMOT.dataInfo END
				                ELSE CMOT.dataInfo END
				        ELSE '''' END, 
				        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
				    FROM #contactMeanOutTable AS CMOT;

				    EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid;
				    IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

				    IF @CampType = 5 BEGIN
				        update ccWhatsAppNumbers set camp_id=0 where camp_id=@cam_id
				        IF(@ConexionInfo <> '''')
				        BEGIN 
				            UPDATE ccWhatsAppNumbers SET camp_id = @cam_id WHERE number = @ConexionInfo
				        END
				    END
				END 
				DECLARE @prevCalif BIT = (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id);

				if @cam_ShowCalifWnd = 1 begin
					If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1) begin
						select 0
						return(0)
					end
					ELSE BEGIN
						UPDATE ccCamps SET cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd, cam_ShowCalifWnd)
						where cam_id = @cam_id
						select 1
						return(0)
					end
				  
				UPDATE ccCamps SET
				cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
				where cam_id = @cam_id


				 IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
				    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
				    SELECT 
				        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
				        getDate(), 
				        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
				        @operation, 
				        3, 
				        ''OUT_SHOW_DISPOSITIONS'',
				        CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
				        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
				 END

				 select 1
				 return(0)
				end

				 IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
				    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
				    SELECT 
				        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
				        getDate(), 
				        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
				        @operation, 
				        3, 
				        ''OUT_SHOW_DISPOSITIONS'',
				        CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
				        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
				 END

				select 2
				return(0)

				set nocount off'
	EXEC(@sql)

	SET @process = 'CW-8012 Cambio de tipo de dato en línea 834 CAST(@closeConversationTime AS INT)'
	SET @sql = 'ALTER PROCEDURE  [dbo].[ccsp_UpdateACDWhatsappConfig]
			    @ConexionInfo varchar(400),
			    @inbound_id int,
			    @ConnUser varchar(60),
			    @tNotas int,
			    @closeConversationTime tinyint,
			    @ShowCalifWnd bit,
			    @ExitWrapUpDisposition bit,
			    @MUTimeOutClient int,
			    @allowFileAttachments bit,
			    @userId SMALLINT, 
			    @idArea SMALLINT, 
			    @isCreating BIT

			    AS
			    set nocount on
			    IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
			    BEGIN

			        UPDATE contactMeanIn SET ConnPass = ''N/A'', numMessages = 3, timeAlertMessage = 5, answerTimeOut = 10 where inboundId = @inbound_id;

			        EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanIn'', @columnNameId=''inboundId'', @valueId= @inbound_id, @userId= @userid

			        IF OBJECT_ID(N''tempdb..#contactMeanInTable'') IS NOT NULL DROP TABLE #contactMeanInTable

			        Create table #contactMeanInTable 
			        (
			            columnInfo VARCHAR(255),
			            dataInfo VARCHAR(255),
			            identifierInfo VARCHAR(255)
			        )

			        UPDATE contactMeanIn SET conexionInfo = @conexionInfo, connUser = @connUser, closeConversationTime = CAST(@closeConversationTime AS INT), answerTimeoutClient = @MUTimeOutClient, allowFileAttachments = @allowFileAttachments        
			        where inboundId = @inbound_id;

			        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inbound_id, @userId = @userid, @tableTemp=''#contactMeanInTable'';

			        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
			        SELECT 
			            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
			            getDate(), 
			            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
			            CASE WHEN @isCreating = 1 THEN 40 ELSE 53 END, 
			            3, 
			            CMIT.identifierInfo,
			            CASE WHEN CMIT.identifierInfo IS NOT NULL AND CMIT.identifierInfo <> '''' THEN
			                CASE
			                    WHEN CMIT.identifierInfo IN (''IN_ATTACH_FILES_WHATS'') THEN
			                        CASE WHEN CMIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
			                    ELSE CMIT.dataInfo END
			            ELSE '''' END, 
			            (SELECT [name] FROM contactMeanIn WHERE inboundId = @inbound_id)
			        FROM #contactMeanInTable AS CMIT;

			        EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanIn'', @columnNameId = ''inboundId'', @valueId = @inbound_id, @userId = @userid;

			        IF OBJECT_ID(N''tempdb..#contactMeanInTable'') IS NOT NULL DROP TABLE #contactMeanInTable

			        UPDATE ccWhatsAppNumbers SET inboundId = @inbound_id WHERE number = @conexionInfo


			    END;

			    IF EXISTS (SELECT Inbound_id FROM ccInbound WHERE Inbound_id = @inbound_id) 
			    BEGIN
			    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inbound_id, @userId= @userid

			        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

			        Create table #ccInboundTable 
			        (
			            columnInfo VARCHAR(255),
			            dataInfo VARCHAR(255),
			            identifierInfo VARCHAR(255)
			        )

			        UPDATE ccInbound SET tNotas = @tNotas, ShowCalifWnd = @ShowCalifWnd, ExitWrapUpDisposition = @ExitWrapUpDisposition where Inbound_id = @inbound_id;

			        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid, @tableTemp=''#ccInboundTable'';

			        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
			        SELECT 
			            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
			            getDate(), 
			            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
			            40, 
			            3, 
			            CASE 
			                WHEN CCIT.identifierInfo = ''IN_WRAP_UP_TIME'' THEN ''IN_WRAP_UP_TIME_WHATS''
			                WHEN CCIT.identifierInfo = ''IN_SHOW_DISPOSITIONS'' THEN ''IN_SHOW_DISPOSITIONS_WHATS'' 
			                ELSE  CCIT.identifierInfo 
			            END,
			            CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
			                CASE
			                    WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_WRAP_UP_TIME'', ''IN_WRAP_ON_DIPOSITION_WHATS'') THEN
			                        CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
			                    ELSE CCIT.dataInfo END
			            ELSE '''' END, 
			            (SELECT [name] FROM contactMeanIn WHERE inboundId = @inbound_id)
			        FROM #ccInboundTable AS CCIT;

			        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid;

			        IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable
			    END;
			    SELECT @inbound_id;
			    return(@inbound_id)

			    set nocount off'
	EXEC(@sql)

	SET @process = 'CW-8012 Cambio de tipo de dato en línea 920'
	SET @sql = 'ALTER PROCEDURE  [dbo].[ccsp_UpdateOutWhatsappConfig] 
	            @ConexionInfo varchar(400),
	            @outbound_id int,
	            @descripcion varchar(400), 
	            @ConnUser varchar(60),
	            @tNotas int,
	            @closeConversationTime int,
	            @ShowCalifWnd bit,
	            @ExitAssisted bit,
	            @MUTimeOutClient int,
	            @allowFileAttachments bit,
	            @userId SMALLINT, 
	            @idArea SMALLINT, 
	            @isCreating SMALLINT

	            AS
	            set nocount on
	            IF NOT EXISTS (SELECT camp_id FROM ContactMeanOut WHERE camp_id = @outbound_id) BEGIN

	                INSERT INTO contactMeanOut (meanContactTypeId, name, camp_id, isActive, numMessages,conexionInfo,connUser,closeConversationTime,ConnPass,answerTimeoutClient,allowFileAttachments)
	                VALUES (5, @descripcion, @outbound_id, (select cam_activo  from ccCamps where cam_id = @outbound_id), 3, NULL, NULL, NULL, ''N/A'', NULL, NULL);

	            END

	                        IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

	                        Create table #contactMeanOutTable 
	                        (
	                            columnInfo VARCHAR(255),
	                            dataInfo VARCHAR(255),
	                            identifierInfo VARCHAR(255)
	                        )

	                        EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @outbound_id, @userId= @userid


	                        UPDATE contactMeanOut SET
	                            conexionInfo = @conexionInfo,
	                            connUser = @connUser,
	                            closeConversationTime = @closeConversationTime,
	                            answerTimeoutClient = @MUTimeOutClient,
	                            allowFileAttachments = @allowFileAttachments
	                        WHERE camp_id = @outbound_id

	                        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @outbound_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';

	                        DELETE FROM #contactMeanOutTable WHERE dataInfo = '''''''';

	                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
	                        SELECT 
	                            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
	                            getDate(), 
	                            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
	                            46, 
	                            3, 
	                            CMOT.identifierInfo,
	                            CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
	                                CASE
	                                    WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
	                                        CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
	            
	                                    ELSE CMOT.dataInfo END
	                            ELSE '''' END, 
	                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @outbound_id)
	                        FROM #contactMeanOutTable AS CMOT;

	                        EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @outbound_id, @userId = @userid;
	                        IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

	                        UPDATE ccWhatsAppNumbers SET camp_id = @outbound_id WHERE number = @conexionInfo

	            IF EXISTS (SELECT cam_id FROM ccCamps WHERE cam_id = @outbound_id) 
	            BEGIN

	                        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

	                        Create table #ccCampsTable 
	                        (
	                            columnInfo VARCHAR(255),
	                            dataInfo VARCHAR(255),
	                            identifierInfo VARCHAR(255)
	                        )

	                        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @outbound_id, @userId= @userid

	                        UPDATE ccCamps SET cam_tnotas = @tNotas, cam_ShowCalifWnd = @ShowCalifWnd, exitAssisted = @ExitAssisted, CampType = 5 where cam_id = @outbound_id;

	                        IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @outbound_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

	                        DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'');

	                        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
	                        SELECT 
	                            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
	                            getDate(), 
	                            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
	                            46, 
	                            3, 
	                            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
	                                CASE WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN ''OUT_WHATS_EXIT_ASSISTED''
	                                ELSE CCCT.identifierInfo END
	                            ELSE CCCT.identifierInfo END,
	                            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
	                                CASE
	                                    WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'') THEN
	                                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
	            
	                                    ELSE CCCT.dataInfo END
	                            ELSE '''' END, 
	                            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @outbound_id)
	                        FROM #ccCampsTable AS CCCT;

	                        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @outbound_id, @userId = @userid;
	                        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

	            END;
	            SELECT @outbound_id;

	            set nocount off'
	EXEC(@sql)

	SET @process = 'CW-8012 Cambio de tipo de dato en línea 1067'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccspADMaddConversationTweet]
				@action int,
				@inboundId int = null,
				@clientId varchar(255)= null,
				@isFinished bit = 0,
				@screenNameClient varchar(100) = null,
				@screenNameInbound varchar(100) = null,
				@meanContactTypeId smallint = null,
				@twitId varchar(255) = null,
				@conversationId bigint = null,
				@date datetime=null,
				@replayId varchar(255)=null,
				@tipoTwitId tinyint=1,
				@messageId bigint = null,
				@dispositionId smallint=0,
				@subDispositionId smallint=0,
				@tWrapUp int =0

				as
				set nocount on

				declare @ninteration int ,@messageOutTwitterId bigint
				declare @userId int
				declare @isEndConversation bit


				if @action = 1 begin --Revisa que exista la conversacion
					select @conversationId =  isnull(max(conversationTwitterId),0) from conversationTwitter where isFinished = 0 and meanContactTypeId = 2 and ClientId = @clientId and inboundId=@inboundId
					if @conversationId = 0
						select cast(0 as bigint) as Id
					else begin
						declare @closeConversation int
						declare @tRsponse datetime
						select @tRsponse = isnull(max(tSend),getdate()) from messageOutTwitter where conversationTwitterId = @conversationId
						select @closeConversation = closeConversationTime from contactMeanIn where inboundId=@inboundId
						 if datediff(dd,getdate(),@tRsponse ) > @closeConversation
							select  cast(0 as bigint)  as Id
						else
							select @conversationId as Id
					end
				    return 0
				end
				else if @action = 2 begin --Nueva conversacion y mensaje entrada y salida
				    --agregar tabla de messagetwit fecha de descarga
					if @replayId is null or @replayId=''''
						set @replayId= ''0''
				    if NOT EXISTS (select * from messageInTwitter where twitId = @twitId) 
					BEGIN
						insert into conversationTwitter (inboundId,ClientId,isFinished,screenNameClient,screenNameInbound,meanContactTypeId,replayId)
						values(@inboundId,@clientId,@isFinished,@screenNameClient,@screenNameInbound,@meanContactTypeId,@replayId)
						set  @conversationId  = SCOPE_IDENTITY()
					
							insert into messageInTwitter(conversationTwitterId,tipoTwitId,twitId,[date]) values(@conversationId,@tipoTwitId,@twitId,@date)
							set @messageId=SCOPE_IDENTITY()
					
						insert into messageOutTwitter(conversationTwitterId,messageStatusId,tipoTwitId,userId,[date],ninteration,messageInTwitterIdIni,messageInTwitterIdEnd)
						values(@conversationId,1,@tipoTwitId,0,@date,1,@messageId,@messageId)

					END
				    select 0 as LastUserId,@conversationId as Id, @messageId as MessageId
				    return 0
				end
				else if @action = 3 begin --Nuevo mensaje Entrada
					---Revisa que no se contesto el twitt
					select @messageOutTwitterId=max(A.messageOutTwitterId),@ninteration= count(B.messageInTwitterId)
					from messageOutTwitter A inner join messageInTwitter B on A.conversationTwitterId=B.conversationTwitterId
					where A.conversationTwitterId=@conversationId and A.messageStatusId not in (5,6,7,8,9,10,11)
					
					SELECT TOP 1  @messageId=messageInTwitterId from messageInTwitter where twitId = @twitId

					IF @messageId is null 
					BEGIN
						insert into messageInTwitter(conversationTwitterId,tipoTwitId,twitId,[date]) values(@conversationId,@tipoTwitId,@twitId,@date)
						set @messageId=SCOPE_IDENTITY()

						if  @messageOutTwitterId is null begin
							insert into messageOutTwitter(conversationTwitterId,messageStatusId,tipoTwitId,userId,[date],ninteration,messageInTwitterIdIni,messageInTwitterIdEnd)
							values(@conversationId,1,@tipoTwitId,0,@date,1,@messageId,@messageId)
							set @messageOutTwitterId=SCOPE_IDENTITY()
						end
						else begin
							update messageOutTwitter set messageInTwitterIdEnd=@messageId,[date]=@date,ninteration=@ninteration
							where messageOutTwitterId=@messageOutTwitterId
						end
					end
					select @userId = userId  from messageOutTwitter with(nolock) where messageOutTwitterId=@messageOutTwitterId
					select @userId as LastUserId,@conversationId as Id, @messageId as MessageId
					return 0
				end
				else if @action = 4 begin --Obtiene el maximo messageOutTwitterId por conversacion
				    select @messageOutTwitterId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId
					select @replayId=replayId from conversationTwitter where conversationTwitterId=@conversationId
					select @messageOutTwitterId as messageOutTwitterId,@replayId as replayId
					return 0
				end
				else if @action = 5 begin --Ultimo mensaje en por ACD
				    select cast(isnull(max(twitId),0)as bigint) as Id, max(date) as Date from messageInTwitter as A
					inner join conversationTwitter as B on A.conversationTwitterId=B.conversationTwitterId
					where B.inboundId=@inboundId
					return 0
				end
				else if @action = 6 begin --Obtiene conversaciÃ³n dependiendo del replayId
					select @conversationId=conversationTwitterId  from messageOutTwitter where twitId=@replayId
					if @conversationId is not null begin
						select @replayId=replayId from conversationTwitter where conversationTwitterId=@conversationId
					end
					else begin
						select 0 as conversationId,''0'' as replayId
					end
					select @conversationId as conversationId,@replayId as replayId
					return 0
				end

				set nocount off'
	EXEC(@sql)
	---------------------------------------------------------------------- END IVAN MARTIN hotfix/IM-CW-8012_Wrong_Datatype_in_WhatsApp_Config_Release_Branch ----------------------------------------------------------------------
	------------------------BEGIN JONATHAN RAMIREZ------------------------------------------------------------------------------------------
	SET @process = 'JR 1 - Update settings description (166, 253)';
	SET @sql = '
		IF EXISTS (SELECT * FROM ccSettings WHERE setting_id = 166) BEGIN
			UPDATE ccSettings SET 
			descripcion = ''Llamada - Marcar sólo en horarios permitidos por ley.'',
			description = ''Call - Dial only during compliance schedules.''
			WHERE setting_id = 166
		END

		IF EXISTS (SELECT * FROM ccSettings WHERE setting_id = 253) BEGIN
			UPDATE ccSettings SET 
			descripcion = ''SMS - Marcar sólo en horarios permitidos por ley.'',
			description = ''SMS - Dial only during compliance schedules.''
			WHERE setting_id = 253
		END
	';
	EXEC(@sql);

	SET @process = 'JR 2 - Se modifica ccsp_GetHourLaw, se añade parametro @isSms, para saber de que setting tomar el horario ley.';
	SET @sql='
	ALTER PROCEDURE [dbo].[ccsp_GetHourLaw] @isSms BIT = 0
	AS
	SET NOCOUNT ON

	DECLARE @isShudulerLey BIT
	DECLARE @valueShudulerLey VARCHAR(max), @hourStart INT, @hourEnd INT, @minStart INT, @minEnd INT
	DECLARE @shourStart VARCHAR(max), @shourEnd VARCHAR(max)

	DECLARE @settingId int = CASE WHEN @isSms = 0 THEN 166 ELSE 253 END

	SELECT @valueShudulerLey = valor
	FROM ccsettings
	WHERE setting_id = @settingId

	SELECT @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex(''|'', @valueShudulerLey)) AS INT), @valueShudulerLey = substring(
	        @valueShudulerLey, charindex(''|'', @valueShudulerLey) + 1, len(@valueShudulerLey))

	IF @valueShudulerLey = ''''
	BEGIN
	    SET @valueShudulerLey = ''0|07:00|22:00''

	    UPDATE ccsettings
	    SET valor = @valueShudulerLey
	    WHERE setting_id = @settingId
	END

	IF @isShudulerLey = 1
	BEGIN
	    SELECT @shourStart = substring(@valueShudulerLey, 0, charindex(''|'', @valueShudulerLey)), 
	    @shourEnd = substring(@valueShudulerLey, charindex(''|'', 
	                @valueShudulerLey) + 1, len(@valueShudulerLey))

	    SELECT @hourStart = substring(@shourStart, 0, charindex('':'', @shourStart)), 
	    @minStart = substring(@shourStart, charindex('':'', @shourStart) + 1, len(
	                @shourStart))

	    SELECT @hourEnd = substring(@shourEnd, 0, charindex('':'', @shourEnd)), 
	    @minEnd = substring(@shourEnd, charindex('':'', @shourEnd) + 1, len(@shourEnd))
	END
	ELSE
	BEGIN
	    SELECT @hourStart = 0, @minStart = 0, @hourEnd = 23, @minEnd = 59
	END

	SELECT @hourStart as hourStart, @minStart as minStart, @hourEnd as hourEnd, @minEnd minEnd
	';
	EXEC(@sql);

	SET @process = 'JR 3 - Correccion SP ccsp_smsCampSchedule, Se obtiene el horario ley con base en tipo de campaña';
	SET @sql = '
	ALTER PROCEDURE [dbo].[ccsp_smsCampSchedule]
	@camId as int
	AS

	declare @horaUniversal datetime
	declare @hourStart int,@hourEnd int,@minStart int,@minEnd int
	declare @timeMaxContestacion tinyint

	set @timeMaxContestacion=30

	select @timeMaxContestacion=cam_tNoContesta from cccamps where cam_id=@camId
	declare @schLaw table (hourStart int not null,minStart int not null,hourEnd int not null,minEnd int not null)

	insert into @schLaw
	exec ccsp_GetHourLaw @isSms = 1
	SELECT @hourStart = hourStart, @minStart = minStart, @hourEnd = hourEnd, @minEnd = minEnd from @schLaw

	SET DATEFIRST 1
	set @horaUniversal = getutcdate()

	;with camSch as(
	select ROW_NUMBER() OVER(ORDER BY idate DESC) AS id
	,DATEPART(hh,idate) HoraInicio, DATEPART(mi,idate) as MinInicio
	,DATEPART(hh,fDate) horaFin, DATEPART(mi,fDate) as MinFin
	,idate,fDate
	from ccSmsSchedules where cam_id= @camId 
	) 
	, camSchLaw as(
	select id,
	case when HoraInicio>@hourStart then HoraInicio else @hourStart end HoraInicio,
	case when (horaInicio>@hourStart or (horaInicio=@hourStart and MinInicio>=@minStart) ) then MinInicio  else @minStart end MinInicio,
	case when horaFin<@hourEnd then horaFin else @hourEnd end HoraFin,
	case when ((horaFin < @hourEnd or (horaFin=@hourEnd and MinFin<=@minEnd) )) then MinFin  else @minEnd end MinFin
	,convert(datetime, CONVERT(date, idate)) as idate,convert(datetime,convert(date,fDate)) as fDate
	,@hourStart hourStart
	from camSch
	), timeZone as(
	select tz_id,
	dateadd(mi, tz_offset*60, @horaUniversal) as fecha
	from ccTimeZones
	)

	select distinct
	dateadd(mi,(HoraInicio*60)+MinInicio ,idate) [Start]
	, dateadd(ss,-(2*@timeMaxContestacion), dateadd(mi,(horaFin*60)+MinFin ,fDate)) [End]
	from camSchLaw Sch
	inner join timeZone t on 
	t.fecha between dateadd(mi,(HoraInicio*60)+MinInicio ,idate)  and dateadd(mi,(horaFin*60)+MinFin ,fDate)
	';
	EXEC(@sql);

	SET @process = 'JR 4 - Se agrega variable para saber si el tipo de campaña es SMS @isSmsCamp';
	SET @sql = '
	ALTER PROCEDURE [dbo].[ccsp_OUTcheckTimeZone] @cam_id AS INT,@isReturnSelect bit=1
	AS
	SET NOCOUNT ON

	DECLARE @horaUniversal DATETIME, @revHorario BIT, @isShudulerLey BIT, @dateNow DATETIME
	DECLARE @hourStart INT, @hourEnd INT, @minStart INT, @minEnd INT
	DECLARE @timeMaxContestacion INT, @campType INT;

	SET @timeMaxContestacion = 60

	SELECT @revHorario = valor
	FROM ccsettings
	WHERE setting_id = 112

	SELECT @timeMaxContestacion = (cam_tNoContesta * 2)
	FROM cccamps
	WHERE cam_id = @cam_id

	SET @timeMaxContestacion = CEILING(cast(@timeMaxContestacion AS DECIMAL(10, 2)) / cast(60 AS DECIMAL(10, 2)))

	declare @schLaw table (hourStart int not null,minStart int not null,hourEnd int not null,minEnd int not null)

	SELECT @campType = CampType
	FROM ccCamps
	WHERE cam_id = @cam_id;

	DECLARE @isSmsCamp BIT = CASE WHEN @campType = 7 THEN 1 ELSE 0 END;

	insert into @schLaw
	exec ccsp_GetHourLaw @isSms = @isSmsCamp
	SELECT @hourStart = hourStart, @minStart = minStart, @hourEnd = hourEnd, @minEnd = minEnd from @schLaw

	SET DATEFIRST 1
	SET @horaUniversal = getutcdate()
	SET @dateNow = getdate()
	declare @iZonas int
	-- Si la campaña no tiene horarios asignados, marcar todas las zonas
	IF @revHorario = 0
	BEGIN
	    IF NOT EXISTS (
	            SELECT cam_id
	            FROM ccCampsHorarios WITH (INDEX (IX_ccCampsHorarios))
	            WHERE cam_id = @cam_id
	            )
	    BEGIN
	        SELECT @iZonas=sum(DISTINCT tz_id)
	        FROM (
	            SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha, 
	            datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora, 
	            datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto, 
	            datepart(dw, dateadd(mi, tz_offset * 60, @horaUniversal)) AS dia
	            FROM ccTimeZones
	            ) zonas
	        WHERE (
	                hora > @hourStart OR ( hora = @hourStart AND minuto >= @minStart)
	                )
	            AND (
	                hora < @hourEnd OR ( hora = @hourEnd AND minuto <= @minEnd)
	                )

	    if @isReturnSelect=1 begin
	        select @iZonas as iZonas
	    end
	    return @iZonas
	    END
	END

	IF @campType <> 7
	BEGIN
	    
	    SELECT h.horario_id, Descripcion, CASE WHEN HoraInicio > @hourStart THEN HoraInicio ELSE @hourStart END HoraInicio
	    , CASE WHEN (horaInicio > @hourStart OR (horaInicio = @hourStart    AND MinInicio >= @minStart) ) THEN MinInicio ELSE @minStart END MinInicio
	    , CASE WHEN horaFin < @hourEnd THEN horaFin ELSE @hourEnd END HoraFin
	    , CASE WHEN (
	        (horaFin < @hourEnd OR (horaFin = @hourEnd AND MinFin <= @minEnd)
	            )
	        ) THEN MinFin ELSE @minEnd END MinFin, Lunes, Martes, Miercoles, Jueves, Viernes, Sabado, Domingo
	    INTO #tempCamp
	    FROM cchorarios h
	    INNER JOIN ccCampsHorarios WITH (INDEX (IX_ccCampsHorarios)) ON h.horario_id = ccCampsHorarios.horario_id
	        AND ccCampsHorarios.cam_id = @cam_id

	    SELECT @iZonas=isnull(sum(DISTINCT tz_id), 0)
	    FROM (
	        SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha, 
	        datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora, 
	        datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto, 
	        datepart(dw, dateadd(mi, tz_offset * 60, @horaUniversal)) AS dia
	        FROM ccTimeZones
	        ) zonas
	    INNER JOIN #tempCamp ON (
	            (
	                hora > HoraInicio OR ( hora = HoraInicio AND minuto >= MinInicio)
	                )
	            AND (
	                hora < HoraFin OR (hora = HoraFin AND minuto <= (MinFin - @timeMaxContestacion))
	                )
	            AND (
	                Lunes = dia
	                OR Martes * 2 = dia
	                OR Miercoles * 3 = dia
	                OR Jueves * 4 = dia
	                OR Viernes * 5 = dia
	                OR Sabado * 6 = dia
	                OR domingo * 7 = dia
	                )
	            )

	    DROP TABLE #tempCamp
	    if @isReturnSelect=1 begin
	        select @iZonas as iZonas
	    end
	    return @iZonas
	END
	ELSE
	BEGIN
	        ;

	    WITH sch
	    AS (
	        SELECT DATEPART(hh, idate) AS HoraInicio, DATEPART(mi, iDate) AS MinInicio, 
	        DATEPART(hh, fdate) HoraFin, DATEPART(mi, fdate) MinFin
	        FROM ccSmsSchedules
	        WHERE cam_id = @cam_id
	            AND @dateNow BETWEEN iDate AND fDate
	        ), daysch
	    AS (
	        SELECT CASE WHEN HoraInicio > @hourStart THEN HoraInicio ELSE @hourStart END HoraInicio
	        , CASE WHEN (horaInicio > @hourStart OR (horaInicio = @hourStart AND MinInicio >= @minStart )
	                        ) THEN MinInicio ELSE @minStart END MinInicio
	        , CASE WHEN horaFin < @hourEnd THEN horaFin ELSE @hourEnd END HoraFin
	        , CASE WHEN ((  horaFin < @hourEnd OR ( horaFin = @hourEnd AND MinFin <= @minEnd))
	                        ) THEN MinFin ELSE @minEnd END MinFin
	        FROM sch
	        ), zonas
	    AS (
	        SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha
	        , datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora
	        , datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto
	        FROM ccTimeZones
	        )
	    SELECT @iZonas=isnull(sum(DISTINCT B.tz_id), 0)
	    FROM daysch A
	    INNER JOIN zonas B ON (
	            hora > HoraInicio OR ( hora = HoraInicio AND minuto >= MinInicio)
	            )
	        AND (
	            hora < HoraFin OR (hora = HoraFin AND minuto <= (MinFin - @timeMaxContestacion))
	            )

	    if @isReturnSelect=1 begin
	        select @iZonas as iZonas
	    end
	    return @iZonas
	END
	';
	EXEC(@sql);


	------------------------END JONATHAN RAMIREZ------------------------------------------------------------------------------------------
	------------------------BEGIN ULISES ESPINOSA------------------------------------------------------------------------------------------
	set @process = 'CW-8076 Error Al calificar una llamada con subcalificaciones en el dashboard'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAADMGetCalifDayForced]
        @type smallint,
        @cam_id smallint,
        @calif_id smallint = NULL,
        @isKolob BIT = 0
        AS 
        set nocount on
        create table #CalifTemp (id int identity,
        tipo integer, 
        Cam_id varchar(50), 
        Calificacion varchar(60), 
        subCalificacion varchar(60) null,
        calif_id smallint null,
        Total int,
        GraphColor varchar(15),
        IsSubDisp BIT)

        declare @today datetime
        set @today = convert(datetime, convert (varchar(11), getdate(), 101))
        --set @today =convert(datetime, convert (varchar(11), ''2015-10-01 17:50:20.470'', 101))

        -- Seleccion de idioma -- 
        declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
        select @nIdioma = case valor when 0 then ''Sin calificación'' WHEN 1 THEN ''No disposition''  else ''Sem classificação'' end
        from ccsettings where setting_id = 27 -- 0esp

        select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
        from ccsettings where setting_id = 27 -- 0 esp

        if @type=0 
        BEGIN
            insert into #CalifTemp 
            select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13
                    then case when description is not null 
                                then description 
                                else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                                end
            else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
            end end as Calificacion,
            case when count(co.califSub_id) > 0 then 1 else 0 end as Subcalificacion,co.calif_id as calif_id,count(*) cantidad,
            ISNULL(GraphColor,''1DB4E2'') GraphColor,
            CASE WHEN ISNULL(rel.calif_id, 0) = 0 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS IsSubDisp
            from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
            left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
            LEFT join cctipoSubCalifRel rel on rel.calif_id = ca.calif_id and co.califSub_id = rel.califSub_id and tipoSubRel = 0
            left join ccTipoCalifSubOUT tcsout on co.califSub_id = tcsout.califSub_id
            left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
            left join ccCamps ci on ci.cam_id = co.cam_id 
            where co.cal_inicio > @today
            and co.cam_id = @cam_id
            group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id,GraphColor, rel.calif_id
        END

        if @type=1 
        insert into #CalifTemp 
        select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
        else @nIdioma-- substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
        end as Calificacion,count(ci.califSub_id) as subCalificacion,ci.calif_id,count(*)  as total,
        ISNULL(GraphColor,''1DB4E2'') GraphColor,
        0 as IsSubDisp
        from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) 
        left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
        left join ccInbound cci on cci.inbound_id = ci.inbound_id 
        where ci.cal_inicio > @today
        and ci.inbound_id = @cam_id
        and statuscall_id = 13 
        group by description, cci.inbound_id,ci.califSub_id,ci.calif_id,GraphColor

        -- Se corrigio suma de totales -- 
        Alter table #CalifTemp add iTotal4Campaign int null

        if (select valor from ccSettings where setting_id = 78) = 0
        update #CalifTemp set iTotal4Campaign = 0

        else    
        update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign 
        from (select cam_id, sum(A.Total) iTotal4Campaign
        from #CalifTemp A group by cam_id) t join #CalifTemp c
        on t.cam_id = c.cam_id

        if @type=1 
        BEGIN
            IF(@isKolob = 1)
            BEGIN
                select tipo as Type, cast(cam_id as varchar) as CampId, calificacion as Calification, cast(subCalificacion as varchar) as SubCalificationQuantity, cast(calif_id as smallint) as CalificationId, sum( total ) as Total, GraphColor from (
                select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
                    else @nIdioma --substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                    end as Calificacion,0 as subCalificacion ,a.disposition as calif_id, COUNT(disposition) as Total,ISNULL(GraphColor,''1DB4E2'') GraphColor--,0 as iTotal4Campaign
                from ccriachats a left join ccTipoCalif b 
                on a.disposition=b.calif_id 
                where a.chatDate > @today
                and a.inboundId = @cam_id
                group by inboundId, Description, GraphColor, a.disposition
                union all
        
        
                select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                then calificacion 
                else @nIdioma --substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
                end as Calificacion,
                case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor  --iTotal4Campaign -- para ver total por campaña
                from #CalifTemp 
                group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                then calificacion 
                else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
                end, Cam_id,calif_id, iTotal4Campaign, GraphColor
                )  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id,GraphColor   order by tipo,cam_id 
            END
            ELSE
            BEGIN
                select tipo as Type, cast(cam_id as varchar) as CampId, calificacion as Calification, cast(subCalificacion as varchar) as SubCalificationQuantity, cast(calif_id as smallint) as CalificationId, sum( total ) as Total, GraphColor from (
                select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
                    else @nIdioma --substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                    end as Calificacion,0 as subCalificacion ,0 as calif_id,count(disposition) as Total,ISNULL(GraphColor,''1DB4E2'') GraphColor--,0 as iTotal4Campaign
                from ccriachats a left join ccTipoCalif b 
                on a.disposition=b.calif_id 
                where a.chatDate > @today
                and a.inboundId = @cam_id
                group by inboundId, Description, GraphColor
        
                union all
        
        
                select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                then calificacion 
                else @nIdioma --substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
                end as Calificacion,
                case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor  --iTotal4Campaign -- para ver total por campaña
                from #CalifTemp 
                group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                then calificacion 
                else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
                end, Cam_id,calif_id, iTotal4Campaign, GraphColor
            )  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id,GraphColor order by tipo,cam_id 
            END
        END
            
        if @type=0 

        select tipo as Type,Cam_id as CampId,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
        then calificacion 
        else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
        end as Calification,subCalificacion as SubCalificationQuantity, calif_id as CalificationId,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor -- , iTotal4Campaign -- para ver total por campaña
        ,IsSubDisp
        from #CalifTemp 
        group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
        then calificacion 
        else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
        end, Cam_id,subCalificacion, calif_id, iTotal4Campaign, GraphColor, IsSubDisp



        if @type = 3 begin -----entrada acd''s
            select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
            else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
            end as Calificacion,isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(*) as totales 
            from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
            left join ccInbound cci on cci.inbound_id = ci.inbound_id 
            left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
            where ci.cal_inicio > @today
            and ci.inbound_id = @cam_id
            and statuscall_id = 13 
            and ci.calif_id = @calif_id
            group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id 
        end

        if @type = 4 begin --salida campañas
                select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
                    then case when description is not null 
                                then description 
                                else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
                                end
            else case when sll.descripcion is not null 
            then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
            end end as Calificacion,isnull(cso.califSubDesc,@nIdiomaSub) ,count(*) cantidad 
            from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
            left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
            left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
            left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
            left join ccCamps ci on ci.cam_id = co.cam_id 
            where co.cal_inicio > @today
            and co.cam_id = @cam_id
            group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
        end 
     

        drop table #CalifTemp 
        set nocount off'
		EXEC(@sql)
	------------------------END ULISES ESPINOSA------------------------------------------------------------------------------------------
	------------------------Begin Jesus Gallardo 125.20230719.0.4------------------------------------------------------------------------------------------
	set @process = 'CW-8074 Alter SP ccsp_GalateaGetInboundConfiguration @command=2 ISNULL(cast(c.closeConversationTime as int), 0) [MaxAnswerTime]'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetInboundConfiguration]
@command int,
@inboundId int
AS
BEGIN

SET NOCOUNT ON;

if @command=0
begin
select descripcion from ccInbound where Inbound_id = @inboundId
end
if @command=1 -- Voice campaign
begin
	select 
	A.Inbound_id [InboundId],
	A.descripcion [Description],
	A.chat [MediaType],
	A.Status,
	isnull(gra.graphic_id,1) [Frame],
	A.tNotas,
	A.tMaxWaitCall,
	A.nMaxQue,
	A.tel_maxwait,
	A.tel_maxqueue,
	A.tel_outservice,
	A.tel_noct,
	A.ShowCalifWnd,
	A.editableCallKey [EditableCallKey],
	A.queuePosition [QueuePosition],
	A.tMaxQueueCallBack,
	A.stopRecording [StopRecording],
	A.dialPrefixOverflow [DialPrefixOverflow],
	isnull(A.callerIdDesc, '''') [CallerIdDesc],
	isnull(A.startStopRecording,0) [StartStopRecording],
	case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyAgent  else cast(0 as bit) end [CallBackSurveyAgent],
	case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyClient else cast(0 as bit) end [CallBackSurveyClient],
	case when A.cam_id > 0  and C.callsBySurvey>0 then cast(1 as bit) else cast(0 as bit) end [IsRelationSurvey],
	isnull(A.editableDtmf,0) [EditableDtmf],
	isnull(A.addDataCallBackReminder,0) [AddDataCallBackReminder],
	isnull(A.recordHold, 0) [RecordHold]
	from ccInbound A
	left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
	left join ccCamps C on C.cam_id=A.cam_id
	where A.Inbound_id=@inboundId
end
if @command=2 -- WhatsApp campaign
begin
	declare @numbers varchar(max)
	select @numbers=COALESCE(@numbers + '','', '''') + number from ccWhatsAppNumbers where inboundId = 0 and status = 1

	select i.Inbound_id [InboundId], i.descripcion [Description], i.chat [MediaType], i.Status, isnull(g.graphic_id,1) [Frame],
	ISNULL(c.conexionInfo,'''') [Number],
	ISNULL(@numbers,'''') [FreeNumbersStr],
	ISNULL(cast(c.closeConversationTime as int), 0) [MaxAnswerTime],
	ISNULL(c.answerTimeoutClient, 30) [MUTimeOutClient],
	ISNULL(c.allowFileAttachments, 0) [AllowFileAttachments],
	i.tNotas [tNotas],
	i.ExitWrapUpDisposition,
	i.ShowCalifWnd
	from ccInbound i left join ccRIAInboundGraph g on i.Inbound_id = g.Inbound_id
	left join contactMeanIn c on i.Inbound_id = c.inboundId and i.chat = 5 and c.meanContactTypeId = 5
	where i.Inbound_id=@inboundId
end
if @command=3 -- Email campaign
begin
	select 
	A.Inbound_id [InboundId],
	A.descripcion [Description],
	A.chat [MediaType],
	A.Status,
	isnull(gra.graphic_id,1) [Frame],
	A.tNotas,
	A.ShowCalifWnd,
	C.conexionInfo [ConnInfo],
	C.connUser  [ConnUserName],
	C.ConnPass [ConnPwd],
	C.isActive [IsActive],
	C.timeAlertMessage,
	C.closeConversationTime [CloseConversationTime],
	C.answerTimeOut [AnswerTimeOut],
	C.name [SenderName]
	from ccInbound A
	left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
	left join contactMeanIn C on A.Inbound_id = C.inboundId and C.meanContactTypeId=1
	where A.Inbound_id=@inboundId
end
if @command=4 -- Chat campaign
begin
	select 
	i.Inbound_id [InboundId],
	i.descripcion [Description],
	i.chat [MediaType],
	i.Status,
	isnull(ig.graphic_id,1) [Frame],
	i.tNotas,
	i.ShowCalifWnd,
	i.inactiveChatTime [InactiveChatTime],
	i.chatDomain [ChatDomain],
	i.chatTimeOverflow [ChatTimeOverflow],
	i.chatQueueOverflow [ChatQueueOverflow]
	from ccInbound i
	left join ccRIAInboundGraph ig on ig.Inbound_id=i.Inbound_id
	where i.Inbound_id =@inboundId
end

RETURN(0)

SET NOCOUNT OFF;    
END'
	EXEC(@sql)
	------------------------End Jesus Gallardo 125.20230719.0.4------------------------------------------------------------------------------------------
---------------------------------------BEGIN Jesus Gallardo hotfix/125.20230719.0.6 ---------------------------------------------------------
	SET @process = 'DEV1-397 ALTER column ccCallsIn.cal_tXfer float'
	SET @sql = 'if exists (SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = ''ccCallsIn'' and COLUMN_NAME=''cal_tXfer'' and DATA_TYPE=''tinyint''
)
begin
	ALTER TABLE ccCallsIn DROP CONSTRAINT DF_ccCallsIn_cal_tXfer;
    alter table ccCallsIn alter column cal_tXfer float;
	ALTER TABLE ccCallsIn ADD CONSTRAINT DF_ccCallsIn_cal_tXfer DEFAULT 0 FOR cal_tXfer;
end'
	EXEC(@sql)

	SET @process = 'DEV1-397 ALTER column ccCallsIn.cal_tRing float'
	SET @sql = 'if exists (SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = ''ccCallsIn'' and COLUMN_NAME=''cal_tRing'' and DATA_TYPE=''smallint''
)
begin
	ALTER TABLE ccCallsIn DROP CONSTRAINT DF_ccCallsIn_cal_tRing;
    alter table ccCallsIn alter column cal_tRing float;
	ALTER TABLE ccCallsIn ADD CONSTRAINT DF_ccCallsIn_cal_tRing DEFAULT 0 FOR cal_tRing;
end'
	EXEC(@sql)

	SET @process = 'DEV1-397 ALTER column ccCallsIn.cal_tDialog float'
	SET @sql = 'if exists (SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = ''ccCallsIn'' and COLUMN_NAME=''cal_tDialog'' and DATA_TYPE=''smallint''
)
begin
	ALTER TABLE ccCallsIn DROP CONSTRAINT DF_ccCallsIn_cal_tDialog;
    alter table ccCallsIn alter column cal_tDialog float;
	ALTER TABLE ccCallsIn ADD CONSTRAINT DF_ccCallsIn_cal_tDialog DEFAULT 0 FOR cal_tDialog;
end'
	EXEC(@sql)

	SET @process = 'DEV1-397 ALTER column ccCallsIn.cal_tNotas float'
	SET @sql = 'if exists (SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = ''ccCallsIn'' and COLUMN_NAME=''cal_tNotas'' and DATA_TYPE=''smallint''
)
begin
	ALTER TABLE ccCallsIn DROP CONSTRAINT DF_ccCallsIn_cal_tNotas;
    alter table ccCallsIn alter column cal_tNotas float;
	ALTER TABLE ccCallsIn ADD CONSTRAINT DF_ccCallsIn_cal_tNotas DEFAULT 0 FOR cal_tNotas;
end'
	EXEC(@sql)

	SET @process = 'DEV1-397 ALTER column ccoCallsOut.cal_tXfer float'
	SET @sql = 'if exists (SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = ''ccoCallsOut'' and COLUMN_NAME=''cal_tXfer'' and DATA_TYPE=''tinyint''
)
begin
	ALTER TABLE ccoCallsOut DROP CONSTRAINT DF_ccoCallsOut_cal_tXfer;
    alter table ccoCallsOut alter column cal_tXfer float;
	ALTER TABLE ccoCallsOut ADD CONSTRAINT DF_ccoCallsOut_cal_tXfer DEFAULT 0 FOR cal_tXfer;
end'
	EXEC(@sql)

	SET @process = 'DEV1-397 ALTER column ccoCallsOut.cal_tRing float'
	SET @sql = 'if exists (SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = ''ccoCallsOut'' and COLUMN_NAME=''cal_tRing'' and DATA_TYPE=''smallint''
)
begin
	ALTER TABLE ccoCallsOut DROP CONSTRAINT DF_ccoCallsOut_cal_tRing;
    alter table ccoCallsOut alter column cal_tRing float;
	ALTER TABLE ccoCallsOut ADD CONSTRAINT DF_ccoCallsOut_cal_tRing DEFAULT 0 FOR cal_tRing;
end'
	EXEC(@sql)

	SET @process = 'DEV1-397 ALTER column ccoCallsOut.cal_tDialog float'
	SET @sql = 'if exists (SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = ''ccoCallsOut'' and COLUMN_NAME=''cal_tDialog'' and DATA_TYPE=''smallint''
)
begin
	ALTER TABLE ccoCallsOut DROP CONSTRAINT DF_ccoCallsOut_cal_tDialog;
    alter table ccoCallsOut alter column cal_tDialog float;
	ALTER TABLE ccoCallsOut ADD CONSTRAINT DF_ccoCallsOut_cal_tDialog DEFAULT 0 FOR cal_tDialog;
end'
	EXEC(@sql)

	SET @process = 'DEV1-397 ALTER column ccoCallsOut.cal_tNotas float'
	SET @sql = 'if exists (SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = ''ccoCallsOut'' and COLUMN_NAME=''cal_tNotas'' and DATA_TYPE=''smallint''
)
begin
	ALTER TABLE ccoCallsOut DROP CONSTRAINT DF_ccoCallsOut_cal_tNotas;
    alter table ccoCallsOut alter column cal_tNotas float;
	ALTER TABLE ccoCallsOut ADD CONSTRAINT DF_ccoCallsOut_cal_tNotas DEFAULT 0 FOR cal_tNotas;
end'
	EXEC(@sql)

	SET @process = 'DEV1-397 ALTER Sp ccsp_AgentSetCallStatus @cal_tXfer, @cal_tring type float '
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentSetCallStatus] 
	@callout_id INT, 
    @cal_id     INT, 
    @TipoCall   TINYINT, -- 1= IN,  2=Out
    @TipoMov    TINYINT, -- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
    @cal_tXfer  float    = 0, 
    @cal_tring  float   = 0, 
    @user_id    SMALLINT   = 0, 
    @extension  VARCHAR(5) = '''', 
    @isChatCall BIT        = 0
AS
     SET NOCOUNT ON
     DECLARE @RecicleSIC TINYINT

     SELECT @RecicleSIC = ISNULL(valor, 0)
     FROM ccSettings
     WHERE setting_id = 60

     DECLARE @ANI_x VARCHAR(19)
     DECLARE @cal_inicio DATETIME
     DECLARE @callout_id_IN INT
     DECLARE @cal_key VARCHAR(20)
     DECLARE @cam_id INT
     DECLARE @cal_telefono VARCHAR(30)
     DECLARE @surveycamid INT
     DECLARE @inbound_id INT
     IF @TipoMov = 4 OR @TipoMov = 14 -- DIALOG OnDialog
         BEGIN
             IF @TipoCall = 2
                 BEGIN
                     IF @TipoMov = 4
                         BEGIN
                             UPDATE ccoCallsOUT WITH(ROWLOCK)
                               SET cal_Inicio = GETDATE(), 
                                   statusCall_id = 13, 
                                   cal_manual = CASE
                                                    WHEN @isChatCall = 1
                                                    THEN 3
                                                    ELSE cal_manual
                                                END
                             WHERE cal_id = @cal_id
                     END
                         ELSE
                         IF @TipoMov = 14
                             UPDATE ccoCallsOUT WITH(ROWLOCK)
                               SET statusCall_id = 13, 
                                   cal_tRing = @cal_tring, 
                                   user_id = case when user_id=0 and @user_id>0 then @user_id else user_id end, 
                                   cal_extension = case when cal_extension=0 and @extension>0 then @extension else cal_extension end
                             WHERE cal_id = @cal_id
                     IF @RecicleSIC = 0
                         BEGIN
                             DELETE ccoWorkingTable WITH(ROWLOCK)
                             WHERE callout_id = @callout_id

                             DELETE ccoCallPriorityOrder WITH(ROWLOCK)
                             WHERE callout_id = @callout_id
                     END
                     UPDATE ccoCallBacks
                       SET [status] = 1, 
                           schedulerStatus = 1, 
                           cal_fcallback = cal_inicio
                     FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
                     WHERE a.callout_id = b.callout_id
                           AND b.callout_id = @callout_id
                           AND b.cal_id = @cal_id
                           AND [status] = 0
                           AND statusCall_id = 13

                     -- calcula el costo de la llamada
                     EXEC ccsp_CstoCalculaCosto @cal_id

                     RETURN(0)
             END
             IF @TipoMov = 4
                 UPDATE ccCallsIN WITH(ROWLOCK)
                   SET statusCall_id = 13
                 WHERE cal_id = @cal_id

                 ELSE
                 IF @TipoMov = 14
                     UPDATE ccCallsIN WITH(ROWLOCK)
                       SET statusCall_id = 13, 
                           cal_tRing = @cal_tring, 
                           user_id = case when user_id=0 and @user_id>0 then @user_id else user_id end, 
                           cal_extension = case when cal_extension=0 and @extension>0 then @extension else cal_extension end
                     WHERE cal_id = @cal_id

             -- Elimina callback generado por abandono
             SELECT @ANI_x = cal_ani, 
                    @cal_inicio = cal_inicio
             FROM cccallsin WITH (INDEX(PK_ccCallsIn))
             WHERE cal_id = @cal_id

             SELECT @callout_id_IN = callout_id
             FROM ccRIAUpdateCallBack_Abandon
             WHERE cal_ani = @ANI_x

             UPDATE ccoCallBacks WITH(ROWLOCK)
               SET [status] = 1, 
                   schedulerStatus = 1, 
                   cal_fcallback = @cal_inicio
             WHERE callout_id = @callout_id_IN
                   AND [status] = 0

             DELETE ccoWorkingTable WITH(ROWLOCK)
             WHERE callout_id IN
             (
                 SELECT DISTINCT
                        (callout_id)
                 FROM ccRIAUpdateCallBack_Abandon WITH(ROWLOCK)
                 WHERE cal_ani = @ANI_x
             )

             DELETE ccRIAUpdateCallBack_Abandon WITH(ROWLOCK)
             WHERE cal_ANI = @ANI_x

             RETURN(0)
     END
     IF @TipoMov = 7 --OTHER OFFHook_OnXfer
         BEGIN
             IF @cal_id <= 0
                 RETURN(0)
             IF @TipoCall = 2
                 BEGIN
                     UPDATE ccoCallsOUT WITH(ROWLOCK)
                       SET statusCall_id = 16
                     WHERE cal_id = @cal_id
                     -- calcula el costo de la llamada

                     UPDATE ccoCallBacks
                       SET [status] = 2, 
                           schedulerStatus = 1, 
                           cal_fcallback = cal_inicio
                     FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
                     WHERE a.callout_id = b.callout_id
                           AND b.callout_id = @callout_id
                           AND b.cal_id = @cal_id
                           AND [status] = 0
                           AND statusCall_id = 16

                     EXEC ccsp_CstoCalculaCosto 
                          @cal_id

                     RETURN(0)
             END
             UPDATE ccCallsIN WITH(ROWLOCK)
               SET statusCall_id = 16
             WHERE cal_id = @cal_id

             SELECT @ANI_x = cal_ani, 
                    @cal_inicio = cal_inicio
             FROM cccallsin WITH (INDEX(PK_ccCallsIn))
             WHERE cal_id = @cal_id

             SELECT @callout_id_IN
             FROM ccRIAUpdateCallBack_Abandon
             WHERE cal_ani = @ANI_x

             UPDATE ccoCallBacks WITH(ROWLOCK)
               SET [status] = 2, 
                   schedulerStatus = 1, 
                   cal_fcallback = @cal_inicio
             WHERE callout_id = @callout_id_IN
                   AND [status] = 0

             RETURN(0)
     END
     IF @TipoMov = 9 --RING CallNoAnswered
         BEGIN
             IF @TipoCall = 2
                 BEGIN
                     UPDATE ccoCallsOUT WITH(ROWLOCK)
                       SET statusCall_id = 15, 
                           cal_tXFer = @cal_txFer, 
                           cal_tRing = @cal_tring
                     WHERE cal_id = @cal_id

                     -- calcula el costo de la llamada

                     UPDATE ccoCallBacks
                       SET [status] = 2, 
                           schedulerStatus = 1, 
                           cal_fcallback = cal_inicio
                     FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
                     WHERE a.callout_id = b.callout_id
                           AND b.callout_id = @callout_id
                           AND b.cal_id = @cal_id
                           AND [status] = 0
                           AND statusCall_id = 15

                     EXEC ccsp_CstoCalculaCosto @cal_id
             END

             UPDATE ccCallsIN WITH(ROWLOCK)
               SET statusCall_id = 15, 
                   cal_tXFer = @cal_txFer, 
                   cal_tRing = @cal_tring
             WHERE cal_id = @cal_id

             SELECT @ANI_x = cal_ani, 
                    @cal_inicio = cal_inicio
             FROM cccallsin WITH (INDEX(PK_ccCallsIn))
             WHERE cal_id = @cal_id

             SELECT @callout_id_IN
             FROM ccRIAUpdateCallBack_Abandon
             WHERE cal_ani = @ANI_x

             UPDATE ccoCallBacks WITH(ROWLOCK)
               SET [status] = 2, 
                   schedulerStatus = 1, 
                   cal_fcallback = @cal_inicio
             WHERE callout_id = @callout_id_IN
                   AND [status] = 0

             RETURN(0)
     END
     SET NOCOUNT OFF'
	EXEC(@sql)

	SET @process = 'DEV1-397 ALTER SP ccsp_AgentUpdateCallTimes, @cal_tXfer,@cal_tRing,@cal_tDialog,@cal_tNotas type float'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentUpdateCallTimes]
@IDCall int,
@cal_tXfer float,
@cal_tDialog float,
@cal_tNotas float,
@TipoCall tinyint,
@cal_tRing float=0,
@mtmoh smallint = 0,
@isChatCall bit = 0,
@isErroManualCall bit =0,
@isTransferEngine bit =0
AS
set nocount on
if @IDCall<=0 
	return(0)

declare @tMinAVRS smallint
declare @cal_manual int
declare @minimoDialogo tinyint 
select @minimoDialogo = valor from ccSettings where setting_id = 13

set @cal_manual=0

if @TipoCall=1 begin--INBOUND
	if @cal_tDialog < @minimoDialogo and @isTransferEngine =1 begin
	--el status 18 es para llamada cortada con transferencia en Reminder
	exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @IDCall, @nStatus = 18
	end
	Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, 
	cal_tDialog=case when @cal_tDialog > 0 and @cal_tDialog > cal_tDialog then @cal_tDialog else cal_tDialog end, 
	cal_tNotas=@cal_tNotas, 
	cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, 
	cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end
	Where cal_id= @IDCall

	--Actualizar tiempo total de llamada
	exec ccsp_EngineLogTransfers 2, @IDCall, @TipoCall, 2, null, @cal_tXfer, @cal_tDialog

	-- Elimina callback generado por abandono
  
	if @isTransferEngine = 0  begin
	Declare @ANI_x varchar(19)
	select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

	DELETE ccoWorkingTable with(rowlock ) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
	end
end
else if @TipoCall=2 begin--OUTBOUND 
	

	Update ccoCallsOUT with(rowlock) Set cal_tXfer=case when @cal_tXfer > 0 then @cal_tXfer else cal_tXfer end, 
	cal_tRing=case when @cal_tRing > 0 then @cal_tRing else cal_tRing end, 
	cal_tDialog=case when @cal_tDialog > 0 and @cal_tDialog > cal_tDialog then @cal_tDialog else cal_tDialog end, 
	
	cal_tNotas=case when @cal_tNotas > 0 then @cal_tNotas else cal_tNotas end, 
	cal_tMoh=case when @mtmoh > 0 then @mtmoh else cal_tMoh end,
	
	cal_manual=case when @isChatCall=1 then 3 else cal_manual end,
	cal_colgada=0, statusCall_id=case when @isErroManualCall=0 then 13 else statusCall_id end,
	totalCall_Time=case when totalCall_Time is null then @cal_tDialog else totalCall_Time end 
	Where cal_id=@IDCall
	
	-- calcula el costo de la llamada
	exec ccsp_CstoCalculaCosto @IDCall
	select @cal_manual=cal_manual from ccoCallsOUT with(nolock) Where cal_id=@IDCall

	end

select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

if @cal_tDialog >= @tMinAVRS and @cal_manual<>1
	and not exists(select * from ccAVRSTransfer where cal_id=@IDCall and tipo=@TipoCall - 1) 
	begin 
		insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
end

return(0)

set nocount off'
	EXEC(@sql)

	SET @process = 'DEV1-397 ALTER SP ccsp_GalateaAdminInbound --> DlgsAveTime =CONVERT(int, ISNULL(SUM (CASE WHEN statusCall_id = 13 THEN cal_tDialog + cal_tNotas ELSE 0 END), 0)),'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT, 
                                            @InboundId AS SMALLINT = 0,
											@User_id AS SMALLINT = 0,
											@OutboundID AS SMALLINT = 0,
											@multi_cam as varchar(max) = null
AS
BEGIN
	set nocount on;

	if(@Option = 1) -- Por campaña 
	begin
	    select 
	        ISNULL(count (*), 0) as Calls,
	        ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
	        ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
	        ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
	        ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
	        ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
	        ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
	        ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
	        ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
	        ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
	        THEN 1 ELSE NULL END), 0) AS Other
	    from ccCallsIn a (nolock)
	    where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) and a.inbound_id = @InboundId

	end

	if(@Option = 2) -- Todas las campañas 
	begin
	    select 
			inbound.Inbound_id as IDEspec,
			inbound.descripcion as Name,
	        ISNULL(count (*), 0) as Calls,
	        ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
	        ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
	        ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
	        ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
	        ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
	        ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
	        ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
	        ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
	        ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
	        THEN 1 ELSE NULL END), 0) AS Other
	    from ccCallsIn a (nolock)
		left join ccInbound inbound on a.inbound_id = inbound.Inbound_id
	    where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) 
		group by inbound.Inbound_id, inbound.descripcion
	end

	if(@Option = 3) -- Obtiene los datos de las llamadas de todos los ACD, datos que se muestran en el tablero de información del administrador 
	begin
		SELECT 
			a.inbound_id, calls = ISNULL(COUNT(*), 0), -- calls
			Dialogs = ISNULL(COUNT (CASE WHEN statusCall_id = 13 THEN 1 ELSE NULL END), 0), -- Answered
			DlgsAveTime =CONVERT(int, ISNULL(SUM (CASE WHEN statusCall_id = 13 THEN cal_tDialog + cal_tNotas ELSE 0 END), 0)),
			QueueAveTime =ISNULL( avg( CASE WHEN cal_que > 0 THEN cal_tWait ELSE NULL END), 0) ,
			abandon = ISNULL(COUNT(CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0), -- Abandoned
			OverFlowQueue = ISNULL(COUNT (CASE WHEN statusCall_id =8 THEN 1 ELSE NULL END), 0),
			OverFlowTimeOut = ISNULL(COUNT (CASE WHEN statusCall_id =7 THEN 1 ELSE NULL END), 0), -- OverFlowQueue+OverFlowTimeOut = not answered
			outOfSchedule = ISNULL(COUNT (CASE WHEN statusCall_id =2 THEN 1 ELSE NULL END), 0), -- fuera de horario
			outOfService = ISNULL(COUNT (CASE WHEN statusCall_id =3 THEN 1 ELSE NULL END), 0), -- fuera de servicio
			noAgentsLoggedIn = ISNULL(COUNT (CASE WHEN statusCall_id =4 THEN 1 ELSE NULL END), 0), -- sin agentes firmados
			assigned = ISNULL(COUNT (CASE WHEN statusCall_id =11 THEN 1 ELSE NULL END), 0), -- asignada
			--assignedAndNotAnswered = ISNULL(COUNT (CASE WHEN statusCall_id =15 THEN 1 ELSE NULL END), 0), -- asignada y no contestada
			--assignedAndTookLine = ISNULL(COUNT (CASE WHEN statusCall_id =16 THEN 1 ELSE NULL END), 0), -- asignada y toma linea
			callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0)
			--onQueue = ISNULL(COUNT(CASE WHEN statusCall_id = 5 THEN 1 ELSE NULL END), 0)
			--initCalls = CAST(ISNULL(COUNT(CASE WHEN statusCall_id = 1 THEN 1 ELSE NULL END), 0) AS varchar(7))+''|''+
			--			ISNULL((SELECT STUFF((SELECT ''|'' + cast(ci.cal_id AS varchar(7))
			--			FROM ccCallsin ci (nolock) WHERE cal_inicio > dateadd(mi,-5,getdate()) AND ci.inbound_id=a.inbound_id
			--			FOR XML PATH('''')) ,1,1,'''')),''0'')
		FROM ccCallsIn a (nolock)
		WHERE cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))
				--and a.inbound_id in (select cam_id from ccSupervisorCam where user_id = @User_id and tipo = 0)
		GROUP BY a.inbound_id
	--	SET nocount off
	--	return(0)
	end

	if(@Option = 4) -- Carga los ACD del administrador mandado
	begin
		SELECT cam_id 
		FROM ccSupervisorCam  nolock
		WHERE user_id = @User_id and tipo = 0
		SET nocount off
		return(0)
	end

	IF(@Option = 5) -- Relate the inbound campaign with the outbound campaign
	BEGIN
		IF(@multi_cam is not null)
		BEGIN
			UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id IN (
				SELECT value from dbo.fn_RIASplitDelimited(@multi_cam,'',''))
			SELECT 1;
			RETURN 1;
		END
		IF((SELECT ISNULL(cam_id,-1) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId) != -1)
			BEGIN
				SELECT -1;
				RETURN -1;
			END;
		ELSE
			BEGIN
				UPDATE ccInbound SET cam_id = @OutboundID WHERE Inbound_id = @InboundID;
				SELECT 1;
				RETURN 1;
			END;
	END;        
	IF(@Option = 6) -- Delete the relation between inbound and outbound campaigns
	BEGIN
		UPDATE ccInbound SET cam_id = null WHERE Inbound_id = @InboundId;
		SELECT 1;
		RETURN 1;
	END;
	IF(@Option = 7) -- Check if the inbound Campaign is related
	BEGIN
		SELECT CAST(ISNULL(cam_id,-1) AS INT) AS outboundId FROM ccInbound nolock WHERE Inbound_id = @InboundId;
	END
	IF(@Option = 8) -- Delete the relation between inbound campaings which are related to outdbound campaign
	BEGIN
		UPDATE ccInbound SET cam_id = null WHERE cam_id = @OutboundID;
		SELECT 1;
		RETURN 1;
	END
END'
	EXEC(@sql)

	SET @process = 'DEV1-397 ALTER SP ccsp_GetAgentIndividualCounters convert(int,sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end)) tDialog,
	sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end) tWrapup,'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters]
@type as int, @sup_id as int = 0 as
set nocount on

declare @fecha_ini datetime
select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

if @type = 1 --Session time
    begin
        SELECT User_id, case
            WHEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0
                THEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))
            ELSE sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) +
                convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14)))
            END as logintime
        FROM ccLogLogin a with(nolock,index(IX_ccLogLogin_4)), ccGenViewRelsSupsAgent b
        where fecha >= @fecha_ini
        and a.User_id = b.agt
        and b.sup = @sup_id
        GROUP BY User_id
    end

else if @type = 2 begin--Status agent
    
    ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login 
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where 
        wgAdmin.User_id=@sup_id
    )

    select User_id,TipoStatusAge_id,sum(segundos) as segundos from (
    SELECT User_id, TipoStatusAge_id, tStatus As segundos
    FROM ccLogAgentesDia a with(nolock,index(IX_ccLogAgentesDia_4))
    inner join TableUserAgent b  on  a.User_id = b.userId   
    WHERE fecha >= @fecha_ini   
    union all   
    select A.User_id,
    case when A.TipoStatusAge_id in(0,1) then 3
    when A.currentStatus in (21,5,9) then 4
    else A.currentStatus end as TipoStatusAge_id,
    DATEDIFF(ss,A.fecha,getdate()) as seconds   
    from ccLogAgentesDia A with(nolock)
    inner join
    (select max(fecha) fecha,USER_ID from ccLogAgentesDia D with(nolock,index(IX_ccLogAgentesDia_4))
    inner join TableUserAgent C on D.User_id=C.userId
    where fecha >= @fecha_ini    
        group by User_id) B
    on A.User_id=B.User_id and A.fecha=B.fecha and A.currentStatus not in (0,-2)

    )x
    group by User_id,TipoStatusAge_id
    ORDER BY User_id

end

else if @type = 3 begin

    ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login 
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where 
        wgAdmin.User_id=@sup_id
    )

    select calls.user_id, calls.total_calls, calls.type_calls, users.login, calls.nCalls, calls.tDialog, calls.tWrapup, calls.tHold 
    from ccusers As users ,
        (
            select calls.User_id, count(*) AS ''total_calls'',
            CASE
            WHEN statuscall_id = 15 THEN 5  --OutBound Asignada pero no contestada
            WHEN cal_manual = 2 THEN 3      --OutBound llamada manual
            ELSE 2                          --Llamada de OutBound
            END AS ''type_calls'',      
            count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
            convert(int,sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end)) tDialog,
            convert(int,sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end)) tWrapup,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold
            from TableUserAgent as tAgent
            inner join ccoCallsOut calls WITH (NOLOCK index(IX_ccoCallsOut_10))   
            on tAgent.userId=calls.User_id
            WHERE statuscall_id <> 11  --OutBound sin estado definitivo
            AND cal_inicio >= @fecha_ini
            GROUP BY User_id, statuscall_id, cal_manual--,tAgent.login
        
            union

            select calls.User_id, count(*) AS ''total_calls'',
            CASE
            WHEN statuscall_id = 15 THEN 4  --InBound Asignada pero no contestada
            ELSE 1                          --Llamada de InBound
            END AS ''type_calls'',      
            count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
            convert(int,sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end)) tDialog,
            convert(int,sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end)) tWrapup,
            sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold

            from TableUserAgent as tAgent
            inner join ccCallsIn calls WITH (NOLOCK index(IX_ccCallsIn_5)) 
            on tAgent.userId=calls.User_id
            WHERE statuscall_id <> 11  --OutBound sin estado definitivo
            AND cal_inicio >= @fecha_ini
            GROUP BY User_id, statuscall_id--,tAgent.login
        ) AS calls
        where users.user_id = calls.user_id     

    end

else if @type = 4
    begin
        
        ;
    WITH TableUserAgent (userId)
    AS
    (
        select distinct wgAgt.User_id as userId --,usr.login 
        from ccriaworkgroupusers wgAdmin
        inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
        inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
        where 
        wgAdmin.User_id=@sup_id
    )


        select a.user_id, a.login
        from ccusers a (nolock)--, ccGenViewRelsSupsAgent b
        inner join TableUserAgent b on a.User_id=b.userId       
    end
else if @type = 5
    begin          
	declare @users table(userId int primary key)


	if exists(select * from ccUsers_Roles where User_id=@sup_id and Rol_id=1 ) begin
		insert into @users
		select user_id from ccUsers where TipoUser_id=1
	end
	else begin
		
		insert into @users
		select distinct wgAgt.User_id as userId --,usr.login 
		from ccriaworkgroupusers wgAdmin
		inner join ccriaworkgroupusers wgAgt on wgAdmin.IDWG=wgAgt.IDWG 
		inner join ccUsers usr on usr.User_id = wgAgt.User_id and usr.TipoUser_id=1
		where 
		wgAdmin.User_id=@sup_id 
	end

	SELECT cast(User_id AS INT) UserId
		,sum(CASE WHEN TipoStatusAge_id = 2 THEN tStatus ELSE 0 END) NotReady
		,sum(CASE WHEN TipoStatusAge_id = 3 THEN tStatus ELSE 0 END) Ready
		,sum(CASE WHEN TipoStatusAge_id = 4 THEN tStatus ELSE 0 END) Dialog
		,sum(CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE 0 END) XFer
		,sum(CASE WHEN TipoStatusAge_id = 6 THEN tStatus ELSE 0 END) Wrapup
		,sum(CASE WHEN TipoStatusAge_id = 7 THEN tStatus ELSE 0 END) Other
		,sum(CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE 0 END) Ringing
		,sum(CASE WHEN TipoStatusAge_id = 11 THEN tStatus ELSE 0 END) Problem
		FROM ccLogAgentesDia A with(nolock)
		inner join @users B on A.User_id=B.userId
		WHERE fecha >= @fecha_ini
			AND TipoStatusAge_id > 0
		GROUP BY User_id 

  
    end
set nocount on'
	EXEC(@sql)

	SET @process = 'DEV1-397 ALTER SP ccsp_SaveStatusAgent @tStatus y  @tDialog'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus float,
@TipoCall  tinyint,
@Camp smallint,
--@isTransferSurvey bit=0, --0 Callback, 1 Realiza Transferencia inmediata
@callout_id int=0,
@call_id int=0,
@isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
@tDialog float =0 ,
@currentStatus int =-2,--NUEVO PAR?METRO PARA LA NUEVA COLUMNA
@Fecha4 datetime=null,
@tMusicHold int =0,
@isTransferEngine bit = 0
AS

if @Fecha4 is null set @Fecha4 = getdate()

if @TipoCall > 0 set @TipoCall = @TipoCall - 1

if (@User_id > 0 ) begin

declare @cam_id int,@surveycamId int
declare @cal_telefono varchar(30)
declare @cal_key varchar(40)
declare @inbound_id int
declare @callBackSurveyClients bit
declare @cal_whoHung tinyint
declare @cal_tDialog int
declare @cal_tNotas float
declare @cal_tNotaOri int
declare @tMinAVRS smallint
declare @calInicio datetime
declare @sumCall float
declare @cal_manual int 

set @cal_tNotas =0
set @cal_tNotaOri=0

if @TipoStatusAge_id=32 set @tStatus=CONVERT(DECIMAL(10,2), ROUND(@tStatus, 0, 1))
--4 Dialog,6 Notas, 27 Notas Fallida
if @TipoStatusAge_id in (4,6,27) and @call_id>0 begin
if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas


set @cal_manual =0

if @TipoCall = 0 begin --IN

select @calInicio=cal_Xfer,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas, @Camp=Inbound_id, @cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas, @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani ,@cal_whoHung=cal_whoHung
        from ccCallsIN with(index(IX_ccCallsIn_6),nolock) where cal_id = @call_id and statusCall_id = 13

if @cal_tDialog = 0 and @tDialog >0  and @isLogout=1  begin
    if @Fecha4<DATEADD(ms,( @sumCall+@tDialog+@cal_tNotas)*1000,@calInicio) begin
    set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
    if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
    if @TipoStatusAge_id=6  begin
        if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
        else  set @tDialog=@tDialog-1
    end
    end
    update ccCallsIN with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas,cal_tMoh=@tMusicHold where cal_id = @call_id and statusCall_id = 13
end
end
else begin --OUT
select @calInicio=cal_inicio,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,
@cam_id = cam_id,@cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas from ccoCallsOut where cal_id = @call_id
set @Camp=@cam_id

if @cal_tDialog = 0 and @tDialog>0 and @isLogout=1  begin
    if @Fecha4<DATEADD(ms,( @sumCall+@tDialog+@cal_tNotas)*1000,@calInicio) begin
    set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
    if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
    if @TipoStatusAge_id=6  begin
        if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
        else  set @tDialog=@tDialog-1
    end
    end

    update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog, cal_tNotas=@cal_tNotas,cal_tMoh=@tMusicHold where cal_id = @call_id and statusCall_id = 13
end
else if @TipoStatusAge_id=4 and @cal_tDialog = 0 and @tDialog>0
    update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog  where cal_id = @call_id
else if @TipoStatusAge_id=6 and @cal_tNotaOri = 0 and @cal_tNotas>0
    update ccoCallsOut with(rowlock) set cal_tNotas=@cal_tNotas where cal_id = @call_id
end

select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1 and @cal_manual<>1 begin
    insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
end

if @TipoStatusAge_id in(6,27)  and @isLogout=1  begin
--Valida que el agente no pudo guardar el status antes de desloguear
if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4) and @Fecha4 )
    INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
end


end


if (@TipoStatusAge_id=4) begin-- 4 = Dialogo
declare @tStatus3 float, @Fecha3 datetime
select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia with(nolock) where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
insert into ccLogAgentesDia_Dialog (User_id,Cam_id,fecha_Calc_ms,tStatus_Dispo,fecha_Dispo,tStatus_Dialog,fecha_Dialog)
select @User_id, cam_id, datediff(ms, dateadd(ms, -(@tStatus3*1000), @Fecha3), dateadd(ms, -(@tStatus3*1000), @Fecha4)), @tStatus3, @Fecha3, @tStatus, @Fecha4
from cccampsagente where user_id = @User_id


---Agregar callback en caso de este activo setting en campa?as o acd y tenga relacion de campa?a de encuesta
if @call_id>0 begin
if @TipoCall = 0 begin --IN

    select @surveycamid = isnull(cam_id,0),@callBackSurveyClients = callBackSurveyClient  from ccinbound where inbound_id = @inbound_id

    if @surveycamId>0  and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
        if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
        begin
            if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100
            begin
            insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
            values(right((cast(@call_id as varchar) + '''' + @cal_Key),40),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()) )
            end
        end
    end
end --@TipoCall = 0
else begin  --OUT



    select @surveycamId = isnull(surveycamid,0),@callBackSurveyClients= callBackSurveyClient from cccamps where cam_id = @cam_id
    select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono,@cal_whoHung=cal_whoHung
    from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
    where callout_id = @callout_id and statusCall_id = 13 and cal_id = @call_id

    if @surveycamId>0 and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
    if (select surveyPctg from ccCamps where cam_id = @surveycamId) >= rand() *100
    begin
        insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
        values(right((cast(@call_id as varchar) + '''' + @cal_Key),40),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()))
    end
    end
end
end--@isTransferSurvey = 0 and @callout_id>0


end

if @TipoCall = 0 and @isLogout = 1  and @isTransferEngine = 1 begin --IN
declare @minimoDialogo tinyint 
select  @minimoDialogo = valor from ccSettings where setting_id = 13
if @cal_tDialog < @minimoDialogo
    begin
    --el status 18 es para llamada cortada con transferencia en Reminder
    exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @call_id, @nStatus = 18
end

end 

if @TipoStatusAge_id =6  and @isLogout=0
begin
--Valida que el ccserver no haya guardado antes el status antes al desloguear
if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-10,@Fecha4) and @Fecha4 and tStatus = @tStatus+1)
    INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )
end
else
INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)  VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )

if ( @TipoStatusAge_id = 2 )   -- 2 = No Disponible
begin
INSERT ccLogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha, IdCampEsp, Tipo )
VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4, @Camp, @TipoCall )

---Para Agente RIA: OAYC
INSERT ccRIALogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha )
VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4 )
end

-- Actualiza para reporte de tiempos especiales (Boan)
if @Camp > 0
begin
if exists (select * from ccLogAgentesDia with(index(IX_ccLogAgentesDia_5),nolock)
        where IdCampEsp = 0 and user_id = @User_id)
    begin
    update ccLogAgentesDia with(rowlock)
    set IdCampEsp = @Camp, Tipo = @TipoCall
    where IdCampEsp = 0
    and user_id = @User_id
    end

if exists (select * from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_4),nolock)
        where IdCampEsp = 0 and user_id = @User_id)
    begin
    update ccLogAgentesNotReady with(rowlock)
    set IdCampEsp = @Camp, Tipo = @TipoCall
    where IdCampEsp = 0
    and user_id = @User_id
    end
end

if ( @TipoStatusAge_id = 34  and @call_id > 0) -- Dialogo WhatsApp
begin
	if @TipoCall=0 begin
		update ccWhatsAppConversations set tChatting = (tChatting + @tStatus) where conversationId = @call_id;
		set @Camp = (select inboundId from ccWhatsAppConversations  where conversationId = @call_id);
		EXEC ccsp_WhatsAppInformation @Option = 2, @InboundId = @Camp
	end
	else begin
		update ccWhatsAppConversationsOut set tChatting = (tChatting + @tStatus) where conversationId = @call_id;
		set @Camp = (select camId from ccWhatsAppConversationsOut  where conversationId = @call_id);
		EXEC ccsp_WhatsAppInformationOut @Option = 2, @camId = @Camp
	end
end
end'
	EXEC(@sql)


	---------------------------------------END Jesus Gallardo hotfix/125.20230719.0.6-----------------------------------------------------------

	---------------------------------------Begin Jesus Gallardo hotfix/125.20230719.0.7-----------------------------------------------------------
	SET @process = 'CW-8077 Alter SP ccsp_InsertDNCList se agrega validacion para no insertar telefonos vacios select * from #mytempCall where [telefono]<>@phoneEmpty'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL
WITH RECOMPILE
AS


declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)
,@tel10 as varchar(30),@tel11 as varchar(30)

insert into cclistanegra(telefono,idtipolista,HashKey, calKey) values(@telephone, @ln_id,@hashCalKey, @calKey)

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall


CREATE TABLE [dbo].[#mycamps] (	[campsid] [int] NULL)

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id and B.CampType not in(7,5)

CREATE TABLE [dbo].[#myprincipaltempCall](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE CLUSTERED INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltempCall]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltempCall]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltempCall]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltempCall]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltempCall]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltempCall]([cal_telefono5]) 

CREATE TABLE [dbo].[#mytempCall](
	[callout_id] [int] NULL, 
	[telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempCall]([callout_id]) 

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @tel = dbo.completa(@telephone, @pais, @ld)

set @tel10=RIGHT(@tel,10)
set @tel11=RIGHT(@tel,11)

declare @fech datetime = getdate()-30
if @hashCalKey is not null and @hashCalKey > 0
begin

	insert into [#myprincipaltempCall] 
	SELECT a.callout_id as callout_id, a.cam_id,3,@ln_id as idtipolista , a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
	FROM [ccoCallsOutSource] as a, #mycamps as b with(nolock) 
	WHERE a.cam_id = b.campsid 
	AND dbo.hashList(cal_Key) = @hashCalKey and  cal_fechadial > @fech  
end
else begin
	insert into [#myprincipaltempCall]
	SELECT a.callout_id as callout_id, a.cam_id,''3'',cast(@ln_id as nvarchar) as idtipolista , a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
	FROM [ccoCallsOutSource] as a, #mycamps as b with(nolock) 
	WHERE a.cam_id = b.campsid	
	and (@tel  IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) 
	or @tel10 IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) 
	or @tel11 IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5])) 
	and  cal_fechadial > @fech  
end


if EXISTS (select * from #myprincipaltempCall)
begin
	declare @column nvarchar(max), @sql nvarchar(max)
	,@sqlDeleteWorking nvarchar(max)
	,@sqlUpdateWorking nvarchar(max)
	,@sqlCaseWorking nvarchar(max)
	,@params nvarchar(max)
	,@phoneEmpty varchar(1)
	,@sqlWithReplace nvarchar(max)

	set @phoneEmpty=''''
	set @column=''cal_telefono''
	set @params=''@tel varchar(30),@tel10 varchar(30),@tel11 varchar(30),@phoneEmpty varchar(1),@fech datetime''
	set @sqlDeleteWorking=''and cs.cal_telefono2=@phoneEmpty
	and cs.cal_telefono3=@phoneEmpty
	and cs.cal_telefono4=@phoneEmpty
	and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono2<>@phoneEmpty then cs.cal_telefono2 
	when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
	when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
	when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
	else @phoneEmpty end ''

	set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
	update wt 
	set cal_telefono = CASE_UPDATE_WT
	from ccoCallsOutSource cs 
	inner join ccoWOrkingTable wt on cs.callout_id = wt.callout_id
	inner join #mytempCall t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > @fech and cs.COLUMN_CHECK= wt.cal_telefono''

	set @sql=''insert #mytempCall
select callout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempCall] with(nolock)
where cal_telefono in(@tel,@tel10,@tel11)

if EXISTS (select * from #mytempCall)
begin		
	-- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
	delete wt with(rowlock)
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytempCall t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > @fech and
	cs.COLUMN_CHECK = wt.cal_telefono
	AND_DELETE_WT

	UPDATE_SMS_WT_QUERY

	--insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytempCall where [telefono]<>@phoneEmpty

	-- Eliminamos el telefono1 de CS
	update ccoCallsOutSource 
	set COLUMN_CHECK = @phoneEmpty
	from ccoCallsOutSource cs 
	inner join #mytempCall t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > @fech		

	truncate table #mytempCall
end''

	
	/******************/
	/*** Telefono 1 ***/
	/******************/
	
	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)	
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech	

	/******************/
	/*** Telefono 2 ***/
	/******************/
	set @column=''cal_telefono2''
	
	set @sqlDeleteWorking='' and cs.cal_telefono3=@phoneEmpty
		and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
		when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech

	/******************/
	/*** Telefono 3 ***/
	/******************/
	set @column=''cal_telefono3''
	
	set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech
	
	/******************/
	/*** Telefono 4 ***/
	/******************/	
	
	set @column=''cal_telefono4''
	
	set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech
	
	/******************/
	/*** Telefono 5 ***/
	/******************/

	set @column=''cal_telefono5''	
	set @sqlDeleteWorking='' and cs.cal_telefono5=@phoneEmpty''	
	set @sqlCaseWorking=''''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',''''),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech

end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall'
	EXEC(@sql)

	SET @process = 'DEV1-436 Alter SP CofetelActions se valida @type = 2 que no este vacia para truncate table Series'
	SET @sql = 'ALTER PROCEDURE [dbo].[CofetelActions]
@type tinyint
as
if @type = 1
begin
	truncate table SeriesTmp
end
		
if @type = 2
begin
	if exists(select * from SeriesTmp) begin
		truncate table Series
	end
end
		
declare @ret bit
set @ret = 1
		
select @ret'
	EXEC(@sql)

	SET @process = 'DEV1-436 Alter SP CofetelUpdateData Valida que este vacia Series para insertar los registros @type = 1'
	SET @sql = '
ALTER PROCEDURE [dbo].[CofetelUpdateData]
@type tinyint
as
if @type = 1
begin
	if not exists(select * from Series) begin
		insert into Series
		select * from SeriesTmp
	end
end
		
declare @ret bit
set @ret = 1
		
select @ret'
	EXEC(@sql)
	
	---------------------------------------END Jesus Gallardo hotfix/125.20230719.0.7-----------------------------------------------------------
	---------------------------------------Begin Ivan Martin hotfix/125.20230719.0.7-----------------------------------------------------------
	SET @process = 'Se quita procedure ccspOutboundSmsMessage'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccspOutboundSmsMessage'')
				BEGIN
				    DROP PROCEDURE ccspOutboundSmsMessage;
				END'
	EXEC(@sql)

	SET @process = 'Se agrega action 9 para revertir el status de mensajes que no se procesaron bien'
	SET @sql = 'CREATE procedure [dbo].[ccspOutboundSmsMessage] 
				@action int,
				@camId int = null,
				@SentMsg int=null,
				@smsoutIds varchar(max)=null,
				@SystemApiId varchar(100)=null,
				@statusSystemsId int =null,
				@InsufficientBalance int=null,
				@date datetime =null
				as
				declare @sql varchar(max)
				if @action=1 begin
					select cast(cam_id as int) as CamId,cam_descripcion as [Name],cam_procesando as [Start] 
					from ccCamps where CampType=7 and IDArea is not null and( @camId is null or cam_id=@camId)
				end
				else if @action=2 begin
					select tz_offset from ccTimeZones ORDER BY tz_id
				end
				else if @action=3 begin
					select cast(camId as int) CamId,SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected 
					from ccSmsConversationsResult where ( @camId is null or camId=@camId)
				end
				else if @action=4 begin
					truncate table ccSmsConversationsResult
				end
				else if @action=5 begin
					if not exists(select * from ccSmsConversationsResult where camId=@camId) begin
						insert into ccSmsConversationsResult values(@camId,@SentMsg,0,0,0,0,@InsufficientBalance)
					end
					else begin
						update ccSmsConversationsResult set SentMsg=SentMsg+@SentMsg 
						,InsufficientBalance=InsufficientBalance+@InsufficientBalance
						where camId=@camId
					end
				end
				else if @action=6 begin	
					set @sql=''declare @listCamId table(camId int,status bit)

				declare @camId int
				insert into @listCamId
				select distinct cam_id,0 from smsWorkingTable with(nolock) where smsout_id in(''+@smsoutIds+'')

				while exists(select * from @listCamId where status=0)begin
					select top 1 @camId=CamId from @listCamId where status=0
					
					exec ccsp_GalateaGetCampsNvosCB @cam_id=@camId,@Tipo=2,@regval=1
					update @listCamId set status=1 where status=0 and @camId=CamId 
				end
				delete from smsWorkingTable where smsout_id in(''+@smsoutIds+'')
					''
					exec (@sql)
				end
				else if @action=7 begin
					declare @statusSystemsIdOld int
					declare @ccSmsConversationsResult table(camId int,statusSystemsId int,description varchar(255), value int)
					select top(1) @camId =cam_id,@statusSystemsIdOld=statusSystemsId from smsccoLogDial with(nolock) where SystemApiId=@SystemApiId
					update smsccoLogDial set statusSystemsId=@statusSystemsId where SystemApiId=@SystemApiId
					
					insert into @ccSmsConversationsResult
					select camId, ROW_NUMBER() OVER(ORDER BY camId ASC)-1 AS statusSystemsId, description,value
					from ccSmsConversationsResult
					unpivot
					(
						value
						for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected,InsufficientBalance)
					) unpiv
					where camId= @camId

					update @ccSmsConversationsResult set value =case when value>0 then value-1 else 0 end where statusSystemsId=@statusSystemsIdOld
					update @ccSmsConversationsResult set value =value+1 where statusSystemsId=@statusSystemsId
					
					;with res as(
					select * from 
					(
						select camId, description, value
						from @ccSmsConversationsResult 
					) src
					pivot
					(
					sum(value)
					for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected,InsufficientBalance)
					) piv
					)

					update B 
					set B.SentMsg=A.SentMsg
					,B.Delivered=A.Delivered
					,B.NotDelivered=A.NotDelivered
					,B.RecipientRejected=A.RecipientRejected
					,B.CarrierRejected=A.CarrierRejected
					,B.InsufficientBalance=A.InsufficientBalance
					from
					res A
					inner join ccSmsConversationsResult B on A.camId=B.camId
				end
				else if @action=8 begin
					update smsccoLogDial set Bill=0.70 where smsDate>=@date and statusSystemsId not in(4,5)
				end
				else if @action=9 begin
					CREATE TABLE #TempSmsOutIds (
				    smsout_id INT
					);

					INSERT INTO #TempSmsOutIds (smsout_id)
					SELECT DISTINCT wt.smsout_id
					FROM smsWorkingTable wt
					JOIN smsOutSource os ON wt.smsout_id = os.smsout_id
					LEFT JOIN smsccoLogDial cco ON wt.smsout_id = cco.smsout_id
					WHERE wt.sms_status IN(1,2) 
					AND cco.smsout_id IS NULL;

					UPDATE wt
					SET wt.sms_status = 0
					FROM smsWorkingTable wt
					JOIN #TempSmsOutIds temp ON wt.smsout_id = temp.smsout_id;

					DROP TABLE #TempSmsOutIds;
				end'
	EXEC(@sql)
	---------------------------------------End Ivan Martin hotfix/125.20230719.0.7-----------------------------------------------------------
	---------------------------------------Start Jonathan Ramírez hotfix/125.20230719.0.8-----------------------------------------------------------
	SET @process = '1 - HU(KR098000) - 0719.0.8 - JR - Create new table ccSettings2';
	SET @sql = '
	IF NOT EXISTS(SELECT * FROM sys.tables WHERE name=''ccSettings2'') BEGIN
		CREATE TABLE ccSettings2(
			setting_id smallint NOT NULL,
			valor varchar(300),
			descripcion varchar(150) NOT NULL,
			Status tinyint,
			Tipo varchar(3),
			detalle varchar(600),
			description varchar(600),
			bLoadSettings bit,
			validate varchar(255)
		);
	END
	';
	EXEC(@sql)

	SET @process = '2 - HU(KR098000) - 0719.0.8 - JR - Create new view VIEW_SETTINGS';
	SET @sql = '
	CREATE VIEW [dbo].[VIEW_SETTINGS]
		AS
		SELECT setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate FROM ccSettings 
		UNION
		SELECT setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate FROM ccSettings2
	';
	EXEC(@sql);

	SET @process = '3 - HU(KR098000) - 0719.0.8 - JR - Create new setting 257';
	SET @sql = '
	IF NOT EXISTS (SELECT * FROM ccSettings2 WHERE setting_id = 257) BEGIN
		INSERT INTO	ccSettings2 (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate)
		VALUES (
		257, 
		''5|3000|5'',
		''Número de campañas con cargas simultáneas de registros | Número de registros a cambiar de ‘pendientes’ a ‘nuevos’ por campaña | Tiempo límite de carga'', 
		1, 
		''GRL'', 
		''Carga de Registros Pendientes a Nuevos. Cantidad de campañas simultaneas | Limite de Registros por campaña 
		| Tiempo limite de carga'', 
		''Number of campaigns that can load records simultaneously I Number of records by campaign that 
		can be switched from ‘pending’ to ‘new’ | Load timeout.'', 
		0, 
		''^\d{1,2}\|\d{1,4}||\d{1,2}$'');
	END
	';
	EXEC(@sql);

	SET @process = '4 - HU(KR098000) - 0719.0.8 - JR - Alter SP ccsp_RIAOUTInsertNewJOBS_WT_Camp, add var (recordsQuantitySetting, settingValueP1)';
	SET @sql = '
	ALTER PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000
	AS
	SET NOCOUNT ON

	DECLARE @prioridad VARCHAR(8)
	DECLARE @batchsizeIni AS INT
	DECLARE @batchsizeFin AS INT
	DECLARE @rango AS DECIMAL
	DECLARE @rowstoInsert AS INT
	DECLARE @campType AS INT
    DECLARE @recordsQuantitySetting VARCHAR(8)
	DECLARE @settingValueP1 VARCHAR(25)

	SET @rowstoInsert = 0
	SET @batchsizeIni = 0
	SET @batchsizeFin = 0
	SET @rango = 0.00

	IF EXISTS(SELECT * FROM sys.views WHERE NAME = ''VIEW_SETTINGS'') BEGIN
		SELECT @recordsQuantitySetting = [valor] FROM VIEW_SETTINGS WHERE setting_id = 257;
		IF(@recordsQuantitySetting IS NOT NULL AND @recordsQuantitySetting <> '''') BEGIN
			SELECT @settingValueP1 = SUBSTRING(@recordsQuantitySetting, CHARINDEX(''|'', @recordsQuantitySetting)+1, LEN(@recordsQuantitySetting)),
				   @top = (SUBSTRING(@settingValueP1, 1, CHARINDEX(''|'', @settingValueP1)-1));
		END ELSE SET @top = 3000
	END ELSE SET @top = 3000

	SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
	FROM ccCampsPrioridadTel WITH (NOLOCK)
	WHERE cam_id = @camp_id

	SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id = @camp_id;

	DELETE ccUploadTemporal
	WHERE cam_id = @camp_id

	IF(@campType = 7)
	BEGIN
			CREATE TABLE #tempsmsOutSource (Id INT PRIMARY KEY identity, smsout_id INT, cam_id INT, sms_phoneNumber VARCHAR(19), sms_status TINYINT, sms_dateDial DATETIME, cal_keyw VARCHAR(40), iTimeZone INT, iTimeZone_summer INT, iTimeZone2 INT, iTimeZone_summer2 INT, iTimeZone3 INT, iTimeZone_summer3 INT, iTimeZone4 INT, iTimeZone_summer4 INT, iTimeZone5 INT, iTimeZone_summer5 INT, list_id INT)

			CREATE NONCLUSTERED INDEX [IX_TempSMSO] ON [dbo].[#tempsmsOutSource] ([Id] ASC)
				WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

			CREATE TABLE #smsoutIdSource (smsout_id INT NOT NULL PRIMARY KEY)

			CREATE TABLE #smsoutIdSource2 (smsout_id INT NOT NULL PRIMARY KEY)

			INSERT INTO #smsoutIdSource
			SELECT top(@top) sos.smsout_id
			FROM dbo.smsOutSource AS sos  WITH (INDEX (IX_smsOutSource_2), NOLOCK)
			inner join dbo.smsWorkingTable AS swt WITH (INDEX (IX_smsWorkingTable_2), NOLOCK) 
			on sos.callkey = swt.cal_keyw AND sos.cam_id = swt.cam_id 
			WHERE sos.cam_id = @camp_id and sos.sms_status IN (0, 7) AND swt.sms_status <= 2

			UNION

			SELECT top(@top) swt2.smsout_id
			FROM dbo.smsOutSource AS sos2 WITH (INDEX (IX_smsOutSource_2), NOLOCK)
			inner join dbo.smsWorkingTable AS swt2 (NOLOCK)on sos2.smsout_id = swt2.smsout_id 
			WHERE sos2.cam_id = @camp_id AND (sos2.sms_status < 2 OR sos2.sms_status = 7)

			INSERT INTO #smsoutIdSource2
			SELECT top(@top) sos.smsout_id
			FROM dbo.smsOutSource AS sos WITH (INDEX (IX_smsOutSource_1), NOLOCK)
			WHERE sos.sms_status IN (0, 1, 7) AND cam_id = @camp_id

			INSERT #tempsmsOutSource(smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, cal_keyw, iTimeZone, 
			iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4,
			 iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id)
			SELECT TOP(@top) smsout_id, cam_id, RTRIM(LEFT(LTRIM(sms_phoneNumber + ''        '' + sms_phoneNumber2 + ''         '' 
			+ sms_phoneNumber3 + ''         '' + sms_phoneNumber4 + ''         '' + sms_phoneNumber5 + ''         ''), 13)) AS sms_phoneNumber,
			 CASE sms_status WHEN 7 THEN 1 ELSE sms_status END sms_status, sms_dateDial, callkey, 
			 CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone ELSE NULL END iTimeZone,
			  CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone_summer ELSE NULL END iTimeZone_summer, 
			  CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone2 ELSE NULL END iTimeZone2,
			   CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone_summer2 ELSE NULL END iTimeZone_summer2, 
			   CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone3 ELSE NULL END iTimeZone3, 
			   CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone_summer3 ELSE NULL END iTimeZone_summer3,
				CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone4 ELSE NULL END iTimeZone4, 
				CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone_summer4 ELSE NULL END iTimeZone_summer4, 
				CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone5 ELSE NULL END iTimeZone5, 
				CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone_summer5 ELSE 
						NULL END iTimeZone_summer5, list_id
			FROM dbo.smsOutSource  WITH (INDEX (IX_smsOutSource_1), NOLOCK)
			WHERE cam_id = @camp_id AND (sms_status < 2 OR sms_status = 7) 

			SELECT @rowstoInsert = COUNT(*) FROM #tempsmsOutSource AS tos;

			
			IF EXISTS(SELECT * FROM #tempsmsOutSource)
			BEGIN
				SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
				FROM #tempsmsOutSource  WITH (NOLOCK)

				SET @batchsizeFin = @batchsizeFin + @rango

				WHILE 1 = 1
				BEGIN
					-- Nuevos Jobs
					INSERT INTO dbo.smsWorkingTable
					WITH (TABLOCKX) (smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, attemps, user_id,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id)
					SELECT smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, 0, 0 ,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id
					FROM #tempsmsOutSource 
					WHERE id > @batchsizeIni AND id <= @batchsizeFin

					IF @batchsizeFin > @rowstoInsert
						BREAK
					ELSE
					BEGIN
						SET @batchsizeIni = @batchsizeIni + @rango
						SET @batchsizeFin = @batchsizeFin + @rango
					END
				END

				UPDATE dbo.smsOutSource
				SET sms_status = 2
				FROM dbo.smsOutSource AS sos WITH (NOLOCK), #smsoutIdSource2  cis3 WITH (NOLOCK)
				WHERE sos.smsout_id = cis3.smsout_id
			END

			DROP TABLE #smsoutIdSource

			DROP TABLE #smsoutIdSource2

			DROP TABLE #tempsmsOutSource
	END
	ELSE
	BEGIN
			CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19), cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(40), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT, iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT, iZonaHoraria_verano5 INT, list_id INT)

			CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
				WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

			CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

			CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

			INSERT INTO #calloutIdSource
			SELECT top(@top) cs.callout_id
			FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_15), NOLOCK)
			inner join ccoWorkingTable wt WITH (INDEX (IX_ccoWorkingTable_15), NOLOCK) 
			on cs.callout_id = wt.callout_id AND cs.cam_id = wt.cam_id 
			WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

			UNION

			SELECT top(@top) Cout.callout_id
			FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK)
			inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id 
			WHERE Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)
	

			INSERT INTO #calloutIdSource2
			SELECT top(@top) callout_id
			FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_11), NOLOCK)
			WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

			IF exists(SELECT * FROM #calloutIdSource) 
			BEGIN
				UPDATE ccoCallBacks
				SET [status] = 6, schedulerStatus = 1
				WHERE callout_id IN (
						SELECT callout_id
						FROM #calloutIdSource cis
						)

				UPDATE ccoCallsOutSource
				SET cal_Status = 4
				WHERE callout_id IN (
						SELECT callout_id
						FROM #calloutIdSource cis
						)
			END

			INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, 
			iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
			 iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
			SELECT TOP(@top) callout_id, cam_id, CASE WHEN ISNULL(recycleType, 1) = 0 THEN 
			CASE 
				WHEN recyclePhone = 1 THEN cal_telefono
				WHEN recyclePhone = 2 THEN cal_telefono2
				WHEN recyclePhone = 3 THEN cal_telefono3
				WHEN recyclePhone = 4 THEN cal_telefono4
				else cal_telefono5
			END
			ELSE rtrim(left(ltrim(cal_telefono + ''        '' + cal_telefono2 + ''         '' 
				+ cal_telefono3 + ''         '' + cal_telefono4 + ''         '' + cal_telefono5 + ''         ''), 13)) 
			END AS cal_telefono,
			 CASE cal_status WHEN 7 THEN 1 ELSE cal_status END cal_status, cal_fechaDial, cal_key, 
			 CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria ELSE NULL END iZonaHoraria,
			  CASE WHEN LEN(cal_telefono) > 0 THEN iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano, 
			  CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria2 ELSE NULL END iZonaHoraria2,
			   CASE WHEN LEN(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2, 
			   CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria3 ELSE NULL END iZonaHoraria3, 
			   CASE WHEN LEN(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
				CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria4 ELSE NULL END iZonaHoraria4, 
				CASE WHEN LEN(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4, 
				CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria5 ELSE NULL END iZonaHoraria5, 
				CASE WHEN LEN(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE 
						NULL END iZonaHoraria_verano5, list_id
			FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
			WHERE cam_id = @camp_id AND (cal_status < 2 OR cal_status = 7) /*AND CONVERT(VARCHAR(10),cal_fechaDial, 103) >= CONVERT(VARCHAR(10), GETDATE(), 103)*/

			SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

			IF EXISTS(SELECT * FROM #tempCallsOutSource)
			BEGIN
				SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
				FROM #tempCallsOutSource WITH (NOLOCK)

				SET @batchsizeFin = @batchsizeFin + @rango

				WHILE 1 = 1
				BEGIN
					-- Nuevos Jobs
					INSERT INTO ccoWorkingTable
					WITH (TABLOCKX) (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
					SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id
					FROM #tempCallsOutSource
					WHERE id > @batchsizeIni AND id <= @batchsizeFin

					IF @batchsizeFin > @rowstoInsert
						BREAK
					ELSE
					BEGIN
						SET @batchsizeIni = @batchsizeIni + @rango
						SET @batchsizeFin = @batchsizeFin + @rango
					END
				END

				UPDATE ccoCallsOutSource
				SET cal_status = 2, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
				FROM ccoCallsOutSource co WITH (NOLOCK), #calloutIdSource2 cis3 WITH (NOLOCK)
				WHERE co.callout_id = cis3.callout_id
			END

			DROP TABLE #calloutIdSource

			DROP TABLE #calloutIdSource2

			DROP TABLE #tempCallsOutSource
	END

	UPDATE ccCampsNvosCB
	SET dateUpdate = NULL
	WHERE id = @camp_id

	SET NOCOUNT OFF
	';
	EXEC(@sql);
	---------------------------------------End Jonathan Ramírez hotfix/125.20230719.0.8-----------------------------------------------------------

	---------------------------------------Begin Jesus Gallardo hotfix/125.20230719.0.10-----------------------------------------------------------
	SET @process = 'DEV1-444 Asembis Alter SP AgentCheckCampsActive se agerga valicacion si es null @idArea';
	SET @sql = 'ALTER PROCEDURE [dbo].[AgentCheckCampsActive]
@cam_id as smallint,
@user_id as smallint,
@forceManualCall as tinyint = 0
AS

declare @isValidCall as int
declare @timeZoneRule as int
declare @idArea as int

select @isValidCall = count(*)from ccCampsAgente with(nolock) where cam_id = @cam_id and user_id = @user_id
select @idArea = IDArea from ccCamps with(nolock) where cam_id = @cam_id
select @timeZoneRule = 0
if @idArea is not NULL
begin
	select @isValidCall = cam_ModoManual, @timeZoneRule = timeZoneRule, @idArea = 1
	from ccCamps with(nolock) where cam_id = @cam_id
	end

	else if @idArea is null
	begin
	select  @isValidCall = cam_ModoManual, @timeZoneRule = timeZoneRule, @idArea = 0
	from ccCamps with(nolock) where cam_id = @cam_id
	end

select @isValidCall as Validation, @timeZoneRule as TimeZoneRule, isnull(@idArea,0) as Active';
	EXEC(@sql);

	SET @process = 'DEV1-444 Asembis Alter SP ccsp_GalateaAdminCampaigns IF @Option = 12 left JOIN ccCampsExtend extended (NOLOCK) ON camps.cam_id = extended.cam_id';
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] 
@Option AS      SMALLINT, 
@CampType AS    SMALLINT = 0, 
@WorkgroupId AS INT      = 0, 
@Id AS          INT      = 0, 
@AdminId AS     SMALLINT = 0, 
@PinUpdate AS   SMALLINT = 0, 
@LoadId AS      INT      = 0, 
@Type AS        SMALLINT = 0,
@InboundType    SMALLINT = 0,
@AreaId         SMALLINT = 0,
@multi_type     varchar(max) = null
AS
BEGIN
	SET NOCOUNT ON;
	IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type
		BEGIN
			IF @CampType = 1 -- Campaigns Out
				BEGIN
					IF @WorkgroupId IS NOT NULL
						BEGIN
							SELECT CAST(IdCampEsp AS INT) AS Id
							FROM ccRIACampEspWG
							WHERE IDWG = @WorkgroupId
									AND Tipo = 1
									ORDER BY IdCampEsp ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe una lista de campañas de salida con el id de grupo de trabajo especificado'', 18, 1);
					END;
			END;
			IF @CampType = 0 -- Campaigns In (ACD)
				BEGIN
					IF @WorkgroupId IS NOT NULL
						BEGIN
							SELECT CAST(IdCampEsp AS INT) AS Id
							FROM ccRIACampEspWG
							WHERE IDWG = @WorkgroupId
									AND Tipo = 0
									ORDER BY IdCampEsp ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe una lista de campañas de entrada con el id de grupo de trabajo especificado'', 18, 1);
					END;
			END;
			RETURN 0;
	END;
	IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id
		BEGIN
			IF @CampType = 1 -- Campaigns Out
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							SELECT DISTINCT 
							CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
							isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
							camps.cam_procesando IsStarted, 
							ISNULL(a.AreaName, '''') AS Area, 
							CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
							CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType,
							ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
							FROM ccCamps camps
							LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
							LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
							LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
							WHERE camps.cam_id = @Id
							ORDER BY camps.cam_descripcion ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
					END;
			END;
			IF @CampType = 0 -- Campaigns In (ACD)
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							SELECT DISTINCT 
							CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, 
							ISNULL(a.AreaName, '''') AS Area, 
							CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType
							FROM ccInbound inb
									LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
									LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
							WHERE inb.Inbound_id = @Id
									ORDER BY inb.descripcion ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe campañas de entrada con el id especificado'', 18, 1);
					END;
			END;
			RETURN 0;
	END;
	IF @Option = 3   -- Update OverallTotalNew By Campaign
		BEGIN
			IF @Id IS NOT NULL
				BEGIN
					UPDATE ccCampsNvosCB
						SET 
							OverallTotalNew = ccCampsNvosCB.new
					WHERE id = @Id;
			END;
			ELSE
				BEGIN
					RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 4   -- Update Pin from Campaign per Admin
		BEGIN
			IF @Id IS NOT NULL
				AND @AdminId IS NOT NULL
				BEGIN
					IF @PinUpdate = 1
						BEGIN
							INSERT INTO PinedCampaigns(CampId, AdminId, Type)
						VALUES(@Id, @AdminId, @Type);
					END;
					IF @PinUpdate = 0
						BEGIN
							DELETE FROM PinedCampaigns
							WHERE CampId = @Id
									AND AdminId = @AdminId
									AND Type = @Type;
					END;
			END;
			ELSE
				BEGIN
					RAISERROR(''ERROR. La campañas o administrador no existen'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 5   -- Get Pin from Campaign Ids per Admin
		BEGIN
			IF @AdminId IS NOT NULL
				BEGIN
					SELECT CampId AS Id
					FROM PinedCampaigns
					WHERE AdminId = @AdminId
							AND Type = @Type
							ORDER BY Id ASC;
			END;
			ELSE
				BEGIN
					RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 6   -- Get Blacklist Ids by Campaign Id
		BEGIN
			IF @Id IS NOT NULL
				BEGIN
					DECLARE @BlackListIds VARCHAR(MAX);
					SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
					FROM Camplistanegra
					WHERE cam_id = @Id
							AND STATUS = 1;
					SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
			END;
			ELSE
				BEGIN
					RAISERROR(''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 7   -- Get RegistryListIds Ids by Campaign Id
		BEGIN
			IF(@Id IS NOT NULL
				AND EXISTS
			(
				SELECT *
				FROM cccamps
				WHERE cam_id = @Id
			))
				BEGIN
					SELECT TOP 1 list_id
					FROM ccRIARegistryLists
					WHERE cam_id = @Id
							AND STATUS = 2
							ORDER BY list_id DESC;
			END;
			ELSE
				BEGIN
					--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
					RAISERROR(''ERROR. No existe una campaña con el id especificado'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 8   -- Delete RegistryListIds Ids by LoadId
		BEGIN
			IF(@LoadId IS NOT NULL
				AND EXISTS
			(
				SELECT *
				FROM ccRIARegistryLists
				WHERE list_id = @loadID
						AND STATUS <> 0
			))
				BEGIN
					UPDATE ccoCallsOutSource
						SET 
							cal_status = ''5''
					WHERE list_id = @loadID;
					DELETE FROM ccoWorkingTable
					WHERE list_id = @LoadId;
					EXEC ccsp_RIARegistryLists 
							@action = 6, 
							@list_id = @LoadId;
			END;
			ELSE
				BEGIN
					--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
					RAISERROR(''ERROR. No existe una carga el id especificado'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @option = 9   -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
		BEGIN
			DECLARE @table TABLE
			(camId    INT, 
				campType TINYINT, 
				PRIMARY KEY(camId, campType)
			);
			INSERT INTO @table
					SELECT DISTINCT 
							IdCampEsp, Tipo
					FROM ccRIACampEspWG wg
					WHERE wg.IDWG IN
					(
						SELECT IDWG
						FROM ccRIAWorkGroupUsers
						WHERE IDWG <> @WorkgroupId
								AND User_id = @AdminId
					);
			SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
			FROM @table A
					RIGHT JOIN
			(
				SELECT wg.IdCampEsp, wg.Tipo
				FROM ccRIACampEspWG wg
				WHERE wg.IDWG = @WorkgroupId
			) B ON A.camId = B.IdCampEsp
					AND A.campType = B.Tipo
			WHERE A.camId IS NULL
					ORDER BY IdCampEsp;
			RETURN 0;
	END;
	IF @option = 10  -- Get Agents States with totals per campaign by admin id and campaign type
	BEGIN
	DECLARE @date DATETIME= CONVERT(DATE, DATEADD(hh, -3, GETDATE()));
	DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY(id));
	DECLARE @AgentsList TABLE(id INT, PRIMARY KEY(id));
	DECLARE @tmpCamAgent TABLE(camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY(camId, userId));
	DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT );
	DECLARE @CurrentStatus TABLE(userId INT, CurrentState INT, IdCampEsp INT, camType INT);
	DECLARE @campDataTotal TABLE(camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY(camId));

	INSERT INTO @AdminWorkgroups SELECT DISTINCT IDWG
	FROM ccRIAWorkGroupUsers WG, 
		ccUsers_Roles R
	WHERE WG.User_id = @AdminId
	OR (R.User_id = @AdminId
	AND R.Rol_id = 7);
					        
	INSERT INTO @AgentsList SELECT DISTINCT A.User_id
	FROM ccRIAWorkGroupUsers A
	INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
	INNER JOIN ccUsers C ON A.User_id = C.User_id 
	AND C.TipoUser_id = 1
	ORDER BY A.User_id;

					INSERT INTO @tmpCamAgent SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id,
	CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
	FROM ccRIACampEspWG campPerWg
	INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
	INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
	INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
	left JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp and @CampType = 0
	left JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp and @CampType = 1
	where C.TipoUser_id = 1
	AND campPerWg.Tipo = @CampType
	AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
					  
	;WITH lastState AS (
	SELECT A.user_id, MAX(A.fecha) AS fecha
	FROM ccLogAgentesDia A
	INNER JOIN @AgentsList B ON A.User_id = B.id
	WHERE fecha >= @date
	GROUP BY user_id)

	INSERT INTO @CurrentStatus 
	SELECT B.User_id,
	CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS currentStatus,
	B.IdCampEsp,
	B.Tipo
	FROM lastState A
	INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
	AND A.fecha = B.fecha;

	IF @Id = 0 AND @CampType = 0 
	BEGIN
	DELETE FROM @tmpCamAgent WHERE multimediaType = 5
	END

	DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;
	IF @CampType = 1 BEGIN
	SELECT @MultimediaType = meanContactTypeId FROM contactMeanOut WHERE camp_id = @Id
	END
	ELSE BEGIN
		SELECT @chatType = ci.chat FROM dbo.ccInbound AS ci WHERE ci.Inbound_id = @Id;
		SELECT @MultimediaType = meanContactTypeId FROM contactMeanIn WHERE inboundId = @Id
	END 

	IF(@chatType = 1)
	BEGIN
		SET @MultimediaType = 1
	END
			
	DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN ''23'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes
			
	INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
	(CASE 
		WHEN @chatType = 1 THEN 
		CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'',''))  THEN @CampType 
		ELSE 
		CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN @CampType 
		ELSE null 
		END END END) AS isCampDialog, B.camType
	FROM @tmpCamAgent A
	INNER JOIN @CurrentStatus B ON A.userId = B.userId
	WHERE (@Id = 0 or A.camId = @Id)

	IF @CampType = 1
	BEGIN
	;with  campDataTotal as(
		select camId,count(*) total from @tmpCamAgent A group by camId
	)

	insert into @campDataTotal
	select 
		A.camId,
		B.cam_descripcion as campName 
		,A.Total
		,C.AreaName as Area
		from campDataTotal A
		INNER JOIN ccCamps B ON A.camId= B.cam_id 
		INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
	END
	ELSE
	BEGIN    
	;with  campDataTotal as(
		select camId,count(*) total from @tmpCamAgent A group by camId
	)

	insert into @campDataTotal
	select 
		A.camId,
		B.descripcion as campName 
		,A.Total
		,C.AreaName as Area
		from campDataTotal A
		INNER JOIN ccInbound B ON A.camId = B.Inbound_id 
		INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
	END

	;WITH stateCamp AS(
	SELECT A.CampId,
	count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready,
	count(CASE WHEN A.CurrentState NOT IN(-2, -1, 0, 3, 4, 5, 6, 9, 30, 34) THEN 1 
			WHEN A.CurrentState IN (6, 34, 4) AND (A.CampId != C.IdCampEsp OR A.campType != @CampType) THEN 1 ELSE NULL END) AS notReady,
	COUNT(isCampDialog) AS dialog, 
	COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected 
	FROM @AgentStatus A
	INNER JOIN @CurrentStatus C ON A.userId = C.userId
	GROUP BY A.CampId
	)

	SELECT 
	A.camId,
	A.campName,
	A.Total,
		ISNULL(B.ready, 0) AS Ready,
	ISNULL(B.notReady, 0 ) AS NotReady, 
	ISNULL(B.dialog, 0) AS Dialog,
	CASE WHEN B.disconnected IS NULL THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END Disconnected,
	A.Area
	FROM @campDataTotal A
	LEFT JOIN stateCamp B ON A.camId = B.CampId
	ORDER BY A.campName

		RETURN 0;
	END;
	IF @Option = 11  -- Get Campaigns Ids List Per Workgroup and Campaign Type
		BEGIN                
			IF Not EXISTS
			(
				SELECT *
				FROM ccUsers_Roles NOLOCK
				WHERE User_id = @AdminId
						AND Rol_id = 7
			)
				BEGIN
		print ''xxxx SIn Super''
					;WITH wgId
							AS (SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT 
								CAST(IdCampEsp AS INT) AS Id
							FROM ccRIACampEspWG A (NOLOCK)
								INNER JOIN wgId ON wgId.IDWG = A.IDWG
													AND A.Tipo = @CampType;
			END;
			ELSE
				BEGIN
		--print ''xxxx Super''
		IF @CampType = 1
		BEGIN
			SELECT DISTINCT 
				CAST(cam_id AS INT) AS Id
						FROM ccCamps (NOLOCK) where IDArea IS NOT NULL
		END
		ELSE
		BEGIN 
			SELECT DISTINCT 
				CAST(Inbound_id AS INT) AS Id
						FROM ccInbound (NOLOCK) where IDArea IS NOT NULL
		END
			END;
			RETURN 0;
	END;
	IF @Option = 12  -- Get All Campaigns complete information per Campaign Type and Campaign Id
		BEGIN
			IF @CampType = 1 -- Campaigns Out
				BEGIN
					SELECT DISTINCT 
					CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
					isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
					camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
					CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType,
					ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
					FROM ccCamps camps (NOLOCK)
					INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
					INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
					left JOIN ccCampsExtend extended (NOLOCK) ON camps.cam_id = extended.cam_id
					--WHERE camps.cam_id = @Id
					ORDER BY camps.cam_descripcion ASC;
			END;
			ELSE
				BEGIN
					SELECT DISTINCT 
											CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId, inb.chat AS InboundType, 0 as OutboundType
					FROM ccInbound inb (NOLOCK)
							INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
							INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = inb.IDArea
							ORDER BY inb.descripcion ASC;
			END;
			RETURN 0;
	END;
	IF @Option = 13
	BEGIN
		BEGIN                
			IF NOT EXISTS
			(
				SELECT *
				FROM ccUsers_Roles NOLOCK
				WHERE User_id = @AdminId
						AND Rol_id = 7
			)
				BEGIN
					IF @CampType = 1
						BEGIN
							WITH wgId
								AS (SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT 
									CAST(IdCampEsp AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,CAST(-1 AS INT) AS RelatedCampId
								FROM ccRIACampEspWG A
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 1
									INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id;
						END
					ELSE
						BEGIN
							WITH wgId
								AS (SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT 
									CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
								FROM ccRIACampEspWG A (NOLOCK)
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 0
									INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id 
									AND ((@multi_type is null AND cci.chat = @InboundType)
										OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
						END
			END;
			ELSE
				BEGIN
				IF @CampType = 1
					BEGIN
						SELECT DISTINCT 
								CAST(cam_id AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,-1 AS RelatedCampId
						FROM ccCamps NOLOCK where IDArea = @AreaId
					END
				ELSE
					BEGIN 
						SELECT DISTINCT 
								CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
						FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
						AND ((@multi_type is null AND cci.chat = @InboundType)
							OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

					END
			END;
			RETURN 0;
		END;
	END;

	IF @Option = 14
		BEGIN
			IF NOT EXISTS
			(
					SELECT *
					FROM ccUsers_Roles NOLOCK
					WHERE User_id = @AdminId
							AND Rol_id = 7
			)
				BEGIN
					WITH wgId
							AS (SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT 
								CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
							FROM ccRIACampEspWG A (NOLOCK)
								INNER JOIN wgId ON wgId.IDWG = A.IDWG
													AND A.Tipo = 0
								INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND isnull(cci.cam_id,-1) = -1
								AND ((@multi_type is null AND cci.chat = @InboundType)
									OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

				END
			ELSE
				BEGIN
					SELECT DISTINCT 
					CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
					FROM ccInbound cci (NOLOCK) where IDArea = @AreaId AND isnull(cam_id,-1) = -1
					AND ((@multi_type is null AND cci.chat = @InboundType)
						OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

				END
		END
	IF @Option = 15
		BEGIN
			SELECT DISTINCT 
			CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
			FROM ccInbound NOLOCK where cam_id = @Id
		END
END;
';
	EXEC(@sql);

	SET @process = 'DEV1-444 Asembis Alter SP ';
	SET @sql = '';
	EXEC(@sql);


	---------------------------------------End Jesus Gallardo hotfix/125.20230719.0.10-----------------------------------------------------------



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
