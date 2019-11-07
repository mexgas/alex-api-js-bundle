CREATE PROCEDURE ccsp_SaveAgentData
@User_id int,
@nXferIN smallint,
@nXferOut smallint,
@nDialogsIN smallint,
@nDialogsOut smallint,
@tNotReady int,
@tReady int,
@tDialog int,
@tXfer int,
@tWrapUp int,
@tOther int,
@tWClient int,
@tRinging int,
@tProblem int
AS
Insert ccDataAgents (User_id, nDialogsIN, nDialogsOut, nXferIN, nXferOut, tNotReady, tReady, tDialog, tXfer, tWrapUp, tOther, tWClient, tRinging, tProblem )
		Values (@User_id, @nDialogsIN, @nDialogsOut, @nXferIN, @nXferOut, @tNotReady, @tReady, @tDialog, @tXfer, @tWrapUp,
			 @tOther, @tWClient, @tRinging, @tProblem )