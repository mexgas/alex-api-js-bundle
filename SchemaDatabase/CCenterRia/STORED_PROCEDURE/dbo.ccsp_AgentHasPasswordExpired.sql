/*
   Verifica si el password de un agente (o de cualquier usuario) ha caducado
*/

CREATE PROCEDURE dbo.ccsp_AgentHasPasswordExpired 

@User_ID as integer, -- Número de usuario
@Period as integer -- Días en que el password expira

AS

declare @HasExpired as bit
declare @LastChange as datetime
declare @Difference as integer




--Obtiene cuándo fue el último cambio al password
SELECT @LastChange=LastPasswordChange FROM ccUsers WHERE User_id = @User_ID

--Obtiene los días de diferencia entre la fecha actual y la de último cambio
SELECT @Difference=datediff(dd,@LastChange,getdate())

--Devuelve el resultado
IF @Period=0 

  SELECT @HasExpired=0

ELSE IF abs(@Difference) >= @Period 
    SELECT @HasExpired = 1
ELSE

    SELECT @HasExpired = 0

SELECT 'HasExpired'=@HasExpired