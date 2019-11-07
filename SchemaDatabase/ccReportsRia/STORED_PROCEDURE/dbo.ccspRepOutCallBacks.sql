CREATE PROCEDURE [dbo].[ccspRepOutCallBacks]
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
	delete RepOutCallBacks with(rowlock)
	where date >= @from and date < @to

	insert into RepOutCallBacks
	select cal_fecha as [date], b.user_id as [userId], b.login as [user], c.cam_id as [campaignId], c.cam_descripcion as [campaign],
	cal_key as [callKey], cal_telefono as [originalTel], cal_telCB as [scheduledTel], cal_fecha as [originalDate], 
	cal_fusercallback as [scheduledDate],
	case a.status when 0 then 'systemTranslated_Pending'
	when 1 then 'systemTranslated_Answer'
	when 2 then 'systemTranslated_NoAnswer'
	when 3 then 'systemTranslated_Recicled'
	when 4 then 'systemTranslated_Expired'
	when 5 then 'systemTranslated_OldRecord'
	when 6 then 'systemTranslated_LoadRecord' end as [status], 
	case when cal_fcallback is null then ''
		when convert(varchar(13),cal_fcallback) = 'jan 1 1900' then ''
		else convert(varchar(255),cal_fcallback) end as [dialDate]
	, datepart(yyyy,cal_fecha) as [year]
	, datepart(mm,cal_fecha) as [month]
	, datepart(dd,cal_fecha) as [day]
	, datepart(hh,cal_fecha) as [hour]
	, datepart(mi,cal_fecha) as [minutes]
	from ccocallbacks a, ccUserView b, cccamps c
	where cal_fecha between @from and @to
	and a.user_id = b.user_id
	and a.cam_id = c.cam_id
end