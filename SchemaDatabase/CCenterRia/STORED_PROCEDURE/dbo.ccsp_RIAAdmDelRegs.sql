CREATE PROCEDURE [dbo].[ccsp_RIAAdmDelRegs]
		@tipoDel int, -- 1 Registros Nuevos / 2 Registros CallBack / 3 Registros sin meter a WT / 4 Registros CallBack - Excepto los programados por Agentes
		@cam_id int,
		@phone varchar(30) = '',
		@calkey varchar(40) = '',
		@exact bit = 1
		AS

		if @tipoDel = 1 --nuevos
		 begin
			delete ccoWorkingTable where cam_id = @cam_id and cal_status = 0
		 end

		if @tipoDel = 2 --callbacks
		 begin
			delete ccoWorkingTable where cam_id = @cam_id and cal_status = 1
		 end

		if @tipoDel = 3 -- 3 Registros sin meter a WT
		 begin
			update ccocallsoutsource --with(rowlock)
			set cal_Status = 5 
			where cam_id = @cam_id 
			and cal_status in(0, 7)
        
			Delete ccUploadTemporal where cam_id = @cam_id
		 end

		if @tipoDel = 4 --callbacks
		 begin
			delete ccoWorkingTable where cam_id = @cam_id and cal_status = 1 and user_id=0
		 end

		if @tipoDel = 5 --callbacks
		 begin
			delete ccoWorkingTable where cam_id = @cam_id and cal_status = 3
		 end

		if @tipoDel = 6 -- Delete a record from a specific campaign containing a specific phone number
		begin   
			delete ccoWorkingTable --with(rowlock) 
			where callout_id in (select callout_id 
									from ccocallsoutsource with(nolock)
									where cam_id = @cam_id 
									and (cal_telefono = @phone or 
											cal_telefono2 = @phone or 
											cal_telefono3 = @phone or 
											cal_telefono4 = @phone or 
											cal_telefono5 = @phone))

			update ccocallsoutsource --with(rowlock)
			set cal_Status = 5 
			where cam_id = @cam_id  and 
				(cal_telefono = @phone or 
				cal_telefono2 = @phone or 
				cal_telefono3 = @phone or 
				cal_telefono4 = @phone or 
				cal_telefono5 = @phone)
        
		end

		if @tipoDel = 7 -- Delete all the records from a specific campaign
		begin
			delete from ccoWorkingTable where cam_id = @cam_id

			update ccocallsoutsource set cal_Status = 5 where cam_id = @cam_id
		end

		if @tipoDel = 8 --delete records by specific callkey
		 begin
			if @exact = 1
				delete ccoWorkingTable with(rowlock) where cal_keyw = @calkey and cal_status <> 2
			else
				delete ccoWorkingTable with(rowlock) where cal_keyw like '%' + @calkey + '%' and cal_status <> 2
		 end