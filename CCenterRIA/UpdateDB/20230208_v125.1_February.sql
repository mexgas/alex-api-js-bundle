/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.33

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 125 --**********actualizar a 123 sin fix
SET @versionfix = 1
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validación para cuando pasamos a una nueva versión LTS
IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN

	BEGIN TRY
		------------------------------------------------- BEGIN Marco Garcia K033000 Download Black List ----------------------------------------------------------------------
		SET @process = 'K033001-Descargar LN add column calKey to cclistanegra table'
		set @sql = 'IF not exists (SELECT * FROM sys.columns WHERE name = N''calKey'' AND Object_ID = Object_ID(N''cclistanegra''))
			BEGIN
				ALTER TABLE cclistanegra ADD calKey VARCHAR(40) NULL
			END'
		EXEC(@sql)

		SET @process = 'K033001-Descargar LN delete procedure ccsp_InsertDNCList'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_InsertDNCList'')
			BEGIN
				DROP PROCEDURE ccsp_InsertDNCList
			END'
		EXEC(@sql)

		SET @process = 'K033001-Descargar LN create procedure ccsp_InsertDNCList'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_InsertDNCList]
		@telephone as varchar(30),
		@ln_id as integer,
		@hashCalKey bigint=NULL,
		@calKey VARCHAR(40) = NULL
		WITH RECOMPILE
		AS

		declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)

		insert into cclistanegra(telefono,idtipolista,HashKey, calKey) values(@telephone, @ln_id,@hashCalKey, @calKey)

		CREATE TABLE [dbo].[#mycamps] (
		  [campsid] [int] NULL
		  )

		CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

		insert #mycamps
		select cam_id from Camplistanegra where idtipolista = @ln_id

		CREATE TABLE [dbo].[#myprincipaltemp](
		  [callout_id] [int] NULL, 
		  [cam_id] [smallint] NULL ,
		  [tipomov] [int] NULL,
		  [idtipolista] [int] NULL,
		  [cal_telefono] [varchar] (15) NULL ,
		  [cal_telefono2] [varchar] (15) NULL ,
		  [cal_telefono3] [varchar] (15) NULL ,
		  [cal_telefono4] [varchar] (15) NULL ,
		  [cal_telefono5] [varchar] (15) NULL
		  )

		CREATE CLUSTERED INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltemp]([callout_id]) 
		CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltemp]([cal_telefono]) 
		CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltemp]([cal_telefono2]) 
		CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltemp]([cal_telefono3]) 
		CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltemp]([cal_telefono4]) 
		CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltemp]([cal_telefono5]) 

		CREATE TABLE [dbo].[#mytemp](
		  [callout_id] [int] NULL, 
		  [telefono] [varchar] (15) NULL ,
		  [cam_id] [smallint] NULL ,
		  [tipomov] [int] NULL,
		  [idtipolista] [int] NULL
		  )

		CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) 

		select @pais = valor from ccSettings with(nolock) where setting_id = 104
		select @ld = valor from ccSettings with(nolock) where setting_id = 17
		select @tel = dbo.completa(@telephone, @pais, @ld)

		--declare @Sql nvarchar(max)
		--declare @fecha datetime = dateadd(dd,-30,getdate())
		declare @fech datetime = getdate()-30
		if @hashCalKey is not null or @hashCalKey > 0
		begin

		  insert into [#myprincipaltemp] 
		  SELECT a.callout_id as callout_id, a.cam_id,''3'',cast(@ln_id as nvarchar) as idtipolista , a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
		  FROM [ccoCallsOutSource] as a, #mycamps as b with(nolock) WHERE a.cam_id = b.campsid 
		  AND dbo.hashList(cal_Key) = @hashCalKey and  cal_fechadial > @fech
  
		end
		else begin
		  insert into [#myprincipaltemp]
		  SELECT a.callout_id as callout_id, a.cam_id,''3'',cast(@ln_id as nvarchar) as idtipolista , a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
		  FROM [ccoCallsOutSource] as a, #mycamps as b with(nolock) WHERE a.cam_id = b.campsid
		  and (@tel  IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) 
		  or right(@tel,10) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) 
		  or right(@tel,11) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5])) 
		  and  cal_fechadial > @fech
  
		end

		--EXEC(@Sql)

		if EXISTS (select * from #myprincipaltemp)
		  begin
			/******************/
			/*** Telefono 1 ***/
			/******************/
			insert #mytemp
			select callout_id,cal_telefono,cam_id,tipomov,idtipolista
			from [#myprincipaltemp] with(nolock)
			where (cal_telefono = @tel or cal_telefono = right(@tel, 10) or cal_telefono = right(@tel, 11))

			if EXISTS (select * from #mytemp)
			begin
			  -- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
			  delete ccoWOrkingTable with(rowlock)
			  from ccoWOrkingTable wt 
			  inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			  inner join #mytemp t on wt.callout_id = t.callout_id
			  where cs.cal_fechadial > @fech and
			  cs.cal_telefono = wt.cal_telefono
			  and rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
						 + cs.cal_telefono3 + ''         ''
						 + cs.cal_telefono4 + ''         ''
						 + cs.cal_telefono5 + ''         ''),13)) = ''''

			  -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			  update ccoWOrkingTable 
			  set cal_telefono = rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
								+ cs.cal_telefono3 + ''         ''
								+ cs.cal_telefono4 + ''         ''
								+ cs.cal_telefono5 + ''         ''),13))
			  from ccoCallsOutSource cs 
			  inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			  inner join #mytemp t on cs.callout_id = t.callout_id
			  where cs.cal_fechadial > @fech and cs.cal_telefono= wt.cal_telefono

			  ---insertar el historial
			  insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			  select * from #mytemp

			  -- Eliminamos el telefono1 de CS
			  update ccoCallsOutSource 
			  set cal_telefono = ''''
			  from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			  where cs.cal_fechadial > @fech

			  truncate table #mytemp
			end

			/******************/
			/*** Telefono 2 ***/
			/******************/
			insert #mytemp
			select callout_id,cal_telefono2,cam_id,tipomov,idtipolista
			from [#myprincipaltemp] with(nolock)
			where (cal_telefono2 = @tel or cal_telefono2 = right(@tel, 10) or cal_telefono2 = right(@tel, 11))

			if EXISTS (select * from #mytemp)
			begin
			  -- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
			  delete ccoWOrkingTable 
			  from ccoWOrkingTable wt 
			  inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			  inner join #mytemp t on wt.callout_id = t.callout_id
			  where cs.cal_fechadial > @fech and cs.cal_telefono2= wt.cal_telefono 
			  and rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
						 + cs.cal_telefono4 + ''         ''
						 + cs.cal_telefono5 + ''         ''),13)) = ''''

			  -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			  update ccoWOrkingTable 
			  set cal_telefono = rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
								+ cs.cal_telefono4 + ''         ''
								+ cs.cal_telefono5 + ''         ''),13))
			  from ccoCallsOutSource cs 
			  inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			  inner join #mytemp t on cs.callout_id = t.callout_id
			  where cs.cal_fechadial > @fech and cs.cal_telefono2= wt.cal_telefono

			  ---insertar el historial
			  insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			  select * from #mytemp

			  -- Eliminamos el telefono2 de CS
			  update ccoCallsOutSource 
			  set cal_telefono2 = ''''
			  from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			  where cs.cal_fechadial > @fech

			  truncate table #mytemp
			end

			/******************/
			/*** Telefono 3 ***/
			/******************/
			insert #mytemp
			select callout_id,cal_telefono3,cam_id,tipomov,idtipolista
			from [#myprincipaltemp] with(nolock)
			where (cal_telefono3 = @tel or cal_telefono3 = right(@tel, 10) or cal_telefono3 = right(@tel, 11))

			if EXISTS (select * from #mytemp)
			begin
			  -- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			  delete ccoWOrkingTable 
			  from ccoWOrkingTable wt 
			  inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			  inner join #mytemp t on wt.callout_id = t.callout_id
			  where cs.cal_fechadial > @fech and cs.cal_telefono3= wt.cal_telefono  
			  and  rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
						  + cs.cal_telefono5 + ''         ''),13)) = ''''

			  -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			  update ccoWOrkingTable 
			  set cal_telefono = rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
								+ cs.cal_telefono5 + ''         ''),13))
			  from ccoCallsOutSource cs 
			  inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			  inner join #mytemp t on cs.callout_id = t.callout_id
			  where cs.cal_fechadial > @fech and cs.cal_telefono3= wt.cal_telefono

			  ---insertar el historial
			  insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			  select * from #mytemp

			  -- Eliminamos el telefono3 de CS
			  update ccoCallsOutSource 
			  set cal_telefono3 = ''''
			  from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			  where cs.cal_fechadial > @fech

			  truncate table #mytemp
			end

			/******************/
			/*** Telefono 4 ***/
			/******************/
			insert #mytemp
			select callout_id,cal_telefono4,cam_id,tipomov,idtipolista
			from [#myprincipaltemp] with(nolock)
			where (cal_telefono4 = @tel or cal_telefono4 = right(@tel, 10) or cal_telefono4 = right(@tel, 11))

			if EXISTS (select * from #mytemp)
			begin
			  -- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			  delete ccoWOrkingTable 
			  from ccoWOrkingTable wt 
			  inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			  inner join #mytemp t on wt.callout_id = t.callout_id
			  where cs.cal_fechadial > @fech and cs.cal_telefono4= wt.cal_telefono 
			  and rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13)) = ''''

			  -- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			  update ccoWOrkingTable 
			  set cal_telefono = rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13))
			  from ccoCallsOutSource cs 
			  inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			  inner join #mytemp t on cs.callout_id = t.callout_id
			  where cs.cal_fechadial > @fech and cs.cal_telefono4= wt.cal_telefono

			  ---insertar el historial
			  insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			  select * from #mytemp

			  -- Eliminamos el telefono4 de CS
			  update ccoCallsOutSource 
			  set cal_telefono4 = ''''
			  from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			  where cs.cal_fechadial > @fech

			  truncate table #mytemp
			end

			/******************/
			/*** Telefono 5 ***/
			/******************/
			insert #mytemp
			select callout_id,cal_telefono5,cam_id,tipomov,idtipolista
			from [#myprincipaltemp] with(nolock)
			where (cal_telefono5 = @tel or cal_telefono5 = right(@tel, 10) or cal_telefono5 = right(@tel, 11))

			if EXISTS (select * from #mytemp)
			begin
			  -- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			  delete ccoWOrkingTable 
			  from ccoWOrkingTable wt 
			  inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			  inner join #mytemp t on wt.callout_id = t.callout_id
			  where cs.cal_fechadial > @fech and cs.cal_telefono5= wt.cal_telefono

			  ---insertar el historial
			  insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			  select * from #mytemp

			  -- Eliminamos el telefono5 de CS
			  update ccoCallsOutSource 
			  set cal_telefono5 = ''''
			  from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			  where cs.cal_fechadial > @fech
			end
		  end

		drop table [#myprincipaltemp]
		drop table [#mytemp]
		drop table [#mycamps]   '

		EXEC(@sql);

		SET @process = 'K033001-Descargar LN delete procedure ccsp_AgentUpdateCallCALIF'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_AgentUpdateCallCALIF'')
			BEGIN
				DROP PROCEDURE ccsp_AgentUpdateCallCALIF
			END'
		EXEC(@sql);

		SET @process = 'K033001-Descargar LN create procedure ccsp_AgentUpdateCallCALIF'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_AgentUpdateCallCALIF] @IDCall INT, @calif_id SMALLINT, @TipoCall SMALLINT, @Origin INT = 0, @cal_key VARCHAR(40) = NULL, @callOutId INT = 0, @subId SMALLINT = 0
				AS
				SET NOCOUNT ON

				DECLARE @RecicleSIC TINYINT, @Reprogram TINYINT, @DateNewDial SMALLDATETIME, @idTipoLista INT, @autoCB TINYINT, @tel VARCHAR(30), @camp INT, @iddncList AS INT
				DECLARE @userid INT

				SELECT @RecicleSIC = valor
				FROM ccSettings
				WHERE setting_id = 60

				SELECT @RecicleSIC = IsNull(@RecicleSIC, 0)

				DECLARE @hashTel INT
				DECLARE @killListID INT = (
						SELECT idtipolista
						FROM ccTiposListaNegra
						WHERE Tipolista = ''default/KillList''
						)
				DECLARE @killListSetting INT = (
						SELECT STATUS
						FROM ccSettings
						WHERE setting_id = 215
						)

				IF @TipoCall = 1
				BEGIN
					UPDATE ccCallsIN
					SET calif_id = @calif_id, cal_origin_id = @Origin, cal_key = isnull(@cal_key, cal_key), califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
					WHERE cal_id = @IDCall

					IF EXISTS (
							SELECT idTipoLista
							FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
							WHERE tipo = 0 AND calif_id = @calif_id
							)
					BEGIN
						SELECT @tel = dbo.Completa_ListaNegra(ci.cal_ANI), @iddncList = cbl.idTipoLista
						FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
						JOIN cccalifblacklist AS cbl ON ci.calif_id = cbl.calif_id
						WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0

						IF @tel IS NOT NULL AND @iddncList IS NOT NULL
						BEGIN
							--insert ccListaNegra
							INSERT INTO cclistanegra (telefono, idtipolista, calKey)
							VALUES (@tel, @iddncList, @cal_key)

							--insert cc_killlist
							IF (@killListSetting = 1 AND @iddncList = @killListID) -- verifies if kill list setting is active and if the list_id matches killList id
							BEGIN
								select @hashTel = dbo.hashPhone(@tel)

								IF NOT EXISTS (
										SELECT hashtel
										FROM cc_KillList
										WHERE hashTel = @hashTel
										)
								BEGIN
									INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
									VALUES (@hashTel, @iddncList, GETDATE())
								END
							END

							INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
							SELECT dbo.Completa_ListaNegra(ci.cal_ANI), cbl.idTipoLista, ci.Inbound_id, getdate(), ci.dni_id, 6
							FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
							JOIN cccalifblacklist cbl ON ci.calif_id = cbl.calif_id
							WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0
						END
					END

					RETURN (0)
				END

				IF @TipoCall = 2
				BEGIN
					-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
					SELECT @autoCB = autocallback
					FROM ccTipoCalifSubout
					WHERE califSub_Id = @subId

					-- Si no tiene subcalificacion toma la de la calificacion
					IF @autoCB IS NULL
					BEGIN
						SELECT @autoCB = autocallback
						FROM cctipocalifout
						WHERE calif_id = @calif_id
					END

					IF @autoCB = 1
					BEGIN
						SELECT @callOutId = callout_id, @camp = cam_id, @userid = user_id
						FROM ccocallsout
						WHERE Cal_id = @IDCall

						SELECT @DateNewDial = dateadd(mi, t_autoCB, getdate())
						FROM cccamps cam
						WHERE cam.cam_id = @camp

						EXEC ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
					END

					UPDATE ccoCallsOUT
					SET calif_id = @calif_id, califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
					WHERE cal_id = @IDCall

					IF EXISTS (
							SELECT idTipoLista
							FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
							WHERE tipo = 1 AND calif_id = @calif_id
							) AND NOT EXISTS (
							SELECT co.cal_telefono
							FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
							JOIN ccListaNegra bl ON dbo.Completa_ListaNegra(co.cal_telefono) = bl.telefono OR co.cal_telefono = bl.telefono
							WHERE co.cal_id = @idCall AND bl.idtipolista IN (
									SELECT idTipoLista
									FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
									WHERE tipo = 1 AND calif_id = @calif_id
									)
							)
					BEGIN --IF

						CREATE TABLE #NUMANDBL (id int identity,  iddncList int)
						CREATE TABLE #NUMBERS (id int identity, number varchar(30))
						DECLARE @allnumbersToBl BIT
						DECLARE @number varchar(30)

						SELECT @allnumbersToBl = allNumbersToBlacklist FROM ccTipoCalifOUT WHERE calif_id = @calif_id

						IF(@allnumbersToBl = 1)
						BEGIN
							DECLARE @camid SMALLINT
							SELECT @camid = cam_id FROM ccoCallsOut WITH (INDEX (PK_ccoCallsOut)) WHERE cal_id = @IDCall
							DECLARE @i SMALLINT = 0
							WHILE (@i < 5 )
							BEGIN
								SELECT @number = CASE @i 
													WHEN 0 THEN cal_telefono 
													WHEN 1 THEN cal_telefono2
													WHEN 2 THEN cal_telefono3
													WHEN 3 THEN cal_telefono4
													WHEN 4 THEN cal_telefono5
													END FROM ccoCallsOutSource WHERE callout_id = @callOutId AND cam_id = @camid
								SET @number = dbo.Completa_ListaNegra(@number)
								IF(LEFT(@number, 1) <> ''E'') 
								BEGIN
									INSERT INTO #NUMBERS (number) VALUES (@number)
								END
								SET @i = @i + 1
							END
						END
						ELSE
						BEGIN
							SELECT @number = co.cal_telefono
							FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
							WHERE co.cal_id = @idCall 
							SET @number = dbo.Completa_ListaNegra(@number)
							IF(LEFT(@number, 1) <> ''E'') 
							BEGIN
								INSERT INTO #NUMBERS (number) VALUES (@number)
							END
						END

						IF((SELECT COUNT(*) FROM #NUMBERS) > 0) begin
							INSERT INTO #NUMANDBL (iddncList) 
							select cbl.idTipoLista from cccalifblacklist cbl  where cbl.calif_id=@calif_id and cbl.tipo = 1
						END

						DECLARE @Count int		
						WHILE (SELECT count(id) from #NUMANDBL) > 0
						BEGIN  --WHILE
							select @Count = count(id) from #NUMANDBL
							SELECT @iddncList = iddncList from #NUMANDBL where id = @Count
							DECLARE @countNumbers INT, @indexNumbers INT = 1
							SELECT @countNumbers = COUNT(*) FROM #NUMBERS
							WHILE( @indexNumbers <= @countNumbers) --WHILE NUMBERS
							BEGIN 
								SELECT @tel = number FROM #NUMBERS WHERE id = @indexNumbers
								IF @tel IS NOT NULL AND @iddncList IS NOT NULL
								BEGIN--Tel adn iddnclist
									EXEC ccsp_InsertDNCList @telephone = @tel, @ln_id = @iddncList, @calKey= @cal_key;

									IF (@killListSetting = 1 AND @iddncList = @killListID)
									BEGIN
										select @hashTel = dbo.hashPhone(@tel)

										IF NOT EXISTS (SELECT hashtel FROM cc_KillList WHERE hashTel = @hashTel)
										BEGIN
											INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
											VALUES (@hashTel, @iddncList, GETDATE())
										END
									END

									INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
									SELECT @tel, @iddncList, co.cam_id, getdate(), co.callout_id, 6
									FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
									--JOIN cccalifblacklist cbl ON co.calif_id = cbl.calif_id
									WHERE co.cal_id = @idCall 
								END --Tel adn iddnclist
								SET @indexNumbers = @indexNumbers + 1
							END --WHILE NUMBERS
							delete from #NUMANDBL where id = @Count
						END --WHILE
						DROP TABLE #NUMANDBL
						DROP TABLE #NUMBERS
					END --IF
					IF @RecicleSIC = 1
					BEGIN
						-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
						SELECT @Reprogram = CanReprogram
						FROM ccTipoCalifSubout
						WHERE califSub_Id = @subId

						-- Si no tiene subcalificacion toma la de la calificacion
						IF @Reprogram IS NULL
						BEGIN
							SELECT @Reprogram = CanReprogram
							FROM ccTipoCalifOUT
							WHERE calif_id = @calif_id
						END

						IF @callOutId = 0
							SELECT @callOutId = callout_id
							FROM ccocallsout
							WHERE Cal_id = @IDCall

						UPDATE ccoWorkingTable
						SET calif_id = @calif_id, cal_status = CASE @Reprogram WHEN 0 THEN 3 ELSE cal_status END
						WHERE callout_id = @callOutId
					END

					DECLARE @keepDial BIT
					DECLARE @finishPreview SMALLINT

					-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
					SELECT @keepDial = keepDial
					FROM ccTipoCalifSubout
					WHERE califSub_Id = @subId

					-- Si no tiene subcalificacion toma la de la calificacion
					IF @keepDial IS NULL
					BEGIN
						SELECT @keepDial = keepDial
						FROM ccTipoCalifout
						WHERE calif_id = @calif_id
					END

					SELECT @finishPreview = isnull(finishPreview, 0)
					FROM ccTipoCalifout
					WHERE calif_id = @calif_id

					IF @keepDial = 1
					BEGIN
						UPDATE ccologdials
						SET TipoDialingMode = dbo.fn_getDialingMode(@IDCall, 3, 0, @camp)
						WHERE logDial_id IN (
								SELECT TOP 1 L.logDial_id
								FROM ccoLogDials L WITH (INDEX (IX_ccoLogDials_2), NOLOCK)
								JOIN ccoCallsOut O WITH (INDEX (PK_ccoCallsOut), NOLOCK) ON L.callout_id = O.callout_id
								WHERE O.cal_id = @IDCall
								ORDER BY L.logDial_id DESC
								)
					END

					SELECT @keepDial, @finishPreview

					RETURN (0)
				END

				SET NOCOUNT OFF'
		EXEC(@sql)
			
		SET @process = 'K033001-Descargar LN delete procedure ccsp_RIADNCList'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIADNCList'')
			BEGIN
				DROP PROCEDURE ccsp_RIADNCList
			END'
		EXEC(@sql)

		SET @process = 'K033001-Descargar LN create procedure ccsp_RIADNCList'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_RIADNCList] @phoneNumber AS VARCHAR(30), @idDNCList AS INTEGER, @tipoMov AS TINYINT, @calKey AS VARCHAR(40) = NULL
		AS
		DECLARE @hashCalKey bigint, @hashPhone BIGINT

		IF @calKey IS NOT NULL
		BEGIN
			SELECT @hashCalKey = dbo.hashList(@calKey)
		END

		IF @tipoMov = 1
		BEGIN -- Inserta Lista Negra	
			EXEC ccsp_InsertDNCList @telephone = @phoneNumber, @ln_id = @idDNCList, @hashCalKey = @hashCalKey, @calKey = @calKey

			INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
			VALUES (@phoneNumber, 7, @idDNCList)
		END

		IF @tipoMov = 2
		BEGIN -- Borra Lista Negra	
			SELECT @hashPhone = dbo.hashPhone(@phoneNumber)

			IF @hashCalKey IS NULL
			BEGIN
				DELETE
				FROM cclistanegra
				WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idDNCList
			END
			ELSE
			BEGIN
				DELETE
				FROM cclistanegra
				WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idDNCList
			END

			INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
			VALUES (@phoneNumber, 5, @idDNCList)
		END

		IF @tipoMov = 3
		BEGIN -- Reemplaza Lista Negra
			INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
			SELECT telefono, ''4'', @idDNCList
			FROM cclistanegra
			WHERE idtipolista = @idDNCList

			DELETE
			FROM cclistanegra
			WHERE idtipolista = @idDNCList
		END '
		EXEC(@sql);



		SET @process = 'K033001-Descargar LN delete procedure ccsp_GalateaAdminUploadBLst'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaAdminUploadBLst'')
			BEGIN
				DROP PROCEDURE ccsp_GalateaAdminUploadBLst
			END'
		EXEC(@sql)

		SET @process = 'K033001-Descargar LN create procedure ccsp_GalateaAdminUploadBLst'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaAdminUploadBLst]  @command TINYINT, @telephone VARCHAR(20) = 0, @idtipolista INT, @calKey AS VARCHAR(40) = NULL, @isKolob bit=0
		AS
		DECLARE @hashCalKey BIGINT, @hashPhone BIGINT

		SELECT @hashPhone = dbo.hashPhone(@telephone)

		IF @calKey IS NOT NULL
		BEGIN
		  SELECT @hashCalKey = dbo.hashList(@calKey)
		END

		IF @hashCalKey IS NULL
		BEGIN
		  IF @command IN (1, 4) --LookForNumber 
			AND EXISTS (
			  SELECT idtipolista
			  FROM cclistanegra
			  WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idtipolista
			  )
		  BEGIN
			SELECT 1

			RETURN (0)
		  END
		END
		ELSE
		BEGIN
		  IF @command IN (1, 4) --LookForNumber 
			AND EXISTS (
			  SELECT idtipolista
			  FROM cclistanegra
			  WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
			  )
		  BEGIN
			SELECT 1

			RETURN (0)
		  END
		END

		IF @command = 1 --Insert Number
		BEGIN
		  EXEC ccsp_InsertDNCList @telephone, @idtipolista, @hashCalKey, @calKey

		  INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
		  VALUES (@telephone, 1, @idtipolista)

		  SELECT 200
		END

		IF @command = 2 --Delete Number
		BEGIN
		  --Check if phone number exists
					IF EXISTS(SELECT cln.Hashtel FROM dbo.ccListaNegra AS cln WHERE cln.Hashtel = @hashPhone AND cln.idtipolista = @idtipolista)
					BEGIN
						  IF @hashCalKey IS NULL
						  BEGIN
							--Check if request is from kolob or xion
							IF(@isKolob = 1)
							BEGIN
								--Check if phone number has calKey assigned
								SELECT @hashCalKey = cln.HashKey FROM dbo.ccListaNegra AS cln WHERE cln.Hashtel = @hashPhone AND cln.idtipolista = @idtipolista
								IF (@hashCalKey IS NOT NULL)
								BEGIN
									SELECT CAST(-1 AS INT) --Phone number need a calkey to delete it
								END
								ELSE
								BEGIN
									INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
									VALUES (@telephone, 5, @idtipolista)

									DELETE
									FROM cclistanegra
									WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idtipolista;
									SELECT CAST(1 AS INT)
								END
							END
							ELSE
							BEGIN
								INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
								VALUES (@telephone, 5, @idtipolista)

								DELETE
								FROM cclistanegra
								WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idtipolista
							END
						  END
						  ELSE
						  BEGIN
							--Check if phone with calKey exist
							IF NOT EXISTS (SELECT cln.HashKey FROM dbo.ccListaNegra AS cln WHERE cln.HashKey = @hashCalKey AND cln.idtipolista = @idtipolista)
							BEGIN
								SELECT CAST(-4 AS INT) --Phone Number with calKey not exist
							END
							ELSE
							BEGIN
								INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
								VALUES (@telephone, 5, @idtipolista)

								DELETE
								FROM cclistanegra
								WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
								IF(@isKolob = 1)
								BEGIN
									SELECT CAST(1 AS INT)
								END
							END
						  END
					END
					ELSE
					BEGIN
						SELECT CAST(-3 AS INT) --Phone Number not exist
					END
				  RETURN (0)
		END

		IF @command = 3 --Reemplaza
		BEGIN
		  INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
		  SELECT telefono, 4, @idtipolista
		  FROM cclistanegra
		  WHERE idtipolista = @idtipolista

		  DELETE
		  FROM cclistanegra
		  WHERE idtipolista = @idtipolista

		  RETURN (0)
		END

		IF @command = 5 --Delete by idtipolista
		BEGIN
		  UPDATE ccTiposListaNegra
		  SET STATUS = 0
		  WHERE idtipolista = @idtipolista

		  DELETE ccAgendaListaNegra
		  WHERE idagenda IN (
			  SELECT idagenda
			  FROM ccAgenda_TipolistaNegra
			  WHERE idtipolista = @idtipolista
			  )

		  DELETE ccAgenda_TipolistaNegra
		  WHERE idtipolista = @idtipolista

		  DELETE cccalifblacklist
		  WHERE idtipolista = @idtipolista

		  DELETE Camplistanegra
		  WHERE idtipolista = @idtipolista

		  DECLARE @telefono VARCHAR(10)

		  WHILE EXISTS (
			  SELECT telefono
			  FROM ccListaNegra
			  WHERE idtipolista = @idtipolista
			  )
		  BEGIN
			SELECT TOP 1 @hashPhone = Hashtel, @telefono = telefono
			FROM ccListaNegra
			WHERE idtipolista = @idtipolista

			INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
			VALUES (@telefono, 5, @idtipolista)

			DELETE
			FROM cclistanegra
			WHERE Hashtel = @hashPhone AND idtipolista = @idtipolista
		  END

		  RETURN (0)
		END

		SET NOCOUNT OFF'
		EXEC(@sql);


		SET @process = 'K033001-Descargar LN delete procedure ccsp_GalateaAdminBlackListPhones'
		SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaAdminBlackListPhones'')
			BEGIN
				DROP PROCEDURE ccsp_GalateaAdminBlackListPhones
			END'
		EXEC(@sql)

		SET @process = 'K033001-Descargar LN create procedure ccsp_GalateaAdminBlackListPhones'
		SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminBlackListPhones]
			@type TINYINT,
			@idBlackList INT
			AS
			BEGIN
				SET NOCOUNT ON;

				/*Variables Tables*/
				DECLARE @repeatedPhoneNumbers TABLE (telefono VARCHAR(19))
				DECLARE @numbersWithoutrepeatedNumbers TABLE (telefono VARCHAR(19), calKey VARCHAR(40), fecha DATETIME)
				DECLARE @repeatedNumberPhonesAllColumns TABLE (telefono VARCHAR(19), calKey VARCHAR(40), fecha DATETIME)

				IF(@type = 1) -- GET BLACK LIST PHONES BY ID
				BEGIN

					/*Save phone numbers repeated in ccListanegra table*/
					INSERT INTO @repeatedPhoneNumbers
					(
						telefono
					)
					SELECT telefono FROM ccListaNegra 
					WHERE idtipolista = @idBlackList
					GROUP BY telefono
					HAVING COUNT(*)>1;

					/*Save phone numbers that are not repeated*/
					INSERT INTO @numbersWithoutrepeatedNumbers
					(
						telefono,
						calKey,
						fecha
					)
					 SELECT cln.telefono, cln.calKey, MAX(chln.fecha) AS fecha FROM dbo.ccListaNegra AS cln 
					 INNER JOIN dbo.ccHistorialListaNegra AS chln ON chln.telefono = cln.telefono
					 AND chln.idtipolista = cln.idtipolista
					 WHERE cln.telefono NOT IN (SELECT rpn.telefono FROM @repeatedPhoneNumbers AS rpn) AND chln.idtipolista = @idBlackList  AND chln.idtipomov IN (1,7)
					 GROUP BY cln.telefono, cln.calKey

					 /*Save phone numbers repeated with all the columns we need */
					 INSERT INTO @repeatedNumberPhonesAllColumns
					 (
						 telefono,
						 calKey,
						 fecha
					 )
					SELECT t.telefono,
						   t.calKey,
						   MIN(t.fecha) AS fecha FROM  ( SELECT cln.telefono, cln.calKey, MAX(chln.fecha) AS fecha FROM dbo.ccListaNegra AS cln 
					 INNER JOIN dbo.ccHistorialListaNegra AS chln ON chln.telefono = cln.telefono
					 AND chln.idtipolista = cln.idtipolista
					 WHERE cln.telefono IN (SELECT rpn.telefono FROM @repeatedPhoneNumbers AS rpn) AND chln.idtipolista = @idBlackList  AND chln.idtipomov IN (1,7)
					 GROUP BY cln.telefono, cln.calKey) t
					 GROUP BY t.telefono,
							  t.calKey



					/*Get all phone numbers with necesary columns without phone numbers repeated*/
					SELECT telefono,
						   ISNULL(calKey, '''') AS calKey,
						   fecha FROM @numbersWithoutrepeatedNumbers
					UNION 
					 SELECT 
						rnpac2.telefono,MIN(rnpac2.calKey) AS calKey, rnpac2.fecha
					 FROM (
							SELECT rnpac.telefono,
								   MIN(rnpac.fecha) AS fecha FROM @repeatedNumberPhonesAllColumns AS rnpac
								   GROUP BY rnpac.telefono
							) foo 
							JOIN @repeatedNumberPhonesAllColumns AS rnpac2 ON foo.telefono = rnpac2.telefono AND foo.fecha = rnpac2.fecha
							GROUP BY rnpac2.telefono, rnpac2.fecha
							ORDER BY fecha DESC
				END
			END'
			EXEC(@sql);

			------------------------------------------------- END Marco Garcia K033000 Download Black List ----------------------------------------------------------------------

			SET @process = '#777 ALTER PROCEDURE [dbo].[ccsp_UpdateCallsOutFromTempAction] se modifica @action=6 para evitar bloqueos'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_UpdateCallsOutFromTempAction]
@action INT,
@tableName NVARCHAR(255),
@cal_status int = 0,
@idLoad int=0,
@motivo varchar(50)=null,
@cam_id int=null,
@isIAQuantumCamp bit =0,
@internationalRecords int=0

AS
BEGIN
SET NOCOUNT ON;

DECLARE @sql NVARCHAR(MAX);
DECLARE @paramDef NVARCHAR(300);
DECLARE @count INT;
declare @emtpy varchar(1)='''',@zipCodeSchedule bit
declare @columnsIAQuntum varchar(max)=''''

IF @action = 1
BEGIN
	SET @sql = ''
	UPDATE '' + QUOTENAME(@tableName) + ''
	SET international = 1'';

	EXEC sp_executesql @sql;
END
ELSE IF @action = 2
BEGIN

	if @isIAQuantumCamp =1 begin
		set @columnsIAQuntum='', data_api_quantum, data_overflow_variables_quantum''
	end

	SET @sql = ''
	INSERT INTO dbo.ccoCallsOutSource (
		cal_Key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
		Dato1, Dato2, Dato3, Dato4, Dato5,
		dialPrefix, list_id, cam_id, Region, Localidad, cal_status, cal_fechaDial
		,iZonaHoraria,iZonaHoraria_verano
		,iZonaHoraria2,iZonaHoraria_verano2
		,iZonaHoraria3,iZonaHoraria_verano3
		,iZonaHoraria4,iZonaHoraria_verano4
		,iZonaHoraria5,iZonaHoraria_verano5
		'' + @columnsIAQuntum + ''
	)
	SELECT
		cal_Key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5,
		Dato1, Dato2, Dato3, Dato4, Dato5,
		dialPrefix, list_id, cam_id, Region, Localidad, cal_status, cal_fechaDial
		,iZonaHoraria,iZonaHoraria_verano
		,iZonaHoraria2,iZonaHoraria_verano2
		,iZonaHoraria3,iZonaHoraria_verano3
		,iZonaHoraria4,iZonaHoraria_verano4
		,iZonaHoraria5,iZonaHoraria_verano5
		'' + @columnsIAQuntum + ''
	FROM '' + QUOTENAME(@tableName) + ''
	WHERE callout_id = 0'';

	EXEC sp_executesql @sql;
END

ELSE IF @action = 3
BEGIN
	SET @sql = ''
	INSERT INTO dbo.ccoCallsPreviewData (
		cal_Key, cam_id, TotalData, Headers,
		Dato6, Dato7, Dato8, Dato9, Dato10,
		Dato11, Dato12, Dato13, Dato14, Dato15
	)
	SELECT
		A.cal_Key, A.cam_id, A.TotalData, A.Headers,
		A.Dato6, A.Dato7, A.Dato8, A.Dato9, A.Dato10,
		A.Dato11, A.Dato12, A.Dato13, A.Dato14, A.Dato15
	FROM '' + QUOTENAME(@tableName) + '' A
	left join ccoCallsPreviewData B on A.cal_Key=B.cal_Key and A.cam_id=B.cam_id
	WHERE B.cam_id is null;
	'';

	EXEC sp_executesql @sql;
END
ELSE IF @action = 4
BEGIN
	SET @sql = ''
	UPDATE C SET
		C.Headers = A.Headers,
		C.TotalData = A.TotalData,
		C.Dato6 = A.Dato6, C.Dato7 = A.Dato7, C.Dato8 = A.Dato8, C.Dato9 = A.Dato9, C.Dato10 = A.Dato10,
		C.Dato11 = A.Dato11, C.Dato12 = A.Dato12, C.Dato13 = A.Dato13, C.Dato14 = A.Dato14, C.Dato15 = A.Dato15
	FROM '' + QUOTENAME(@tableName) + '' A
	INNER JOIN dbo.ccoCallsPreviewData C WITH (ROWLOCK, UPDLOCK)
		ON A.cal_Key = C.cal_Key AND A.cam_id = C.cam_id;
	'';

	EXEC sp_executesql @sql;
END
ELSE IF @action =5
BEGIN
	if @isIAQuantumCamp =1 begin
		set @columnsIAQuntum='', C.data_api_quantum = A.data_api_quantum, C.data_overflow_variables_quantum = A.data_overflow_variables_quantum''
	end

	SET @sql = ''
	UPDATE C SET
		C.cal_status = CASE WHEN B.callout_id IS NULL THEN @cal_status_param ELSE C.cal_status END,
		C.cal_telefono = A.cal_telefono,
		C.cal_telefono2 = A.cal_telefono2,
		C.cal_telefono3 = A.cal_telefono3,
		C.cal_telefono4 = A.cal_telefono4,
		C.cal_telefono5 = A.cal_telefono5,
		C.Dato1 = A.Dato1,
		C.Dato2 = A.Dato2,
		C.Dato3 = A.Dato3,
		C.Dato4 = A.Dato4,
		C.Dato5 = A.Dato5,
		C.dialPrefix = A.dialPrefix,
		C.list_id = A.list_id,
		C.cal_fechaDial = case when ISNULL(B.cal_status, 0) = 1 then C.cal_fechaDial else A.cal_fechaDial end,
		C.Region = A.Region,
		C.Localidad = A.Localidad,
		C.international = A.international,
		C.recycledByResult = @emtpy,
		C.recycledByDisposition = 0,
		C.recyclePhone = 0,
		C.recycleType = 1
		,C.iZonaHoraria=A.iZonaHoraria,C.iZonaHoraria_verano=A.iZonaHoraria_verano
		,C.iZonaHoraria2=A.iZonaHoraria2,C.iZonaHoraria_verano2=A.iZonaHoraria_verano2
		,C.iZonaHoraria3=A.iZonaHoraria3,C.iZonaHoraria_verano3=A.iZonaHoraria_verano3
		,C.iZonaHoraria4=A.iZonaHoraria4,C.iZonaHoraria_verano4=A.iZonaHoraria_verano4
		,C.iZonaHoraria5=A.iZonaHoraria5,C.iZonaHoraria_verano5=A.iZonaHoraria_verano5
		'' + @columnsIAQuntum + ''
	FROM '' + QUOTENAME(@tableName) + '' A
	LEFT JOIN dbo.ccoWorkingTable B WITH (ROWLOCK, UPDLOCK, READPAST) ON A.callout_id = B.callout_id AND B.cal_status <= 2
	INNER JOIN dbo.ccoCallsOutSource C WITH (ROWLOCK, UPDLOCK) ON A.callout_id = C.callout_id'';

	SET @paramDef = N''@cal_status_param TINYINT, @emtpy varchar(1)'';
	EXEC sp_executesql @sql, @paramDef, @cal_status_param = @cal_status, @emtpy= @emtpy;
END
ELSE IF @action = 6
BEGIN
	DECLARE @today DATE = CONVERT(DATE, GETDATE());

	SET @sql = ''
UPDATE B
SET B.list_id = A.list_id
FROM '' + QUOTENAME(@tableName) + '' A
INNER JOIN ccoCallsOutSource C WITH (NOLOCK)  ON A.callout_id = C.callout_id
INNER JOIN ccoWorkingTable B WITH (NOLOCK)    ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id
WHERE B.list_id <> A.list_id;

WHILE 1 = 1
BEGIN
    ;WITH cte AS
    (
        SELECT TOP (200) ld.logDial_id
        FROM '' + QUOTENAME(@tableName) + '' t
        LEFT JOIN ccoWorkingTable wt WITH (READPAST, UPDLOCK) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
        INNER JOIN ccoLogDials ld WITH (UPDLOCK) ON ld.callout_id = t.callout_id
        WHERE wt.callout_id IS NULL AND ld.fecha >= @today AND (ld.canBeRecycled = 1 OR ld.canBeRecycled IS NULL)
		ORDER BY ld.logDial_id
    )
    UPDATE ld
    SET ld.canBeRecycled = 0
    FROM ccoLogDials ld
    INNER JOIN cte x
        ON ld.logDial_id = x.logDial_id;

    IF @@ROWCOUNT = 0 BREAK;

	WAITFOR DELAY ''''00:00:00.05'''';
END


WHILE 1 = 1
BEGIN
    ;WITH cte AS
    (
        SELECT TOP (200) co.cal_id
        FROM '' + QUOTENAME(@tableName) + '' t
        LEFT JOIN ccoWorkingTable wt WITH (READPAST, UPDLOCK) ON t.cam_id = wt.cam_id AND t.callout_id = wt.callout_id AND wt.cal_status < 2
        INNER JOIN ccoCallsOut co WITH (UPDLOCK) ON co.callout_id = t.callout_id
        WHERE wt.callout_id IS NULL AND co.cal_Inicio >= @today AND (co.canBeRecycled = 1 OR co.canBeRecycled IS NULL)
		ORDER BY co.cal_id
    )
    UPDATE co
    SET co.canBeRecycled = 0
    FROM ccoCallsOut co
    INNER JOIN cte x
        ON co.cal_id = x.cal_id;

    IF @@ROWCOUNT = 0 BREAK;

	WAITFOR DELAY ''''00:00:00.05'''';
END

	'';
	--print(@sql)
	EXEC sp_executesql @sql, N''@today DATE'', @today=@today;
END
ELSE IF @action = 7
BEGIN

	-- Contar registros inválidos
	SET @sql = ''
	SELECT @cnt = COUNT(*)
	FROM '' + QUOTENAME(@tableName) + '' A
	LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
		ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
	WHERE B.callout_id IS NULL and A.callout_id > 0;'';

	EXEC sp_executesql @sql, N''@cnt INT OUTPUT'', @cnt = @count OUTPUT;

	-- Insertar en ccRIALogPhones los registros sin match
	SET @sql = ''
	INSERT INTO ccRIALogPhones(load_id, cal_key, telefono, tipoMov, motivo,internationalRecords)
	SELECT @idLoad, A.cal_Key, @emtpy, 2, @motivo,@internationalRecords
	FROM '' + QUOTENAME(@tableName) + '' A
	LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
		ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
	WHERE B.callout_id IS NULL;'';

	EXEC sp_executesql @sql,
		N''@idLoad INT, @motivo NVARCHAR(200),@emtpy varchar(1),@internationalRecords int'',
		@idLoad = @idLoad,
		@motivo = @motivo,
		@internationalRecords =@internationalRecords,
		@emtpy=@emtpy;

	-- Eliminar los registros sin match
	SET @sql = ''
	DELETE A
	FROM '' + QUOTENAME(@tableName) + '' A
	LEFT JOIN ccoWorkingTable B WITH (NOLOCK)
		ON A.callout_id = B.callout_id AND A.cam_id = B.cam_id AND B.cal_status <= 2
	WHERE B.callout_id IS NULL;'';

	EXEC(@sql);

	-- Retornar el count como resultado
	SELECT @count AS RegistrosEliminados;
END
ELSE IF @action = 8
BEGIN


	-- Contar total de registros antes del borrado
	SET @sql = ''
	SELECT @cnt = COUNT(*) FROM '' + QUOTENAME(@tableName) + '';'';

	EXEC sp_executesql @sql, N''@cnt INT OUTPUT'', @cnt = @count OUTPUT;

	-- Log en ccRIALogPhones todos los registros de la tabla temporal
	SET @sql = ''
	INSERT INTO ccRIALogPhones(load_id, cal_key, telefono, tipoMov, motivo,internationalRecords)
	SELECT @idLoad, cal_Key, @emtpy, 6, @motivo,@internationalRecords FROM '' + QUOTENAME(@tableName) + '';'';

	EXEC sp_executesql @sql,
			N''@idLoad INT, @motivo NVARCHAR(200),@emtpy varchar(1),@internationalRecords int'',
		@idLoad = @idLoad,
		@motivo = @motivo,
		@internationalRecords =@internationalRecords,
		@emtpy=@emtpy;

	-- Eliminar todos los registros de la tabla temporal
	SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '';'';
	EXEC(@sql);

	-- Retornar el número de registros eliminados
	SELECT @count AS RegistrosEliminados;
END
ELSE IF @action = 9 BEGIN

	DECLARE @country TINYINT;
	SELECT @country = CONVERT(TINYINT, valor) FROM ccSettings WITH (NOLOCK) WHERE setting_id = 104;
	if @country =1 begin
		select @zipCodeSchedule=zipCodeSchedule from ccCampsExtend where cam_id =@cam_id
	end
	if @zipCodeSchedule is null begin
		set @zipCodeSchedule=0
	end

	SET @sql = ''
UPDATE T SET
	iZonaHoraria = CASE
		WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
		WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
		ELSE dbo.fnGetTimeZone(T.cal_telefono,  0) END,

	iZonaHoraria_verano = CASE
		WHEN (cal_telefono IS NULL OR LTRIM(RTRIM(cal_telefono)) = @emtpy) THEN 0
		WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
		ELSE dbo.fnGetTimeZone(T.cal_telefono,  1) END,

	iZonaHoraria2 = CASE
		WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
		WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
		ELSE dbo.fnGetTimeZone(T.cal_telefono2,  0) END,

	iZonaHoraria_verano2 = CASE
		WHEN (cal_telefono2 IS NULL OR LTRIM(RTRIM(cal_telefono2)) = @emtpy) THEN 0
		WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
		ELSE dbo.fnGetTimeZone(T.cal_telefono2,  1) END,

	iZonaHoraria3 = CASE
		WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
		WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
		ELSE dbo.fnGetTimeZone(T.cal_telefono3,  0) END,

	iZonaHoraria_verano3 = CASE
		WHEN (cal_telefono3 IS NULL OR LTRIM(RTRIM(cal_telefono3)) = @emtpy) THEN 0
		WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
		ELSE dbo.fnGetTimeZone(T.cal_telefono3,  1) END,

	iZonaHoraria4 = CASE
		WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
		WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
		ELSE dbo.fnGetTimeZone(T.cal_telefono4,  0) END,

	iZonaHoraria_verano4 = CASE
		WHEN (cal_telefono4 IS NULL OR LTRIM(RTRIM(cal_telefono4)) = @emtpy) THEN 0
		WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
		ELSE dbo.fnGetTimeZone(T.cal_telefono4,  1) END,

	iZonaHoraria5 = CASE
		WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
		WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_invierno,0)
		ELSE dbo.fnGetTimeZone(T.cal_telefono5,  0) END,

	iZonaHoraria_verano5 = CASE
		WHEN (cal_telefono5 IS NULL OR LTRIM(RTRIM(cal_telefono5)) = @emtpy) THEN 0
		WHEN  @country=1 AND @zipCodeSchedule= 1 THEN ISNULL(Z.tz_id_verano,0)
		ELSE dbo.fnGetTimeZone(T.cal_telefono5,  1) END

FROM '' + QUOTENAME(@tableName) + '' T
OUTER APPLY dbo.fnGetTimeZoneByZip(T.Dato1) AS Z
''
EXEC sp_executesql @sql,
		N''@zipCodeSchedule bit,@country TINYINT,@emtpy varchar(1)'',
		@zipCodeSchedule = @zipCodeSchedule,
		@country = @country,
		@emtpy = @emtpy

--print(@sql)
END
ELSE IF @action = 10
BEGIN
	SET @sql = ''DELETE FROM '' + QUOTENAME(@tableName) + '' WHERE callout_id = 0;'';
	EXEC sp_executesql @sql;
END
	ELSE IF @action = 11 BEGIN

	SET @sql = ''
UPDATE T SET
	international=@internationalRecords
FROM '' + QUOTENAME(@tableName) + '' T
''
EXEC sp_executesql @sql,
		N''@internationalRecords int'',
		@emtpy = @emtpy

END


ELSE
BEGIN
	RAISERROR(''Acción inválida: %d. Use 1 = UpdateOutSource, 2 = UpdateLogDials, 3 = UpdateCallsOut, 4 = UpdateInternational'', 16, 1, @action);
	RETURN;
END
END'
EXEC(@sql)

			

		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
		EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
