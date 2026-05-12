use CCenterRIA;
Go

IF OBJECT_ID('dbo.ccDNCQueue', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ccDNCQueue
    (
        QueueId BIGINT IDENTITY(1,1) PRIMARY KEY,
        telefono VARCHAR(30) NOT NULL,
        ln_id INT NOT NULL,
        calKey VARCHAR(40) NULL,
        status TINYINT NOT NULL DEFAULT 0,
        created_at DATETIME NOT NULL DEFAULT GETDATE(),
        started_at DATETIME NULL,
        retry_count INT NOT NULL DEFAULT 0,
        error_message VARCHAR(1000) NULL
    );
END