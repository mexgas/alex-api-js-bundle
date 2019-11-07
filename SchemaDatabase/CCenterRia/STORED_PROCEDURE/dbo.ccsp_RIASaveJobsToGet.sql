CREATE PROCEDURE [dbo].[ccsp_RIASaveJobsToGet]
@cam_id int,
@JobType tinyint

AS
	UPDATE ccCAMPS SET cam_TipoJobs=@JobType, cam_SortColumns= 0
	WHERE cam_id = @cam_id