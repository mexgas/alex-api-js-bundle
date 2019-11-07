CREATE PROCEDURE ccspAdmModTtdList 
@id int
AS
SELECT [weekday], type, start1, end1, start2, end2 FROM ccTimetabledetail
 WHERE timetable=@id