CREATE PROCEDURE dbo.ccsp_OUTCheckCampJobs
@cam_id as int,
@Tipo as int=0
as
set nocount on
declare @JobsNew int, @JobsCBs int
	select 
		@JobsNew = count(case cal_status when 0 then 1 else null end), 
		@JobsCBs = count(case cal_status when 1 then 1 else null end)
	from ccoWorkingTable where cam_id = @cam_id

	SELECT cam_procesando, cam_TipoJobs, 'JobsNew' =@JobsNew, 'JobsCallBacks' =@JobsCBs
	FROM ccCamps WHERE cam_id = @cam_id
set nocount off