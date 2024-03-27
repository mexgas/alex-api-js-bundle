--204
/***********************************************/
-- Delete Old Records New Version Febrero 2024 --
/***********************************************/
set nocount on

declare @idSqlCmd int
declare @sqlCmd nvarchar(max)
declare @days int

set @idSqlCmd = 0
set @sqlCmd  =''
set @days = 30

create table #sqlCmdDeleteOldRecords(
idSqlCmd int identity primary key,
sqlCmd nvarchar(max) not null,
[status] int not null,
isReplicated bit not null
)

create table #ccoCallsOutSourceIds(
callout_id int not null primary key
)

insert into #ccoCallsOutSourceIds (callout_id)
select distinct A.callout_id
from ccoCallsOutSource A
inner join ccoLogDials b on A.callout_id = b.callout_id
where b.fecha < dateadd(dd, -@days, getdate())

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('truncate table ccBorrardasReciclaje', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('truncate table ccLogCampsAgentesDia', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('truncate table cclogInfo', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('truncate table ccUploadTemporal', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccLogReciclaje where fecha < @date', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccPosicionCamps where Fecha < @date', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccPosicionEspecialidad where Fecha < @date', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccRIAlog where operationDate < @date', 0, 0)


insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccRIAlog where operationDate < @date', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccRiaChat_log where fecha_chat < @date', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccRIALogAgentesNotReady where fecha < @date', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccRIAWorkGroup_logDial_id where timestamp < @date', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete xxclientehistorial where fechaAct < @date', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccCallsIn where cal_Inicio < @date', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete cccallsreject where cal_inicio < @date', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccLogAgentesDia where fecha < @date', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccLogAgentesDia_Dialog where fecha_Dialog < @date', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccLogAgentesNotReady where fecha < @date', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccLogLogin where fecha < @date', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccLogtransfers where fechaFin < @date', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccriachats where chatDate < @date', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccRIAWorkGroup_Calid where timestamp < @date', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ivrcallsin where date < @date', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ivroptions where date < @date', 0, 1)

/******************************************************************/
/* Delete by date because rows in ccoLogDials > ccoCallsOutSource */
/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete ccoLogDials where fecha < @date', 0, 1)

/******************************************************************/

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete a from cchistoriallistanegra as a inner join #ccoCallsOutSourceIds as b on a.callout_id = b.callout_id and A.fecha<@date', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete a from ccoWorkingTable as a inner join #ccoCallsOutSourceIds as b on a.callout_id = b.callout_id and cal_fechaDial<@date', 0, 0)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete a from ccocallbacks as a, #ccoCallsOutSourceIds as b where a.callout_id = b.callout_id and cal_fecha<@date', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete a from ccoCallsOut as a  inner join #ccoCallsOutSourceIds b on  a.callout_id = b.callout_id where a.cal_Inicio<@date', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete a from ccoLogDials as a  inner join #ccoCallsOutSourceIds b on a.callout_id = b.callout_id and fecha<@date', 0, 1)

--quita los calloutId que existen registros recientes
insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values (';with logDialsMax as(
select b.callout_id,MAX(b.fecha) fecha from #ccoCallsOutSourceIds A
inner join ccoLogDials b on A.callout_id = b.callout_id
group by b.callout_id
)
delete B from logDialsMax A
inner join #ccoCallsOutSourceIds B on A.callout_id=B.callout_id
where @date>A.fecha', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete a from ccoCallsOutSource a inner join #ccoCallsOutSourceIds b on a.callout_id = b.callout_id and cal_fechaDial<@date', 0, 1)

insert into #sqlCmdDeleteOldRecords (sqlCmd, [status], isReplicated)
values ('delete a from ccoCallPriorityOrder a inner join #ccoCallsOutSourceIds b on a.callout_id = b.callout_id where a.callout_id = b.callout_id', 0, 1)

while (select count(*) from #sqlCmdDeleteOldRecords where [status] = 0 ) > 0
	begin
		set rowcount 1
			select @idSqlCmd = idSqlCmd, @sqlCmd = SqlCmd from #sqlCmdDeleteOldRecords where [status] = 0 order by idSqlCmd
		set rowcount 0

		--print (@sqlCmd)
		exec sp_executesql @sqlCmd, N'@date datetime', @date

		WAITFOR DELAY '00:00:01'

		while(SELECT count(*)
				FROM sys.dm_exec_requests a
				INNER JOIN sys.dm_exec_connections b
				ON a.session_id = b.session_id
				INNER JOIN sys.dm_exec_sessions c
				ON c.session_id = a.session_id
				CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS d
				WHERE a.session_id > 50
				AND a.session_id = @@SPID
				and d.text = @sqlCmd) > 0
			begin
				WAITFOR DELAY '00:00:01'
			end

		update #sqlCmdDeleteOldRecords
		set [status] = 1
		where idSqlCmd = @idSqlCmd
	end

drop table #sqlCmdDeleteOldRecords
drop table #ccoCallsOutSourceIds