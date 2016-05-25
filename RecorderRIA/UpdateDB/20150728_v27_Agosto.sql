/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: José Velasco
Date: 2015/07/28
Description: AVRS

	Add  column califSub_id en ria_grabacion
	Add  column califSub_id en ria_grabacionConsulta
	Insert value trec_parametros

	create SP  - trsp_AdmRecSearchCallIdStr

	Alter SP trsp_AdmRecSearchAllRecs
	Alter SP trsp_AdmRecSearchOneDay

Database: CCRecorderRia
Required version: 26

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @process nvarchar(max)
declare @sql nvarchar(max)
declare @errorGenerated nvarchar(max)
/* Version to release (use the version o
	f your own databse)*/
set @version = 27

/* Actual version (use your own script to do it) */
set @actualVersion =  (select par_valor from trec_parametros where par_id = 30)

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

	set @process = 'DROP CONSTRAINT [formacalifdefaulttotal]'
	set @Sql='if exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''formacalifdefaulttotal'')
	begin
		ALTER TABLE [dbo].[RIA_FORMACALIF] DROP CONSTRAINT [formacalifdefaulttotal]
	end'

	EXEC(@Sql)	

	set @process = 'Alter table RIA_FORMACALIF modify total_forma'
	set @Sql='ALTER TABLE RIA_FORMACALIF alter column total_forma  int'
	EXEC(@Sql)	

	set @process = 'ADD CONSTRAINT [formacalifdefaulttotal]'
	set @Sql='if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''formacalifdefaulttotal'')
	begin
		ALTER TABLE [dbo].[RIA_FORMACALIF] ADD  CONSTRAINT [formacalifdefaulttotal]  DEFAULT ((0)) FOR [total_forma]
	end'
	EXEC(@Sql)	

	/* Start script release */
	set @process = 'conversation - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''conversation'') begin
create table [conversation](
	conversationId [int] identity NOT NULL,
	inboundId [smallint] NOT NULL,
	info [varchar](255) NULL,
	isInbox [bit] NOT NULL,
	isFinished [bit] NOT NULL,
	mailClient [varchar] (60) NOT NULL,
	mailInbound [varchar](60) NULL,
	meanContactTypeId [smallint] NOT NULL
)
end'

	EXEC(@Sql)

	set @process = 'message - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''message'') begin
create table [message](
	messageId [int] identity NOT NULL,
	conversationId [int] NOT NULL,
	messageStatusId [int] NOT NULL,
	userId [smallint] NOT NULL,
	[date] [datetime] NOT NULL,
	tQueue [datetime] NULL,
	tWait [int] NOT NULL DEFAULT(0),
	tRetention [int] NOT NULL DEFAULT(0),
	tResponse [int] NOT NULL DEFAULT(0),
	tWrapUp [tinyint] NOT NULL DEFAULT(0),
	tSend [datetime] NULL,
	isSender bit NOT NULL DEFAULT(0)
)
end'
	EXEC(@sql)

	set @process = 'messageUnAssigned - Create Table'
	set @Sql='if not exists (select * from sys.tables where name = N''messageUnAssigned'') 	begin
	Create table messageUnAssigned(
		[messageId] [int] NOT NULL,
		userId [int] NOT NULL,
		time [int] NOT NULL DEFAULT(0),
		isLogout [bit] NOT NULL DEFAULT(0)
	)
end'
	EXEC(@Sql)

	
	set @process = ' - Drop if exists [trsp_AdmGetQualityTemplateScored]'
	set @Sql='if exists (select * from sys.procedures where name = N''trsp_AdmGetQualityTemplateScored'') DROP PROCEDURE trsp_AdmGetQualityTemplateScored'
	EXEC(@Sql)	

	set @process = 'add colum - ria_grabacion'
	set @sql='if not exists (select * from sys.columns where name = N''califSub_id'' and Object_ID = Object_ID(N''ria_grabacion''))  ALTER TABLE ria_grabacion ADD califSub_id  smallint NOT NULL DEFAULT 0 '
	EXEC(@sql)

	set @process = 'add colum - ria_grabacionConsulta'
	set @sql='if not exists (select * from sys.columns where name = N''califSub_id'' and Object_ID = Object_ID(N''ria_grabacionConsulta'')) ALTER TABLE ria_grabacionConsulta ADD califSub_id smallint NOT NULL DEFAULT 0 '
	EXEC(@sql)

	set @process = 'add colum - ria_grabacion'
	set @sql='if not exists (select * from sys.columns where name = N''cal_tMoh'' and Object_ID = Object_ID(N''ria_grabacion''))  ALTER TABLE ria_grabacion ADD cal_tMoh  smallint NOT NULL DEFAULT 0 '
	EXEC(@sql)

	set @process = 'add colum - ria_grabacionConsulta'
	set @sql='if not exists (select * from sys.columns where name = N''cal_tMoh'' and Object_ID = Object_ID(N''ria_grabacionConsulta'')) ALTER TABLE ria_grabacionConsulta ADD cal_tMoh smallint NOT NULL DEFAULT 0 '
	EXEC(@sql)

	set @process = 'Insert Value  - trec_parametros'  	
	set @sql='if not exists (select * from trec_parametros where par_id=72)
		insert into trec_parametros (par_id,par_descripcion,par_valor,par_detail) values (72,''Stop Video onDispositionApplied event'',0,''0 = Stop video onCallEnd event; 1 = Stop video onDispositionApplied event'')'


	set @process = 'trsp_AdmRecSearchCallIdStr - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmRecSearchCallIdStr'') DROP PROCEDURE trsp_AdmRecSearchCallIdStr'
  	EXEC(@sql)


	set @process = 'create SP  - trsp_AdmRecSearchCallIdStr'	
	set @sql='CREATE PROCEDURE [dbo].[trsp_AdmRecSearchCallIdStr]
@Sup_id int,
@callIdList as nvarchar(max)
AS
BEGIN

declare @fecha  datetime
declare @sql nvarchar(max)

    set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

    select r.id_grabacion, avg(r.total_forma) as total_forma
    into #tempRiaFormaCalif from ria_formacalif r 
    inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t 
    on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
    group by r.id_grabacion   
      
    select distinct a.IdCampEsp, a.Tipo as Tipo_llamada
    into #tempCampEspWG from ccRIACampEspWGConsulta a 
    inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = 6 and a.IDWG = b.IDWG

    set @sql = ''
      select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
      finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
      isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
      isnull (z.total_forma,0) as total_forma,a.id_repositorio,
      CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
      CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion, 
      a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
      from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))   
      left join ccPosicion b on b.pos_id = a.cal_extension * -1
      --left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
      left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
      left join ccTipoCalif AS f ON a.calif_id = f.calif_id
      left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
      left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
      inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
      where a.cal_id in(''+@callIdList+'')''+''
      union
      select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
      finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
      isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
      isnull (z.total_forma,0) as total_forma,a.id_repositorio,
      CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
      CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
      a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
      from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))   
      left join ccPosicion b on b.pos_id = a.cal_extension * -1
      --left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
      left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
      left join ccTipoCalif AS f ON a.calif_id = f.calif_id
      left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
      left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
      inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
      where a.cal_id in(''+@callIdList+'')''

      exec sp_executesql @sql

      drop table #tempRiaFormaCalif
      drop table #tempCampEspWG
END'	 
	EXEC(@sql)

	set @process = 'alter SP  - trsp_AdmRecSearchAllRecs'
	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchAllRecs]
@Sup_id int,
@Finicio datetime,
@Ffin datetime
AS
BEGIN

SET NOCOUNT ON

declare @sql1 nvarchar(max)
declare @sql2 nvarchar(max)
declare @sql3 nvarchar(max)

declare @sqlUnion nvarchar(max)
declare @maxDate datetime

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


SELECT @sql1 = CASE WHEN EXISTS (
	select top 1 1
	from RIA_GRABACION a with (index(IX_RIA_GRABACION_8))
	left join ccPosicion b on b.pos_id = a.cal_extension * -1
	left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
	left join ccTipoCalif AS f ON a.calif_id = f.calif_id
	left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )
	left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
	where a.finicio BETWEEN  @Finicio AND @Ffin and a.IDWG is not null
	) THEN ''select DISTINCT  a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito,
	a.age_id,a.finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
	isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
	isnull (z.total_forma,0) as total_forma,a.id_repositorio,
	CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
	CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
	grab_id as grabID, a.IDWG as IDWG,isnull( CASE WHEN a.tipo_llamada = 2  THEN k.califSubDesc ELSE p.califSubDesc END,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
	from RIA_GRABACION a with (index(IX_RIA_GRABACION_8))
	left join cctipocalifsubout k on k.califSub_id=a.califSub_id
	left join cctipocalifsub p on p.califSub_id=a.califSub_id
	left join ccPosicion b on b.pos_id = a.cal_extension * -1
	left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
	left join ccTipoCalif AS f ON a.calif_id = f.calif_id
	left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
	where a.IDWG is not null and a.finicio BETWEEN '''''' + cast(@Finicio as nvarchar) + '''''' AND '''''' + cast(@Ffin as nvarchar) + '''''''' ELSE '''' END


SELECT @sql2 = CASE WHEN EXISTS (
	select top 1 1
	from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
	left join ccPosicion b on b.pos_id = a.cal_extension * -1
	left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
	left join ccTipoCalif AS f ON a.calif_id = f.calif_id
	left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )
	left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
	left join #tempComplete U on  g.IDWG=U.IDWG and  g.tipo=U.Tipo_llamada and a.cam_id=U.IdCampEsp  and a.age_id=U.user_id
	where a.finicio BETWEEN  @Finicio AND @Ffin and U.IDWG is not null
	) THEN ''select  a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
	finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
	isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
	isnull (z.total_forma,0) as total_forma,a.id_repositorio,
	CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
	CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
	a.grab_id as grabID, cast(a.IDWG as nvarchar) as IDWG,isnull( CASE WHEN a.tipo_llamada = 2  THEN k.califSubDesc ELSE p.califSubDesc END,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
	from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
	left join cctipocalifsubout k on k.califSub_id=a.califSub_id
	left join cctipocalifsub p on p.califSub_id=a.califSub_id
	left join ccPosicion b on b.pos_id = a.cal_extension * -1
	left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
	left join ccTipoCalif AS f ON a.calif_id = f.calif_id
	left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )
	left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
	left join #tempComplete U on
	g.IDWG=U.IDWG and  g.tipo=U.Tipo_llamada and a.cam_id=U.IdCampEsp  and a.age_id=U.user_id
	where U.IDWG is not null and U.IDWG is not null and a.finicio BETWEEN '''''' + cast(@Finicio as nvarchar) + '''''' AND '''''' + cast(@Ffin as nvarchar) + '''''''' ELSE '''' END


 SELECT @sql3 = CASE WHEN EXISTS (
	 select top 1 1
	 from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
	 left join ccPosicion b on b.pos_id = a.cal_extension * -1
	 left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
	 left join ccTipoCalif AS f ON a.calif_id = f.calif_id
	 left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
	 where a.finicio BETWEEN  @Finicio AND @Ffin and a.IDWG is not null
	 ) THEN ''select DISTINCT  a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito,
	 a.age_id,a.finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
	 isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
	 isnull (z.total_forma,0) as total_forma,a.id_repositorio,
	 CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
	 CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
	 grab_id as grabID, cast(a.IDWG as nvarchar),isnull( CASE WHEN a.tipo_llamada = 2  THEN k.califSubDesc ELSE p.califSubDesc END,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
	 from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
	 left join cctipocalifsubout k on k.califSub_id=a.califSub_id
	 left join cctipocalifsub p on p.califSub_id=a.califSub_id
	 left join ccPosicion b on b.pos_id = a.cal_extension * -1
	 left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
	 left join ccTipoCalif AS f ON a.calif_id = f.calif_id
	 left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
	 where a.IDWG is not null and a.finicio BETWEEN '''''' + cast(@Finicio as nvarchar) + '''''' AND '''''' + cast(@Ffin as nvarchar) + '''''''' ELSE '''' END

 select @sqlUnion = '' union ''

  if (@sql1 <> '''' and @sql2 <> '''' and @sql3 <> '''' )
     exec (@sql1 + @sqlUnion + @sql2 + @sqlUnion + @sql3 )
  else if (@sql1 <> '''' and @sql2 <> '''' and @sql3 = '''')
     exec (@sql1 + @sqlUnion + @sql2 )
  else if (@sql1 <> '''' and @sql2 = '''' and @sql3 <> '''')
     exec (@sql1 + @sqlUnion + @sql3 )
  else if (@sql1 = '''' and @sql2 <> '''' and @sql3 <> '''')
     exec (@sql2 + @sqlUnion + @sql3 )
  else if (@sql1 <> '''' and @sql2 = '''' and @sql3 = '''')
     exec (@sql1 )
  else if (@sql1 = '''' and @sql2 <> '''' and @sql3 = '''')
     exec (@sql2 )
  else if (@sql1 = '''' and @sql2 = '''' and @sql3 <> '''')
     exec (@sql3 )

drop table #tempRiaFormaCalif
drop table #tempCampEspWG
drop table #tempComplete

END'
	EXEC(@Sql)


	set @process = 'alter SP  - trsp_AdmRecSearchOneDay'
	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchOneDay]
@Sup_id int

AS
BEGIN

declare @sql1 nvarchar(max)

select r.id_grabacion, avg(r.total_forma) as total_forma
into #tempRiaFormaCalif2 from ria_formacalif r 
inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t 
on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
group by r.id_grabacion   

select distinct a.IdCampEsp, a.Tipo as Tipo_llamada
into #tempCampEspWG2 from ccRIACampEspWGConsulta a 
inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG

select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
into #tempComplete2
from  ccRIACampEspWGConsulta a inner join 
(select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in (select  distinct a.IDWG
from ccRIACampEspWGConsulta a 
inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG) 
and user_id <> @Sup_id) b
on a.IDWG=b.IDWG 


SELECT @sql1 = CASE WHEN EXISTS (
  select top 1 1 
  from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))   
  left join ccPosicion b on b.pos_id = a.cal_extension * -1
  left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
  left join ccTipoCalif AS f ON a.calif_id = f.calif_id
  left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )       
  left join #tempRiaFormaCalif2 z on a.grab_id=z.id_grabacion
  left join #tempComplete2 U on
  g.IDWG=U.IDWG and  g.tipo=U.Tipo_llamada and a.cam_id=U.IdCampEsp  and a.age_id=U.user_id
  where a.finicio >= Convert(nvarchar(11),Getdate(),120) and U.IDWG is not null 
  ) THEN ''select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
  finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
  isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
  isnull (z.total_forma,0) as total_forma,a.id_repositorio,
  CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
  CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
  a.grab_id as grabID, isnull(g.IDWG,0)as IDWG,isnull( CASE WHEN a.tipo_llamada = 2  THEN k.califSubDesc ELSE p.califSubDesc END,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
  from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))  
  left join cctipocalifsubout k on k.califSub_id=a.califSub_id
  left join cctipocalifsub p on p.califSub_id=a.califSub_id 
  left join ccPosicion b on b.pos_id = a.cal_extension * -1
  left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
  left join ccTipoCalif AS f ON a.calif_id = f.calif_id
  left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )       
  left join #tempRiaFormaCalif2 z on a.grab_id=z.id_grabacion
  left join #tempComplete2 U on
  g.IDWG=U.IDWG and  g.tipo=U.Tipo_llamada and a.cam_id=U.IdCampEsp  and a.age_id=U.user_id
  where U.IDWG is not null and a.finicio >= '''''' + Convert(nvarchar(11),Getdate(),120) + '''''''' ELSE '''' END

  if (@sql1 <> '''' )
    exec (@sql1 )

  drop table #tempRiaFormaCalif2
  drop table #tempCampEspWG2  
  drop table #tempComplete2 
END'
	EXEC(@Sql) 

  set @process = 'ALTER procedure [dbo].[trsp_InsertRecNode]---------------------'
  set @sql='ALTER procedure [dbo].[trsp_InsertRecNode]
@grabId int,
@type int
as
begin

declare @sql as nvarchar(max)
declare @callType as nvarchar(20)
declare @shoutLevel as nvarchar(20)
declare @date as datetime
declare @formatedDate as nvarchar(50)
declare @language as int
declare @start as int
declare @country as int
declare @xml as xml
declare @crmNode as xml
declare @manual as nvarchar(10)
declare @rating as nvarchar(20)
declare @sqlCRM nvarchar(2000)
declare @supervisor as nvarchar(50)
declare @template as nvarchar(50)
declare @callID as nvarchar(50)

	declare @table as nvarchar(20)
	set @table=''RIA''
	--declare @score as nvarchar(20)

	--Get languange
	set @language = (
			select valor
			from ccSettings
			where setting_id = 27)

	--Get call type
	set @callType = (
			select tipo_llamada
			from ria_grabacion
			where grab_id = @grabId)

	--Get shout level
	set @shoutlevel = (
			select sho.nombre_nivel
			from
			ria_grabacion rec
			inner join ria_tipo_gritos sho
			on rec.id_nivel_grito = sho.id_nivel_grito
where rec.grab_id = @grabId
)

set @start = (
		select charindex(''|'',@shoutLevel)
)

--Spanish
if @language = 0
		begin
				set @shoutlevel = (
					select substring(@shoutlevel,0,@start)
				)
		end
else
		begin
				set @shoutlevel = (
					select substring(@shoutlevel,(@start+1),(LEN(@shoutlevel)-1))
				)
		end

--Get date
set @date = (
		select finicio
		from ria_grabacion
		where grab_id = @grabId )

--Set format date
set @formatedDate = (
		select convert(varchar(23), @date, 126))

--Call manual
declare @manualId as int

set @manualId = (
		select cal_manual
		from RIA_GRABACION
		where grab_id = @grabId
)

if @manualId = 0
		begin
				set @manual = (''N/A'')
		end
else
		begin
				set @manual = (''Manual'')
		end

--Get rating
set @rating = (
		select  top 1 isnull (total_forma,0)
		from ria_formacalif
		where id_grabacion = @grabId order by fecha_calif desc)



----Get score
--set @score = (
--     select   top 1 isnull (total_forma,0)
--     from ria_formacalif
--     where id_grabacion = @grabId order by fecha_calif desc

--     --left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
--     --left join ccTipoCalif AS f ON a.calif_id = f.calif_id
--     )


/*
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
		C16-----> Duration Recording as 00:00:00
		C17-----> Position Extension
		C18-----> rating(Scoring Template)
		C19-----> Reposiory ID
		C20-----> Disposition
		C21-----> Disposition ID
		C22-----> Has Video
		C23-----> Agent Full Name
		C24-----> Supervisor Name
		c25-----> Score Template
*/

if @type =0 ---Process to Insert
BEGIN

	if @callType = 1 --Inbound
		BEGIN

			select  @callID = cal_id from ria_grabacion where grab_id = @grabId

			set @xml = (
				select top 1 rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',
				@formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
				rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
				CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2)
				+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
				isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
				CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
				usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'','''' as ''@C24'','''' as ''@C25'',usr.Login as ''@C26''
			from
			ria_grabacion rec
			inner join ccRIAWorkGroup_Calid wgc on rec.cal_id = wgc.cal_id
			inner join ccriacat_workgroup cwg on wgc.IDWG = cwg.IDWG
			inner join ccRIACampEspWGConsulta cewg on cwg.IDWG = cewg.IDWG
			inner join ccinbound inb on cewg.IdCampEsp = inb.Inbound_id
			inner join ccUsers usr on usr.User_id = rec.age_id
			inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
			inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
			left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
			left join ccTipoCalif AS f  ON rec.calif_id = f.calif_id
			where
			(rec.tipo_llamada = 1)
			and (cewg.Tipo = 0)
			and (wgc.tipo = 0)
			and (inb.chat = 0)
			and (rec.cam_id=cewg.IdCampEsp )
			and (rec.grab_id = @grabId)

			for xml path(''R02''))

			--Get crm node
			if @xml is not null
			  begin
				select @crmNode = node from ccCRMNodes where [type]=1 and cal_id=@callID
				if @crmNode is not null
					begin
							update ccCRMNodes set grab_id=@grabId where [type]=1 and cal_id=@callID
							set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
							execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
					end
			end


		END
	else
		BEGIN

			select  @callID = cal_id from ria_grabacion where grab_id = @grabId

			set @xml = (
				select top 1 rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'', inb.cam_descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',
				@formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
				rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
				CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2)
				+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
				isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
				CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
				usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'','''' as ''@C24'','''' as ''@C25'',usr.Login as ''@C26''
			from
			ria_grabacion rec
			inner join ccRIAWorkGroup_Calid wgc on rec.cal_id = wgc.cal_id
			inner join ccriacat_workgroup cwg on wgc.IDWG = cwg.IDWG
			inner join ccRIACampEspWG cewg on cwg.IDWG = cewg.IDWG
			inner join cccamps inb on cewg.IdCampEsp = inb.cam_id
			inner join ccUsers usr on usr.User_id = rec.age_id
			inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
			inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
			left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
			left join ccTipoCalif AS f  ON rec.calif_id = f.calif_id
			where
			(rec.tipo_llamada = 2)
			and (cewg.Tipo = 1)
			and (wgc.tipo = 1)
			and (rec.cam_id=cewg.IdCampEsp )
			and (rec.grab_id = @grabId)
			for xml path(''R02''))

			--Get crm node
			if @xml is not null
				begin
					select @crmNode = node from ccCRMNodes where [type]=2 and cal_id=@callID
					if @crmNode is not null
						begin
								update ccCRMNodes set grab_id=@grabId where [type]=2 and cal_id=@callID
								set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
								execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
						end
				end

		END

			if (@xml IS NOT NULL)
				insert into ria_RecNode (grab_id,node,dateIn,[status]) values (@grabId,@xml, getdate(),0)

END

if @type =1 ---Process to Update
BEGIN
if (select count (*) grab_id from RIA_GRABACION where grab_id=@grabId) > 0
	begin -- Node in RIA_GRABACION
		select @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
		RIA_FORMATOS as formatos
		inner join RIA_FORMACALIF formatosCalif on formatosCalif.id_formato=formatos.id_formato
		inner join RIA_GRABACION grabacion  on grabacion.grab_id= formatosCalif.id_grabacion
		inner join ccUsers supervisor on supervisor.User_id = formatosCalif.id_supervisor
		where
		formatosCalif.tipo=1
		and grabacion.grab_id=@grabId

		if @callType = 1
		BEGIN

			select  @callID = cal_id from ria_grabacion where grab_id = @grabId

			set @xml = (
				select top 1 rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',
				@formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
				rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
				CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2)
				+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
				isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
				CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
				usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', @supervisor as ''@C24'',@Template as ''@C25'',usr.Login as ''@C26''
			from
			ria_grabacion rec
			inner join ccRIAWorkGroup_Calid wgc on rec.cal_id = wgc.cal_id
			inner join ccriacat_workgroup cwg on wgc.IDWG = cwg.IDWG
			inner join ccRIACampEspWGConsulta cewg on cwg.IDWG = cewg.IDWG
			inner join ccinbound inb on cewg.IdCampEsp = inb.Inbound_id
			inner join ccUsers usr on usr.User_id = rec.age_id
			inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
			inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
			left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
			left join ccTipoCalif AS f  ON rec.calif_id = f.calif_id
			where
			(rec.tipo_llamada = 1)
			and (cewg.Tipo = 0)
			and (wgc.tipo = 0)
			and (inb.chat = 0)
			and (rec.cam_id=cewg.IdCampEsp )
			and (rec.grab_id = @grabId)

			for xml path(''R02''))

			--Get crm node
			if @xml is not null
				begin

				select @crmNode = node from ccCRMNodes where [type]=1 and cal_id=@callID
				if @crmNode is not null
					begin
							update ccCRMNodes set grab_id=@grabId where [type]=1 and cal_id=@callID
							set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
							execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
					end
				end


		END
		else
			BEGIN
				select  @callID = cal_id from ria_grabacion where grab_id = @grabId

				set @xml = (
					select  top 1  rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'', inb.cam_descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',
					@formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
					rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
					CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2)
					+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
					isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
					CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
					usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',@supervisor as ''@C24'',@Template as ''@C25'',usr.Login as ''@C26''
				from
				ria_grabacion rec
				inner join ccRIAWorkGroup_Calid wgc on rec.cal_id = wgc.cal_id
				inner join ccriacat_workgroup cwg on wgc.IDWG = cwg.IDWG
				inner join ccRIACampEspWG cewg on cwg.IDWG = cewg.IDWG
				inner join cccamps inb on cewg.IdCampEsp = inb.cam_id
				inner join ccUsers usr on usr.User_id = rec.age_id
				inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
				inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
				left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
				left join ccTipoCalif AS f  ON rec.calif_id = f.calif_id
				where
				(rec.tipo_llamada = 2)
				and (cewg.Tipo = 1)
				and (wgc.tipo = 1)
				and (rec.cam_id=cewg.IdCampEsp )
				and (rec.grab_id = @grabId)
				for xml path(''R02''))

				--Get crm node
				if @xml is not null
					begin
						select @crmNode = node from ccCRMNodes where [type]=2 and cal_id=@callID
						if @crmNode is not null
							begin
									update ccCRMNodes set grab_id=@grabId where [type]=2 and cal_id=@callID
									set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
									execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
							end
					end

			END


		end
else   -- Node in RIA_GRABACIONCONSULTA
	begin
		select @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
		RIA_FORMATOS as formatos
		inner join RIA_FORMACALIF formatosCalif
			on formatosCalif.id_formato=formatos.id_formato
		inner join RIA_GRABACIONCONSULTA grabacion
			on grabacion.grab_id= formatosCalif.id_grabacion
		inner join ccUsers supervisor
			on supervisor.User_id = formatosCalif.id_supervisor
		where
		formatosCalif.tipo=1
		and grabacion.grab_id=@grabId

		if @callType = 1
		BEGIN
			select  @callID = cal_id from ria_grabacionconsulta where grab_id = @grabId

			set @xml = (
				select rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',
				@formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
				rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
				CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2)
				+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
				isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
				CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
				usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',@supervisor as ''@C24'',@Template as ''@C25'' ,usr.Login as ''@C26''
			from ria_grabacionconsulta rec
			inner join ccRIAWorkGroup_Calid wgc on rec.cal_id = wgc.cal_id
			inner join ccriacat_workgroup cwg on wgc.IDWG = cwg.IDWG
			inner join ccRIACampEspWGConsulta cewg on cwg.IDWG = cewg.IDWG
			inner join ccinbound inb on cewg.IdCampEsp = inb.Inbound_id
			inner join ccUsers usr on usr.User_id = rec.age_id
			inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
			inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
			left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
			left join ccTipoCalif AS f  ON rec.calif_id = f.calif_id
			where
			(rec.tipo_llamada = 1)
			and (cewg.Tipo = 0)
			and (wgc.tipo = 0)
			and (inb.chat = 0)
			and (rec.cam_id=cewg.IdCampEsp )
			and (rec.grab_id = @grabId)

			for xml path(''R02''))

			--Get crm node
			if @xml is not null
				begin
					select @crmNode = node from ccCRMNodes where [type]=1 and cal_id=@callID
					if @crmNode is not null
						begin
								update ccCRMNodes set grab_id=@grabId where [type]=1 and cal_id=@callID
								set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
								execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
						end
				end
		END
		else
			BEGIN

				select  @callID = cal_id from ria_grabacionconsulta where grab_id = @grabId

				set @xml = (
					select rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'', inb.cam_descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',
					@formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'',
					rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
					CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2)
					+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
					isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
					CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
					usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',@supervisor as ''@C24'',@Template as ''@C25'',usr.Login as ''@C26''
				from
				ria_grabacionconsulta rec
				inner join ccRIAWorkGroup_Calid wgc on rec.cal_id = wgc.cal_id
				inner join ccriacat_workgroup cwg on wgc.IDWG = cwg.IDWG
				inner join ccRIACampEspWG cewg on cwg.IDWG = cewg.IDWG
				inner join cccamps inb on cewg.IdCampEsp = inb.cam_id
				inner join ccUsers usr on usr.User_id = rec.age_id
				inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
				inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1
				left join ccTipoCalifOUT AS e  ON rec.calif_id = e.calif_id
				left join ccTipoCalif AS f  ON rec.calif_id = f.calif_id
				where
				(rec.tipo_llamada = 2)
				and (cewg.Tipo = 1)
				and (wgc.tipo = 1)
				and (rec.cam_id=cewg.IdCampEsp )
				and (rec.grab_id = @grabId)
				for xml path(''R02''))

				--Get crm node
				if @xml is not null
						begin
								select @crmNode = node from ccCRMNodes where [type]=2 and cal_id=@callID
								if @crmNode is not null
									begin
											update ccCRMNodes set grab_id=@grabId where [type]=2 and cal_id=@callID
											set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
											execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
									end
						end

			END

		end


		if (@xml IS NOT NULL)
			update ria_RecNode set node =@xml,[status]=2 where grab_id = @grabId

END


end'
  EXEC(@sql)
 
  	set @process = 'CREATE PROCEDURE [dbo].[trsp_AdmGetQualityTemplateScored] ------'
	set @Sql='CREATE PROCEDURE [dbo].[trsp_AdmGetQualityTemplateScored]
@id_chat int,
@id_formato int=2
AS
BEGIN
	SET NOCOUNT ON;
	select total_forma from [dbo].[RIA_FORMACALIF] where id_grabacion = @id_chat AND tipo=@id_formato AND id_formato=@id_formato
END'
	EXEC(@Sql)

	set @process = 'ALTER PROCEDURE [dbo].[trsp_AdmSaveChatScoresFormaCalif]'
	set @Sql='ALTER PROCEDURE [dbo].[trsp_AdmSaveChatScoresFormaCalif]
@chat_id int,
@id_calificador int,
@id_supervisor int,
@id_formato int,
@total_forma int,
@age_id int,
@version int,
@typeServices tinyint =2

AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @cam_id int 
if @typeServices = 2 begin
	select @cam_id= InboundId from ccriachats where chatId = @chat_id
end
else if @typeServices = 3 begin
	select  @cam_id=min(B.inboundId) from message A
	inner join conversation B on A.conversationId=A.conversationId
	where A.messageId=@chat_id
end


insert RIA_FORMACALIF (fecha_calif,id_calificador,id_supervisor,id_grabacion,id_formato,total_forma,age_id,version, tipo,cam_id)
values (GetDate(),@id_calificador,@id_supervisor,@chat_id,@id_formato,@total_forma,@age_id,@version, @typeServices,@cam_id)

select Scope_Identity()

END'
	EXEC(@Sql)

	set @process = 'ALTER PROCEDURE [dbo].[trsp_AdmVerifyingChatFormatEditing] ------'
	set @Sql='ALTER PROCEDURE [dbo].[trsp_AdmVerifyingChatFormatEditing]
@id_chat int,
@id_formato int,
@type tinyint = 2


AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

declare @grab_id int, @id_forma int

	-- Insert statements for procedure here

Select @id_forma = isnull(id_forma,0) from CCRecorderRIA.dbo.RIA_FORMACALIF where id_grabacion = @id_chat and id_formato = @id_formato and tipo=@type

--Retrieving the id forma
select isnull(@id_forma,0)

END'
	EXEC(@Sql)

	set @process = 'ALTER PROCEDURE [dbo].[trsp_GetTemplateandSupervisor] ------'
	set @Sql='ALTER PROCEDURE [dbo].[trsp_GetTemplateandSupervisor] 
@type integer = 2,
@sIdChat Integer
AS

declare @supervisor as nvarchar(50)
declare @template as nvarchar(50)

select top 1 @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
		RIA_FORMATOS as formatos inner join RIA_FORMACALIF formatosCalif on formatosCalif.id_formato=formatos.id_formato
		inner join ccUsers supervisor on supervisor.User_id = formatosCalif.id_supervisor
		where formatosCalif.tipo=@type and formatosCalif.id_grabacion=@sIdChat order by formatosCalif.fecha_calif desc	

select @Template,@supervisor'
	EXEC(@Sql)

    set @process = 'trsp_AdmRecSearchNodeSubCalif - Drop if exists'
    set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmRecSearchNodeSubCalif'') DROP PROCEDURE trsp_AdmRecSearchNodeSubCalif'
    EXEC(@sql)


    set @process = 'create SP  - trsp_AdmRecSearchNodeSubCalif'    
    set @sql='CREATE PROCEDURE [dbo].[trsp_AdmRecSearchNodeSubCalif]
	@calif_id int,
	@CallType int

	AS
	BEGIN

	SET NOCOUNT ON;

	IF @CallType = 0 
	BEGIN
	      select distinct(A.califSub_id),A.califSubDesc from cctipocalifsubout as A 
	      inner join cctiposubcalifrel B  on B.calif_id=@calif_id
	      where  B.tipoSubRel=0 and b.califSub_id=A.califSub_id

	END

	ELSE IF @CallType = 1 
	BEGIN
	      select distinct(A.califSub_id),A.califSubDesc from cctipocalifsub as A 
	      inner join cctiposubcalifrel B  on B.calif_id=@calif_id
	      where  B.tipoSubRel=1 and b.califSub_id=A.califSub_id
	END
END'       
    EXEC(@sql)



		set @process = 'alter SP  - trsp_AdmAVRSReportDemo'            
        set @sql='ALTER PROCEDURE [dbo].[trsp_AdmAVRSReportDemo]
@id_formato int,
@version int,
@call_id int,
@tipo int,
@medio int

AS

BEGIN
       CREATE TABLE #tbl_ReporteConcepto(id int primary key identity(1,1),id_concepto int,concepto varchar(max));
       CREATE TABLE #tbl_ReportePregunta(id int primary key identity(1,1),id_pregunta int,pregunta varchar(max),id_concepto int,respuesta nvarchar(max),peso int,valor int);
       CREATE TABLE #tbl_Reporte(id int primary key identity(1,1),conceptopregunta varchar(max),respuesta varchar(max),puntos nvarchar(max),valorTotal nvarchar(max));

       declare @iter as int
       declare @iter1 as int
       declare @id_concepto int
       declare @respuesta varchar(max)
       declare @idForma as int
       declare @id_grabacion as int
       set @iter=1
       set @iter1=1
       
       if @medio =1
          BEGIN
                IF EXISTS (select grab_id from ria_grabacion where cal_id=@call_id and tipo_llamada=@tipo)
                   BEGIN
            
                          set @id_grabacion = (select grab_id from RIA_GRABACION where cal_id=@call_id and tipo_llamada=@tipo)

                   END
                ELSE
                   BEGIN

                          set @id_grabacion = (select grab_id from RIA_GRABACIONCONSULTA where cal_id=@call_id and tipo_llamada=@tipo)
            
                   END
          
                set @idForma=(select top 1 id_forma from ria_formacalif where id_grabacion=@id_grabacion and id_formato=@id_formato and version =@version order by id_forma desc)
          END
       else
          BEGIN
                set @id_grabacion = @call_id

                set @idForma=(select top 1  id_forma from ria_formacalif where id_grabacion=@id_grabacion and id_formato=@id_formato and version =@version order by id_forma desc)
                
          END


       INSERT into #tbl_ReporteConcepto select id_concepto,con_descripcion from RIA_CONCEPTOS where id_formato=@id_formato and version=@version

       while @iter <=(select count(1)  from #tbl_ReporteConcepto)
       begin
              select @id_concepto=id_concepto from #tbl_ReporteConcepto where id=@iter
              INSERT into #tbl_ReportePregunta  SELECT  RIA_PREGUNTAS.id_pregunta, RIA_PREGUNTAS.enunciado_pregunta, RIA_PREGUNTAS.id_concepto,RIA_RESULTADOSFORMA.etiquetas, RIA_RESULTADOSFORMA.peso,RIA_PREGUNTAS.peso
                                         FROM         RIA_PREGUNTAS INNER JOIN
                                          RIA_RESULTADOSFORMA ON RIA_PREGUNTAS.id_pregunta = RIA_RESULTADOSFORMA.id_pregunta
                                          where id_concepto=@id_concepto and RIA_RESULTADOSFORMA.id_forma=@idForma;
       set @iter = @iter+1;
       end

       while @iter1 <= (select count(1)  from #tbl_ReporteConcepto) 
       begin
              INSERT into #tbl_Reporte select concepto,'''','''','''' from #tbl_ReporteConcepto where id=@iter1
              select @id_concepto=id_concepto from #tbl_ReporteConcepto where id=@iter1
             INSERT into #tbl_Reporte select pregunta,respuesta,peso,valor from #tbl_ReportePregunta where id_concepto=@id_concepto
              set @iter1 = @iter1+1;
       end    

       INSERT into #tbl_Reporte
       select ''Total'','''',convert(nvarchar(max),sum(convert(int,puntos)))as peso,convert(nvarchar(max),sum(convert(int,valorTotal)))as valor From #tbl_Reporte
       
       select * from #tbl_Reporte

END'
    EXEC(@Sql)

    set @process = 'alter SP  - trsp_AdmSaveScoresFormaCalif'             
    set @sql='ALTER PROCEDURE [dbo].[trsp_AdmSaveScoresFormaCalif]
-- Add the parameters for the stored procedure here

@cal_id int,
@tipo_llamada int,
@id_calificador int,
@id_supervisor int,
@id_formato int,
@total_forma int,
@version int


AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

       -- Insert statements for procedure here

declare @grab_id bigint,@cam_id int, @age_id int


set @grab_id = (select grab_id from (select grab_id from RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)
set @cam_id = (select cam_id from (select cam_id from CCRecorderRIA.dbo.RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select cam_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)
set @age_id = (select age_id from (select age_id from CCRecorderRIA.dbo.RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select age_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)


Insert RIA_FORMACALIF (fecha_calif,id_calificador,id_supervisor,id_grabacion,id_formato,total_forma,age_id,version,tipo,tipo_llamada,cam_id)
values (GetDate(),@id_calificador,@id_supervisor,@grab_id,@id_formato,@total_forma,@age_id,@version, 1,@tipo_llamada,@cam_id)

select Scope_Identity()

exec trsp_InsertRecNode @grab_id,1


END'

	EXEC(@Sql)

	set @process = 'alter SP  - trsp_AdmRecSearchCalID'
	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchCalID]
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
	 CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
	 grab_id as grabID, a.IDWG as IDWG,isnull( CASE WHEN a.tipo_llamada = 2  THEN k.califSubDesc ELSE p.califSubDesc END,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
	 from RIA_GRABACION a with (index(IX_RIA_GRABACION_8))
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
	 CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
	 grab_id as grabID, a.IDWG as IDWG,isnull( CASE WHEN a.tipo_llamada = 2  THEN k.califSubDesc ELSE p.califSubDesc END,'''') AS califSub_id,a.cal_tMoh as cal_tMoh
	 from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
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
       '
EXEC(@Sql)



	/* End script release */

		/* Upgrade database version (use your own script to do it) */
		update trec_parametros set par_valor = @Version where par_id = 30

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off