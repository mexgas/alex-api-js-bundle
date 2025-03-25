USE CCenterRIA

-- Add columns to ccCampsExtend if they do not already exist
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'ccCampsExtend' AND COLUMN_NAME = 'RescheduledSurveyAI')
BEGIN
    ALTER TABLE ccCampsExtend ADD RescheduledSurveyAI BIT DEFAULT 0 NOT NULL;
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'ccCampsExtend' AND COLUMN_NAME = 'ImmediateSurveyAI')
BEGIN
    ALTER TABLE ccCampsExtend ADD ImmediateSurveyAI BIT DEFAULT 0 NOT NULL;
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'ccCampsExtend' AND COLUMN_NAME = 'ApplyRescheduledSurveyForCompletedCallsAI')
BEGIN
    ALTER TABLE ccCampsExtend ADD ApplyRescheduledSurveyForCompletedCallsAI BIT DEFAULT 0 NOT NULL;
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'ccCampsExtend' AND COLUMN_NAME = 'EnableCallRecordingAI')
BEGIN
    ALTER TABLE ccCampsExtend ADD EnableCallRecordingAI BIT DEFAULT 0 NOT NULL;
END
