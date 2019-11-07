create function dbo.fnGetTimeDifference
(	
	@IdTimeZone int
)
RETURNS int
AS
BEGIN			
	if @IdTimeZone = 0
		return 0
	declare @difHoursPhone as int
	declare @difHoursServer as int
	declare @total as int		
			
	select @difHoursServer = datediff(hh,getutcdate(),getdate())					
	select @difHoursPhone = tz_offset from ccTimeZones where tz_id = @IdTimeZone						
	select @total =  @difHoursServer - @difHoursPhone 									

	return @total
END