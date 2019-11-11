CREATE PROCEDURE ccspGenExporta
@server as varchar(100),
@tabla as varchar(50),
@campoFecha as varchar(50),
@from AS varchar(20),
@to AS varchar(20),
@borra bit = 1
AS
declare @sql as varchar(8000)

set @sql = 'ccspGenExporta: ' +  @tabla
exec ccsp_LogInfo @sql, -18

SET ARITHABORT ON
-- Borra tabla destino
set @sql = 'DELETE '+@server+'.dbo.' + @tabla +'  WHERE ' + @campoFecha+ ' >= '+char(0x27)+@from+char(0x27)+' AND '+ @campoFecha + ' < '+char(0x27)+@to+char(0x27)+''
--print @sql
exec (@sql)

-- Inserta de origen a destino
set @sql  = 'INSERT INTO '+@server+'.dbo.' + @tabla +'  '
set @sql = @sql + 'select * from '+ @tabla +'  WHERE '+ @campoFecha +' >= '+char(0x27)+@from+char(0x27)+' AND '+ @campoFecha +' < '+char(0x27)+@to+char(0x27)+''
exec (@sql)

-- Borra tabla origen
IF @@ERROR = 0 and @borra = 1
BEGIN
	set @sql = 'TRUNCATE TABLE  '+ @tabla
	exec (@sql)
END