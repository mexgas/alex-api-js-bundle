CREATE PROCEDURE [dbo].[ccspRepOutDispositionsContacOwner]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin

	--Borrar lo que esta para no repetir
	delete from RepOutDispositionsContacOwner with(rowlock)	where date >= @from AND date < @to

	insert into RepOutDispositionsContacOwner
	select [date],cam_id,Campaign, total,sumContactOwner as totalContactOwner,
	dbo.fPercentage(sumContactOwner,Total) as percentageContactOwner,
	datepart(yyyy,[date]) as [year], datepart(mm,[date]) [mounth],  datepart(dd,[date]) [day],
	datepart(hh,[date]) [hour], datepart(mi,[date]) [minute]
	 from (
	select CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ ':00',121) as [date],a.cam_id,b.cam_descripcion as Campaign,
	count(*) total,
	sum(
		case when isnull(calOut.contactOwner,0) = 1 then 1
		when isnull(calSubOut.contactOwner,0) = 1  then 1 else 0 end
	 ) as sumContactOwner
	from ccocallsout a
	left join cccamps b on	b.cam_id = a.cam_id
	left join cctipocalifout calOut on calOut.calif_id=a.calif_id
	left join ccTipoCalifSubOUT calSubOut on calSubOut.califSub_id=a.califSub_id
	where a.cal_Inicio>=@from and a.cal_Inicio<@to
	group by CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ ':00',121),a.cam_id,b.cam_descripcion
	)X
end