CREATE Procedure [dbo].[ccsp_ADMGetCalifDay]
@Tipo bit, @cam_id int = 0, @user_id int = -1
AS
declare @Total int
declare @idioma as bit
declare @sin as varchar(25)
declare @otra as varchar(7)

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

if @idioma = 1
begin
	select @sin = 'No disposition'
	select @otra = 'Others'
end
else
begin
	select @sin = 'Sin Calificacion'
	select @otra = 'Otras'
end


create table #CalifTemp (
 Calificacion varchar(50),
 Total int )

if @user_id = -1 begin
	if @tipo = 1
		if @cam_id = 0
			insert into #CalifTemp	
		
			select case when description is not null then description else @sin  end as Calificacion, count(*)
			from ccoCallsOut co left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
			where cal_inicio > convert(varchar(11), getdate(), 101)
			and statuscall_id = 13
			group by description
		else
			insert into #CalifTemp	
		
			select case when description is not null then description else @sin end as Calificacion, count(*)
			from ccoCallsOut co left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
			where cal_inicio > convert(varchar(11), getdate(), 101)
			and (cam_id = @cam_id ) and statuscall_id = 13
			group by description
	else
	
		insert into #CalifTemp	
	
		select case when description is not null then description else @sin end as Calificacion, count(*)
		from ccCallsIn ci left join ccTipoCalif ca on ci.calif_id = ca.calif_id
		where cal_inicio > convert(varchar(11), getdate(), 101)
		and (inbound_id = @cam_id or @cam_id = 0) and statuscall_id = 13
		group by description
end
else
begin
		insert into #CalifTemp	

		select case when description is not null then 'IN - ' + description else @sin end as Calificacion, count(*)
		from ccCallsIn ci left join ccTipoCalif ca on ci.calif_id = ca.calif_id
		where cal_inicio > convert(varchar(11), getdate(), 101)
		and user_id = @user_id and statuscall_id = 13
		group by description

		insert into #CalifTemp	

		select case when description is not null then 'OUT - ' + description else @sin end as Calificacion, count(*)
		from ccoCallsOut co left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
		where cal_inicio > convert(varchar(11), getdate(), 101)
		and user_id = @user_id and statuscall_id = 13
		group by description
end



select @Total = sum(Total) from #CalifTemp

select case when total > @total / 100 or calificacion = @sin then calificacion else @otra end as Calificacion,
sum(Total) as Total
from #CalifTemp
group by case when total > @total / 100 or calificacion = @sin then calificacion else @otra end
order by 2 desc

drop table #CalifTemp