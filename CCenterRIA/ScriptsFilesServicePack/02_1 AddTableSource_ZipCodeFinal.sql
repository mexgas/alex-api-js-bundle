USE CCenterRIA
GO

-- 1. TABLA PARA LLAMADAS (ccoCallsOutSource)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ccoCallsOutSource_ZipCode' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.ccoCallsOutSource_ZipCode (
        callout_id INT NOT NULL, 
        
        zipCode VARCHAR(10) DEFAULT(''),
        isZipCodeValidation BIT DEFAULT(0)
        
        CONSTRAINT PK_ccoCallsOutSource_ZipCode PRIMARY KEY CLUSTERED (callout_id),
        CONSTRAINT FK_ccoCallsOutSource_ZipCode_Main FOREIGN KEY (callout_id) 
            REFERENCES dbo.ccoCallsOutSource(callout_id) ON DELETE CASCADE
    );

    CREATE INDEX IX_ccoCallsOutSource_ZipCode_Zip1 ON dbo.ccoCallsOutSource_ZipCode(zipCode);
END

-- 2. TABLA PARA WHATSAPP (ccWhatsAppOutSource)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ccWhatsAppOutSource_ZipCode' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.ccWhatsAppOutSource_ZipCode (
        WAOut_Id BIGINT NOT NULL, 
        zipCode VARCHAR(10) DEFAULT(''),
        isZipCodeValidation BIT DEFAULT(0),
        
        CONSTRAINT PK_ccWhatsAppOutSource_ZipCode PRIMARY KEY CLUSTERED (WAOut_Id),
        CONSTRAINT FK_ccWhatsAppOutSource_ZipCode_Main FOREIGN KEY (WAOut_Id) 
            REFERENCES dbo.ccWhatsAppOutSource(WAOut_Id) ON DELETE CASCADE
    );
END

-- 3. TABLA PARA SMS (smsOutSource)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'smsOutSource_ZipCode' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.smsOutSource_ZipCode (
        smsout_id INT NOT NULL, 
        zipCode VARCHAR(10) DEFAULT(''),
        isZipCodeValidation BIT DEFAULT(0),
        
        CONSTRAINT PK_smsOutSource_ZipCode PRIMARY KEY CLUSTERED (smsout_id),
        CONSTRAINT FK_smsOutSource_ZipCode_Main FOREIGN KEY (smsout_id) 
            REFERENCES dbo.smsOutSource(smsout_id) ON DELETE CASCADE
    );
END