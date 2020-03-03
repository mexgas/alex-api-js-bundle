ALTER TABLE ccCamps ADD holdCall BIT NOT NULL DEFAULT(1)

-----------------------------------------------

CREATE PROCEDURE [dbo].[ccspGalateaGetccCampsData]
@action tinyint,
@cam_id int
AS BEGIN
    IF @action = 1  -- Check if DTMF function is enabled (type int) 
    BEGIN
		select isnull(funcEspDtmf, 0) as FuncEspDtmf from ccCamps where cam_id = @cam_id	
    END
    IF @action = 2  -- Check if hold is enabled (type bit) 
    BEGIN
		select holdCall from ccCamps where cam_id = @cam_id	
    END
END