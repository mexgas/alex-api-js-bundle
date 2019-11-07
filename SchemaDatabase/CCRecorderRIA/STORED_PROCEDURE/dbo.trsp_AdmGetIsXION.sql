Create procedure [dbo].[trsp_AdmGetIsXION]
	as
	set nocount on
	--declare @version varchar(max)
	SELECT par_valor  from trec_parametros where par_id = 29