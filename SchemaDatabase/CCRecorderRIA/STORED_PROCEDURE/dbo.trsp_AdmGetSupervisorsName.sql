CREATE PROCEDURE  [dbo].[trsp_AdmGetSupervisorsName]

@user_id int

AS
BEGIN

	SET NOCOUNT ON;


select IsNULL(Nombres,'') as nombre ,ISNULL(ApellidoPaterno,'') as apellidopaterno, ISNULL(ApellidoMaterno,'') as apellidomaterno from ccUsers where user_id = @user_id


END