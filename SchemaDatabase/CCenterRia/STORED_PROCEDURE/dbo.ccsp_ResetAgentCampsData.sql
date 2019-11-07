CREATE PROCEDURE ccsp_ResetAgentCampsData
@Object tinyint,		-- 1=Agentes, 2=Espec, 3=Camps
@TipoReset tinyint	-- 1=Today, 2= NotToday
AS
IF ( @Object= 1 ) -- Agentes
BEGIN
	IF ( @TipoReset= 1 )
	BEGIN
		Delete ccDataAgents Where datepart(dy,fecha) = datepart(dy, getdate())
	END 
	ELSE
	BEGIN
		Delete ccDataAgents Where datepart(dy,fecha) <> datepart(dy, getdate())
	END
END
IF ( @Object= 2 ) -- Especialidades
BEGIN
	IF ( @TipoReset= 1 )
	BEGIN
		Delete ccDataCamps Where tipocall=1 and datepart(dy,fecha) = datepart(dy, getdate())
	END 
	ELSE
	BEGIN
		Delete ccDataCamps  Where  tipocall=1 and datepart(dy,fecha) <> datepart(dy, getdate())
	END
END
IF ( @Object= 3 ) -- Campaas
BEGIN
	IF ( @TipoReset= 1 )
	BEGIN
		Delete ccDataCamps Where tipocall=2 and datepart(dy,fecha) = datepart(dy, getdate())
	END 
	ELSE
	BEGIN
		Delete ccDataCamps  Where  tipocall=2 and datepart(dy,fecha) <> datepart(dy, getdate())
	END
END