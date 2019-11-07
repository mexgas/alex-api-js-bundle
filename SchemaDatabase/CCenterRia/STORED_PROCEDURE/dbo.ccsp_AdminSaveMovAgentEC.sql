CREATE  PROCEDURE ccsp_AdminSaveMovAgentEC
@User_id smallint,
@EC_id smallint,
@TipoLlamada tinyint,
@Prioridad tinyint,
@Skill tinyint,
@Super_id smallint =0
AS
--ccsp_AdminSaveMovAgentEC 0, 12, 0, 1, 1
--@User_id smallint, 0
--@EC_id smallint, 12
--@TipoLlamada tinyint, 0 
--@Prioridad tinyint,1
--@Skill tinyint1
declare @tipoLlamadasUsr integer
select @tipoLlamadasUsr = tipollamadas from ccusers where user_id = @user_id

if @TipoLlamada=1 -- INBOUND
begin
	-- HLAS 20050425, si la especialidad o el agente es cero se asigna el agente a todas las especialidades o todos los agentes a la esp.
	
	Delete ccInboundAgentes
	where (user_id = @User_id or @User_id = 0) and (inbound_id=@EC_id or @EC_id = 0) 

	Insert ccInboundAgentes (User_id, Inbound_id, cli_id, prioridad, skill)
	select user_id, inbound_id, cli_id, @Prioridad as Prioridad, @Skill as Skill
	from ccUsers, ccInbound
	where (user_id = @user_id or @user_id = 0) and (inbound_id = @ec_id or @ec_id = 0) and ( tipollamadas = 1 or tipollamadas = 3) and tipoUser_id = 1 and ccUsers.status > 0

	if @tipoLlamadasUsr = 1 or @tipoLlamadasUsr = 3
		exec ccsp_ADMlogAgentsMovs @Super_id, @User_id, @EC_id, @TipoLlamada, 1
end
if @TipoLlamada=2 -- OUTBOUND
begin
	Delete ccCampsAgente
	where user_id = @User_id and (cam_id=@EC_id or @EC_id = 0)
	Insert ccCampsAgente (User_id, cam_id, prioridad, skill)
	select user_id, cam_id, @Prioridad as Prioridad, @Skill as Skill
	from ccUsers, ccCamps
	where (user_id = @user_id or @user_id = 0) and (cam_id = @ec_id or @ec_id = 0) and (tipollamadas = 2 or tipollamadas = 3) and tipoUser_id = 1 and ccUsers.status > 0

	if @tipoLlamadasUsr = 2 or @tipoLlamadasUsr = 3
		exec ccsp_ADMlogAgentsMovs @Super_id, @User_id, @EC_id, @TipoLlamada, 1
end