CREATE PROCEDURE  [dbo].[trsp_AdmVerifyMarksToExport2]
			@grabIds nvarchar(max)

			AS
			BEGIN
			declare @sql nvarchar(max)
						
			set @sql='select count(*) from (select * from RIA_Grabacion where grab_id in('+@grabids +') 
			 union select * from RIA_GrabacionConsulta where grab_id in('+@grabids +')) A 
			 inner join RIA_MARCAS B on B.tipo_llamada = A.tipo_llamada and B.call_Id=A.cal_id'
			 --print (@sql)
			 exec(@sql)

			END