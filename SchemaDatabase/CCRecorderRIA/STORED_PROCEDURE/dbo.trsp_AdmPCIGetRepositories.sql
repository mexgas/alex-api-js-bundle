-- =============================================
-- Author:		Javier R. R.
-- Create date: Enero 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmPCIGetRepositories]

@Grab_ID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


select ruta_local from RIA_REPOSITORIOS where id_repositorio =  
(select * from (select id_repositorio from RIA_GRABACIONCONSULTA where grab_id = @Grab_ID
UNION select id_repositorio from RIA_GRABACION where grab_id = @Grab_ID ) x )


END