CREATE PROCEDURE dbo.ccsp_AVRSLogin
@username VARCHAR(20),
@password VARCHAR(32)
AS
set nocount on
-- SP usado por AVRS para firmarse cuando esta integrado con CW
DECLARE @age_id as INT -- ID de agente
DECLARE @perfilCalidad as INT -- Indica si muestra la opcin de crear formatos de calificacin

SELECT @age_id=user_id, @perfilCalidad=CASE WHEN TipoUser_id & 4 = 4 THEN 4 END 
FROM ccUsers WHERE login=@username AND (password=@password OR password = dbo.md5(@password)) AND TipoUser_id > 1 AND status=1

IF @username='root'
 BEGIN
	select @perfilCalidad = 2
 END

IF @age_id>0
 BEGIN
	SELECT 'age_id'=@age_id, 'perfil_id'=@perfilCalidad
	return(0)
 END

SELECT 'age_id'=0, 'perfil_id'=0
set nocount off