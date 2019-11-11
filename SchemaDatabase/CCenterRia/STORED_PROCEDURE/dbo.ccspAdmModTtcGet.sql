CREATE PROCEDURE ccspAdmModTtcGet
@user_id smallint,
@day datetime
AS
SELECT nombres + ' ' + apellidopaterno + ' ' + ISNULL(apellidomaterno, ''), [day], [override], type, start1, end1, start2, end2
 FROM ccTimetablechange INNER JOIN ccUsers
		 ON (ccTimetablechange.[user_id]=ccUsers.[user_id])
 WHERE ccTimetablechange.[user_id]=@user_id AND [day]=@day