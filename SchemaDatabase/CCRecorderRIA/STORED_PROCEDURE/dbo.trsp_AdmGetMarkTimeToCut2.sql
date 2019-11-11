CREATE PROCEDURE [dbo].[trsp_AdmGetMarkTimeToCut2]
@grabId bigint

AS
BEGIN

declare @sql nvarchar(max)

set @sql='select top 1 isnull(SUM(DATEDIFF(SECOND, 0, marca)),0) from (select * from RIA_Grabacion where grab_id='+cast(@grabId as nvarchar(max))
+'union select * from RIA_GrabacionConsulta where grab_id='+cast(@grabId as nvarchar(max))
+') A left join RIA_MARCAS B on B.tipo_llamada = A.tipo_llamada and B.call_Id=A.cal_id'
--print (@sql)
exec(@sql)

END