CREATE PROCEDURE ccspAdmTresAddMod
	@description varchar(20),
	@value smallint
AS

DECLARE @tmpId AS smallint
SELECT @tmpId=[id] FROM ccConfigTreshold WHERE [description]=@description

IF (@tmpId = NULL)
BEGIN
	SELECT @tmpId=ISNULL(MAX([id]),0)+1 FROM ccConfigTreshold
	INSERT ccConfigTreshold ([id], [description], [value]) VALUES (@tmpId, @description, @value)
END
ELSE
BEGIN
	UPDATE ccConfigTreshold SET [value]=@value WHERE [id]=@tmpId
END