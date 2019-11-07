CREATE PROCEDURE [dbo].[trsp_AVRSGetExportRecRepository] AS

SET NOCOUNT ON

SELECT par_valor from CCRecorderRIA.dbo.TREC_PARAMETROS with(nolock) where par_id = 65