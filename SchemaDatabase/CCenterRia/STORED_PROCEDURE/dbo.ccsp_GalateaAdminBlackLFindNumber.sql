CREATE PROCEDURE ccsp_GalateaAdminBlackLFindNumber--guiandose del sp de xion ccsp_RIAFindNumber
@number varchar(10)

AS
	select distinct a1.idtipolista as BlackListId,tipolista as BlackListName from cclistanegra a1 
	inner join cctiposlistanegra a2 on (a1.idtipolista=a2.idtipolista) where telefono = @number