CREATE FUNCTION [dbo].[GetDataPhone] (@tel VARCHAR(32), @pais TINYINT = 1, @cldLocal VARCHAR(7) = '55')
RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE @ld VARCHAR(7),@serie varchar(7),@rank varchar(7)
	DECLARE @lon TINYINT
	DECLARE @result TINYINT
	DECLARE @mod VARCHAR(10)
	DECLARE @Cadena VARCHAR(32)
	DECLARE @isLocal BIT
	declare @rankNum int

	declare @region varchar(20), @localidad varchar(20) 
	select @region='',@localidad=''
	SELECT @tel = dbo.limpia(@tel)

	if @tel='' begin
		return ''
	end

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
				RETURN 'E_' + @tel

			--set @serie= substring(@tel, len(@ld) + 1, 6 - len(@ld))
			set @rank= right(@tel, 4)
			set @rankNum=cast(@rank as int)

			SELECT TOP 1 @mod = modalidad,@region = estado, @localidad = municipio
			FROM series NOLOCK
			WHERE cld = @ld AND serie = @serie AND @rankNum BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

			IF @mod NOT IN ('FIJO', 'MPP', 'CPP')
			BEGIN
				RETURN 'E_' + @tel
			END

			DECLARE @specialDialPlan TINYINT

			SELECT @specialDialPlan = valor
			FROM ccsettings WITH (NOLOCK)
			WHERE setting_id = 195


			SET @isLocal = 0

			IF @cldLocal = @ld or EXISTS (
					SELECT *
					FROM ccRiaArecode
					WHERE area = @ld
					)					
			BEGIN
				SET @isLocal = 1
			END		
			
			
			IF @specialDialPlan = 2
			BEGIN --Number 10 digits
				RETURN @ld+'|'+@serie+'|'+@rank+'|'+ @tel+'|'+@region+'|'+@localidad+'|'+case @mod when 'CPP' then '1' else '0' end +'|'+case @isLocal when 1 then '1' else '0' end
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

		RETURN @ld+'|'+@serie+'|'+@rank+'|'+ @tel+'|'+@region+'|'+@localidad+'|'+case @mod when 'CPP' then '1' else '0' end +'|'+case @isLocal when 1 then '1' else '0' end
	END --Termina Mexico
				
	Return ''
END