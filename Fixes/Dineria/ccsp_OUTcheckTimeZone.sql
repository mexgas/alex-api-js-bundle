USE [CCenterRia]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_OUTcheckTimeZone]    Script Date: 02/03/2024 08:42:00 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	ALTER PROCEDURE [dbo].[ccsp_OUTcheckTimeZone] @cam_id AS INT,@isReturnSelect bit=1
	AS
	SET NOCOUNT ON

	DECLARE @horaUniversal DATETIME, @revHorario BIT, @isShudulerLey BIT, @dateNow DATETIME
	DECLARE @hourStart INT, @hourEnd INT, @minStart INT, @minEnd INT
	DECLARE @timeMaxContestacion INT, @campType INT;

	SET @timeMaxContestacion = 60

	SELECT @revHorario = valor
	FROM ccsettings
	WHERE setting_id = 112

	SELECT @timeMaxContestacion = (cam_tNoContesta * 2)
	FROM cccamps
	WHERE cam_id = @cam_id

	SET @timeMaxContestacion = CEILING(cast(@timeMaxContestacion AS DECIMAL(10, 2)) / cast(60 AS DECIMAL(10, 2)))

	declare @schLaw table (hourStart int not null,minStart int not null,hourEnd int not null,minEnd int not null)

	SELECT @campType = CampType
	FROM ccCamps
	WHERE cam_id = @cam_id;

	DECLARE @isSmsCamp BIT = CASE WHEN @campType = 7 THEN 1 ELSE 0 END;

	insert into @schLaw
	exec ccsp_GetHourLaw @isSms = @isSmsCamp
	SELECT @hourStart = hourStart, @minStart = minStart, @hourEnd = hourEnd, @minEnd = minEnd from @schLaw

	SET DATEFIRST 1
	SET @horaUniversal = getutcdate()
	SET @dateNow = getdate()
	declare @iZonas int
	-- Si la campaña no tiene horarios asignados, marcar todas las zonas
	IF @revHorario = 0
	BEGIN
	    IF NOT EXISTS (
	            SELECT cam_id
	            FROM ccCampsHorarios WITH (INDEX (IX_ccCampsHorarios))
	            WHERE cam_id = @cam_id
	            )
	    BEGIN
	        SELECT @iZonas=sum(DISTINCT tz_id)
	        FROM (
	            SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha, 
	            datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora, 
	            datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto, 
	            datepart(dw, dateadd(mi, tz_offset * 60, @horaUniversal)) AS dia
	            FROM ccTimeZones
	            ) zonas
	        WHERE (
	                hora > @hourStart OR ( hora = @hourStart AND minuto >= @minStart)
	                )
	            AND (
	                hora < @hourEnd OR ( hora = @hourEnd AND minuto <= @minEnd)
	                )

	    if @isReturnSelect=1 begin
	        select @iZonas as iZonas
	    end
	    return @iZonas
	    END
	END

	IF @campType <> 7
	BEGIN
	    
	    SELECT h.horario_id, Descripcion, CASE WHEN HoraInicio > @hourStart THEN HoraInicio ELSE @hourStart END HoraInicio
	    , CASE WHEN (horaInicio > @hourStart OR (horaInicio = @hourStart    AND MinInicio >= @minStart) ) THEN MinInicio ELSE @minStart END MinInicio
	    , CASE WHEN horaFin < @hourEnd THEN horaFin ELSE @hourEnd END HoraFin
	    , CASE WHEN (
	        (horaFin < @hourEnd OR (horaFin = @hourEnd AND MinFin <= @minEnd)
	            )
	        ) THEN MinFin ELSE @minEnd END MinFin, Lunes, Martes, Miercoles, Jueves, Viernes, Sabado, Domingo
	    INTO #tempCamp
	    FROM cchorarios h
	    INNER JOIN ccCampsHorarios WITH (INDEX (IX_ccCampsHorarios)) ON h.horario_id = ccCampsHorarios.horario_id
	        AND ccCampsHorarios.cam_id = @cam_id

	    SELECT @iZonas=isnull(sum(DISTINCT tz_id), 0)
	    FROM (
	        SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha, 
	        datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora, 
	        datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto, 
	        datepart(dw, dateadd(mi, tz_offset * 60, @horaUniversal)) AS dia
	        FROM ccTimeZones
	        ) zonas
	    INNER JOIN #tempCamp ON (
	            (
	                hora > HoraInicio OR ( hora = HoraInicio AND minuto >= MinInicio)
	                )
	            AND (
	                hora < HoraFin OR (hora = HoraFin AND minuto <= (MinFin - @timeMaxContestacion))
	                )
	            AND (
	                Lunes = dia
	                OR Martes * 2 = dia
	                OR Miercoles * 3 = dia
	                OR Jueves * 4 = dia
	                OR Viernes * 5 = dia
	                OR Sabado * 6 = dia
	                OR domingo * 7 = dia
	                )
	            )

	    DROP TABLE #tempCamp
	    if @isReturnSelect=1 begin
	        select @iZonas as iZonas
	    end
	    return @iZonas
	END
	ELSE
	BEGIN
	        ;

	    WITH sch
	    AS (
	        SELECT DATEPART(hh, idate) AS HoraInicio, DATEPART(mi, iDate) AS MinInicio, 
	        DATEPART(hh, fdate) HoraFin, DATEPART(mi, fdate) MinFin
	        FROM ccSmsSchedules
	        WHERE cam_id = @cam_id
	            AND @dateNow BETWEEN dateadd(hh,-12,iDate) AND dateadd(hh,12,fDate)
	        ), daysch
	    AS (
	        SELECT CASE WHEN HoraInicio > @hourStart THEN HoraInicio ELSE @hourStart END HoraInicio
	        , CASE WHEN (horaInicio > @hourStart OR (horaInicio = @hourStart AND MinInicio >= @minStart )
	                        ) THEN MinInicio ELSE @minStart END MinInicio
	        , CASE WHEN horaFin < @hourEnd THEN horaFin ELSE @hourEnd END HoraFin
	        , CASE WHEN ((  horaFin < @hourEnd OR ( horaFin = @hourEnd AND MinFin <= @minEnd))
	                        ) THEN MinFin ELSE @minEnd END MinFin
	        FROM sch
	        ), zonas
	    AS (
	        SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha
	        , datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora
	        , datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto
	        FROM ccTimeZones
	        )
	    SELECT @iZonas=isnull(sum(DISTINCT B.tz_id), 0)
	    FROM daysch A
	    INNER JOIN zonas B ON (
	            hora >= HoraInicio OR ( hora = HoraInicio AND minuto >= MinInicio)
	            )
	        AND (
	            hora < HoraFin OR (hora = HoraFin AND minuto <= (MinFin - @timeMaxContestacion))
	            )

	    if @isReturnSelect=1 begin
	        select @iZonas as iZonas
	    end
	    return @iZonas
	END
	