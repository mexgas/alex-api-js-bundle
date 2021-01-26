CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSchedulesManagement]
	@option smallint = -1,
	@camId int = -1,
	@camType smallint = -1,
	@scheduleId int = -1,
	@areaId smallint = -1,
	@moduleId tinyint = 0,
	@userId smallint = -1,
	@operationType tinyint = 0
AS
SET NOCOUNT ON;
DECLARE @transtate BIT
IF @@TRANCOUNT = 0
BEGIN
	SET @transtate = 1
	BEGIN TRANSACTION transtate
	END
	BEGIN TRY
		IF @option = 1 --Obtener horarios
		BEGIN
			SELECT horario_id as ScheduleId, Descripcion as [Description],
			HoraInicio as StartHour, MinInicio as StartMinute, HoraFin as EndHour,
			MinFin as EndMinute, Lunes as Monday, Martes as Tuesday, Miercoles as Wednesday,
			Jueves as Thursday, Viernes as Friday, Sabado as Saturday, Domingo as Sunday FROM ccHorarios
		END
		IF @option = 2 --Obtener relaciones de horarios y campañas
		BEGIN
			IF(@camType=1)
			BEGIN
				SELECT cam_id as CampId, Horario_id as ScheduleId FROM ccCampsHorarios WHERE cam_id = @camId
			END
			IF(@camType=0)--campañas de entrada
			BEGIN
				SELECT CONVERT(INT, Inbound_id) as CampId, Horario_id as ScheduleId FROM ccInboundHorarios WHERE Inbound_id = CONVERT(SMALLINT, @camId)
			END
		END
		IF @option =3--agregar la relación de horarios con campañas de salida y entrada
		BEGIN
			IF(@camType =1)
			BEGIN
				IF NOT EXISTs (SELECT cam_id, Horario_id FROM ccCampsHorarios WHERE cam_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					INSERT INTO [CCenterRia].[dbo].[ccCampsHorarios](cam_id, Horario_id)
						VALUES (@camId, @scheduleId)
					SELECT 1
				END
				SELECT 0
			END
			IF(@camType = 0)
			BEGIN
				IF NOT EXISTs (SELECT Inbound_id, Horario_id FROM ccInboundHorarios WHERE Inbound_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					INSERT INTO [CCenterRia].[dbo].ccInboundHorarios(Inbound_id, Horario_id)
						VALUES (@camId, @scheduleId)
					SELECT 1
				END
				SELECT 0
			END
		END
		IF @option = 4 --eliminar relación del horario
		BEGIN
			IF(@camType = 1)
			BEGIN
				IF EXISTs (SELECT cam_id, Horario_id FROM ccCampsHorarios WHERE cam_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					DELETE ccCampsHorarios where cam_id=@camId and horario_id=@scheduleId
					SELECT 1
				END
				SELECT 0
			END
			IF(@camType = 0)
			BEGIN
				IF EXISTs (SELECT Inbound_id, Horario_id FROM ccInboundHorarios WHERE Inbound_id = @camId AND Horario_id = @scheduleId)
				BEGIN
					DELETE ccInboundHorarios where inbound_id=@camId and horario_id=@scheduleId
					SELECT 1
				END
				SELECT 0
			END
		END
		IF @option = 5
		BEGIN
			IF (EXISTS(SELECT Horario_id FROM ccInboundHorarios WHERE horario_id = @scheduleId) OR EXISTS(SELECT Horario_id FROM ccCampsHorarios WHERE Horario_id = @scheduleId))
			BEGIN
				SELECT 1
			END
			ELSE
			BEGIN
				SELECT 0
			END
		END
		IF @option = 7 --insetar log
		BEGIN
			DECLARE @area nvarchar(max) = (SELECT AreaName FROM [CCenterRia].[dbo].[ccRIACat_Areas] where IDArea = @areaId)
			DECLARE @userName nvarchar(max) = (SELECT [Login] FROM [CCenterRia].[dbo].[ccUsers] where [User_id] = @userId)
			DECLARE @campDescription nvarchar(max) 
			DECLARE @scheduleName nvarchar(max)
			IF(@camType = 1)
			BEGIN
				SET @campDescription = (SELECT cam_descripcion FROM [CCenterRia].[dbo].[ccCamps] WHERE cam_id = @camId)
			END
			IF(@camType = 0)
			BEGIN
				SET @campDescription = (SELECT descripcion FROM [CCenterRia].[dbo].[ccInbound] WHERE Inbound_id = @camId)
			END
			IF(@camType = 2)--actualizar horarios
			BEGIN
				IF (@scheduleId = 0)
				BEGIN
					SET @campDescription = ''
					DECLARE @MAXID INT = (SELECT MAX(horario_id) FROM ccHorarios)
					SET @scheduleName = (SELECT Descripcion FROM [CCenterRia].[dbo].[ccHorarios] WHERE horario_id = @MAXID)
				END
				ELSE
				BEGIN
					SET @campDescription = (SELECT Descripcion FROM [CCenterRia].[dbo].ccHorarios where horario_id = @scheduleId)
					SET @scheduleName = ''
				END
			END
			ELSE
			BEGIN
				SET @scheduleName = (SELECT Descripcion FROM [CCenterRia].[dbo].[ccHorarios] WHERE horario_id = @scheduleId)
			END
			INSERT INTO [CCenterRia].[dbo].[ccRIALog](areaName, operationDate, operationType, login, module_id, value, target)
				VALUES (@area, GETDATE(), @operationType, @userName, @moduleId, @scheduleName, @campDescription)
		END
		IF @option = 8 --obtener los ids de las campañas con el horario asignado
		BEGIN
			SELECT cam_id FROM ccCampsHorarios WHERE Horario_id=@scheduleId
		END
		IF @option = 9
		BEGIN
			SELECT Descripcion FROM ccHorarios
		END
		IF @option = 10
		BEGIN
			SELECT MAX(horario_id) FROM ccHorarios
		END
		IF @transtate = 1 AND XACT_STATE() = 1
		BEGIN
			COMMIT TRANSACTION transtate
		END;
	END TRY
	BEGIN CATCH
		DECLARE @error INT, @message VARCHAR(4000), @xstate INT;
		SELECT @error = ERROR_NUMBER(), @message = ERROR_MESSAGE(), @xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			ROLLBACK
		IF @xstate = 1
			ROLLBACK TRANSACTION ccsp_GalateaAdminPortsManagement;
		RAISERROR ('ccsp_GalateaAdminSchedulesManagement: %d: %s', 16, 1, @error, @message) ;
	END CATCH;