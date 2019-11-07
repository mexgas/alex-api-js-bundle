CREATE PROCEDURE ccsp_ADMAddAgent
@Login varchar(12),
@Nombres varchar(45),
@ApellidoPaterno varchar(35),
@ApellidoMaterno varchar(35),
@Password  varchar(15),
@Sexo bit
AS
set nocount on
declare @User_id smallint
declare @idioma as bit
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

if exists(select login from ccUsers where Login = @Login and status > 0)
 begin
	select -1, case @idioma when 1 then 'Login in Use' else 'Login en Uso' end
	return(0)
 end
 
if exists( select Nombres from ccUsers where Nombres=@Nombres AND ApellidoPaterno=@ApellidoPaterno AND ApellidoMaterno=@ApellidoMaterno)
 begin
	select -2, case @idioma when 1 then 'Name in Use' else 'Nombre en Uso' end
	return(0)
 end

Insert ccUsers ( Login, Nombres, ApellidoPaterno, ApellidoMaterno, Password, TipoUser_id, Status, TipoLLamadas, Sexo )
 Values( @Login, @Nombres, @ApellidoPaterno, @ApellidoMaterno, @Password, 1, 1, 1, @Sexo )
select @User_id= User_id from ccUsers where Login= @Login

select @User_id, case @idioma when 1 then 'User ' + @Login + ' Added Succesfully'
else 'Usuario ' + @Login + ' Dado de Alta' end
return(0)
set nocount off