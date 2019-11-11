CREATE PROCEDURE dbo.ccsp_AgentGetCalifAttributes
@calif_id int,
@Type tinyint=1,
@isSub tinyint=2
AS
SET NOCOUNT ON
set @Type = @Type+@isSub-2 -- 1-in|2-out|3-subin|4-subout

if @Type=1
begin
	select CanReprogram from cctipocalif where calif_id=@calif_id group by CanReprogram	
	return(0)
end

if @Type=2
begin
	select CanReprogram from cctipocalifOut where calif_id=@calif_id group by CanReprogram, autoTime
	return(0)
end

if @Type=3
begin
	select CanReprogram from cctipocalifSub where califSub_id=@calif_id group by CanReprogram
	return(0)
end

if @Type=4
begin
	select CanReprogram from cctipocalifSubOut where califSub_id=@calif_id group by CanReprogram
	return(0)
end