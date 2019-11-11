CREATE procedure ccsp_AgentNotReadyTimer
@user_id smallint,
@tipoNotReady_id tinyint
AS
set nocount on
declare @time_acum int, @time_xEv int, @timeLeft int, @nextStatus smallint, @tStatusDia int

select @time_acum = time_Acum, @time_xEv = time_xEv, @nextStatus = NextStatus
from ccTipoNotReady with(index(PK_ccTipoNotReady)) where tipoNotReady_id = @tiponotready_id

-- Todo el tiempo que el agente necesite
select @timeLeft = -1 
select @tStatusDia = 0
if @time_acum > 0 and @time_acum < 86400 
 begin
	select @tStatusDia = isnull(sum(tstatus), 0)
	from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady))
	where fecha > convert(varchar(11), getdate(), 121) and user_id = @user_id and tiponotready_id = @tipoNotReady_id

	select @timeLeft = @time_xEv - @tStatusDia

	if @time_acum - @tStatusDia < @timeLeft 
	 begin
		select @timeLeft = @time_acum - @tStatusDia
	 end
 end

select @timeLeft as TimeLeft, @nextStatus as NextStatus -- Si timeleft = -1 no tiene límite
set nocount off