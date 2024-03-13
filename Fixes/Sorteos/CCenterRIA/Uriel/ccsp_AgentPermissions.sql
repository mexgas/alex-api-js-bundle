USE [CCenterRIA]
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ccsp_AgentPermissions]
	@user_id int
AS
BEGIN
	SET NOCOUNT ON;
	SELECT distinct cast(dialMask & 1 as int) as 'RestringeCelular',
	            cast( (dialMask & 2) /2 as int) as 'Restringeld', cast((dialMask & 4) / 4 as int) as 'RestringeLocal',
	            cast( xfermask as int) as 'RecibeTransferencia', cast(CanChangeStatus as tinyint) CanChangeStatus,
	            cast(XferAgents as tinyint) XferAgents,
	            cast(isnull(startStopRecording,0) as tinyint) StartStopRecording,
				isnull(AllowPlayRecordsOnCallHistory, 1) AllowPlayRecordsOnCallHistory,
				AllowMarks
	            FROM ccUsers u left join ccRIAAgentsPermissions p on u.User_id = p.AgentId
	            WHERE User_id = @user_id
END
GO
