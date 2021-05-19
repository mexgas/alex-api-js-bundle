CREATE PROCEDURE [dbo].[ccsp_LoadExcelFile] 
				@template_id VARCHAR(1000), @fileN VARCHAR(1000), @components NVARCHAR(MAX), @names NVARCHAR(MAX), @cal_key
				VARCHAR(1000), @sheetName VARCHAR(1000), @hasHeaders VARCHAR(10), @user_id INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @tableName VARCHAR(1000)=
	(
		SELECT TABLE_NAME
		FROM INFORMATION_SCHEMA.TABLES
		WHERE TABLE_NAME = 'CS_Data_' + @template_id
	);
	DECLARE @TempTable VARCHAR(1000)= 'TEMP_' + @tableName;
	DECLARE @sql VARCHAR(MAX);

	IF @components IS NOT NULL OR 
	   @components <> ''
	BEGIN

		IF EXISTS
		(
			SELECT *
			FROM sys.tables
			WHERE name = @TempTable
		)
		BEGIN
			SET @sql = 'Drop table ' + @TempTable;
			EXEC (@sql);
		END;
		SET @sql = 'select * into ' + @TempTable + ' from ' + @tableName + ' where 1=0';
		EXEC (@sql);

		SET @sql = 'insert into ' + @TempTable + ' (call_key,date,' + @components + ')
	SELECT [' + @cal_key + '],convert(datetime,getdate()), ' + @names +
		'
	FROM OPENROWSET(
    ''Microsoft.ACE.OLEDB.12.0'',
    ''Excel 8.0;HDR=' + @hasHeaders + ';Database=' + @fileN + ''',
    ''select * from [' + @sheetName + '$]'')

	select convert(varchar(1000),' + @template_id + ') as [template_id]
	';
		EXEC (@sql);


		SET @sql = 'delete A from '+@TempTable+' A where A.Call_key is null or A.Call_key='''''
		EXEC (@sql);

		SET @sql = '
		delete A from '+@TempTable+' A 
		inner join (
		select max(Record_id) as Record_id,Call_key from '+@TempTable+' group by Call_key Having count(*)>1)
		B on A.Record_id<>B.Record_id and A.Call_key=B.Call_key'

		EXEC (@sql);

		DECLARE @dataSet NVARCHAR(MAX)= '';
		SELECT @dataSet = @dataSet + 'A.' + COLUMN_NAME + '= B.' + COLUMN_NAME + ','
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = @tableName AND 
			  COLUMN_NAME NOT IN( 'Record_id', 'Call_key', 'Date' );

		SET @dataSet = SUBSTRING(@dataSet, 0, LEN(@dataSet));

		SET @sql = 'update A set ' + @dataSet + ' from ' + @tableName + ' A 
	inner join ' + @TempTable + ' b on A.Call_key=B.Call_key';
	
		EXEC (@sql);

		SET @sql = 'delete B from ' + @tableNAme + ' A 
	inner join ' + @TempTable + ' B on A.Call_key=B.Call_key';
		EXEC (@sql);

		SET @sql = 'insert into ' + @tableName + ' (call_key,date,' + @components + ')' + '
	select Call_key,Date,' + @components + ' from ' + @TempTable;
		EXEC (@sql);		

		SET @sql = 'drop table ' + @TempTable;
		EXEC (@sql);

		EXEC ccsp_Logger @action = 2, @action_id = 6, @template_id = @template_id, @user_id = @user_id;

	END;
END;