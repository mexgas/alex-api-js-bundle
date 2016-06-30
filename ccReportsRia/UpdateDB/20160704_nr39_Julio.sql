/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 20160608
Description:


Database: ccReportsRiaPara
Required version: 38

----ALTER PROCEDURE [dbo].[ccspRepCatalogos]

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 38

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

		set @process = ''
		set @Sql= ''
		EXEC(@Sql)

		set @process = 'DROP JOB -- ShrinkLogCCReportsRia'
		set @Sql= 'if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''ShrinkLogCCReportsRia'')
	EXEC msdb.dbo.sp_delete_job @job_name=N''ShrinkLogCCReportsRia'', @delete_unused_schedule=1'
		EXEC(@Sql)

		set @process = 'DROP JOB -- CW Reports Migration'
		set @Sql= 'if exists(SELECT * FROM msdb.dbo.sysjobs WHERE name = N''CW Reports Migration'')
	EXEC msdb.dbo.sp_delete_job @job_name=N''CW Reports Migration'', @delete_unused_schedule=1'
		EXEC(@Sql)

		set @process = ''
		set @Sql= ''
		EXEC(@Sql)

		set @process = 'CREATE JOB -- CW Reports Migration'
		set @Sql= 'USE [msdb]
/****** Object:  Job [CW Reports Migration]    Script Date: 14/06/2016 12:35:39 p.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 14/06/2016 12:35:39 p.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Reports Migration'',
		@enabled=1,
		@notify_level_eventlog=0,
		@notify_level_email=0,
		@notify_level_netsend=0,
		@notify_level_page=0,
		@delete_level=0,
		@description=N''No description available.'',
		@category_name=N''[Uncategorized (Local)]'',
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CW Reports Migration]    Script Date: 14/06/2016 12:35:39 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''CW Reports Migration'',
		@step_id=1,
		@cmdexec_success_code=0,
		@on_success_action=1,
		@on_success_step_id=0,
		@on_fail_action=2,
		@on_fail_step_id=0,
		@retry_attempts=0,
		@retry_interval=0,
		@os_run_priority=0, @subsystem=N''TSQL'',
		@command=N''
if (select [status] from migration where id = 1) = 0
begin
	if (select count(distinct publication)
	from distribution.dbo.MSsnapshot_history a ,distribution.dbo.MSsnapshot_agents b
	where b.publisher_db = ''''CCenterRia'''' and b.id = a.agent_id and comments like ''''%A snapshot of%%article(s) was generated.%'''') = 17
	begin
		update migration with (rowlock) set [status] = 1, [dateStart] = getdate(), [dateEnd] = getdate() where id = 1
		update migration with (rowlock) set [status] = 1, [dateStart] = getdate() where id = 33

		declare @from as datetime
		declare @day as int

		select @day = valor from ccReportsRia.dbo.ccSettings where setting_id = 27
		select @from = convert(datetime,convert(varchar(11),getdate() - @day))

		BEGIN TRANSACTION ccspRepOutDialDetail;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 2
			exec ccspRepOutDialDetail 1, @from
			COMMIT TRANSACTION ccspRepOutDialDetail;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutDialDetail;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 2
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 2 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCalls;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 3
			exec ccspRepOutCalls 1,  @from
			COMMIT TRANSACTION ccspRepOutCalls;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCalls;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 3
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 3 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentGI;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 4
			exec ccspRepAgentGI 1,  @from
			COMMIT TRANSACTION ccspRepAgentGI;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentGI;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 4
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 4 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentKPI;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 5
			exec ccspRepAgentKPI 1,  @from
			COMMIT TRANSACTION ccspRepAgentKPI;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentKPI;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 5
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 5 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentNotReady;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 6
			exec ccspRepAgentNotReady 1,  @from
			COMMIT TRANSACTION ccspRepAgentNotReady;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentNotReady;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 6
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 6 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentNotReadyDet;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 7
			exec ccspRepAgentNotReadyDet 1,  @from
			COMMIT TRANSACTION ccspRepAgentNotReadyDet;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentNotReadyDet;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 7
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 7 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepAgentSession;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 8
			exec ccspRepAgentSession 1,  @from
			COMMIT TRANSACTION ccspRepAgentSession;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepAgentSession;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 8
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 8 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInBill01900;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 9
			exec ccspRepInBill01900 1,  @from
			COMMIT TRANSACTION ccspRepInBill01900;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInBill01900;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 9
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 9 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInCalls;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 10
			exec ccspRepInCalls 1,  @from
			COMMIT TRANSACTION ccspRepInCalls;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInCalls;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 10
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 10 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInDIDResume;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 11
			exec ccspRepInDIDResume 1,  @from
			COMMIT TRANSACTION ccspRepInDIDResume;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInDIDResume;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 11
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 11 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInEffectiveness;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 12
			exec ccspRepInEffectiveness 1,  @from
			COMMIT TRANSACTION ccspRepInEffectiveness;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInEffectiveness;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 12
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 12 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInCallsDetail;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 13
			exec ccspRepInCallsDetail 1,  @from
			COMMIT TRANSACTION ccspRepInCallsDetail;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInCallsDetail;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 13
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 13 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInNotTransferred;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 14
			exec ccspRepInNotTransferred 1,  @from
			COMMIT TRANSACTION ccspRepInNotTransferred;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInNotTransferred;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 14
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 14 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInRejectedCalls;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 15
			exec ccspRepInRejectedCalls 1,  @from
			COMMIT TRANSACTION ccspRepInRejectedCalls;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInRejectedCalls;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 15
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 15 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCallBacks;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 16
			exec ccspRepOutCallBacks 1,  @from
			COMMIT TRANSACTION ccspRepOutCallBacks;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCallBacks;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 16
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 16 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepIVRGeneral;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 17
			exec ccspRepIVRGeneral 1,  @from
			COMMIT TRANSACTION ccspRepIVRGeneral;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepIVRGeneral;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 17
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 17 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepIVRByOptions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 18
			exec ccspRepIVRByOptions 1,  @from
			COMMIT TRANSACTION ccspRepIVRByOptions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepIVRByOptions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 18
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 18 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCallsDetail;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 19
			exec ccspRepOutCallsDetail 1,  @from
			COMMIT TRANSACTION ccspRepOutCallsDetail;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCallsDetail;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 19
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 19 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCallsByTelephone;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 20
			exec ccspRepOutCallsByTelephone 1,  @from
			COMMIT TRANSACTION ccspRepOutCallsByTelephone;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCallsByTelephone;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 20
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 20 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepIVRDetail;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 21
			exec ccspRepIVRDetail 1,  @from
			COMMIT TRANSACTION ccspRepIVRDetail;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepIVRDetail;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 21
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 21 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutDials;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 22
			exec ccspRepOutDials 1,  @from
			COMMIT TRANSACTION ccspRepOutDials;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutDials;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 22
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 22 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepIVRFirstOption;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 23
			exec ccspRepIVRFirstOption 1,  @from
			COMMIT TRANSACTION ccspRepIVRFirstOption;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepIVRFirstOption;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 23
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 23 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInChangeFlow;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 24
			exec ccspRepInChangeFlow 1,  @from
			COMMIT TRANSACTION ccspRepInChangeFlow;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInChangeFlow;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 24
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 24 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutCallBilling;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 25
			exec ccspRepOutCallBilling 1,  @from
			COMMIT TRANSACTION ccspRepOutCallBilling;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutCallBilling;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 25
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 25 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutDispositions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 26
			exec ccspRepOutDispositions 1,  @from
			COMMIT TRANSACTION ccspRepOutDispositions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutDispositions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 26
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 26 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutKPI;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 27
			exec ccspRepOutKPI 1,  @from
			COMMIT TRANSACTION ccspRepOutKPI;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutKPI;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 27
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 27 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepOutSubDispositions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 28
			exec ccspRepOutSubDispositions 1,  @from
			COMMIT TRANSACTION ccspRepOutSubDispositions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepOutSubDispositions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 28
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 28 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepSpecialTimes;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 29
			exec ccspRepSpecialTimes 1,  @from
			COMMIT TRANSACTION ccspRepSpecialTimes;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepSpecialTimes;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 29
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 29 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepTrunkBusy;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 30
			exec ccspRepTrunkBusy 1,  @from
			COMMIT TRANSACTION ccspRepTrunkBusy;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepTrunkBusy;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 30
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 30 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInDispositions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 31
			exec ccspRepInDispositions 1,  @from
			COMMIT TRANSACTION ccspRepInDispositions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInDispositions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 31
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 31 and [error] = ''''''''

		BEGIN TRANSACTION ccspRepInSubDispositions;
		BEGIN TRY
			update migration with (rowlock) set [dateStart] = getdate() where id = 32
			exec ccspRepInSubDispositions 1,  @from
			COMMIT TRANSACTION ccspRepInSubDispositions;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION ccspRepInSubDispositions;
			update migration with (rowlock) set [error] = ERROR_MESSAGE() where id = 32
		END CATCH

		update migration with (rowlock) set [status] = 1, [dateEnd] = getdate() where id = 32 and [error] = ''''''''

		update migration with (rowlock) set [status] = 2, [dateEnd] = getdate() where id = 33
	end
end
else begin
	EXEC msdb.dbo.sp_update_job @job_name=N''''CW Reports Migration'''',@enabled = 0
end
'',
		@database_name=N''ccReportsRia'',
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''migration'',
		@enabled=1,
		@freq_type=4,
		@freq_interval=1,
		@freq_subday_type=4,
		@freq_subday_interval=1,
		@freq_relative_interval=0,
		@freq_recurrence_factor=0,
		@active_start_date=20130620,
		@active_end_date=99991231,
		@active_start_time=0,
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
		EXEC(@Sql)

		set @process = ''
		set @Sql= ''
		EXEC(@Sql)

		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off