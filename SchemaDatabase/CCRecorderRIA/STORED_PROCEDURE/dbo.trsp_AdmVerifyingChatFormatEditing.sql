CREATE PROCEDURE [dbo].[trsp_AdmVerifyingChatFormatEditing]
@id_chat int,@id_formato int,@type tinyint = 2


AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;


	-- Insert statements for procedure here

Select isnull(max(id_forma),0) from RIA_FORMACALIF
where id_grabacion = @id_chat and id_formato = @id_formato and tipo=@type

END