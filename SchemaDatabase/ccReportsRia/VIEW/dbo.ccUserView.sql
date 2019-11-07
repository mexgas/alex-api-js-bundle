CREATE VIEW [dbo].[ccUserView] AS
select User_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,TipoStatusAge_id,TipoUser_id,Status,Sexo,IDArea from ccUsers 
union
select User_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,TipoStatusAge_id,TipoUser_id,Status,Sexo,IDArea from ccUsers_Consulta