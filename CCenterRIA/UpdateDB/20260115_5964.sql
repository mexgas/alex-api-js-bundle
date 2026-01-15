USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_UpdateCallsOutFromTempAction]    Script Date: 15/01/2026 01:22:51 p. m. ******/
-- se realizó cambio en el option5, para que se actualice la fecha (cal_fechaDial), cuando los registros son existentes, 
--pero evitando que si el registro esta en callback en workingTable, la fecha no se actualice.
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccsp_UpdateCallsOutFromTempAction]
		@action INT,
		@tableName NVARCHAR(255),
		@cal_status int = 0,
		@idLoad int=0,
		@motivo varchar(50)=null,
		@cam_id int=null,
		@isIAQuantumCamp bit =0,
		@internationalRecords int=0

	AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @sql NVARCHAR(MAX);
		DECLARE @paramDef NVARCHAR(300);    
		DECLARE @count INT;
		declare @emtpy varchar(1)='',@zipCodeSchedule bit 
		declare @columnsIAQuntum varchar(max)=''   

		IF @action = 1
		BEGIN
			SET @sql = '
			UPDATE ' + QUOTENAME(@tableName) + '
			SET international = 1';
		   
			EXEC sp_executesql @sql;
		END
		ELSE IF @action = 2
		BEGIN
				
			if @isIAQuantumCamp =1 begin
				set @columnsIAQuntum=', data_api_quantum, data_overflow_variables_quantum'
			end

			SET @sql = '
			INSERT INTO dbo.ccoCallsOutSource (
				cal_Key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
				Dato1, Dato2, Dato3, Dato4, Dato5,
				dialPrefix, list_id, cam_id, Region, Localidad, cal_status, cal_fechaDial
				,iZonaHoraria,iZonaHoraria_verano
				,iZonaHoraria2,iZonaHoraria_verano2
				,iZonaHoraria3,iZonaHoraria_verano3
				,iZonaHoraria4,iZonaHoraria_verano4
				,iZonaHoraria5,iZonaHoraria_verano5
				' + @columnsIAQuntum + '
			)
			SELECT
				cal_Key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
				Dato1, Dato2, Dato3, Dato4, Dato5,
				dialPrefix, list_id, cam_id, Region, Localidad, cal_status, cal_fechaDial
				,iZonaHoraria,iZonaHoraria_verano
				,iZonaHoraria2,iZonaHoraria_verano2
				,iZonaHoraria3,iZonaHoraria_verano3
				,iZonaHoraria4,iZonaHoraria_verano4
				,iZonaHoraria5,iZonaHoraria_verano5
				' + @columnsIAQuntum + '
			FROM ' + QUOTENAME(@tableName) + '
			WHERE callout_id = 0';

			EXEC sp_executesql @sql;
		END
		
		ELSE IF @action = 3
		BEGIN
			SET @sql = '
			INSERT INTO dbo.ccoCallsPreviewData (
				cal_Key, cam_id, TotalData, Headers,
				Dato6, Dato7, Dato8, Dato9, Dato10,
				Dato11, Dato12, Dato13, Dato14, Dato15
			)
			SELECT 
				A.cal_Key, A.cam_id, A.TotalData, A.Headers,
				A.Dato6, A.Dato7, A.Dato8, A.Dato9, A.Dato10,
				A.Dato11, A.Dato12, A.Dato13, A.Dato14, A.Dato15
			FROM ' + QUOTENAME(@tableName) + ' A
			left join ccoCallsPreviewData B on A.cal_Key=B.cal_Key and A.cam_id=B.cam_id
			WHERE B.cam_id is null;
			';
		
			EXEC sp_executesql @sql;
		END
		ELSE IF @action = 4
		BEGIN
			SET @sql = '
			UPDATE C SET
				C.Headers = A.Headers,
				C.TotalData = A.TotalData,
				C.Dato6 = A.Dato6, C.Dato7 = A.Dato7, C.Dato8 = A.Dato8, C.Dato9 = A.Dato9, C.Dato10 = A.Dato10,
				C.Dato11 = A.Dato11, C.Dato12 = A.Dato12, C.Dato13 = A.Dato13, C.Dato14 = A.Dato14, C.Dato15 = A.Dato15
			FROM ' + QUOTENAME(@tableName) + ' A
			INNER JOIN dbo.ccoCallsPreviewData C WITH (ROWLOCK, UPDLOCK)
				ON A.cal_Key = C.cal_Key AND A.cam_id = C.cam_id;
			';
		
			EXEC sp_executesql @sql;
		END
		ELSE IF @action =5
		BEGIN
			if @isIAQuantumCamp =1 begin
				set @columnsIAQuntum=', C.data_api_quantum = A.data_api_quantum, C.data_overflow_variables_quantum = A.data_overflow_variables_quantum'
			end

			SET @sql = '
			UPDATE C SET
				C.cal_status = CASE WHEN B.callout_id IS NULL THEN @cal_status_param ELSE C.cal_status END,
				C.cal_telefono = A.cal_telefono,
				C.cal_telefono2 = A.cal_telefono2,
				C.cal_telefono3 = A.cal_telefono3,
				C.cal_telefono4 = A.cal_telefono4,
				C.cal_telefono5 = A.cal_telefono5,
				C.Dato1 = A.Dato1,
				C.Dato2 = A.Dato2,
				C.Dato3 = A.Dato3,
				C.Dato4 = A.Dato4,
				C.Dato5 = A.Dato5,
				C.dialPrefix = A.dialPrefix,
				C.list_id = A.list_id,
				C.cal_fechaDial = case when ISNULL(B.cal_status, 0) = 1 then C.cal_fechaDial else A.cal_fechaDial end,
				C.Region = A.Region,
				C.Localidad = A.Localidad,
				C.international = A.international,
				C.recycledByResult = @emtpy,
				C.recycledByDisposition = 0,
				C.recyclePhone = 0,
				C.recycleType = 1
				,C.iZonaHoraria=A.iZonaHoraria,C.iZonaHoraria_verano=A.iZonaHoraria_verano
				,C.iZonaHoraria2=A.iZonaHoraria2,C.iZonaHoraria_verano2=A.iZonaHoraria_verano2
				,C.iZonaHoraria3=A.iZonaHoraria3,C.iZonaHoraria_verano3=A.iZonaHoraria_verano3
				,C.iZonaHoraria4=A.iZonaHoraria4,C.iZonaHoraria_verano4=A.iZonaHoraria_verano4
				,C.iZonaHoraria5=A.iZonaHoraria5,C.iZonaHoraria_verano5=A.iZonaHoraria_verano5
				' + @columnsIAQuntum + '
			FROM ' + QUOTENAME(@tableName) + ' A
			LEFT JOIN dbo.ccoWorkingTable B WITH (ROWLOCK, UPDLOCK, READPAST) ON A.callout_id = B.callout_id AND B.cal_status <= 2
			INNER JOIN dbo.ccoCallsOutSource C WITH (ROWLOCK, UPDLOCK) ON A.callout_id = C.callout_id';
			
			SET @paramDef = N'@cal_status_param TINYINT, @emtpy varchar(1)';
			EXEC sp_executesql @sql, @paramDef, @cal_status_param = @cal_status, @emtpy= @emtpy;
		END
		ELSE IF @action = 6
		BEGIN
			DECLARE @today DATE = CONVERT(DATE, GETDATE());

			SET @sql = '
		UPDATE B
		SET B.list_id = A.list_id
		FROM ' + QUOTENAME(@tableName) + ' A
		INNER JOIN ccoCallsOutSource C WITH (NOLOCK)  ON A.callout_id = C.callout_id
		INNER JOIN ccoWorkingTable B WITH (NOLOCK)    ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id
		WHERE B.list_id <> A.list_id;


		  UPDATE ld WITH (ROWLOCK) SET ld.canBeRecycled = 0
		  FROM ' + QUOTENAME(@tableName) + ' t
		  LEFT JOIN ccoWorkingTable wt WITH (ROWLOCK, UPDLOCK, READPAST) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
		  INNER JOIN ccoLogDials ld WITH (ROWLOCK, UPDLOCK, INDEX(IX_LogDials_cam_tipo_fecha_callout)) ON ld.cam_id = t.cam_id and ld.callout_id = t.callout_id
		  WHERE wt.callout_id IS NULL AND ld.fecha >= @today AND (ld.canBeRecycled=1 or ld.canBeRecycled is null);
	 
		  UPDATE co WITH (ROWLOCK) SET co.canBeRecycled = 0
		  FROM ' + QUOTENAME(@tableName) + ' t
		  LEFT JOIN ccoWorkingTable wt WITH (ROWLOCK, UPDLOCK, READPAST) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
		  INNER JOIN ccoCallsOut co WITH (ROWLOCK, UPDLOCK) ON co.callout_id = t.callout_id
		  WHERE wt.callout_id IS NULL AND co.cal_Inicio >= @today AND (co.canBeRecycled=1 or co.canBeRecycled is null);
		  ';
			--print(@sql)
			EXEC sp_executesql @sql, N'@today DATE', @today=@today;
		END
		ELSE IF @action = 7
		BEGIN       

			-- Contar registros inválidos
			SET @sql = '
			SELECT @cnt = COUNT(*)
			FROM ' + QUOTENAME(@tableName) + ' A
			LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
				ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
			WHERE B.callout_id IS NULL and A.callout_id > 0;';

			EXEC sp_executesql @sql, N'@cnt INT OUTPUT', @cnt = @count OUTPUT;

			-- Insertar en ccRIALogPhones los registros sin match
			SET @sql = '
			INSERT INTO ccRIALogPhones(load_id, cal_key, telefono, tipoMov, motivo,internationalRecords)
			SELECT @idLoad, A.cal_Key, @emtpy, 2, @motivo,@internationalRecords
			FROM ' + QUOTENAME(@tableName) + ' A
			LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
				ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
			WHERE B.callout_id IS NULL;';

			EXEC sp_executesql @sql,
				N'@idLoad INT, @motivo NVARCHAR(200),@emtpy varchar(1),@internationalRecords int',
				@idLoad = @idLoad,
				@motivo = @motivo,
				@internationalRecords =@internationalRecords,
				@emtpy=@emtpy;

			-- Eliminar los registros sin match
			SET @sql = '
			DELETE A
			FROM ' + QUOTENAME(@tableName) + ' A
			LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
				ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
			WHERE B.callout_id IS NULL;';

			EXEC(@sql);

			-- Retornar el count como resultado
			SELECT @count AS RegistrosEliminados;
		END
		ELSE IF @action = 8
		BEGIN
			

			-- Contar total de registros antes del borrado
			SET @sql = '
			SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@tableName) + ';';
		
			EXEC sp_executesql @sql, N'@cnt INT OUTPUT', @cnt = @count OUTPUT;

			-- Log en ccRIALogPhones todos los registros de la tabla temporal
			SET @sql = '
			INSERT INTO ccRIALogPhones(load_id, cal_key, telefono, tipoMov, motivo,internationalRecords)
			SELECT @idLoad, cal_Key, @emtpy, 2, @motivo,@internationalRecords FROM ' + QUOTENAME(@tableName) + ';';

			EXEC sp_executesql @sql,
					N'@idLoad INT, @motivo NVARCHAR(200),@emtpy varchar(1),@internationalRecords int',
				@idLoad = @idLoad,
				@motivo = @motivo,
				@internationalRecords =@internationalRecords,
				@emtpy=@emtpy;

			-- Eliminar todos los registros de la tabla temporal
			SET @sql = 'DELETE FROM ' + QUOTENAME(@tableName) + ';';
			EXEC(@sql);

			-- Retornar el número de registros eliminados
			SELECT @count AS RegistrosEliminados;
		END
		ELSE IF @action = 9 BEGIN
			
			DECLARE @country TINYINT;
			SELECT @country = CONVERT(TINYINT, valor) FROM ccSettings WITH (NOLOCK) WHERE setting_id = 104;
			if @country =1 begin
				select @zipCodeSchedule=zipCodeSchedule from ccCampsExtend where cam_id =@cam_id
			end
			if @zipCodeSchedule is null begin
				set @zipCodeSchedule=0
			end

			SET @sql = '
		UPDATE T SET 
			iZonaHoraria = CASE 
				WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)            
				ELSE dbo.fnGetTimeZone(T.cal_telefono,  0) END,
	 
			iZonaHoraria_verano = CASE 
			  WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)          
				ELSE dbo.fnGetTimeZone(T.cal_telefono,  1) END,
	 
			iZonaHoraria2 = CASE 
				WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)            
				ELSE dbo.fnGetTimeZone(T.cal_telefono2,  0) END,
	 
			iZonaHoraria_verano2 = CASE 
			  WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)          
				ELSE dbo.fnGetTimeZone(T.cal_telefono2,  1) END,

			iZonaHoraria3 = CASE 
				WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)            
				ELSE dbo.fnGetTimeZone(T.cal_telefono3,  0) END,
	 
			iZonaHoraria_verano3 = CASE 
			  WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)          
				ELSE dbo.fnGetTimeZone(T.cal_telefono3,  1) END,

			iZonaHoraria4 = CASE 
				WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)            
				ELSE dbo.fnGetTimeZone(T.cal_telefono4,  0) END,
	 
			iZonaHoraria_verano4 = CASE 
			  WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)          
				ELSE dbo.fnGetTimeZone(T.cal_telefono4,  1) END,

			iZonaHoraria5 = CASE 
				WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)            
				ELSE dbo.fnGetTimeZone(T.cal_telefono5,  0) END,
	 
			iZonaHoraria_verano5 = CASE 
			  WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
				WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)          
				ELSE dbo.fnGetTimeZone(T.cal_telefono5,  1) END

		FROM ' + QUOTENAME(@tableName) + ' T
		OUTER APPLY dbo.fnGetTimeZoneByZip(T.Dato1) AS Z
		'
		EXEC sp_executesql @sql,
				N'@zipCodeSchedule bit,@country TINYINT,@emtpy varchar(1)',
				@zipCodeSchedule = @zipCodeSchedule,
				@country = @country,
				@emtpy = @emtpy

		--print(@sql)
		END
		ELSE IF @action = 10
		BEGIN
			SET @sql = 'DELETE FROM ' + QUOTENAME(@tableName) + ' WHERE callout_id = 0;';    
			EXEC sp_executesql @sql;
		END
		 ELSE IF @action = 11 BEGIN
					
			SET @sql = '
		UPDATE T SET 
			international=@internationalRecords
		FROM ' + QUOTENAME(@tableName) + ' T
		'
		EXEC sp_executesql @sql,
				N'@internationalRecords int',         
				@emtpy = @emtpy

		END
		

		ELSE
		BEGIN
			RAISERROR('Acción inválida: %d. Use 1 = UpdateOutSource, 2 = UpdateLogDials, 3 = UpdateCallsOut, 4 = UpdateInternational', 16, 1, @action);
			RETURN;
		END
	END