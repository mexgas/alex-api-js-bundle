CREATE PROCEDURE dbo.ccsp_AdminSaveMovAgentECDragDrop
@User_id smallint,
@EC_id smallint,
@EC_anterior smallint,
@TipoLlamada tinyint,
@TipoAnterior tinyint,
@Prioridad tinyint,
@Skill tinyint,
@Supervisor_id smallint = 0
AS
if not (@EC_id = @EC_anterior)
begin
if @TipoLlamada=1 and @TipoAnterior=1-- INBOUND
begin
	if @User_id = 0 and @EC_id > 0 -- Cuando se arrastra una campaña a una especialidad
	begin
		Delete ccInboundAgentes
		where inbound_id=@EC_id and User_id in (select DISTINCT u.User_id
		from ccUsers u, ccCampsAgente c, ccInbound i
		where (c.cam_id = @EC_anterior) and ( tipollamadas = 1 or tipollamadas = 3) and tipoUser_id = 1 and u.status > 0 AND u.User_id = c.user_id)

		Insert ccInboundAgentes (User_id, Inbound_id, cli_id, prioridad, skill)
		select DISTINCT u.User_id, @EC_id as Inbound_id, i.cli_id, @Prioridad as Prioridad, @Skill as Skill
		from ccUsers u, ccCampsAgente c, ccInbound i
		where (c.cam_id = @EC_anterior) and ( tipollamadas = 1 or tipollamadas = 3) and tipoUser_id = 1 and u.status > 0 AND u.User_id = c.user_id
		
		insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
		SELECT distinct u.user_id, c.idCampEsp, 0 cli_id, case c.priority when 0 then 1 else c.priority end priority, 1 skill, c.IDWG
		FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
		 join ccusers s on u.user_id = s.user_id
		WHERE c.tipo=0 and s.tipouser_id = 1 and cast(u.user_id as varchar(10)) + '&' + cast(c.idCampEsp as varchar(10)) not in
		(select cast(user_id as varchar(10)) + '&' + cast(Inbound_id as varchar(10)) from ccInboundAgentes)
	end
	else
	begin
		Delete ccInboundAgentes
		where user_id = @User_id and inbound_id=@EC_id 

		Insert ccInboundAgentes (User_id, Inbound_id, cli_id, prioridad, skill)
		select user_id, inbound_id, cli_id, @Prioridad as Prioridad, @Skill as Skill
		from ccUsers, ccInbound
		where user_id = @user_id and inbound_id = @ec_id and ( tipollamadas = 1 or tipollamadas = 3) and tipoUser_id = 1 and ccUsers.status > 0

		insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
		SELECT distinct u.user_id, c.idCampEsp, 0 cli_id, case c.priority when 0 then 1 else c.priority end priority, 1 skill, c.IDWG
		FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
		 join ccusers s on u.user_id = s.user_id
		WHERE c.tipo=0 and s.tipouser_id = 1 and cast(u.user_id as varchar(10)) + '&' + cast(c.idCampEsp as varchar(10)) not in
		(select cast(user_id as varchar(10)) + '&' + cast(Inbound_id as varchar(10)) from ccInboundAgentes)
	end
end
if @TipoLlamada=2 and @TipoAnterior=0
begin
	if @User_id = 0 and @EC_id > 0 -- Cuando se arrastra una especialidad a una campaña
	begin
		Delete ccCampsAgente
		where cam_id=@EC_id and user_id in (select u.User_id
		from ccUsers u, ccInboundAgentes c
		where (Inbound_id = @EC_anterior) and ( tipollamadas = 2 or tipollamadas = 3) and tipoUser_id = 1 and u.status > 0 AND u.User_id = c.User_id)
		
		Insert ccCampsAgente (User_id, cam_id, prioridad, skill)
		select distinct u.User_id, @EC_id as cam_id, @Prioridad as Prioridad, @Skill as Skill
		from ccUsers u, ccInboundAgentes c
		where (Inbound_id = @EC_anterior) and ( tipollamadas = 2 or tipollamadas = 3) and tipoUser_id = 1 and u.status > 0 AND u.User_id = c.User_id
		
		insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
		SELECT distinct u.user_id, c.idCampEsp, case c.priority when 0 then 1 else c.priority end priority, 1 skill, c.IDWG
		FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
		join ccusers s on u.user_id = s.user_id
		WHERE c.tipo=1 and s.tipouser_id = 1 and cast(u.user_id as varchar(10)) + '&' + cast(c.idCampEsp as varchar(10))
		not in (select cast(user_id as varchar(10)) + '&' + cast(Cam_id as varchar(10)) from CCCAMPSAGENTE)
	end
	else
	begin
	
	Delete ccCampsAgente where user_id = @User_id and cam_id=@EC_id
	Insert ccCampsAgente (User_id, cam_id, prioridad, skill)
	select user_id, cam_id, @Prioridad as Prioridad, @Skill as Skill
	from ccUsers, ccCamps
	where user_id = @user_id and cam_id = @ec_id and (tipollamadas = 2 or tipollamadas = 3) and tipoUser_id = 1 and ccUsers.status > 0

	insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
	SELECT distinct u.user_id, c.idCampEsp, case c.priority when 0 then 1 else c.priority end priority, 1 skill, c.IDWG
	FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
	join ccusers s on u.user_id = s.user_id
	WHERE c.tipo=1 and s.tipouser_id = 1 and cast(u.user_id as varchar(10)) + '&' + cast(c.idCampEsp as varchar(10))
	not in (select cast(user_id as varchar(10)) + '&' + cast(Cam_id as varchar(10)) from CCCAMPSAGENTE)
 
	end	
end

if @TipoLlamada=1 and @TipoAnterior=0 -- Cuando se arrastra una especialidad a otra especialidad
begin
	if @User_id = 0 and @EC_id > 0 
	begin
		Delete ccInboundAgentes
		where inbound_id=@EC_id and User_id in (select u.User_id
		from ccUsers u, ccInboundAgentes c
		where (Inbound_id = @EC_anterior) and tipoUser_id = 1 and u.status > 0 AND u.User_id = c.User_id)

		Insert ccInboundAgentes (User_id, Inbound_id, cli_id, prioridad, skill)
		select DISTINCT u.User_id, @EC_id as Inbound_id, i.cli_id, @Prioridad as Prioridad, @Skill as Skill
		from ccUsers u, ccInboundAgentes c, ccInbound i
		where (c.Inbound_id = @EC_anterior) and tipoUser_id = 1 and u.status > 0 AND u.User_id = c.user_id
		
		insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
		SELECT distinct u.user_id, c.idCampEsp, 0 cli_id, case c.priority when 0 then 1 else c.priority end priority, 1 skill, c.IDWG
		FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
		 join ccusers s on u.user_id = s.user_id
		WHERE c.tipo=0 and s.tipouser_id = 1 and cast(u.user_id as varchar(10)) + '&' + cast(c.idCampEsp as varchar(10)) not in
		(select cast(user_id as varchar(10)) + '&' + cast(Inbound_id as varchar(10)) from ccInboundAgentes)
	end
	else
	begin
		Delete ccInboundAgentes
		where user_id = @User_id and inbound_id=@EC_id 

		Insert ccInboundAgentes (User_id, Inbound_id, cli_id, prioridad, skill)
		select user_id, inbound_id, cli_id, @Prioridad as Prioridad, @Skill as Skill
		from ccUsers, ccInbound
		where user_id = @user_id and inbound_id = @ec_id and ( tipollamadas = 1 or tipollamadas = 3) and tipoUser_id = 1 and ccUsers.status > 0
		
		insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
		SELECT distinct u.user_id, c.idCampEsp, 0 cli_id, case c.priority when 0 then 1 else c.priority end priority, 1 skill, c.IDWG
		FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
		join ccusers s on u.user_id = s.user_id
		WHERE c.tipo=0 and s.tipouser_id = 1 and cast(u.user_id as varchar(10)) + '&' + cast(c.idCampEsp as varchar(10)) not in
		(select cast(user_id as varchar(10)) + '&' + cast(Inbound_id as varchar(10)) from ccInboundAgentes)
	end
end

if @TipoLlamada=2 and @TipoAnterior=1 
begin
	if @User_id = 0 and @EC_id > 0 -- Cuando se arrastra una campaña a otra campaña
	begin
		Delete ccCampsAgente
		where cam_id=@EC_id and user_id in (select u.User_id
		from ccUsers u, ccCampsAgente c
		where (cam_id = @EC_anterior) and tipoUser_id = 1 and u.status > 0 AND u.User_id = c.user_id)
		
		Insert ccCampsAgente (User_id, cam_id, prioridad, skill)
		select u.User_id, @EC_id as cam_id, @Prioridad as Prioridad, @Skill as Skill
		from ccUsers u, ccCampsAgente ca
		where ca.cam_id = @EC_anterior and tipoUser_id = 1 and u.status > 0 AND u.User_id = ca.user_id
		
		insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
		SELECT distinct u.user_id, c.idCampEsp, case c.priority when 0 then 1 else c.priority end priority, 1 skill, c.IDWG
		FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
		join ccusers s on u.user_id = s.user_id
		WHERE c.tipo=1 and s.tipouser_id = 1 and cast(u.user_id as varchar(10)) + '&' + cast(c.idCampEsp as varchar(10))
		not in (select cast(user_id as varchar(10)) + '&' + cast(Cam_id as varchar(10)) from CCCAMPSAGENTE)
	end
	else
	begin
	
		Delete ccCampsAgente
		where user_id = @User_id and cam_id=@EC_id
		Insert ccCampsAgente (User_id, cam_id, prioridad, skill)
		select user_id, cam_id, @Prioridad as Prioridad, @Skill as Skill
		from ccUsers, ccCamps
		where user_id = @user_id and cam_id = @ec_id and (tipollamadas = 2 or tipollamadas = 3) and tipoUser_id = 1 and ccUsers.status > 0
		
		insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
		SELECT distinct u.user_id, c.idCampEsp, case c.priority when 0 then 1 else c.priority end priority, 1 skill, c.IDWG
		FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
		join ccusers s on u.user_id = s.user_id
		WHERE c.tipo=1 and s.tipouser_id = 1 and cast(u.user_id as varchar(10)) + '&' + cast(c.idCampEsp as varchar(10))
		not in (select cast(user_id as varchar(10)) + '&' + cast(Cam_id as varchar(10)) from CCCAMPSAGENTE)
	
	end	
 end
end