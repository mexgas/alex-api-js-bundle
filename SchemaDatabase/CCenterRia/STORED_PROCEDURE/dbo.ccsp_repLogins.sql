CREATE PROCEDURE ccsp_repLogins
@sFini varchar(20),
@sFfin varchar(20)
AS
declare @FIni datetime
declare @FFin datetime
select @FIni=convert(datetime, @sFini, 101), @FFin=convert(datetime, @sFfin, 101)
select U.user_id, Nombres + ' '+ ApellidoPaterno + ' '+ ApellidoMaterno,
'Tipo' = 
  CASE 
    WHEN TipoMov = 1 THEN 'LogIn'
    WHEN TipoMov = 0 THEN 'LogOut'
  END
, Extension, fecha
from ccUsers U join ccLogLogin L on U.User_id = L.User_id
where fecha >= @FIni
and  fecha <= @sFfin
group by  U.user_id, Nombres, ApellidoPaterno, ApellidoMaterno, TipoMov, Extension, fecha
order by Nombres, ApellidoPaterno, fecha