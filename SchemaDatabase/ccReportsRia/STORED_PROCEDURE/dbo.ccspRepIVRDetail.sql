CREATE PROCEDURE [dbo].[ccspRepIVRDetail]
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

	create table #IVRLlamadas(
	IVR_id int not null,
	cal_ani varchar(30) null,
	User_id smallint not null,
	calif_id smallint not null,
	cal_id int not null,
	date datetime not null,
	dnis varchar(50) not null,
	callStatus varchar(50) not null,
	tincall int not null
	)

	insert into #IVRLlamadas
	select A.Ivr_id, A.cal_ani, isnull(B.user_id,0) as [user_id], isnull(B.calif_id,0) as [calif_id],
	isnull(B.cal_id,0) as [cal_id], 
	ISNULL(B.cal_inicio, A.[date]) as date,
	ISNULL(A.dnis,'') as dnis,
	case when ISNULL(B.cal_id,0) > 0 then 'systemTranslated_TransferredToACD' else 'systemTranslated_AbandonedInIVR' end as callStatus,
	ISNULL(A.tincall, 0) as tincall
	from IVRCallsIn as A with (nolock)
	left join ccCallsIn As B with(nolock) on  A.IVR_id = B.IVR_id
	where date >= @from and date < @to

	delete from RepIVRDetail with(rowlock) where date >= @from AND date < @to
		
	insert into RepIVRDetail
	select #IVRLlamadas.date as fecha, 
	cal_ani as telefono
	, isNull(u.nombres + ' ' + u.apellidopaterno + ' ' + u.apellidomaterno,'') as nombre
	, isnull(calif.description, #IVRLlamadas.calif_id) as calificacion, cal_id as cal_id
	, isnull(
	(
		select
		case when selectedOption = '' then ''	else selectedOption + ','	end
			from IVROptions with(nolock)
		where IVROptions.ivr_id = #IVRLlamadas.ivr_id
		order by IVROptions.date for xml path('')
	),'') as opciones	
	,#IVRLlamadas.tincall as tiempo,
	datepart(yyyy,[date]),
	datepart(mm,[date]),
	datepart(dd,[date]),
	datepart(hh,[date]),
	datepart(mi,[date]),
	dnis as DNIS,
	case when name is NULL then 'systemTranslated_NoName' when name = '' then 'systemTranslated_NoName' else name end
	, callStatus
	from #IVRLlamadas
	left join
	(
		select ivr_id,name
		from IVROptions with(nolock)
		where date >= @from and date < @to
		group by ivr_id,name
	) optName on #IVRLlamadas.ivr_id = optName.ivr_id
	left join ccUserView u with(nolock) on (u.user_id = #IVRLlamadas.user_id)
	left join cctipocalif calif with(nolock) on (calif.calif_id = #IVRLlamadas.calif_id)
	where #IVRLlamadas.date >= @from and #IVRLlamadas.date < @to
	order by date
	
	drop table #IVRLlamadas

end