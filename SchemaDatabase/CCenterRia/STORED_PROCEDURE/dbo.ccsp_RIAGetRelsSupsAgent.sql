CREATE PROCEDURE [dbo].[ccsp_RIAGetRelsSupsAgent]

AS

--Relaciones Sup-Agt de acuerdo a WorkGroups
select distinct a1.user_id as agt, a5.user_id as sup, a5.login
from ccusers a1 
inner join ccriaworkgroupusers a2 on (a1.user_id=a2.user_id and tipouser_id=1)
inner join (select a3.user_id, a4.IDWG, a3.login  
			from ccusers a3 
			inner join ccriaworkgroupusers a4 on (a3.user_id = a4.user_id and (tipouser_id = 2 or tipouser_id = 6) and a3.onLine = 1)
			) a5 
			on (a2.IDWG = a5.IDWG)
where a5.user_id not in (select User_id from ccRIAUsr_AdminPermissions where per_id = 4) -- Excluye sólo monitoreo
order by a1.user_id, a5.user_id