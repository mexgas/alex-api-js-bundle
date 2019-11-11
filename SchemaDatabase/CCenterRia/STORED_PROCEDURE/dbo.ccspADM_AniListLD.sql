CREATE PROCEDURE [dbo].[ccspADM_AniListLD]
@type as tinyint,
@idArea as smallint,
@descriptionList as varchar(40) = NULL,
@IdAniLista as smallint = NULL,
@cld as varchar(40)= NULL,
@AniTel as varchar(40)= NULL,
@edo as varchar(40) = NULL
AS
set nocount on
declare @pais tinyint, @listEdos varchar(4000), @idLista as integer, @sql as varchar(500)
select @pais = valor from ccsettings where setting_id = 104

select @listEdos = 'select distinct ' + case @type when 1 then
case @pais	when 1  then 'estado, cld as area '
			when 2  then 'estado, cld as area '
			when 3  then 'municipio as estado, region +''+ serie as area '
			when 4  then 'location as estado, area '
			when 5  then 'cld as estado, cld as area '
			when 6  then 'region as estado, LD as area '
			when 7  then 'region as estado, CLD as area '
			when 8  then 'Regiones as estado, cld +''-''+ [serie inicio] as area '
			when 9  then 'Regiones as estado, LD + AreaCode as area '
			when 10 then 'Regiones as estado, AreaCode as area '
			when 11 then 'zonaGeografica as estado, indicativoDestino as area '
			when 12 then 'zonaGeografica as estado, indicativoDestino as area '
			when 13 then 'zonaGeografica as estado, indicativoDestino as area '
			when 14 then 'provincia as estado, indicativoProvincia as area '
			else '' end
when 4 then
case @pais	when 1  then 'estado, cld as area, @id_anilist as id_anilist, '''' as telani '
			when 2  then 'estado, cld as area, @id_anilist as id_anilist, '''' as telani '
			when 3  then 'municipio as estado, region +''+ serie as area, @id_anilist as id_anilist, '''' as telani '
			when 4  then 'location as estado, area, @id_anilist as id_anilist, '''' as telani '
			when 5  then 'cld as estado, cld as area, @id_anilist as id_anilist, '''' as telani '
			when 6  then 'region as estado, LD as area, @id_anilist as id_anilist, '''' as telani '
			when 7  then 'region as estado, CLD as area, @id_anilist as id_anilist, '''' as telani'
			when 8  then 'Regiones as estado, cld +''-''+ [serie inicio] as area, @id_anilist as id_anilist, '''' as telani '
			when 9  then 'Regiones as estado, LD + AreaCode as area, @id_anilist as id_anilist, '''' as telani '
			when 10 then 'Regiones as estado, AreaCode as area, @id_anilist as id_anilist, '''' as telani '
			when 11 then 'zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''' as telani '
			when 12 then 'zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''' as telani '
			when 13 then 'zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''' as telani '
			when 14 then 'provincia as estado, indicativoProvincia as area, @id_anilist as id_anilist, '''' as telani '
			else '' end end + 'from ' +
case @pais	when 1  then 'series'
			when 2  then 'seriesarg where estado <> '' order by 1'
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

if @type = 1

begin
	exec(@listEdos + ' order by estado')
	--print(@listEdos + ' order by estado')
	return(0)
end

if @type = 2
begin
	select @sql = 'select id_AniList, description from ccEdoAniList where idArea = ' + convert(varchar(5),@idArea) +  case when isnull(@IdAniLista,'') <> '' then ' and id_AniList = ' + convert(varchar(5),@IdAniLista) else '' end
	exec(@sql)
	return(0)
end

if @type = 3
begin
	select @sql = 'select id_AniList, Estado, telAni, area from ccEstadosAni where id_AniList = ' + convert(varchar(5),@IdAniLista) + ' and estado like ''%' + @edo + '%'' and telani <> '''' and id_AniList in (select id_AniList from ccEdoAniList where idArea
= ' +
	 convert(varchar(5),@idArea) + ') order by estado'
	exec(@sql)
	--print(@sql)
	return(0)
end

if @type = 4
begin  --insert new aniList
	if @descriptionList <> '' begin
		if exists(select * from dbo.ccEdoAniList where [description] = @descriptionList )
		 begin
			--raiserror('ERROR. invalid ID', 18, 1)
			select 1
			return(0)
		 end
		insert into ccEdoAniList values(@descriptionList, @idArea)
		select @idLista = id_anilist from ccEdoAniList where [description] = @descriptionList
		set @listEdos = 'insert into ccEstadosAni (estado, area, id_anilist, telani) ' + @listEdos
		set @listEdos = replace(@listEdos, '@id_anilist', convert(varchar(6),@idLista))
		exec(@listEdos)
		--print(@listEdos)
	end
	return(0)
end

if @type = 5
begin --update ccEstadosAni
	if not exists(select * from dbo.ccEstadosAni WHERE id_anilist = @IdAniLista and area = @cld )
	 begin
		--raiserror('ERROR. invalid ID', 18, 1)
		select 1
		return(0)
	 end

	update ccEstadosAni set telani= ISNULL(@AniTel, TELANI) WHERE id_anilist = @IdAniLista and area = @cld
	if @@rowcount>0
		select 0 id, [description]+'(Ld:'+cast(@cld as varchar(10))+')' [description] from ccEdoAniList WHERE id_anilist = @IdAniLista
	return(0)
end

if @type = 6
begin --borra listas
	if not exists(select id_anilist from ccEdoAniList WHERE id_anilist = @IdAniLista and idarea = @idArea )
	 begin
		select 1
		return(0)
	 end

	select @descriptionList=[description] from ccEdoAniList WHERE id_anilist = @IdAniLista and idarea = @idArea
	delete from ccEstadosAni where id_anilist = @IdAniLista
	delete from ccEdoAniList WHERE id_anilist = @IdAniLista

	if @@rowcount>0
		select 0 id, @descriptionList descriptionList
	return(0)
end