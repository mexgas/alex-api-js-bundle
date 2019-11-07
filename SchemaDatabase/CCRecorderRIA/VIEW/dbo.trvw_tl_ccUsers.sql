CREATE VIEW [dbo].[trvw_tl_ccUsers]
AS
SELECT     User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, TipoUser_id
FROM       ccUsers