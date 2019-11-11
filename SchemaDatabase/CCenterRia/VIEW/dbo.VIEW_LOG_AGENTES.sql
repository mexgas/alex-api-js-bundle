CREATE VIEW dbo.VIEW_LOG_AGENTES
AS
SELECT     l.fecha AS HORA_FIN, u.Login AS LOGIN, l.TipoStatusAge_id AS ID_STATUS_AGENTE, t.descripcion AS DESC_STATUS_AGENTE, 
                      l.tStatus AS TIEMPO_STATUS
FROM         dbo.ccLogAgentesDia l INNER JOIN
                      dbo.ccTipoStatusAgente t ON l.TipoStatusAge_id = t.TipoStatusAge_id INNER JOIN
                      dbo.ccUsers u ON l.User_id = u.User_id