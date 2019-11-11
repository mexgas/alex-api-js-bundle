CREATE PROCEDURE [dbo].[ccsp_isFinished]
@tabla int,
@id int,
@result int output
AS
begin
	declare @time int
	if @tabla=0 begin
		set @time=(select cal_tDialog from ccoCallsOut where cal_id=@id)
	end
	else begin
		set @time=(select cal_tDialog from ccCallsIn where cal_id=@id)
	end

	if @time>0 begin
		set @result=0
	end
	else begin
		set @result=1
	end
end