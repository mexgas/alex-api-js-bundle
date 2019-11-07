CREATE TRIGGER [dbo].[trigZonaHoraria] ON [dbo].[ccoCallsOutSource]
FOR INSERT,UPDATE
AS
SET NOCOUNT ON
begin
if update(cal_telefono) begin
	update ccoCallsOutSource 
	set iZonaHoraria = dbo.fnGetTimeZone(cs.cal_telefono,0),
	iZonaHoraria_verano = dbo.fnGetTimeZone(cs.cal_telefono,1)
	from ccoCallsOutSource cs 
	inner join inserted i
	on cs.callout_id = i.callout_id
end

if update(cal_telefono2) begin
	update ccoCallsOutSource 
	set iZonaHoraria2 = dbo.fnGetTimeZone(cs.cal_telefono2,0),
	iZonaHoraria_verano2 = dbo.fnGetTimeZone(cs.cal_telefono2,1)
	from ccoCallsOutSource cs 
	inner join inserted i
	on cs.callout_id = i.callout_id
end

if update(cal_telefono3) begin
	update ccoCallsOutSource 
	set iZonaHoraria3 = dbo.fnGetTimeZone(cs.cal_telefono3,0),
	iZonaHoraria_verano3 = dbo.fnGetTimeZone(cs.cal_telefono3,1)
	from ccoCallsOutSource cs 
	inner join inserted i
	on cs.callout_id = i.callout_id
end

if update(cal_telefono4) begin
	update ccoCallsOutSource 
	set iZonaHoraria4 = dbo.fnGetTimeZone(cs.cal_telefono4,0),
	iZonaHoraria_verano4 = dbo.fnGetTimeZone(cs.cal_telefono4,1)
	from ccoCallsOutSource cs 
	inner join inserted i
	on cs.callout_id = i.callout_id
end

if update(cal_telefono5) begin
	update ccoCallsOutSource 
	set iZonaHoraria5 = dbo.fnGetTimeZone(cs.cal_telefono5,0),
	iZonaHoraria_verano5 = dbo.fnGetTimeZone(cs.cal_telefono5,1)
	from ccoCallsOutSource cs 
	inner join inserted i
	on cs.callout_id = i.callout_id	
end
end