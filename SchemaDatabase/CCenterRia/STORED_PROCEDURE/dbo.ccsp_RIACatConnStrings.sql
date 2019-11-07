CREATE PROCEDURE [dbo].[ccsp_RIACatConnStrings]
@driver varchar(40) = null,
@command tinyint,
@tableName varchar(50) = null,
@fields varchar(1000) = null,
@condition varchar(1000) = null,
@tops tinyint = 1

AS

declare @string as varchar(2000)
declare @leftDelim as char
declare @rightDelim as char
declare @QueryTop as varchar(15)
declare @changeDelimiters as bit 

set @changeDelimiters = 0

	if( @command=1) --Get Column query
		begin
			if (exists(Select ColumnQuery from ccRIACatConnStrings where driver = @driver))
			begin
				Select @string = ColumnQuery from ccRIACatConnStrings where driver = @driver
			end
			else
			begin
				Select @string = ColumnQuery from ccRIACatConnStrings where lower(driver) = 'default'
				set @changeDelimiters = 1
			end
		end
	If( @command=2) --Get table query
		begin
			if (exists(Select TableQuery from ccRIACatConnStrings where driver = @driver))
			begin
				Select @string = TableQuery from ccRIACatConnStrings where driver = @driver
			end
			else
			begin
				Select @string = TableQuery from ccRIACatConnStrings where lower(driver) = 'default'
				set @changeDelimiters = 1
			end
		end
	if( @command=3) --Get preview query
		begin
			if (exists(Select PreviewQuery from ccRIACatConnStrings where driver = @driver))
			begin
				Select @string = PreviewQuery from ccRIACatConnStrings where driver = @driver
			end
			else
			begin
				Select @string = PreviewQuery from ccRIACatConnStrings where lower(driver) = 'default'
				set @changeDelimiters = 1
			end
		end

set @string = REPLACE(@string,'<TABLEREC>',isnull(@tableName,''))
set @string = REPLACE(@string,'<FIELDS>',isnull(@fields,''))
set @string = REPLACE(@string,'<CONDITION>',isnull(@condition,''))


select @leftDelim = leftDelim from ccRIACatConnStrings where driver = @driver
select @rightDelim = rightDelim from ccRIACatConnStrings where driver = @driver


If (@changeDelimiters = 0)
begin
	set @string = REPLACE(@string,'[',isnull(@leftDelim,''))
	set @string = REPLACE(@string,']',isnull(@rightDelim,''))
end

IF @tops = 1 
begin
	select @QueryTop = Tops from ccRIACatConnStrings where driver = @driver
	set @string = REPLACE(@string,'<TOPS>',isnull(@QueryTop,''))
end
else
begin
	set @string = REPLACE(@string,'<TOPS>',isnull('',''))
end

SELECT @string as query



--Select * from ccRIACatConnStrings

--exec ccsp_RIACatConnStrings 'iclit09b.dll',1,'t02datos','campos'

--SELECT COLNAME FROM SYSCOLUMNS WHERE TABID = (SELECT TABID FROM SYSTABLES WHERE TABNAME ='" & TableRec & "')
--update ccRIACatConnStrings set ColumnQuery = 'SELECT COLNAME FROM SYSCOLUMNS WHERE TABID = (SELECT TABID FROM SYSTABLES WHERE TABNAME = ''<TABLEREC>'')'