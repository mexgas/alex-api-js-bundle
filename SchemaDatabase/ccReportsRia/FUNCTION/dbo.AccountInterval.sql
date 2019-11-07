create FUNCTION [dbo].[AccountInterval] (@start datetime,@stop datetime,@state1 datetime,@state2 datetime,@ntotal int)  
RETURNS int
AS  
BEGIN 
	declare @total int
	
	set @total= 
	case when @start<= @state1 and  @stop > @state1 and @stop < @state2 then @ntotal 
	else 0 end

	RETURN (@total)
END