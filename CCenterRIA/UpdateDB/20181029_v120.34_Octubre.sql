/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Daniel Vega
Date: 2018/10/29
Description:
	CW-2257
Database: CCenterRia
Required version: 120.32

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 120--**********actualizar a 120 sin fix
set @versionfix = 34
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;


if  @actualVersion = @version and  @actualVersionFix = 32
	begin
		begin tran
		begin try

	set @process = 'CW-2257 Se agrega el setting 207 contraseña segura'
        set @Sql= '
		
		if not exists(select * from ccSettings where setting_id = 207)
		begin
		insert ccSettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) 
		values (207,1,''Habilita validaciones de contraseña segura para el admin'',1,''ADM'',
		''1 - en el admin la contraseña caduca cada 30 dias y tiene las validaciones de 1 caracter especial, 1 mayuscula, 1 numero y longitud minima de 8 caracteres'',
		''Habilita contraseña segura'',1,''.*'')
		end
    		'
        EXEC(@Sql)       

		set @process = 'CW-2257 Contraseña segura para el admin alter SP login regresa contraseña expiro'
        set @Sql= '
ALTER PROCEDURE [dbo].[ccsp_RIAADMChecaLogin]
@Login varchar(20) = '''',
@Password varchar(40) = '''',
@PasswordLwC varchar(40) = null,
@adminId int = 0

as
set nocount on

declare @x int
set @x=1

if @adminId <> 0
begin
update ccUsers set onLine = 0 where User_id = @adminId
return(0)
end

declare @UserID smallint
--****
declare @TipoUser_idx int
declare @ver int
declare @changeRecDisposition int
set @ver = 0
set @changeRecDisposition = 0

--****
select @UserID=User_id,@TipoUser_idx=TipoUser_id from ccUsers Where Login=@Login AND TipoUser_id in(2,6) and status>0

if(@TipoUser_idx=2 or @TipoUser_idx=6)
begin
if exists (SELECT * FROM ccRIAUsr_AdminPermissions WHERE User_id=@UserID and per_id in (2,6))
begin
set @ver = 1
end
if exists (SELECT * FROM ccRIAUsr_AdminPermissions WHERE User_id=@UserID and per_id=7)
begin
set @changeRecDisposition = 1
end
end

if not exists (select Login from ccUsers Where User_id=@UserID
AND(Password=@Password OR Password = dbo.md5(@password) OR dbo.md5(Password)=@Password
OR Password=@PasswordLwC OR Password = dbo.md5(@PasswordLwC) OR dbo.md5(Password)=@PasswordLwC))
begin
SELECT case when @UserID is null then 0 else 1 end ''LoginOK'', 0 ''PswdOK'', 0 ''UserID'', 0 ''Nombre'', 0 ''ADMServer'', 0 ''AreaId'', 0 ''viewavrs'',0 ''changeRecDisposition''
return(0)
end

update ccUsers set Password=isnull(@PasswordLwC, Password) Where User_id=@UserID and Password<>@PasswordLwC

update ccUsers set onLine = 1 where User_id = @UserID

Select 1 ''LoginOK'', 1 ''PswdOK'', User_id ''UserID'',
Nombres +'' ''+ isnull(ApellidoPaterno,'''') +'' ''+isnull(ApellidoMaterno,'''') ''Nombre'',
(SELECT valor FROM ccSettings WHERE setting_id=8) [ADMServer],
isnull(IDArea,0) ''AreaId'',
@ver  ''ViewAvrs'', @changeRecDisposition  ''changeRecDisposition'',
IIF (DATEDIFF(DAY,LastPasswordChange ,GETDATE()) > 30,1,0) passExpired
From ccUsers Where User_id=@UserID
return(0)
set nocount off   
    		'
    EXEC(@Sql)  	

		 
		/* End script release */

		/* Upgrade database version (use your own script to do it) */		
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end