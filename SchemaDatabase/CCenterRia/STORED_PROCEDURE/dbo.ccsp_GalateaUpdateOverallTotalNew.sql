CREATE PROCEDURE [dbo].[ccsp_GalateaUpdateOverallTotalNew] @CampId AS SMALLINT
				AS
				BEGIN
					set nocount on
					if @CampId is not null
						BEGIN
							UPDATE ccCampsNvosCB set OverallTotalNew = ccCampsNvosCB.new where id = @CampId
						END
				END