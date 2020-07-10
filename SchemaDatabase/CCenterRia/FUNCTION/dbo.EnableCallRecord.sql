CREATE function [dbo].[EnableCallRecord](@call_record_cam tinyint,@pais tinyint, @tel varchar(32))
RETURNS bit
AS  
BEGIN


declare @call_record as bit
set @call_record = 1

	if @pais = 4 begin --Empieza USA		
		-- grabar
		if @call_record_cam = 1 
			return 1
		-- no grabar
		if @call_record_cam=3  
			return 0
		-- grabar zonas permitidas
		if len(@tel) = 10
			select @call_record = isnull(call_record,1)  from ccTimeZoneArea where id_country= @pais and area = left(@tel,3)

		return @call_record
	end --Termina USA

	return 1
END