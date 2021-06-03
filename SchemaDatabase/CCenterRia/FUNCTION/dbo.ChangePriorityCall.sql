CREATE FUNCTION [dbo].[ChangePriorityCall](@priorityCall VARCHAR(8))
RETURNS VARCHAR(8)
AS
BEGIN
    DECLARE @resultado VARCHAR(32);
    SET @resultado = CAST(CASE
        WHEN CAST(SUBSTRING(@priorityCall, 1, 1) AS TINYINT) < 5
        THEN CAST(SUBSTRING(@priorityCall, 1, 1) AS TINYINT) + 1
        ELSE 1
        END AS VARCHAR(1)) + REPLACE('2345NNN', CAST(CASE
        WHEN CAST(SUBSTRING(@priorityCall, 1, 1) AS TINYINT) < 5
        THEN CAST(SUBSTRING(@priorityCall, 1, 1) AS TINYINT) + 1
        ELSE 1
        END AS VARCHAR(1)), '1');
    RETURN @resultado;
END;