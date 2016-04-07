/*
Date: 2016/03/04
Description: 


 Drop PROCEDURE trsp_SaveAVRSExportParameters 
 Create PROCEDURE trsp_SaveAVRSExportParameters

 Alter SP trsp_AdmRecSearchNodeWgCampACDCalif
 Alter SP trsp_GetRecordigsExportService

Database: CCRecorderRia
Required version: 32
*/

SET nocount ON
DECLARE @Version VARCHAR(10) 
DECLARE @Version_Actual VARCHAR(10)
DECLARE @Process VARCHAR(MAX)
DECLARE @Sql NVARCHAR(MAX)
DECLARE @errorGenerated VARCHAR(max)


/* Version to release (use the version of your own databse)*/
set @version = 33

/* Actual version (use your own script to do it) */
select @Version_Actual=par_valor from trec_parametros where par_id = 30

if @Version_Actual=@Version-1
BEGIN
BEGIN TRAN 
BEGIN TRY

	--Index
	
	--Tables
	
	--Functions

  	--SP

  	set @process = 'trsp_SaveAVRSExportParameters - Drop if exists'
  	set @sql='if exists (select * from sys.procedures where name = N''trsp_SaveAVRSExportParameters'') DROP PROCEDURE trsp_SaveAVRSExportParameters'
  	EXEC(@sql)


	set @process = 'Create PROCEDURE trsp_SaveAVRSExportParameters '
  	set @sql='CREATE PROCEDURE [dbo].[trsp_SaveAVRSExportParameters]
	@export_mode AS INT,
	@netcred_id AS INT = -1,
	@net_user AS VARCHAR(100) = '''',
	@net_password AS VARCHAR(100) = '''',
	@net_sever AS VARCHAR(max) = '''',
	@net_path AS VARCHAR(max) = '''',
	@ftp_user AS VARCHAR(100) = '''',
	@ftp_password AS VARCHAR(100) = '''',
	@ftp_sever AS VARCHAR(max) = '''',
	@ftp_path AS VARCHAR(max) = '''',
	@ftp_port AS INT = -1,
	@ftp_protocol AS INT = -1,
	@time_export AS VARCHAR(20) = '''',
	@grabid_start AS INT = -1,
	@csv_log AS INT = -1,
	@delete_rec AS INT = -1,
	@export_format AS INT = 1,
	@export_encrypted AS BIT = 0,
	@file_encrypted AS Bit
	AS
	BEGIN

	DECLARE @repo_Id AS INT

		-- Update FTP Parameters	

		IF @export_mode = 1
			BEGIN

				UPDATE TREC_PARAMETROS
				SET par_valor = @export_format
				WHERE
				par_id = 35

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_path
				WHERE
				par_id = 41

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_protocol
				WHERE
				par_id = 42

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_sever
				WHERE
				par_id = 43

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_user
				WHERE
				par_id = 44

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_password
				WHERE
				par_id = 45

				UPDATE TREC_PARAMETROS
				SET par_valor = @ftp_port
				WHERE
				par_id = 46

				UPDATE TREC_PARAMETROS
				SET par_valor = @csv_log
				WHERE
				par_id = 50	

				UPDATE TREC_PARAMETROS
				SET par_valor = @export_mode
				WHERE
				par_id = 51

				UPDATE TREC_PARAMETROS
				SET par_valor = @delete_rec
				WHERE
				par_id = 57

				UPDATE TREC_PARAMETROS
				SET par_valor = @file_encrypted
				WHERE
				par_id = 61

				UPDATE TREC_PARAMETROS
				SET par_valor = @export_encrypted
				WHERE
				par_id = 62

				IF LEN( @time_export) > 0
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @time_export
						WHERE
						par_id = 33
					END
					
				IF @grabid_start <> -1
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @grabid_start
						WHERE
						par_id = 40
					
					END
			END
		ELSE
			BEGIN

				-- Update NetBios parameters
				declare @avrs_enviroment as int
				SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

				IF @avrs_enviroment = 2
					BEGIN

						UPDATE RIA_NETWORKCREDENTIALS
						SET
						[domain] = @net_sever,
						[user] = @net_user,
						[password] = @net_password
						WHERE
						id = @netcred_id

					END
				ELSE
					BEGIN

						UPDATE TREC_NETWORKCREDENTIALS
						SET
						[domain] = @net_sever,
						[user] = @net_user,
						[password] = @net_password
						WHERE
						id = @netcred_id

					END

				UPDATE TREC_PARAMETROS
				SET par_valor = @export_format
				WHERE
				par_id = 35
					
				UPDATE TREC_PARAMETROS
				SET par_valor = @net_path
				WHERE 
				par_id = 36
					
				IF LEN( @time_export) > 0
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @time_export
						WHERE
						par_id = 33
					END
					
				IF @grabid_start <> -1
					BEGIN
						UPDATE TREC_PARAMETROS
						SET par_valor = @grabid_start
						WHERE
						par_id = 40
					END

				UPDATE TREC_PARAMETROS
				SET par_valor = @csv_log
				WHERE
				par_id = 50

				UPDATE TREC_PARAMETROS
				SET par_valor = @export_mode
				WHERE
				par_id = 51

				UPDATE TREC_PARAMETROS
				SET par_valor = @delete_rec
				WHERE
				par_id = 57
				
				UPDATE TREC_PARAMETROS
				SET par_valor = @file_encrypted
				WHERE
				par_id = 61

				UPDATE TREC_PARAMETROS
				SET par_valor = @export_encrypted
				WHERE
				par_id = 62

			END
	END'
  	EXEC(@sql)


  	set @process = 'Alter PROCEDURE -- trsp_AdmRecSearchNodeWgCampACDCalif'		
	set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeWgCampACDCalif] 
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
			isnull(f.calif_id,0) as calif_id, isnull(g.Description,'''') as califDescription
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
			and g.Description <> ''''
			order by IDWG, tipo, idCampEsp, calif_id

		insert into #tempOutbound (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription)
			select a.Tipo, e.IDWG, e.WGName, a.idCampEsp, b.cam_descripcion as descripcion,
			isnull(d.frame,1) frame, isnull(f.calif_id,0) as calif_id, isnull(g.Description,'''') as califDescription
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
			and g.Description <> ''''
			order by IDWG, tipo, idCampEsp, calif_id

		---Seccion Inbound

		insert into #tempFinal (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
			select B.Tipo,B.IDWG,B.WGName,B.idCampEsp,B.descripcion,B.frame,B.calif_id,B.califDescription,C.califSub_id,isnull(C.califSubDesc,'''') as califSubDesc from #tempInbound B
			inner join cctiposubcalifrel as A on A.calif_id=B.calif_id
			inner join cctipocalifsub as C on C.califSub_id = A.califSub_id
			where  A.tipoSubRel=1
			and C.califSub_id=A.califSub_id	
			and C.califSubDesc <>''''


		insert  into #tempFinal (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
			select Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,'''','''' from #tempInbound where calif_id not in (select distinct (calif_id) from #tempFinal)

		---Seccion Outbound

		insert into #tempFinalOut (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
			select B.Tipo,B.IDWG,B.WGName,B.idCampEsp,B.descripcion,B.frame,B.calif_id,B.califDescription,C.califSub_id,isnull(C.califSubDesc,'''') as califSubDesc from #tempOutbound B
			inner join cctiposubcalifrel as A on A.calif_id=B.calif_id
			inner join cctipocalifsubout as C on C.califSub_id = A.califSub_id
			where  A.tipoSubRel=0
			and C.califSub_id=A.califSub_id
			and C.califSubDesc <>''''

		insert  into #tempFinalOut (Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,califSub_id,califSubDesc)
			select Tipo,IDWG,WGName,idCampEsp,descripcion,frame,calif_id,califDescription,'''','''' from #tempOutbound where calif_id not in (select distinct (calif_id) from #tempFinalOut)

		
		--Seleccion de Toda la Info
		select * from #tempFinal
		union select * from #tempFinalOut
		order by IDWG, tipo, idCampEsp, calif_id
		
		drop table #nodeWorkgroup
		drop table #tempInbound
		drop table #tempOutbound
		drop table #tempFinal
		drop table #tempFinalOut
		
	END'		
	EXEC(@sql)	

	set @process = 'Alter PROCEDURE -- trsp_GetRecordigsExportService'		
	set @sql='ALTER PROCEDURE [dbo].[trsp_GetRecordigsExportService]
				 @grabId AS INT,
				 @integrated AS INT
				 AS
				 BEGIN
					 DECLARE @SQL AS NVARCHAR(MAX)

					   IF @integrated = 1
					    BEGIN
						    SET @SQL = ''SELECT TOP 10000 * FROM(
						    SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local,t.finicio 
						    FROM RIA_GRABACIONCONSULTA t INNER JOIN TREC_REPOSITORIOS r ON
						    t.id_repositorio = r.id_repositorio 
						    UNION 
						    SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local ,t.finicio 
						    FROM RIA_GRABACION t INNER JOIN TREC_REPOSITORIOS r ON
						    t.id_repositorio = r.id_repositorio)x
						    WHERE x.grab_id >=''+ CONVERT(VARCHAR(10), @grabId) +''AND x.finicio < GETDATE()
						    ORDER BY x.grab_id''
				      	END
						ELSE IF @integrated = 0
						BEGIN

							SET @SQL = ''SELECT TOP 10000 * FROM(
							SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local,t.finicio 
							FROM TREC_GRABACIONCONSULTA t INNER JOIN TREC_REPOSITORIOS r ON
							t.id_repositorio = r.id_repositorio 
							UNION 
							SELECT t.grab_id,t.tipo_llamada,t.cal_id,r.id_repositorio,r.ruta_local ,t.finicio 
							FROM TREC_GRABACION t INNER JOIN TREC_REPOSITORIOS r ON
							t.id_repositorio = r.id_repositorio)x
							WHERE x.grab_id >=''+ CONVERT(VARCHAR(10), @grabId) +''AND x.finicio < GETDATE()
							ORDER BY x.grab_id''

						ED

						EXEC SP_EXECUTESQL @SQL

				END'		
	EXEC(@sql)
	
------------------ End Script @Sql ------------------

UPDATE trec_parametros SET par_valor = @version WHERE par_id = 30

COMMIT tran
END try

BEGIN catch	
	SELECT @errorGenerated = 'DB Script Version: ' + cast(@Version AS NVARCHAR) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)
	ROLLBACK tran
END catch
END

ELSE
 BEGIN
	SELECT 'Data base incorrect version ' + cast(@Version_Actual AS VARCHAR(5)) + ', please update to  ' + cast(@Version AS VARCHAR(5))
 END
SET nocount off
