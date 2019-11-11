CREATE PROCEDURE ccsp_ResetJobs AS
	Update ccoWorkingTable SET cal_status=1
	where cal_status=2