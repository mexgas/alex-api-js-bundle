CREATE PROCEDURE [dbo].[ccsp_RIACampsSupAgent]
@loginAgent varchar(30),
@PassAgent varchar(32),
@PassSup varchar(32)
AS
SET NOCOUNT ON
select 
 (select count(distinct cam_id) as x from ccCampsAgente where cam_id in
	(select sca.cam_id 
	from ccsupervisorcam sca join ccusers usr on sca.user_id=usr.user_id
	where sca.tipo = 1 and (usr.tipoUser_id&2=2) and (usr.password=@PassSup or usr.password=dbo.md5(@PassSup))
 ) and user_id in (select user_id from ccusers where tipoUser_id = 1 and login = @loginAgent))
+
 (select count(distinct inbound_id) from ccInboundAgentes where inbound_id in
	(select sca.cam_id 
	from ccsupervisorcam sca join ccusers usr on sca.user_id=usr.user_id
	where sca.tipo = 0 and (usr.tipoUser_id&2=2) and (usr.password=@PassSup or usr.password=dbo.md5(@PassSup))
 ) and user_id in ( select user_id from ccusers where tipoUser_id = 1 and login = @loginAgent))
 as Accountant
SET NOCOUNT OFF