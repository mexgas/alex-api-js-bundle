/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/11/10
Description:

Database: CCenterRia
Required version: 123.12

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
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 12
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

				set @process = 'se quita sp si existe'
				set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_OUTgetTimeZone'')
				    begin
					DROP PROCEDURE ccsp_OUTgetTimeZone;
				    end'
				EXEC(@sql)
		
				set @process = 'se agrega sp ccsp_OUTgetTimeZone'
				set @sql = '
					        create procedure [dbo].[ccsp_OUTgetTimeZone]
						@phone varchar(20)
						AS
						set nocount on
						declare @bIsDaylight int, @country_id int
						
						SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
						select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
						select dbo.fnGetTimeZone(@phone,@bIsDaylight)
		'
				EXEC(@sql)

		set @process = 'CW-4506 Función Series alter fnGetTimeZone'
		set @sql = 'ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
RETURNS int
AS
 BEGIN
  declare @lada as varchar(5)
  declare @timeZone as int
  declare @ld as varchar(5)
  declare @location as varchar(500)
  declare @locality as varchar(255)
  declare @country as tinyInt
  declare @pais varchar(2)
  declare @serie varchar(10)
  declare @rank int
  declare @len int

  select @lada = valor from ccsettings with(nolock) where setting_id = 17
  select @country = valor, @pais = valor from ccSettings with(nolock) where setting_id = 104

  select @ld = ''''
  select @location = ''''
  set @timeZone=0
	
  if @phone='''' begin
    return 0;
  end

  set @len=len(@phone)

    if @country = 1 begin

		if @len<10 and @len + len(@lada)=10 begin
			set @phone=@lada+@phone
			set @len=len(@phone)
		end      

      if @len = 10
        begin         
			IF EXISTS (
					SELECT TOP 1 cld
					FROM series NOLOCK
					WHERE cld = left(@phone, 3)
					and serie=SUBSTRING(@phone,4,3)
					)
				SELECT @ld = left(@phone, 3),@serie=SUBSTRING(@phone,4,3)
			ELSE IF EXISTS (
					SELECT TOP 1 cld
					FROM series NOLOCK
					WHERE cld = left(@phone, 2)
					and serie=SUBSTRING(@phone,3,4)
					)
				SELECT @ld = left(@phone, 2),@serie=SUBSTRING(@phone,3,4)


        end    	

      if @ld <> ''''
        begin			
		    set @rank=right(@phone, 4)

          select top 1 @location = estado, @locality = MUNICIPIO from series 
		  where cld = @ld and serie = @serie and @rank between [NUMERACION INICIAL] and [NUMERACION FINAL]

          if @location is null or not exists(select  locality from ccTimeZoneArea (nolock) where id_country=@country and area=@ld and locality=@locality)
            set @locality = null					         
        end
	else begin
		set @ld=@lada
	end

		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
          where id_country = @country and 
          area = @ld and 
		  ( @location is null or location=@location)

		return isNull(@timeZone,0)
    end

   else  if @country = 2 begin
      declare @telTemp varchar(15)
      set @telTemp = @phone
      select @phone = dbo.Completa(@phone, @pais, @lada)
      if left(@phone,1) = ''E'' begin set @phone = @telTemp end
      select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaArgDetail where
        ( len(@phone) = 6 and @lada = area and len(area) = 4 )
        or
        ( len(@phone) = 7 and @lada = area and len(area) = 3 )
        or
        ( len(@phone) = 8 and @lada = area and len(area) = 2 )
        or
        ( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
        or
        ( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
        or
        ( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
        or
        ( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
        or
        ( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
        or
        ( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 )
        if @timeZone is null
          begin
            select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
            where id_country = @country and (
              ( len(@phone) = 6 and @lada = area and len(area) = 4 )
              or
              ( len(@phone) = 7 and @lada = area and len(area) = 3 )
              or
              ( len(@phone) = 8 and @lada = area and len(area) = 2 )
              or
              ( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
              or
              ( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
              or
              ( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
              or
              ( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
              or
              ( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
              or
              ( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 ))
          end
    end

  else if @country = 3 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
    where id_country = @country and (
    ( len(@phone) = 7 and @lada = area )
    or
    ( len(@phone) = 8 and left(@phone,1) = area )
    or
    ( len(@phone) in(10,11) and (left(@phone,1) = ''3'' or substring(@phone,2,1) = ''3'')))
  end

   else if @country = 4

    begin
      select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaUsaDetail where
      ( len(@phone) = 7 and @lada = area and len(area) = 3 )
      or
      ( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 and left(right(@phone, 7), 3) = prefix)
      if @timeZone is null
        begin
          select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
          where id_country = @country and (
          ( len(@phone) = 7 and @lada = area and len(area) = 3 )
          or
          ( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
        end
    end

   else if @country = 5 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
    where id_country = @country and (
    ( len(@phone) = 6 and @lada = area )
    or
    ( len(@phone) = 7 and @lada = area )
    or
    ( len(@phone) = 8 and left(@phone,1) = area )
    or
    ( len(@phone) = 8 and left(@phone,2) = area )
    or
    ( len(@phone) = 9 and left(@phone,2) = area )
    or
    ( len(@phone) = 10 and substring(@phone,3,1) = area and left(@phone,2) = ''09'' ))
  end

  else if @country = 6 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
    where id_country = @country and (
    ( len(@phone) = 7 and @lada = area and len(area) = 3 )
    or
    ( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
  end

  else if @country = 7 begin
    declare @phoneTemp as varchar(10)
    select @phoneTemp = right ( @phone, 10 )
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
    where id_country = @country and (
    (len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
    (len(@phoneTemp) = 10 and left(@phoneTemp,5) = area ) or
    (len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
    (len(@phoneTemp) = 10 and left(@phoneTemp,4) = area ) or
    (len(@phoneTemp) = 9 and left(@phoneTemp,4) = area ) or
    (len(@phoneTemp) = 10 and left(@phoneTemp,3) = area ) or
    (len(@phoneTemp) = 10 and left(@phoneTemp,2) = area )
    )
  end

  if @country = 8 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
    where id_country = @country and (
    (len(@phone) = 7 and @lada = area) or
    (len(@phone) = 9 and substring(@phone, 2, 1) = area) or
    (len(@phone) = 10 and substring(@phone, 2, 1) = area) or
    (len(@phone) = 11 and substring(@phone, 2, 1) = area))
  end

   else if @country = 9 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    -- len(@phone) = 10
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
      where id_country = @country and (
      (convert (int, substring(@phone, 1, 4)) = convert (int, area) and len(area) = 4) or
      (convert (int, substring(@phone, 1, 2)) = convert (int, area) and len(area) = 2))
    end
  end

 else  if @country = 10 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    -- 8 <= len(@phone) <= 19
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
      where id_country = @country and (
      ((len(@phone) between  8 and  9)                                      and                   @lada = area) or
      ((len(@phone) between 10 and 11)                                      and substring(@phone, 1, 2) = area) or
      ((len(@phone) between 12 and 13) and substring(@phone, 1, 4) = ''9090'' and                   @lada = area) or
      ((len(@phone)       = 13       )                                      and substring(@phone, 4, 2) = area) or
      ((len(@phone) between 14 and 15) and substring(@phone, 1, 2) = ''90''   and substring(@phone, 5, 2) = area) or
      ((len(@phone)       = 14       ) and substring(@phone, 1, 1) = ''0''    and substring(@phone, 4, 2) = area))
    end
  end

  else if @country = 11 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  else if @country = 12 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  if @country = 13 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  else if @country = 14 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      if len(@phone) = 9 begin
        select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
        where id_country = @country and ((substring(@phone, 1, 2) = area) or (substring(@phone, 1, 3) = area))
      end
    end
  end

 else  if @country = 15 OR @country = 16  begin --Peru
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = 32
    end
  end

  return isNull(@timeZone,0)
 END'

		EXEC(@sql)

		set @process = 'CW-4506 Función Series alter GetDataPhone'
		set @sql = 'ALTER FUNCTION [dbo].[GetDataPhone] (@tel VARCHAR(32), @pais TINYINT = 1, @cldLocal VARCHAR(7) = ''55'')
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
	select @region='''',@localidad=''''
	SELECT @tel = dbo.limpia(@tel)

	if @tel='''' begin
		return ''''
	end

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

			--set @serie= substring(@tel, len(@ld) + 1, 6 - len(@ld))
			set @rank= right(@tel, 4)
			set @rankNum=cast(@rank as int)

			SELECT TOP 1 @mod = modalidad,@region = estado, @localidad = municipio
			FROM series NOLOCK
			WHERE cld = @ld AND serie = @serie AND @rankNum BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

			IF @mod NOT IN (''FIJO'', ''MPP'', ''CPP'')
			BEGIN
				RETURN ''E_'' + @tel
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
				RETURN @ld+''|''+@serie+''|''+@rank+''|''+ @tel+''|''+@region+''|''+@localidad+''|''+case @mod when ''CPP'' then ''1'' else ''0'' end +''|''+case @isLocal when 1 then ''1'' else ''0'' end
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

		RETURN @ld+''|''+@serie+''|''+@rank+''|''+ @tel+''|''+@region+''|''+@localidad+''|''+case @mod when ''CPP'' then ''1'' else ''0'' end +''|''+case @isLocal when 1 then ''1'' else ''0'' end
	END --Termina Mexico
				
	Return ''''
END
'

		EXEC(@sql)

		set @process = 'CW-4506 Función Series alter VerificaRegionLocalidad'
		set @sql = 'ALTER FUNCTION [dbo].[VerificaRegionLocalidad](@tel varchar(32),@pais tinyint = 0, @cldLocal varchar(7) = '''')
RETURNS @retVRL TABLE
(
    tel varchar(32) PRIMARY KEY NOT NULL,
    region varchar(32) NULL,
    localidad varchar(32) NULL
)
 BEGIN
 declare @ld varchar(7)
 declare @lon tinyint 
 declare @lonLd tinyint 
 declare @region varchar(20)
 declare @localidad varchar(20) 
 declare @serie varchar(10)
 
 select @region='''',@localidad=''''

 if (@pais = 0 and @cldLocal = '''') begin
	select @pais = valor from ccSettings with(nolock) where setting_id = 104
	select @cldLocal = valor from ccSettings with(nolock) where setting_id = 17
end

 select @tel = dbo.limpia(@tel)

if @pais = 1 begin --Empieza Mexico
	select @lon = len(@tel)
	if @lon in(7,8) begin
		set @tel = @cldLocal + @tel
		set @ld=@cldLocal
	end	
	
	select @tel = right(@tel, 10)
	select @lon = len(@tel)	
  if @lon = 10 begin

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

		

		if @serie is not null begin
			set @lonLd=len(@ld)
			select top 1 @region = estado, @localidad = municipio from series nolock where cld=@ld and SERIE=@serie
		end
		else begin
			select top 1 @region = estado, @localidad = municipio from series nolock where cld=@cldLocal
		end

	end
   else  begin
		if (@region is null) begin
			select top 1 @region = estado from series nolock where cld=@cldLocal
		end		
	end
end --Termina Mexico

  INSERT @retVRL
        SELECT @tel as phone, @region as estado, @localidad as municipio
  RETURN

end'

		EXEC(@sql)
		
		set @process = 'actualizacion de funcion limpiaUSA para contemplar 911'
		set @sql = 'ALTER procedure [dbo].[ccsp_LimpiaUsa]
		@tel varchar(20),
		@Camp int = 0,
		@calKey varchar(20) = ''''
		as
		set nocount on
		declare @lon tinyint
		
		select @tel = dbo.limpia(@tel)
		select @lon = len(@tel)
		
		if @lon not in (7, 10, 11) and @tel <> ''911''
		 begin
			select 1 as res, @tel as tel --Longitud invalida
			return(0)
		 end
		
		if @tel = ''911''
		 begin
		 	select 4 as res, @tel as tel -- not ok, block 911
		 	return(0)
		 end
		
		declare @ld varchar(4)
		select @ld = valor from ccsettings where setting_id = 17
		
		declare @len tinyint, @plans tinyint, @hl tinyint, @ht tinyint, @fl tinyint, @ft tinyint
		declare @plan varchar(15), @tel10 varchar(10)
		select @plan = valor from ccSettings where setting_id = 149
		select @plans = COUNT(*) from dbo.fn_RIASplitDelimited(@plan,''|'')
		if @plans = 4
		begin
			select 
			 @hl = case when id = 1 then cast(value as tinyint) else @hl end,
			 @ht = case when id = 2 then cast(value as tinyint) else @ht end,
			 @fl = case when id = 3 then cast(value as tinyint) else @fl end,
			 @ft = case when id = 4 then cast(value as tinyint) else @ft end from dbo.fn_RIASplitDelimited(@plan,''|'')
			 print @hl
		end
		else if @plans = 2
		begin
			select 
			 @hl = case when id = 1 then cast(value as tinyint) else @hl end,
			 @ft = case when id = 2 then cast(value as tinyint) else @ft end from dbo.fn_RIASplitDelimited(@plan,''|'')
			 select @ht = @hl, @fl = @ft
		end
		select @tel10 = RIGHT(@ld + @tel, 10)
		if SUBSTRING(@tel10, 1, LEN(@ld)) = @ld
		begin --HNPA
			set @len = @hl
			if @hl <> @ht and (select COUNT(*) from ccNPALocalPrefixes) > 0 and not exists(select * from ccNPALocalPrefixes where NPA+NXX = SUBSTRING(@tel10, 1, 6))
				set @len = @ht
		end
		else --FNPA
		begin
			set @len = @ft
			if @fl <> @ft and (select COUNT(*) from ccNPALocalPrefixes) > 0 and exists(select * from ccNPALocalPrefixes where NPA+NXX = SUBSTRING(@tel10, 1, 6))
				set @len = @fl
		end
		
		select @tel = case @len when 7 then SUBSTRING(@tel10, 4, 7) when 10 then @tel10 when 11 then ''1'' + @tel10 end
		
		-- lista negra
		if (select dbo.ValidateBlackListPhone(@tel,@Camp,@calKey))=1 begin
			select 4 as res, @tel as tel --blackList
			return(0)
		end	
		
		select 0 as res, @tel as tel
		
		set nocount off'
				EXEC(@sql)
				

				set @process = 'se cambia sp de login xion para que no haga update de contraseña'
				set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAChecaLogin]
		@Login varchar(20),
		@Password varchar(40),
		@Computer varchar(20),
		@PasswordLwC varchar(40) = null
		AS
		declare @LoginOK tinyint, @PswdOK tinyint, @CompuOK tinyint, @ExtenOK tinyint, @TeclaOK tinyint, @XferAgents tinyint
		declare @Nombre varchar(60), @Extension varchar(15), @UserID smallint, @CCServer varchar(20)
		
		--Para posiciones ip, by ODC
		declare @ext_id int, @pos_id int, @isIP bit, @ipExtension varchar(15)
		
		-- Para live connected
		-- Tipo de conexion: 0 normal, 1 liveconnected
		declare @tipoConexion smallint
		
		SELECT @LoginOK=0, @PswdOK=0, @CompuOK=0, @ExtenOK=0, @TeclaOK=0, @XferAgents=0,
		 @Extension='' '', @UserID='' '', @Nombre='' '', @tipoConexion = 0, @ipExtension='''', @isIP=0
		SELECT @CCServer=valor FROM ccSettings WHERE setting_id=7
		
		IF not exists(select Login from ccUsers Where Login=@Login and status>0 and tipoUser_id=1)
		  GOTO Mostrar
		else
		  set @LoginOK=1
		
		IF not exists(select Login from ccUsers Where Login = @Login
		 AND (Password=@Password OR Password = dbo.md5(@password) OR dbo.md5(Password)=@Password
		 or Password=@PasswordLwC OR Password = dbo.md5(@PasswordLwC) OR dbo.md5(Password)=@PasswordLwC)
		 and status > 0 and tipoUser_id = 1)
		  GOTO Mostrar
		else
		  set @PswdOK=1
		
		-- Se actualiza a Lower Case
		--update ccUsers with(rowlock) set Password=isnull(@PasswordLwC, Password) where Login=@Login and status>0 and tipoUser_id=1
		
		if not exists (select Computer from ccPosicion Where Status=1 and Computer=@Computer)
		  insert ccposicion (computer, ext_id) select @Computer, 0
		
		set @CompuOK = 1
		
		if not exists(select Computer from ccPosicion P join ccMonitorExt M on P.ext_id= M.ext_id
		 Where p.Status=1 and M.Status=1 and Computer=@Computer)
		  GOTO Mostrar
		else
		  set @ExtenOK=1
		
		select @Extension=Extension, @ext_id=p.ext_id, @pos_id=p.pos_id, @tipoConexion=p.tipoConexion, @isIP=isIP
		from ccPosicion P join  ccMonitorExt M on P.ext_id= M.ext_id
		Where Computer = @Computer
		
		select @TeclaOK=count(*) from ccTeclaExtensionPuerto T join ccMonitorExt M on T.ext_id=M.ext_id where M.Extension=@Extension
		
		select @UserID=user_id, @Nombre=Nombres + '' '' + isnull(ApellidoPaterno,'''') + '' '' +isnull(ApellidoMaterno,''''), @XferAgents=XferAgents
		from ccUsers Where Login = @Login AND TipoUser_id=1 AND status = 1
		
		Mostrar:
		--Para posiciones ip, by ODC
		-- No verifica ccTeclaExtensionPuerto, @TeclaOK =1
		-- Regresa un etension ''virtual''.  Debe ser diferente a cualquiera de ccMonitorExt.Extension
		IF @ext_id=0
		 BEGIN
		  select @TeclaOK =1, @Extension=cast(@pos_id * -1 as varchar(15))
		 END
		
		---Por OAYC IPExtension, extension, para cuando es posición IP con alguna extension asignada
		IF(@ext_id > 0  and @isIP=1)
		 BEGIN
		  select @TeclaOK =1, @ipExtension = @Extension, @Extension = cast( @pos_id * -1 as varchar(15))
		 END
		-----------
		
		IF @tipoConexion = 1
		  select @TeclaOK =1
		
		--  CRMx
		DECLARE @crmxActive TINYINT
		SET @crmxActive = 0
		IF (SELECT COUNT(setting_id) FROM ccsettings WHERE setting_id = 168) = 1
		  BEGIN
		    SELECT @crmxActive = valor FROM ccsettings WHERE setting_id = 168
		  END
		
		
		declare @passSecure int
		select @passSecure= valor from ccSettings where setting_id=207
		
		
		SELECT @LoginOK as [LoginOK], @PswdOK as [PswdOK], @CompuOK as [CompuOK], @ExtenOK as [ExtenOK], @Extension as [Extension],
		@UserID as [UserID], @Nombre as [Nombre], @CCServer as [CCServer], @TeclaOK as TeclaOK, @tipoConexion as TipoConexion, @ipExtension as ipExtension,
		@XferAgents as XferAgents, @crmxActive as [CRMx], @passSecure as [passSecure]
		'
		EXEC(@sql)



		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
