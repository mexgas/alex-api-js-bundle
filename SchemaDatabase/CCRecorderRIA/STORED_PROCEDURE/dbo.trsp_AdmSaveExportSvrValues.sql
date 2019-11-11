-- =============================================
-- Author:		Javier Ruelas
-- Create date: October 2012
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[trsp_AdmSaveExportSvrValues]
	-- Add the parameters for the stored procedure here

@sExportHour nvarchar(MAX),
@sAudioFormat nvarchar(MAX),
@sExportPath nvarchar(MAX),
@sSystemUser nvarchar(MAX),
@sSystemPass nvarchar(MAX),
@sExportStartIn nvarchar(MAX),
@sFtpServer nvarchar(MAX),
@sFtpUser nvarchar(MAX),
@sFtpPass nvarchar(MAX),
@sFtpPort nvarchar(MAX),
@sFtpTimeOut nvarchar(MAX),
@sFtpMode nvarchar(MAX),
@sExportHistory nvarchar(MAX),
@sExportType nvarchar(MAX),
@sCustomExport nvarchar(MAX),
@sExportCustomChar nvarchar(MAX)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
declare @Desencripta as nvarchar(MAX)


Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sExportHour where par_id = 33
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sAudioFormat where par_id = 35
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sExportPath where par_id = 36
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sSystemUser where par_id = 38
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sSystemPass where par_id = 39
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sExportStartIn where par_id = 42
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sFtpServer where par_id = 43
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sFtpUser where par_id = 44
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sFtpPass where par_id = 45
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sFtpPort where par_id = 46
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sFtpTimeOut where par_id = 47
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sFtpMode where par_id = 48
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sExportHistory where par_id = 50
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sExportType where par_id = 51
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sCustomExport where par_id = 52
Update CCRecorderRIA.dbo.TREC_PARAMETROS set par_valor =@sExportCustomChar where par_id = 53

END