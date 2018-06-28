USE [master]
GO

declare @sessionKIll table(id int identity, sessionId int)
declare @i int,@count int
declare @sessionId int
DECLARE @SQL nvarchar(1000)

insert into @sessionKIll(sessionId)
SELECT	s.session_id AS SessionID		
FROM	sys.dm_exec_sessions s INNER JOIN sys.dm_exec_connections c
			ON s.session_id = c.session_id
		LEFT OUTER JOIN sys.sysprocesses p			ON s.session_id = p.spid
		CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) AS st
		where s.[program_name] like '%Replication Merge Agent%' 		

select * from @sessionKIll

select @i=1,@count =COUNT(*) from @sessionKIll
while @i<=@count begin
	select @sessionId=sessionId from @sessionKIll where id=@i
	SET @SQL = 'KILL ' + CAST(@sessionId as varchar(max))
	begin try
		EXEC (@SQL)
	end try
	begin catch
		print @SQL+ ' is proccess end'
	end catch
	set @i=@i+1
end

--KILL 112
--  -- Name: sp_MSregistermergesnappubid  --  -- Description: This procedure is used by the merge agent to register the   --              pubid of the publication for which the current snapshot is   --              being delivered in the snapshot delivery progress table. By   --              registering the pubid and the snapshot session token in the   --              snapshot delivery progress table, the merge agent will be   --              able to detect the case where a different snapshot is   --              being delivered over a previously interrupted snapshot.   --              If a different snapshot is being delivered over an   --              interrupted snapshot, this procedure will perform the   --              necessary cleanup in the merge meta-data tables to ensure that  --              the new snapshot can be delivered successfully.  --                -- Parameters: @snapshot_session_token nvarchar(260) (mandatory)  --             @pubid uniqueidentifier (mandatory)  --  -- Note: This procedure should only be called by the merge agent at the   --       subscriber database.  --  -- Returns: 0 - succeeded  --          1 - failed  --  -- Security: This is a public interface object, security check is performed   --           inside this procedure to restrict access to sysadmins and   --           db_owners of the subscriber database.  --  create procedure sys.sp_MSregistermergesnappubid (      @snapshot_session_token nvarchar(260),      @pubid uniqueidentifier      )  as  begin      set nocount on      declare @retcode int      declare @pubidprefix nvarchar(100)      declare @transaction_opened bit      declare @snapshot_progress_token nvarchar(500)      declare @snapshot_progress_token_hash nvarchar(500)      declare @previous_snapshot_session_token nvarchar(260)        select @retcode = 0      select @pubidprefix = N'<MergePubId>:'      select @transaction_opened = 0      select @snapshot_progress_token = @pubidprefix + convert(nvarchar(100), @pubid)      select @snapshot_progress_token_hash = sys.fn_repl32bitstringhash(@snapshot_progress_token)      select @previous_snapshot_session_token = null           -- Security check      exec @retcode = sys.sp_MSreplcheck_subscribe      if @@error<>0 or @retcode<>0 begin select @retcode=1 goto Failure end        begin transaction      save transaction sp_MSregistermergesnappubid      if @@error<>0 or @retcode<>0 begin select @retcode=1 goto Failure end      select @transaction_opened = 1        -- Try to pick up the session token of a previously interrupted snapshot      -- delivery session for this publication      if object_id('dbo.MSsnapshotdeliveryprogress', 'U') is not null      begin            select @previous_snapshot_session_token = session_token            from dbo.MSsnapshotdeliveryprogress           where progress_token_hash = @snapshot_progress_token_hash             and progress_token = @snapshot_progress_token          if @@error<>0 or @retcode<>0 begin select @retcode=1 goto Failure end            -- The current snapshot is different from the one interrupted before,           -- need to do cleanup of the interrupted snapshot                      if @previous_snapshot_session_token is not null and             @previous_snapshot_session_token <> @snapshot_session_token          begin              exec @retcode = sys.sp_MSpurgepartialmergesnapshot                       @pubid = @pubid              if @@error<>0 or @retcode<>0 begin select @retcode=1 goto Failure end              exec @retcode = sys.sp_MSrecordsnapshotdeliveryprogress                      @snapshot_session_token = @snapshot_session_token,                      @snapshot_progress_token = @snapshot_progress_token              if @@error<>0 or @retcode<>0 begin select @retcode=1 goto Failure end              end          else if @previous_snapshot_session_token is null          begin              exec @retcode = sys.sp_MSrecordsnapshotdeliveryprogress                      @snapshot_session_token = @snapshot_session_token,                      @snapshot_progress_token = @snapshot_progress_token              if @@error<>0 or @retcode<>0 begin select @retcode=1 goto Failure end              end      end      else      begin          exec @retcode = sys.sp_MSrecordsnapshotdeliveryprogress                  @snapshot_session_token = @snapshot_session_token,                  @snapshot_progress_token = @snapshot_progress_token          if @@error<>0 or @retcode<>0 begin select @retcode=1 goto Failure end          end        commit transaction      if @@error<>0 or @retcode<>0 begin select @retcode=1 goto Failure end      select @transaction_opened = 0        Failure:      if @transaction_opened = 1      begin          rollback transaction sp_MSregistermergesnappubid          commit transaction      end      return @retcode  end  
