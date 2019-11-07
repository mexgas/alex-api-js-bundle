CREATE PROCEDURE [dbo].[trsp_AdmGetExportFields]
			 @usuarioId int,@grabId bigint

			AS
			BEGIN

			SET NOCOUNT ON

			declare @campos nvarchar(max),@columns nvarchar(max),@sql nvarchar(max)

			select @campos=isnull(max(campos),'') from RIA_PERFILES_EXPORTACION where id_usuario = @usuarioId and active =1

			select @columns = coalesce (@columns+',', '') + b.Campo from dbo.fn_RIASplitDelimited(@campos,',') a
			 inner join TREC_FORM_ARCHIVOSEXPORT b on a.value=b.id

			 
			 set @sql='select ' + @columns + ' from RIA_Grabacion where grab_id='+cast(@grabId as nvarchar(max))
			 +'union select '+@columns+' from RIA_GrabacionConsulta where grab_id='+cast(@grabId as nvarchar(max))
			 --print (@sql)
			 exec(@sql)

			END