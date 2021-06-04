CREATE VIEW [dbo].[ccRIACampEspWGView] AS
select A.IDWG,B.IdCampEsp,A.WGName, Tipo from ccriacat_workgroup A 
	inner join ccRIACampEspWG B on A.IDWG=B.IDWG 

union
select A.IDWG,B.IdCampEsp,A.WGName, Tipo from ccriacat_workgroup A 
	inner join ccRIACampEspWGConsulta B on A.IDWG=B.IDWG