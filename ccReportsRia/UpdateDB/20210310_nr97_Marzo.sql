SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 97

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'CW-4645 Alter SP ccspRepAgentNotReady'
		SET @sql = '					
					ALTER PROCEDURE [dbo].[ccspRepAgentNotReady]
					@action as tinyint,
					@from as datetime = null,
					@to as datetime = null
					AS



					if @from is null
						select @from = convert(datetime,convert(varchar(11),getdate()))
					if @to is null
						select @to = getdate()

					if @action = 1
					begin
	
						IF OBJECT_ID(''tempdb..#notReady'') IS NOT NULL drop table #notReady	
						IF OBJECT_ID(''tempdb..#notReady2'') IS NOT NULL drop table #notReady2	
						IF OBJECT_ID(''tempdb..#tempFechasR'') IS NOT NULL drop table #tempFechasR

						declare @dateNow datetime
						set @dateNow=getdate()

						create table #tempFechasR(id int,fecha datetime,tiempo int)	  

						SELECT DATEADD(ss,-(tStatus),(fecha)) as dateStartDetail,(fecha) as dateEndDetail,
						convert(smalldatetime,convert(varchar(13),DATEADD(ss,-tStatus,fecha),121) + '':00:00.000'',121) AS timegroup
						,dateadd(hh,1,convert(smalldatetime,convert(varchar(13),fecha,121) + '':00:00.000'',121)) as timegroup_next, TipoNotReady_id
						,[User_id],(tStatus) as [timeNotReady],1 as [count], tstatus as [time]
						into #notReady
						FROM ccLogAgentesNotReady
						WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to
	
						insert into #tempFechasR   
						select User_id,MAX(fecha) as maxfecha,DATEDIFF(ss,MAX(fecha),@dateNow) from ccLogAgentesDia
						where CONVERT(varchar(11),fecha,121)=CONVERT(varchar(11), @dateNow,121) group by User_id  

						insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next,TipoNotReady_id,[User_id],[timeNotReady],[count],[time])
						select
						B.fecha as dateStartDetail,
						@dateNow as dateEndDetail,
						CONVERT(smalldatetime,CONVERT(varchar(13),B.fecha,121)+ '':00'',121) AS timegroup,
						case when @dateNow=CONVERT(smalldatetime,CONVERT(varchar(13),@dateNow,121)+ '':00'',121) then CONVERT(smalldatetime,CONVERT(varchar(13),@dateNow,121)+ '':00'',121)
						else CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(hh,1,@dateNow),121)+ '':00'',121) end AS timegroup_next
						,0 as TipoNotReady_id,User_id,0 as timeNotReady,1 as [count],tiempo as [time]
						from ccLogAgentesDia A
						inner JOIN #tempFechasR B ON A.fecha=B.fecha  and A.User_id=B.id WHERE currentStatus =2
	
						select * into #notReady2 from #notReady where datediff(HH,timegroup,timegroup_next)>1	 
						delete #notReady where datediff(HH,timegroup,timegroup_next) > 1
						;
						with times as(
						select convert(varchar(13),Start,121)+'':00:00'' as Start,dateadd(hh,1, convert(varchar(13),Start,121)+'':00:00'') as Stop 
						from TmpTimesInterval where start between @from and @to
						group by convert(varchar(13),Start,121)+'':00:00'',convert(varchar(13),Stop,121)+'':00:00''
						)	
						insert into #notReady(dateStartDetail,dateEndDetail,timegroup,timegroup_next, tiponotready_id,User_id,timeNotReady, [count])
						select (dateStartDetail),(dateEndDetail),convert(varchar,th.start,121) as timegroup,convert(varchar, th.stop,121) as timegroup_next, tiponotready_id,[User_id]
						,isnull((case 
						when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) 
						then datediff(ss,dateStartDetail,dateadd(ss,timeNotReady,dateStartDetail))
						when th.start <= dateStartDetail and  th.stop > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail)
						then datediff(ss,dateStartDetail,th.stop)
						when th.start > dateStartDetail and th.start <= dateadd(ss,timeNotReady,dateStartDetail) and  th.stop > dateadd(ss,timeNotReady,dateStartDetail) 
						then datediff(ss,th.start,dateadd(ss,timeNotReady,dateStartDetail))
						when th.start > dateStartDetail and th.stop < dateadd(ss,timeNotReady,dateStartDetail) 
						then datediff(ss,th.start,th.stop) else  0 end),0) as timeNotReady,
						1 as [count]


						from #notReady2 t
						inner join times th on (t.timegroup > th.Start and t.timegroup < th.stop) OR th.Start between t.timegroup and t.timegroup_next
						where  datediff(ss,th.start,timegroup_next)>0
	
						--Delete tepetidos
						delete from RepAgentNotReady with(rowlock) 	where date >= @from AND date < @to
						;
						with tmpSession as(
							select user_id,convert(varchar(14),timegroup,121)+''00:00'' as timegroup 	
							,sum(tlog) as tlog
							from TmpSessionTimeGroup where login between @from and @to
							group by user_id,  convert(varchar(14),timegroup,121)+''00:00''
						),
						timeNotReady as(
							select timegroup,User_id,TipoNotReady_id,timeNotReady [time],sum([count]) [count] from #notReady 
							group by User_id,timegroup,TipoNotReady_id,timeNotReady
						)

						insert into RepAgentNotReady
						select A.timegroup as date,userView.Login,A.user_id, userView.apellidopaterno + '' '' + userView.apellidomaterno + '' '' + userView.nombres as [user]
						,a.tlog as sessionTime
						,isnull(d.tiponotready_id,0) tiponotready_id, 
						isnull(d.descripcion,'''') descripcion
						,isnull(d.descripcion,'''') + ''_Count'' as descripcion_count, isnull([count],0) count,
						isnull(d.descripcion,'''') + ''_Time'' as descripcion_time
						,isnull(timeNotReady.time,0) as [time],
						isnull(timeNotReady.time,0) as timeSeconds
						,datepart(yyyy,a.timegroup) year, datepart(mm,a.timegroup) [mounth], datepart(dd,a.timegroup) [day], datepart(hh,a.timegroup) [hour]
						,0 as [minute]
						from tmpSession A
						inner join ccUserView userView on A.user_id=userView.User_id
						left join timeNotReady on timeNotReady.User_id=A.user_id and A.timegroup=timeNotReady.timegroup
						left join ccTipoNotReady d on timeNotReady.TipoNotReady_id=d.TipoNotReady_id	
		
						IF OBJECT_ID(''tempdb..#notReady'') IS NOT NULL drop table #notReady	
						IF OBJECT_ID(''tempdb..#notReady2'') IS NOT NULL drop table #notReady2	
						IF OBJECT_ID(''tempdb..#tempFechasR'') IS NOT NULL drop table #tempFechasR
	
					end'
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

