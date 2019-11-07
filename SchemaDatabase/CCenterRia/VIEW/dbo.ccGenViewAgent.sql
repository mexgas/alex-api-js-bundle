CREATE VIEW [dbo].[ccGenViewAgent]
AS
SELECT CASE WHEN ccGEnAgent.timegroup IS NOT NULL THEN ccGEnAgent.timegroup WHEN ccGenViewIncall.timegroup IS NOT NULL 
 THEN ccGenViewIncall.timegroup WHEN ccGenViewOutcall.timegroup IS NOT NULL THEN ccGenViewOutcall.timegroup ELSE 0 END AS timegroup,
 CASE WHEN ccGEnAgent.user_id IS NOT NULL THEN ccGEnAgent.user_id WHEN ccGenViewIncall.user_id IS NOT NULL 
 THEN ccGenViewIncall.user_id WHEN ccGenViewOutcall.user_id IS NOT NULL THEN ccGenViewOutcall.user_id ELSE - 1 END AS user_id,
 ISNULL(dbo.ccGenViewInCall.nxfer,0)AS nxfer_in,ISNULL(dbo.ccGenViewInCall.nanswer,0)AS nanswer_in,ISNULL(dbo.ccGenViewInCall.nabnd_xfer,0)
 AS nabnd_xfer_in,ISNULL(dbo.ccGenViewInCall.nabnd_ring,0)AS nabnd_ring_in,ISNULL(dbo.ccGenViewInCall.nabnd_dialog,0)AS nabnd_dlg_in,
 ISNULL(dbo.ccGenViewInCall.nabnd_xfer,0)+ ISNULL(dbo.ccGenViewInCall.nabnd_ring,0)+ ISNULL(dbo.ccGenViewInCall.nabnd_dialog,0)AS abnd_a_xfer_in,
 ISNULL(dbo.ccGenViewInCall.nno_answer,0)AS nno_answer_in,ISNULL(dbo.ccGenViewInCall.nlost,0)AS nlost_in,ISNULL(dbo.ccGenViewInCall.tdialog,0)
 AS tdialog_in,ISNULL(dbo.ccGenViewInCall.tnotes,0)AS tnotes_in,ISNULL(dbo.ccGenViewInCall.tring,0)AS tring_in,ISNULL(dbo.ccGenViewInCall.txfer,0)AS txfer_in,
 ISNULL(dbo.ccGenViewOutCall.nxfer,0)AS nxfer_out,ISNULL(dbo.ccGenViewOutCall.nanswer,0)AS nanswer_out,ISNULL(dbo.ccGenViewOutCall.nabnd_xfer,0)
 AS nabnd_xfer_out,ISNULL(dbo.ccGenViewOutCall.nabnd_ring,0)AS nabnd_ring_out,ISNULL(dbo.ccGenViewOutCall.nabnd_dialog,0)AS nabnd_dlg_out,
 ISNULL(dbo.ccGenViewOutCall.nabnd_xfer,0)+ ISNULL(dbo.ccGenViewOutCall.nabnd_ring,0)+ ISNULL(dbo.ccGenViewOutCall.nabnd_dialog,0)AS abnd_a_xfer_out,
 ISNULL(dbo.ccGenViewOutCall.nno_answer,0)AS nno_answer_out,ISNULL(dbo.ccGenViewOutCall.nlost,0)AS nlost_out,ISNULL(dbo.ccGenViewOutCall.tdialog,0)
 AS tdialog_out,ISNULL(dbo.ccGenViewOutCall.tnotes,0)AS tnotes_out,ISNULL(dbo.ccGenViewOutCall.tring,0)AS tring_out,ISNULL(dbo.ccGenViewOutCall.txfer,0)
 AS txfer_out,ISNULL(dbo.ccGenAgent.nother,0)AS nother,ISNULL(dbo.ccGenAgent.tunknown,0)AS tunknown,ISNULL(dbo.ccGenAgent.tnot_av,0)AS tnot_av,
 ISNULL(dbo.ccGenAgent.tlog,0)AS tlog,ISNULL(dbo.ccGenAgent.treq,0)AS treq,ISNULL(dbo.ccGenAgent.tav,0)AS tav,ISNULL(dbo.ccGenAgent.tother,0)AS tother,
 ISNULL(dbo.ccGenAgent.tprob,0)AS tprob,ISNULL(dbo.ccGenViewInCall.nMoh,0)AS nMoh_in,ISNULL(dbo.ccGenViewOutCall.nMoh,0)AS nMoh_out,
 ISNULL(dbo.ccGenViewInCall.nWHag,0)AS nWHag_in,ISNULL(dbo.ccGenViewOutCall.nWHag,0)AS nWHag_out,ISNULL(dbo.ccGenViewInCall.nWHcl,0)
 AS nWHcl_in,ISNULL(dbo.ccGenViewOutCall.nWHcl,0)AS nWHcl_out
FROM ccGenAgent FULL OUTER JOIN
 dbo.ccGenViewInCall ON dbo.ccGenViewInCall.timegroup=dbo.ccGenAgent.timegroup AND dbo.ccGenViewInCall.user_id=dbo.ccGenAgent.user_id FULL OUTER JOIN
 dbo.ccGenViewOutCall ON dbo.ccGenViewOutCall.timegroup=dbo.ccGenAgent.timegroup AND dbo.ccGenViewOutCall.user_id=dbo.ccGenAgent.user_id