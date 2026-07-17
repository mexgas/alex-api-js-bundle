/*
Autor: Jesus Gallardo
Descripcion:


Version requerida: 50
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 55
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

	set @process = 'CW-1770 Version 51  drop index ria_recnode.IX_status'
	set @Sql= 'if exists (select * from sys.indexes where name = N''IX_status'' and object_id = OBJECT_ID(N''ria_recnode'')) begin
	drop index ria_recnode.IX_status
 end'
    EXEC(@Sql)

    set @process = 'CW-1770 Version 51 Alter column ria_RecNode.status'
	set @Sql= 'alter table ria_RecNode alter column status smallint'
    EXEC(@Sql)

    set @process = 'CW-1770 Version 51  CReate index ria_recnode.IX_status'
	set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_status'' and object_id = OBJECT_ID(N''ria_recnode'')) begin
	create index IX_status on ria_RecNode(status)
 end
'
    EXEC(@Sql)


	set @process = 'CW-2155 Se agrega columna HHMM a TREC_FORM_ARCHIVOSEXPORT'
    set @Sql= '
	
	if not exists(select * from TREC_FORM_ARCHIVOSEXPORT where id = 23)
			begin	
	insert into TREC_FORM_ARCHIVOSEXPORT (id,Formato,Campo,Orden,Comentarios)
	values (23,''HHMM'',''REPLACE(CONVERT(varchar(5), finicio, 108), '''':'''', '''''''') as HHMM'',0,''Time in format HHMM'')
	end
		'
    EXEC(@Sql)       

	set @process = 'CW-943 Etiquetas en Portugués'
	set @Sql= 'ALTER PROCEDURE [dbo].[trsp_AdmAVRSReportLanguage]
@idioma as int
AS
BEGIN					
SET NOCOUNT ON;
if @idioma=1
begin
select ''Reporte de Evaluacion de Llamadas'' as [001], 
''Información de la Llamada'' as [002], 
''agente'' as [003],
''Supervisor'' as [004],
''Teléfono'' as [005],
''Tipo de Llamada'' as [006],
''Fecha'' as [007],
''ID de LLamada'' as [008],
''ID de Grabación'' as [009],
''CallKey'' as [010],
''Duración'' as [011],
''Campaña/ACD'' as [012],
''Formato de evaluación'' as [013],
''Fecha de evaluación'' as [014],
''Firma de Agente'' as [015],
''Firma de Supervisor'' as [016],
''Firma de Calidad'' as [017],
''Detalles de Evaluación'' as [018],
''Concepto/Pregunta'' as [019],
''Respuesta'' as [020],
''Puntos'' as [021],
''Valor Total'' as [022],
''Reporte de Evaluacion de Chat'' as [023],
''Información de Chat'' as [024],
''Dominio'' as [025],
''ID de Chat'' as [026]
end
else if @idioma=3
begin
select ''Relatório de avaliação da chamada'' as [001], 
''Informação da chamada'' as [002], 
''Agente'' as [003],
''Supervisor'' as [004],
''Telefone'' as [005],
''Tipo de chamada'' as [006],
''Data'' as [007],
''ID da chamada'' as [008],
''ID da gravação'' as [009],
''CallKey'' as [010],
''Duração'' as [011],
''Campanha/Grupo ACD'' as [012],
''Formulário de avaliação'' as [013],
''Data da avaliação'' as [014],
''Assinatura do agente'' as [015],
''Assinatura do supervisor'' as [016],
''Assinatura do Departamento de Qualidade'' as [017],
''Detalhes da avaliação'' as [018],
''Conceito/Pregunta'' as [019],
''Resposta'' as [020],
''Pontos'' as [021],
''Valor Total'' as [022],
''Relatório de avaliação da conversa de chat'' as [023],
''Informação da conversa de chat'' as [024],
''Domínio'' as [025],
''ID da conversa de chat'' as [026]
end
else if @idioma=2
begin
select ''Call Evaluation Report'' as [001], 
''Call Information'' as [002], 
''Agent'' as [003],
''Supervisor'' as [004],
''Phone'' as [005],
''Call Type'' as [006],
''Date'' as [007],
''Call ID'' as [008],
''Recording ID'' as [009],
''CallKey'' as [010],
''Length'' as [011],
''Campaign/ACD group'' as [012],
''Scoring template'' as [013],
''Evaluation date'' as [014],
''Agent signature'' as [015],
''Supervisor signature'' as [016],
''Quality Department signature'' as [017],
''Evaluation details'' as [018],
''Concept/Question'' as [019],
''Answer'' as [020],
''Points'' as [021],
''Total score'' as [022],
''Chat Evaluation Reportt'' as [023],
''Chat Information'' as [024],
''Dominio'' as [025],
''Chat ID'' as [026]
end
END'
	EXEC(@sql)


		set @process = 'CW-943 Etiquetas en Portugués ccsp_getVersion'
 	set @sql ='-- =============================================
/*Catalogo de errores:
-1 / ERROR. ??? -- Este error no es controlado, es una excepcion del store, server, segun mande la alerta es lo que se mostrara
-2 / ERROR. Modulo no valido -- Cuando en el parametro de modulo no se ingresa BD|DB, AVRS, ALL
-3 / ERROR. Version no Valida para ''BD/AVRS''. Version Actual: ''#Version'' -- Cuando se quiere generar una versión que no es mayor a la actual
-4 / ERROR. generado al actualizar a version ''#Version'' -- Cuando se presento un problema al hacer el update de la version, por lo cual no se actualizo
*/
ALter procedure [dbo].[ccsp_getVersion]
@Module varchar(4) = null,
@Version int = 0 output
as
set nocount on
declare @Idioma int
select @Idioma = cast(par_valor as int) from trec_parametros where par_id = 26
if @Module=''DB''
	set @Module=''BD''
if upper(isnull(@Module, '''')) not in (''BD'', ''AVRS'', ''ALL'')
 begin
	select ''-2'' ID, case @Idioma when 1 then ''ERROR. Modulo no valido''
	 when 2 then ''ERRO. Módulo inválido''
	else ''ERROR. Invalid Module'' end [Description]
	return(0)
 end
if @Module = ''ALL''
 begin
	select par_valor Ver_BD_AVRS from trec_parametros where par_id = 30
	return(0)
 end
declare @nVersion varchar(30)
select @nVersion = cast(par_valor as varchar(15)) from trec_parametros where par_id = 30
BEGIN TRY
	declare @version_1 varchar(15), @version_2 varchar(9)
	set @version_1 = substring(@nVersion, 1, charindex(''.'', @nVersion)-1)
	set @nVersion = substring(@nVersion, charindex(''.'', @nVersion) + 1, len(@nVersion))
	set @version_2 = @nVersion
END TRY
BEGIN CATCH
	select ''-1'' ID, ERROR_MESSAGE() [Description]
	return(0)
END CATCH
if isnull(@Version, 0) = 0
 begin
	select @version = cast(case upper(@Module) when ''BD'' then @version_2
	else @version_1 end as int)
	select @version Version
	return(@version)
 end
if upper(@Module) = ''BD'' and (@Version <= cast(@version_2 as int) or (@Version - cast(@version_2 as int))>1)
 begin
	select ''-3'' ID, case @Idioma when 1
	then ''ERROR. Version no Valida para BD. Version Actual: '' + @version_2
	when 2 then ''ERRO. Versão inválida para BD, versão atual: '' + @version_2
	else ''ERROR. Invalid Version for DB. Current Version: '' + @version_2
	end [Description]
	return(0)
 end
if @Version <= cast(case upper(@Module) when ''BD'' then @version_2
else @version_1 end as int)
 begin
	select ''-3'' ID, case @Idioma when 1
	then ''ERROR. Version no Valida para '' + @Module + ''. Version Actual: '' +
	 case upper(@Module) when ''BD'' then @version_2 else @version_1 end
	 when 2
	then ''ERRO. Versão inválida para '' + @Module + ''. Versão atual: '' +
	 case upper(@Module) when ''BD'' then @version_2 else @version_1 end
	else ''ERROR. Invalid Version for '' + @Module + ''. Current Version: '' +
	 case upper(@Module) when ''BD'' then @version_2 else @version_1 end
	end [Description]
	return(0)
 end
if upper(@Module) = ''BD'' set @version_2 = @Version
else set @version_1 = @Version
set @nVersion = @version_1 + ''.'' + @version_2
update trec_parametros set par_valor = @nVersion where par_id = 30
if @@rowcount = 1
	select ''0'' ID, ''Actualizado a version: '' + @nVersion [Description]
else
	select ''-4'' ID, case @Idioma when 1
	then ''ERROR generado al actualizar a version '' + @nVersion
	when 2 then ''ERRO encontrado ao atualizar a versão '' + @nVersion
	else ''ERROR introduced when upgrading to version '' + @nVersion
	end [Description]
return (0)
set nocount off'
	
	EXEC(@sql)

	set @process = 'CW-1770 Version 51  Alter SP trsp_InsertRecNode'
	set @Sql= 'ALTER procedure [dbo].[trsp_InsertRecNode]
@grabId int,
@type int=0
as
begin

  declare @shoutLevel as nvarchar(20)
 declare @language as int
 declare @start as int
 declare @callType int

 declare @xml as xml
 declare @crmNode as xml
 declare @manual as nvarchar(10)
 declare @rating as nvarchar(20)
 declare @sqlCRM nvarchar(max)
 declare @supervisor as nvarchar(50)
 declare @template as nvarchar(50)
 declare @callID as nvarchar(50)
 declare @isHistory bit
 declare @Prefijo varchar(50)
 set @Prefijo = ''''

 declare @table as nvarchar(20)
 set @table=''RIA''

 /*
  CDATE---> Date Generic
  C01-----> grab_id
  C02-----> Type of Recording (Inbound/Outbound)
  C03-----> Camp/ACD descripcion
  C04-----> ShoutLevel
  C05-----> Agent Login
  C06-----> Formated date
  C07-----> Position Computer
  C08-----> Duration
  C09-----> Ani
  C10-----> Dnis
  C11-----> Calkey
  C12-----> Manual
  C13-----> User ID
  C14-----> cal ID
  C15-----> Cam /ACD ID
  C16-----> Duration Reco@rding as 00:00:00
  C17-----> Position Extension
  C18-----> rating(Scoring Template)
  C19-----> Reposiory ID
  C20-----> Disposition
  C21-----> Disposition ID
  C22-----> Has Video
  C23-----> Agent Full Name
  C24-----> Supervisor Name
  C25-----> Score Template
  C26-----> graphic_id
  C27-----> Prefix recording
  CID-----> CamId
  CType---> Tipo de llamada
 */

 select @language= valor from ccSettings where setting_id = 27



 if exists (select *  from ria_grabacion where grab_id = @grabId   ) begin
		select @isHistory=0,@callType=rec.tipo_llamada
	  ,@Prefijo = rec.Prefijo
	  ,@manual = case when rec.cal_manual = 0 then ''N/A'' else ''Manual'' end
	  ,@shoutlevel =sho.nombre_nivel
	  ,@rating= isnull(total_forma  ,0)
	  ,@callID=cal_id
	 from ria_grabacion rec
	 left join ria_tipo_gritos sho on rec.id_nivel_grito = sho.id_nivel_grito
	 left join (select top 1 total_forma,id_grabacion from ria_formacalif where id_grabacion = @grabId order by fecha_calif desc)  formCalif on formCalif.id_grabacion=rec.grab_id
	 where grab_id = @grabId
 end
 else begin
	 select
	 @isHistory=1,
	 @callType=rec.tipo_llamada,  @manual = case when rec.cal_manual = 0 then ''N/A'' else ''Manual'' end
	  ,@shoutlevel =sho.nombre_nivel
	  ,@rating= isnull(total_forma  ,0)
	  ,@callID=cal_id
	 from RIA_GRABACIONCONSULTA rec
	 left join ria_tipo_gritos sho on rec.id_nivel_grito = sho.id_nivel_grito
	 left join (select top 1 total_forma,id_grabacion from ria_formacalif where id_grabacion = @grabId order by fecha_calif desc)  formCalif on formCalif.id_grabacion=rec.grab_id
	 where grab_id = @grabId
 end




 --Languages 0 spanish 1 english
 select @shoutlevel=case when @language =0 then substring(@shoutlevel,0,@start) else  substring(@shoutlevel,(@start+1),(LEN(@shoutlevel)-1)) end


 select @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
   RIA_FORMATOS as formatos
   inner join RIA_FORMACALIF formatosCalif on formatosCalif.id_formato=formatos.id_formato
   inner join RIA_GRABACION grabacion  on grabacion.grab_id= formatosCalif.id_grabacion
   inner join ccUsers supervisor on supervisor.User_id = formatosCalif.id_supervisor
   where grabacion.grab_id=@grabId and formatosCalif.tipo=1

if @isHistory=0 begin

 set @xml = (
	 select * from (
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	   ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27'',rec.cam_id as ''@CID'',rec.tipo_llamada AS ''@CType''
	   	   from
	   ria_grabacion rec
	   inner join ccinbound inb on rec.cam_id = inb.Inbound_id and rec.tipo_llamada  = 1
	   inner join ccUsers usr on usr.User_id = rec.age_id
	   inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	   left join ccTipoCalif AS e  ON rec.calif_id = e.calif_id
	   inner join ccRIAInboundGraph grap on grap.Inbound_id=inb.Inbound_id
	   where rec.grab_id = @grabId
	  union
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'',inb.cam_descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'',convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.Description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	  ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27'',rec.cam_id as ''@CID'',rec.tipo_llamada AS ''@CType''
	   from
	  ria_grabacion rec
	  inner join cccamps inb on rec.cam_id = inb.cam_id and rec.tipo_llamada  = 2
	  inner join ccUsers usr on usr.User_id = rec.age_id
	  inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	  left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
	  inner join ccRIACampsGraph grap on grap.cam_id=inb.cam_id
	  where rec.grab_id = @grabId  )x
	  for xml path(''R02'')
	 )
 end
 else begin
	 set @xml = (
	 select * from (
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	   ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27'',rec.cam_id as ''@CID'',rec.tipo_llamada AS ''@CType''
	   from
	   RIA_GRABACIONCONSULTA rec
	   inner join ccinbound inb on rec.cam_id = inb.Inbound_id and rec.tipo_llamada  = 1
	   inner join ccUsers usr on usr.User_id = rec.age_id
	   inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	   left join ccTipoCalif AS e  ON rec.calif_id = e.calif_id
	   inner join ccRIAInboundGraph grap on grap.Inbound_id=inb.Inbound_id
	   where rec.grab_id = @grabId
	  union
	  select convert(varchar(23), rec.finicio, 126) as ''@CDATE'',rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'',inb.cam_descripcion as ''@C03'', isnull(@shoutLevel,0) as ''@C04'', usr.Login as ''@C05'',
	  convert(varchar(23), rec.finicio, 126) as ''@C06'',pos.Computer as ''@C07'',convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
	  rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',rec.cam_id as ''@C15'',
	  CONVERT(CHAR(8),DATEADD(second,rec.duracion,0),108) AS ''@C16'',
	  isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
	  isnull(e.Description,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
	  usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', isnull(@supervisor,'''') as ''@C24'', isnull(@Template,'''') as ''@C25''
	  ,grap.graphic_id as ''@C26'',@Prefijo as ''@C27'',rec.cam_id as ''@CID'',rec.tipo_llamada AS ''@CType''
	   from
	  RIA_GRABACIONCONSULTA rec
	  inner join cccamps inb on rec.cam_id = inb.cam_id and rec.tipo_llamada  = 2
	  inner join ccUsers usr on usr.User_id = rec.age_id
	  inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
	  left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
	  inner join ccRIACampsGraph grap on grap.cam_id=inb.cam_id
	  where rec.grab_id = @grabId  )x
	  for xml path(''R02'')
	 )
 end

if @xml is not null begin
	select @crmNode = node from ccCRMNodes where [type]= @callType and cal_id=@callID
	if @crmNode is not null begin
		update ccCRMNodes set grab_id=@grabId where [type]=@callType and cal_id=@callID
		set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(max),@crmNode)+'' into(/R02)[1]'''') ''
		execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
	end
end

if exists(select * from RIA_RecNodeHistory where grab_id=@grabId) begin
	update RIA_RecNodeHistory set node =@xml,[status]=2 where grab_id = @grabId
end
else if not exists(select * from ria_RecNode where grab_id=@grabId) begin
	if @xml is not null
		insert into ria_RecNode (grab_id,node,dateIn,[status]) values (@grabId,@xml, getdate(),0)
	else
		insert into ria_RecNode (grab_id,node,dateIn,[status]) values (@grabId,@xml, getdate(),-1)
end
else if @xml is not null begin
	update ria_RecNode set node =@xml,[status]=2  where grab_id = @grabId	
end
	--select @xml
end'
    EXEC(@Sql)    

    set @process = 'CW-2495 -- trsp_muevegrabaciones'
	set @Sql= 'ALTER PROCEDURE [dbo].[trsp_muevegrabaciones]
AS
BEGIN
declare @fecha datetime
declare @Integrado as int

select @integrado = par_valor from trec_parametros where par_id = 29
set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)


--AVRS XION
if (@integrado = 2) BEGIN       

       	INSERT INTO [RIA_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
			info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
			cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh)												
		SELECT grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
			info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
			cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG,califSub_id,cal_tMoh
		FROM [RIA_GRABACION] with(nolock, index(IX_RIA_GRABACION_3)) WHERE [finicio] < @fecha;		

		DELETE RIA_GRABACION with(rowlock) WHERE [finicio] < @fecha;
END
else BEGIN  --AVRS Integrada ó AVRS Stand Alone
       SET IDENTITY_INSERT TREC_GRABACIONCONSULTA ON

       INSERT INTO [TREC_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
			info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
			cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG)
       SELECT grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,dni,tamano,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
			info5,id_repositorio,id_nivel_grito,tipo_Llamada,cam_id,calif_id,cal_id,cal_key,cal_manual,cal_extension,cal_whoHung,cal_whoRec,id_plantilla,fvalida,fvalida2,borra_id,
			cal_fcallback,dni_id,extra_info,extra_info2,id_rep_video,video,IDWG
       FROM [TREC_GRABACION] with(nolock, index(IX_TREC_GRABACION_3)) WHERE [finicio] < @fecha;

       SET IDENTITY_INSERT TREC_GRABACIONCONSULTA OFF

       DELETE TREC_GRABACION with(rowlock) WHERE [finicio] < @fecha;
END
END'
    EXEC(@Sql)
		
	set @process = 'CW-2469 -- Clave de cifrado de grabaciones'
	set @Sql= 'if(not exists(select * from trec_parametros where par_id=75))
		insert trec_parametros values (75, ''Clave cifrado'', '''', ''Clave usada para la encripcion de grabaciones'')'
	EXEC(@Sql)
		
------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	select par_valor from trec_parametros where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end
 else begin
	select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
