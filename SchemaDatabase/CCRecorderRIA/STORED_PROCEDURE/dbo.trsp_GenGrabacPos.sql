/****** Object:  Stored Procedure dbo.trsp_GenGrabacPos    Script Date: 07/10/2009 03:34:54 p.m. ******/




CREATE PROCEDURE [dbo].[trsp_GenGrabacPos]
@fini as smalldatetime,
@ffin as smalldatetime
 AS

DELETE FROM TREC_GEN_GRABAC_POS WHERE timegroup BETWEEN @fini AND @ffin

INSERT INTO TREC_GEN_GRABAC_POS
SELECT  CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + ':00', 121) as timegroup,pos_pc as extension, 
count(*) as GRABACIONES, SUM(case when duracion<7 then 1 else 0 end) as SHORTCALLS, 
SUM(duracion) as 'DURACION', convert(varchar,SUM(tamano)) as 'TAMANO' from trec_grabacion 
WHERE CONVERT(smalldatetime, CONVERT(varchar(13), finicio, 121) + ':00', 121) BETWEEN @fini 
AND @ffin  AND pos_pc IS NOT NULL AND pos_pc <> ''
GROUP BY CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + ':00', 121), pos_pc  
ORDER BY CONVERT(smalldatetime, CONVERT(char(13), finicio, 121) + ':00', 121), pos_pc