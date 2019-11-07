CREATE PROCEDURE [dbo].[ccspGenResAgent]
@from AS smalldatetime,
@to AS smalldatetime
AS

 --exec ccsp_LogInfo 'Inicia ccspGenResAgent ', -17

declare @break integer 
declare @pagos integer 
declare @personal integer 

DELETE FROM ccGenResumenAgente WHERE FECHA >= @from AND FECHA < @to

select @break = max(case when descripcion like 'break' then tiponotready_id else -1 end), 
@pagos = max(case when descripcion like 'pagos' then tiponotready_id else -1 end), 
@personal = max(case when descripcion like 'personal' then tiponotready_id else -1 end) 
from cctiponotready 

INSERT INTO ccGenResumenAgente
SELECT 
gss.user_id AS user_id, 
gss.daygroup AS FECHA, 
SUM(gvw.tlog) as SESION, 
CONVERT(varchar(8),MIN(gss.login),108) AS ENTRADA, 
CONVERT(varchar(8),MAX(gss.logout),108) AS SALIDA, 
SUM(gvw.tdialog_in) + SUM(gvw.tnotes_in) + SUM(gvw.tdialog_out)+ SUM(gvw.tnotes_out) AS DLG, 
SUM(gvw.tnot_av) AS ND, 
SUM(gvw.nxfer_out) AS NCALLS, 
SUM(gvw.nxfer_in) AS NCALLSIN, 
SUM(gvw.abnd_a_xfer_in) + SUM(abnd_a_xfer_out) AS NCALLSCORTA, 
SUM(gvw.nanswer_in) + SUM(gvw.nanswer_out) AS NATEND, 
ISNULL(SUM(gci.amount)+ 
SUM(gco.amount),0) AS [NNOCALIF], 
ISNULL(SUM(gen.[BREAK]),0) AS [NDBREAK], 
ISNULL(SUM(gen.[PERSONAL]),0) AS [NDPERSONAL], 
ISNULL(SUM(gen.[PAGOS]),0) AS [NDPAGOS] 
FROM 

( 
SELECT MIN(login) login, MAX(logout) logout, user_id, CASE WHEN DATEPART(hh,login) < 5 THEN 
CAST(CONVERT(varchar(10),DATEADD(day,-1,login),121) +' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),login,121)
+' 00:00:00'AS datetime) END daygroup from ccgensession WHERE CASE WHEN DATEPART(hh,login) < 5 THEN 
CAST(CONVERT(varchar(10),DATEADD(day,-1,login),121) +' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),login,121)
+' 00:00:00'AS datetime) END BETWEEN @from  AND @to 
GROUP BY CASE WHEN DATEPART(hh,login) < 5 THEN 
CAST(CONVERT(varchar(10),DATEADD(day,-1,login),121) +' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),login,121)
+' 00:00:00'AS datetime) END, user_id
) AS gss 

JOIN 
(
  SELECT CASE WHEN ccGenAgent.daygroup IS NOT NULL THEN ccGEnAgent.daygroup 
         WHEN ccGenViewIncall.daygroup IS NOT NULL THEN ccGenViewIncall.daygroup 
         WHEN ccGenViewOutcall.daygroup IS NOT NULL THEN ccGenViewOutcall.daygroup ELSE 0 END AS daygroup,
 CASE WHEN ccGEnAgent.user_id IS NOT NULL THEN ccGEnAgent.user_id 
	 WHEN ccGenViewIncall.user_id IS NOT NULL THEN ccGenViewIncall.user_id 
	 WHEN ccGenViewOutcall.user_id IS NOT NULL THEN ccGenViewOutcall.user_id ELSE - 1 END AS user_id,
 ISNULL(ccGenViewInCall.nxfer, 0) AS nxfer_in, ISNULL(ccGenViewInCall.nanswer, 0) AS nanswer_in, 
 ISNULL(ccGenViewInCall.nabnd_xfer, 0) + ISNULL(ccGenViewInCall.nabnd_ring, 0) + ISNULL(ccGenViewInCall.nabnd_dialog, 0) AS abnd_a_xfer_in,
 ISNULL(ccGenViewInCall.tdialog, 0) AS tdialog_in, ISNULL(ccGenViewInCall.tnotes, 0) AS tnotes_in,
 
 ISNULL(ccGenViewOutCall.nxfer, 0) AS nxfer_out, ISNULL(ccGenViewOutCall.nanswer, 0) AS nanswer_out, 
 ISNULL(ccGenViewOutCall.nabnd_xfer, 0) + ISNULL(ccGenViewOutCall.nabnd_ring, 0) + ISNULL(ccGenViewOutCall.nabnd_dialog, 0) AS abnd_a_xfer_out,
 ISNULL(ccGenViewOutCall.tdialog, 0) AS tdialog_out, ISNULL(ccGenViewOutCall.tnotes, 0) AS tnotes_out, 
 
 ISNULL(ccGenAgent.tnot_av, 0) AS tnot_av, ISNULL(ccGenAgent.tlog, 0) AS tlog
 
 FROM 

(
SELECT CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END daygroup, user_id, 
SUM(tnot_av) tnot_av, SUM(tlog) tlog FROM dbo.ccGenAgent
WHERE 
CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END BETWEEN @from AND @to 
GROUP BY CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END, user_id
)ccGenAgent 
 FULL JOIN 

(
SELECT CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END daygroup, user_id, 
SUM(nxfer) nxfer, SUM(nanswer) nanswer,  SUM(nabnd_xfer) AS nabnd_xfer, SUM(nabnd_ring) AS nabnd_ring, SUM(nabnd_dialog) 
AS nabnd_dialog, SUM(tdialog) AS tdialog, SUM(tnotes) AS tnotes
FROM  dbo.ccGenInCall
WHERE 
CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END BETWEEN @from  AND @to
GROUP BY CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END, user_id 
) ccGenViewIncall 
 ON (ccGenViewIncall.daygroup = ccGenAgent.daygroup AND ccGenViewIncall.[user_id] = ccGenAgent.[user_id]) 

 FULL JOIN 

(
SELECT CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END daygroup, user_id, 
SUM(nxfer) nxfer, SUM(nanswer) nanswer,  SUM(nabnd_xfer) AS nabnd_xfer, SUM(nabnd_ring) AS nabnd_ring, 
SUM(nabnd_dialog) AS nabnd_dialog, SUM(tdialog) AS tdialog, SUM(tnotes) AS tnotes FROM  dbo.ccGenOutCall 
WHERE 
CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END BETWEEN @from AND @to
GROUP BY CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END, user_id 
)ccGenViewOutcall 
 ON (ccGenViewOutcall.daygroup = ccGenAgent.daygroup AND ccGenViewOutcall.[user_id] = ccGenAgent.[user_id])
 OR (ccGenViewOutcall.daygroup = ccGenViewIncall.daygroup AND ccGenViewOutcall.[user_id] = ccGenViewIncall.[user_id])

) gvw 
ON 
gss.[user_id] = gvw.[user_id] 
AND gvw.daygroup = gss.daygroup
JOIN 
( 
SELECT  
CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END daygroup,  
user_id,  
ISNULL(SUM(CASE tiponotready_id WHEN @break THEN [TIME] end),0) AS [BREAK], 
ISNULL(SUM(CASE tiponotready_id WHEN @pagos THEN [TIME] end),0) AS [PAGOS], 
ISNULL(SUM(CASE tiponotready_id WHEN @personal THEN [TIME] end),0) AS [PERSONAL] 
FROM 
ccGenAgentNotReady  
WHERE CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END BETWEEN @from AND @to
GROUP BY CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END, USER_ID 
) 
AS gen 
ON   
gen.daygroup = gss.daygroup AND 
gss.[user_id] = gen.[user_id]  
LEFT OUTER JOIN 
( 
SELECT 
User_id, 
CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END daygroup, 
SUM(CASE calif_id WHEN 0 THEN amount END) AS amount 
FROM 
ccGenInCalif  
WHERE CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END BETWEEN @from AND @to

GROUP BY CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END, USER_ID 
) AS gci 
ON 
gci.daygroup = gss.daygroup 
AND gss.[user_id] = gci.[user_id] 
LEFT OUTER JOIN 
( 
SELECT 
User_id, 
CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END daygroup, 
SUM(CASE calif_id WHEN 0 THEN amount else 0 END) AS amount 
FROM 
ccGenOutCallCalif 
WHERE CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END BETWEEN @from AND @to

GROUP BY CASE WHEN DATEPART(hh,timegroup) < 5 THEN CAST(CONVERT(varchar(10),DATEADD(day,-1,timegroup),121)
+' 00:00:00' AS datetime) ELSE CAST(CONVERT(varchar(10),timegroup,121)+' 00:00:00'AS datetime) END, USER_ID
) AS gco 
ON 
gco.daygroup = gss.daygroup 
AND gss.[user_id] = gco.[user_id] 
GROUP BY gss.daygroup, gss.logout, gss.user_id