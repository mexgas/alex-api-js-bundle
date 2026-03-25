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
