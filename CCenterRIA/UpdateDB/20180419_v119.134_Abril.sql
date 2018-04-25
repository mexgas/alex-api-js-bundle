/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Mike Trejo
Date: 2018/04/04
Description:



Database: CCenterRia
Required version: 119.119.123

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

set @version = 119--**********actualizar a 119 sin fix
set @versionfix = 134
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 133
	begin
		begin tran
		begin try

		set @process = 'CW-1331  Version 119.122 Create tables ccChannelTransfer'
		set @Sql= 'if not exists(select * from sys.tables where name=''ccChannelTransfer'' ) begin
	create table ccChannelTransfer(
	pbxId tinyint	 NOT NULL,
	proveedorId tinyint	NOT NULL,
	startChannel int NOT NULL,
	endChannel int NOT NULL)

	ALTER TABLE ccChannelTransfer ADD PRIMARY KEY (pbxId,proveedorId);
end'
		EXEC(@sql)

		set @process = 'CW-1331  Version 119.122 ADD Column ccLogTransfers.pbxId'
		set @Sql= 'if not exists (select * from sys.columns where name = N''pbxId'' and Object_ID = Object_ID(N''ccLogTransfers''))
begin
    ALTER TABLE ccLogTransfers ADD pbxId tinyint;
end'
		EXEC(@sql)

		set @process = 'CW-1331  Version 119.122 ADD Column ccLogTransfers.ccLogTransfers'
		set @Sql= 'if not exists (select * from sys.columns where name = N''channel'' and Object_ID = Object_ID(N''ccLogTransfers''))
begin
    ALTER TABLE ccLogTransfers ADD channel int;
end'
		EXEC(@sql)

		set @process = 'CW-1331  Version 119.122 -- Alter SP ccsp_EngineLogTransfers'
		set @Sql= 'ALTER procedure [dbo].[ccsp_EngineLogTransfers]
@action as tinyint,
@cal_id as integer,
@tipo as tinyint,
@modo as tinyint,
@destino as varchar(50),
@tantes integer = 0,
@tdespues integer = 0,
@pbxId tinyint =0,
@channel int =0
as
-- tipo: 1 inbound, 2 outbound
-- modo: 0 externa ciega, 1 agente, 2 acd, 3 confer, 4 externa supervisada, 5 desborde

declare @totalCall_Time integer
declare @callout_id int

if @action = 1 begin
    if @modo = 4 begin
        insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel) 
        values ( @cal_id, @tipo, @modo, @destino, @tantes, @tdespues, getdate(), @pbxId,@channel )
        if @tdespues > 0 begin
                select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tdespues
                update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
        end
    end
    else begin
        if not exists (select * from ccLogTransfers where cal_id = @cal_id and tipo = @tipo)
            insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel) 
            values ( @cal_id, @tipo, @modo, @destino, 0, @tantes, getdate() ,@pbxId,@channel )

        if @tipo = 2 begin
            if @modo = 5 begin
                select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
                update ccLogTransfers set tDespuesXfer = @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2), tAntesXfer = @tdespues + (select tAntesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2) where cal_id = @cal_id and tipo = 2
            end
        
            if @modo in (0,1,2) begin
                select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
                update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
            end
        end

        else begin
            if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
                select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
                select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
                update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
            end
        end
    end
    if not exists(select * from ccAVRSTransfer where cal_id=@cal_id and tipo= @tipo-1) begin
        insert into ccAVRSTransfer (cal_id,tipo) values(@cal_id,@tipo-1)
    end
end

else if @action = 2 begin   
    if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
        select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
        update ccLogTransfers set tDespuesXfer = @tdespues + @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2) where cal_id = @cal_id and tipo = 2
        select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes + @tdespues
        update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
    end
end

else if @action = 4 begin
    select @totalCall_Time = ISNULL((select sum(tincall) from IVRCallsIn where callout_id = @cal_id), 0) + ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0)
    update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
end'
		EXEC(@sql)


		set @process = 'CW-1331  Version 119.122 udpate ccLogTransfers pbxId and channel '
		set @Sql= 'update ccLogTransfers set pbxId=0,channel=0 where pbxId is null and channel is null'
		EXEC(@sql)
	 
		set @process = 'Agregar nuevo menú a ccMenus-- CW-1697'
    	set @Sql= 'if not exists (select * from ccMenus where menu_id=2090)
begin
insert into ccMenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
values(2090,''Información General Especial|General Information Special'',2000,''B'',2,3,'''',''c706077b228a003efcba36c3d76f8ccd36593f3a4dd74e5c87b92746ea976e6fa69c0068d09919abe5b326a8e278fcaaf3a01cb1653f02e5933aa50fb8cf0147'');
end'
		EXEC(@Sql)

			set @process = 'Insertar datos en tabla ccMenus -- CW-1331'
		set @Sql= 'if not exists (select * from ccmenus where menu_id=4250)
		begin
			insert into ccMenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,release) values(4250,''Llamadas Contestadas y Transferidas|Answered and Transfer Calls'', 4000, ''B'', 4, 3,''d858e34ff9e6e3eac25177b292cc1ecd4db3504470848abb0c98ce0e953332e3194a869b013e81f376c6f4ee2d3eed7e7230ec9d5d275d790015a477571b5987780bf1f6f57527fb1a643962bb991c05'')
		end'
		EXEC(@Sql)
	
		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
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
