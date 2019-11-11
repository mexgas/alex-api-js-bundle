CREATE FUNCTION [dbo].[Completa] (@phone VARCHAR(32), @pais VARCHAR(2) = '', @cldLocal VARCHAR(5) = '')
RETURNS VARCHAR(32)
AS
BEGIN
	DECLARE @resultado VARCHAR(32)
	DECLARE @ld VARCHAR(7)
	DECLARE @isLocal BIT

	IF @pais = ''
	BEGIN
		SELECT @pais = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 104
	END

	IF @cldLocal = ''
	BEGIN
		SELECT @cldLocal = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 17
	END

	SELECT @phone = dbo.limpia(@phone)

	SELECT @resultado = @phone

	DECLARE @lenPhone INT, @lenLd INT

	SET @lenPhone = len(@resultado)
	SET @lenLd = len(@cldLocal)

	IF @pais = 1
	BEGIN --Empieza Mexico 		
		IF @lenPhone < 10
		BEGIN
			RETURN 'E_NV_Longitud';
		END

		IF @lenPhone = 12 AND left(@phone, 2) <> '01'
		BEGIN
			RETURN 'E_NV_Longitud';
		END

		IF @lenPhone = 13 AND left(@phone, 3) NOT IN ('044', '045')
		BEGIN
			RETURN 'E_NV_Longitud';
		END

		SET @resultado = right(@resultado, 10)
		SET @isLocal = 0

		DECLARE @specialDialPlan TINYINT

		SELECT @specialDialPlan = valor
		FROM ccsettings WITH (NOLOCK)
		WHERE setting_id = 195

		IF EXISTS (
				SELECT TOP 1 area
				FROM ccRiaArecode NOLOCK
				WHERE area = left(@resultado, 3)
				)
			SELECT @ld = left(@resultado, 3), @isLocal = 1
		ELSE IF EXISTS (
				SELECT TOP 1 area
				FROM ccRiaArecode NOLOCK
				WHERE area = left(@resultado, 2)
				)
			SELECT @ld = left(@resultado, 2), @isLocal = 1
		ELSE
		BEGIN
			SET @ld = @cldLocal

			IF left(@resultado, len(@ld)) = @ld
			BEGIN
				SET @isLocal = 1
			END
		END

		SET @lenLd = len(@ld)

		IF @specialDialPlan = 1
		BEGIN
			--Number local 10 digit
			--Number LD 12 digit
			--Number Cell 13 digit
			SELECT @resultado = CASE WHEN @lenPhone = 10 THEN CASE WHEN @isLocal = 1 THEN @resultado ELSE '01' + @resultado END --10 Dig Local, LD
					WHEN @lenPhone = 12 THEN CASE WHEN @isLocal = 1 THEN @resultado ELSE @phone END --12 Dig Local, LD
					WHEN @lenPhone = 13 THEN CASE WHEN @isLocal = 1 THEN '044' + @resultado ELSE '045' + @resultado END --13 Dig Local, LD
					ELSE 'E_NV_Longitud' END --Other Long
		END
		ELSE IF @specialDialPlan = 0
		BEGIN
			--Number local 7 o 8 digit
			--Number LD 12 digit
			--Number Cell 13 digit
			SELECT @resultado = CASE WHEN @lenPhone = 10 THEN CASE WHEN @isLocal = 1 THEN right(@resultado, 10 - @lenLd) ELSE '01' + @resultado END --10 Dig Local, LD
					WHEN @lenPhone = 12 THEN CASE WHEN @isLocal = 1 THEN right(@resultado, 10 - @lenLd) ELSE @phone END --12 Dig Local, LD							
					WHEN @lenPhone = 13 THEN CASE WHEN @isLocal = 1 THEN '044' + @resultado ELSE '045' + @resultado END --13 Dig Local, LD
					ELSE 'E_NV_Longitud' END
		END

		--Termina Mexico
		RETURN @resultado
	END
	ELSE IF @pais = 2
	BEGIN -- Empieza Argentina
		SELECT @resultado = CASE WHEN (@lenPhone = 7 AND @lenLd = 3) OR (@lenPhone = 6 AND @lenLd = 4) THEN @resultado
						-- cuando son 8 digitos y la lada es de 2 digitos, se regresa el telefono tal cual
						-- cuando la lada es de 4 digitos, se revisa la posibiidad de que sea un celular, si es asi se regresa
				WHEN @lenPhone = 8 THEN CASE WHEN @lenLd = 4 THEN CASE WHEN left(@resultado, 2) = '15' THEN @resultado END ELSE CASE WHEN @lenLd = 2 THEN @resultado END END
						-- Este caso solamente es cuando el telefono es un celular y la lada es de 3 digitos
				WHEN @lenPhone = 9 THEN CASE WHEN left(@resultado, 2) = '15' THEN @resultado ELSE 'E_NV_Cel' END
						-- Cuando son 10 numeros y la lada es igual, solo se marcan los numeros restantes para llamada local
						-- Si es diferente se le agrega un 0 para llamadas de larga distancia
				WHEN @lenPhone = 10 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE CASE WHEN left(@resultado, 2) = '15' THEN @resultado ELSE '0' + @resultado END END
						-- Cuando el numero telefonico viene con un 0 al inicio, se verifica la lada
						-- si no es la misma lada, pero el telefono empieza con 0, se regresa tal cual
				WHEN @lenPhone = 11 THEN CASE WHEN left(@resultado, 1) = '0' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE @resultado END ELSE 'E_NV_LD' END
						-- Celular, si tiene 12 numeros y el numero es local, solo se marca el 15 y el numero
						-- si no es local se le agrega el 0 y se marca el numero
				WHEN @lenPhone = 12 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN CASE WHEN substring(@resultado, @lenLd + 1, 2) = '15' THEN right(@resultado, 12 - @lenLd) ELSE 'E_NV_Cel' END ELSE '0' + @resultado END
						-- Celular, con 0 al inicio si es local, quita el area y marca apartir del 15, si no, lo regresa igual
				WHEN @lenPhone = 13 THEN CASE WHEN left(@resultado, 1) = '0' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN substring(@resultado, @lenLd + 2, 12 - @lenLd) ELSE @resultado END ELSE 'E_NV_Cel' END ELSE 'E_NV_Longitud' END

		--Termina Argentina
		RETURN @resultado
	END
	ELSE IF @pais = 3
	BEGIN --Empieza colombia
		SELECT @resultado = CASE 
				--Si son 7 digitos, se regresa igual
				WHEN @lenPhone = 7 THEN @resultado
						--Cuando son 8 digitos si la lada es igual se quita y se regresan 7 numeros
				WHEN @lenPhone = 8 THEN CASE WHEN left(@resultado, 1) = @cldLocal THEN right(@resultado, 7) ELSE @resultado END
						-- Cuando son 10 digitos, se revisa que tenga prefijo celular y se agrega un 0
				WHEN @lenPhone = 10 THEN CASE WHEN left(@resultado, 3) IN ('300', '301', '302', '303', '304', '305', '310', '311', '312', '313', '314', '315', '316', '317', '318', '319', '320') THEN '0' + @resultado ELSE 'E_NV_Cel' END
						--Cuando son 11 digitos, se revisa que el primer numero sea un 0 y que los siguientes 3 numeros sean
						--prefijo de celular
				WHEN @lenPhone = 11 THEN CASE WHEN left(@resultado, 1) = '0' THEN CASE WHEN substring(@resultado, 2, 3) IN ('300', '301', '302', '303', '304', '305', '310', '311', '312', '313', '314', '315', '316', '317', '318', '319', '320') THEN @resultado ELSE 'E_NV_Cel' END ELSE 'E_NV_Cel' END ELSE 'E_NV_Longitud' END

		-- Termina Colombia
		RETURN @resultado
	END
	ELSE IF @pais = 4
	BEGIN --Empieza USA
		SELECT @resultado = CASE @lenPhone WHEN 3 THEN CASE @resultado WHEN '911' THEN @resultado ELSE 'E_NV_Longitud' END WHEN 7 THEN @resultado WHEN 10 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE '1' + @resultado END WHEN 11 THEN CASE WHEN left(@resultado, 1) = '1' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE @resultado END ELSE 'E_NV_LD' END ELSE 'E_NV_Longitud' END

		--Termina USA
		RETURN @resultado
	END
	ELSE IF @pais = 5
	BEGIN --5:Chile
		SELECT @resultado = CASE @lenPhone WHEN 6 THEN @resultado WHEN 7 THEN @resultado
						-- se revisa si es un celular, si es asi se le agrega el 09 excepto con los prefijos que se mezclan con ladas
				WHEN 8 THEN CASE WHEN @cldLocal = left(@resultado, @lenLd) THEN right(@resultado, 8 - @lenLd) ELSE CASE WHEN left(@resultado, 1) IN (8, 9) THEN '09' + @resultado ELSE CASE WHEN left(@resultado, 1) = '6' THEN CASE WHEN left(@resultado, 2) IN (61, 63, 64, 65, 67) THEN @resultado ELSE '09' + @resultado END ELSE CASE WHEN left(@resultado, 1) = '7' THEN CASE WHEN left(@resultado, 2) IN (71, 72, 73, 75) THEN @resultado ELSE '09' + @resultado END ELSE @resultado END END END END
						-- Se revisa que sea la lada permitida a 9 numeros, si es asi se regresa igual, si tiene el prefijo
						-- de telefonia voIp se le agrega el 0 al inicio
				WHEN 9 THEN CASE WHEN @cldLocal = left(@resultado, 2) THEN right(@resultado, 7) ELSE CASE WHEN left(@resultado, 2) IN (41, 32, 65) THEN @resultado ELSE CASE WHEN left(@resultado, 2) = '44' THEN '0' + @resultado ELSE CASE WHEN left(@resultado, 1) = '9' AND substring(@resultado, 2, 1) IN (6, 7, 8, 9) THEN '0' + @resultado ELSE 'E_NV_Longitud' END END END END WHEN 10 THEN CASE WHEN left(@resultado, 2) = '09' THEN @resultado ELSE 'E_NV_Cel' END ELSE 'E_NV_Longitud' END

		-- Termina Chile
		RETURN @resultado
	END

	IF @pais = 6
	BEGIN -- Venezuela
		SELECT @resultado = CASE @lenPhone WHEN 7 THEN @resultado WHEN 10 THEN '0' + @resultado WHEN 11 THEN CASE WHEN left(@resultado, 1) = '0' THEN @resultado ELSE 'E_NV_Longitud' END ELSE 'E_NV_Longitud' END

		RETURN @resultado
	END
			--Termina Venezuela
	ELSE IF @pais = 7
	BEGIN --7: Reino Unido
		SELECT @resultado = CASE @lenPhone WHEN 11 THEN CASE left(@resultado, 1) WHEN '0' THEN @resultado ELSE 'E_NV_Longitud' END WHEN 10 THEN CASE left(@resultado, 1) WHEN '0' THEN @resultado ELSE '0' + @resultado END WHEN 9 THEN CASE WHEN left(@resultado, 1) <> '0' THEN '0' + @resultado ELSE 'E_NV_Longitud' END WHEN 8 THEN CASE WHEN substring(@resultado, 1, 2) = '08' THEN @resultado ELSE 'E_NV_Longitud' END WHEN 7 THEN CASE WHEN left(@resultado, 1) = '8' THEN '0' + @resultado ELSE 'E_NV_Longitud' END ELSE 'E_NV_Longitud' END

		RETURN @resultado
	END
			-- Termina UK
	ELSE IF @pais = 8
	BEGIN -- arabia saudita
		SELECT @resultado = CASE @lenPhone WHEN 7 THEN @resultado WHEN 8 THEN CASE substring(@resultado, 1, 1) WHEN @cldLocal THEN right(@resultado, 7) ELSE '0' + @resultado END WHEN 9 THEN CASE substring(@resultado, 1, 1) WHEN '5' THEN '0' + @resultado WHEN '0' THEN CASE substring(@resultado, 2, 1) WHEN @cldLocal THEN right(@resultado, 7) ELSE @resultado END ELSE 'E_NV_Longitud' END WHEN 10 THEN CASE substring(@resultado, 2, 1) WHEN '5' THEN @resultado ELSE 'E_NV_Longitud' END WHEN 11 THEN CASE substring(@resultado, 2, 1) WHEN '8' THEN CASE substring(@resultado, 3, 3) WHEN '111' THEN @resultado ELSE 'E_NV_Longitud' END ELSE CASE WHEN substring(@resultado, 3, 3) = '510' OR substring(@resultado, 3, 3) = '511' THEN @resultado ELSE 'E_NV_Longitud' END END WHEN 13 THEN @resultado ELSE 'E_NV_Longitud' END

		RETURN @resultado
	END -- arabia saudita
	ELSE IF @pais = 9
	BEGIN --Australia
		SELECT @resultado = CASE @lenPhone WHEN 8 THEN
						/*case when exists (select AreaCode
              from SeriesAU
              where convert(int,LD) = convert(int,@cldLocal)
              and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then*/
						CASE substring(@resultado, 1, 4) WHEN '5550' THEN 'E_NV_LD' ELSE @cldLocal + @resultado END
						/*else case when exists (select AreaCode
              from SeriesAU
              where convert(int,LD) = convert(int,'04')
              and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then
    '04' +  @resultado
    else 'E_NV_Cel' end end*/
				WHEN 9 THEN CASE WHEN left(@resultado, 1) <> '0' THEN CASE substring(@resultado, 2, 4) WHEN '5550' THEN 'E_NV_LD' ELSE '0' + @resultado END ELSE 'E_NV_LD' END WHEN 10 THEN CASE substring(@resultado, 3, 4) WHEN '5550' THEN 'E_NV_LD' ELSE @resultado END ELSE 'E_NV_Longitud' END

		RETURN @resultado
	END
	ELSE IF @pais = 10
	BEGIN --Brasil
		SELECT @resultado = CASE @lenPhone
				--llamada local fijo o celular
				WHEN 8 THEN @resultado WHEN 9 THEN @resultado WHEN 10 THEN -- Numero nacional
						CASE WHEN left(@resultado, 2) = @cldLocal THEN right(@resultado, 8) ELSE @resultado END WHEN 11 THEN -- Este caso solomente es para numero celular
						CASE WHEN left(@resultado, 2) = @cldLocal THEN right(@resultado, 9) ELSE @resultado END WHEN 12 THEN -- llamadas por cobrar local
						CASE WHEN (left(@resultado, 4) = '9090') THEN right(@resultado, 8) ELSE 'E_NV_PC' END WHEN 13 THEN CASE WHEN left(@resultado, 4) = '9090' THEN right(@resultado, 9) -- llamadas por cobrar local celular
							WHEN left(@resultado, 1) = '0' THEN CASE WHEN substring(@resultado, 4, 2) = @cldLocal THEN right(@resultado, 8) ELSE right(@resultado, 10) END -- llamadas de LDN
							ELSE 'E_NV_Longitud' END WHEN 14 THEN CASE WHEN left(@resultado, 2) = '90' THEN -- llamadas por cobrar larga distancia
									CASE WHEN substring(@resultado, 5, 2) = @cldLocal THEN right(@resultado, 8) ELSE right(@resultado, 11) END WHEN left(@resultado, 1) = '0' THEN --llamada larga distancia a celular
									CASE WHEN substring(@resultado, 4, 2) = @cldLocal THEN right(@resultado, 9) ELSE right(@resultado, 11) END ELSE 'E_NV_Longitud' END WHEN 15 THEN CASE WHEN left(@resultado, 2) = '90' THEN -- Llamadas por cobrar a celular LD
									CASE WHEN substring(@resultado, 5, 2) = @cldLocal THEN right(@resultado, 9) ELSE right(@resultado, 11) END ELSE 'E_NV_Longitud' END ELSE 'E_NV_Longitud' END

		RETURN @resultado
	END
	ELSE IF @pais = 11
	BEGIN --Guatemala
		IF @lenPhone = 8 AND charindex(substring(@resultado, 1, 1), '2,3,4,5,6,7') <= 0
		BEGIN
			SELECT @resultado = 'E_' + @resultado
		END
		ELSE
			SELECT @resultado = 'E_NV_Longitud'

		RETURN @resultado
	END
	ELSE IF @pais = 12
	BEGIN --Costa Rica
		IF @lenPhone = 8 AND charindex(substring(@resultado, 1, 1), '2,3,4,5,6,7,8') <= 0
		BEGIN
			SELECT @resultado = 'E_' + @resultado
		END
		ELSE IF @lenPhone = 10 AND charindex(substring(@resultado, 1, 3), '800,900,905') <= 0
		BEGIN
			SELECT @resultado = 'E_' + @resultado
		END
		ELSE IF charindex(substring(@resultado, 1, 2), '00,08') <= 0
		BEGIN
			SELECT @resultado = 'E_' + @resultado
		END

		RETURN @resultado
	END
	ELSE IF @pais = 13
	BEGIN --Salvador
		IF @lenPhone = 8 AND charindex(substring(@resultado, 1, 1), '2,6,7') <= 0
		BEGIN
			SELECT @resultado = 'E_' + @resultado
		END
		ELSE IF charindex(substring(@resultado, 1, 2), '00') <= 0
		BEGIN
			SELECT @resultado = 'E_' + @resultado
		END

		RETURN @resultado
	END
	ELSE IF @pais = 14
	BEGIN --Spain
		IF @lenPhone = 9 AND charindex(substring(@resultado, 1, 1), '5,6,7,8,9') <= 0
		BEGIN
			SELECT @resultado = 'E_' + @resultado
		END
		ELSE IF charindex(substring(@resultado, 1, 2), '00') <= 0
		BEGIN
			SELECT @resultado = 'E_' + @resultado
		END

		RETURN @resultado
	END
	ELSE IF @pais = 15
	BEGIN --Peru
		SELECT @resultado = CASE WHEN (@lenPhone = 7 AND @lenLd = 1) OR (@lenPhone = 6 AND @lenLd = 2) THEN @resultado WHEN @lenPhone = 8 THEN CASE WHEN substring(@resultado, 1, @lenLd) = @cldLocal THEN right(@resultado, 8 - @lenLd) ELSE '0' + @resultado END WHEN @lenPhone = 9 THEN CASE WHEN left(@resultado, 1) = '0' AND substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 8 - @lenLd) ELSE @resultado END ELSE 'E_NV_Longitud' END

		RETURN @resultado
	END --Termina Peru
	ELSE IF @pais = 16
	BEGIN --Panama
		SELECT @resultado = CASE WHEN (@lenPhone = 7) THEN CASE WHEN substring(@resultado, 1, 1) IN ('2', '3', '4', '5', '7', '9') THEN @resultado ELSE 'E_' + @resultado END WHEN (@lenPhone = 8) THEN CASE WHEN substring(@resultado, 1, 1) = '6' THEN @resultado ELSE 'E_' + @resultado END ELSE CASE WHEN substring(@resultado, 1, 2) = '00' THEN @resultado ELSE 'E_' + @resultado END END

		RETURN @resultado
	END

	-- Termina
	RETURN @resultado
END