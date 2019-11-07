CREATE procedure dbo.ccsp_RIAChangePriority
@IDWG varchar(255),
@User_ID varchar(255) = null, 
@campEspID varchar(255),
@priority varchar(255),
@InOut varchar(255)
as
set nocount on
Declare @Tabla varchar(16), @campo varchar(10), @SQL varchar(4000)
Declare @workgroups as table (IDWG_temp int)
select @Tabla = case @InOut when 1 then 'ccCampsAgente' else 'ccInboundAgentes' end,
 @campo = case @InOut when 1 then 'cam_id' else 'inbound_id' end

if isnull(@User_ID,'') = ''-- Update Priority
 begin
	Declare @ccRIAWorkGroupUsers Table (User_id smallint)
	insert into @ccRIAWorkGroupUsers
	select A.User_id from ccRIAWorkGroupUsers A join ccUsers B 
	 on A.User_id = B.User_id and B.TipoUser_id < 2 where IDWG = @IDWG

	UPDATE ccRIACampEspWG set priority = @priority 
	where IDWG = @IDWG and IdCampEsp = @campEspID and Tipo = @InOut

	if @InOut = 1
	 begin
		UPDATE ccCampsAgente set prioridad = 
		 case @priority when 0 then prioridad else @priority end
		where cam_id = @campEspID and user_id 
		in(select User_id from @ccRIAWorkGroupUsers)
	 end

	else
	 begin
		UPDATE ccInboundAgentes set prioridad = case @priority when 0 then prioridad else @priority end
		where Inbound_id = @campEspID and user_id in(select User_id from @ccRIAWorkGroupUsers)
	 end
	
	insert into @workgroups 
	select distinct IDWG from ccRIAWorkGroupUsers where user_id in (
	select user_id from ccRIAWorkGroupUsers where IDWG = @IDWG)
	 
 end
else
 begin
	set @SQL = 'UPDATE ' + @Tabla + ' set prioridad = ' +
	case @priority when '0' then 'prioridad' else @priority end + '
	where user_id in (select cast(value as int) from dbo.fn_RIASplitDelimited(''' + @User_ID + ''', '',''))  and ' + @campo + ' = ' + @campEspID
	exec(@SQL)

	insert into @workgroups select IDWG from ccRIAWorkGroupUsers where user_id in (select value from dbo.fn_RIASplitDelimited(@User_ID,','))
 end

while exists (select IDWG_temp from @workgroups)
 begin
	select top 1 @IDWG = IDWG_temp from @workgroups order by IDWG_temp
	exec ccsp_RIACalcula_WGPriority @IDWG, @campEspID, @InOut
	delete @workgroups where IDWG_temp = @IDWG
 	exec(@SQL)
 end

return(0)
set nocount off