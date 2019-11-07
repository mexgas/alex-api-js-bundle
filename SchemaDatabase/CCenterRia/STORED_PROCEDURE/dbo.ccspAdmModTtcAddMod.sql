CREATE PROCEDURE ccspAdmModTtcAddMod
@user_id smallint,
@day datetime,
@override bit,
@type tinyint,
@start1 datetime,
@end1 datetime,
@start2 datetime,
@end2 datetime
AS
DECLARE @testid int

SELECT @testid=[user_id] FROM ccTimetablechange
 WHERE [user_id]=@user_id AND [day]=@day

IF (@testid=NULL)
  BEGIN
	INSERT ccTimetablechange ([user_id], [day], [override], type, start1, end1, start2, end2)
	 VALUES(@user_id, @day, @override, @type, @start1, @end1, @start2, @end2)
  END
ELSE
  BEGIN
	UPDATE ccTimetablechange
	  SET  [override]=@override, type=@type, start1=@start1, end1=@end1, start2=@start2, end2=@end2
	  WHERE [user_id]=@user_id AND [day]=@day

  END