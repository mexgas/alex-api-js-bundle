CREATE procedure [dbo].[ccsp_OUTGetNewProviderJobs]
		@CAMPID as int,
		@test as int=0,
		@nAgentsLogin as int=1
		as
		set nocount on
		declare @topCount smallint, @bIsDaylight bit, @revHorario bit
		declare @country_id int, @TipoJobs int
		declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
		declare @sql varchar(MAX), @Order_Asc_Desc char(4)
		declare @camSurvey int
		DECLARE @iZonasTable TABLE (value int)

		select @camSurvey = 0

		select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

		-- VALIDAMOS EL PAIS Y LADA CONFIGURADA --
		SELECT @country_id =valor FROM ccSettings WHERE setting_id=104
		select @revHorario=valor from ccsettings where setting_id = 112
		-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
		SELECT @Order_Asc_Desc=case dialOrder when 1 then 'desc' else 'asc' end FROM ccCamps WHERE cam_id=@CAMPID
		SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,'asc')

		SET DATEFIRST 1
		--Checamos si es horario de verano
		select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
		if @iZonas is null begin

			INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
			select @iZonas=value from @iZonasTable
			--Checamos si la campaña tiene horarios configurados
			if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
				begin
				declare @horaUniversal as datetime
				set @horaUniversal=getutcdate()

				if @iZonas = 0 begin
					SELECT 0 as callout_id, 0 as cam_id, '' as cal_telefono, 0 as cal_status, '' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
					return
				end
				end

			else
			begin
				if @camSurvey > 0
					begin
						SELECT 0 as callout_id, 0 as cam_id, '' as cal_telefono, 0 as cal_status, '' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
						return
					end
			end
		end

		set @sql='CREATE TABLE #NEW_JOBS
		(callout_id int,
			cam_id int,
			cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
			cal_status tinyint,
			cal_fechaDial datetime,
			user_id int,
			tz int,
		tz2 int,
		tz3 int,
		tz4 int,
		tz5 int,
		tel varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
		tel2 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
		tel3 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
		tel4 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
		tel5 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
		tel_type smallint,
		tel2_type smallint,
		tel3_type smallint,
		tel4_type smallint,
		tel5_type smallint,
		dialOrder varchar(10),
		list_id int,
		sequence smallint,
		calkey varchar(max)
		)'

		-- 0=Ambas, 1=CallBacks, 2=Nuevas
		select @topCount=valor from ccSettings where setting_id=94

		if isnull(@topCount,0)=0
			select @topCount=case when @nAgentsLogin<3 then 30
			when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
			when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
			when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
			when @nAgentsLogin>=16 then 240 else 20 end

		select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

		declare @isVerano varchar(max)
		set @isVerano = 'W.izonahoraria' + case @bIsDaylight when 1 then '_verano' else '' end

		if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
			begin
			select @sql=@sql+nchar(13)+ 'SET ROWCOUNT ' + cast( @topCount/2 as varchar )

			select @sql=@sql+nchar(13)+ 'INSERT #NEW_JOBS
			SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
			W.izonahoraria' +case @bIsDaylight when 1 then '_verano' else '' end+' as tz,
			W.izonahoraria' +case @bIsDaylight when 1 then '_verano' else '' end+'2 as tz2,
			W.izonahoraria' +case @bIsDaylight when 1 then '_verano' else '' end+'3 as tz3,
			W.izonahoraria' +case @bIsDaylight when 1 then '_verano' else '' end+'4 as tz4,
			W.izonahoraria' +case @bIsDaylight when 1 then '_verano' else '' end+'5 as tz5,
			couts.cal_telefono as tel,
			couts.cal_telefono2 as tel2,
			couts.cal_telefono3 as tel3,
			couts.cal_telefono4 as tel4,
			couts.cal_telefono5 as tel5,'
			if @country_id = 1
			begin
				set @sql=@sql+'dbo.fnGetCallType(couts.cal_telefono) tel_type,
				dbo.fnGetCallType(couts.cal_telefono2) tel2_type,
				dbo.fnGetCallType(couts.cal_telefono3) tel3_type,
				dbo.fnGetCallType(couts.cal_telefono4) tel4_type,
				dbo.fnGetCallType(couts.cal_telefono5) tel5_type,
				'
			end
			else
			begin
				set @sql=@sql+'0 tel_type,0 tel2_type,0 tel3_type,0 tel4_type,0 tel5_type,'
			end
			set @sql=@sql+'
			couts.dial_tels as dialOrder, W.list_id, isnull(R.sequence,0) as sequence,
			couts.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5) calkey
			FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
			on W.list_id = R.list_id
			left join ccocallsoutsource couts (nolock)
			on W.callout_id = couts.callout_id
			WHERE W.cal_status=1 -- CallBacks
			and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
			and W.cam_id=' + cast(isnull(@CAMPID,'0') as varchar(7)) + '
			and (
				((W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+' & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
			or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'=0) or
				((W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'2 & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
			or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'2=0) or
				((W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'3 & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
			or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'3=0) or
				((W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'4 & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
			or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'4=0) or
				((W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'5 & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
			or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'5=0)
			)
			and isnull(R.status,2) = 2
			order by W.prioridad_cb desc, W.cal_fechaDial ' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
			end -- TOMA EN CUENTA LOS CALLBACKS

		if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
			begin
			select @sql=@sql+nchar(13)+ 'SET ROWCOUNT ' + cast( @topCount/2 as varchar )

			select @sql=@sql+nchar(13)+ 'INSERT #NEW_JOBS
			SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
			W.izonahoraria' +case @bIsDaylight when 1 then '_verano' else '' end+' as tz,
			W.izonahoraria' +case @bIsDaylight when 1 then '_verano' else '' end+'2 as tz2,
			W.izonahoraria' +case @bIsDaylight when 1 then '_verano' else '' end+'3 as tz3,
			W.izonahoraria' +case @bIsDaylight when 1 then '_verano' else '' end+'4 as tz4,
			W.izonahoraria' +case @bIsDaylight when 1 then '_verano' else '' end+'5 as tz5,
			couts.cal_telefono as tel,
			couts.cal_telefono2 as tel2,
			couts.cal_telefono3 as tel3,
			couts.cal_telefono4 as tel4,
			couts.cal_telefono5 as tel5,'
			if @country_id = 1
			begin
				set @sql=@sql+'dbo.fnGetCallType(couts.cal_telefono) tel_type,
				dbo.fnGetCallType(couts.cal_telefono2) tel2_type,
				dbo.fnGetCallType(couts.cal_telefono3) tel3_type,
				dbo.fnGetCallType(couts.cal_telefono4) tel4_type,
				dbo.fnGetCallType(couts.cal_telefono5) tel5_type,
				'
			end
			else
			begin
				set @sql=@sql+'0 tel_type,0 tel2_type,0 tel3_type,0 tel4_type,0 tel5_type,'
			end
			set @sql=@sql+'
			couts.dial_tels as dialOrder, W.list_id, isNull(R.sequence,0) as sequence,
			couts.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5) calkey
			FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
			on W.list_id = R.list_id
			left join ccocallsoutsource couts (nolock)
			on W.callout_id = couts.callout_id
			WHERE W.cal_status=0 -- Nuevas
			and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
			and W.cam_id='+ cast(isnull(@CAMPID,'0') as varchar(7)) + '
			and (
				( (W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+' & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
			or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'=0) or
				( (W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'2 & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
			or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'2=0) or
				((W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'3 & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
			or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'3=0) or
				((W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'4 & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
			or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'4=0) or
				((W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'5 & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
			or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'5=0)
			)
			and isnull(R.status,2) = 2
			order by R.sequence, W.cal_fechaDial '+ @Order_Asc_Desc +', W.callout_id'

			end -- TOMA EN CUENTA LAS NUEVAS

		----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
		select @sql=@sql+nchar(13)+ 'SET rowcount 0'
		if @Test=0
			begin
			select @sql=@sql+nchar(13)+ 'UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
			WHERE callout_id in(select callout_id from #NEW_JOBS)'
			end

		select @sql=@sql+nchar(13)+ 'SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
		user_id, tz, tz2, tz3, tz4, tz5, tel, tel2, tel3, tel4, tel5, dialOrder, list_id, sequence, calkey,
		tel_type, tel2_type, tel3_type, tel4_type, tel5_type
		FROM #NEW_JOBS where len(cal_telefono)>0'

		select @sql=@sql+nchar(13)+ 'DROP table #NEW_JOBS'
		--print @sql
		exec(@sql)
		return(0)