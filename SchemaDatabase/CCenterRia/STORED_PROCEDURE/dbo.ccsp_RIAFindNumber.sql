CREATE PROCEDURE [dbo].[ccsp_RIAFindNumber]
@number varchar(10)

AS
	if ( select count(*) from cclistanegra a1 inner join cctiposlistanegra a2 on (a1.idtipolista=a2.idtipolista) where telefono = @number ) > 0
		select a1.idtipolista,tipolista from cclistanegra a1 inner join cctiposlistanegra a2 on (a1.idtipolista=a2.idtipolista) where telefono = @number
	else
	begin
		select -1 --No existe
	end