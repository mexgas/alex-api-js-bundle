ALTER PROCEDURE [dbo].[ccspRepOutAnswCalls]
@action as tinyint,
@from AS datetime = null,
@to AS datetime = null
AS

SET NOCOUNT ON

if @action = 1
begin
	if @from is null
		select @from = convert(datetime,convert(varchar(11),getdate()))
	if @to is null	
		select @to = getdate()
							
	delete RepOutAnswCalls with(rowlock)
	where [date] between @from and @to
						
	insert RepOutAnswCalls select [date], campaignId, ca.cam_descripcion campaign, 
	abnd.IDWG workgroupId, e.WGName workgroup, isnull(f.IDArea,0) areaId, g.AreaName area, total,
	cast(((nasig_tl*100.0)/total) as decimal(5,2)) asig_tl,
	cast(((nasig_nc*100.0)/total) as decimal(5,2)) asig_nc,
	cast(((nAnswered*100.0)/total) as decimal(5,2)) Answered,
	cast(((nassigned*100.0)/total) as decimal(5,2)) assigned,
	cast(((nabdn_sis*100.0)/total) as decimal(5,2)) abdn_sis
	from (
		select convert(varchar(10),cal_inicio,121) [date], co.cam_id campaignId, isnull(min(d.IDWG),1) idwg, count(*) total, 
		COUNT(CASE WHEN(statusCall_id = 16)THEN co.cal_id ELSE NULL END) nasig_tl,
		COUNT(CASE WHEN(statuscall_id = 15)THEN co.cal_id ELSE NULL END) nasig_nc,
		COUNT(CASE WHEN(statuscall_id = 13)THEN co.cal_id ELSE NULL END) nAnswered,
		COUNT(CASE WHEN(statuscall_id = 11)THEN co.cal_id ELSE NULL END) nassigned,
		COUNT(CASE WHEN(statuscall_id in (6,4))THEN co.cal_id ELSE NULL END) nabdn_sis
		from ccocallsout co with(nolock) 
		left join ccRIAWorkGroup_Calid d on (d.cal_id = co.cal_id)
		where cal_inicio between @from and @to group by convert(varchar(10),cal_inicio,121),co.cam_id
	) abnd left join cccamps ca on ca.cam_id=abnd.campaignId 
	left join ccRIACat_WorkGroup as e on (e.idwg = abnd.idwg)
	left join ccRIAAreaWorkGroup as f on (f.idwg = e.idwg)
	left join ccRIACat_Areas as g on (g.idarea = f.idarea)
end