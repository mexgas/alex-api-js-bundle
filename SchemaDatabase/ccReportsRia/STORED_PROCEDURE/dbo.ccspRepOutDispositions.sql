CREATE PROCEDURE [dbo].[ccspRepOutDispositions]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

create table #detailWorkGroup(
	IDWG int not null,
	idCampaing int not null,
	WGName varchar(45)
)

if @action = 1
begin

	insert into #detailWorkGroup
	select A.IDWG,B.IdCampEsp,A.WGName from ccriacat_workgroup A 
	inner join ccRIACampEspWG B on A.IDWG=B.IDWG 
	where Tipo=1 
	 
	--Borrar lo que esta para no repetir
	delete from RepOutDispositions with(rowlock)
	where date >= @from AND date < @to

	insert into  RepOutDispositions
	select CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ ':00',121) as dateHour, a.cam_id, '' as Campaign, a.calif_id, '' as DispName, '', count(calif_id) DispAmount, user_id, '' as login
	, '' as username, b.IDArea, '' as areaName, 1 as wgId, 'systemTranslated_WorkGroup' as wg,
	datepart(yyyy,max(cal_inicio)) as year, datepart(mm,max(cal_inicio)), datepart(dd,max(cal_inicio)),
	datepart(hh,max(cal_inicio)), datepart(mi,max(cal_inicio))
	from ccocallsout a 		
	left join cccamps b
	on	b.cam_id = a.cam_id		
	where cal_inicio >= @from AND cal_inicio < @to and a.statuscall_id = 13 and cal_manual in (0,2)
	and b.idArea is not null
	group by CONVERT(smalldatetime,CONVERT(varchar(13),a.cal_inicio,121)+ ':00',121),a.cam_id, a.calif_id, user_id,b.IDArea

	update a set campaign = isnull(cam_descripcion,'')
	from RepOutDispositions a
	left join cccamps b 
	on a.campaignId = b.cam_id
	where [date] >= @from AND [date] < @to

	update a set disposition = isnull(description,'systemTranslated_Dispositionless'), disposition_count = isnull(description,'systemTranslated_Dispositionless') + '_Count'
	from RepOutDispositions a
	left join cctipocalifout b 
	on a.dispositionId = b.calif_id
	where [date] >= @from AND [date] < @to

	update a set username = isnull(login,'')
	from RepOutDispositions a
	left join ccUserView b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set agentName = isnull(Nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMaterno,'')
	from RepOutDispositions a
	left join ccUserView b 
	on a.userId = b.user_id
	where [date] >= @from AND [date] < @to

	update a set area = isnull(AreaName,'')
	from RepOutDispositions a
	left join ccRIACat_Areas b 
	on a.areaId = b.IDArea
	where [date] >= @from AND [date] < @to

	update a set a.workgroupId = isnull(b.IDWG,0), a.wg = isnull(b.WGName, '-')
	from RepOutDispositions a
	left join #detailWorkGroup b
	on a.campaignId = b.idCampaing
	
	drop table #detailWorkGroup

end