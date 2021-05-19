CREATE PROCEDURE [dbo].[cssp_getTemplateData] 
				@componentString VARCHAR(MAX), @template_id VARCHAR(1000), @cal_key VARCHAR(1000)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @sql VARCHAR(MAX);

	set @sql=
	'SELECT columnName, dataValue FROM CS_Data_' + @template_id +
	' UNPIVOT(dataValue FOR columnName IN('+@componentString+')) AS unpiv 
	WHERE call_key =  convert(nvarchar(1000),'''+ @cal_key+''')'
	PRINT @sql;
	EXEC (@sql);
END;