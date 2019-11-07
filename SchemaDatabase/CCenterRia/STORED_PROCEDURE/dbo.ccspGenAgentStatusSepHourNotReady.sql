CREATE PROCEDURE [dbo].[ccspGenAgentStatusSepHourNotReady]
	@start_date	datetime,
	@end_date	datetime
	AS
	BEGIN
		DECLARE @user_id smallint,
			@status_id	tinyint,
			@duracion	int,
			@timetot	int,
			@end_time	datetime,
			@start_time	datetime,
			@base_hour	datetime,
			@sql as varchar (8000),
			@duracion_rest	int,
			@full_hours	int,
			@cur_hour	int

		DECLARE Log_Cursor CURSOR FOR
		SELECT [user_id], tiponotready_id, tstatus, fecha
			, DATEADD(s, -tstatus, fecha) AS start
			FROM ccLogAgentesNotReady 
			WHERE  fecha > DATEADD(hh, 1, CONVERT(datetime, CONVERT(varchar(13), DATEADD(ss, -tstatus, fecha), 121) + ':00', 121))
				AND fecha between @start_date and @end_date
			ORDER BY fecha
		
		OPEN Log_Cursor
		FETCH NEXT FROM Log_Cursor INTO @user_id, @status_id, @duracion, @end_time, @start_time

		WHILE @@fetch_status = 0 
		BEGIN
			SELECT @base_hour = DATEADD(hh, 1, CONVERT(datetime, CONVERT(varchar(13), @start_time, 121) + ':00', 121))
			SELECT @duracion_rest = DATEDIFF(s, @base_hour, @end_time)
			SELECT @full_hours = @duracion_rest / 3600
			select @timetot = @duracion
		
			set @sql = 'INSERT INTO ccLogAgentesNotReady ([user_id], tiponotready_id, tstatus, fecha, separado) VALUES (' + convert(varchar(5),@user_id) +  ',' + convert(varchar(5),@status_id) + ',' + convert(varchar(5),convert(int,DATEDIFF(s, @start_time, @base_hour)))+ ',' + convert(varchar(20),@base_hour,120) + ', 3)'
			exec sp_sqlexec @sql

			select @timetot = @timetot - DATEDIFF(s, @start_time, @base_hour)
			SELECT @cur_hour = 1
			
			WHILE @cur_hour <= @full_hours
			BEGIN
				set @sql = 'INSERT INTO ccLogAgentesNotReady ([user_id], tiponotready_id, tstatus, fecha, separado) VALUES (' + convert(varchar(5),@user_id) + ',' + convert(varchar(5),@status_id) + ', 3600,' + convert(varchar(20),DATEADD(hh, @cur_hour, @base_hour),120) + ', 2)'
				exec sp_sqlexec @sql

				select @timetot = @timetot - 3600
				SELECT @cur_hour = @cur_hour + 1
			END

			--print('UPDATE ccLogAgentesNotReady SET tstatus = (' + convert(varchar(10),@duracion_rest) + ' % 3600) - 1, separado = 1 WHERE [user_id]= ' + convert(varchar(5),@user_id) + ' AND tiponotready_id= ' + convert(varchar(5),@status_id) + ' AND fecha= ' + convert(varchar(20),@end_time,120) + ' AND separado =0')
			set @sql = 'UPDATE ccLogAgentesNotReady SET tstatus = (' + convert(varchar(10),@timetot) + ' % 3600), separado = 1 WHERE [user_id]= ' + convert(varchar(5),@user_id) + ' AND tiponotready_id= ' + convert(varchar(5),@status_id) + ' AND fecha= ' + convert(varchar(20),@end_time,120) + ' AND separado =0'
			exec sp_sqlexec @sql

			FETCH NEXT FROM Log_Cursor INTO @user_id, @status_id, @duracion, @end_time, @start_time
		END
		CLOSE Log_Cursor
		DEALLOCATE Log_Cursor
	END