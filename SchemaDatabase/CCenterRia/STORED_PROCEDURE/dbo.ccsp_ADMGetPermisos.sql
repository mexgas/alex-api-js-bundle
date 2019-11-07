CREATE PROCEDURE ccsp_ADMGetPermisos
@user_id int = 0
AS
Select distinct u.User_id as ID, Login, Nombres + ' ' + isNull(apellidoPaterno,'') + ' ' + 
isNull(ApellidoMaterno, '') as 'Nombre', cast(dialMask & 1 as bit) as 'Restringe celular',
cast( (dialMask & 2) /2 as bit) as 'Restringe ld', cast((dialMask & 4) / 4 as bit) as 'Restringe local', 
cast( xfermask as bit) as 'Recibe transferencia' 
from ccUsers u inner join ccCampsAgente c 
on u.user_id = c.user_id
inner join ccSupervisorCam s
on c.cam_id = s.cam_id
and tipo = 1
and (s.user_id = @user_id or @user_id = 0)
where status > 0 and tipouser_id = 1