CREATE Procedure dbo.ccsp_RIAADMGetAgentCalifDay
@Type tinyint, 
@cam_id as smallint,
@user_id int
AS
set nocount on
declare @Total int
create table #CalifTemp (
 tipo integer,
 cam_id int,
 Calificacion varchar(50),
 Total int )

If @Type = 0 --especialidad
 begin
		insert into #CalifTemp	
		select 0 as tipo,ci.Inbound_id as cam_id, case when description is not null then description else 'No disposition' end as Calificacion, count(*)
		from ccCallsIn ci left join ccTipoCalif ca on ci.calif_id = ca.calif_id
		left join ccInbound cci on cci.inbound_id = ci.inbound_id		
		where cal_inicio > convert(varchar(11), getdate(), 101) and 
		user_id = @user_id and statuscall_id = 13 and  ci.Inbound_id = case @cam_id when 0 then ci.Inbound_id else @cam_id end
		group by description,ci.Inbound_id
 end

If @Type = 1--campañas
 begin
		insert into #CalifTemp	
		select 1 as tipo,co.cam_id as cam_id,case when description is not null then description else 'No disposition' end as Calificacion, count(*)
		from ccoCallsOut co left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
		left join ccCamps ci on ci.cam_id = co.cam_id
		where cal_inicio > convert(varchar(11), getdate(), 101) and 
		user_id = @user_id and statuscall_id = 13 and co.cam_id = case @cam_id when 0 then co.cam_id else @cam_id end
		group by description,co.cam_id
 end

select @Total = sum(Total) from #CalifTemp
select tipo,cam_id,case when total > @total / 100 or calificacion = 'No disposition' then calificacion else 'Others' end as Calificacion,
sum(Total) as Total from #CalifTemp
group by tipo, case when total > @total / 100 or calificacion = 'No disposition' then calificacion else 'Others' end, cam_id
order by 2 desc

drop table #CalifTemp
set nocount off