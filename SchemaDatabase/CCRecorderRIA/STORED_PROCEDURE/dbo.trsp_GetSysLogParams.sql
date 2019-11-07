CREATE PROCEDURE [dbo].[trsp_GetSysLogParams]
AS
BEGIN
    select id, par_valor from TREC_SYSLOG_PARAMS
END