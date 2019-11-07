CREATE PROCEDURE ccsp_ADMGetCamCalifRel 
@user_id smallint = 1
AS

select 0 as tipo, i.inbound_id as cam_id, descripcion as 'Camp_Espec', c.calif_id, cast(orden as varchar(3)) + '. ' + ci.description as Calificacion, '-' as CanReprogram, '-' as AutoTime, orden
from ccInbound i left join ccCalifCamp c
on i.inbound_id = c.cam_id and c.tipo = 0
left join ccTipoCalif ci
on c.calif_id = ci.calif_id
where inbound_id in (select cam_id from ccSupervisorCam where tipo = 0 and user_id = @user_id ) or @user_id =1
UNION
select 1 as tipo, o.cam_id, cam_descripcion + case cam_activo when 1 then '' else ' - INACTIVA' end as 'Camp_Espec', c.calif_id, cast(orden as varchar(3)) + '. ' + co.description as Calificacion, cast(case canReprogram when 0 then 'NO' else 'SI' end as varchar(2)) as CanReprogram, case canReprogram when 0 then '-' else cast(AutoTime as varchar(10)) end as AutoTime, orden
from ccCamps o left join ccCalifCamp c
on o.cam_id = c.cam_id and c.tipo = 1
left join ccTipoCalifOUT co
on c.calif_id = co.calif_id
where o.cam_id in (select cam_id from ccSupervisorCam where tipo = 1 and user_id = @user_id ) or @user_id = 1
order by tipo, camp_espec, orden