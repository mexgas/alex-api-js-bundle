CREATE PROCEDURE [dbo].[trsp_AdmGetMarks]

@cal_id int,
@tipo_llamada int


AS
BEGIN

    SET NOCOUNT ON;

    select a.id_marca,a.user_id,b.login, a.marca, a.tipo_marca
    from RIA_MARCAS a inner join ccUsers b
    on  b.user_id = a.user_id
    where (a.call_id = @cal_id and tipo_llamada = @tipo_llamada)
    order by marca


END