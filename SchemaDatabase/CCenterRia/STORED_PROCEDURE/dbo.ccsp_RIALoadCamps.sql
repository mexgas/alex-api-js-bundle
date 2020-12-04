CREATE PROCEDURE [dbo].[ccsp_RIALoadCamps] @option SMALLINT, @AreaId SMALLINT = NULL, @Sup SMALLINT = NULL, @WGID SMALLINT = NULL
						AS
						SET NOCOUNT ON

						DECLARE @loginDays INT

						SET @loginDays = 0

						IF @option = 1 -- Todas las campañas
						BEGIN
							SELECT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0), isnull(DNCscrub, 0)
							FROM ccCamps a1
							JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
							JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
							WHERE a3.type_id = 1 AND a1.cam_id IN (
									SELECT cam_id
									FROM dbo.fGet_CampAcd_Area(@Sup, 1)
									)
							ORDER BY 5, 2

							RETURN (0)
						END

						IF @option = 2 -- Campañas de un Area
						BEGIN
							SELECT DISTINCT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG
							FROM ccCamps a1
							JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
							JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
							WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
							ORDER BY cam_descripcion

							RETURN (0)
						END

						IF @option = 3 -- Campañas por Supervisor
						BEGIN
							SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(a1.IDArea, 0) IDArea
							FROM ccCamps a1
							JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
							JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
							JOIN ccSupervisorCam a4 ON a1.cam_id = a4.cam_id
							WHERE a3.type_id = 1 AND a4.tipo = 1 AND a4.user_id = @Sup
							ORDER BY 5, 2

							RETURN (0)
						END

						IF @option = 4 -- Rels Camps-Agents
						BEGIN
							SELECT @loginDays = valor
							FROM ccSettings
							WHERE setting_id = 211 --Numero dias que cargara las relaciones

							SELECT LOGIN, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea, min(rel_id) rel_id
							FROM (
								SELECT A.LOGIN, A.User_id, Prioridad, Skill, C.cam_id, C.cam_descripcion, isnull(C.IDArea, 0) IDArea, CA.rel_id
								FROM ccCamps C
								JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id
								JOIN ccRIACampsGraph a2 ON C.cam_id = a2.cam_id
								JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
								JOIN ccUsers A ON A.User_id = CA.User_id AND A.TipoUser_id = 1 AND A.STATUS = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays)
								WHERE C.cam_id IN (
										SELECT cam_id
										FROM ccsupervisorcam
										WHERE user_id = CASE isnull(@Sup, 0) WHEN 0 THEN user_id ELSE @Sup END AND tipo = 1
										)
								) Relations
							GROUP BY LOGIN, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea
							ORDER BY User_id, cam_descripcion, cam_id, Prioridad

							RETURN (0)
						END

						IF @option = 5 -- Campañas por Supervisor
						BEGIN
							SELECT @AreaId = IDArea
							FROM ccUsers
							WHERE User_id = @sup

							SELECT DISTINCT Camps.cam_id, Camps.cam_descripcion, a3.frame, Camps.cam_procesando, isnull(Camps.IDArea, 0) IDArea, IsNull(CN.New, 0) AS New, IsNull(CN.CB, 0) AS CB, IsNull(CN.Pro, 0) AS Pro, IsNull(CN.pen, 0) AS Pen, cast(Camps.cam_procesando AS INT) AS St, Camps.cam_TipoJobs AS Job, isnull(CN.Fin, 0) Fin, isnull(CP.prioridad, '12345NNN') prioridad, cast(camps.dialorder AS TINYINT) dialorder, cast(camps.progDial AS TINYINT) progDial, U.monitored, Camps.aggressionFactor
							FROM ccCamps Camps
							LEFT JOIN ccCampsPrioridadTel CP ON CP.cam_id = Camps.cam_id
							LEFT JOIN ccCampsNvosCB CN ON CN.id = Camps.cam_id
							JOIN ccRIACampsGraph a2 ON (Camps.cam_id = a2.cam_id)
							JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
							JOIN ccSupervisorCam U ON Camps.cam_id = U.cam_id
							WHERE U.user_id = @sup AND tipo = 1 AND a3.type_id = 1 AND Camps.cam_id IN (
									SELECT cam_id
									FROM ccSupervisorCam
									WHERE tipo = 1 AND user_id = @sup
									) AND Camps.IDArea = @AreaId
							ORDER BY 5, cam_procesando DESC, cam_descripcion

							RETURN (0)
						END

						IF @option = 7 -- Una sola
						BEGIN
							SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(IDArea, 0) IDArea, isnull(DNCscrub, 0) DNCScrub
							FROM ccCamps a1
							JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
							JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
							WHERE a3.type_id = 1 AND isnull(a1.cam_id, 0) = isnull(@AreaId, 0)
							ORDER BY 5, 2

							RETURN (0)
						END

						IF @option = 8 -- Campañas de un Agente
						BEGIN
							SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame
							FROM ccCamps a1
							JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
							JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
							JOIN ccCampsAgente a4 ON a1.cam_id = a4.cam_id
							WHERE a3.type_id = 1 AND a4.user_id = @Sup
							ORDER BY 2

							RETURN (0)
						END
						IF @option = 9 -- Campañas de un Area
						BEGIN
							(SELECT DISTINCT a1.cam_id as CamID, cam_descripcion as CamDescription, frame as Frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) as RelationsWG,1 CamType, ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 1 and IdCampEsp = a1.cam_id and IDWG = @WGID group by IdCampEsp),0) IsAssignedToCurrentWG
							FROM ccCamps a1
							JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
							JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
							WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
							UNION
							SELECT DISTINCT b1.inbound_id, descripcion, frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(b1.inbound_id, 2) relationsWG, 0 CampType, ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 0 and IdCampEsp = b1.inbound_id and IDWG = @WGID group by IdCampEsp),0) isAssignedToCurrentWG--select * from ccRIACampEspWG
							FROM ccinbound b1
							JOIN ccRIAinboundGraph b2 ON b1.inbound_id = b2.inbound_id
							INNER JOIN ccRIAGraphics b3 ON b2.graphic_id = b3.graphic_id
							LEFT JOIN (
								SELECT inbound_id, CASE WHEN (sum(skill) / count(user_id)) = max(skill) THEN 0 ELSE 1 END skillDif
								FROM ccSkills
								GROUP BY inbound_id
								) S ON S.Inbound_id = b1.inbound_id
							WHERE b3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
							) ORDER BY camtype desc,cam_descripcion

							RETURN (0)
						END

						RETURN (0)

						SET NOCOUNT OFF