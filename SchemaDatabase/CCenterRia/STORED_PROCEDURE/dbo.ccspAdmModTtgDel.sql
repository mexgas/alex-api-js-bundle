CREATE PROCEDURE ccspAdmModTtgDel
@id int
AS
DELETE ccTimetabledetail
 WHERE timetable=@id
DELETE ccTimetable
 WHERE [id] = @id