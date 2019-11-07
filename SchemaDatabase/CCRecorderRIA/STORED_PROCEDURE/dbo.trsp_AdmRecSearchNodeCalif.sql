CREATE PROCEDURE [dbo].[trsp_AdmRecSearchNodeCalif]
							@CamACD_id int,
							@CallType int
							AS
							BEGIN
								SET NOCOUNT ON;

								IF @CallType = 0 
								BEGIN

									select a.calif_id, b.Description from ccCalifCamp a
									inner join ccTipoCalif b 
									on b.calif_id = a.calif_id and b.Calif_Status = 1
									where cam_id = @CamACD_id and a.tipo = 0
								END
								ELSE IF @CallType = 1 
									BEGIN 

										select a.calif_id, b.Description from ccCalifCamp a
										inner join ccTipoCalifOUT b 
										on b.calif_id = a.calif_id and b.CalifOUT_Status = 1
										where cam_id = @CamACD_id and a.tipo = 1
									END

							END