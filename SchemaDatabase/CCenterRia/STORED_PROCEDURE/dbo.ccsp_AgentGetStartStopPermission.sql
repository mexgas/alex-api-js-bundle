CREATE PROCEDURE [dbo].[ccsp_AgentGetStartStopPermission]
@age_id int,
@cam_id int,
@call_type int
AS
BEGIN
	SET NOCOUNT ON;

	declare @agentRec int, @valor as int
	set @valor = 0
	set @agentRec = (select isnull(startStopRecording,0) from ccusers (nolock) where [User_id] = @age_id)

	IF @agentRec = 1
	BEGIN
		---------- Entra agente con permiso de StartStopRecording
		IF @call_type = 1 ------- Revisamos especialidad
			set @valor = (select isnull(startStopRecording,0) from ccInbound (nolock) where Inbound_id = @cam_id)
		ELSE ------- Revisamos Campaña
			set @valor = (select isnull(startStopRecording,0) from ccCamps (nolock) where cam_id = @cam_id)
	END

	select @valor Allowed
END