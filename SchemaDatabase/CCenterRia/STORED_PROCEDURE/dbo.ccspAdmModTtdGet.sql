CREATE PROCEDURE ccspAdmModTtdGet
@id int,
@wd tinyint
AS
SELECT type, start1, end1, start2, end2 FROM ccTimetabledetail
 WHERE timetable=@id AND [weekday]=@wd