CREATE FUNCTION [dbo].[VerificaRegionLocalidad](@tel varchar(32),@pais tinyint = 0, @cldLocal varchar(7) = '')
RETURNS @retVRL TABLE
(
    tel varchar(32) PRIMARY KEY NOT NULL,
    region varchar(32) NULL,
    localidad varchar(32) NULL
)
 BEGIN
 declare @ld varchar(7)
 declare @lon tinyint 
 declare @lonLd tinyint 
 declare @region varchar(20)
 declare @localidad varchar(20) 
 declare @serie varchar(10)
 
 select @region='',@localidad=''

 if (@pais = 0 and @cldLocal = '') begin
	select @pais = valor from ccSettings with(nolock) where setting_id = 104
	select @cldLocal = valor from ccSettings with(nolock) where setting_id = 17
end

 select @tel = dbo.limpia(@tel)

if @pais = 1 begin --Empieza Mexico
	select @lon = len(@tel)
	if @lon in(7,8) begin
		set @tel = @cldLocal + @tel
		set @ld=@cldLocal
	end	
	
	select @tel = right(@tel, 10)
	select @lon = len(@tel)	
  if @lon = 10 begin

		IF EXISTS (
				SELECT TOP 1 cld
				FROM series NOLOCK
				WHERE cld = left(@tel, 3)
				and serie=SUBSTRING(@tel,4,3)
				)
			SELECT @ld = left(@tel, 3),@serie=SUBSTRING(@tel,4,3)
		ELSE IF EXISTS (
				SELECT TOP 1 cld
				FROM series NOLOCK
				WHERE cld = left(@tel, 2)
				and serie=SUBSTRING(@tel,3,4)
				)
			SELECT @ld = left(@tel, 2),@serie=SUBSTRING(@tel,3,4)

		

		if @serie is not null begin
			set @lonLd=len(@ld)
			select top 1 @region = estado, @localidad = municipio from series nolock where cld=@ld and SERIE=@serie
		end
		else begin
			select top 1 @region = estado, @localidad = municipio from series nolock where cld=@cldLocal
		end

	end
   else  begin
		if (@region is null) begin
			select top 1 @region = estado from series nolock where cld=@cldLocal
		end		
	end
end --Termina Mexico

  INSERT @retVRL
        SELECT @tel as phone, @region as estado, @localidad as municipio
  RETURN

end