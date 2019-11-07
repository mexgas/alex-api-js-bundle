CREATE procedure ccsp_ADMgetAgentsCampsMovslog
as

declare @fecha smalldatetime
declare @idioma as bit
declare @todos as varchar(15)
declare @todas as varchar(15)
declare @agregain as varchar(15)
declare @eliminain as varchar(15)
declare @agregaout as varchar(15)
declare @eliminaout as varchar(15)

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23
set @fecha =dateadd(  dd, -7,  convert( smalldatetime, convert( varchar(10), getdate(), 121 ), 121 ))

if @idioma = 1
begin
select @todos = 'todos'
select @todas = 'todas'
select @agregain = 'agrega in'
select @eliminain = 'elimina in'
select @agregaout = 'agrega out'
select @eliminaout = 'elimina out'
end
else
begin
select @todos = 'all'
select @todas = 'all'
select @agregain = 'add in'
select @eliminain = 'remove in'
select @agregaout = 'add out'
select @eliminaout = 'remove out'

end

select super as Supervisor, mov as Movimiento, isNull(login, @todos) as Agente, isNull(camp, @todas ) as Espe_Camp , fecha from 
(
	select
	cu2.login as super,
	case cma.tipomov when 1 then @agregain else @eliminain  end as mov,
	cu1.login, 
	cam.descripcion as camp,
	cma.fecha
	from ccCampsMovsAgts cma
	left join ccUsers cu1 on cma.user_id = cu1.user_id
	join ccUsers cu2 on cma.superId = cu2.user_id
	left join ccInbound cam on cma.EC_id = cam.inbound_id
	where cma.tipoAsig = 1 and cma.fecha > @fecha
	union 
	select 
	cu2.login as super,
	case cma.tipomov when 1 then @agregaout else @eliminaout  end as mov,
	cu1.login, 
	cam.cam_descripcion as camp,
	cma.fecha
	from ccCampsMovsAgts cma
	left join ccUsers cu1 on cma.user_id = cu1.user_id
	join ccUsers cu2 on cma.superId = cu2.user_id
	left join ccCAmps cam on cma.EC_id = cam.cam_id
	where cma.tipoAsig = 2 and cma.fecha > @fecha
)x
order by fecha