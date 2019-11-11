CREATE Function [dbo].[TelAni](@tel varchar(32), @lista smallint)
RETURNS varchar(32)
AS
BEGIN
declare @cldLocal varchar(10), @pais tinyint, @lon tinyint, @ret as varchar(10)
declare @telResp varchar(32) = ''

select  @cldLocal = valor from ccsettings where setting_id = 17
select @pais = valor, @ret = '' from ccSettings where setting_id = 104

	if @lista = 0 begin
		select @tel = ''
	end

	if @pais = 1 begin --Empieza Mexico
		select @lon = len(@tel)
		if @lon >= 10 begin
			select TOP 1 @telResp = telani from ccEstadosAni WITH (NOLOCK) where id_anilist = @lista and (
				( left(right(@tel, 10), 3) = area and len(area) = 3 )
				or
				( left(right(@tel, 10), 2) = area and len(area) = 2 ))
			AND telani <> ''
		end
		else begin
			select @telResp = ''
		end

		return @telResp
	end --Termina Mexico

	if @pais = 2 begin  -- Empieza Argentina
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=13 begin
			select @telResp = telAni from ccEstadosAni where id_anilist = @lista and
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
			select @telResp = ''
		end
			return @telResp
	end  --Termina Argentina

	if @pais = 3 begin  --Empieza Colombia
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=13 begin
			select @telResp = telani from ccEstadosAni where id_anilist = @lista and
				(( len(@tel) = 7 and @cldlocal = area )
				or
				( len(@tel) = 8 and left(@tel,5) = area )
				or
				( len(@tel) in(10,11) and (left(@tel,1) = '3' or substring(@tel,2,1) = '3')))
		end
		else begin
			select @telResp = ''
		end
		return @telResp
	end  --Termina Colombia

	if @pais = 4 begin --Empieza USA
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=15 begin
			if @lon = 7 begin
				set @tel = @cldLocal + @tel
			end
			set @tel = right(@tel, 10)
			select @telResp = telani from ccEstadosAni where area = left(@tel,3) and id_anilist = @lista
		end
		else begin
			select @telResp = ''
		end
		return @telResp
	end --Termina USA

	if @pais = 5 begin -- Empieza Chile
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=15 begin
			select @telResp = telani from ccEstadosAni where id_anilist = @lista and
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
			( len(@tel) = 10 and substring(@tel,3,1) = area and left(@tel,2) = '09' ))
		end
		else begin
			select @telResp = ''
		end
		return @telResp
	end --Termina Chile

	if @pais = 6 begin -- Venezuela
		select @lon = len(@tel)
		if @lon >= 7 and @lon <=11 begin
			select @telResp = telani from ccEstadosAni where id_anilist = @lista and
				(len(@tel) = 7 and left(@tel,3) = area or
				len(@tel) = 11 and substring(@tel,2,3) = area)
		end
		else begin
			select @telResp = ''
		end

		return @telResp
	end --Termina Venezuela

	if @pais = 7 begin -- Empieza UK
		select @lon = len(@tel)
		if left(@tel,1) = '0' begin
			set  @tel = substring(@tel,2,(len(@tel)-1))
		end

		if @lon >= 9 and @lon <=11 begin
			select @telResp = telani from ccEstadosAni where id_anilist = @lista and
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
			select @telResp = ''
		end
		return @telResp
	end --Termina UK

	if @pais = 8 begin --Empieza Arabia Saudita
		select @lon = len(@tel)
		if @lon >= 7 and @lon <=13 begin
			select @telResp = telani from ccEstadosAni where id_anilist = @lista and
				(len(@tel) = 7 and '0'+@cldlocal + '-'+ substring(@tel,1,1) + '00' = area or
				len(@tel) = 9 and substring(@tel,1,3) + '00' = replace(area,'-','') or
				len(@tel) = 10 and substring(@tel,1,4) + '00' = replace(area,'-','') or
				len(@tel) = 11 and substring(@tel,1,4)+ '0' = replace(area,'-','') or
				len(@tel) = 11 and substring(@tel,1,5) = replace(area,'-',''))
		end
		else begin
			select @telResp = ''
		end

		return @telResp
	end --Termina Arabia Saudita

	if @pais = 9 --Empieza Australia
		begin
			select @lon = len(@tel)
			if @lon >= 8 and @lon <=10
				begin
					select @telResp = telani from ccEstadosAni where id_anilist = @lista
					and (len(@tel) = 8 and @cldLocal + substring(@tel,1,2) = area or
							len(@tel) = 9 and '0' + substring(@tel,1,3) = area or
							len(@tel) = 10 and substring(@tel,1,4) = area)
				end
			else
				begin
					select @telResp = ''
				end

			return @telResp
		end --Termina Australia

	if @pais = 10 begin -- Empieza Brasil
		select @lon = len(@tel)
		if @lon >= 8 and @lon <=15 begin
			select @telResp = telani from ccEstadosAni where id_anilist = @lista and (
				((@lon       = 8        )                                    and             @cldlocal = area) or
				((@lon       = 9        ) and substring(@tel, 1, 1) = '9'    and             @cldlocal = area) or
				((@lon between 10 and 11)                                    and substring(@tel, 1, 2) = area) or
				((@lon between 12 and 13) and substring(@tel, 1, 4) = '9090' and             @cldlocal = area) or
				((@lon       = 13       )                                    and substring(@tel, 4, 2) = area) or
				((@lon between 14 and 15) and substring(@tel, 1, 2) = '90'   and substring(@tel, 5, 2) = area) or
				((@lon       = 14       ) and substring(@tel, 1, 1) = '0'    and substring(@tel, 4, 2) = area))
		end
		else begin
			select @telResp = ''
		end

		return @telResp
	end -- Termina Brasil

	if @pais = 11 begin --Empieza Guatemala
		if len(@tel) = 8  begin
			select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
		end
		else begin
			select @telResp = ''
		end

		return @telResp
	end --Termina Guatemala

	if @pais = 12 begin --Empieza Costa Rica
		if len(@tel) = 8  begin
			select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
		end
		else if len(@tel) = 10 begin
			select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 3) = area
		end
		else begin
			if charindex(substring(@tel,1,2),'00,08') <= 0
				select @telResp = ''
			else
				select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 2) = area
		end

		return @telResp
	end --Termina Costa Rica

	if @pais = 13 begin --Empieza Salvador
		if len(@tel) = 8  begin
			select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
		end
		else begin
			if charindex(substring(@tel,1,2),'00') <= 0
				select @telResp = ''
			else
				select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 2) = area
		end

		return @telResp
	end --Termina Salvador

	if @pais = 14 begin --Empieza Espa?a
		if len(@tel) = 9  begin
			select @telResp = telani from ccEstadosAni where id_anilist = @lista and
			((substring(@tel, 1, 1) = area) or
			(substring(@tel, 1, 2) = area) or
			(substring(@tel, 1, 3) = area))
		end
		else
			select @telResp = ''

		return @telResp
	end --Termina Espa?a

	if @pais = 15 begin -- Empieza Peru
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=9 begin
			select @telResp = telani from ccEstadosAni where id_anilist = @lista and
			(( len(@tel) = 6 and @cldlocal = area )
			or
			( len(@tel) = 7 and @cldlocal = area )
			or
			( len(@tel) = 9 and left(@tel,1)='0' and substring(@tel,2,len(@cldlocal)) = area ))
		end
		else begin
			select @telResp = ''
		end
		return @telResp
	end --Termina Peru

	if @pais = 16 begin --Empieza Panama
		if len(@tel) = 7  begin
			select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
		end
		else begin
			if charindex(substring(@tel,1,2),'00') <= 0
				select @telResp = ''
			else
				select @telResp = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 2) = area
		end

		return @telResp
	end --Termina Panama

	return @ret
END