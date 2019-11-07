CREATE procedure [dbo].[ccsp_RIAADMgetAbandonoSalida]
@User_id smallint = null,
@cam_id smallint = null
AS 
set nocount on
declare @fecha datetime, @ultimo datetime
declare @lastAband float

select @ultimo = valor from ccSettings where setting_id = 25
if datediff(ss, @ultimo, getdate()) > 300 
begin
	set @fecha = getdate()
	update ccsettings set valor = convert(varchar(19), @fecha, 121) where setting_id = 25

	-- calcula abandono para la grafica
	exec ccsp_RIAADMgetAbandonoSalida_Fix	
end

if @User_id is not null
begin
	select distinct h.cam_id, isnull(h.AbndPctg,0)
	from ccAbandonoSalida h inner join ccSupervisorCam i on h.cam_id = i.cam_id
	where i.user_id = @User_id

	return(0)
end

if @cam_id is not null
begin
	select top 1 @lastAband = AbndPctg from ccAbandonoSalida_Chart
	where cam_id = @cam_id order by timestamp desc

	select @cam_id as cam_id, x.cam_descripcion, isNull(@lastAband,0) as LastAbndPctg, x.ts as timestamp, x.AbndPctg from 
	(
		select top 20 C.cam_descripcion,
		convert(varchar(4), A.Timestamp, 108)+'0' as ts, isnull(A.AbndPctg,0) as AbndPctg
		from ccAbandonoSalida_Chart A 
		join ccCamps C on A.cam_id = C.cam_id
		Where A.cam_id=@cam_id
		order by timestamp desc
	)x order by x.ts

	return(0)
end

set nocount off