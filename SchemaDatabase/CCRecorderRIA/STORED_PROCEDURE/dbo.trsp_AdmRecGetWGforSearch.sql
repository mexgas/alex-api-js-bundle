CREATE PROCEDURE [dbo].[trsp_AdmRecGetWGforSearch]

@Cal_id int,
@User_id int,
@CallType int



AS
BEGIN

	SET NOCOUNT ON;

select IDWG from ccRIAWorkGroup_Calid where cal_id = @Cal_id and User_id = @User_id and tipo = @CallType

END