/****** Object:  Stored Procedure dbo.trsp_GenGrabacExt    Script Date: 07/10/2009 03:34:54 p.m. ******/




CREATe  PROCEDURE [dbo].[trsp_GenGrabacExt]
@fini as smalldatetime,
@ffin as smalldatetime
 AS

DELETE FROM TREC_GEN_GRABAC_EXT WHERE timegroup BETWEEN @fini AND @ffin

INSERT INTO TREC_GEN_GRABAC_EXT
SELECT  CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + ':00', 121) as timegroup ,extension as extension, 
count(*) as GRABACIONES, SUM(case when duracion<7 then 1 else 0 end) as SHORTCALLS, 
SUM(duracion) as 'DURACION', convert(varchar,SUM(tamano)) as 'TAMANO' from trec_grabacion grab
LEFT JOIN TREC_MONITOR mon ON grab.extension = mon.mon_extension and mon.isIPExt = 0
WHERE CONVERT(smalldatetime, CONVERT(varchar(13), finicio, 121) + ':00', 121) BETWEEN @fini
AND @ffin  GROUP BY CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + ':00', 121), extension  
ORDER BY CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + ':00', 121), extension