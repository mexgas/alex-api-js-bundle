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
	SELECT IDWG, IdCampEsp, WGName from ccRIACampEspWGView where Tipo = 1
	 
	--Borrar lo que esta para no repetir
	delete from RepOutDispositions with(rowlock) 	where date >= @from AND date < @to

	--CTE
	;with callOut as(
	select CONVERT(smalldatetime, CONVERT(varchar(13), a.cal_inicio,121) + ':00', 121) as date, 
		a.cam_id, a.calif_id, count(calif_id) DispAmount, user_id	
		from ccocallsout a 			
		where cal_inicio >= @from AND cal_inicio < @to and 
		a.statuscall_id = 13 and cal_manual in (0,2)	
		group by CONVERT(smalldatetime, CONVERT(varchar(13), a.cal_inicio,121) + ':00', 121), a.cam_id, a.calif_id, user_id
		)

insert into  RepOutDispositions
	select A.date,a.cam_id, ISNULL(b.cam_descripcion,'') as Campaign,
	a.calif_id, isnull(c.Description,'systemTranslated_Dispositionless') as DispName, 
	isnull(c.Description,'systemTranslated_Dispositionless')+'_Count' as disposition_count,
    a.DispAmount as [count], A.user_id, ISNULL(d.login,'') [login],
    isnull(Nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMaterno,'') as username, 
	isnull(b.IDArea,0) as IDArea, isnull(e.AreaName,'') as areaName, 1 as wgId, 'systemTranslated_WorkGroup' as wg,
	datepart(yyyy,date) as year, datepart(mm,date) as mounth, datepart(dd,date) as day,
	datepart(hh,date) as hour, datepart(mi,date) as min
	from callOut A
	left join cccamps b on a.cam_id = b.cam_id
	left join cctipocalifout c on A.calif_id = c.calif_id
	left join ccUserView d on a.User_id = d.User_id
	left join ccRIACat_Areas e on b.IDArea = e.IDArea

	update A set A.areaId = B.IDArea, A.area = C.AreaName
    from RepOutDispositions A
    inner join ccRIAAreaWorkGroup B on A.workgroupId = B.IDWG
    inner join ccRIACat_Areas C on C.IDArea = B.IDArea
    where [date] >= @from AND [date] < @to and areaId=0 
    
    update a set a.workgroupId = isnull(b.IDWG,0), a.wg = isnull(b.WGName, '-')
	from RepOutDispositions a
	left join #detailWorkGroup b	
    on a.campaignId = b.idCampaing
	where [date] >= @from AND [date] < @to

	drop table #detailWorkGroup

end