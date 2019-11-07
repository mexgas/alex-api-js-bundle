CREATE PROCEDURE [dbo].[ccsp_RIAOUTCampMovs]
@cam_id int,
@nStatusNEW tinyint,
@user_id int=0
AS
SET NOCOUNT ON
/*
Realiza cambios en el status de la campaña
Inserta un registro en la tabla ccCampsMovs cada vez que se realiza una acción
Nueva version: Inserta el id del usuario que realizó el cambio y el número de usuarios conectados al momento de hacer el cambio
*/
declare @nStatusNOW tinyint, @nTipoAnt smallint -- Tipo anterior de movimientos
declare @nNewJobs int, @nCBJobs int, @nAgentConn int --Cantidad de agentes conectados

IF  @nStatusNEW NOT IN (0,1,2)--0=Inicio, 1=Procesando, 2=Nuevos Registros
 BEGIN
	SELECT 0 --No se hizo Cambio
	RETURN(0)
 END

SELECT @nStatusNOW= cam_procesando, @nTipoAnt = cam_TipoJobs FROM ccCamps WHERE cam_id = @cam_id

SELECT @nNewJobs= count(cal_status) FROM ccoWorkingTable WHERE cal_status =0 and cam_id =  @cam_id -- New Jobs
SELECT @nCBJobs = count(cal_status) FROM ccoWorkingTable WHERE cal_status =1 and cam_id =  @cam_id -- CallBacks

SELECT @nAgentConn = count(*) 
FROM ccposicion pos JOIN cccampsagente camp ON camp.user_id = pos.user_id
WHERE camp.cam_id = @cam_id	and pos.user_id > 0

IF @nStatusNEW not in (0,1)
 begin
 -- Nuevos Jobs
	INSERT ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords,user_id, cant_agent, prevMovs) 
	Values ( @cam_id , @nStatusNEW, isnull(@nNewJobs,0), isnull(@nCBJobs,0),@user_id, @nAgentConn, @nTipoAnt)
	return(0)
 end

IF @nStatusNOW=@nStatusNEW
 begin
	SELECT 0 --No se hizo Cambio
	IF @nStatusNEW = 0
		UPDATE ccCampsAutoInicio SET AutoInicio = 0, AutoInicioHora = 0 WHERE cam_id = @cam_id
	return(0)
 end

-- Start / Stop
INSERT ccCampsMovs ( cam_id, TipoMov, NewRecords, CBRecords, user_id, cant_agent, prevMovs ) Values ( @cam_id , @nStatusNEW, isnull(@nNewJobs,0), isnull(@nCBJobs,0), @user_id, @nAgentConn, @nTipoAnt)

-- Cambia el valor de statusnew para insertar sólo iniciar o detener en ccamps
SET @nStatusNEW = CASE  WHEN @nStatusNEW <> 0 THEN 1 ELSE 0  END
UPDATE ccCamps SET cam_procesando=@nStatusNEW  WHERE cam_id=@cam_id

--Versión anterior para insertar 
--INSERT ccCampsMovs ( cam_id, TipoMov, NewRecords, CBRecords) Values ( @cam_id , @nStatusNEW, isnull(@nNewJobs,0), isnull(@nCBJobs,0) )
SELECT 1 --SI se hizo Cambio

--Detener el AUTOINICIO si se detiene la campaña
IF @nStatusNEW = 0
	UPDATE ccCampsAutoInicio SET AutoInicio = 0, AutoInicioHora = 0 WHERE cam_id = @cam_id

SET NOCOUNT OFF