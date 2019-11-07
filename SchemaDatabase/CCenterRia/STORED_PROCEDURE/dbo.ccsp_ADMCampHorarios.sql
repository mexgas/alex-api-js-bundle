CREATE PROCEDURE [dbo].[ccsp_ADMCampHorarios]
@cam_id smallint,
@horario_id smallint, -- Si Tipo =2, aqui viene el ID de Horario
@Tipo tinyint -- 1=ALTA, 2=Modificacion, 3=Borrar
AS
declare @Descripcion varchar(40),@valueShudulerLey varchar(max)
declare @idioma bit,@authorizationCallLaw bit,@msgLaw varchar(max)
declare @isShudulerLey bit,@shourStart varchar(max),@shourEnd varchar(max)

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

select @Descripcion=Upper(Descripcion) from ccHorarios where horario_id=@horario_id
if @Tipo=1 begin
	if ( select count(*) from ccCampsHorarios where cam_id = @cam_id and horario_id=@horario_id) > 0
		if @idioma = 1
		select 0, 'Schedule Already Assigned'
		else
		select 0, 'Horario ya Asignado'
	else
	begin
		select @valueShudulerLey = valor from ccsettings where setting_id=166
		select @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex('|',@valueShudulerLey)) as int),@valueShudulerLey=substring(@valueShudulerLey, charindex('|',@valueShudulerLey) + 1, len(@valueShudulerLey))

		if @valueShudulerLey='' begin
			set @valueShudulerLey='0|07:00|22:00'
			update ccsettings set valor=@valueShudulerLey where setting_id=166
		end

		if @isShudulerLey = 1 begin
			select @shourStart=substring(@valueShudulerLey, 0, charindex('|',@valueShudulerLey)),@shourEnd=substring(@valueShudulerLey, charindex('|',@valueShudulerLey) + 1, len(@valueShudulerLey))
		end
		else begin
			select @shourStart='07:00',@shourEnd='22:00'
		end

		if @isShudulerLey = 0 begin
			set @msgLaw= case when @idioma = 1 then 'You can call 24 hours' else 'Se podra llamar las 24 horas' end
		end
		else begin
			set @msgLaw= case when @idioma = 1 then 'Only you can call on schedule '+ @shourStart + ' to ' + @shourEnd
				else 'Solo se podra llamar en el horario '+ @shourStart + ' a ' + @shourEnd end
		end
		Insert ccCampsHorarios (cam_id, Horario_id  ) Values ( @cam_id, @horario_id )
		if @idioma = 1
		select -1, 'Schedule: ' + @Descripcion + ' Assigned to the Campaign OK\n'+@msgLaw
		else
		select -1, 'Horario: ' + @Descripcion + ' Asignado en la Campaña OK\n'+@msgLaw
	end
end
if ( @Tipo=3 )
begin
	Delete ccCampsHorarios where cam_id = @cam_id and horario_id=@horario_id
	if @idioma = 1
	select -1, 'Schedule: ' + @Descripcion + ' Removed from Campaign'
	else
	select -1, 'Horario: ' + @Descripcion + ' Removido de la Campaña'
end