USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_GalateaGetCampaignsIAController]    Script Date: 12/02/2026 04:16:55 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ccsp_GalateaGetCampaignsIAController]
    @Option INT,      
    @AdminID INT      
AS
BEGIN
    SET NOCOUNT ON;

    IF @Option = 1
    BEGIN
        SELECT
            cast(i.Inbound_id as int) AS inbound_id,
            i.descripcion AS description,
            cast(i.chat as smallint) as chat
        FROM
            ccRIAWorkGroupUsers wgu
            INNER JOIN ccRIACampEspWG cwg ON wgu.IDWG = cwg.IDWG
            INNER JOIN ccInbound i ON cwg.IdCampEsp = i.Inbound_id
        WHERE
            wgu.user_id = @AdminID
            AND cwg.Tipo = 0               
        ORDER BY
            i.Inbound_id;                
    END
    
END
