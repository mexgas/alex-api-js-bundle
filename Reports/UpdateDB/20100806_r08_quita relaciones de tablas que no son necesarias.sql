/*
Autor: Armando Rodriguez
Fecha: 2010/08/06
Descripcion: Actualizacion de los jobs de exp_jobs, para corregir errores,quita relaciones inecesarias de las tablas y quita identity de tabla ccocallsoutsource
Version requerida: 7
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '8'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='update exp_jobs set useCCenInCNX = 1 where Description= ''Borra guardados'''
	EXEC(@Sql)

 	set @Sql='update exp_jobs set useCCenInCNX = 1 where Description= ''ccloglogin'''
	EXEC(@Sql)

 	set @Sql='update exp_jobs set useCCenInCNX = 1 where Description= ''cclogAgentesDia'''
	EXEC(@Sql)

 	set @Sql='update exp_jobs set useCCenInCNX = 1, days=''1111111'', useCCRepInDes = 1 where Description= ''cclogtransfers'''
	EXEC(@Sql)

 	set @Sql='update exp_jobs set useCCenInCNX = 1 where Description= ''ccspGenCatalogos'''
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.ccLogAgentesDia
	DROP CONSTRAINT FK_ccLogAgentesDia_ccTipoStatusAgente'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.ccoDialers
	DROP CONSTRAINT FK_ccoDialers_cstoProvedor'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.cstoTarifa
	DROP CONSTRAINT FK_cstoTarifa_cstoProvedor'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.cstoTarifa
	DROP CONSTRAINT FK_cstoTarifa_cstoTipoLlamada'
	EXEC(@Sql)

 	set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenSession @start, @end
select * from ccgensession where login >= @start and login < @end'' where description = ''ccspGenSession'''
	EXEC(@Sql)

 		set @Sql='Alter PROCEDURE [dbo].[ccspGenAgentStatusSepHourNotReady]
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
		WHERE  fecha > DATEADD(hh, 1, CONVERT(datetime, CONVERT(varchar(13), DATEADD(ss, -tstatus, fecha), 121) + '':00'', 121))
			AND fecha between @start_date and @end_date
		ORDER BY fecha
	
	OPEN Log_Cursor
	FETCH NEXT FROM Log_Cursor INTO @user_id, @status_id, @duracion, @end_time, @start_time

	WHILE @@fetch_status = 0 
	BEGIN
		SELECT @base_hour = DATEADD(hh, 1, CONVERT(datetime, CONVERT(varchar(13), @start_time, 121) + '':00'', 121))
		SELECT @duracion_rest = DATEDIFF(s, @base_hour, @end_time)
		SELECT @full_hours = @duracion_rest / 3600
		select @timetot = @duracion
	
		set @sql = ''INSERT INTO ccLogAgentesNotReady ([user_id], tiponotready_id, tstatus, fecha, separado) VALUES ('' + convert(varchar(5),@user_id) +  '','' + convert(varchar(5),@status_id) + '','' + convert(varchar(5),convert(int,DATEDIFF(s, @start_time, @base_hour)))+ '','' + char(0x27) + convert(varchar(20),@base_hour,120) + char(0x27) + '', 3)''
		exec sp_sqlexec @sql

		select @timetot = @timetot - DATEDIFF(s, @start_time, @base_hour)
		SELECT @cur_hour = 1
		
		WHILE @cur_hour <= @full_hours
		BEGIN
			set @sql = ''INSERT INTO ccLogAgentesNotReady ([user_id], tiponotready_id, tstatus, fecha, separado) VALUES ('' + convert(varchar(5),@user_id) + '','' + convert(varchar(5),@status_id) + '', 3600,'' + char(0x27) + convert(varchar(20),DATEADD(hh, @cur_hour, @base_hour),120) + char(0x27) + '', 2)''
			exec sp_sqlexec @sql

			select @timetot = @timetot - 3600
			SELECT @cur_hour = @cur_hour + 1
		END

		--print(''UPDATE ccLogAgentesNotReady SET tstatus = ('' + convert(varchar(10),@duracion_rest) + '' % 3600) - 1, separado = 1 WHERE [user_id]= '' + convert(varchar(5),@user_id) + '' AND tiponotready_id= '' + convert(varchar(5),@status_id) + '' AND fecha= '' + convert(varchar(20),@end_time,120) + '' AND separado =0'')
		set @sql = ''UPDATE ccLogAgentesNotReady SET tstatus = ('' + convert(varchar(10),@timetot) + '' % 3600), separado = 1 WHERE [user_id]= '' + convert(varchar(5),@user_id) + '' AND tiponotready_id= '' + convert(varchar(5),@status_id) + '' AND fecha= '' + char(0x27) + convert(varchar(24),@end_time,121) + char(0x27) + '' AND separado =0''
		exec sp_sqlexec @sql

		FETCH NEXT FROM Log_Cursor INTO @user_id, @status_id, @duracion, @end_time, @start_time
	END
	CLOSE Log_Cursor
	DEALLOCATE Log_Cursor
END
'
		EXEC(@Sql)

 		set @Sql='update exp_jobs set readquery = ''declare @server varchar(200)
declare @sql  varchar(8000)
declare @from datetime
declare @to datetime

select @server = valor from ccsettings where setting_id = 22

set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)

set @sql = ''''declare @fec1 as varchar(20)
select @fec1 = max(callout_id) from '''' + @server +''''.dbo.ccocallsoutsource WITH(NOLOCK)
''''
set @sql = @sql + ''''select callout_id,cal_key,cam_id,cal_fechaDial, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, Dato1, Dato2, Dato3, Dato4, Dato5 from ccoCallsOutSource WITH(NOLOCK) where callout_id > @fec1 AND cal_fechadial < '''' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
--print @sql
exec(@sql)

exec ccsp_LogInfo @sql, -19'' where description = ''ccocallsoutsource'' '
	EXEC(@Sql)

 	set @Sql='update z set z.tstatus=0 from cclogagentesnotready z join (select * from(select count(*) cantidad, user_id,tiponotready_id,tstatus,fecha from cclogagentesnotready
group by user_id,tiponotready_id,tstatus,fecha) as a where cantidad > 1) as b on(separado = 1 and z.user_id = b.user_id and z.tiponotready_id=b.tiponotready_id and z.fecha=b.fecha)
'
	EXEC(@Sql)

declare @cantidad int
declare @tabla  AS varchar(20)
SELECT @tabla='ccocallsoutsource'
SELECT @cantidad = count(*) FROM syscolumns c, sysobjects o WHERE c.STATUS & 128 = 128 AND o.id = c.id AND o.name=@tabla 
if @cantidad >0 begin

	set @Sql='CREATE TABLE dbo.Tmp_ccoCallsOutSource
	(
	callout_id int NOT NULL,
	cal_Key varchar(20) NOT NULL,
	cam_id smallint NOT NULL,
	cal_fechaDial smalldatetime NOT NULL,
	cal_telefono varchar(19) NOT NULL,
	cal_telefono2 varchar(19) NOT NULL,
	cal_telefono3 varchar(19) NOT NULL,
	cal_telefono4 varchar(19) NOT NULL,
	cal_telefono5 varchar(19) NOT NULL,
	[Dato1] [varchar](255) NOT NULL,
	[Dato2] [varchar](255) NOT NULL,
	[Dato3] [varchar](255) NOT NULL,
	[Dato4] [varchar](255) NOT NULL,
	[Dato5] [varchar](255) NOT NULL
	)  ON [PRIMARY]'
	EXEC(@Sql)

 	set @Sql='IF EXISTS(SELECT * FROM dbo.ccoCallsOutSource)
	 EXEC(''INSERT INTO dbo.Tmp_ccoCallsOutSource (callout_id, cal_Key, cam_id, cal_fechaDial)
		SELECT callout_id, cal_Key, cam_id, cal_fechaDial FROM dbo.ccoCallsOutSource WITH (HOLDLOCK TABLOCKX)'')'
	EXEC(@Sql)

 	set @Sql='DROP TABLE dbo.ccoCallsOutSource'
	EXEC(@Sql)

	set @Sql='alter table dbo.Tmp_ccoCallsOutSource
 add constraint DF_ccoCallsOutSource_cal_telefono default ('''') for cal_telefono'
	EXEC(@Sql)
	set @Sql='alter table dbo.Tmp_ccoCallsOutSource
 add constraint DF_ccoCallsOutSource_cal_telefono2 default ('''') for cal_telefono2'
	EXEC(@Sql)
	set @Sql='alter table dbo.Tmp_ccoCallsOutSource
 add constraint DF_ccoCallsOutSource_cal_telefono3 default ('''') for cal_telefono3'
	EXEC(@Sql)
	set @Sql='alter table dbo.Tmp_ccoCallsOutSource
 add constraint DF_ccoCallsOutSource_cal_telefono4 default ('''') for cal_telefono4'
	EXEC(@Sql)
	set @Sql='alter table dbo.Tmp_ccoCallsOutSource
 add constraint DF_ccoCallsOutSource_cal_telefono5 default ('''') for cal_telefono5'
	EXEC(@Sql)

	set @Sql='alter table dbo.Tmp_ccoCallsOutSource
 add constraint DF_ccoCallsOutSource_Dato1 default ('''') for [Dato1]'
	EXEC(@Sql)
	set @Sql='alter table dbo.Tmp_ccoCallsOutSource
 add constraint DF_ccoCallsOutSource_Dato2 default ('''') for [Dato2]'
	EXEC(@Sql)
	set @Sql='alter table dbo.Tmp_ccoCallsOutSource
 add constraint DF_ccoCallsOutSource_Dato3 default ('''') for [Dato3]'
	EXEC(@Sql)
	set @Sql='alter table dbo.Tmp_ccoCallsOutSource
 add constraint DF_ccoCallsOutSource_Dato4 default ('''') for [Dato4]'
	EXEC(@Sql)
	set @Sql='alter table dbo.Tmp_ccoCallsOutSource
 add constraint DF_ccoCallsOutSource_Dato5 default ('''') for [Dato5]'
	EXEC(@Sql)

 	set @Sql='EXECUTE sp_rename N''dbo.Tmp_ccoCallsOutSource'', N''ccoCallsOutSource'', ''OBJECT'''
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.ccoCallsOutSource ADD CONSTRAINT
	PK_ccoCallsOutSource PRIMARY KEY CLUSTERED 
	(
	callout_id
	) WITH( PAD_INDEX = OFF, FILLFACTOR = 90, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
'
	EXEC(@Sql)

 	set @Sql='CREATE NONCLUSTERED INDEX IX_ccoCallsOutSource_1 ON dbo.ccoCallsOutSource
	(
	cam_id
	) WITH( PAD_INDEX = OFF, FILLFACTOR = 90, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
'
	EXEC(@Sql)

 	set @Sql='CREATE NONCLUSTERED INDEX IX_ccoCallsOutSource_2 ON dbo.ccoCallsOutSource
	(
	cal_Key
	) WITH( PAD_INDEX = OFF, FILLFACTOR = 90, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
'
	EXEC(@Sql)

 	set @Sql='CREATE NONCLUSTERED INDEX IX_ccoCallsOutSource_5 ON dbo.ccoCallsOutSource
	(
	cal_fechaDial DESC
	) WITH( PAD_INDEX = OFF, FILLFACTOR = 90, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccoCallsOutSource_10] ON [dbo].[ccoCallsOutSource] ([Dato1]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccoCallsOutSource_3] ON [dbo].[ccoCallsOutSource] ([Dato3]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccoCallsOutSource_4] ON [dbo].[ccoCallsOutSource] ([cal_telefono]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccoCallsOutSource_6] ON [dbo].[ccoCallsOutSource] ([cal_telefono2]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccoCallsOutSource_7] ON [dbo].[ccoCallsOutSource] ([cal_telefono3]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccoCallsOutSource_8] ON [dbo].[ccoCallsOutSource] ([cal_telefono4]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccoCallsOutSource_9] ON [dbo].[ccoCallsOutSource] ([cal_telefono5]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)
end



------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC]
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off


