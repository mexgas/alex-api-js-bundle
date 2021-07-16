CREATE PROCEDURE [dbo].[ccsp_RIAGetRelsSupsAgent]

AS
--Relaciones Sup-Agt de acuerdo a WorkGroups
IF OBJECT_ID('tempdb..#Agt') IS NOT NULL
    DROP TABLE #Agt;
IF OBJECT_ID('tempdb..#Adm') IS NOT NULL
    DROP TABLE #Adm;
SELECT u.user_id AS agt, 
       w.IDWG
INTO #Agt
FROM ccusers u
     INNER JOIN ccriaworkgroupusers w WITH(NOLOCK) ON u.user_id = w.user_id
                                                      AND tipouser_id = 1;
SELECT u.user_id, 
       w.IDWG, 
       u.login, 
       ur.rol_id
INTO #Adm
FROM ccusers u
     INNER JOIN ccriaworkgroupusers w ON(u.user_id = w.user_id
                                         AND (tipouser_id = 2
                                              OR tipouser_id = 6)
                                         AND u.onLine = 1)
     LEFT JOIN ccUsers_Roles ur WITH(NOLOCK) ON ur.User_id = u.User_id
                                                AND ur.rol_id = 7;
SELECT DISTINCT 
       agt.agt AS agt, 
       adm.user_id AS sup, 
       adm.login
FROM #Agt agt
     INNER JOIN #Adm adm WITH(NOLOCK) ON agt.IDWG = adm.IDWG
                                         OR adm.Rol_id = 7
WHERE adm.user_id NOT IN
(
    SELECT User_id
    FROM ccRIAUsr_AdminPermissions
    WHERE per_id = 4
) -- Excluye sólo monitoreo
ORDER BY agt.agt, 
         adm.user_id;

IF OBJECT_ID('tempdb..#Agt') IS NOT NULL
    DROP TABLE #Agt;
IF OBJECT_ID('tempdb..#Adm') IS NOT NULL
    DROP TABLE #Adm;