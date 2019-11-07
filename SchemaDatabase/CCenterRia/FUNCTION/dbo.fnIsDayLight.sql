CREATE FUNCTION [dbo].[fnIsDayLight](@country_id int, @date DATETIME)
RETURNS BIT
AS
BEGIN
	if exists (
		select * 
		from ccHorarioVerano
		where @date between inicio and fin
		and year(@date) = year(inicio) 
		and year(@date) = year(fin) 
		and country_id = @country_id)
	begin
		RETURN 1
	end

	if exists (
		select * 
		from ccHorarioVerano 
		where @date between inicio and fin
		and year(@date) > year(inicio) 
		and year(@date) = year(fin)
		and country_id = @country_id)
	begin
		RETURN 1
	end

	if exists (
		select * 
		from ccHorarioVerano 
		where @date between inicio and fin
		and year(@date) = year(inicio) 
		and year(@date) < year(fin)
		and country_id = @country_id)
	begin
		RETURN 1
	end
	
	RETURN 0
END