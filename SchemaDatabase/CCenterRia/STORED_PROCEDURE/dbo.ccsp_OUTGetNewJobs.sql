CREATE procedure [dbo].[ccsp_OUTGetNewJobs]
		@CAMPID int,
		@test int=0,
		@nAgentsLogin int=1,
		@iZonas int = null
		as
		--set nocount on
		declare @total int
		declare @topCount smallint, @bIsDaylight bit, @revHorario bit
		declare @country_id int, @TipoJobs int
		--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
		declare @sql varchar(MAX), @Order_Asc_Desc char(4)
		declare @camSurvey int
		select @camSurvey = 0
		DECLARE @iZonasTable TABLE (value int)

		select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

		-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
		SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
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
						  if @iZonas = 0 begin
								SELECT 0 as callout_id, 0 as cam_id, '' as cal_telefono, 0 as cal_status, '' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
								return
						  end
			  end
			  else begin
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
					SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,'
					+@isVerano+','
					+@isVerano+'2,'
					+@isVerano+'3,'
					+@isVerano+'4,'
					+@isVerano+'5,
					W.list_id, isNull(R.sequence,0) as sequence,
					cs.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5) calkey
					FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
					left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
					WHERE W.cal_status=1 -- CallBacks
					and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
					and W.cam_id=' + cast(isnull(@CAMPID,'0') as varchar(7)) + '
					and (
						  ( (W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+' & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
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
					order by prioridad_cb desc, W.cal_fechaDial ' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)

					--select @sql
		end -- TOMA EN CUENTA LOS CALLBACKS

		if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
		begin
					select @sql=@sql+nchar(13)+ 'SET ROWCOUNT ' + cast( @topCount/2 as varchar )

					select @sql=@sql+nchar(13)+ 'INSERT #NEW_JOBS
					SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,'
					+@isVerano+','
					+@isVerano+'2,'
					+@isVerano+'3,'
					+@isVerano+'4,'
					+@isVerano+'5,
					W.list_id, isNull(R.sequence,0) as sequence,
					cs.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5) calkey
					FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
					left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
					WHERE W.cal_status=0 -- Nuevas
					and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
					and W.cam_id='+ cast(isnull(@CAMPID,'0') as varchar(7)) + '
					and (
						  ( (W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+' & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
					or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'=0) or
						   ( (W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'2 & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
					or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'2=0) or
						   ( (W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'3 & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
					or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'3=0) or
						   ( (W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'4 & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
					or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'4=0) or
						   ( (W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'5 & ' + cast(isnull(@iZonas,0) as varchar(20))+ ')>0
					or W.izonahoraria'+case @bIsDaylight when 1 then '_verano' else '' end+'5=0)
					)
					and isnull(R.status,2) = 2
					order by R.sequence, W.cal_fechaDial '+ @Order_Asc_Desc +', callout_id'

		end -- TOMA EN CUENTA LAS NUEVAS
		----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
		select @sql=@sql+nchar(13)+ 'SET rowcount 0'
		if @Test=0
			  begin
					select @sql=@sql+nchar(13)+ 'UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
					WHERE callout_id in(select callout_id from #NEW_JOBS)'
		end

		if @Test = 2
		begin
			  select @sql=@sql+nchar(13)+ ' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0'
			  declare @nSQL nvarchar(4000)
			  set @nSQL=cast(@sql as nvarchar(4000))
			  exec sp_executesql @nSQL, N'@outA int OUTPUT',@outA=@total OUTPUT
			  return(@total)
		end
		else
		begin
			  select @sql=@sql+nchar(13)+ 'SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
		user_id, tz, tz2, tz3, tz4, tz5,
		case when tz is null then '''' else cal_telefono end as tel,
		case when tz2 is null then '''' else cal_telefono end as tel2,
		case when tz3 is null then '''' else cal_telefono end as tel3,
		case when tz4 is null then '''' else cal_telefono end as tel4,
		case when tz5 is null then '''' else cal_telefono end as tel5,
		NULL as dialOrder, list_id, sequence, calkey,
		0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type
		FROM #NEW_JOBS where len(cal_telefono)>0

		---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
		declare @regval int
		SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
		exec ccsp_RIAGetCampsNvosCB @cam_id=1,@Tipo=2,@user_id =0,@regval=@regval
		'
		end

		set @sql=@sql+nchar(13)+ 'DROP table #NEW_JOBS'
		print (@sql)
		exec(@sql)

		return(0)