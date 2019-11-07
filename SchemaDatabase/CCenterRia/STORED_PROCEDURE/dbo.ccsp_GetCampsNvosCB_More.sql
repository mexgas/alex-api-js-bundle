CREATE PROCEDURE ccsp_GetCampsNvosCB_More 
@cam_id integer = 0,
@tipo integer = 0
AS
if @tipo = 0 begin
	if @cam_id = 0 begin
		--ASP  Version 2005/01/11
		select Camps.cam_id as ID, cam_descripcion as 'Campaña',
			IsNull(Jobs.New, 0) as New, IsNull(Jobs.CB, 0) as CB,
			IsNull(Jobs.cbAg, 0) as CAg, IsNull(Jobs.Pro, 0) as Pr,
			IsNull(Pends.pend, 0) as Pen,	
			case cam_procesando 
				when 1 then 'Pro'
				when 0 then ''
			end as St,
			case cam_TipoJobs
				when 2 then 'New'
				when 1 then 'CB'
				when 0 then 'Amb'
			end as Job
		from
		ccCamps Camps Left Join 
		(select cam_id, 
			count(case when cal_status=0 then 1 else null end) as New,
			count(case when cal_status=1 then 1 else null end) as CB,
			count(case when (cal_status=1 and user_id>0) then 1 else null end) as cbAg,
			count(case when cal_status=2 then 1 else null end) as Pro		
		from ccoWorkingTable
		group by cam_id
		) Jobs
		on Camps.cam_id = Jobs.cam_id
		Left Join
		(select cam_id, count(*) as Pend
				from ccocallsoutsource where cal_status = 0
				group by cam_id) Pends
		On Camps.cam_id = Pends.cam_id
		Order by cam_procesando desc, cam_descripcion
	end
end

if @tipo = 1 begin
	if @cam_id = 0 begin
		--ASP  Version 2005/01/11
		select Camps.cam_id as ID, cam_descripcion as 'Campaña',
			IsNull(Jobs.New, 0) as New, IsNull(Jobs.CB, 0) as CB, IsNull(Jobs.cbAg, 0) as CAg, IsNull(Jobs.Pro, 0) as Pr,
			case cam_procesando 
				when 1 then 'Pro'
				when 0 then ''
			end as St
		from
		ccCamps Camps Left Join 
		(select cam_id, 
			count(case when cal_status=0 then 1 else null end) as New,
			count(case when cal_status=1 then 1 else null end) as CB,
			count(case when (cal_status=1 and user_id>0) then 1 else null end) as cbAg,
			count(case when cal_status=2 then 1 else null end) as Pro		
		from ccoWorkingTable
		group by cam_id
		) Jobs
		on Camps.cam_id = Jobs.cam_id
	end

	if @cam_id > 0 begin
		select Camps.cam_id as ID, cam_descripcion as 'Campaña',
			IsNull(Jobs.New, 0) as New, IsNull(Jobs.CB, 0) as CB,
			IsNull(Jobs.cbAg, 0) as CAg, IsNull(Jobs.Pro, 0) as Pr,
			IsNull(Pends.pend, 0) as Pen	,	
			case cam_procesando 
				when 1 then 'Pro'
				when 0 then ''
			end as St,
			case cam_TipoJobs
				when 2 then 'New'
				when 1 then 'CB'
				when 0 then 'Amb'
			end as Job
		from
		ccCamps Camps Left Join 
		(select cam_id, 
			count(case when cal_status=0 then 1 else null end) as New,
			count(case when cal_status=1 then 1 else null end) as CB,
			count(case when (cal_status=1 and user_id>0) then 1 else null end) as cbAg,
			count(case when cal_status=2 then 1 else null end) as Pro		
		from ccoWorkingTable
		group by cam_id
		) Jobs
		on Camps.cam_id = Jobs.cam_id
		Left Join
		(select cam_id, count(*) as Pend
				from ccocallsoutsource where cal_status = 0
				group by cam_id) Pends
		On Camps.cam_id = Pends.cam_id
		Where Camps.cam_id=@cam_id
		Order by cam_procesando desc, cam_descripcion
	end
end