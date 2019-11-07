CREATE PROCEDURE [dbo].[trsp_AdmRecSearchCalID]
@Sup_id int,
@call_id as int

AS
BEGIN
	SET NOCOUNT ON;

	 select r.id_grabacion, avg(r.total_forma) as total_forma
	 into #tempRiaFormaCalif from ria_formacalif r
	 inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t
	 on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
	 group by r.id_grabacion

	 select distinct a.IdCampEsp, a.Tipo as Tipo_llamada
	 into #tempCampEspWG from ccRIACampEspWGConsulta a
	 inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG

	 select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
	 into #tempComplete
	 from  ccRIACampEspWGConsulta a inner join
	 (select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in (select  distinct a.IDWG
	 from ccRIACampEspWGConsulta a
	 inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG)
	 and user_id <> @Sup_id) b
	 on a.IDWG=b.IDWG


	 select DISTINCT  a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito,
	 a.age_id,a.finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
	 isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
	 isnull (z.total_forma,0) as total_forma,a.id_repositorio,
	 CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
	 CASE WHEN duracion / 3600 < 10 THEN '0' ELSE '' END + RTRIM(a.duracion / 3600) + ':' + RIGHT('0' + RTRIM(a.duracion % 3600 / 60), 2) + ':' + RIGHT('0' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
	 grab_id as grabID, a.IDWG as IDWG,isnull( CASE WHEN a.tipo_llamada = 2  THEN k.califSubDesc ELSE p.califSubDesc END,'') AS califSub_id,a.cal_tMoh as cal_tMoh
	 from RIA_GRABACION a with (index(IX_RIA_GRABACION_7))
	 left join cctipocalifsubout k on k.califSub_id=a.califSub_id
	 left join cctipocalifsub p on p.califSub_id=a.califSub_id
	 left join ccPosicion b on b.pos_id = a.cal_extension * -1
	 left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
	 left join ccTipoCalif AS f ON a.calif_id = f.calif_id
	 left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
	 where a.cal_id = @call_id
	 union
	 select DISTINCT  a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito,
	 a.age_id,a.finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
	 isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
	 isnull (z.total_forma,0) as total_forma,a.id_repositorio,
	 CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
	 CASE WHEN duracion / 3600 < 10 THEN '0' ELSE '' END + RTRIM(a.duracion / 3600) + ':' + RIGHT('0' + RTRIM(a.duracion % 3600 / 60), 2) + ':' + RIGHT('0' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
	 grab_id as grabID, a.IDWG as IDWG,isnull( CASE WHEN a.tipo_llamada = 2  THEN k.califSubDesc ELSE p.califSubDesc END,'') AS califSub_id,a.cal_tMoh as cal_tMoh
	 from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_7))
	 left join cctipocalifsubout k on k.califSub_id=a.califSub_id
	 left join cctipocalifsub p on p.califSub_id=a.califSub_id
	 left join ccPosicion b on b.pos_id = a.cal_extension * -1
	 left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
	 left join ccTipoCalif AS f ON a.calif_id = f.calif_id
	 left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
	 where a.cal_id = @call_id

	 drop table #tempRiaFormaCalif
	 drop table #tempCampEspWG
	 drop table #tempComplete

END