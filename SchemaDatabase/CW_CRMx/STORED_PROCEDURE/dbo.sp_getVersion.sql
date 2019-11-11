-- =============================================
-- Author:		<Miguel Cast>
-- Create date: <2015-FEB-10>
-- Description:	<Get's the CRMx version>
-- =============================================
CREATE PROCEDURE [dbo].[sp_getVersion]
	-- Add the parameters for the stored procedure here
	@directive NVARCHAR(4) = NULL,
	@Version int = 0 output
AS
BEGIN
	IF @directive NOT IN ( 'ALL', 'BD', 'ADM', 'AGT', 'RPT') AND @directive IS NOT NULL
		BEGIN
			SELECT 'Version module not suitable.'
			return (0)
		END
	ELSE
		BEGIN
		if isnull(@Version, 0) = 0
			begin
				SELECT @Version=cast(value as int) FROM settings WHERE id = 1
				select @version Version
				return(@version)
		END
		else begin
			declare @versionActual  int
			SELECT @versionActual=cast(value as int)  FROM settings WHERE id = 1
			if @Version<=@versionActual begin
				select '-3' ID, 'ERROR. Invalid Version for  '+@directive + '. Current Version: ' +@versionActual
			return (0)
			end
			else begin
				update settings set value = @Version where id = 1
			end
		end
	END
END