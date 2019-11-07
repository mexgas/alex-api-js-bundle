CREATE PROCEDURE ccspAdmModTtgList
@user_id int
AS
SELECT [id], startdate, enddate, fixed, days
 FROM ccTimetable
 WHERE [user_id]=@user_id