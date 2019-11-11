/*
Realiza cambios en el status de la campaña
Inserta un registro en la tabla ccCampsMovs cada vez que se realiza una acción
Nueva version: Inserta el id del usuario que realizó el cambio y el número de usuarios conectados al momento de hacer el cambio
*/
CREATE PROCEDURE ccsp_OUTCampMovs
@cam_id int,
@nStatusNEW tinyint,
@user_id int=0
AS
set nocount on
declare @nStatusNOW tinyint, @nNewJobs int, @nCBJobs int
declare @nAgentConn int --Cantidad de agentes conectados
declare @nTipoAnt smallint -- Tipo anterior de movimientos

IF @nStatusNEW not in (0,1,2) --0=Inicio, 1=Procesando, 2=Nuevos Registros
 BEGIN
	SELECT 0 --No se hizo Cambio
	return(0)
 END

SELECT @nStatusNOW= cam_procesando, @nTipoAnt = cam_TipoJobs FROM ccCamps WHERE cam_id = @cam_id

SELECT @nNewJobs= count(cal_status) FROM ccoWorkingTable WHERE cam_id = @cam_id and cal_status =0 -- New Jobs
SELECT @nCBJobs= count(cal_status) FROM ccoWorkingTable WHERE cam_id = @cam_id and cal_status =1 -- CallBacks

SELECT @nAgentConn = count(user_id) from 
	(select count(camp.user_id) user_id FROM
	ccposicion pos JOIN cccampsagente camp ON
	camp.user_id = pos.user_id WHERE 
	camp.cam_id = @cam_id and pos.user_id > 0
	group by camp.IDWG) X

if @nStatusNEW not in (0,1)
 BEGIN	-- Nuevos Jobs
	INSERT ccCampsMovs ( cam_id, TipoMov, NewRecords, CBRecords,user_id, cant_agent, prevMovs) Values ( @cam_id , @nStatusNEW, isnull(@nNewJobs,0), isnull(@nCBJobs,0),@user_id, @nAgentConn, @nTipoAnt)
	return(0)
 END

IF @nStatusNOW <> @nStatusNEW
 BEGIN	-- Start / Stop
	INSERT ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id, cant_agent, prevMovs) 
	Values (@cam_id, @nStatusNEW, isnull(@nNewJobs,0), isnull(@nCBJobs,0), @user_id, @nAgentConn, @nTipoAnt)
	-- Cambia el valor de statusnew para insertar sólo iniciar o detener en ccamps
	SET @nStatusNEW = CASE WHEN @nStatusNEW <> 0 THEN 1 ELSE 0 END
	UPDATE ccCamps SET cam_procesando=@nStatusNEW WHERE cam_id=@cam_id

	SELECT 1 --SI se hizo Cambio
 END

ELSE
 BEGIN
	SELECT 0 --No se hizo Cambio
 END

--Detener el AUTOINICIO si se detiene la campaña
IF @nStatusNEW = 0
 BEGIN
	UPDATE ccCampsAutoInicio SET AutoInicio = 0, AutoInicioHora = 0 WHERE cam_id = @cam_id
 END

return(0)
set nocount off