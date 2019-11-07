CREATE procedure [dbo].[ccsp_GetRecord] 
		@action int,
		@IdRepository int = 1,
		@DateStart Date,
		@DateEnd date
		as
		if @action =1
		begin
			select grab_id,cal_id,tipo_llamada,Prefijo 
			from RIA_GRABACION 
			where id_repositorio = @IdRepository and
			cast(finicio as Date) >= Cast(@DateStart As Date) and	cast(ffin as Date) <= cast(@DateEnd as Date)
			order by grab_id
		end

		if @action =2
		begin
			select grab_id,cal_id,tipo_llamada,Prefijo 
			from RIA_GRABACION where cast(finicio as Date) >= Cast(@DateStart As Date) and	cast(ffin as Date) <= cast(@DateEnd as Date)
			order by grab_id
		end