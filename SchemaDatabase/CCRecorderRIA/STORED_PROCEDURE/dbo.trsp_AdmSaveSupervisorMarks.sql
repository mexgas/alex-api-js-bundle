CREATE PROCEDURE [dbo].[trsp_AdmSaveSupervisorMarks]
    -- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada int,
@user_id int,
@marca nvarchar(MAX)


AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here

declare @grab_id int


set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)

insert CCRecorderRIA.dbo.RIA_MARCAS (grab_id,user_id,marca,tipo_marca,tipo_llamada,call_id) values (@grab_id,@user_id,@marca,2,@tipo_llamada,@cal_id )

END