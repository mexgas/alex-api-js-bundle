
----------------------------------------------------- BEGIN SMS Masivo Muñoz KR134000  ----------------------------------------------------------------

----------------------------------------------------- BEGIN KR134001-Módulo de segmentos  ----------------------------------------------------------------


SET @process = 'KR134001 CREATE TABLE ccSmsSegments';
SET @sql = '
IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = ''ccSmsSegments'') BEGIN
    CREATE TABLE ccSmsSegments(
        SegmentId INT IDENTITY(1,1) PRIMARY KEY,
        Name VARCHAR(255),
        IsGlobal BIT DEFAULT(0),
        CampaignId SMALLINT DEFAULT (0)
    )
END';
EXEC (@sql);

SET @process = 'KR134001 CREATE TABLE ccSmsConditions FK SegmentId';
SET @sql = '
IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = ''ccSmsConditions'') BEGIN
    CREATE TABLE ccSmsConditions(
        ConditionId INT IDENTITY(1,1) PRIMARY KEY,
        SegmentId INT FOREIGN KEY REFERENCES ccSmsSegments(SegmentId),
        Field VARCHAR(255),
        Operator VARCHAR(2),
        Value VARCHAR(255),
        DailyLimit INT, 
        WeeklyLimit INT
    )
END';
EXEC (@sql);

SET @process = 'KR134001 DROP PROCEDURE ccspSmsSegments';
SET @sql = '
IF EXISTS (SELECT * FROM sys.procedures WHERE name = ''ccspSmsSegments'')
BEGIN
    DROP PROCEDURE ccspSmsSegments
END';
EXEC (@sql);

SET @process = 'KR134001 CREATE PROCEDURE ccspSmsSegments';
SET @sql = '
ALTER PROCEDURE [dbo].[ccspSmsSegments] 
@Action SMALLINT = NULL, 
@CampaignId INT = 0,
@Ids VARCHAR(MAX) = ''''
AS

DECLARE @IdsTemp TABLE (Id INT);
DECLARE @Result TABLE (Names VARCHAR(MAX));
INSERT INTO @IdsTemp SELECT VALUE FROM dbo.fn_RIASplitDelimited(@Ids,'','')

IF @Action IS NOT NULL BEGIN
    IF @Action = 1 BEGIN        -- Get all segments and conditions
        SELECT s.SegmentId, 
               s.Name AS SegmentName, 
               s.IsGlobal AS SegmentIsGlobal,
               s.CampaignId,
               c.ConditionId, 
               c.Field AS ConditionField,
               c.Operator AS ConditionOperator, 
               c.Value AS ConditionValue, 
               c.DailyLimit AS ConditionDailyLimit,
               c.WeeklyLimit AS ConditionWeeklyLimit
        FROM ccSmsSegments s
        LEFT JOIN ccSmsConditions c ON s.SegmentId = c.SegmentId
        ORDER BY s.SegmentId, c.ConditionId;
        RETURN 0
    END
    ELSE IF @Action = 2 BEGIN       -- Assign/unassign segments to/from campaign 
        UPDATE ccSmsSegments
        SET CampaignId = CASE WHEN @CampaignId != 0 THEN @CampaignId ELSE 0 END
        FROM @IdsTemp ids
        WHERE ccSmsSegments.SegmentId = ids.Id

        INSERT INTO @Result
        SELECT ISNULL(segments.Name,'''')
        FROM @IdsTemp ids
        INNER JOIN ccSmsSegments segments ON segments.SegmentId = ids.Id
    END
    SELECT * FROM @Result
END
ELSE BEGIN
    RAISERROR(''Invalid action specified.'', 16, 1);
    RETURN -1;
END';
EXEC (@sql);


      
----------------------------------------------------- END KR134001-Módulo de segmentos ----------------------------------------------------------------
