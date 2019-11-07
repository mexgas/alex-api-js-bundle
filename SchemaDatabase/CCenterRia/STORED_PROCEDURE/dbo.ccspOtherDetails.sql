CREATE PROCEDURE [dbo].[ccspOtherDetails]
@action as tinyint,
@cam_id as tinyint,
@to as datetime = null
AS
BEGIN
SET ANSI_WARNINGS off
SET NOCOUNT ON
SELECT count(tipoResDial_id) as num, cam_id, tipoResDial_id,
	 disconnectCause, convert(varchar(10),fecha,120) as [fecha]
 FROM ccoLogDials
 WHERE tipoResDial_id = 8
 AND cam_id = @cam_id
 AND convert(varchar(10),fecha,120) = convert(varchar(10),GETDATE(),120)
 group by cam_id, tipoResDial_id, disconnectCause, convert(varchar(10),fecha,120)
END