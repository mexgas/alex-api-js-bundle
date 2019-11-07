create function dbo.fn_CampEspWG (@ID smallint, @tipo tinyint) -- 0:WG-Esp / 1:WG-Camp / 2:Esp-WG / 3:Camp-WG
returns int
as
begin
declare @Relations smallint

if @tipo in(0,1)
	select @Relations = count(IDWG) from ccRIACampEspWG where tipo = @tipo and IDWG = @ID group by IDWG

else if @tipo=2
	select @Relations = count(IdCampEsp) from ccRIACampEspWG where tipo = 0 and IdCampEsp = @ID group by IdCampEsp

else if @tipo=3
	select @Relations = count(IdCampEsp) from ccRIACampEspWG where tipo = 1 and IdCampEsp = @ID group by IdCampEsp

return isnull(@Relations,0)
end