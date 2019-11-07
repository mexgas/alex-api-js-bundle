CREATE VIEW [dbo].[ccGenViewInCall]	
AS
SELECT timegroup,user_id,SUM(nxfer)AS nxfer,SUM(nanswer)AS nanswer,SUM(nabnd_xfer)AS nabnd_xfer,SUM(nabnd_ring)AS nabnd_ring,SUM(nabnd_dialog)
 AS nabnd_dialog,SUM(nno_answer)AS nno_answer,SUM(nlost)AS nlost,SUM(tdialog)AS tdialog,SUM(tnotes)AS tnotes,SUM(tring)AS tring,SUM(txfer)AS txfer,
 SUM(nMoh)AS nMoh,SUM(nWHag)AS nWHag,SUM(nWHcl)AS nWHcl
FROM ccGenInCall GROUP BY timegroup,user_id