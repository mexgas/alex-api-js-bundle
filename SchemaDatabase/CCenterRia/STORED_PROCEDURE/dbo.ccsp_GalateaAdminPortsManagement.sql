CREATE PROCEDURE [dbo].[ccsp_GalateaAdminPortsManagement]
			@action SMALLINT,
			@dialer_id INT = 0,
			@cam_id SMALLINT = 0
			AS
			SET NOCOUNT ON;
			DECLARE @transtate BIT
			IF @@TRANCOUNT = 0
			BEGIN
				SET @transtate = 1
			BEGIN TRANSACTION transtate
			END
			BEGIN TRY
				IF @action = 1 --return all ports
				BEGIN
					SELECT Dialers.dialer_id AS DialerId, Dialers.Descripcion AS PortDescription, Provedor.Descrip AS ProviderDescription, Dialers.Puerto
					FROM [CCenterRia].[dbo].[ccoDialers] AS Dialers INNER JOIN [CCenterRia].[dbo].[cstoProvedor] AS Provedor 
					ON Dialers.provedor_id = Provedor.provedor_id
				END;
				IF @action = 2 --return ports for camp
				BEGIN
					SELECT dialer_id AS DialerId, cam_id AS CampId FROM [CCenterRia].[dbo].[ccoDialerCamp] ORDER BY cam_id
				END;
				IF @action = 3 --insert port
				BEGIN
					IF NOT EXISTS (SELECT dialer_id, cam_id FROM [CCenterRia].[dbo].[ccoDialerCamp]
						WHERE dialer_id=@dialer_id AND cam_id=@cam_id)
					BEGIN
						INSERT INTO [CCenterRia].[dbo].[ccoDialerCamp](dialer_id, cam_id) VALUES (@dialer_id, @cam_id)
					END;
				END;
				IF @action = 4 --delete port
				BEGIN
					DELETE FROM [CCenterRia].[dbo].[ccoDialerCamp] WITH(ROWLOCK) WHERE cam_id = @cam_id AND dialer_id = @dialer_id
				END;
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
			RAISERROR ('ccsp_GalateaAdminPortsManagement: %d: %s', 16, 1, @error, @message) ;
			END CATCH;