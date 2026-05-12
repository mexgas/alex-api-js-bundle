ALTER PROCEDURE [dbo].[ccsp_ManualCallGetRotativeAni]
@phones VARCHAR(MAX),
@camId INT
AS
set nocount on
DECLARE @ManualCallANIMode SMALLINT

SELECT @ManualCallANIMode = ISNULL(ManualCallANIMode, 0) FROM ccCampsExtend WHERE cam_id = @camId;

IF(@ManualCallANIMode > 0) BEGIN
	DECLARE @aniId INT;
	DECLARE @rotativeAlgo INT;
	DECLARE @Anis TABLE(id INT, pid VARCHAR(2), phone VARCHAR(32), ani VARCHAR(32));

	SELECT @aniId = [idAniListManual], @rotativeAlgo = [rotativeAlgorithmManual] FROM ccCamps WHERE cam_id = @camId;

	INSERT @Anis
	EXEC ccsp_DLRGetRotativeANI @callout_id=0, @phones=@phones, @aniList=@aniId,@algo=@rotativeAlgo;

	IF EXISTS(SELECT 1 FROM @Anis) BEGIN
		SELECT TOP 1 ani FROM @Anis
	END ELSE IF EXISTS (SELECT valor FROM ccSettings WHERE setting_id = 177) BEGIN
		SELECT * FROM ccSettings WHERE setting_id = 177
	END ELSE BEGIN
		SELECT ''
	END
END
ELSE BEGIN
	SELECT ''
END
set nocount off