CREATE PROCEDURE [dbo].[ccspGenSession]
@from as smalldatetime,
@to as smalldatetime
AS
set nocount on

declare @date datetime
CREATE TABLE #tempccGenSession(
	[fila] int NOT NULL,
	[user_id] [smallint] NOT NULL,
	[login] [datetime] NOT NULL,
	[logout] [datetime] NULL,
	[extension] [varchar](7) NOT NULL,
	primary key (fila,user_id)
)

CREATE TABLE #temUserIdLogoutNull([user_id] [smallint] NOT NULL)
CREATE TABLE #temIdMaxLogoutNull([fila] int NOT NULL,[user_id] [smallint] NOT NULL,primary key (fila,user_id))


insert into #tempccGenSession
select A.Fila, A.User_id,A.fecha login,S.fecha logout,A.Extension
from (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,User_id,Extension,TipoMov,fecha--convert(varchar(19),fecha,121) fecha
from ccLogLogin a where fecha >= @from and fecha <= @to
)A
left join (select ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY FECHA,tipoMov) Fila,User_id,Extension,TipoMov,fecha from ccLogLogin a where fecha >= @from	and fecha <= @to
) S
on A.Fila=S.Fila-1 and A.User_id=S.User_id and A.TipoMov=1 and S.TipoMov=0
where A.TipoMov=1
order by login


update x  set x.fila = x.row
from(
	select fila, ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY login) row from #tempccGenSession
)x


insert into #temUserIdLogoutNull
select user_id from #tempccGenSession where logout is null group by user_id


insert into #temIdMaxLogoutNull
select A.fila,A.user_id from #tempccGenSession A
inner join (
select max(fila) fila,user_id from #tempccGenSession where user_id in( select user_id from #temUserIdLogoutNull ) group by user_id)B
	on A.fila=B.fila and A.user_id=B.user_id
	where A.logout is null

set @date=GETDATE()
update A set A.logout=case when @to<@date then @to else @date end from #tempccGenSession A
inner join #temIdMaxLogoutNull B on A.user_id=B.user_id and A.fila=B.fila


update A set A.logout =
	(select case when  max(fecha) is not null then max(fecha) when DATEDIFF(ss,A.login,B.login)<2 then DATEADD(ms,-10,B.login) else DATEADD(ms,5,A.login) end from ccLogAgentesDia C where A.user_Id=C.User_id and fecha between A.login and B.login ) --logout,
 from #tempccGenSession A
left join #tempccGenSession B on A.fila=B.fila-1  and A.user_id=B.user_id
where A.logout is null


delete from #tempccGenSession where login=logout

delete A
from #tempccGenSession A
inner join
(
select user_id,convert(varchar(19),[login],121)[login],convert(varchar(19),logout,121)logout  from #tempccGenSession
group by user_id,convert(varchar(19),[login],121),convert(varchar(19),logout,121) having count(*)>1
) B
on A.user_id=B.user_id and convert(varchar(19), A.login,121) =B.login and convert(varchar(19), A.logout,121)=B.logout



SELECT TOP 0 * INTO #temp_ccGenSession FROM #tempccGenSession

INSERT INTO #temp_ccGenSession (Fila,[user_id], extension, login, logout)
select ROW_NUMBER() OVER(ORDER BY login)+1000 Fila,
user_id, ext, login, logout
from(select a.user_id, max(Extension) as ext, a.fecha as 'logout',
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
		) as 'login'
		from ccLogLogin a
		where a.tipomov=0
		and fecha >= @from
		and fecha <= @to
		group by a.user_id, a.fecha) as sessiontime
		where datediff(day,login,logout) >= 1
order by user_id, login

UPDATE a with (ROWLOCK)
SET a.logout = b.logout
FROM #tempccGenSession b
INNER JOIN #tempccGenSession a on a.user_id = b.user_id and a.login = b.login and a.logout <> b.logout


select user_id, [login],[logout],extension from #tempccGenSession

DROP TABLE #temp_ccGenSession
drop table #tempccGenSession
drop table #temUserIdLogoutNull
drop table #temIdMaxLogoutNull


return(0)
set nocount off