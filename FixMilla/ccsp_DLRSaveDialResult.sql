USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_DLRSaveDialResult]    Script Date: 27/03/2024 10:54:10 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccsp_DLRSaveDialResult] 
				@callout_id INT, @cam_id SMALLINT, @tipoResDial_id TINYINT, @Telefono VARCHAR(30), @Puerto SMALLINT,
				@tDialing TINYINT= 0, @tBusy SMALLINT= 0, @call_id INT= 0, @answerbit BIT= NULL, @tAnswerBit SMALLINT= 0,
				@canceledNoAgents BIT= 0, @disconnectCause VARCHAR(250)= '', @cal_key VARCHAR(40)= '', @call_TS VARCHAR(15)=
				''
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @tNow AS DATETIME, @RecicleSIC TINYINT;
	DECLARE @logDial_id INT;
	DECLARE @tAnswerBitFinal AS DATETIME;
	DECLARE @tTotal SMALLINT;

	SELECT @RecicleSIC = ISNULL(valor, 0)
	FROM ccSettings
	WHERE setting_id = 60;

	SELECT @tTotal = @tDialing + @tAnswerBit;

	SELECT @tNow = GETDATE();

	SELECT @tAnswerBitFinal = DATEADD(ss, -@tAnswerBit, @tNow);

	-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
	IF @cal_key = ''
	BEGIN		
		SELECT @cal_key = cal_key
		FROM ccoCallsOutSource WITH(NOLOCK)
		WHERE @callout_id = callout_id;			
	END;
		
	IF @call_id > 0 AND @tipoResDial_id = 1
	BEGIN
		INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
		TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id )
				SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
				'00000000', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.
				fnGetTipoLlamada( @Telefono );
	END;
	ELSE
	BEGIN
		INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
		TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id )
				SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
				'00000000', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(
				@Telefono );
	END;

	SELECT @logDial_id = SCOPE_IDENTITY();
		

	-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
	IF @call_id > 0 AND @tipoResDial_id = 1
	BEGIN
		UPDATE ccoCallsOut WITH(ROWLOCK)
			SET cal_puerto = @Puerto, cal_manual = CASE WHEN cal_manual = 1 THEN 2 ELSE cal_manual END
			WHERE cal_id = @call_id AND cal_puerto = 0;

		EXEC ccsp_CstoCalculaCosto @call_id;		
	END;


	--2020-06-04 para marcaciones manuales no efectivas guarda el cal_id
	--if @call_id > 0 and @tipoResDial_id != 1
	--begin
	--	update ccologdials with(rowlock) set cal_id=@call_id where logDial_id=@logDial_id
	--end

	-- inserta informacion para reportes de workgroup
	INSERT INTO ccRIAWorkGroup_logDial_id( IDWG, logDial_id, cam_id, TIMESTAMP )
	SELECT IDWG, @logDial_id, IdCampEsp, GETDATE()
	FROM ccRIACampEspWG with(nolock) 
	WHERE tipo = 1 AND 	IdCampEsp = @cam_id;

	-- Guarda configuracion de TipoDialingMode
	UPDATE ccoLogDials WITH(ROWLOCK)
		SET TipoDialingMode = dbo.fn_getDialingMode( @call_id, 0, @logDial_id, @cam_id )
	WHERE logDial_id = @logDial_id;

IF @RecicleSIC = 1
	BEGIN
		UPDATE ccoWorkingTable WITH(ROWLOCK) SET tipoResDial_id = @tipoResDial_id WHERE callout_id = @callout_id;
	END;
	SET NOCOUNT OFF;
END;

SELECT @logDial_id as LogDialId