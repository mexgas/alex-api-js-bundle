/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Alan Minor 
Date: 2017/21/12
Description:



Database: CCenterRia
Required version: 119.10.2

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 119 sin fix
set @versionfix = 111
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and ( @actualVersionFix = 104)
	begin
		begin tran
		begin try


		set @process = 'CW-322 -- Create Table seriesPa'
    	set @Sql= 'if not exists (select * from sys.tables where name = N''seriesPa'') begin
		create table seriesPa (
		zonaGeografica varchar(50) not null
		, indicativoDestino varchar(2) not null
		, rangoInicio varchar(8) not null
		, rangoFinal varchar(8) not null
		)
end'
    	EXEC(@Sql)

		set @process = 'CW-322 -- Insertar datos en la tabla seriesPa'
		set @Sql= 'if not exists (select * from seriesPa) begin
	insert into seriesPA values(''Bocas Del Toro'', ''7'', ''0000000'', ''9999999'')
	insert into seriesPA values(''Ciudad De Panama'', ''2'', ''0000000'', ''9999999'')
	insert into seriesPA values(''Colon'', ''4'', ''0000000'', ''9999999'')
	insert into seriesPA values(''Santiago De Veraguas'', ''9'', ''0000000'', ''9999999'')
	insert into seriesPA values(''Provincia De Chiriqui'', ''5'', ''0000000'', ''9999999'')
	insert into seriesPA values(''Movil'', ''6'', ''0000000'', ''9999999'')
	insert into seriesPA values(''Provincia de Panama'', ''3'', ''0000000'', ''9999999'')'
		EXEC(@Sql)

		set @process = 'CW-322 -- Modificacion en la funcion fnGetTimeZone'
		set @Sql= 'ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
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

  select @lada = valor from ccsettings with(nolock) where setting_id = 17
  select @country = valor, @pais = valor from ccSettings with(nolock) where setting_id = 104

  select @ld = ''''
  select @location = ''''

    if @country = 1 begin

      select @phone=case when len(@phone) > 10 then RIGHT(@phone,10) when LEN(@phone)=10-LEN(@lada) then @lada+@phone else @phone  end

      if (len(@phone) = 10)
        begin
          if(exists(select top 1 cld from series with(index(IX_CLD),nolock) where cld=left(@phone,2)))
            select @ld = case when left(@phone,2) = @lada then 0 else left(@phone,2) end
          else if(exists(select top 1 cld from series nolock where cld=left(@phone,3)))
            select @ld = case when left(@phone,3) = @lada then 0 else left(@phone,3) end
        end
      else
        select @ld = 0

      if @ld <> 0
        begin
          select @location = estado, @locality = MUNICIPIO
          from series
          where cld = @ld
          and serie = substring(@phone, len(@ld) + 1, 6 - len(@ld))
          and right(@phone, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

          if not exists(select locality from ccTimeZoneArea (nolock) where area=@ld and locality=@locality)
            set @locality = null

          select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
          where id_country = @country and (
          ( len(@phone) = 8 and @lada = area and len(area) = 2 )
          or
          ( len(@phone) = 7 and @lada = area and len(area) = 3 )
          or
          ( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 )
          or
          ( len(@phone) >= 10 and left(right(@phone, 10), 2) = area and len(area) = 2 ))
          and location = @location and case when locality is null then 1 else 2 end=(case when @locality is null then 1 when locality=@locality then 2 else 0 end)
        end
      else
        begin
          select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
          where id_country = @country and (
          ( len(@phone) = 8 and @lada = area and len(area) = 2 )
          or
          ( len(@phone) = 7 and @lada = area and len(area) = 3 )
          or
          ( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 )
          or
          ( len(@phone) >= 10 and left(right(@phone, 10), 2) = area and len(area) = 2 ))
        end
    end

    if @country = 2 begin
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

  if @country = 3 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
    where id_country = @country and (
    ( len(@phone) = 7 and @lada = area )
    or
    ( len(@phone) = 8 and left(@phone,1) = area )
    or
    ( len(@phone) in(10,11) and (left(@phone,1) = ''3'' or substring(@phone,2,1) = ''3'')))
  end

  if @country = 4

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

  if @country = 5 begin
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

  if @country = 6 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
    where id_country = @country and (
    ( len(@phone) = 7 and @lada = area and len(area) = 3 )
    or
    ( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
  end

  if @country = 7 begin
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

  if @country = 9 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    -- len(@phone) = 10
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
      where id_country = @country and (
      (convert (int, substring(@phone, 1, 4)) = convert (int, area) and len(area) = 4) or
      (convert (int, substring(@phone, 1, 2)) = convert (int, area) and len(area) = 2))
    end
  end

  if @country = 10 begin
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

  if @country = 11 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  if @country = 12 begin
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

  if @country = 14 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      if len(@phone) = 9 begin
        select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
        where id_country = @country and ((substring(@phone, 1, 2) = area) or (substring(@phone, 1, 3) = area))
      end
    end
  end

  if @country = 15 OR @country = 16  begin --Peru
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = 32
    end
  end

  return isNull(@timeZone,0)
 END'
		EXEC(@Sql)

		
		set @process = 'CW-322 -- Modificacion del SP ccsp_RIAccSettingsConfig'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIAccSettingsConfig]
			@command tinyint,
			@setting_id smallint = null,
			@value varchar(200) = null
			AS
			set nocount on

			declare @idioma tinyint
			declare @activeChat tinyint

			select @idioma=valor from ccSettings where setting_id=27
			Select @activeChat=valor from ccSettings where setting_id=145

			if @command=0
			 begin
				SELECT case @idioma when 0 then descripcion else [description] end descripcion
				FROM ccSettings WITH(NOLOCK, index(PK_ccSettings)) WHERE setting_id=@setting_id
				order by descripcion
				return(0)
			 end

			if @command=1
			 begin
				Select setting_id, case @idioma when 0 then descripcion else [description] end descripcion, valor, tipo,validate
				from ccSettings WITH(NOLOCK, index(PK_ccSettings)) where tipo in (''AGT'',''ADM'',''GRL'',''REP'',''SV'')
				and (setting_id not in (139,140,141)
				or   setting_id     in (139,140,141) and @activeChat > 0)
				order by tipo, descripcion
				return(0)
			 end

			if @command=2
			 begin
				if @setting_id = 27 and @value not in(''0'',''1'') begin
					set @value = 0
				end
				else if @setting_id = 104 and @value not in(''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''9'',''10'',''11'',''12'',''13'',''14'',''15'',''16'') begin
					set @value = 1
				end
				update ccSettings set valor=@value where setting_id = @setting_id
				return(0)
			 end

			set nocount off'
		EXEC(@Sql)


		set @process = 'CW-322 -- Modificacion en la funcion Completa_ListaNegra'
		set @Sql= 'ALTER FUNCTION [dbo].[Completa_ListaNegra] (@Cadena varchar(30))
			RETURNS varchar(30) AS
			begin
			declare @resultado varchar(30), @ld varchar(6), @pais tinyint, @BLActivo tinyint

			select @ld=valor from ccSettings with(nolock) where setting_id=17
			select @pais = valor from ccsettings with(nolock) where setting_id = 104
			select @BLActivo = valor from ccsettings with(nolock) where setting_id = 114

			select @resultado=dbo.Completa(@Cadena, @pais, @ld)

			if @BLActivo = 1 begin
				if @pais in (1,4)
				 begin
					if left(@resultado, 1)=''E''
						return @resultado

					select @resultado = case
					 when len(@resultado)in(7,8) then @ld + @resultado
					 when @resultado=''911'' OR len(@resultado)=10 then @resultado
					 when len(@resultado) in (11,12,13) then right(@resultado,10)
					 else ''E_NV_Longitud''
					 end

					 return @resultado
				 end

				if @pais = 2
				 begin
					select @resultado = dbo.fnClearPhoneArg(@cadena)
					return @resultado
				 end

				if @pais = 3 and left(@resultado,1) <> ''E''
				 begin
					select @resultado = case
						when len(@resultado) = 7 then @ld + @resultado
						when len(@resultado) in(8,10) then @resultado
						when len(@resultado) = 11 then right(@resultado,10)
						else ''E_NV_Longitud'' end
					return @resultado
				 end

				if @pais = 5 and left(@resultado,1) <> ''E''
				 begin
					select @resultado = case
						when len(@resultado) in (6,7) then @ld + @resultado
						when len(@resultado) in (8,9) then @resultado
						when len(@resultado) = 10 then right(@resultado,9)
						else ''E_NV_Longitud'' end
					return @resultado
				 end

				if @pais = 6 and left(@resultado,1) <> ''E''
				begin
					select @resultado = case
						when len(@resultado) = 7 then @ld + @resultado
						when len(@resultado) = 10 then @resultado
						when len(@resultado) = 11 then right(@resultado,10)
						else ''E_NV_Longitud'' end
					return @resultado
				end

				if @pais = 7 and left(@resultado,1) <> ''E''
				begin
					select @resultado = right(@resultado,10)
					return @resultado
				end

				if @pais = 8
				begin
					if left(@resultado,1) = ''E''
					begin
						return @resultado
					end
					select @resultado = case
						when len(@resultado) = 7 then ''0'' + @ld + @resultado
						when len(@resultado) = 9 and substring(@resultado,1,1) = ''0'' then @resultado
						when len(@resultado) = 10 and substring(@resultado,2,1) = ''5'' then @resultado
						when len(@resultado) = 11 and substring(@resultado,3,3) in (''111'',''510'',''511'') then @resultado
						else ''E_NV_Longitud'' end
					return @resultado
				end

				if @pais = 9 and left(@resultado,1) <> ''E''
				begin
					return @resultado
				end


				-- Brasil
				if @pais = 10 and left(@resultado,1) <> ''E''
				begin
					return @resultado
				end

				--Guatemala
				if @pais = 11 and left(@resultado,1) <> ''E''
				begin
					return @resultado
				end

				--Costa Rica
				if @pais = 12 and left(@resultado,1) <> ''E''
				begin
					return @resultado
				end

				--Salvador
				if @pais = 13 and left(@resultado,1) <> ''E''
				begin
					return @resultado
				end

				--Spain
				if @pais = 14 and left(@resultado,1) <> ''E''
				begin
					return @resultado
				end

				--Peru
				if @pais = 15 and left(@resultado,1) <> ''E''
				begin
					return @resultado
				end

				--Panama
				if @pais = 16 and left(@resultado,1) <> ''E''
				begin
					return @resultado
				end
			end
			else begin
			 select @resultado = dbo.Limpia(@cadena)
			end

			return @resultado
			end'
		EXEC(@Sql)


		set @process = 'CW-322 -- Modificacion n la funcion TelAni'
		set @Sql= 'ALTER function [dbo].[TelAni](@tel varchar(32), @lista smallint)
			RETURNS varchar(32)
			AS
			BEGIN
			--declare @edo varchar(250)
			declare @cldLocal varchar(10), @pais tinyint, @lon tinyint, @ret as varchar(10)

			select  @cldLocal = valor from ccsettings where setting_id = 17
			select @pais = valor, @ret = '''' from ccSettings where setting_id = 104

				if @lista = 0 begin
					select @tel = ''''
				end

				if @pais = 1 begin --Empieza Mexico
					select @lon = len(@tel)
					if @lon >= 7 and @lon <=13 begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and
						(( len(@tel) = 8 and @cldlocal = area and len(area) = 2 )
							or
							( len(@tel) = 7 and @cldlocal = area and len(area) = 3 )
							or
							( len(@tel) >= 10 and left(right(@tel, 10), 3) = area and len(area) = 3 )
							or
							( len(@tel) >= 10 and left(right(@tel, 10), 2) = area and len(area) = 2 ))
					end
					else begin
						select @tel = ''''
					end

					return @tel
				end --Termina Mexico

				if @pais = 2 begin  -- Empieza Argentina
					select @lon = len(@tel)
					if @lon >= 6 and @lon <=13 begin
						select @tel = telAni from ccEstadosAni where id_anilist = @lista and
							(( @lon = 6 and left(@tel,4) = area and len(area) = 4 )
							or
							( @lon = 7 and left(@tel,3) = area and len(area) = 3 )
							or
							( @lon = 8 and left(@tel,2) = area and len(area) = 2 )
							or
							( @lon = 11 and substring(@tel, 2, 2) = area and len(area) = 2 )
							or
							( @lon = 11 and substring(@tel, 2, 3) = area and len(area) = 3 )
							or
							( @lon = 11 and substring(@tel, 2, 4) = area and len(area) = 4 )
							or
							( @lon = 13 and substring(@tel, 2, 2) = area and len(area) = 2 )
							or
							( @lon = 13 and substring(@tel, 2, 3) = area and len(area) = 3 )
							or
							( @lon = 13 and substring(@tel, 2, 4) = area and len(area) = 4 ))
					end
					else begin
						select @tel = ''''
					end
						return @tel
				end  --Termina Argentina

				if @pais = 3 begin  --Empieza Colombia
					select @lon = len(@tel)
					if @lon >= 6 and @lon <=13 begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and
							(( len(@tel) = 7 and @cldlocal = area )
							or
							( len(@tel) = 8 and left(@tel,5) = area )
							or
							( len(@tel) in(10,11) and (left(@tel,1) = ''3'' or substring(@tel,2,1) = ''3'')))
					end
					else begin
						select @tel = ''''
					end
					return @tel
				end  --Termina Colombia

				if @pais = 4 begin --Empieza USA
					select @lon = len(@tel)
					if @lon >= 6 and @lon <=15 begin
						if @lon = 7 begin
							set @tel = @cldLocal + @tel
						end
						set @tel = right(@tel, 10)
						--select @edo = location from ccTimeZoneAreaUsa where area = left(@tel,3)
						select @tel = telani from ccEstadosAni where area = left(@tel,3) and id_anilist = @lista
					end
					else begin
						select @tel = ''''
					end
					return @tel
				end --Termina USA

				if @pais = 5 begin -- Empieza Chile
					select @lon = len(@tel)
					if @lon >= 6 and @lon <=15 begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and
						(( len(@tel) = 6 and @cldlocal = area )
						or
						( len(@tel) = 7 and @cldlocal = area )
						or
						( len(@tel) = 8 and left(@tel,1) = area )
						or
						( len(@tel) = 8 and left(@tel,2) = area )
						or
						( len(@tel) = 9 and left(@tel,2) = area )
						or
						( len(@tel) = 10 and substring(@tel,3,1) = area and left(@tel,2) = ''09'' ))
					end
					else begin
						select @tel = ''''
					end
					return @tel
				end --Termina Chile

				if @pais = 6 begin -- Venezuela
					select @lon = len(@tel)
					if @lon >= 7 and @lon <=11 begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and
							(len(@tel) = 7 and left(@tel,3) = area or
							len(@tel) = 11 and substring(@tel,2,3) = area)
					end
					else begin
						select @tel = ''''
					end

					return @tel
				end --Termina Venezuela

				if @pais = 7 begin -- Empieza UK
					select @lon = len(@tel)
					if left(@tel,1) = ''0'' begin
						set  @tel = substring(@tel,2,(len(@tel)-1))
					end

					if @lon >= 9 and @lon <=11 begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and
						(( len(@tel) = 10 and substring(@tel,1,5) = area )
						or
						( len(@tel) = 10 and substring(@tel,1,4) = area )
						or
						( len(@tel) = 10 and substring(@tel,1,3) = area )
						or
						( len(@tel) = 10 and substring(@tel,1,2) = area )
						or
						( len(@tel) = 9 and substring(@tel,1,5) = area )
						or
						( len(@tel) = 9 and substring(@tel,1,4) = area ) )
					end
					else begin
						select @tel = ''''
					end
					return @tel
				end --Termina UK

				if @pais = 8 begin --Empieza Arabia Saudita
					select @lon = len(@tel)
					if @lon >= 7 and @lon <=13 begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and
							(len(@tel) = 7 and ''0''+@cldlocal + ''-''+ substring(@tel,1,1) + ''00'' = area or
							len(@tel) = 9 and substring(@tel,1,3) + ''00'' = replace(area,''-'','''') or
							len(@tel) = 10 and substring(@tel,1,4) + ''00'' = replace(area,''-'','''') or
							len(@tel) = 11 and substring(@tel,1,4)+ ''0'' = replace(area,''-'','''') or
							len(@tel) = 11 and substring(@tel,1,5) = replace(area,''-'',''''))
					end
					else begin
						select @tel = ''''
					end

					return @tel
				end --Termina Arabia Saudita

				if @pais = 9 --Empieza Australia
					begin
						select @lon = len(@tel)
						if @lon >= 8 and @lon <=10
							begin
								select @tel = telani from ccEstadosAni where id_anilist = @lista
								and (len(@tel) = 8 and @cldLocal + substring(@tel,1,2) = area or
									 len(@tel) = 9 and ''0'' + substring(@tel,1,3) = area or
									 len(@tel) = 10 and substring(@tel,1,4) = area)
							end
						else
							begin
								select @tel = ''''
							end

						return @tel
					end --Termina Australia

				if @pais = 10 begin -- Empieza Brasil
					select @lon = len(@tel)
					if @lon >= 8 and @lon <=15 begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and (
							((@lon       = 8        )                                    and             @cldlocal = area) or
							((@lon       = 9        ) and substring(@tel, 1, 1) = ''9''    and             @cldlocal = area) or
							((@lon between 10 and 11)                                    and substring(@tel, 1, 2) = area) or
							((@lon between 12 and 13) and substring(@tel, 1, 4) = ''9090'' and             @cldlocal = area) or
							((@lon       = 13       )                                    and substring(@tel, 4, 2) = area) or
							((@lon between 14 and 15) and substring(@tel, 1, 2) = ''90''   and substring(@tel, 5, 2) = area) or
							((@lon       = 14       ) and substring(@tel, 1, 1) = ''0''    and substring(@tel, 4, 2) = area))
					end
					else begin
						select @tel = ''''
					end

					return @tel
				end -- Termina Brasil

				if @pais = 11 begin --Empieza Guatemala
					if len(@tel) = 8  begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
					end
					else begin
						select @tel = ''''
					end

					return @tel
				end --Termina Guatemala

				if @pais = 12 begin --Empieza Costa Rica
					if len(@tel) = 8  begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
					end
					else if len(@tel) = 10 begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 3) = area
					end
					else begin
						if charindex(substring(@tel,1,2),''00,08'') <= 0
							select @tel = ''''
						else
							select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 2) = area
					end

					return @tel
				end --Termina Costa Rica

				if @pais = 13 begin --Empieza Salvador
					if len(@tel) = 8  begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
					end
					else begin
						if charindex(substring(@tel,1,2),''00'') <= 0
							select @tel = ''''
						else
							select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 2) = area
					end

					return @tel
				end --Termina Salvador

				if @pais = 14 begin --Empieza España
					if len(@tel) = 9  begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and
						((substring(@tel, 1, 1) = area) or
						(substring(@tel, 1, 2) = area) or
						(substring(@tel, 1, 3) = area))
					end
					else
						select @tel = ''''

					return @tel
				end --Termina España

				if @pais = 15 begin -- Empieza Peru
					select @lon = len(@tel)
					if @lon >= 6 and @lon <=9 begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and
						(( len(@tel) = 6 and @cldlocal = area )
						or
						( len(@tel) = 7 and @cldlocal = area )
						or
						( len(@tel) = 9 and left(@tel,1)=''0'' and substring(@tel,2,len(@cldlocal)) = area ))
					end
					else begin
						select @tel = ''''
					end
					return @tel
				end --Termina Peru

				if @pais = 16 begin --Empieza Panama
					if len(@tel) = 7  begin
						select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
					end
					else begin
						if charindex(substring(@tel,1,2),''00'') <= 0
							select @tel = ''''
						else
							select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 2) = area
					end

					return @tel
				end --Termina Panama

				return @ret
			END'
		EXEC(@Sql)


		set @process = 'CW-322 -- Modificacion del SP ccsp_Limpia'
		set @Sql= 'ALTER procedure [dbo].[ccsp_Limpia]
			@tel varchar(30),
			@Camp int = 0
			as
			set nocount on
			declare @lon tinyint, @ld varchar(4), @pais varchar(3), @extLen smallint, @manOpt smallint
			select @tel = dbo.limpia(@tel)
			select @lon = len(@tel)
			select @pais = valor from ccSettings with(nolock) where setting_id = 104
			select @ld = valor from ccSettings with(nolock) where setting_id = 17
			select @extLen = valor from ccsettings with(nolock) where setting_id = 108
			select @manOpt = valor from ccsettings with(nolock) where setting_id = 195
			declare @telTemp as varchar(15)

			if @extLen=@lon and @lon>1
			 begin
				select 0 as res, @tel as tel -- Extension
				return(0)
			 end

			if @pais = 1
			 begin
				if @lon = 3 and @tel = ''911''
				begin
					select 4 as res, @tel as tel
					return(0)
				end

				if @lon < 7 or @lon = 7 and len(@ld) = 2 or @lon = 8 and len(@ld) = 3 or @lon in (9, 11) or @lon > 13
				 begin
					select 1 as res, @tel as tel --Longitud invalida
					return(0)
				 end

				if @lon = 12 and left(@tel, 2) <> ''01'' or @lon = 13 and left(@tel, 3) <> ''044'' and left(@tel, 3) <> ''045'' and left(@tel, 3) <> ''001''
				 begin
					select 2 as res, @tel as tel--Digitos incorrectos
					return(0)
				 end

				if left(@tel, 3) = ''001''
				 begin
					select 0 as res, @tel as tel
					return(0)
				 end

				declare @mod varchar(5)
				select @tel = case when @lon in (7, 8) then @ld + @tel else right(@tel, 10) end
				select @mod = modalidad from series where cld + serie = left(@tel, 6) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

				if exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra))
				on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
				 begin
					select 4 as res, @tel as tel
					return(0)
				 end

				if @mod = ''CPP''
				 begin
					select 0 as res, case left(@tel, len(@ld)) when @ld then ''044'' else ''045'' end + @tel as tel
					return(0)
				 end

				if @mod in (''FIJO'', ''MPP'')
				 begin
					if @manOpt = 1 --10 digits
					begin
						set @lon = len(@tel)
						if @lon = 10 - len(@ld)
							set @tel = @ld + @tel

						if @lon = 12 and left(@tel, 2) = ''01''
							set @tel = right(@tel, 10)
						select 0 as res, @tel
					end
					else
						select 0 as res, case left(@tel, len(@ld)) when @ld then right(@tel, 10 - len(@ld)) else ''01'' + @tel end as tel
					return(0)
				 end

				--if @mod is null
				select 3 as res, @tel as tel--No encontrado
				return(0)
			 end

			if @pais = 2
			 begin
				select @telTemp = @tel
				set @tel = dbo.completa(@tel, @pais, @ld)
				if left(@tel,1)=''E'' begin
					select 1 as res, @telTemp --Longitud Invalida
					return
				end

				select @tel = dbo.fnClearPhoneArg(@tel)

				if (len(@tel) = 10 or len(@ld + @tel) = 10) and left(@tel,1) <> ''E'' begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and (telefono = @tel or telefono= @ld + @tel) and status=1)
				   begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					end else begin
						select 4 as res, @tel
						return(0)
					end
				end else begin select 2 as res, @telTemp as tel end --Digitos incorrectos
			 end

			if @pais = 3
			 begin
				select @telTemp = @tel
				if @lon < 7 or @lon = 9 or (@lon = 10 and  left(@telTemp,1) <> ''3'') or (@lon = 11 and  left(@telTemp,2) <> ''03'') begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				end
				select @tel = dbo.Completa_ListaNegra(@tel)

				if (len(@tel) = 8 or len(@tel) = 10) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 4
			 begin
				exec ccsp_LimpiaUsa @tel, @Camp
				return(0)
			 end

			if @pais = 5
			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)

				if len(@tel) in(8,9) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 6
			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)


				if len(@tel) = 10 and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 7

			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)

				if (len(@tel) = 9 or len(@tel) = 10) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin

						select @tel = dbo.verifica(@tel)
						if left(@tel,1)=''E'' begin
							select 3 as res, @telTemp -- No existe el telefono
						end
						else begin
							select 0 as res, @telTemp  -- Todo Bien
						end
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel --lista negra
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end


			if @pais = 8
			 begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)

				if left(@tel,1)=''E'' begin
					select 1 as res, @telTemp --Longitud Invalida
					return (0)
				end

				if (len(@tel) = 9 or len(@tel) = 10 or len(@tel) = 11 )
				begin
					if not exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra)) on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					end
					else
					begin
						select 4 as res, @tel
						return(0)
					end
				end
			 end

			if @pais = 9 --Australia
			 begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)

				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			 end

			if @pais = 10 -- Brasil
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				set @lon = len(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 11 -- Guatemala
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 12 -- Costa Rica
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 13 -- Salvador
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 14 -- Spain
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end


			if @pais = 16 -- Panama
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end'
		EXEC(@Sql)


		set @process = 'CW-322 -- Modificacion a la funcion Verifica'
		set @Sql= 'ALTER FUNCTION [dbo].[Verifica](@tel varchar(32))
			RETURNS varchar(32) AS
			 BEGIN
				declare @ld varchar(7)
				declare @lon tinyint
				declare @result tinyint
				declare @mod varchar(10)
				declare @Cadena varchar(32)
				declare @cldLocal varchar(7)
				declare @pais tinyint

				select @cldLocal = valor from ccsettings with(nolock) where setting_id = 17
				select @pais = valor from ccSettings with(nolock) where setting_id = 104
				select @tel = dbo.limpia(@tel)

				if @pais = 1 begin --Empieza Mexico
					select @lon = len(@tel)
					if @lon between 7 and 8 begin
						set @tel = @cldLocal + @tel
					end
					select @tel = right(@tel, 10)
					select @lon = len(@tel)

					if @lon = 10 begin

						if(exists(select top 1 cld from series nolock where cld=left(@tel,2)))
							select @ld = left(@tel,2)
						else if(exists(select top 1 cld from series nolock where cld=left(@tel,3)))
							select @ld = left(@tel,3)
						else
							return ''E_'' + @tel

						select @mod = modalidad from series nolock where cld = @ld and serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

						select @tel = case
							when @mod in (''FIJO'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''01'' + @tel end
							when @mod = ''CPP'' then case when @ld = @cldLocal then ''044'' + @tel else ''045'' + @tel end
							else ''E_'' + @tel
						end
					end else begin
						if @lon > 0 begin
							select @tel = ''E_'' + @tel
						end
					end
					return @tel
				end --Termina Mexico

				-- Empieza Argentina
				if @pais = 2 begin
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
					if left(@tel,1) = ''E'' begin return @tel end
					select @lon = len(@tel)
					if @lon in(6,7,8) and left(@tel,2) <> ''15'' begin
						set @tel = @cldLocal + @tel
					end

					if @lon in (8,9,10) and left(@tel,2) = ''15'' begin
						set @tel = @cldLocal + substring(@tel,3,@lon - 2)
					end

					--Buscamos el 15
					if @lon = 13 begin
						declare @index as int
						select @index = charindex(''15'',@tel)
						--El unico caso en el que la lada tiene un 15 es con lada 3715
						if @index < 2 begin
							select @tel = ''E_'' + @tel
							return @tel
						end
						else begin
							if substring(@tel,@index-2,4) = ''3715''
								begin
									select @ld = ''3715''
									set @tel = @ld + right(@tel,6)
								end
							else
								begin
									select @ld = substring(@tel,2,@index-2)
									set @tel = @ld + right(@tel,13 - (@index + 1))
								end
						end
					end

					select @tel = right(@tel, 10)

					if len(@tel) = 10 begin
						declare @serie as varchar(5)
						begin
							-- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
							declare @contLD as int
							declare @cont as int
							set @contLD=4
								BuscaLada:
								if isnull(@ld,'''') = '''' and @contLD >= 2
									begin
										select @ld = cld from seriesArg where cld=left(@tel,@contLD)
										if isnull(@ld,'''') = '''' begin
											set @contLD = @contLD - 1
											goto BuscaLada
										end
									end
								else begin
										if isnull(@ld,'''') = '''' begin
											select @tel = ''E_'' + @tel
										end
								end
						end

						-- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
						begin
						if len(@ld) = 2 begin
								set @cont = 5
								buscaSerie2:
								if isnull(@serie,'''') = '''' and @cont >= 4 begin
									select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,3,@cont)
									if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie2 end
								end
						end
						else begin
							if len(@ld) = 3 begin
								set @cont = 4
								buscaSerie3:
								if isnull(@serie,'''') = '''' and @cont >= 3 begin
									select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,4,@cont)
									if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie3 end
								end
							end
							else begin
								if len(@ld) = 4 begin
									set @cont = 3
									buscaSerie4:
									if isnull(@serie,'''') = '''' and @cont >= 2 begin
										select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,5,@cont)
										if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie4 end
									end
								end
							end
						end

						end

						select @mod = modalidad from seriesArg where cld = @ld and serie = @serie and right(@tel, 10 - len(@ld) - len(@serie)) between [NUMERACION INICIAL] and [NUMERACION FINAL]

						-- Si la serie es nula, existe una posibilidad de que la lada este mal, asi que se quita un numero de la lada y se vuelve a buscar la serie
						--select @ld,@serie,@mod,@contLD
						if isNull(@serie,'''') = '''' and @contLD>1 begin
						set @contLD = len(@ld) - 1
						set @ld = null
						goto BuscaLada
						end

						select @tel = case
							when @mod in (''BASICA'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''0'' + @tel end
							when @mod = ''CPP'' then case when @ld = @cldLocal then ''15'' + right(@tel,10-len(@ld)) else ''0'' + @ld + ''15'' + right(@tel,10-len(@ld)) end
							else ''E_'' + @tel
						end
					end else begin
						if len(@tel) > 0 begin
							select @tel = ''E_'' + @tel
						end
					end
					return @tel
				end  --Termina Argentina

				if @pais = 3 begin  --Empieza Colombia
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
					if left(@tel,1) = ''E'' begin
						return @tel
					end

					if len(@tel) not in (7,8,10,11) begin
						return ''E_'' + @tel
					end

					if len(@tel) = 7 begin
						if exists(select serie from seriesCol where serie = left(@tel,4) and @cldLocal = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end

					if len(@tel) = 8 begin
						if exists(select serie from seriesCol where serie = substring(@tel,2,4) and left(@tel,1) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end

					if len(@tel) = 10 begin
						if exists(select serie from seriesCol where serie = substring(@tel,5,3) and (left(@tel,3) + ''-'' + substring(@tel,4,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end

					if len(@tel) = 11 begin
						if exists(select serie from seriesCol where serie = substring(@tel,6,3) and (substring(@tel,2,3) + ''-'' + substring(@tel,5,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end
				end  --Termina Colombia

				-- Empieza Chile
				if @pais = 5 begin
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
					if left(@tel,1) = ''E'' begin
						return @tel
					end

					if len(@tel) = 6 and len(@cldLocal) = 2 begin
						if exists(select serie from seriesChi where cld = @cldLocal and left(@tel,3) = serie and right(@tel,3) between numeracioninicial and numeracionFinal) begin
							return @tel
						end
						else begin return ''E_'' + @tel end
					end

					if len(@tel) = 7 begin
						if @cldLocal in (2,41,44,32) begin
							if exists(select serie from serieschi where serie = left(@tel,4)) begin return @tel end
							else begin
								if left(@tel,3) = ''200'' and exists(select serie from serieschi where serie = left(@tel,3) ) begin return @tel end
							end
						end
					end

					if len(@tel) = 8 begin
						if left(@tel,1) = ''2'' begin
								if exists(select serie from serieschi where serie = substring(@tel,2,4)) begin return @tel end
								else begin
									if exists(select serie from serieschi where serie = substring(@tel,2,5)) begin return @tel end
									else begin return ''E_'' + @tel end
								end
						end
						else begin
							return @tel
						end
					end

					if len(@tel) = 10 begin
						if left(@tel,2) = ''09'' begin
							if exists(select serie from serieschi where cld=substring(@tel,3,1) and serie = substring(@tel,5,3)) begin
								return @tel
							end
							else begin
								return ''E_'' + @tel
							end
						end

					end
				end
				--Termina Chile

				if @pais = 6 begin --Empieza Venezuela
					select @lon = len(@tel)
					if @lon = 7  begin
						set @tel = @cldLocal + @tel
					end

					select @tel = right(@tel, 10)

					if len(@tel) = 10 begin
						select @ld = left(@tel,3)
						select @mod = tipo from seriesVen where left(@tel,3) = LD

						if @mod = ''CPP'' begin
							if exists( select * from seriesVen where LD = @ld ) begin
								if @ld = @cldLocal begin
									select @tel = right(@tel,7)
								end
								else begin
									select @tel = ''0'' + @tel
								end
							end
							else begin
								select @tel = ''E_'' + @tel
							end
						end
						else begin
							if @mod = ''FIJO'' begin
								if exists( select serie from seriesVen where serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [Inicio] and [Fin]) begin
									if @ld = @cldLocal begin
										select @tel = right(@tel,7)
									end
									else begin
										select @tel = ''0'' + @tel
									end
								end
								else begin
									select @tel = ''E_'' + @tel
								end
							end
							else begin
								select @tel = ''E_'' + @tel
							end
						end
					end
					else begin
						if len(@tel) > 0 begin
							select @tel = ''E_'' + @tel
						end
					end
					return @tel
				end --Termina Venezuela

				if @pais = 7 begin -- Empieza UK
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
					if left(@tel, 1) = ''E'' begin -- regresa error por longitud
						return @tel
					end
					select @lon = len(@tel)

					--numeros no geograficos
					if (left(@tel, 2) in(''03'', ''07'', ''09'') and @lon <> 11) or (left(@tel, 3) in(''055'', ''056'', ''070'') and @lon <> 11) begin
						return ''E_'' + @tel --error por longitud con lada correcta
					end
					else begin
						if left(@tel, 7) in(''0845464'') or left(@tel, 5) = ''07624'' or left(@tel, 4) in(''0500'', ''0800'') or left(@tel, 3) in(''055'', ''056'', ''070'', ''76'') or left(@tel, 2) in(''03'', ''07'', ''08'', ''09'') begin
							return @tel; --longitud correcta y numero no geografico
						end
					end

					--numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
					if (left(@tel, 7) in(''0159575'', ''0159576'')) or
						(left(@tel, 5) in(''02820'',''02821'',''02825'',''02827'',''02828'',''02829'',''02830'',''02837'',''02838'',''02840'',''02841'',''02842'',''02843'',''02844'',''02866'',''02867'',''02868'',''02870'',''02871'',''02877'',''02879'',''02880'',''02881'',''02882'',''02885'',''02886'',''02887'',''02889'',''02890'',''02891'',''02892'',''02893'',''02894'',''02895'',''02897'') and @lon = 11) or --claves 2xxx tienen formato 4-6
						(left(@tel, 4) in(''0113'', ''0114'',''0115'',''0116'',''0117'',''0118'',''0121'',''0131'',''0141'',''0151'',''0161'',''0238'',''0239'') and @lon = 11) or --3-digit area codes have 7-digit subscribers.
						(left(@tel, 3) in(''020'',''024'',''029'') and @lon = 11) begin --2-digit area codes have 8-digit subscribers.
						return @tel;
					end

					--numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
					if left(@tel, 2) = ''01'' begin
						select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,4) --mayor numero de ladas (va primero por ser mas probable)
						if @ld > 0 begin
							return @tel;
						end
						else begin
							select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,5) --ladas restantes
							if @ld > 0 begin
								return @tel;
							end
						end
					end --si no encontro ni error ni coincidencia entonces esta mal
					return ''E_'' + @tel
				end --Termina UK

				if @pais = 8 begin --Empieza Arabia Saudita
					select @tel = dbo.completa(@tel, @pais, @cldLocal)
					select @lon = len(@tel)
					if @lon = 7 begin
						set @tel = ''0'' + @cldLocal + @tel
					end
					select @lon = len(@tel)

					if @lon = 9 begin
						if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,2) = cld) begin
							if (substring(@tel,2,1) = @cldLocal)
							begin
								return right(@tel,7)
							end else begin
								return @tel
							end
						end
						else begin
							return ''E_'' + @tel
						end
					end
					if @lon = 10 begin
						if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,4,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,3) = cld) begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end
					if @lon = 11 begin
						if exists(select regiones,* from seriesSA where right(@tel,6) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 6 and left(@tel,2) = cld) begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end
				end --Termina Arabia Saudita

				if @pais = 9
					begin --Empieza Australia
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						select @lon = len(@tel)

						if left(@tel,1) <> ''E''
							begin
								if exists(select Regiones
										  from SeriesAU
										  where convert(int,LD) = convert(int,substring(@tel, 1, 2))
										  and convert(int,AreaCode) = convert(int,substring(@tel, 3, 2))
										  and convert(int,substring(@tel, 5, 6)) between convert(int,SerieInicio) and convert(int,SerieFin))
									begin
										return @tel
									end
								else
									begin
										return ''E_'' + @tel
									end
							end
						else
							begin
								return @tel
							end
					end --Termina Australia

				if @pais= 10
					begin -- Inicia Brasil
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						select @lon = len(@tel)
						if left(@tel,1) <> ''E''
							begin
								if @lon in (8,9) begin --numero local
									if exists(
									select Regiones
										from seriesBR where
											convert(int,AreaCode) = convert(int,@cldLocal) and
											convert(int,@tel) between convert(int,SerieInicio) and convert(int,SerieFin)
									)
									begin
										return @tel
									end
									else begin
										return ''E_'' + @tel
									end
								end
								if @lon in (10,11) begin --numero nacional
									if exists(
									select Regiones
										from seriesBR where
											convert(int,AreaCode) = convert(int,left(@tel,2)) and
											convert(int,right(@tel, @lon-2)) between convert(int,SerieInicio) and convert(int,SerieFin)
									)
									begin
										return @tel
									end
									else begin
										return ''E_'' + @tel
									end
								end
							end

						else begin
							return @tel
						end
					end -- Termina Brasil

				if @pais= 11
					begin -- Inicia Guatemala
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						if left(@tel,1) <> ''E''
							begin
								if exists(select zonaGeografica from seriesGT (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
									return @tel
								else
									return ''E_'' + @tel
							end
						else
							return @tel
					end -- Termina Guatemala

					if @pais= 12
					begin -- Inicia Costa Rica
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						if left(@tel,1) <> ''E''
							begin
								if len(@tel)=8
									if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
										return @tel
									else
										return ''E_'' + @tel
								else if len(@tel)=10 begin
									if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,3) and right(@tel, 7) between rangoInicio and rangoFinal)
										return @tel
									else
										return ''E_'' + @tel
								end
								else
									if charindex(substring(@tel,1,2),''00,08'') <= 0
										return ''E_'' + @tel
									else
										return @tel
							end
					end -- Termina Costa Rica

				if @pais= 13
					begin -- Inicia Salvador
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						if left(@tel,1) <> ''E''
							begin
								if len(@tel)=8
									if exists(select zonaGeografica from seriesSV (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
										return @tel
									else
										return ''E_'' + @tel
								else
									if charindex(substring(@tel,1,2),''00'') <= 0
										return ''E_'' + @tel
									else
										return @tel
							end
					end -- Termina Salvador

				if @pais= 14
					begin -- Inicia Spain
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						if left(@tel,1) <> ''E''
							begin
								if len(@tel)=9
									if exists(select provincia from seriesEsp (nolock) where indicativo = substring(@tel,1,1) and right(@tel, 8) between numInicial and numFinal)
										return @tel
									else
										return ''E_'' + @tel
								else
									if charindex(substring(@tel,1,2),''00'') <= 0
										return ''E_'' + @tel
									else
										return @tel
							end
					end -- Termina España

				if @pais= 15 begin --Inicia Peru
					select @tel = dbo.Completa(@tel, @pais, @cldLocal)
					select @lon = len(@tel)
					if @lon between 6 and 7 begin
						set @tel = @cldLocal + @tel
					end
					select @tel = right(@tel, 9)
					select @lon = len(@tel)
					if left(@tel,1) <> ''E'' begin
						if @lon = 9 begin
							if exists(select zonaGeografica from seriesPE (nolock) where
								left(@tel,1) = 9 or
								substring(@tel,2,1) = 1 and areaNumeracion = 1 and right(@tel, 7) between rangoInicio and rangoFinal or
								substring(@tel,2,1) <> 1 and left(@tel,2) = areaNumeracion and right(@tel, 7) between rangoInicio and rangoFinal
							)
								return @tel
							else
								return ''E_'' + @tel
						end
					end
				end --Termina Peru

				if @pais= 16
					begin -- Inicia Panama
						select @tel = dbo.completa(@tel, @pais, @cldLocal)
						if left(@tel,1) <> ''E''
							begin
								if len(@tel)=7
									if exists(select zonaGeografica from seriesPa (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
										return @tel
									else
										return ''E_'' + @tel
								else
									if charindex(substring(@tel,1,2),''00'') <= 0
										return ''E_'' + @tel
									else
										return @tel
							end
					end -- Termina Salvador

				return @tel
			end'
		EXEC(@Sql)


		set @process = 'CW-322 -- Modificacion a la funcion Completa'
		set @Sql= 'ALTER function [dbo].[Completa](@Cadena varchar(32), @pais varchar(2) = '''', @ld varchar(5) = '''')
			RETURNS varchar(32)
			AS
			BEGIN
			declare @resultado varchar(32)

			if (@pais = '''' and @ld = '''')
				begin
					select @pais = valor from ccSettings with(nolock) where setting_id = 104
					select @ld = valor from ccSettings with(nolock) where setting_id = 17
				end
			select @resultado = dbo.limpia(@Cadena)

			--Completa 1:México 2:Argentina 3:Colombia 4:USA 5:Chile 6: venezuela 7: UK 8: arabia saudita 9: Australia 10:Brasil 11:Guatemala 12:Costa Rica 13:Salvador
			if @pais = 1
			 begin
				--Empieza Mexico
				select @resultado = case
				 when (len(@resultado)=8 and len(@ld)=2) or (len(@resultado)=7 and len(@ld)=3) then @resultado
				 when len(@resultado)=10 then
				   case when left(@resultado, len(@ld)) = @ld
					then right(@resultado, 10 - len(@ld)) else ''01'' + @resultado end
				 when len(@resultado)=12 then
				   case when left(@resultado, 2) = ''01'' then
					 case when substring(@resultado, 3, len(@ld)) = @ld
					   then right(@resultado, 10 - len(@ld)) else @resultado end
					else ''E_NV_LD'' end
				 when len(@resultado)=13 then
				   case when left(@resultado, 3) in (''044'', ''045'') then
					 case when substring(@resultado, 4, len(@ld)) = @ld then
					   ''044'' + right(@resultado, 10) else ''045'' + right(@resultado, 10)
					 end
				   else ''E_NV_Cel'' end
				else ''E_NV_Longitud'' end

				--Termina Mexico
				return @resultado
			 end

			if @pais = 2
			 begin
				-- Empieza Argentina
				select @resultado = case
				 when (len(@resultado)=7 and len(@ld)=3) or (len(@resultado)=6 and len(@ld)=4) then
					@resultado
				-- cuando son 8 digitos y la lada es de 2 digitos, se regresa el telefono tal cual
				-- cuando la lada es de 4 digitos, se revisa la posibiidad de que sea un celular, si es asi se regresa
				 when len(@resultado) = 8 then
					case when len(@ld) = 4 then
						case when left(@resultado,2) = ''15'' then @resultado end
					else
						case when len(@ld) = 2 then @resultado end
					end
				-- Este caso solamente es cuando el telefono es un celular y la lada es de 3 digitos
				 when len(@resultado)=9 then
					case when left(@resultado, 2) = ''15'' then @resultado else ''E_NV_Cel'' end
				-- Cuando son 10 numeros y la lada es igual, solo se marcan los numeros restantes para llamada local
				 -- Si es diferente se le agrega un 0 para llamadas de larga distancia
				 when len(@resultado)=10 then
				   case when left(@resultado, len(@ld)) = @ld
					then right(@resultado, 10 - len(@ld)) else
						case when left(@resultado,2) = ''15'' then @resultado else ''0'' + @resultado end
				   end
				-- Cuando el numero telefonico viene con un 0 al inicio, se verifica la lada
				-- si no es la misma lada, pero el telefono empieza con 0, se regresa tal cual
				 when len(@resultado)=11 then
				   case when left(@resultado, 1) = ''0'' then
					 case when substring(@resultado, 2, len(@ld)) = @ld
					   then right(@resultado, 10 - len(@ld)) else @resultado end
					else ''E_NV_LD'' end
				-- Celular, si tiene 12 numeros y el numero es local, solo se marca el 15 y el numero
				-- si no es local se le agrega el 0 y se marca el numero
				 when len(@resultado)=12 then
					case when left(@resultado, len(@ld)) = @ld then
						case when substring(@resultado, len(@ld) + 1, 2) = ''15'' then
							right(@resultado,12 - len(@ld)) else ''E_NV_Cel'' end else ''0'' + @resultado end
				-- Celular, con 0 al inicio si es local, quita el area y marca apartir del 15, si no, lo regresa igual
				 when len(@resultado)=13 then
					case when left(@resultado, 1) = ''0'' then
						case when substring(@resultado, 2, len(@ld)) = @ld then substring(@resultado, len(@ld) + 2, 12 - len(@ld)) else @resultado end
					else ''E_NV_Cel'' end
				else ''E_NV_Longitud'' end

				--Termina Argentina
				return @resultado
			 end

			if @pais = 3
			 begin
				--Empieza colombia
				select @resultado = case
				--Si son 7 digitos, se regresa igual
				 when len(@resultado)=7 then
					@resultado
				--Cuando son 8 digitos si la lada es igual se quita y se regresan 7 numeros
				 when len(@resultado) = 8  then
					case when left(@resultado,1) = @ld then right(@resultado,7) else @resultado end
				-- Cuando son 10 digitos, se revisa que tenga prefijo celular y se agrega un 0
				 when len(@resultado)=10 then
					case when left(@resultado,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then ''0'' + @resultado
					else
						''E_NV_Cel''
					end
				--Cuando son 11 digitos, se revisa que el primer numero sea un 0 y que los siguientes 3 numeros sean
				--prefijo de celular
				 when len(@resultado)=11 then
					case when left(@resultado,1)=''0'' then
						case when substring(@resultado,2,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then @resultado else ''E_NV_Cel'' end
					else ''E_NV_Cel'' end
				else ''E_NV_Longitud'' end

				-- Termina Colombia
				return @resultado
			 end

			if @pais = 4
			 begin
				--Empieza USA
				select @resultado = case len(@resultado)
				 when 3 then
					case @resultado when ''911'' then @resultado else ''E_NV_Longitud'' end
				 when 7 then @resultado
				 when 10 then
				   case when left(@resultado, len(@ld)) = @ld
					then right(@resultado, 10 - len(@ld)) else ''1'' + @resultado end
				 when 11 then
				   case when left(@resultado, 1) = ''1'' then
					 case when substring(@resultado, 2, len(@ld)) = @ld
					   then right(@resultado, 10 - len(@ld)) else @resultado end
					else ''E_NV_LD'' end
				else ''E_NV_Longitud'' end

				--Termina USA
				return @resultado
			 end

			if @pais = 5
			 begin
				select @resultado = case len(@resultado)
				 when 6 then @resultado
				 when 7 then @resultado
				-- se revisa si es un celular, si es asi se le agrega el 09 excepto con los prefijos que se mezclan con ladas
				 when 8 then

					case when @ld = left(@resultado,len(@ld)) then right(@resultado,8-len(@ld)) else
						case when left(@resultado,1) in (8,9) then ''09'' + @resultado else
							case when left(@resultado,1) = ''6'' then case when left(@resultado,2) in (61,63,64,65,67) then  @resultado else ''09'' + @resultado end
							 else case when left(@resultado,1) = ''7'' then case when left(@resultado,2) in (71,72,73,75) then @resultado else ''09'' + @resultado end else @resultado end end
						 end
					end
				-- Se revisa que sea la lada permitida a 9 numeros, si es asi se regresa igual, si tiene el prefijo
				-- de telefonia voIp se le agrega el 0 al inicio
				 when 9 then
					case when @ld = left(@resultado,2) then right(@resultado,7) else
						case when left(@resultado,2) in (41,32,65) then @resultado else
							case when left(@resultado,2) = ''44'' then ''0'' + @resultado else
								case when left(@resultado,1) = ''9'' and substring(@resultado,2,1) in (6,7,8,9) then ''0'' + @resultado else ''E_NV_Longitud'' end
							 end
						end
					end
				 when 10 then
					case when left(@resultado,2) = ''09'' then @resultado else ''E_NV_Cel'' end
				else ''E_NV_Longitud'' end

				-- Termina Chile
				return @resultado
			 end

			-- Venezuela
			if @pais = 6 begin
				select @resultado = case len(@resultado)
					when 7 then @resultado
					when 10 then ''0'' + @resultado
					when 11 then
						case when left(@resultado,1) = ''0'' then @resultado else ''E_NV_Longitud'' end
					else
					''E_NV_Longitud'' end
			end
			--Termina Venezuela

			-- UK
			if @pais = 7 begin
				select @resultado = case len(@resultado)
					when 11 then
						case left(@resultado,1)
							when ''0'' then @resultado else ''E_NV_Longitud''
						end
					when 10 then
						case left(@resultado,1)
							when ''0'' then @resultado else ''0'' + @resultado
						end
					when 9 then
						case when left(@resultado,1) <> ''0'' then ''0'' + @resultado else ''E_NV_Longitud'' end
					when 8 then
						case when substring(@resultado, 1, 2) = ''08'' then @resultado else ''E_NV_Longitud'' end
					when 7 then
						case when left(@resultado,1) = ''8'' then ''0'' + @resultado else ''E_NV_Longitud'' end
					else
					''E_NV_Longitud''
				end
			end
			-- Termina UK

			if @pais = 8 begin -- arabia saudita
				select @resultado = case len(@resultado)
				when 7 then @resultado
				when 8 then case substring(@resultado, 1, 1) when @ld then right(@resultado, 7) else ''0'' + @resultado end
				when 9 then case substring(@resultado, 1, 1) when ''5'' then ''0'' + @resultado
							when ''0'' then case substring(@resultado, 2, 1)
									when @ld then right(@resultado, 7) else @resultado end
							else ''E_NV_Longitud''
							end
				when 10 then case substring(@resultado, 2, 1) when ''5'' then @resultado else ''E_NV_Longitud'' end
				when 11 then case substring(@resultado, 2, 1)
								when ''8'' then case substring(@resultado, 3, 3)
												when ''111'' then @resultado else ''E_NV_Longitud'' end
								else case when substring(@resultado, 3, 3) = ''510'' or substring(@resultado, 3, 3) = ''511'' then @resultado else ''E_NV_Longitud'' end
								end
				when 13 then @resultado
				else ''E_NV_Longitud'' end
			end -- arabia saudita

			if @pais = 9 --Australia
			begin
				select @resultado = case len(@resultado)
				when 8 then
					/*case when exists (select AreaCode
									  from SeriesAU
									  where convert(int,LD) = convert(int,@ld)
									  and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then*/
						case substring(@resultado, 1, 4) when ''5550'' then ''E_NV_LD'' else @ld +  @resultado end
					/*else case when exists (select AreaCode
									  from SeriesAU
									  where convert(int,LD) = convert(int,''04'')
									  and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then
					''04'' +  @resultado
					else ''E_NV_Cel'' end end*/
				when 9 then
					case when left(@resultado,1) <> ''0'' then
						case substring(@resultado, 2, 4) when ''5550'' then ''E_NV_LD'' else ''0'' + @resultado end
					else ''E_NV_LD'' end
				when 10 then
					case substring(@resultado, 3, 4) when ''5550'' then ''E_NV_LD'' else @resultado end
				else ''E_NV_Longitud'' end
			end


			if @pais = 10 --Brasil
			begin

				select @resultado = case len(@resultado)
			--llamada local fijo o celular
				when 8 then @resultado
				when 9 then @resultado
				when 10 then  -- Numero nacional
					case when left(@resultado, 2) = @ld
						then right(@resultado,8) else @resultado end
				when 11 then	-- Este caso solomente es para numero celular
						case when left(@resultado, 2) = @ld
							 then right(@resultado,9) else @resultado end
				when 12 then	-- llamadas por cobrar local
					case when (left(@resultado,4) = ''9090'') then right(@resultado,8) else ''E_NV_PC'' end
				when 13 then
					case when left(@resultado,4) = ''9090'' then right(@resultado,9) -- llamadas por cobrar local celular
						 when left(@resultado,1) = ''0'' then
						case when substring(@resultado,4,2)=@ld then right(@resultado,8) else right(@resultado,10) end -- llamadas de LDN
					else ''E_NV_Longitud'' end
				when 14 then
						case when left(@resultado,2) = ''90'' then -- llamadas por cobrar larga distancia
								case when substring(@resultado,5,2) = @ld then right(@resultado,8) else right(@resultado,11) end
							 when left(@resultado,1) = ''0''  then --llamada larga distancia a celular
									case when substring(@resultado,4,2)= @ld then right(@resultado,9) else right(@resultado,11) end
						else ''E_NV_Longitud'' end
				when 15 then
					case when left(@resultado,2) = ''90'' then -- Llamadas por cobrar a celular LD
							case when substring(@resultado,5,2)=@ld then right(@resultado,9) else right(@resultado,11) end
						else ''E_NV_Longitud'' end

				else ''E_NV_Longitud'' end

			end

			if @pais = 11 --Guatemala
			begin
				if len(@resultado)=8
					begin
						if charindex(substring(@resultado,1,1),''2,3,4,5,6,7'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else
					select @resultado = ''E_NV_Longitud''
			end

			if @pais = 12 --Costa Rica
			begin
				if len(@resultado)=8
					begin
						if charindex(substring(@resultado,1,1),''2,3,4,5,6,7,8'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else if len(@resultado)=10
					begin
						if charindex(substring(@resultado,1,3),''800,900,905'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else
					begin
						if charindex(substring(@resultado,1,2),''00,08'') <= 0
							select @resultado = ''E_'' + @resultado
					end
			end

			if @pais = 13 --Salvador
			begin
				if len(@resultado)=8
					begin
						if charindex(substring(@resultado,1,1),''2,6,7'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else
					begin
						if charindex(substring(@resultado,1,2),''00'') <= 0
							select @resultado = ''E_'' + @resultado
					end
			end

			if @pais = 14 --España
			begin
				if len(@resultado)=9
					begin
						if charindex(substring(@resultado,1,1),''5,6,7,8,9'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else
					begin
						if charindex(substring(@resultado,1,2),''00'') <= 0
							select @resultado = ''E_'' + @resultado
					end
			end

			if @pais = 15 --Peru
			begin
				select @resultado = case
				 when (len(@resultado)=7 and len(@ld)=1) or (len(@resultado)=6 and len(@ld)=2) then @resultado
				 when len(@resultado)=8 then
				  case when substring(@resultado, 1, len(@ld)) = @ld
				   then right(@resultado, 8 - len(@ld)) else ''0'' + @resultado end
				 when len(@resultado)=9 then
				   case when left(@resultado,1) = ''0'' and substring(@resultado, 2, len(@ld)) = @ld
					then right(@resultado, 8 - len(@ld)) else @resultado end
				else ''E_NV_Longitud'' end
			end --Termina Peru


			if @pais = 16 --Panama
			begin
				if len(@resultado)=7
					begin
						if charindex(substring(@resultado,1,1),''2,4,5,6,7,9'') <= 0
							select @resultado = ''E_'' + @resultado
					end
				else
					begin
						if charindex(substring(@resultado,1,2),''00'') <= 0
							select @resultado = ''E_'' + @resultado
						else
							begin
							if charindex(substring(@resultado,3,5),''507'') <= 0
								select @resultado = ''00507'' + substring(@resultado,3,len(@resultado)) 
							end
					end
			end

			-- Termina
			return @resultado

			end'
		EXEC(@Sql)


	/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end