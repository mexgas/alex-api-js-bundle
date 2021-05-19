CREATE procedure [dbo].[ccspLoaderScript]
@action int = 0,
@TemplateId int
AS
SET NOCOUNT ON;
begin
declare @sql varchar(max)
declare @TemplateIdVarchar varchar(max)
declare @TempTable varchar(max)
declare @tableNameData varchar(max)

set @TemplateIdVarchar=+convert(varchar(100),@TemplateId)
set @TempTable='TEMP_CS_Data_'+@TemplateIdVarchar


  if @action=1 begin    
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
  end
  else if @action=2 begin   
    set @sql='delete A from '+@TempTable+' A where A.Call_key is null or A.Call_key='''' ';
    exec (@sql);
  end
  else if @action=3 begin   
    set @sql='delete A from '+@TempTable+' A 
    inner join( select max(Record_id) as Record_id,Call_key from '+@TempTable+' 
    group by Call_key Having count(*) > 1) B on A.Record_id<> B.Record_id and A.Call_key = B.Call_key';
    exec (@sql);
  end
  else if @action=4 begin
    set @tableNameData='CS_Data_'+@TemplateIdVarchar
    set @sql='select * into '+ @TempTable +' from ' + @tableNameData + ' where 1=0';
    exec (@sql);
  end
  else if @action=5 begin
    set @tableNameData='CS_Data_'+@TemplateIdVarchar;
    DECLARE @dataSet NVARCHAR(MAX)= '';
    SELECT @dataSet = @dataSet + 'A.' + COLUMN_NAME + '= B.' + COLUMN_NAME + ','
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = @tableNameData AND 
        COLUMN_NAME NOT IN( 'Record_id', 'Call_key', 'Date' );

    SET @dataSet = SUBSTRING(@dataSet, 0, LEN(@dataSet));

    SET @sql = 'update A set ' + @dataSet + ' from ' + @tableNameData + ' A 
    inner join ' + @TempTable + ' b on A.Call_key=B.Call_key';
  
    EXEC (@sql);

    SET @sql = 'delete B from ' + @tableNameData + ' A 
    inner join ' + @TempTable + ' B on A.Call_key=B.Call_key';
    EXEC (@sql);
    DECLARE @components NVARCHAR(MAX)= '';
    SELECT @components = @components + COLUMN_NAME + ','
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = @tableNameData AND 
        COLUMN_NAME NOT IN( 'Record_id', 'Call_key', 'Date' );
        
    SET @components = SUBSTRING(@components, 0, LEN(@components));
    Print @components
    SET @sql = 'insert into ' + @tableNameData + ' (call_key,date,' + @components + ')' + '
    select Call_key,Date,' + @components + ' from ' + @TempTable;
    EXEC (@sql);
  end 
end