CREATE PROCEDURE [dbo].[ccsp_ExtAppsDisposeCall]
	@action as tinyint = 0,
	@type as tinyint = 0,
	@cal_id as smallint = 0,
	@disposition as smallint = 0,
	@subDisposition as smallint = 0,
	@date as varchar(50) = '',
	@cam_id as smallint = 0
	AS
	declare @phone as varchar(15)
	declare @msg as int
	declare @needsCallback as int
	declare @pais varchar(2)
	declare @ld varchar(5)

	set @msg = 0 --No hizo nada

	select @pais = valor from ccSettings with(nolock) where setting_id = 104
	select @ld = valor from ccSettings with(nolock) where setting_id = 17

	if @action = 1 begin  -- Califica y reprograma
		if @type = 1 begin	-- Inbound
		
			if @subDisposition = 0 begin --Si la subcalif tiene 0 buscamos en la calif padre
				select @needsCallback = canReprogram from ccTipoCalif where calif_id = @disposition			
			end else begin -- Si no buscamos en la tabla de las subcalifs
				select @needsCallback = canReprogram from ccTipoCalifSub where califSub_id = @subDisposition			
			end

			if @needsCallback = 1 begin	-- Verificamos si necesita repgoramacion y si la fecha no viene vacia
				if @date <> '' begin
					declare @acd_id as smallint			
					declare @phoneT as varchar(15)

					select @phone = cal_ani, @acd_id = inbound_id from cccallsin with(nolock) where cal_id = @cal_id
					select @cam_id = isnull(cam_id,0) from ccinbound with(nolock) where inbound_id = @acd_id
					select @phoneT = dbo.Completa(@phone, @pais, @ld)

					if @cam_Id <> 0 begin -- Si hay campaña espejo reprogramamos
						select @phone = case when left(@phoneT,1) = 'E' then @phone else @phoneT end
						-- Genera callback
						exec ccsp_InInsertaCallBack '', @cam_id, @phone, @date, '','','','','',1,0
						-- Actualiza calificacion
						update cccallsin set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
						set @msg =  2 -- Reprogramacion Inbound
					end else begin				
						set @msg =  5 -- No hay campaña espejo para el acd	
					end
				end else begin				
					set @msg = 6 -- Necesita repgoramacion pero no hay fecha
				end
			end else begin -- Si no necesita repgoramacion se actualiza la calificacion
				update cccallsin set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
				set @msg = 1 -- Actualizo calificacion 
			end
		end
		else begin -- Outbound

			if @subDisposition = 0 begin --Si la subcalif tiene 0 buscamos en la tabla calif padre
				select @needsCallback = canReprogram from ccTipoCalifOut where calif_id = @disposition
			end else begin -- Si no buscamos en la tabla de las subcalifs
				select @needsCallback = canReprogram from ccTipoCalifSubOut where califSub_id = @subDisposition
			end

			if @needsCallback = 1 begin	-- Verificamos si necesita repgoramacion y si la fecha no viene vacia
				if @date <> '' begin 
					declare @callout_id int
					declare @cal_key as varchar(40)
				
					select @phone = cal_telefono, @cam_id = cam_id, @callout_id = callout_id, @cal_key = cal_key from ccocallsout with(nolock) where cal_id = @cal_id
					exec ccsp_OUTInsertaCallBack @cal_id, @phone, @cam_id, @date, @callout_id, 1, 0, @cal_key
					update ccocallsout set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
					set @msg =  4 -- Reprogramacion Outbound
				end else begin
					set @msg = 6 -- Necesita repgoramacion pero no hay fecha
				end
			end else begin -- Si no necesita repgoramacion se actualiza la calificacion
				update ccocallsout set calif_id = @disposition, califsub_id = @subDisposition where cal_id = @cal_id
				set @msg = 3 -- Actualizo calificacion 
			end

		end	
		select @msg
	end

	if @action = 2 begin
		if @type = 1 begin
			select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
			calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
			from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
			left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
			where cam_id = @cam_id and tipo = 0 
			union
			select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
			calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description",cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
			from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
			left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
			where cam_id = @cam_id and tipo = 0 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
			for xml explicit, type		
		end
		else begin
 			select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback", 
 			calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
			from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
			left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
			where cam_id = @cam_id and tipo = 1 
			union
			select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
			calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description", cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
			from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
			left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
			where cam_id = @cam_id and tipo = 1 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
			for xml explicit, type
		end
	end

	if @action = 3 begin
		if @type = 1 begin
			select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
			calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
			from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
			left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
			where tipo = 0 
			union
			select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
			calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description",cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
			from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
			left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
			where tipo = 0 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
			for xml explicit, type		
		end
		else begin
 			select distinct 1 as tag, null as parent, calif.calif_id "Disposition!1!id", calif.Description "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
 			calif.orden "Disposition!1!califorden", null "SubDisposition!2!id", null "SubDisposition!2!description", null "SubDisposition!2!callback", null "SubDisposition!2!orden"
			from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
			left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
			where tipo = 1 
			union
			select distinct 2 as tag, 1 as parent, calif.calif_id "Disposition!1!id", null "Disposition!1!description", calif.canReprogram "Disposition!1!callback",
			calif.orden "Disposition!1!califorden", sb.califsub_id "SubDisposition!2!id", sb.califSubDesc "SubDisposition!2!description", cast(sb.canReprogram as int) "SubDisposition!2!callback", sb.orden "SubDisposition!2!orden"
			from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
			left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
			left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
			where tipo = 1 and sb.califsub_id is not null order by "Disposition!1!califorden", "Disposition!1!id", "subDisposition!2!orden"
			for xml explicit, type
		end
	end