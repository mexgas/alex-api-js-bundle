CREATE PROCEDURE ccsp_SaveAgentsData
@fecha varchar(12),
@User_id int,
@nXferIN smallint,
@nXferOUT smallint,
@nDialogsIN smallint,
@nDialogsOUT smallint,
@nShortCallIN smallint,
@nShortCallOUT smallint,
@nNoAnswerIN smallint,
@nNoAnswerOUT smallint,
@nHookOnXferIN smallint,
@nHookOnXferOUT smallint,
@nOthers smallint,
@tUnKnown int,
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
declare @Dia as smalldatetime
select @Dia  = convert( smalldatetime, @fecha, 101)
Insert ccDataAgents (User_id, nDialogsIN, nDialogsOut, nXferIN, nXferOut, nShortCallIN, nShortCallOUT,
				nNoAnswerIN, nNoAnswerOUT, nHookOnXferIN, nHookOnXferOUT, nOthers,
				tUnKnown, tNotReady, tReady, tDialog, tXfer, tWrapUp, tOther, tWClient, tRinging, tProblem, fecha)
		Values ( @User_id, @nDialogsIN, @nDialogsOut, @nXferIN, @nXferOut, @nShortCallIN, @nShortCallOUT,
				@nNoAnswerIN, @nNoAnswerOUT, @nHookOnXferIN, @nHookOnXferOUT, @nOthers,
				@tUnKnown,  @tNotReady, @tReady, @tDialog, @tXfer, @tWrapUp, @tOther, @tWClient, @tRinging, @tProblem, @Dia )