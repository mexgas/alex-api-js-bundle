CREATE PROCEDURE ccspAdmModTtcDel
@user_id smallint,
@day datetime
AS
DELETE ccTimetablechange
 WHERE [user_id]=@user_id AND [day]=@day