CREATE PROCEDURE [dbo].[cssp_updateTemplateData] @componentString VARCHAR(MAX)
			  ,@template_id VARCHAR(1000)
			  ,@cal_key VARCHAR(1000)
			AS
			BEGIN
			  SET NOCOUNT ON;

			  DECLARE @sql VARCHAR(MAX);  
			  declare @tableName varchar(500)
			  
			  set @tableName='cs_data_'+convert(VARCHAR(1000), @template_id)

			  SET @sql = '
			   if not exists(select * from ' + @tableName +' where call_key =''' + @cal_key+ ''') begin
					Insert into '+ @tableName +' (Call_key,Date) 
					values ('''+@cal_key+''',getdate())
			   end
				update ' + @tableName + ' set ' + @componentString + ' where call_key =''' + @cal_key+ '''
					'
				--print(@sql)
			  EXEC (@sql);
			END