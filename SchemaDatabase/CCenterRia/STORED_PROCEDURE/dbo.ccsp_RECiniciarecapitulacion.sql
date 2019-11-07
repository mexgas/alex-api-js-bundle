create procedure dbo.ccsp_RECiniciarecapitulacion 
@IDCall int,
@TipoCall tinyint --1 = entrada, 2 = salida
as
set nocount on
declare @hora datetime
set @hora = GETDATE()
if @TipoCall = 1
	UPDATE ccCallsIn SET fvalida = @hora WHERE cal_id = @IDCall

else
	UPDATE ccoCallsOut SET fvalida = @hora WHERE cal_id = @IDCall
return(0)
set nocount off