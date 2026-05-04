USE CCenterRIA;
GO
ALTER PROCEDURE ccsp_UpdateWhatsAppOutFromTempAction --- este sp es nuevo
    @action INT,
    @tableName NVARCHAR(255),
    @isZipCodeValidation BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX);
	DECLARE @paramDef NVARCHAR(300);
	DECLARE @empty varchar(1)='',@zipCodeSchedule BIT;
	declare @columnsZipCode varchar(max)='', @valuesColumnsZipCode varchar(max)='';  


	IF @action = 1 -- insert into ccWhatsAppOutSource from tableTmp
	BEGIN
		SET @sql = 'INSERT INTO dbo.ccWhatsAppOutSource(
		CallKey, camId, PhoneNumber, Status, TimeZone, TimeZone_Summer,
		List_id, User_id, TemplateId, componentJson, Data1,
		Data2, Data3, Data4, Data5, dateDial, MessageContent
		)
		SELECT CallKey, camId, PhoneNumber, Status, 
		TimeZone, TimeZone_Summer, List_id, 
		User_id, TemplateId, componentJson,
		Data1, Data2, Data3, 
		Data4, Data5, dateDial, 
		MessageContent 
		FROM ' + QUOTENAME(@tableName) + ' 
		where IsUpdated=0 AND IsReadyToDelete=0;'


		IF (@isZipCodeValidation = 1)
		BEGIN
			SET @columnsZipCode = ', zipCode, isZipCodeValidation'
			SET @valuesColumnsZipCode = ', T.cal_zipCodeValidation, ' +CAST(@isZipCodeValidation AS VARCHAR(1));

			SET @sql += '
			INSERT INTO dbo.ccWhatsAppOutSource_ZipCode (WAOut_Id ' + @columnsZipCode  + ')
			SELECT 
				C.WAOut_Id
				' + @valuesColumnsZipCode  + '
			FROM ' + QUOTENAME(@tableName) + ' AS T
			INNER JOIN dbo.ccWhatsAppOutSource AS C WITH (NOLOCK)
				ON T.CallKey = C.CallKey 
				AND T.camId = C.camId
			WHERE T.IsUpdated = 0 AND T.IsReadyToDelete = 0
				AND T.cal_zipCodeValidation IS NOT NULL 
				AND T.cal_zipCodeValidation <> '''';';
		END

		SET @sql += 'UPDATE ' + QUOTENAME(@tableName) + ' SET IsReadyToDelete = 1 WHERE IsUpdated = 0 AND IsReadyToDelete = 0;';

		EXEC sp_executesql @sql;
	END
	ELSE IF @action = 2 -- update info in ccWhatsAppOutSource from tableTmp
	BEGIN


		SET @sql = 'UPDATE cwaos
            SET
                PhoneNumber = A.PhoneNumber,
                Data1 = A.Data1,
                Data2 = A.Data2,
                Data3 = A.Data3,
                Data4 = A.Data4,
                Data5 = A.Data5,
                componentJson = A.componentJson,
                MessageContent = A.MessageContent,
                TemplateId = A.TemplateId,
                dateDial = CASE WHEN ISNULL(cwwt.WaStatus, 0) = 0 THEN  A.dateDial ELSE cwaos.dateDial END
            FROM ' + QUOTENAME(@tableName) + '  as A
            inner join dbo.ccWhatsAppOutSource AS cwaos with(nolock) on A.WAOut_id = cwaos.WAOut_id
            left join dbo.ccoWAWorkingTable AS cwwt with(nolock) ON A.WAOut_id = cwwt.WAOut_id
            WHERE (cwwt.WAOut_id is null OR cwwt.WaStatus = 0)  and A.IsUpdated = 1 AND A.IsReadyToDelete = 0;';


			IF (@isZipCodeValidation = 1)
			BEGIN
				SET @columnsZipCode = 'Z.zipCode = ' + CASE WHEN @isZipCodeValidation = 1 THEN 'A.cal_zipCodeValidation' ELSE '@empty' END + 
                        ', Z.isZipCodeValidation = ' + CAST(@isZipCodeValidation AS VARCHAR(1));

				SET @sql += '
				UPDATE Z SET 
					' + @columnsZipCode + '
				FROM ' + QUOTENAME(@tableName) + ' A
				LEFT JOIN dbo.ccoWAWorkingTable B WITH (ROWLOCK, UPDLOCK, READPAST) ON A.WAOut_id = B.WAOut_id
				INNER JOIN dbo.ccWhatsAppOutSource_ZipCode Z WITH (ROWLOCK, UPDLOCK) ON A.WAOut_id = Z.WAOut_id
				WHERE (B.WAOut_id is null OR B.WaStatus = 0)  and A.IsUpdated = 1 AND A.IsReadyToDelete = 0;

				INSERT INTO dbo.ccWhatsAppOutSource_ZipCode (WAOut_id, zipCode, isZipCodeValidation)
				SELECT A.WAOut_id, A.cal_zipCodeValidation, 1
				FROM ' + QUOTENAME(@tableName) + ' A
				WHERE A.WAOut_id > 0 
					AND A.IsUpdated = 1 AND A.IsReadyToDelete = 0
					AND A.cal_zipCodeValidation IS NOT NULL 
					AND A.cal_zipCodeValidation <> ''''
					AND NOT EXISTS (SELECT 1 FROM dbo.ccWhatsAppOutSource_ZipCode Z WHERE Z.WAOut_id = A.WAOut_id);';
			END

			SET @sql += 'UPDATE ' + QUOTENAME(@tableName) + ' SET IsReadyToDelete = 1 WHERE IsUpdated = 1 AND IsReadyToDelete = 0;';
			

		EXEC sp_executesql @sql,
			N'@empty varchar(1)',
			@empty = @empty;
	END
    ELSE IF @action = 3 -- update phone number in workingtable if it is exist and WaStatus is Zero, not load by outbound whatsapp
	BEGIN
		SET @sql = 'UPDATE cwwt
            SET
                cwwt.PhoneNumber = A.phoneNumber,
				cwwt.dateDial = cwaos.dateDial
          FROM ' + QUOTENAME(@tableName) + ' as A inner join dbo.ccoWAWorkingTable AS cwwt with(nolock) ON A.WAOut_Id = cwwt.WAOut_Id
            inner join dbo.ccWhatsAppOutSource AS cwaos with(nolock) on A.WAOut_Id = cwaos.WAOut_Id
            WHERE A.IsUpdated = 1 and cwwt.WaStatus = 0;'

			EXEC sys.sp_executesql @sql;
	END
	ELSE IF @action = 4 -- update time zone
	BEGIN
		DECLARE @country TINYINT;
		DECLARE @zipLogic_Inv VARCHAR(100) = '';
		DECLARE @zipLogic_Ver VARCHAR(100) = '';
		DECLARE @zipJoin VARCHAR(MAX) = '';

		SELECT @country = CONVERT(TINYINT, valor) FROM ccSettings WITH (NOLOCK) WHERE setting_id = 104;
		IF @country = 1
		BEGIN
			select @zipCodeSchedule=@isZipCodeValidation;
		END
		  
		if @zipCodeSchedule is null begin
			set @zipCodeSchedule=0
		END

		IF @zipCodeSchedule = 1 
		BEGIN
			SET @zipLogic_Inv = 'WHEN @country=1 THEN ISNULL(Z.tz_id_invierno,0) ';
			SET @zipLogic_Ver = 'WHEN @country=1 THEN ISNULL(Z.tz_id_verano,0) ';
			SET @zipJoin = ' OUTER APPLY dbo.fnGetTimeZoneByZip(T.cal_zipCodeValidation) AS Z ';
		END
        
		SET @sql = '
		UPDATE T SET 
			TimeZone = CASE 
				WHEN (PhoneNumber IS NULL OR LTRIM(RTRIM(PhoneNumber)) = @empty) THEN 0   
				 ' + @zipLogic_Inv + ' 
				  ELSE dbo.fnGetTimeZone(T.PhoneNumber,  0) END,
			TimeZone_Summer = CASE 
				WHEN (PhoneNumber IS NULL OR LTRIM(RTRIM(PhoneNumber)) = @empty) THEN 0  
				 ' + @zipLogic_Ver + '   
				  ELSE dbo.fnGetTimeZone(T.PhoneNumber,  1) END
		FROM ' + QUOTENAME(@tableName) + ' T ' + @zipJoin;

		EXEC sp_executesql @sql,
		N'@country TINYINT,@empty varchar(1)',
			@country = @country,
			@empty = @empty;
	END
	ELSE IF @action = 5 --- delete table temp registries
	BEGIN
	 SET @sql = 'DELETE FROM ' + QUOTENAME(@tableName) + ' WHERE IsReadyToDelete = 1;';    
			EXEC sp_executesql @sql;
	END
END;
GO