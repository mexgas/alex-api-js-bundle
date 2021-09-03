/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/* 
Author: José Velasco
Date: 2015/03/10
Description: Update Marzo 2015 AVRS

  Se creat el SP trsp_AdmRecSearchCallIdStr
  
  Se actualiza el SP trsp_GetAppParameters
  Se actualiza el SP trsp_AdmRecSearchOneDay
  Se actualiza el SP trsp_AdmRecSearchAllRecs

Database: CCRecorderRia
Required version: 24

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 25

/* Actual version (use your own script to do it) */
set @actualVersion =  (select par_valor from trec_parametros where par_id = 30)

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

	/* Start script release */  	

  set @process = 'trsp_AdmRecSearchCallIdStr - Drop if exists'
  set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmRecSearchCallIdStr'') DROP PROCEDURE trsp_AdmRecSearchCallIdStr'
  EXEC(@sql)


  set @process = 'create SP  - trsp_AdmRecSearchCallIdStr'
  if exists (select * from sys.procedures where name = N'trsp_AdmRecSearchCallIdStr')
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
  else
    set @sql = ''

  EXEC(@sql)

  set @process = 'alter SP  - trsp_GetAppParameters'
  if exists (select * from sys.procedures where name = N'trsp_GetAppParameters')
  set @sql='ALTER PROCEDURE [dbo].[trsp_GetAppParameters]
  @app_id AS INT
    AS
    BEGIN
    DECLARE  @avrs_enviroment AS INT
    DECLARE @SQL AS NVARCHAR(MAX)

    --AVRS Record Manager
    IF @app_id = 1
    BEGIN
      SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

        IF @avrs_enviroment = 2
          BEGIN
        
            SET @SQL = ''SELECT par_valor,par_id 
                  FROM TREC_PARAMETROS 
                  WHERE par_id 
                  IN (67,68,69,70)
                  ORDER BY par_id''                      
          END 
        ELSE
          BEGIN

            SET @SQL = ''SELECT * FROM
                  (SELECT par_valor,par_id FROM TREC_PARAMETROS 
                  WHERE par_id in (33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,61,62,63,29,2,65,67)
                  UNION
                  SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
                  FROM TREC_GRABACION)x
                  ORDER BY x.par_id''
          END
    END

    EXEC sp_executesql @SQL

    END'
  else
    set @sql = ''

  EXEC(@sql)



  set @process = 'alter SP  - trsp_AdmRecSearchOneDay'
  if exists (select * from sys.procedures where name = N'trsp_AdmRecSearchOneDay')
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
  a.grab_id as grabID, isnull(g.IDWG,0)as IDWG
  from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))   
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
  else
    set @sql = ''

  EXEC(@sql)



  set @process = 'alter SP  - trsp_AdmRecSearchAllRecs'
  if exists (select * from sys.procedures where name = N'trsp_AdmRecSearchAllRecs')
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
  from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))   
  left join ccPosicion b on b.pos_id = a.cal_extension * -1
  left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
  left join ccTipoCalif AS f ON a.calif_id = f.calif_id
  left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )       
  left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
  left join #tempComplete U on
  g.IDWG=U.IDWG and  g.tipo=U.Tipo_llamada and a.cam_id=U.IdCampEsp  and a.age_id=U.user_id
  where a.finicio BETWEEN  @Finicio AND @Ffin and U.IDWG is not null  
  ) THEN ''select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
  finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
  isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
  isnull (z.total_forma,0) as total_forma,a.id_repositorio,
  CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
  CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
  a.grab_id as grabID, isnull(g.IDWG,0)as IDWG
  from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))   
  left join ccPosicion b on b.pos_id = a.cal_extension * -1
  left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
  left join ccTipoCalif AS f ON a.calif_id = f.calif_id
  left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )       
  left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
  left join #tempComplete U on
  g.IDWG=U.IDWG and  g.tipo=U.Tipo_llamada and a.cam_id=U.IdCampEsp  and a.age_id=U.user_id
  where U.IDWG is not null and a.finicio BETWEEN '''''' + cast(@Finicio as nvarchar) + '''''' AND '''''' + cast(@Ffin as nvarchar) + '''''''' ELSE '''' END --+  and U.IDWG is not null 


select @sql2 = '' union ''

SELECT @sql3 = CASE WHEN EXISTS (
  select top 1 1 
  from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))     
  left join ccPosicion b on b.pos_id = a.cal_extension * -1
  left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
  left join ccTipoCalif AS f ON a.calif_id = f.calif_id
  left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )       
  left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
  left join #tempComplete U on
  g.IDWG=U.IDWG and  g.tipo=U.Tipo_llamada and a.cam_id=U.IdCampEsp  and a.age_id=U.user_id
  where a.finicio BETWEEN  @Finicio AND @Ffin and U.IDWG is not null
  ) THEN ''select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
  finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
  isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
  isnull (z.total_forma,0) as total_forma,a.id_repositorio,
  CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
  CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
  a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
  from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))     
  left join ccPosicion b on b.pos_id = a.cal_extension * -1
  left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
  left join ccTipoCalif AS f ON a.calif_id = f.calif_id
  left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 )       
  left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
  left join #tempComplete U on
  g.IDWG=U.IDWG and  g.tipo=U.Tipo_llamada and a.cam_id=U.IdCampEsp  and a.age_id=U.user_id 
  where U.IDWG is not null and a.finicio BETWEEN '''''' + cast(@Finicio as nvarchar) + '''''' AND '''''' + cast(@Ffin as nvarchar) + '''''''' ELSE '''' END --+ '' and U.IDWG is not null ''


  if (@sql1 <> '''' and @sql3 <> '''')
    exec (@sql1 + @sql2 + @sql3)
  else if (@sql1 <> '''' and @sql3 = '''')
    exec (@sql1)
  else if (@sql1 = '''' and @sql3 <> '''')
    exec (@sql3)
  else
    exec (@sql1)

  --if (@sql1 <> '''' and @sql3 <> '''')
  --  print (@sql1 + @sql2 + @sql3)
  --else if (@sql1 <> '''' and @sql3 = '''')
  --  print (@sql1)
  --else if (@sql1 = '''' and @sql3 <> '''')
  --  print (@sql3)
  --else
  --  print (@sql1)
        
drop table #tempRiaFormaCalif
drop table #tempCampEspWG 
drop table #tempComplete

END'
  else
    set @sql = ''

  EXEC(@sql)

	



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