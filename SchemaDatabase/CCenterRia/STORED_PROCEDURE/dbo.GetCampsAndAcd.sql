CREATE procedure [dbo].[GetCampsAndAcd]
			@action int,
			@camId int = 0,
			@tipoLlamada int = 0,
			@prefijo varchar(max)=''

			as
			if @action =1 
				begin
					select cam_id as Cam_Id,cam_descripcion as Descripcion ,2 as [TipoLlamada] from ccCamps
					union
					select Inbound_id as Cam_Id,descripcion as Descripcion ,1 as [TipoLlamada] from ccinbound 
				end
			if @action = 2
				if @tipoLlamada = 1
				begin
					UPDATE ccInbound set prefijo = @prefijo where Inbound_id = @camId 
				end
				if @tipoLlamada = 2
				begin
					UPDATE ccCamps set prefijo = @prefijo where cam_id = @camId 
				end