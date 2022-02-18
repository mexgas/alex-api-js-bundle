CREATE PROCEDURE [dbo].[ccsp_AgentGetCalificaciones] @inOut  TINYINT
                                                    ,

/**********
0 in, 1 out
**********/

                                                    @cam_id INT, 
                                                    @isXml  BIT     = 1
AS
     SET NOCOUNT ON;
     DECLARE @sql NVARCHAR(MAX);
     IF @inOut = 0
         BEGIN
             IF EXISTS
             (
                 SELECT calif.calif_id
                 FROM ccTipoCalif AS calif
                      JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
                      LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id
                                                            AND rel.tipoSubRel = 1
                      LEFT JOIN ccTipoCalifSub AS sb ON rel.califsub_id = sb.califsub_id
                 WHERE cam_id = @cam_id
                       AND tipo = @inOut
             )
                 BEGIN
                     DECLARE @relationCamId INT;
                     SELECT @relationCamId = cam_id
                     FROM ccInbound
                     WHERE Inbound_id = @cam_id;
                     IF @relationCamId IS NULL
                         BEGIN
                             SET @relationCamId = 0
                     END;
                     SET @sql = ';WITH disposition
    AS (SELECT DISTINCT
             1 AS tag,NULL AS parent,calif.calif_id AS "selection!1!id",calif.Description AS "selection!1!string",calif.orden AS "selection!1!califorden",
			 ISNULL(calif.EndConversation,0) AS "selection!1!endConversation",NULL AS "subSelection!2!id",
			 NULL AS "subSelection!2!string",NULL AS "subSelection!2!orden",NULL AS "subSelection!2!endConversation",
			 ISNULL(calif.CanReprogram,0) AS "selection!1!canReprogram",NULL AS "subSelection!2!canReprogram"
        FROM ccTipoCalif AS calif
        INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id AND camp.cam_id = @cam_id AND camp.tipo = @inOut
        LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 1
        LEFT JOIN ccTipoCalifSub AS sb ON rel.califsub_id = sb.califsub_id
        WHERE calif.CanReprogram = 0 OR calif.CanReprogram = 1 AND @relationCamId > 0
        UNION
        SELECT DISTINCT
             2 AS tag,1 AS parent,calif.calif_id AS "selection!1!id",NULL AS "selection!1!string",calif.orden AS "selection!1!califorden",
			 ISNULL(calif.EndConversation,0) AS "selection!1!endConversation",sb.califsub_id AS "subSelection!2!id",
			 sb.califSubDesc AS "subSelection!2!string",CAST(sb.orden AS INT) AS "subSelection!2!orden",
			 ISNULL(sb.EndConversation,0) AS "subSelection!2!endConversation",NULL AS "selection!1!canReprogram",ISNULL(sb.CanReprogram,0) AS "subSelection!2!canReprogram"
        FROM ccTipoCalif AS calif
        INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id AND camp.cam_id = @cam_id AND camp.tipo = @inOut
        LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 1
        LEFT JOIN ccTipoCalifSub AS sb ON rel.califsub_id = sb.califsub_id
        WHERE sb.califsub_id IS NOT NULL AND (sb.CanReprogram = 0 OR sb.CanReprogram = 1 AND @relationCamId > 0))
';
                     IF @isXml = 1
                         BEGIN
                             SET @sql = @sql + 'select * from disposition
               order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden" for xml explicit, type';
                     END;
                     ELSE
                         BEGIN
                             SET @sql = @sql + 'select 
tag as Tag, isnull(parent,0) as Parent, "selection!1!id" as Id,isnull("selection!1!string",'''') as Description,
cast("selection!1!califorden" as int) as Orden, 
"selection!1!endConversation" EndConversation, isnull("subSelection!2!id",0) as SubId,
isnull("subSelection!2!string",'''') as SubDescription, 
cast(isnull("subSelection!2!orden",0) as int) as SubOrden,   
--CAST(  ROW_NUMBER() OVER(PARTITION BY parent ORDER BY "subSelection!2!orden" ASC) as INT) AS SubOrden,
isnull("subSelection!2!endConversation",0) as SubEndConversation, 
isnull("selection!1!canReprogram",0) as CanReprogram,isnull("subSelection!2!canReprogram",0) as SubCanReprogram
FROM disposition';
                     END;
                              PRINT @sql

                     EXEC sp_executesql 
                          @sql, 
                          N'@cam_id int, @InOut tinyint,@relationCamId int', 
                          @cam_id, 
                          @inOut, 
                          @relationCamId;
             END;
             RETURN 0;
     END;
     ELSE
         BEGIN
             IF @inOut = 1
                 BEGIN
                     IF EXISTS
                     (
                         SELECT calif.calif_id
                         FROM ccTipoCalifOUT AS calif
                              JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
                              LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id
                                                                    AND rel.tipoSubRel = 0
                              LEFT JOIN ccTipoCalifSubOUT AS sb ON rel.califsub_id = sb.califsub_id
                         WHERE cam_id = @cam_id
                               AND tipo = @inOut
                     )
                         BEGIN
                             SET @sql = ';WITH disposition
AS (SELECT DISTINCT
       1 AS tag,NULL AS parent,calif.calif_id AS "selection!1!id",calif.Description AS "selection!1!string",calif.keepDial AS "selection!1!keepOnDial",
	   calif.orden AS "selection!1!califorden",ISNULL(calif.finishPreview,0)
       AS "selection!1!finishPreview",NULL AS "subSelection!2!id",NULL AS "subSelection!2!string",NULL AS "subSelection!2!keepOnDial",
	   NULL AS "subSelection!2!orden",ISNULL(calif.CanReprogram,0) AS "selection!1!canReprogram",NULL AS "subSelection!2!canReprogram"
    FROM ccTipoCalifOUT AS calif
    INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
    LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 0
    LEFT JOIN ccTipoCalifSubOUT AS sb ON rel.califsub_id = sb.califsub_id
    WHERE cam_id = @cam_id AND tipo = @inOut
    UNION
    SELECT DISTINCT
       2 AS tag,1 AS parent,calif.calif_id AS "selection!1!id",NULL AS "selection!1!string",NULL AS "selection!1!keepOnDial",calif.orden AS "selection!1!califorden",ISNULL(calif.finishPreview,0) AS
       "selection!1!finishPreview",sb.califsub_id AS "subSelection!2!id",sb.califSubDesc AS "subSelection!2!string", 
	   sb.keepDial AS "subSelection!2!keepOnDial",CAST(sb.orden AS INT) AS "subSelection!2!orden",NULL AS"selection!1!canReprogram",
	   ISNULL(sb.CanReprogram,0) AS "subSelection!2!canReprogram"
    FROM ccTipoCalifOUT AS calif
    INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id
    LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 0
    LEFT JOIN ccTipoCalifSubOUT AS sb ON rel.califsub_id = sb.califsub_id
    WHERE cam_id = @cam_id AND tipo = @inOut AND sb.califsub_id IS NOT NULL)
';
                             IF @isXml = 1
                                 BEGIN
                                     SET @sql = @sql + 'select * from disposition
               order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden" for xml explicit, type';
                             END;
                             ELSE
                                 BEGIN
                                     SET @sql = @sql + 'SELECT tag AS Tag,ISNULL(parent,0) AS Parent,"selection!1!id" AS Id,ISNULL("selection!1!string",'''') AS Description,
    ISNULL("selection!1!keepOnDial",'''') AS KeepOnDial,
    --"selection!1!califorden" AS Orden,
    CAST(  ROW_NUMBER() OVER(ORDER BY "selection!1!califorden" ASC) as int) AS Orden,
    "selection!1!finishPreview" AS
    FinishPreview,ISNULL("subSelection!2!id",0) AS SubId,ISNULL("subSelection!2!string",'''') AS SubDescription
    ,ISNULL("subSelection!2!keepOnDial",0) AS SubKeepOnDial,
    ISNULL("subSelection!2!orden",0) AS SubOrden,    
    ISNULL("selection!1!canReprogram",0) AS CanReprogram,ISNULL("subSelection!2!canReprogram",0) AS SubCanReprogram
    FROM disposition';
                             END;
                             -- PRINT @sql

                             EXEC sp_executesql 
                                  @sql, 
                                  N'@cam_id int, @InOut int', 
                                  @cam_id, 
                                  @inOut;
                     END;
                     RETURN 0;
             END;
             ELSE
                 BEGIN
                     IF @inOut = 10
                         BEGIN
                             SELECT DISTINCT 
                                    S.califSub_id, S.califSubDesc, orden
                             FROM cctipoSubCalifRel AS R
                                  JOIN cctipoCalifSub AS S ON R.califSub_id = S.califSub_id
                             WHERE R.tipoSubRel = 1
                                   AND S.califSub_Status = 1
                                   AND R.calif_id = @cam_id
                                    ORDER BY S.orden, S.califSubDesc;
                             RETURN 0;
                     END;
                     ELSE
                         BEGIN
                             IF @inOut = 11
                                 BEGIN
                                     SELECT DISTINCT 
                                            S.califSub_id, S.califSubDesc, orden
                                     FROM cctipoSubCalifRel AS R
                                          JOIN cctipoCalifSubOut AS S ON R.califSub_id = S.califSub_id
                                     WHERE R.tipoSubRel = 0
                                           AND S.califSubOut_Status = 1
                                           AND R.calif_id = @cam_id
                                            ORDER BY S.orden, S.califSubDesc;
                                     RETURN 0;
                             END;
                     END;
             END;
     END;
     SET NOCOUNT OFF;