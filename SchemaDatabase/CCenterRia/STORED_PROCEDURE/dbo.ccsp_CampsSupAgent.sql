CREATE PROCEDURE dbo.ccsp_CampsSupAgent
@loginAgent varchar(30),
@PassAgent varchar(30),
@loginSup varchar(30),
@PassSup varchar(30)
AS
SET NOCOUNT ON
select sum(x) x from
(	select count(*) as x from 
		(select count(cam_id) cam_id from ccCampsAgente where cam_id in
			(select cam_id from ccsupervisorcam where tipo = 1 and user_id in 
				(select user_id from ccusers where tipoUser_id > 1 and login = @loginSup and (password =@PassSup or password = dbo.md5(@PassSup))
				)
			)
		and user_id in ( select user_id from ccusers where tipoUser_id = 1 and login = @loginAgent)
		group by IDWG
	) as M

	union

	select count(*) from 
		(select count(inbound_id) inbound_id from ccInboundAgentes where inbound_id  in
			(select cam_id from ccsupervisorcam where tipo = 0 and user_id in 
				(select user_id from ccusers where tipoUser_id > 1 and login = @loginSup and (password =@PassSup or password = dbo.md5(@PassSup))
				)
			)
		and user_id in ( select user_id from ccusers where tipoUser_id = 1 and login = @loginAgent)
		group by IDWG
	) as N
)y
SET NOCOUNT OFF