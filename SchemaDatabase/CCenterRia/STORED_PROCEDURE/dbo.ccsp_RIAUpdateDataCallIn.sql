CREATE procedure [dbo].[ccsp_RIAUpdateDataCallIn]
@calloutid int,
@callid int,
@typecall smallint,
@data1 varchar(100),
@data2 varchar(100),
@data3 varchar(100),
@data4 varchar(100),
@data5 varchar(100)

AS

if @typecall = 1 --Inbound 
begin
	Update DataCallIn set Data=@data1 where CallId=@callid and Description = 'Dato 1'
	Update DataCallIn set Data=@data2 where CallId=@callid and Description = 'Dato 2'
	Update DataCallIn set Data=@data3 where CallId=@callid and Description = 'Dato 3'
	Update DataCallIn set Data=@data4 where CallId=@callid and Description = 'Dato 4'
	Update DataCallIn set Data=@data5 where CallId=@callid and Description = 'Dato 5'
end
	
if @typecall = 2 --Outbound 
begin
	update ccocallsoutsource set Dato1 = @data1,
			Dato2 = @data2,
			Dato3 = @data3,
			Dato4 = @data4,
			Dato5 = @data5 where callout_id = @calloutid
end