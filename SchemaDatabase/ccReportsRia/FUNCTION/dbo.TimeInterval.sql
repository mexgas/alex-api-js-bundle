create FUNCTION [dbo].TimeInterval (@start datetime,@stop datetime,@state1 datetime,@state2 datetime)  
RETURNS int
AS  
BEGIN 
	declare @time int
	
	set @time= 
	case when @start <= @state1 and  @stop > @state1 and @start<= @state2 and  @stop > @state2 then datediff(ss,@state1,@state2)
	 when @start<= @state1 and  @stop > @state1 and @stop < @state2 then datediff(ss,@state1,@stop)
	 when @start> @state1 and @start<= @state2 and  @stop > @state2 then datediff(ss,@start,@state2)
	 when @start> @state1 and @stop < @state2 then datediff(ss,@start,@stop) else  0 end

	RETURN (@time)
END