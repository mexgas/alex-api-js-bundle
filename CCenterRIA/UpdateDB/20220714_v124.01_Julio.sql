/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/05/23
Description: Archivo julio 2022, cambios preview

Database: CCenterRia
Required version: 123.27

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 1
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion in(@version,@version-1) and @actualVersionFix >= 53
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'K002056 se agregan menus'
    set @sql = 'if not exists( select * from ccmenus where type=3 and menu_id=12000)
begin
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
	values(12000,''WhatsApp|WhatsApp'',12000,''A'',7,3,'''',''9f1901c17c425d0a50eb4ef481632d34b736aa1dae75e5134dd5c15d4dde150d'')

	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
	values(12010,''Detalle de conversaciones|Conversations Detail'',12000,''B'',7,3,'''',''accb20a46285ea9856ace61e5e3ffd452de1f55f20c7a005ce8e05a503060fb18beee994719b6abd36ad36efaffd0370'')

	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
	values(12020,''Conversaciones por campaña|Conversations by Campaign'',12000,''B'',7,3,'''',''2605c8244920fb599fb936a4bf94521a7284d5e414815e8ef15fa8f6b0040db16a54ce29b02250a22a8cb87c41c6f3b30e3860a31b59d733442bb174a555b7b2'')

end'
	EXEC(@sql)

    set @process = 'K002056 se actualiza el orden de los menus'
    set @sql = '
    update ccMenus set ordengral = 8 where type = 3 and parent = 6000
update ccMenus set ordengral = 9 where type = 3 and parent = 8000
update ccMenus set ordengral = 10 where type = 3 and parent in  (8050,8060,8080)
update ccMenus set ordengral = 11 where type = 3 and parent = 7000
update ccMenus set ordengral = 12 where type = 3 and parent = 9000'
    EXEC(@sql)

    set @process = 'K002056 Se altera ccsp_RIACATMenu'
    set @sql = 'ALTER procedure [dbo].[ccsp_RIACATMenu]
@id_User varchar(2000),
@id_Menu int,
@Type tinyint,
@ReportRol tinyint = 1,
@CM tinyint = 1,
@AE tinyint = 1
as
set nocount on
Declare @NRS tinyint
Declare @AVRS tinyint
Declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenusChat tinyint
Declare @MenuMail tinyint
Declare @MenuCRM tinyint
Declare @monitorPortMenu tinyint

set @MenuMail=0
set @MenuCRM = 0
set @monitorPortMenu =0

select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
select @AVRS = valor from ccSettings where setting_id = 124
select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
select @IVRScripting = valor from ccsettings where setting_id = 125
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155
select @MenuCRM = valor from ccsettings where setting_id = 168
select @monitorPortMenu = case when valor=''1'' then 1 else 0 end from ccsettings where setting_id = 186

---Mail MenuId (81)
if @Type=1
begin
	if @ReportRol = 1
	begin
		Select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus)) where type = 1
		and (
		(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82,83,84,85,69))
		or (menu_id = 41 and @CM = 1)
		or (menu_id = 42 and @AE > 0)
		or (menu_id = 53 and @NRS = 1)
		or (menu_id in (71,72) and @IVRScripting = 1)
		or (menu_id in (73,74,75,76) and @AVRS = 1)
		or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
		or (menu_id = 79 and @MenusChat > 0)
		or (menu_id in (81,82,84,85) and @MenuMail = 1)--Mail
		or (menu_id = 83 and @MenuCRM > 0)
		or (menu_id = 69 and @monitorPortMenu > 0)--Monitoreo de puertos
		)
		order by ordengral asc
		return(0)

	end
	else if @ReportRol = 3 begin
		select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) and menu_id not in (select distinct Parent from ccMenus where menu_id >= 2000 and type = 3)
		and (menu_id not in (3131,3132,3133,3134,3135,3136,8061,8062,8063,8071,8072,8080,10000,10010,10020,10030,10040))
		or  (menu_id     in (3131,3132,3133,3134,3135,3136) and @MenusChat > 0 )
		or  (menu_id     in (8061,8062,8063,8071,8072,8080) and @AVRS > 0)
		or  (menu_id     in (9000,9010) and @MenuCRM > 0 )
		or  (menu_id     in (10000,10010,10020,10030,10040) and @MenuMail > 0 )
		order by ordengral asc,menu_id
		return(0)
	end
	else begin
		select distinct Nivel, menu_descrip, menu_id,ordengral,release from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
		return(0)
	end

end

if @Type=2
begin
	delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu and type = @ReportRol
	return(0)
end

if @Type=3
begin
	insert into ccMenuUser(id_User,id_Menu,type) values (@id_User, @id_Menu,@ReportRol)
	return(0)
end

if @Type=4
begin
	declare @lan varchar(3), @page varchar(200)
	select @page = ''http://''+valor+''/'' from ccSettings where setting_id = 58
	select @lan = case valor when 0 then ''ES'' else ''EN'' end from ccSettings where setting_id = 27

	select ''Help/''+@lan+''/''+ cast(@id_Menu as varchar)+''.swf'' HelpSWF, @page page, @lan lang
	return(0)
end

set nocount off'
    EXEC(@sql)
set @process = 'K004016-Agente-Poder recibir transferencias entre Agentes, se altera el sp ccsp_AgentTransfLstArea para el listado de agentes en blended y normal'
set @sql = '
ALTER PROCEDURE [dbo].[ccsp_AgentTransfLstArea]
@userID INT,
@current INTEGER = 0
AS
set nocount on

BEGIN
declare @value int
declare @valueDialingMode int 
set @value = 0
set @valueDialingMode=0
select @value = case when valor=''1'' then 1 else 0 end from ccSettings (nolock) where setting_id = 191
select @valueDialingMode = case when DialingMode= 1 then 1 else 0 end from ccusers  (nolock) where user_id = @userID
    IF @value = 0
        begin
            select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name,login from ccusers cu (nolock) join
            (
                select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp (nolock)
                join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
            )
            x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID and cu.DialingMode=@valueDialingMode
            Order by name asc
        end

    if @value = 1
        begin
            if (@current <> 0)
                begin
                    select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name,login from ccusers cu (nolock) join
                    (
                        select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp (nolock)
                        join ccmonitorext ce (nolock) on cp.ext_id = ce.ext_id where user_id > 0
                    )
                    x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
                    and IDArea in (select cu.IDArea from ccUsers cu join ccInbound ci (nolock) on cu.IDArea = ci.IDArea where inbound_id =  @current)
                    Order by name asc
                end
            else
                begin
                    select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as name,login from ccusers cu (nolock) join
                    (
                        select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp (nolock)
                        join ccmonitorext ce (nolock) on cp.ext_id = ce.ext_id where user_id > 0
                    )
                    x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID and cu.DialingMode=@valueDialingMode
                    and IDArea in (select IDArea from ccUsers (nolock) where User_id = @userID)
                    Order by name asc
                end
        end
END
       '
EXEC(@sql)
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END


