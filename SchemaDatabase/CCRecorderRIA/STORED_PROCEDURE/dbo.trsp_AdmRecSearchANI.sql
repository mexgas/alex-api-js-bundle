CREATE PROCEDURE [dbo].[trsp_AdmRecSearchANI]
@Sup_id int,
@ani as varchar(100)

AS
BEGIN

SET NOCOUNT ON;

declare @fecha  datetime

set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

	select r.id_grabacion, avg(r.total_forma) as total_forma
	into #tempRiaFormaCalif from ria_formacalif r
	inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t
	on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
	group by r.id_grabacion

	select distinct a.IdCampEsp, a.Tipo as Tipo_llamada
	into #tempCampEspWG from ccRIACampEspWGConsulta a
	inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG

select * from (
	select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
	finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
	isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
	isnull (z.total_forma,0) as total_forma,a.id_repositorio,
	CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
	CASE WHEN duracion / 3600 < 10 THEN '0' ELSE '' END + RTRIM(a.duracion / 3600) + ':' + RIGHT('0' + RTRIM(a.duracion % 3600 / 60), 2) + ':' + RIGHT('0' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
	a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
	from RIA_GRABACION a with (index(IX_RIA_GRABACION_9))
	left join ccPosicion b on b.pos_id = a.cal_extension * -1
	--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id
	left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
	left join ccTipoCalif AS f ON a.calif_id = f.calif_id
	left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )
	left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
	inner join #tempCampEspWG campEspWg on g.IDWG is null or( a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) )
	where a.ani = @ani
	union
	select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
	finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
	isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
	isnull (z.total_forma,0) as total_forma,a.id_repositorio,
	CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
	CASE WHEN duracion / 3600 < 10 THEN '0' ELSE '' END + RTRIM(a.duracion / 3600) + ':' + RIGHT('0' + RTRIM(a.duracion % 3600 / 60), 2) + ':' + RIGHT('0' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
	a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
	from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_9))
	left join ccPosicion b on b.pos_id = a.cal_extension * -1
	--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id
	left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
	left join ccTipoCalif AS f ON a.calif_id = f.calif_id
	left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )
	left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
	inner join #tempCampEspWG campEspWg on g.IDWG is null or( a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) )
	where a.ani = @ani

)X


--select * from #tempCampEspWG


	drop table #tempRiaFormaCalif
	drop table #tempCampEspWG

END