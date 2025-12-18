USE [CCReportsRIA]
GO

/****** Object:  View [dbo].[RepViewOutCallsDetail]    Script Date: 17/12/2025 02:38:52 p. m. ******/
/* Se cambia el alias de login de [userName] a fullName*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


    ALTER VIEW [dbo].[RepViewOutCallsDetail] AS 
    SELECT
    date,
    callKey,
    telephone,
    transfer,
    dialog,
    nque,
    wrapup,
    CallDisposition,
    subDisposition,
    extension,
    userId,
    [login] fullName,
    username [login],
    campaignId,
    campaign,
    duration,
    ncost,
    iva,
    total as totalRow,
    ByCarrier,
    Calltypes,
    dialType,
    whoHangUp,
    dialResult as callStatus,
    calId,
    year,
    month,
    day,
    hour,
    minutes,
    trunk,
    data1 [Dato1],
    data2 [Dato2],
    data3 [Dato3],
    data4 [Dato4],
    data5 [Dato5],
    MessageTime,
    grabId  
    FROM RepOutCallsDetail nolock
GO


