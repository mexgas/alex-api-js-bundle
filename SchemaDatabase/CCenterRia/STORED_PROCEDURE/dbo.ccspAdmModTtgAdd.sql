CREATE PROCEDURE ccspAdmModTtgAdd
@user_id smallint,
@start datetime,
@end datetime,
@fixed bit,
@days smallint
AS
DECLARE @id int
SELECT @id=[id] FROM ccTimetable WHERE [user_id]=@user_id AND startdate=@start
IF (@id = NULL)
BEGIN
	SELECT @id=ISNULL(MAX([id]),0) + 1 FROM ccTimetable
	INSERT INTO ccTimetable ([id], [user_id], startdate, enddate, fixed, days)
	 VALUES (@id, @user_id, @start, @end, @fixed, @days)
END
SELECT 'newID'=@id