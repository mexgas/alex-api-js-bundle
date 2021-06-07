CREATE PROCEDURE [dbo].[ccSpGalateaSeriesUSA]
	@actionId int 
AS
BEGIN	
	SET NOCOUNT ON;
	if @actionId= 1 begin
		if exists(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SeriesUSA') begin
			truncate table SeriesUSA
		end
		else begin			
			CREATE TABLE SeriesUSA(area varchar(5), prefix varchar(5), tz_standar float,
			tz_dayligth float, nxx_type varchar(5), city varchar(50),county varchar(50),state varchar(50));
		end		

	end
	else if @actionId= 2 begin
		if exists(select * from SeriesUSA) begin
			truncate table ccTimeZoneAreaUsaDetail
			insert into ccTimeZoneAreaUsaDetail

			select distinct A.area, A.prefix,B.tz_id as tz_standar,C.tz_id as tz_dayligth,A.city+', '+A.county+', '+A.state 
							,A.nxx_type			
							from SeriesUSA A
							left join ccTimeZones B on A.tz_standar=B.tz_offset
							left join ccTimeZones C on A.tz_dayligth=C.tz_offset			
			where A.nxx_type !='';
		end
	end
	else if @actionId=3 begin			
		select valor from ccsettings where setting_id = 228
	end
END