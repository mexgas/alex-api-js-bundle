CREATE PROCEDURE [dbo].[ccsp_recordingStatus]
@callType int,
@id int,
@action int ,
@recordLocalization int
AS
begin

SET NOCOUNT ON
	if @action=0 begin
		declare @time int
		if @callType=0 begin
			select @time=cal_tDialog from ccoCallsOut with(nolock) where cal_id=@id
		end
		else begin
			select @time=cal_tDialog from ccCallsIn with(nolock) where cal_id=@id
		end
		select case when @time>0 then 1 else 0 end as result
	end
	else if @action=1 begin
		if @callType=0 begin
			update ccoCallsOut with(rowlock) set file_moved=@recordLocalization where cal_id=@id
		end
		else begin
			update ccCallsIn with(rowlock) set file_moved=@recordLocalization where cal_id=@id
		end
	end
end