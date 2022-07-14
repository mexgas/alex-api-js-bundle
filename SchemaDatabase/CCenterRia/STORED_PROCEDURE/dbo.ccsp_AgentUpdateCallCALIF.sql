CREATE PROCEDURE [dbo].[ccsp_AgentUpdateCallCALIF] @IDCall INT, @calif_id SMALLINT, @TipoCall SMALLINT, @Origin INT = 0, @cal_key VARCHAR(20) = NULL, @callOutId INT = 0, @subId SMALLINT = 0
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
		WHERE Tipolista = 'default/KillList'
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
		WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> 'E' AND cbl.tipo = 0

		IF @tel IS NOT NULL AND @iddncList IS NOT NULL
		BEGIN
			--insert ccListaNegra
			INSERT INTO cclistanegra (telefono, idtipolista)
			VALUES (@tel, @iddncList)

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
			WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> 'E' AND cbl.tipo = 0
		END
	END

	RETURN (0)
END

IF @TipoCall = 2
BEGIN
	-- Toma como prioridad la configuraci?n de la subcalificaci?n (en caso de existir)
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

		EXEC ccsp_OUTInsertaCallBack @IDCall, '', @camp, @DateNewDial, @callOutId, 1, @userid, '', 1
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
				IF(LEFT(@number, 1) <> 'E') 
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
			IF(LEFT(@number, 1) <> 'E') 
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
					EXEC ccsp_InsertDNCList @tel, @iddncList

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
		-- Toma como prioridad la configuraci?n de la subcalificaci?n (en caso de existir)
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

	-- Toma como prioridad la configuraci?n de la subcalificaci?n (en caso de existir)
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

SET NOCOUNT OFF