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
	IF EXISTS (SELECT * FROM DataCallIn WHERE CallId=@callid )
		DELETE FROM DataCallIn WHERE CallId=@callid

	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data1, 'Dato 1' )
	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data2, 'Dato 2' )
	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data3, 'Dato 3' )
	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data4, 'Dato 4' )
	INSERT INTO DataCallIn (CallId, Data, Description) Values (@callid, @data5, 'Dato 5' )
end
	
if @typecall = 2 --Outbound 
begin
	update ccocallsoutsource set Dato1 = @data1,
			Dato2 = @data2,
			Dato3 = @data3,
			Dato4 = @data4,
			Dato5 = @data5 where callout_id = @calloutid
end