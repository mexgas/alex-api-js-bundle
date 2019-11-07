CREATE PROCEDURE ccspAdmModUserDel
@id smallint
AS
DECLARE @nTTID bigint

--Delete related entries in Specialist, Timetable, Timetabledetail, Timetablechange
DECLARE cTTD CURSOR FOR
 SELECT [user_id]
 FROM ccTimetable
 WHERE [user_id] = @id
OPEN cTTD
FETCH NEXT FROM cTTD INTO @nTTID
WHILE @@FETCH_STATUS = 0
BEGIN
   DELETE ccTimetabledetail
	WHERE timetable = @nTTID
   FETCH NEXT FROM cTTD INTO @nTTID
END
CLOSE cTTD
DEALLOCATE cTTD
DELETE ccTimetable
	WHERE [user_id] = @id
DELETE ccTimetablechanges
	WHERE [user_id] = @id

DELETE ccUsers
 WHERE [user_id]=@id