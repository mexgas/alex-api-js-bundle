CREATE PROCEDURE ccspAdmModTtcList 
@user_id smallint
AS
SELECT [day], [day], [override]
 FROM ccTimetablechange
 WHERE [user_id] = @user_id