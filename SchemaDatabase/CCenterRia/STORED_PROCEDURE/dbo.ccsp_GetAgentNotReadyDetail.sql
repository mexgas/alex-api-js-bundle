CREATE PROCEDURE [dbo].[ccsp_GetAgentNotReadyDetail] @user_id as int = 0, @sup_id as int = 0, @action as int = 0 as
set nocount on

declare @fecha_ini datetime
select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

create table #cctiponotready(
user_id int not null,
tiponotready_id int not null,
tstatus int not null,
Descripcion varchar(255) not null,
time_acum int not null,
Time_xEv int not null
)

if @action = 1
   begin

        SELECT a.user_id,a.TipoNotReady_id,isnull(sum(tStatus),0) as 'time',a.descripcion,a.Time_Acum,a.Time_xEV
		FROM
		(SELECT user_id,b.login,TipoNotReady_id,descripcion,Time_Acum,Time_xEV
		FROM cctiponotready a (nolock),ccusers b (nolock), ccGenViewRelsSupsAgent c
        WHERE  b.user_id = c.agt
		and c.sup = @sup_id) a
		LEFT JOIN
		(SELECT user_id,TipoNotReady_id,tStatus FROM ccLogAgentesNotReady with(nolock,index(IX_ccLogAgentesNotReady_2))
        WHERE fecha >= @fecha_ini)  b
		ON a.user_id = b.user_id AND a.TipoNotReady_id = b.TipoNotReady_id
		GROUP BY a.user_id,a.TipoNotReady_id,a.descripcion,a.Time_Acum,a.Time_xEV

   end

else if @user_id = 0 and @sup_id > 0
	begin

        SELECT DISTINCT a.user_id, 1 AS 'type', c.login
        from ccLogAgentesNotReady a (nolock),cctiponotready b (nolock), ccusers c (nolock), ccGenViewRelsSupsAgent d
        WHERE  a.user_id = d.agt
		and d.sup = @sup_id
		AND a.TipoNotReady_id = b.TipoNotReady_id
		AND b.Time_xEv <> 0 AND a.tStatus > b.Time_xEv
		and a.fecha >= @fecha_ini
		and a.user_id = c.user_id

        UNION

        SELECT DISTINCT a.user_id, 2 AS 'type', c.login
        from ccLogAgentesNotReady a (nolock),cctiponotready b (nolock), ccusers c (nolock), ccGenViewRelsSupsAgent d
        WHERE a.user_id = d.agt
		and d.sup = @sup_id
		AND a.TipoNotReady_id = b.TipoNotReady_id
		AND b.Time_Acum <> 0
		and a.fecha >= @fecha_ini
		and a.user_id = c.user_id
        GROUP BY a.user_id, a.TipoNotReady_id,b.Time_Acum, c.login
        HAVING sum(a.tStatus) > b.Time_Acum

		UNION

		SELECT a.agt, 0 AS 'type', b.login
		FROM ccGenViewRelsSupsAgent a, ccusers b
		where a.agt = b.user_id
		and a.sup = @sup_id

	end

else if @user_id > 0 and @sup_id = 0
	begin
		insert into #cctiponotready
		select a.user_id, a.tiponotready_id, a.tstatus, b.descripcion, b.time_acum, b.time_xev
		from ccLogAgentesNotReady a (nolocK), cctiponotready b (nolock)
		where user_id = @user_id
		and fecha >= @fecha_ini
		and a.tiponotready_id = b.tiponotready_id

		insert into #cctiponotready
		select @user_id, tiponotready_id, 0, descripcion, time_acum, time_xev
		from ccTipoNotReady nolock
		where tiponotready_id not in (select tiponotready_id from #cctiponotready)
		and issup = 0

		select *
		from #cctiponotready
end

drop table #cctiponotready

set nocount on