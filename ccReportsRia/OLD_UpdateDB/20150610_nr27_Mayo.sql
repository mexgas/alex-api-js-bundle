/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Mick toriz
Date: 2015/03/10
Description:

	------ ALTER PROCEDURE ccspRepAgentSession


Database: ccReportsRia
Required version: 26

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 27

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

	set @process ='ALTER PROCEDURE ccspRepAgentSession'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentSession]
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
					   delete from RepAgentSession with(rowlock) where date >= @from and date < @to

						select *  into #tempSession from(
						 select a.extension, a.user_id, a.fecha as ''subLogin'',
						(
						  select isnull(max(Fecha),getdate()) from ccLogLogin b with(nolock)
							where b.user_id = a.user_id and b.tipomov = 0 and  b.fecha >= a.fecha and b.fecha <=
							(
							  select isnull(min(fecha),''99991231 23:59:59.998'') from ccLogLogin with(nolock)
							  where user_id = b.user_id and tipomov = 1 and fecha > a.fecha)
						  ) as ''subLogout''
						from ccLogLogin a where a.tipomov=1 and fecha >= @from and fecha <= @to)x

					  insert into RepAgentSession
					  select distinct subLogin as date, u.login as userLogin, sessiontime.user_id,
					   u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + u.nombres as [user], extension, subLogin as loginTime,
					   subLogout as logoutTime,
					   datediff(ss,subLogin,subLogout) as sessionTime,
					   datediff(ss,subLogin,subLogout) as sessionTimeSeconds,
					   datepart(yyyy,subLogin), datepart(mm,subLogin), datepart(dd,subLogin),
					   datepart(hh,subLogin), datepart(mi,subLogin)
					  from (
					  select  a.extension, a.user_id,subLogin,
					  (
						select isnull(min(fecha),subLogout) from ccLogLogin where a.user_id= user_id and fecha>subLogin and fecha <subLogout
					  ) subLogout
					   from #tempSession a
					  )sessiontime
					   left join ccusers u on (sessiontime.user_id = u.user_id)




					  SELECT TOP 0 * INTO #temp_RepAgentSession FROM RepAgentSession

					  INSERT INTO #temp_RepAgentSession
					  select subLogin as date, u.login as userLogin, sessiontime.user_id,
					  u.apellidopaterno + '' '' + u.apellidomaterno + '' '' + u.nombres as [user], extension, subLogin as loginTime,
					  subLogout as logoutTime,
					  datediff(ss,subLogin,subLogout) as sessionTime,
					  datediff(ss,subLogin,subLogout) as sessionTimeSeconds,
					  datepart(yyyy,subLogin), datepart(mm,subLogin), datepart(dd,subLogin),
					  datepart(hh,subLogin), datepart(mi,subLogin)
					  from(select a.extension, a.user_id, a.fecha as ''subLogout'',
						(select isnull(max(Fecha),getdate())
						 from ccLogLogin b with(nolock)
						 where b.user_id = a.user_id and
						 b.tipomov = 1 and
						 b.fecha <= a.fecha and
						 b.fecha >= (select isnull(max(fecha),b.fecha)
							from ccLogLogin with(nolock)
							where user_id = b.user_id and
							tipomov = 0 and
							fecha < a.fecha)
						) as ''subLogin''
						from ccLogLogin a
						where a.tipomov=0
						and fecha >= @from
						and fecha <= @to
					   ) as sessiontime
					   left join ccusers u on (sessiontime.user_id = u.user_id)
					   where datediff(day,subLogin,subLogout) >= 1
					  order by user_id, loginTime

					  UPDATE a with (rowlock)
					  SET a.logoutTime = b.logoutTime,
					  a.sessionTime = b.sessionTime,
					  a.sessionTimeSeconds = b.sessionTimeSeconds
					  FROM #temp_RepAgentSession b
					  INNER JOIN RepAgentSession a
					  on a.userId = b.userId
					  and a.loginTime = b.loginTime
					  and a.logoutTime <> b.logoutTime


					  drop table #tempSession
					  DROP TABLE #temp_RepAgentSession


					end'
	EXEC(@sql)

			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			exec ccsp_getVersion 'BD', @version

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