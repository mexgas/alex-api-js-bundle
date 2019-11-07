CREATE procedure [dbo].[ccsp_RIAADMgetAgentsCampsMovslog]
as

declare @fecha smalldatetime
set @fecha = convert( smalldatetime, convert( varchar(10), getdate(), 121 ), 121 )

select super as Supervisor, mov as Movimiento, isNull(login, 'todos') as Agente, isNull(camp, 'todas' ) as Espe_Camp , fecha from 
(
	select
	cu2.login as super,
	case cma.tipomov when 1 then 'agrega in' else 'elimina in'  end as mov,
	cu1.login, 
	cam.descripcion as camp,
	cma.fecha
	from ccCampsMovsAgts cma
	left join ccUsers cu1 on cma.user_id = cu1.user_id
	join ccUsers cu2 on cma.superId = cu2.user_id
	left join ccInbound cam on cma.EC_id = cam.inbound_id
	where cma.tipoAsig = 1
	union 
	select 
	cu2.login as super,
	case cma.tipomov when 1 then 'agrega out' else 'elimina out'  end as mov,
	cu1.login, 
	cam.cam_descripcion as camp,
	cma.fecha
	from ccCampsMovsAgts cma
	left join ccUsers cu1 on cma.user_id = cu1.user_id
	join ccUsers cu2 on cma.superId = cu2.user_id
	left join ccCAmps cam on cma.EC_id = cam.cam_id
	where cma.tipoAsig = 2
)x
order by fecha