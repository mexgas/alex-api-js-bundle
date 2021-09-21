CREATE PROCEDURE [dbo].[ccsp_GalateaAdminANIListLD]
@type as tinyint,
@idArea as smallint,
@descriptionList as varchar(40) = NULL,
@idAniList as smallint = NULL,
@cld as varchar(max)= NULL,
@aniTel as varchar(30)= NULL,
@edo as varchar(350) = NULL
AS
set nocount on
declare @pais tinyint, @listEdos varchar(4000), @idLista as integer, @sql as varchar(500)
select @pais = valor from ccsettings where setting_id = 104

select @listEdos = 'select distinct ' + case @type when 1 then
case @pais	when 1  then 'estado as [state] '
			when 2  then 'estado as [state] '
			when 3  then 'municipio as [state] '
			when 4  then 'location as [state] '
			when 5  then 'cld as [state] '
			when 6  then 'region as [state] '
			when 7  then 'region as [state] '
			when 8  then 'Regiones as [state] '
			when 9  then 'Regiones as [state] '
			when 10 then 'Regiones as [state] '
			when 11 then 'zonaGeografica as [state] '
			when 12 then 'zonaGeografica as [state] '
			when 13 then 'zonaGeografica as [state] '
			when 14 then 'provincia as [state] '
			else '' end
when 4 then
case @pais	when 1  then 'estado, cld as area, @id_anilist as id_anilist, '''' as telani '
			when 2  then 'estado, cld as area, @id_anilist as id_anilist, '''' as telani '
			when 3  then 'municipio as estado, region +''''+ serie as area, @id_anilist as id_anilist, '''' as telani '
			when 4  then 'location as estado, area, @id_anilist as id_anilist, '''' as telani '
			when 5  then 'cld as estado, cld as area, @id_anilist as id_anilist, '''' as telani '
			when 6  then 'region as estado, LD as area, @id_anilist as id_anilist, '''' as telani '
			when 7  then 'region as estado, CLD as area, @id_anilist as id_anilist, '''' as telani '
			when 8  then 'Regiones as estado, cld +''-''+ [serie inicio] as area, @id_anilist as id_anilist, '''' as telani '
			when 9  then 'Regiones as estado, LD + AreaCode as area, @id_anilist as id_anilist, '''' as telani '
			when 10 then 'Regiones as estado, AreaCode as area, @id_anilist as id_anilist, '''' as telani '
			when 11 then 'zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''' as telani '
			when 12 then 'zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''' as telani '
			when 13 then 'zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''' as telani '
			when 14 then 'provincia as estado, indicativoProvincia as area, @id_anilist as id_anilist, '''' as telani '
			else '' end 
end + 'from ' +
case @pais	when 1  then 'series'
			when 2  then 'seriesarg where estado <> '''''
			when 3  then 'seriescol'
			when 4  then 'ccTimeZoneArea where id_country = ' + convert(varchar(5),@pais) + ''
			when 5  then 'serieschi'
			when 6  then 'SeriesVen'
			when 7  then 'SeriesUK'
			when 8  then 'SeriesSA'
			when 9  then 'SeriesAU'
			when 10 then 'SeriesBR'
			when 11 then 'SeriesGT'
			when 12 then 'SeriesCR'
			when 13 then 'SeriesSV'
			when 14 then 'SeriesEsp'
			else '' end + ''

if @type=1
begin	--Get locations / states
	exec(@listEdos + ' order by [state]')
	return(0)
end

if @type=2
begin
	select @sql = 'select id_AniList, description from ccEdoAniList where idArea = ' + convert(varchar(5),@idArea) +  
	case when isnull(@idAniList,'') <> '' then ' and id_AniList = ' + convert(varchar(5),@idAniList) else '' end
	exec(@sql)
	return(0)
end

if @type=3
begin	-- Get Outbound telAni with Area Codes
	select @sql = 'select id_AniList, Estado, telAni, area from ccEstadosAni where id_AniList = ' + convert(varchar(5),@idAniList) + 
	' and estado like ''%' + @edo + '%'' and id_AniList in (select id_AniList from ccEdoAniList where idArea = ' +
	 convert(varchar(5),@idArea) + ') order by estado'
	exec(@sql)
	--print(@sql)
	return(0)
end

if @type=4
begin  --Insert new aniList
	if @descriptionList <> '' begin
		if exists(select * from dbo.ccEdoAniList where [description]=@descriptionList )
		begin
			select cast(2 as int) [result]
			return(0)
		end
		insert into ccEdoAniList values(@descriptionList, @idArea)
		select @idLista = id_anilist from ccEdoAniList where [description] = @descriptionList
		set @listEdos = 'insert into ccEstadosAni (estado, area, id_anilist, telani) ' + @listEdos
		set @listEdos = replace(@listEdos, '@id_anilist', convert(varchar(6),@idLista))
		exec(@listEdos)
		--print(@listEdos)
		select cast(1 as int) [result]
		return(0)
	end
	select cast(0 as int) [result]
	return(0)
end

if @type=5
begin --Save ANI number
	update ccEstadosAni set telani= ISNULL(@aniTel, TELANI) WHERE id_anilist = @idAniList 
	and area in (select value from dbo.fn_RIASplitDelimited(@cld, ','))

	select cast(1 as int) [result]
	return(0)
end

if @type=6
begin --Delete ANI list
	if not exists(select id_anilist from ccEdoAniList WHERE id_anilist = @idAniList and idarea = @idArea )
	 begin
		select cast(-1 as int) [result]
		return(0)
	 end

	delete from ccEstadosAni where id_anilist = @idAniList
	delete from ccEdoAniList WHERE id_anilist = @idAniList

	select cast(1 as int) [result]
	return(0)
end

if @type=7
begin --Update ANI list name
	if(exists(select [description] from ccEdoAniList where [description]=@descriptionList and id_AniList<>@idAniList))
	begin
		select cast(2 as int) [result]
		return(0)
	end

	update ccEdoAniList set [description]=@descriptionList where id_AniList=@idAniList
	select cast(1 as int) [result]
	return(0)
end