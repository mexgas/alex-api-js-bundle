USE CCReportsRIA;

DECLARE @tblist TABLE (tbname nvarchar(max))
INSERT INTO @tblist 
SELECT DISTINCT tablename FROM DataInformation  where tablename is not null

SELECT V1.tbname as '@name'
,(SELECT
V2.columnName as '@name',V2.comments as '@comments' FROM DataInformation V2 
  WHERE V1.tbname = V2.tablename  and V2.comments is not null
  FOR XML PATH('column'), ELEMENTS, TYPE
  )
FROM @tblist V1
FOR XML PATH ('table'), ROOT('tables')