CREATE PROCEDURE [dbo].[ccspRepIVRByOptions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

if @action = 1
	begin
		delete from RepIVRByOptions with(rowlock)
		where date >= @from AND date < @to
		
		insert into RepIVRByOptions
		select date, [level] as [levelOption], min([Description]) as [descriptionOption], count(*) as [quantityOption]
		, datepart(yyyy,date)
		, datepart(mm,date)
		, datepart(dd,date)
		, datepart(hh,date)
		, datepart(mi,date)
		from ivrstructure,
		( 
			select ivrLLamadas.date, ivr_id, isnull
			((
				select selectedOption + ',' 
				from IVROptions	
				where IVROptions.ivr_id = ivrLLamadas.ivr_id 
				order by IVROptions.date 
				for xml path('')
			),'#') as opciones 
			from (
				select A.Ivr_id, A.cal_ani, isnull(B.cal_id,0) as calId , convert(datetime,convert(varchar(11),A.date)) as [date]
				from IVRCallsIn as a 
				left join ccCallsIn as b on  A.IVR_id = B.IVR_id 
				where date >= @from and date < @to
			)ivrLLamadas
			where ivrLLamadas.date >= @from and ivrLLamadas.date < @to
		)x 
		where opciones like [level]+'%'
		group by date, [level]
		order by date, [level]

	end