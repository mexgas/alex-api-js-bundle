CREATE PROCEDURE [dbo].[ccsp_RIAConfParameters]
@nTab varchar(4),
@valor varchar(100),
@setting_id tinyint,
@Type tinyint
AS
declare @sql nvarchar(1000)
	if( @Type=1)--Load Parameters
		begin
			Select setting_id as Id, Descripcion, Valor from ccSettings WHERE Tipo = @nTab AND status=1  ORDER by descripcion
		end

		If ( @Type = 2 )
		begin
			update ccSettings set valor = @valor where setting_id = @setting_id
		end