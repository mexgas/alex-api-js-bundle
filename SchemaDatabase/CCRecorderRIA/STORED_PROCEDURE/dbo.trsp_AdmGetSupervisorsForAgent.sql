CREATE PROCEDURE [dbo].[trsp_AdmGetSupervisorsForAgent]

@cal_id int,
@tipo_llamada int

AS
BEGIN

	SET NOCOUNT ON;

declare @age_id int

set @age_id = (select age_id from (select age_id from RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select age_id from RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada)x)


select distinct a1.user_id as agt, a5.user_id as sup, a5.login from ccusers a1 
inner join ccriaworkgroupusers a2 on (a1.user_id=a2.user_id and tipouser_id=1)
inner join 
(select a3.user_id, a4.IDWG, a3.login  from ccusers a3 
inner join ccriaworkgroupusers a4 on (a3.user_id=a4.user_id and (tipouser_id=2 or tipouser_id=6))) a5 on (a2.IDWG=a5.IDWG)
where a1.user_id = @age_id
order by a1.user_id,a5.user_id

END