CREATE PROCEDURE dbo.ccspGenAgentStatusSepHour
@start_date	datetime,
@end_date	datetime
AS
BEGIN
SET NOCOUNT ON
DECLARE @user_id smallint,
	@status_id	tinyint,
	@duracion	int,
	@timetot	int,
	@end_time	datetime,
	@start_time	datetime,
	@base_hour	datetime,
	@duracion_rest	int,
	@sql as varchar (8000),
	@full_hours	int,
	@cur_hour	int

DECLARE Log_Cursor CURSOR FOR
SELECT DISTINCT [user_id], tipostatusage_id, tstatus, fecha
	, DATEADD(s, -tstatus, fecha) AS start
	FROM ccLogAgentesDia 
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

		set @sql = 'INSERT INTO ccLogAgentesDia ([user_id], tipostatusage_id, tstatus, fecha) VALUES (' + convert(varchar(5),@user_id) +  ',' 
			+ convert(varchar(5),@status_id) + ',' + convert(varchar(5),convert(int,DATEDIFF(s, @start_time, @base_hour)))
			+ ',''' + convert(varchar(24),@base_hour,121) + ''')'
		exec sp_sqlexec @sql

		select @timetot = @timetot - DATEDIFF(s, @start_time, @base_hour)
		SELECT @cur_hour = 1

		WHILE @cur_hour <= @full_hours
		BEGIN
			set @sql = 'INSERT INTO ccLogAgentesDia ([user_id], tipostatusage_id, tstatus, fecha) VALUES (' + convert(varchar(5),@user_id) +  ',' + convert(varchar(5),@status_id) 
			+ ', 3600,''' + convert(varchar(24),DATEADD(hh, @cur_hour, @base_hour),121) + ''')'
			exec sp_sqlexec @sql

			select @timetot = @timetot - 3600
			SELECT @cur_hour = @cur_hour + 1
		END

		set @sql = 'UPDATE ccLogAgentesDia SET tstatus = (' + convert(varchar(10),@timetot) + ' % 3600) WHERE [user_id]=' + convert(varchar(5),@user_id) 
			+ ' AND tipostatusage_id=' + convert(varchar(5),@status_id) + ' AND 
			fecha= ''' + convert(varchar(24),@end_time,121) + ''''

		exec sp_sqlexec @sql
		FETCH NEXT FROM Log_Cursor INTO @user_id, @status_id, @duracion, @end_time, @start_time
	END
CLOSE Log_Cursor
DEALLOCATE Log_Cursor
SET NOCOUNT OFF
END