CREATE PROCEDURE [dbo].[trsp_AdmRecSearchNodeWgCampACDCalif]
  @User_id int AS
BEGIN

	SET NOCOUNT ON

	select b.IDWG, c.WGName
	into #nodeWorkgroup
	from ccusers a
	inner join ccRIAWorkGroupUsersConsulta b on b.user_id = @User_id
	inner join ccRIACat_WorkGroup c on c.IDWG = b.IDWG and c.StatusWorkGroup = 1
	where a.user_id = @User_id
	order by b.IDWG

	create table #tempFinal(
    Tipo smallint,
	IDWG smallint,
	WGName varchar (50),
	IdCampEsp smallint,
	descripcion varchar(50),
	frame smallint,
	calif_id smallint,
	califDescription varchar(100),
	califSub_id smallint,
	califSubDesc varchar(100)
    )

	create table #tempFinalOut(
    Tipo smallint,
	IDWG smallint,
	WGName varchar (50),
	IdCampEsp smallint,
	descripcion varchar(50),
	frame smallint,
	calif_id smallint,
	califDescription varchar(100),
	califSub_id smallint,
	califSubDesc varchar(100)
    )

	create table #tempInbound(
    Tipo smallint,
	IDWG smallint,
	WGName varchar (50),
	IdCampEsp smallint,
	descripcion varchar(50),
	frame smallint,
	calif_id smallint,
	califDescription varchar(100)
    )

	create table #tempOutbound(
    Tipo smallint,
	IDWG smallint,
	WGName varchar (50),
	IdCampEsp smallint,
	descripcion varchar(50),
	frame smallint,
	calif_id smallint,
	califDescription varchar(100)
    )

	insert into #tempInbound (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription)
		select a.Tipo, e.IDWG, e.WGName, a.idCampEsp, b.descripcion, isnull(d.frame,1) frame,
		isnull(f.calif_id,0) as calif_id, isnull(g.Description,'') as califDescription
		from ccRIACampEspWGConsulta a
		inner join ccInbound b on b.Inbound_id = a.idCampEsp
		left join ccRIAInboundGraph c on  c.Inbound_id = a.idCampEsp
		left join ccRIAGraphics d on d.graphic_id = c.graphic_id
		left join #nodeWorkgroup e on a.IDWG = e.IDWG
		left join ccCalifCamp f on b.inbound_id = f.cam_id and f.tipo = 0
		left join ccTipoCalif g on f.calif_id = g.calif_id and g.Calif_Status = 1
		where a.Tipo = 0
		and e.IDWG is not null
		and a.idCampEsp is not null
		and g.Description <> ''
		order by IDWG, tipo, idCampEsp, calif_id

	insert into #tempOutbound (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription)
		select a.Tipo, e.IDWG, e.WGName, a.idCampEsp, b.cam_descripcion as descripcion,
		isnull(d.frame,1) frame, isnull(f.calif_id,0) as calif_id, isnull(g.Description,'') as califDescription
		from ccRIACampEspWGConsulta a
		inner join ccCamps b on b.cam_id = a.idCampEsp
		left join ccRIACampsGraph c on  c.cam_id = a.idCampEsp
		left join ccRIAGraphics d on d.graphic_id = c.graphic_id
		left join #nodeWorkgroup e on a.IDWG = e.IDWG
		left join ccCalifCamp f on b.cam_id = f.cam_id and f.tipo = 1
		left join ccTipoCalifOUT g on f.calif_id = g.calif_id and g.CalifOut_Status = 1
		where a.Tipo = 1
		and e.IDWG is not null
		and a.idCampEsp is not null
		and g.Description <> ''
		order by IDWG, tipo, idCampEsp, calif_id

	---Seccion Inbound

	insert into #tempFinal (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
		select B.Tipo,B.IDWG,B.WGName,B.idCampEsp,B.descripcion,B.frame,B.calif_id,B.califDescription,C.califSub_id,isnull(C.califSubDesc,'') as califSubDesc from #tempInbound B
		inner join cctiposubcalifrel as A on A.calif_id=B.calif_id
		inner join cctipocalifsub as C on C.califSub_id = A.califSub_id
		where  A.tipoSubRel=1
		and C.califSub_id=A.califSub_id
		and C.califSubDesc <>''


	insert  into #tempFinal (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
		select Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,'','' from #tempInbound where calif_id not in (select distinct (calif_id) from #tempFinal)

	---Seccion Outbound

	insert into #tempFinalOut (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
		select B.Tipo,B.IDWG,B.WGName,B.idCampEsp,B.descripcion,B.frame,B.calif_id,B.califDescription,C.califSub_id,isnull(C.califSubDesc,'') as califSubDesc from #tempOutbound B
		inner join cctiposubcalifrel as A on A.calif_id=B.calif_id
		inner join cctipocalifsubout as C on C.califSub_id = A.califSub_id
		where  A.tipoSubRel=0
		and C.califSub_id=A.califSub_id
		and C.califSubDesc <>''

	insert  into #tempFinalOut (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
		select Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,'','' from #tempOutbound where calif_id not in (select distinct (calif_id) from #tempFinalOut)


	--Seleccion de Toda la Info
	select * from #tempFinal
	union select * from #tempFinalOut
	order by IDWG, tipo, idCampEsp, calif_id

	drop table #nodeWorkgroup
	drop table #tempInbound
	drop table #tempOutbound
	drop table #tempFinal
	drop table #tempFinalOut

END