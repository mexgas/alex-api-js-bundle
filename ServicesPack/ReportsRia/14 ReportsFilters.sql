use [CCReportsRIA]

IF NOT EXISTS (
    SELECT TOP 1 1 
    FROM ReportsFilters 
    WHERE ReportName = 'Answered Calls Detail' 
      AND FilterType = 'calltypes' 
      AND FilterValue = 4020
)
BEGIN
    INSERT INTO ReportsFilters (ReportName, FilterType, FilterValue)
    VALUES ('Answered Calls Detail', 'calltypes', 4020)
END

