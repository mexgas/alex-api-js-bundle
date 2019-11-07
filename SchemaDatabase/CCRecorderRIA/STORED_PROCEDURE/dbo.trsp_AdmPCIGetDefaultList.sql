CREATE PROCEDURE [dbo].[trsp_AdmPCIGetDefaultList]

@ListType int


AS
BEGIN

declare @Idiom int

	SET NOCOUNT ON;

set @Idiom = (select valor from ccSettings where setting_id = 27)

if @Idiom = 0

Begin

select PalabraClave from RIA_PCI_DEFAULT_LIST where List_Type = @ListType

End

Else IF @idiom = 1

Begin

select Keyword from RIA_PCI_DEFAULT_LIST where List_Type = @ListType

End

END