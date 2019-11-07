CREATE PROCEDURE [dbo].[ccspRepIVRGeneral]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		delete RepIVRGeneral with(rowlock)
		where date >= @from and date < @to

		insert into RepIVRGeneral
		select convert(varchar(10),date,121) as [date], 
		sum(case when calId = 0 then 1 else 0 end) as [noTransferred], 
		sum(case when calId > 0 then 1 else 0 end) as [transferred], 
		count(*) as [total]
		, datepart(yyyy,convert(varchar(10),date,121))
		, datepart(mm,convert(varchar(10),date,121))
		, datepart(dd,convert(varchar(10),date,121))
		, datepart(hh,convert(varchar(10),date,121))
		, datepart(mi,convert(varchar(10),date,121))
		from (select A.Ivr_id, A.cal_ani, isnull(B.cal_id,0) as calId ,A.date 
				from IVRCallsIn as a 
				left join ccCallsIn as b on  A.IVR_id = B.IVR_id 
				where date >= @from and date < @to) as c
		where date >= @from and date < @to
		group by convert(varchar(10),date,121)
		order by convert(varchar(10),date,121)
	end