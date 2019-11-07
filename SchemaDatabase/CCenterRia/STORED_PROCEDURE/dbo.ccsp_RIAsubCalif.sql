CREATE procedure [dbo].[ccsp_RIAsubCalif]
@action tinyint = 0,
@tipo tinyint = null, -- 0:Outbound / 1:Inbound
@calif_id varchar(max) = nulesol,
@califSub_id varchar(max) = null,
@califSubDesc varchar(60) = null,
@canReprogramSub tinyint = null,
@orden varchar(3) = null,
@idTipoLista int = null,
@keepDial tinyint = null,
@autoCallback tinyint = null,
@contactOwner tinyint = null,
@endConversation tinyint = null
as
set nocount on
begin try
 declare @sxML as varchar(max), @xml as xml, @succesValue varchar(2), @succesType varchar(2)
 set @xml = cast('<?xml version="1.0"?> <MainSubQualificationLoad/>' as xml)
 set @xml.modify('insert element action {""} as last into (/MainSubQualificationLoad)[1]')
 set @xml.modify('insert attribute value {sql:variable("@action")} as last into (/MainSubQualificationLoad/action)[1]')

 if @action = 0
  begin
  select @succesValue=0, @succesType=1 -- No se ingreso el action
  goto Success
  end

 if @action=1 -- Muestra info de Inbound
  begin
  set @xml.modify('insert element qualifications {""} as last into (/MainSubQualificationLoad)[1]')
  set @xml.modify('insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]')
  set @xml.modify('insert element subQualifications {""} as last into (/MainSubQualificationLoad)[1]')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  calif_id as "qualification!1!qualif_id", Description as "qualification!1!qualification",
  CanReprogram as "qualification!1!canReprogram", orden as "qualification!1!sort", isnull(endConversation,0) as "qualification!1!endConversation",
  isnull(0,0) as "qualification!1!contactOwner"
  from cctipocalif where Calif_Status=1) as x order by tag, "qualification!1!sort",
  "qualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, '<qualifications/>')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification", isnull(O.canReprogram,0) "qualifRelation!1!canReprogram", isnull(O.EndConversation,0) "qualifRelation!1!endConversation"
  from cctipoSubCalifRel R join cctipocalifSub O on R.califSub_id = O.califSub_id
  where R.tipoSubRel=1 and R.calif_id in (select top 1 calif_id from cctipocalif where Calif_Status=1 order by orden, Description)) as x
  order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, '<relQualif/>')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  califSub_id as "subQualification!1!qualif_id", califSubDesc as "subQualification!1!qualification",
  isnull(CanReprogram, 0) as "subQualification!1!canReprogram", isnull(orden, 0) as "subQualification!1!sort", isnull(EndConversation, 0) as "subQualification!1!endConversation"
  from cctipocalifSub where CalifSub_Status=1 ) as x order by tag, "subQualification!1!sort",
  "subQualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, '<subQualifications/>')

  select @xml
  return(0)
  end

 if @action=2 -- Muestra Info de Outbound
  begin
  set @xml.modify('insert element qualifications {""} as last into (/MainSubQualificationLoad)[1]')
  set @xml.modify('insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]')
  set @xml.modify('insert element subQualifications {""} as last into (/MainSubQualificationLoad)[1]')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  calif_id as "qualification!1!qualif_id", Description as "qualification!1!qualification",
  CanReprogram as "qualification!1!canReprogram", orden as "qualification!1!sort",
  autoCallback as "qualification!1!AutoCB", keepDial as "qualification!1!keepDial", contactOwner as "qualification!1!contactOwner", finishPreview as "qualification!1!preview"
  from cctipocalifOUT where CalifOut_Status=1) as x order by tag, "qualification!1!sort",
  "qualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, '<qualifications/>')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification", isnull(O.canReprogram,0) "qualifRelation!1!canReprogram"
  from cctipoSubCalifRel R join cctipocalifSubOUT O on R.califSub_id = O.califSub_id
  where R.tipoSubRel=0 and R.calif_id in (select top 1 calif_id from cctipocalifOUT where CalifOUT_Status=1 order by orden, Description)) as x
  order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, '<relQualif/>')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  califSub_id as "subQualification!1!qualif_id", califSubDesc as "subQualification!1!qualification",
  isnull(CanReprogram,0) as "subQualification!1!canReprogram", isnull(orden,0) as "subQualification!1!sort",
  isnull(autoCallback,0) as "subQualification!1!AutoCB", isnull(keepDial,0) as "subQualification!1!keepDial", isnull(contactOwner,0) as "subQualification!1!contactOwner"
  from cctipocalifSubOUT where CalifSubOut_Status=1 ) as x order by tag, "subQualification!1!sort",
  "subQualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, '<subQualifications/>')

  select @xml
  return(0)
  end

  if @tipo is null
  begin
  select @succesValue=0, @succesType=2 -- No se ingreso el tipo
  goto Success
  end

 if @action=3 -- Muestra relacion de Calificaciones con subCalificaciones
  begin
  set @xml.modify('insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]')

  if @tipo=0
   begin
   select @sxML = cast((select * from (select 1 as tag, null as parent,
   R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification",
   isnull(O.canReprogram,0) "qualifRelation!1!canReprogram", autoCallback "qualifRelation!1!autoCallback"
   from cctipoSubCalifRel R join cctipocalifSubOUT O on R.califSub_id = O.califSub_id
   where R.tipoSubRel=0 and R.calif_id in (select value from dbo.fn_RIASplitDelimited(@calif_id,','))) as x
   order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
   select @xml=dbo.xmlAppend(@xml, @sxML, '<relQualif/>')
   select @xml
   return(0)
   end

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification",
  isnull(O.canReprogram,0) "qualifRelation!1!canReprogram"
  from cctipoSubCalifRel R join cctipocalifSub O on R.califSub_id = O.califSub_id
  where R.tipoSubRel=1 and R.calif_id in (select value from dbo.fn_RIASplitDelimited(@calif_id,','))) as x
  order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, '<relQualif/>')
  select @xml
  return(0)
  end

 if @action=4 -- Alta de subcalificaciones
  begin
  if isnull(@califSubDesc, '')=''
   begin
   select @succesValue=0, @succesType=6 -- No se ingreso el nombre de la subcalificacion
   goto Success
   end

  if @tipo=0
   begin
   if exists(select califSub_id from cctipocalifSubOUT where califSubOut_Status=1 and califSubDesc=@califSubDesc)
    begin
    select @succesValue=0, @succesType=3 -- La subCalificacion ya existe
    goto Success
    end

   insert cctipocalifSubOUT (califSubDesc, canReprogram, orden, idTipoLista, califSubOut_Status, keepDial, autoCallback, contactOwner)
   select @califSubDesc, @canReprogramSub, @orden, @idTipoLista, 1, @keepDial, @autoCallback, isnull(@contactOwner,0)
   select @succesType=scope_identity(), @succesValue=1
   goto Success
   end

  if exists(select califSub_id from cctipocalifSub where califSub_Status=1 and califSubDesc=@califSubDesc)
   begin
   select @succesValue=0, @succesType=3 -- La subCalificacion ya existe
   goto Success
   end
  insert cctipocalifSub (califSubDesc,orden,canReprogram,califSub_Status,EndConversation)--,contactOwner
        select @califSubDesc, @orden, @canReprogramSub, 1,isnull(@endConversation, 0)--,isnull(@contactOwner,0)
  select @succesType=scope_identity(), @succesValue=1
  goto Success
  end

 if @action=5 -- baja de subcalificaciones
  begin
   delete cctipoSubCalifRel where tipoSubRel=@tipo and califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, ','))

  if @tipo=0
   begin
   update cctipocalifSubOUT set califSubOut_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, ','))
   update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
   select @succesValue=1
   goto Success
   end

  update cctipocalifSub set califSub_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, ','))
  select @succesValue=1
  goto Success
  end

 if @action=6 -- Actualizacion de subcalificaciones
  begin
   if @tipo=0
   begin
   if not exists(select califSub_id from cctipocalifSubOUT where califSub_id = cast(@califSub_id as smallint))
    begin
    select @succesValue=0, @succesType=4 -- La subCalificacion no existe
    goto Success
    end

   update cctipocalifSubOUT set califSubDesc=isnull(@califSubDesc, califSubDesc), canReprogram=isnull(@canReprogramSub, canReprogram),
    orden=isnull(@orden, orden), idTipoLista=isnull(@idTipoLista, idTipoLista), keepDial=isnull(@keepDial, keepDial),
    autoCallback=isnull(@autoCallback, autoCallback), contactOwner= isnull(@contactOwner,0) where califSub_id = cast(@califSub_id as smallint)
   update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
   select @succesValue=1
   goto Success
   end

  if not exists(select califSub_id from cctipocalifSub where califSub_id = cast(@califSub_id as smallint))
   begin
   select @succesValue=0, @succesType=4 -- La subCalificacion no existe
   goto Success
   end

  if @canReprogramSub=1
         begin
   declare @asignada bit, @can bit
   select @asignada=IB.inbound_id, @can=IB.cam_id from cctipoSubCalifRel CR join cctipoCalif TC on CR.calif_id = TC.calif_id and CR.tipoSubRel=1
      join ccCalifCamp CM on TC.calif_id = CM.calif_id and CM.tipo = 0 join ccInbound IB on CM.cam_id = IB.inbound_id where califSub_id = cast(@califSub_id as smallint)
            if @asignada is not null and @can is null
       begin
       select @succesValue=0, @succesType=5 -- No se puede reprogramar ya que no hay campaña asignada
       goto Success
       end
         end

  update cctipocalifSub set califSubDesc=isnull(@califSubDesc, califSubDesc), orden=isnull(@orden, orden),
   canReprogram=isnull(@canReprogramSub, canReprogram), EndConversation = isnull(@endConversation, 0) where califSub_id = cast(@califSub_id as smallint)

  exec ccsp_RIACATQualifications @Type = 4, @CamEspId = 0, @canReprogram = @canReprogramSub, @qualif_id = @califSub_id
  select @succesValue=1
  goto Success
  end

 if @action=7 -- Asignacion de Calfs / SubCalfs
  begin
  if @tipo=1 and (select cast(sum(isnull(cast(canReprogram as tinyint),0)) as bit) FROM cctipocalifSub where califSub_id in
  (select value from dbo.fn_RIASplitDelimited (@califSub_id, ',')))>0 and not exists (select IB.cam_id from cctipocalif CO
  join ccCalifCamp CF on  CF.calif_id = CO.calif_id and CF.tipo = 0 join ccInbound IB on IB.Inbound_id = CF.cam_id
  where IB.cam_id is not null and CO.calif_id in (select value from dbo.fn_RIASplitDelimited (@calif_id, ',')))
   begin
   select @succesValue=0, @succesType=5 -- No se puede reprogramar ya que no hay campaña asignada
   goto Success
   end

  insert cctipoSubCalifRel (calif_id, califSub_id, tipoSubRel)
  select C.value calif_id, S.value califSub_id, @tipo Tipo
  from dbo.fn_RIASplitDelimited (@califSub_id, ',') S
   cross join dbo.fn_RIASplitDelimited (@calif_id, ',') C
  where cast(C.value as varchar(10))+'|'+cast(S.value as varchar(10))+'|'+cast(@tipo as varchar(10)) not in
   (select cast(calif_id as varchar(10))+'|'+cast(califSub_id as varchar(10))+'|'+cast(tipoSubRel as varchar(10)) from cctipoSubCalifRel)
  and C.value is not null and S.value is not null

if @tipo=0
    update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
    select @succesValue=1
    goto Success
end
 if @action=8 -- Desasignacion de Calfs / SubCalfs
    begin
    delete cctipoSubCalifRel
    where cast(calif_id as varchar(10))+'|'+cast(califSub_id as varchar(10))+'|'+cast(tipoSubRel as varchar(10)) in
    (select cast(C.value as varchar(10))+'|'+cast(S.value as varchar(10))+'|'+cast(@tipo as varchar(10))
   from dbo.fn_RIASplitDelimited (@califSub_id, ',') S cross join dbo.fn_RIASplitDelimited (@calif_id, ',') C)
    if @tipo=0
      update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
      select @succesValue=1
      goto Success
  end

  return(0)
end try
begin catch
  select @succesValue=0, @succesType=0 -- error no controlado
  goto Success
end catch
Success: -- <success value='n' type='n'/>
set @xml.modify('insert element success {""} as last into (/MainSubQualificationLoad)[1]')
set @xml.modify('insert attribute value {sql:variable("@succesValue")} as last into (/MainSubQualificationLoad/success)[1]')
if isnull(@succesType, 0) <> 0
begin
  set @xml.modify('insert attribute type {sql:variable("@succesType")} as last into (/MainSubQualificationLoad/success)[1]')
end
select @xml
return(0)
set nocount off