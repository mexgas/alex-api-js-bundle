CREATE PROCEDURE [dbo].[ccspTwitterConfiguration]     @Option AS SMALLINT,
												   @InboundId as INT
		AS
		BEGIN
			set nocount on
			IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type 
			BEGIN
				IF @InboundId IS NOT NULL
					BEGIN
						SELECT maxDownloadTweetsNumber AS maxDownloadTweetsNumber FROM ccInbound WHERE Inbound_id = @InboundId 
					END
				ELSE
					BEGIN
						raiserror('ERROR. No existe una campa?a de salida con el id especificado', 18, 1)
					END	
			END
		END