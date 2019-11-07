create function dbo.fn_Calcula_UsrPriority (
@User_ID smallint,
@Tipo bit)
returns int
as
begin
declare @max int
if @Tipo=0
	select @max=max(prioridad) from ccInboundAgentes where user_id = @User_ID

else
	select @max=max(prioridad) from ccCampsAgente where user_id = @User_ID

if @max is null or @max = 0
	set @max = 1

return(@max)
end