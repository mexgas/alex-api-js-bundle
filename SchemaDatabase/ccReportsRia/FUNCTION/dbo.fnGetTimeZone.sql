CREATE FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
RETURNS int
AS
 BEGIN
	declare @lada as varchar(5)
	declare @timeZone as int

	select @lada = valor from ccsettings where setting_id = 17

	declare @country as tinyInt
	select @country = valor from ccSettings where setting_id = 104

		if @country = 1 begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
			where id_country = @country and (
			( len(@phone) = 8 and @lada = area and len(area) = 2 )
			or
			( len(@phone) = 7 and @lada = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 2) = area and len(area) = 2 ))
		end

		if @country = 2 begin
			declare @telTemp varchar(15)
			set @telTemp = @phone
			select @phone = dbo.Completa(@phone)
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
		select @phone = dbo.Completa(@phone)
		-- len(@phone) = 10
		if (substring(@phone, 1, 1) <> 'E') begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
			where id_country = @country and (
			(convert (int, substring(@phone, 1, 4)) = convert (int, area) and len(area) = 4) or
			(convert (int, substring(@phone, 1, 2)) = convert (int, area) and len(area) = 2))
		end
	end
	
	if @country = 10 begin
		select @phone = dbo.Completa(@phone)
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

	return isNull(@timeZone,0)
 END