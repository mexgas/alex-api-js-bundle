CREATE PROCEDURE [dbo].[ccspRepOutCallsByTelephone]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		delete RepOutCallsByTelephone with(rowlock)
		where date >= @from and date < @to

		insert into RepOutCallsByTelephone
		select timegroup as [date], cal_telefono as [telephone], cal_key as [callKey], cam_id as [campaignId], cam_descripcion as [campaign], 
		count(cal_telefono) as quantity
		, datepart(yyyy,timegroup) as [year]
		, datepart(mm,timegroup) as [month]
		, datepart(dd,timegroup) as [day]
		, datepart(hh,timegroup) as [hour]
		, datepart(mi,timegroup) as [minutes]
		from(select cal_telefono, convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) as timegroup, cal_key, a.cam_id, b.cam_descripcion
			 from ccocallsout a
			 left join cccamps b on (a.cam_id = b.cam_id) 
			 where cal_inicio >= @from 
			 and cal_inicio < @to) c
		group by cal_telefono, timegroup, cal_key, cam_id, cam_descripcion
		order by cal_telefono, count(cal_telefono)
	end