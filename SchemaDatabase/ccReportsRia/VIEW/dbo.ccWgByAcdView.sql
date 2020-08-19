CREATE VIEW [dbo].[ccWgByAcdView]
AS
SELECT A.Inbound_id, A.descripcion, B.IDWG, A.IDArea, C.User_id
FROM ccinbound A
INNER JOIN ccRIACampEspWG B ON A.Inbound_id=B.IdCampEsp AND tipo=0
INNER JOIN ccriaworkgroupusers C ON C.IDWG = B.IDWG
INNER JOIN ccUserView D ON D.User_id = C.User_id AND TipoUser_id=2