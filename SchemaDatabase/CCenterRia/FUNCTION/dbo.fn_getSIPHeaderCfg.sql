CREATE function [dbo].[fn_getSIPHeaderCfg](@callout_id int, @format varchar(500))
returns varchar(500)
as
begin
	declare @result varchar(500)
	SELECT 
		@result = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@format,'_CAMID_',cast(cam_id as varchar(5))),'_KEY_',cal_Key),'_D1_',Dato1),'_D2_',Dato2),'_D3_',Dato3),'_D4_',Dato4),'_D5_',Dato5),'_CALLOUT_',cast(@callout_id as varchar(10)))
	FROM ccocallsoutsource where callout_id=@callout_id

	select @result = isnull(@result,'')

	return @result
end