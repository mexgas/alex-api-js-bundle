CREATE PROCEDURE [dbo].[ccsp_GalateaLoadWorkGroup]
@Option smallint,
@areaId int
as
declare @agentes varchar(max)
declare @admins varchar(max)
declare @campsIn varchar(max)
declare @campsOut varchar(max)
declare @wgs varchar(max)
declare @count int
declare @id int
declare @wg int

if @option =1 --Obtiene las relaciones de los WG de una area
begin
	SELECT 
	ROW_NUMBER() OVER(ORDER BY idWG ASC) AS Row,
	IDWG,@agentes as agents,@admins as admins,@campsIn as campsIn,@campsOut as campsOut
	into #Relations
	FROM ccRIAAreaWorkGroup 
	WHERE IDArea = @areaId;

	if not exists(select * from ccRIACat_Areas where IDArea = @areaId) or (select count(idWG) from #Relations) = 0
	begin
		select Null as IDWG ,@agentes as agents, @admins as admins, @campsIn as campsIn, @campsOut as campsOut, @wgs as idsWg
		return (0)
	end

	select @count = count(idWG) from #Relations
	set @id =1
	while @id<=@count
	begin
		select @wg =idwg from #Relations where Row =@id
		select @agentes=null, @admins=null,@campsIn=null,@campsOut=null
		select @agentes = coalesce(@agentes + ',', '') +  convert(varchar(12),wgu.user_id)
		from ccUsers u inner join ccRIAWorkGroupUsers wgu on wgu.User_id = u.User_id
		where TipoUser_id = 1 and u.IdArea = @areaId and wgu.IDWG =@wg
		order by u.user_id

		select @admins = coalesce(@admins + ',', '') +  convert(varchar(12),u.user_id)
		from ccUsers u inner join ccRIAWorkGroupUsers wgu on wgu.User_id = u.User_id
		where u.TipoUser_id > 1 and u.IdArea = @areaId  and wgu.IDWG =@wg
		order by u.user_id

		select @campsIn = coalesce(@campsIn + ',', '') +  convert(varchar(12),inbound_id)
		from ccInbound i inner join ccRIACampEspWG wg on wg.IdCampEsp =i.Inbound_id
		where IdArea = @areaId  and wg.IDWG = @wg and wg.Tipo=0
		order by inbound_id
	
		select @campsOut = coalesce(@campsOut + ',', '') +  convert(varchar(12),cam_id)
		from ccCamps c inner join ccRIACampEspWG wg on wg.IdCampEsp = c.cam_id
		where IdArea = @areaId and wg.IDWG = @wg and wg.Tipo=1
		order by cam_id

		Update #Relations set agents= @agentes, admins=@admins, campsIn = @campsIn, CampsOut = @campsOut where IDWG= @wg
		set @id=@id+1
	end
	select Cast(IDWG as varchar(10)) as idwg,agents,admins,campsIn,CampsOut from #Relations

end