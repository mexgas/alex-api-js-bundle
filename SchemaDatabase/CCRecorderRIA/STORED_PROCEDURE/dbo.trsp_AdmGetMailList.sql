CREATE PROCEDURE [dbo].[trsp_AdmGetMailList] AS

SET NOCOUNT ON

select mail_id, isnull(mail,'') as mail, nivel_id from CCRecorderRIA.dbo.TREC_LISTA_MAIL with(nolock)