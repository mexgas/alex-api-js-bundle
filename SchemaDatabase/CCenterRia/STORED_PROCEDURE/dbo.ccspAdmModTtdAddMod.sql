CREATE PROCEDURE ccspAdmModTtdAddMod
@id int,
@wd tinyint,
@type tinyint,
@start1 datetime,
@end1 datetime,
@start2 datetime,
@end2 datetime
AS
DECLARE @testid int
SELECT @testid=timetable FROM ccTimetabledetail
 WHERE timetable=@id AND [weekday]=@wd
IF (@testid=NULL)
  BEGIN
	IF (@type>0)
	BEGIN
		INSERT ccTimetabledetail (timetable, [weekday], type, start1, end1, start2, end2)
		 VALUES(@id, @wd, @type, @start1, @end1, @start2, @end2)
	END
  END
ELSE
  BEGIN
	IF (@type>0)
	BEGIN	
		UPDATE ccTimetabledetail
		  SET type=@type, start1=@start1, end1=@end1, start2=@start2, end2=@end2
		  WHERE timetable=@id AND [weekday]=@wd
	END
	ELSE
	BEGIN
		DELETE ccTimetabledetail
		  WHERE timetable=@id AND [weekday]=@wd
	END
  END