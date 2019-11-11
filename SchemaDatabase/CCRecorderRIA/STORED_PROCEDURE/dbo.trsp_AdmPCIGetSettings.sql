-- =============================================
-- Author:		Fernando S.R.
-- Create date: Enero 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmPCIGetSettings]
@command tinyint,
@setting_id smallint = null,
@value varchar(200) = null 

AS
BEGIN

	SET NOCOUNT ON;

	declare @idioma tinyint
	select @idioma=valor from CCenterRia.dbo.ccSettings where setting_id=27

	if @command=0
	begin
		return(0)
	end

	if @command=1
	begin
		Select par_id, case @idioma when 0 then par_descripcion else [par_description] end par_descripcion, 
			par_valor from RIA_PCI_Settings where par_id in (1,2,3,4,5,6,7,8,9,11,12,13) order by par_id 
		return(0)
	end

	if @command=2
	begin
		update RIA_PCI_Settings set par_valor=@value where par_id = @setting_id
		return(0)
	end

	set nocount off
END