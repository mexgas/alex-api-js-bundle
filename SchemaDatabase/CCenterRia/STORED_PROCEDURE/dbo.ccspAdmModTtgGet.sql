CREATE PROCEDURE ccspAdmModTtgGet
@id int
AS
SELECT [id], startdate, enddate, fixed, days, [user_id]
 FROM ccTimetable
 WHERE [id] = @id