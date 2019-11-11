CREATE PROCEDURE [dbo].[trsp_AdmRecSearchOneDay]
@Sup_id int

AS
BEGIN

declare @sql1 nvarchar(max)
declare @sql2 nvarchar(max)
declare @sqlUnion nvarchar(max)

--Tabla con toda la informaciom
  CREATE TABLE #tempRiAAllInfoOneDay(
			cal_id int,
			tipo_llamada smallint,
			cam_id smallint,
			calif_id smallint,
			duracion int,
			id_nivel_grito int,
			user_id int,
			finicio datetime,
			ani varchar (100),
			dni varchar (100),
			cal_key varchar (100),
			cal_manual tinyint, 
			posicion int,
			computer varchar(100),
			total_forma int,
			id_repositorio tinyint,
			score varchar (100),
			formato_duracion varchar(15),
			grab_id bigint,
			IDWG varchar (800),
			califSub_id varchar(800),
			cal_tMoh smallint
	)	

	CREATE CLUSTERED INDEX [IX_tempRiAAllInfoOneDaydate] ON [#tempRiAAllInfoOneDay]
	(		  
	  [finicio] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]


	create table #auxOutboundOneDay(
       	    cal_id int,
			tipo_llamada smallint,
			cam_id smallint,
			calif_id smallint,
			duracion int,
			id_nivel_grito int,
			user_id int,
			finicio datetime,
			ani varchar (100),
			dni varchar (100),
			cal_key varchar (100),
			cal_manual tinyint, 
			posicion int,
			computer varchar(100),
			total_forma int,
			id_repositorio tinyint,
			score varchar (100),
			formato_duracion varchar(15),
			grab_id bigint,
			IDWG varchar (800),
			califSub_id varchar(800),
			cal_tMoh smallint
			)
			
  --Segmento de Calificaciones
  create table #tempRiaFormaCalifOneDay(
  id_grabacion bigint,
  total_forma int)

  insert into #tempRiaFormaCalifOneDay (id_grabacion,total_forma)
  select r.id_grabacion, avg(r.total_forma) as total_forma
  from ria_formacalif r
  inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t
  on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
  group by r.id_grabacion
  

  --Segmento de Supervisor
  create table #tempCampEspWGfOneDay(
  IdCampEsp smallint,
  Tipo smallint,
  user_id smallint)
	 
  CREATE NONCLUSTERED INDEX [IX_tempCampEspWGfOneDay] ON [#tempCampEspWGfOneDay] 
  (
	[user_id] ASc
  )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
     
  insert into #tempCampEspWGfOneDay (IdCampEsp,Tipo,user_id)
	  select distinct a.IdCampEsp, a.Tipo as Tipo_llamada,b.User_id
  from ccRIACampEspWGConsulta a
  inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG		
	
   --Segmento de usurios asociados al supervisor			     
  create table #tempCompleteOneDay(
  IdCampEsp smallint,
  Tipo smallint ,
  user_id smallint,
  IDWG smallint)                 

  CREATE NONCLUSTERED INDEX [IX_tempCompleteOneDayUser] ON [#tempCompleteOneDay] 
  (		  
   [user_id] ASC
  )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
     
 
   insert into #tempCompleteOneDay  (IdCampEsp,Tipo,user_id,IDWG)  
   select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
   from  ccRIACampEspWGConsulta a  inner join
   (select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in 
		(select  distinct a.IDWG from ccRIACampEspWGConsulta a
		 inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG
		 )and user_id <> @Sup_id
	) b on a.IDWG=b.IDWG

	--Seccion Inbound RIAGrabacion

	insert into #tempRiAAllInfoOneDay
		select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
				finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
				isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
				isnull (z.total_forma,0) as total_forma,a.id_repositorio,
				isnull (f.description,'')  AS score,
				CASE WHEN duracion / 3600 < 10 THEN '0' ELSE '' END + RTRIM(a.duracion / 3600) + ':' + RIGHT('0' + RTRIM(a.duracion % 3600 / 60), 2) + ':' + RIGHT('0' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
				grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'') AS califSub_id,a.cal_tMoh as cal_tMoh
		from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
		left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
		left join cctipocalifsub p on p.califSub_id=a.califSub_id
		left join ccPosicion b on b.pos_id = a.cal_extension * -1
		left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
		left join #tempRiaFormaCalifOneDay z on a.grab_id=z.id_grabacion
		inner join #tempCompleteOneDay U with (index(IX_tempCompleteOneDayUser)) on a.age_id=U.user_id  
		where a.finicio >=  dateadd(hour, -2, GetDate())-- Convert(nvarchar(11),Getdate(),120) 
		and a.tipo_llamada=1
		
		
	insert into #tempRiAAllInfoOneDay
		select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
				finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
				isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
				isnull (z.total_forma,0) as total_forma,a.id_repositorio,
				isnull (f.description,'')  AS score,
				CASE WHEN duracion / 3600 < 10 THEN '0' ELSE '' END + RTRIM(a.duracion / 3600) + ':' + RIGHT('0' + RTRIM(a.duracion % 3600 / 60), 2) + ':' + RIGHT('0' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
				grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'') AS califSub_id,a.cal_tMoh as cal_tMoh
		from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
		left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
		left join cctipocalifsub p on p.califSub_id=a.califSub_id
		left join ccPosicion b on b.pos_id = a.cal_extension * -1
		left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
		left join #tempRiaFormaCalifOneDay z on a.grab_id=z.id_grabacion
		inner join #tempCampEspWGfOneDay U with (index(IX_tempCampEspWGfOneDay)) on a.age_id=U.user_id  
		where a.finicio >=  dateadd(hour, -2, GetDate())--Convert(nvarchar(11),Getdate(),120) 
		and a.tipo_llamada=1
		

	--Seccion Outbound RIAGrabacion
	insert into #auxOutboundOneDay(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
						finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
						id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)		
			select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
						finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
						isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
						isnull (z.total_forma,0) as total_forma,a.id_repositorio,
						isnull (e.description,'')  AS score,
						CASE WHEN duracion / 3600 < 10 THEN '0' ELSE '' END + RTRIM(a.duracion / 3600) + ':' + RIGHT('0' + RTRIM(a.duracion % 3600 / 60), 2) + ':' + RIGHT('0' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
						grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'') AS califSub_id,a.cal_tMoh as cal_tMoh
			from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id			
			left join cctipocalifsubout k on k.califSub_id=a.califSub_id		
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
			left join #tempRiaFormaCalifOneDay z on a.grab_id=z.id_grabacion			
			where a.finicio >=  dateadd(hour, -2, GetDate())--Convert(nvarchar(11),Getdate(),120) 
			and a.tipo_llamada=2
			
	
	
	insert into #tempRiAAllInfoOneDay
	select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
					finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
			        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutboundOneDay a 
	inner join #tempCompleteOneDay U  on a.user_id=U.user_id

	insert into #tempRiAAllInfoOneDay
	select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
					finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
			        id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutboundOneDay a 
	inner join #tempCampEspWGfOneDay U  on a.user_id=U.user_id

	--Seleccionar info de tabla global
	select distinct a.cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
		   finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
		   id_repositorio,score,formato_duracion,grab_id,cast(isnull(a.IDWG,'') as nvarchar(max)) as IDWG,califSub_id,cal_tMoh
	into #tempFinal
	from #tempRiAAllInfoOneDay a with (index(IX_tempRiAAllInfoOneDaydate))
	order by finicio asc
	
	select
		t1.cal_id, t1.User_id, t1.tipo,
		stuff((
			select '|' +  cast(t.IDWG as varchar)
			from ccRIAWorkGroup_Calid t
			where t.cal_id = t1.cal_id
			order by t.IDWG
			for xml path('')
			),1,1,'') as wgList
	into #tempWgList
	from ccRIAWorkGroup_Calid t1
	left outer join #tempFinal tf on tf.cal_id = t1.cal_id
	where tf.user_id = t1.User_id
	and tf.tipo_llamada - 1 = t1.tipo
	group by t1.cal_id, t1.User_id, t1.tipo
	
	select distinct a.cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
		   finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
		   id_repositorio,score,formato_duracion,grab_id,cast(isnull(b.wgList,'') as nvarchar(max)) as IDWG,califSub_id,cal_tMoh
	from #tempFinal a
	left outer join #tempWgList b on a.cal_id = b.cal_id
	where a.user_id = b.user_id
	and a.tipo_llamada -1 = b.tipo
	order by finicio asc
	
	drop table #tempRiaFormaCalifOneDay
	drop table #tempCampEspWGfOneDay
	drop table #tempCompleteOneDay
	drop table #tempRiAAllInfoOneDay
	drop table #auxOutboundOneDay
	drop table #tempFinal
	drop table #tempWgList
	
END