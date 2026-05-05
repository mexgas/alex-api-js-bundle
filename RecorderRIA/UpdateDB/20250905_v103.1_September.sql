set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
    Set @Version = 103
    Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
    begin tran
    begin try

	-----------------------------------BEGIN Sercvices Pack 1-8 ---------------------------------------
    SET @process = 'DROP TABLE ccBaseXDB;'
	SET @sql = 'IF EXISTS (
SELECT 1
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    WHERE t.name = N''ccBaseXDB''
      AND c.name = N''id''
      AND c.is_identity = 1
)
BEGIN
 DROP TABLE ccBaseXDB;
END'
	EXEC(@sql)

    SET @process = 'CREATE TABLE ccBaseXDB '
    SET @sql = 'if not exists (select * from sys.tables where name = N''ccBaseXDB'')
begin
    CREATE TABLE ccBaseXDB (
        id INT primary key NOT NULL,
        serviceId INT NULL,
        dateStart DATETIME NOT NULL,
        dateEnd DATETIME NULL,
        Xname VARCHAR(25) NOT NULL,
        isFull BIT NULL
    );
end'
    EXEC(@sql)


    SET @process = ''
    SET @sql = ''
    EXEC(@sql)

    SET @process = ''
    SET @sql = ''
    EXEC(@sql)

    SET @process = ''
    SET @sql = ''
    EXEC(@sql)

    SET @process = ''
    SET @sql = ''
    EXEC(@sql)

    SET @process = ''
    SET @sql = ''
    EXEC(@sql)

    SET @process = ''
    SET @sql = ''
    EXEC(@sql)

    SET @process = ''
    SET @sql = ''
    EXEC(@sql)

    SET @process = ''
    SET @sql = ''
    EXEC(@sql)
    ------------------------------------END Sercvices Pack 1-8 ----------------------------------------




    update trec_parametros set par_valor = @Version where par_id = 30
    set @Version_Actual=@Version_Actual+1

    select par_valor from trec_parametros where par_id = 30

    commit tran

    end try
    begin catch
        select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
        RAISERROR(@errorGenerated, 11, 1)
    rollback tran
    end catch
 end
 else begin
    select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
