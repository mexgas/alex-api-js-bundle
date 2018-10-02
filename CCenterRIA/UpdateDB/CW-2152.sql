/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author:Daniel Vega
		
Date: 
Description:

Database: CCenterRia
Required version: 

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

set @version = 120--**********actualizar a 119 sin fix
set @versionfix = 25
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 24
	begin
		begin tran
		begin try
			

		set @process = 'CW-2152 Alter column Data'
        set @Sql= 'alter table DataCallIn alter column [Data] varchar(255)'
        EXEC(@Sql)        

        set @process = 'CW-2152 Alter FN fn_RIASplitDelimited'
        set @Sql= 'ALTER FUNCTION [dbo].[fn_RIASplitDelimited]
(	
	@List nvarchar(2000),
	@SplitOn nvarchar(1)
)
RETURNS @RtnValue table (
	Id int identity(1,1),
	Value nvarchar(255)
)
AS
BEGIN
	While (Charindex(@SplitOn,@List)>0)
	Begin 
		Insert Into @RtnValue (value)
		Select 
			Value = ltrim(rtrim(Substring(@List,1,Charindex(@SplitOn,@List)-1))) 
		Set @List = Substring(@List,Charindex(@SplitOn,@List)+len(@SplitOn),len(@List))
	End 
	
	Insert Into @RtnValue (Value)
    Select Value = ltrim(rtrim(@List))

    Return
END'
        EXEC(@Sql)        

        set @process = 'CW-2152 Alter SP spInsertCall'
        set @Sql= 'ALTER PROCEDURE [dbo].[spInsertCall]
@Pto smallint,
@DNIS varchar(14),
@ANI as varchar(14),
@inbound_id smallint=0,
@IVR_id int = 0, --Id del IVR
@CALLDATA as varchar(1275) = ''''
AS
declare @dni_id as smallint
declare @cal_id as int
declare @datacall as varchar(100)

select @Ani = left(rtrim(ltrim(@ANI)), 13)
select @DNIS = rtrim(ltrim(@DNIS))

	--busca dni_id
	select @dni_id = isnull ( ( select dni_id From ccDNIS Where dni_numero =  @DNIS and dni_status = 1 ), 0)
	
	--busca especialidad
	IF @inbound_id =0 and @dni_id >0
		select @Inbound_id=ED.Inbound_id from ccInboundDnis ED where ED.dni_id = @dni_id
	
	INSERT ccCallsIN ( cal_ANI, dni_id, cal_puerto, cal_Inicio, inbound_id, IVR_id )
	VALUES ( @ANI, @dni_id, @Pto, getdate(), @inbound_id, @IVR_id )

	select @cal_id = scope_identity()

	IF @inbound_id > 0 
	BEGIN
		insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
		select idwg, @cal_id, 0 as user_id, getdate() timestamp, 0 as tipo from ccRIACampEspWG wg		
		where wg.tipo = 0 and wg.IdCampEsp = @Inbound_id

	END

	IF @CALLDATA <> ''''	BEGIN -- Transfer Reminder
		set @CALLDATA=SUBSTRING(@CALLDATA,0,len(@CALLDATA)-2)
		insert into DataCallIn (CallId, Data, Description) 
		select @cal_id,value,''Dato ''+cast(id as varchar(max)) from dbo.[fn_RIASplitDelimited](@CALLDATA,''~'')
	END

	Select @cal_id as IDCall, @dni_id as IDdnis'
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
