use CCRecorderRIA
Go

IF EXISTS (
SELECT 1
	FROM sys.columns c
	INNER JOIN sys.tables t ON c.object_id = t.object_id
	WHERE t.name = N'ccBaseXDB'
	  AND c.name = N'id'
	  AND c.is_identity = 1
)
BEGIN
 DROP TABLE ccBaseXDB;
END


if not exists (select * from sys.tables where name = N'ccBaseXDB')
begin
    CREATE TABLE ccBaseXDB (
        id INT primary key NOT NULL,
        serviceId INT NULL,
        dateStart DATETIME NOT NULL,
        dateEnd DATETIME NULL,
        Xname VARCHAR(25) NOT NULL,
        isFull BIT NULL
    );
end