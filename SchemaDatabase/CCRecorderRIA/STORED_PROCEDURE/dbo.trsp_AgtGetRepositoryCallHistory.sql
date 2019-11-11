CREATE PROCEDURE  [dbo].[trsp_AgtGetRepositoryCallHistory]

@CallID int,
@Tipo_llamada smallint


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @IDRepositorio int

set @IDRepositorio = (select id_repositorio from RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @CallID and tipo_llamada = @Tipo_llamada UNION select id_repositorio from RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @CallID and tipo_llamada = @Tipo_llamada)

select isnull(dirvirtual_audio,'') as dirvirtual_audio  from TREC_REPOSITORIOS where id_repositorio = @IDRepositorio

END