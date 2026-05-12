USE [CCReportsRIA]
GO

/****** Object:  View [dbo].[ccUserView]    Script Date: 19/03/2026 03:03:30 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [dbo].[ccUserView] AS
SELECT 
    User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, 
    TipoStatusAge_id, TipoUser_id, Status, Sexo, isnull(IDArea,1) IDArea, fCreate 
FROM ccUsers
UNION
SELECT 
    User_id, Login, Nombres, ApellidoPaterno, ApellidoMaterno, 
    TipoStatusAge_id, TipoUser_id, Status, Sexo, isnull(IDArea,1) IDArea, fCreate 
FROM ccUsers_Consulta;
    
GO


