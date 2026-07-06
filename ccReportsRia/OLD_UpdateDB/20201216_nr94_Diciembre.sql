SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 94

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'CW-4591 Insert en tablas ReportsFiltersMenus '
		SET @sql = '
					if ((select count (idReport) from ReportsFiltersMenus where idReport=4040 and filterMenuName=''filterby'') = 0)
					begin
						insert into ReportsFiltersMenus(idReport,filterMenuName) values(4040,N''filterby'')
					end
					'
		EXEC(@sql)

		SET @process = 'CW-4591 Insert en tablas ReportsFiltersMenus '
		SET @sql = '
					if ((select count (idReport) from ReportsFiltersMenus where idReport=4040 and filterMenuName=''date'') = 0)
					begin
						insert into ReportsFiltersMenus(idReport,filterMenuName) values(4040,N''date'')
					end
					'
		EXEC(@sql)


		SET @process = 'CW-4591 Insert en tablas ReportsFilters'
		SET @sql = '
					if ((select count (reportName) from ReportsFilters where filterName=''users'' and id=4040) = 0 )
					begin
						insert into ReportsFilters values(''Call Disposition campaign wg area'',''users'',4040)
					end'
		EXEC(@sql)

		SET @process = 'CW-4591 Insert en tablas ReportsFilters'
		SET @sql = '
					if ((select count (reportName) from ReportsFilters where filterName=''areas'' and id=4040) = 0 )
					begin
						insert into ReportsFilters values(''Call Disposition campaign wg area'',''areas'',4040)
					end
					'
		EXEC(@sql)

		SET @process = 'CW-4591 Insert en tablas ReportsFilters'
		SET @sql = '
					if ((select count (reportName) from ReportsFilters where filterName=''campaigns'' and id=4040) = 0 )
					begin
						insert into ReportsFilters values(''Call Disposition campaign wg area'',''campaigns'',4040)
					end
					'
		EXEC(@sql)

		SET @process = 'CW-4591 Insert en tablas ReportsFilters'
		SET @sql = '
					if ((select count (reportName) from ReportsFilters where filterName=''dispositionsOut'' and id=4040) = 0 )
					begin
						insert into ReportsFilters values(''Call Disposition campaign wg area'',''dispositionsOut'',4040)
					end
					'
		EXEC(@sql)

		SET @process = 'CW-4591 Insert en tablas ReportsFilters'
		SET @sql = '
					if ((select count (reportName) from ReportsFilters where filterName=''workgroups'' and id=4040) = 0 )
					begin
						insert into ReportsFilters values(''Call Disposition campaign wg area'',''workgroups'',4040)
					end
					'
		EXEC(@sql)

		SET @process = 'CW-4581 Insert en tablas ReportsFiltersMenus y ReportsFilters'
		SET @sql = '
					if ((select count (reportName) from ReportsFilters where filterName=''users'' and id=2030) = 0 )
					begin
						insert into ReportsFilters values(''Unavailable'',''users'',2030)
					end		
					'
		EXEC(@sql)

		
		SET @sql = '
					if ((select count (idReport) from ReportsFiltersMenus where idReport=2030 and filterMenuName=''filterby'') = 0)
					begin
						insert into ReportsFiltersMenus(idReport,filterMenuName) values(2030,N''filterby'')
					end'
		EXEC(@sql)

		
		SET @sql = '
					if ((select count (idReport) from ReportsFiltersMenus where idReport=2030 and filterMenuName=''date'') = 0)
					begin
						insert into ReportsFiltersMenus(idReport,filterMenuName) values(2030,N''date'')
					end'
		EXEC(@sql)

		
		SET @sql = '
					if ((select count (reportName) from ReportsFilters where filterName=''unavailables'' and id=2030) = 0 )
					begin
						insert into ReportsFilters values(''Unavailable'',''unavailables'',2030)
					end'
		EXEC(@sql)

		SET @process = 'CW-4580 Alter table RepAgentSummary'
		SET @sql = '
					if not exists (select * from sys.columns where name = N''login'' and Object_ID = Object_ID(N''RepAgentSummary'' ))
					begin
						EXEC sp_rename ''RepAgentSummary.userId'', ''login'', ''COLUMN'';
					end
	
					'
		EXEC(@sql)

		
		SET @sql = '
					if  not exists (select * from sys.columns where name = N''userId'' and Object_ID = Object_ID(N''RepAgentSummary''))
					begin
						Alter table ccReportsRIA.dbo.RepAgentSummary add userId smallint
					end'
		EXEC(@sql)

		SET @process = 'CW-4580 Insert en tablas ReportsFiltersMenus y ReportsFilters'
		SET @sql = '
					if ((select count (reportName) from ReportsFilters where filterName=''users'' and id=2100) = 0 )
					begin
						insert into ReportsFilters values(''Agent Summary'',''users'',2100)
					end					
					'
		EXEC(@sql)

		
		SET @sql = '
					if ((select count (idReport) from ReportsFiltersMenus where idReport=2100 and filterMenuName=''filterby'') = 0)
					begin
						insert into ReportsFiltersMenus(idReport,filterMenuName) values(2100,N''filterby'')
					end'
		EXEC(@sql)

		
		SET @sql = '
					if ((select count (idReport) from ReportsFiltersMenus where idReport=2100 and filterMenuName=''date'') = 0)
					begin
						insert into ReportsFiltersMenus(idReport,filterMenuName) values(2100,N''date'')
					end'
		EXEC(@sql)

		SET @process = 'CW-4580 Alter sp [ccspRepAgentSummary]  '
		SET @sql = '
					ALTER PROCEDURE [dbo].[ccspRepAgentSummary] 
					@action as tinyint, @from as datetime = null, @to as datetime = null	
					AS
					SET NOCOUNT ON
					if @from is null
						select @from = convert(datetime, convert(varchar(11), getdate()))
					if @to is null
						select @to = getdate()

					if @action = 1
					BEGIN

					declare @break integer 
					declare @pagos integer 
					declare @personal integer 
					declare @trabajoAdm integer
					declare @retro integer
					declare @falla integer
					declare @capacitacion integer
					declare @callwork integer
					declare @pausaGrl integer
					declare @rh integer
					declare @inicio integer

					declare @tresRing AS smallint
					declare @tresDialog AS smallint
					exec @tresRing=ccspConfigTresRing
					exec @tresDialog=ccspConfigTresDialog

					create table #AgentSession(
						user_id int not null,
						[user] varchar(255),
						login datetime ,
						logout datetime,
						sessionTime int,
						daygroup datetime
					)

					create table #RepDetail(
						user_id int not null,
						notReady int,
						daygroup datetime
					)

					create table #ccUsers(
						user_id int not null,
						login varchar(20)
					)

					create table #tipoNotReady(
						user_id int not null,
						daygroup datetime,
						break_ int,
						pagos_ int,
						personal_ int,
						trabajoAdm_ int,
						retro_ int,
						falla_ int,
						capacitacion_ int,
						callwork_ int,
						pausagrl_ int,
						rh_ int,
						inicio_ int
					)

					create table #CallsOut(
						user_id int not null,
						NoCalifOut int,
						NotAttendedCallOut int,
						AttendedCallOut int,
						tDialogOut int,
						tNotesOut int,
						abnd_xfer int,
						abnd_ring int,
						abnd_dialog int,
						daygroup datetime
					)

					create table #CallsIn(
						user_id int not null,
						NoCalifIn int,
						NotAttendedCallIn int,
						AttendedCallIn int,
						tDialogIn int,
						tNotesIn int,
						abnd_xfer int,
						abnd_ring int,
						abnd_dialog int,
						daygroup datetime
					)

					select 
						@break = max(case when descripcion like ''break'' then tiponotready_id else -1 end), 
						@pagos = max(case when descripcion like ''pagos'' then tiponotready_id else -1 end), 
						@personal = max(case when descripcion like ''personal'' then tiponotready_id else -1 end),
						@trabajoAdm = max(case when descripcion like ''trabajoAdm'' then tiponotready_id else -1 end),
						@retro = max(case when descripcion like ''retro'' then tiponotready_id else -1 end),
						@falla = max(case when descripcion like ''falla'' then tiponotready_id else -1 end),
						@capacitacion = max(case when descripcion like ''capacitacion'' then tiponotready_id else -1 end), 
						@callwork = max(case when descripcion like ''CWCallWork'' then tiponotready_id else -1 end), 
						@pausaGrl = max(case when descripcion like ''pausaGrl'' then tiponotready_id else -1 end),
						@rh = max(case when descripcion like ''rh'' then tiponotready_id else -1 end),
						@inicio = max(case when descripcion like ''inicio'' then tiponotready_id else -1 end) 
					from cctiponotready 

					insert into #AgentSession
						select	g.userId, g.[user] as [user], min(g.loginTime) as login, MAX(g.logoutTime) as logout, sum(g.sessionTimeSeconds) as sessionTime,
							dbo.getdaygroup(g.loginTime) as daygroup
						from RepAgentSession g
						where dbo.getdaygroup(g.loginTime) BETWEEN @from AND @to
						group by dbo.getdaygroup(g.logintime), g.userId, g.[user]

					insert into #ccUsers	
						select c.User_id, c.Login
						from ccUsers c

					insert into #RepDetail
						select r.userId, sum(r.timeSeconds) as notReady, dbo.getdaygroup(r.date) as daygroup
						from RepAgentNotReady r
						where dbo.getdaygroup(r.date) BETWEEN @from AND @to
						group by dbo.getdaygroup(r.date), r.userId

					insert into #tipoNotReady
						select	r.userId, dbo.getdaygroup(r.startDate) daygroup,
							isnull(sum(case r.tiponotreadyId when @break then r.statusTime end), 0) as break_,
							isnull(sum(case r.tiponotreadyId when @pagos then r.statusTime end), 0) as pagos_,
							isnull(sum(case r.tiponotreadyId when @personal then r.statusTime end), 0) as personal_,
							isnull(sum(case r.tiponotreadyId when @trabajoAdm then r.statusTime end), 0) as trabajoAdm_,
							isnull(sum(case r.tiponotreadyId when @retro then r.statusTime end), 0) as retro_,
							isnull(sum(case r.tiponotreadyId when @falla then r.statusTime end), 0) as falla_,
							isnull(sum(case r.tiponotreadyId when @capacitacion then r.statusTime end), 0) as capacitacion_,
							isnull(sum(case r.tiponotreadyId when @callwork then r.statusTime end), 0) as callwork_,
							isnull(sum(case r.tiponotreadyId when @pausaGrl then r.statusTime end), 0) as pausagrl_,
							isnull(sum(case r.tiponotreadyId when @rh then r.statusTime end), 0) as rh_,
							isnull(sum(case r.tiponotreadyId when @inicio then r.statusTime end), 0) as inicio_
						from RepAgentNotReadyDet r
						where dbo.getdaygroup(r.startDate) between @from and @to
						group by dbo.getdaygroup(r.startDate), r.userId

					insert into #CallsOut
						select	r.User_id,
							isnull(sum(case when r.calif_id =0 then 1 else null end),0) NoCalifOut,
							isnull(sum(case when r.statusCall_id = 11 then 1 else null end),0) NotAttendedCallOut,
							isnull(sum(case when r.statusCall_id = 13 then 1 else null end),0) AttendedCallOut,
							sum(r.cal_tDialog) tDialogOut, sum(r.cal_tNotas) tNotesOut,
							COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END)AS abnd_xfer,
							COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END)AS abnd_ring,
							COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END)AS abnd_dialog,
							dbo.getdaygroup(r.cal_Inicio) as daygroup
						from ccoCallsOut r with(index(IX_ccoCallsOut_2),nolock)
						where dbo.getdaygroup(r.cal_Inicio) between @from and @to and cal_manual in (0,2)
						group by dbo.getdaygroup(r.cal_Inicio), r.User_id

					insert into #CallsIn
						select	r.User_id,
							isnull(sum(case when r.calif_id =0 then 1 else null end),0) NoCalifIn,
							isnull(sum(case when r.statusCall_id = 11 then 1 else null end),0) NotAttendedCallIn,
							isnull(sum(case when r.statusCall_id = 13 then 1 else null end),0) AttendedCallIn,
							sum(r.cal_tDialog) tDialogIn, sum(r.cal_tNotas) tNotesIn,
							COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer,
							COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring,
							COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog,
							dbo.getdaygroup(r.cal_Inicio) as daygroup
						from ccCallsIn r with(index(IX_ccCallsIn),nolock)
						where dbo.getdaygroup(r.cal_Inicio) between @from and @to
						group by dbo.getdaygroup(r.cal_Inicio), r.User_id 

					delete RepAgentSummary with(rowlock) where date between @from and @to

					insert into RepAgentSummary

					select	a.daygroup as date,
						c.login as [login],
						a.[user] as [user],
						''''  as Campaing,
						sum(a.sessionTime) as sessionTime,
						MIN(a.login) as loginTime,
						MAX(a.logout) as logoutTime,
						(sum(isnull(co.tDialogOut,0)) + sum(isnull(co.tNotesOut,0)) + sum(isnull(ci.tDialogIn,0)) + sum(isnull(ci.tNotesIn,0))) as dialogTime,
						ISNULL(sum(r.notready),0) as ndTime,
						sum(isnull(co.AttendedCallOut,0)) as NCallsOut,
						sum(isnull(ci.AttendedCallIn,0)) as NCallsIn,
						ISNULL(sum(co.abnd_xfer) + sum(co.abnd_ring) + sum(co.abnd_ring) + sum(ci.abnd_xfer) + sum(ci.abnd_ring) + sum(ci.abnd_ring),0) as NCallsCorta,
						ISNULL(SUM(isnull(co.NotAttendedCallOut,0)) + SUM(isnull(ci.NotAttendedCallIn,0)),0) as NAtend,
						ISNULL(sum(isnull(ci.NoCalifIn,0)) + sum(isnull(co.NoCalifOut,0)),0) as NNoCalif,
						ISNULL(SUM(isnull(t.break_,0)), 0) as NdBreak,
						ISNULL(SUM(t.personal_), 0) as NdPersonal,
						ISNULL(SUM(t.pagos_), 0) as NdPagos,
						ISNULL(SUM(t.trabajoAdm_), 0) as NdTrabajoAdm,
						ISNULL(SUM(t.retro_), 0) as NdRetro,
						ISNULL(SUM(t.falla_), 0) as NdFalla,
						ISNULL(SUM(t.capacitacion_), 0) as NdCapacitacion,
						ISNULL(SUM(t.callwork_), 0) as NdCWCallWork,
						ISNULL(SUM(t.pausagrl_), 0) as NdPausaGrl,
						ISNULL(SUM(t.rh_), 0) as NdRH,
						ISNULL(SUM(t.inicio_), 0) as NdInicio,
						ISNULL(sum(a.sessionTime),0) - ISNULL(sum(r.notready),0) as Available,
						ISNULL((sum(isnull(co.tDialogOut,0)) + sum(isnull(co.tNotesOut,0)) + sum(isnull(ci.tDialogIn,0)) + sum(isnull(ci.tNotesIn,0))) / (sum(co.AttendedCallOut) + sum(ci.AttendedCallIn)),0)  as PromDialog,
						0 as Skill,
						''Verde'' as Center,
						(sum(isnull(co.tNotesOut,0)) + sum(isnull(ci.tNotesIn,0))) as twrapup,
						c.user_id as userId
					from #AgentSession a
					left join #RepDetail r on r.user_id = a.user_id and r.daygroup = a.daygroup
					left join #tipoNotReady t on t.user_id = a.user_id and t.daygroup = a.daygroup
					left join #CallsOut co on co.user_id = a.user_id and co.daygroup = a.daygroup
					left join #CallsIn ci on ci.user_id = a.user_id and ci.daygroup = a.daygroup 
					left join #ccUsers c on a.user_id = c.user_id
					group by a.user_id, a.daygroup, a.[user], c.login, c.user_id
					order by a.daygroup

					drop table #AgentSession
					drop table #RepDetail
					drop table #tipoNotReady
					drop table #CallsOut
					drop table #CallsIn
					drop table #ccUsers

					END'
		EXEC(@sql)

		set @process='CW-4585 Alter sp [ccspRepOutCallsDetail] '
		set @sql = '
					ALTER PROCEDURE [dbo].[ccspRepOutCallsDetail] 
					@action as tinyint,
					@from as datetime = NULL,
					@to as datetime = NULL
					AS

					IF @from IS NULL
						SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

					IF @to IS NULL
						SELECT @to = getdate()

					DECLARE @IVA INT
					DECLARE @country AS TINYINT

					SELECT @IVA = convert(INT, isnull(valor, 0))
					FROM ccsettings
					WHERE setting_id = 25

					SELECT @country = convert(TINYINT, isnull(valor, 1))
					FROM ccsettings
					WHERE setting_id = 104

					IF @country IS NULL
						SET @country = 1

					IF @action = 1
					BEGIN
						--Borrar lo que esta para no repetir
						DELETE
						FROM RepOutCallsDetail WITH (ROWLOCK)
						WHERE DATE >= @from AND DATE < @to

						INSERT INTO RepOutCallsDetail
						SELECT Call.cal_inicio AS [date],
							Call.cal_key AS [callKey],
							Call.cal_telefono AS [telephone],
							Call.cal_txfer + call.cal_tring AS [transfer],
							Call.cal_tdialog AS [dialog],
							ISNULL(Call.cal_tMoh, 0) AS [nque],
							Call.cal_tnotas AS [wrapup],
							ISNULL(Tipo.[description], '''') AS [CallDisposition],
							Call.cal_extension AS [extension],
							isnull(Usr.user_id, 0) AS [userId],
							ISNULL(convert(VARCHAR(255), Usr.LOGIN), ''systemTranslated_NoUserName'') [login],
							ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, '''') AS [username],
							camps.cam_id AS [campaignId],
							ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') AS [campaign],
							(CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60) AS [duration],
							CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country)) AS [ncost],

							@IVA AS iva,
							CONVERT(DECIMAL(10,2), dbo.fnGetCstoTarifa(Call.tipoLlamada_id, Call.provedor_id, (CEILING((ISNULL(Call.totalCall_Time, 0) + ISNULL(Call.cal_tMsg, 0)) / 60.0) * 60),@country) * (1 + (@IVA / 100.00))) AS total,
							CASE 
								WHEN prov.descrip IS NOT NULL THEN prov.descrip
								ELSE ''systemTranslated_NoCarrier'' 
							END AS [ByCarrier],
							ISNULL(tl.descrip, ''systemTranslated_Indefinite'') AS [Calltypes],
							CASE 
								WHEN Call.cal_manual = 0 THEN ''systemTranslated_Auto'' 
								ELSE ''systemTranslated_Manual'' 
							END AS [dialType], 
							CASE 
								WHEN Call.cal_whoHung = 0 THEN ''systemTranslated_Client'' 
								WHEN Call.cal_whoHung = 1 THEN ''systemTranslated_Agent'' 
								ELSE ''systemTranslated_AgentSurvey'' 
							END [whoHangUp], 
							CASE 
								WHEN call.califsub_id = 0 THEN ''systemTranslated_NoSubDisposition'' 
								ELSE isnull(sub.califSubDesc, '''') 
							END AS [subDisposition],
							sta.descripcion AS [dialResult], 
							Call.cal_id as [calId],
							datepart(yyyy, Call.cal_inicio) AS [year],
							datepart(mm, Call.cal_inicio) AS [month],
							datepart(dd, Call.cal_inicio) AS [day],
							datepart(hh, Call.cal_inicio) AS [hour],
							datepart(mi, Call.cal_inicio) AS [minutes],
							Call.cal_puerto,
							ISNULL(cs.Dato1, '''') AS [data1],
							ISNULL(cs.Dato2, '''') AS [data2],
							ISNULL(cs.Dato3, '''') AS [data3],
							ISNULL(cs.Dato4, '''') AS [data4],
							ISNULL(cs.Dato5, '''') AS [data5],
							ISNULL(Call.cal_tMsg, 0) AS [MessageTime],
							ISNULL(rc.grab_id, 0) as grabId
						FROM ccoCallsOut Call
							LEFT JOIN ccTipoCalifOUT Tipo ON Call.calif_id = Tipo.calif_id
							LEFT JOIN ccUserView Usr ON Usr.[user_id] = Call.[user_id] -- User_id IS NOT NULL
							LEFT JOIN ccCamps camps ON camps.[cam_id] = Call.[cam_id]
							LEFT JOIN ccStatusLlamada sta ON call.statuscall_id = sta.statuscall_id
							LEFT JOIN cstoProvedor prov ON prov.[provedor_id] = Call.[provedor_id]
							LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = Call.[tipoLlamada_id] AND tl.Country_id = @country)
							LEFT JOIN ccTipoCalifSubOut sub ON call.califsub_id = sub.califsub_id
							LEFT JOIN ccoDialers di ON di.dialer_id = Call.cal_puerto AND call.provedor_id = di.provedor_id
							LEFT JOIN ccoCallsOutSource cs ON Call.callout_id = cs.callout_id
							LEFT JOIN ccCallCost_RIA cc ON cc.country_id = tl.country_id AND cc.tipoLlamada_id = tl.tipoLlamada_id
							LEFT JOIN Ria_grabacion rc on (rc.cal_id = Call.cal_id and rc.tipo_llamada = 2)
						WHERE Call.cal_inicio >= @from AND Call.cal_inicio < @to AND Call.cal_manual IN (0, 2)
						ORDER BY DATE
					END'
		EXEC(@sql)

				
		IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF

