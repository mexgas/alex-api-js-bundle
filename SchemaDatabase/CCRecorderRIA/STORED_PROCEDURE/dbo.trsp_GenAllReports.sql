CREATE PROCEDURE [dbo].[trsp_GenAllReports] AS
Declare @ffin as smalldatetime, @fini as smalldatetime
SELECT @ffin = CAST(CONVERT(VARCHAR(10), GETDATE(), 121) AS SMALLDATETIME)
SELECT @fini = DATEADD(d,-1,@ffin)

EXEC trsp_GenAgenteExt @fini, @ffin
EXEC trsp_GenDuracion @fini, @ffin
EXEC trsp_GenGrabacExt @fini, @ffin
EXEC trsp_GenGrabacPos @fini, @ffin
EXEC trsp_GenHoraPto @fini, @ffin
EXEC trsp_GenPuntajesMonitor @fini, @ffin
EXEC trsp_GenPuntajesAgente @fini, @ffin
EXEC trsp_GenPuntajesSupervisor @fini, @ffin