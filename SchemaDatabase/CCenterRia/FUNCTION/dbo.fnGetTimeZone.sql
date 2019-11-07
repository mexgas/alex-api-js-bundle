CREATE FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
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

  select @ld = ''
  select @location = ''

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
      if left(@phone,1) = 'E' begin set @phone = @telTemp end
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
    ( len(@phone) in(10,11) and (left(@phone,1) = '3' or substring(@phone,2,1) = '3')))
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
    ( len(@phone) = 10 and substring(@phone,3,1) = area and left(@phone,2) = '09' ))
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
    if (substring(@phone, 1, 1) <> 'E') begin
      select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
      where id_country = @country and (
      (convert (int, substring(@phone, 1, 4)) = convert (int, area) and len(area) = 4) or
      (convert (int, substring(@phone, 1, 2)) = convert (int, area) and len(area) = 2))
    end
  end

  if @country = 10 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    -- 8 <= len(@phone) <= 19
    if (substring(@phone, 1, 1) <> 'E') begin
      select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
      where id_country = @country and (
      ((len(@phone) between  8 and  9)                                      and                   @lada = area) or
      ((len(@phone) between 10 and 11)                                      and substring(@phone, 1, 2) = area) or
      ((len(@phone) between 12 and 13) and substring(@phone, 1, 4) = '9090' and                   @lada = area) or
      ((len(@phone)       = 13       )                                      and substring(@phone, 4, 2) = area) or
      ((len(@phone) between 14 and 15) and substring(@phone, 1, 2) = '90'   and substring(@phone, 5, 2) = area) or
      ((len(@phone)       = 14       ) and substring(@phone, 1, 1) = '0'    and substring(@phone, 4, 2) = area))
    end
  end

  if @country = 11 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> 'E') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  if @country = 12 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> 'E') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  if @country = 13 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> 'E') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  if @country = 14 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> 'E') begin
      if len(@phone) = 9 begin
        select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
        where id_country = @country and ((substring(@phone, 1, 2) = area) or (substring(@phone, 1, 3) = area))
      end
    end
  end

  if @country = 15 OR @country = 16  begin --Peru
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> 'E') begin
      select @timeZone = 32
    end
  end

  return isNull(@timeZone,0)
 END