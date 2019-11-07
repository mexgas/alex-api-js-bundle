CREATE PROCEDURE ccspAdmModTtgMod
@id int,
@start datetime,
@end datetime,
@fixed bit,
@days smallint
AS
UPDATE ccTimetable
 SET startdate=@start, enddate=@end, fixed=@fixed, days=@days FROM ccTimetable
 WHERE [id] = @id