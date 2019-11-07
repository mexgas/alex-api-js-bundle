CREATE procedure [dbo].[ccsp_getVersion]
@Module varchar(3) = null,
@Version int = 0 output
as
set nocount on
declare @Idioma bit
select @Idioma = cast(valor as bit) from ccSettings where setting_id = 27

if upper(isnull(@Module, '')) not in ('BD', 'ADM', 'AGT', 'ALL', 'BDF')
 begin
	select '-2' ID, case @Idioma when 0 then 'ERROR. Modulo no valido'
	else 'ERROR. Invalid Module' end [Description]
	return(0)
 end

declare @nVersion varchar(30)
select @nVersion = cast(valor as varchar(15)) from ccSettings where setting_id = 77

BEGIN TRY
	declare @version_1 varchar(15), @version_2 varchar(9), @version_3 varchar(6), @version_4 varchar(6)
	declare @Prueba table
	 (id int,
	  value nvarchar(100)
	 )
	 insert into @Prueba
		 select * from  fn_RIASplitDelimited (@nVersion,'.')

	 IF not exists (select value from @Prueba where id = 4) begin

		update ccsettings
		set valor = valor +'.00'
		where setting_Id = 77

		insert into @Prueba (value)
		values('00')
	 end

END TRY

BEGIN CATCH
	select '-1' ID, ERROR_MESSAGE() [Description]
	return(0)
END CATCH

if isnull(@Version, 0) = 0
 begin

	select @version_1 = value from @Prueba where id = 1
	select @version_2 = value from @Prueba where id = 2
	select @version_3 = value from @Prueba where id = 3
	select @version_4 = value from @Prueba where id = 4

	if upper(@Module) = 'ALL' or upper(@Module) = 'BDF' begin
		if  upper(@Module) = 'ALL'
			select @version_1 + '.' + @version_2 + '.' + @version_3+'.'+ @version_4
		else if  upper(@Module) = 'BDF'
			select @version_1 + '.' + @version_4

		return(0)
	end
	else
		select @version = cast(case upper(@Module) when 'BD' then @version_1
		when 'ADM' then @version_2 when 'AGT' then @version_3 end as int)
		select @version Version
		return(@version)

 end

--return

if upper(@Module) = 'BD' and (@Version <= cast(@version_1 as int) or (@Version - cast(@version_1 as int))>1)
 begin
	select '-3' ID, case @Idioma when 0
	then 'ERROR. Version no Valida para BD. Version Actual: ' + @version_1
	else 'ERROR. Invalid Version for BD. Current Version: ' + @version_1
	end [Description]
	return(0)
 end

if @Version <= cast(case upper(@Module) when 'BD' then @version_1
when 'ADM' then @version_2 else @version_3 end as int)
 begin
	select '-3' ID, case @Idioma when 0
	then 'ERROR. Version no Valida para ' + @Module + '. Version Actual: ' +
	 case upper(@Module) when 'BD' then @version_1 when 'ADM' then @version_2 else @version_3 end
	else 'ERROR. Invalid Version for ' + @Module + '. Current Version: ' +
	 case upper(@Module) when 'BD' then @version_1 when 'ADM' then @version_2 else @version_3 end
	end [Description]
	return(0)
 end



	select @version_1 = value from @Prueba where id = 1
	select  @version_2 =value from @Prueba where id = 2
	select @version_3 = value from @Prueba where id = 3
	select @version_4 = isnull(max(value),0) from @Prueba where id = 4


if upper(@Module) = 'BD' set @version_1 = @Version
else if upper(@Module) = 'ADM' set @version_2 = @Version
else if upper(@Module) = 'AGT' set @version_3 = @Version
else set @version_4 = @Version

set @nVersion = @version_1 + '.' + @version_2 + '.' + @version_3 + '.' + @version_4
update ccSettings set valor = @nVersion where setting_id = 77


if @@rowcount = 1
	select '0' ID, 'Actualizado a version: ' + @nVersion [Description]

else
	select '-4' ID, case @Idioma when 0
	then 'ERROR generado al actualizar a version ' + @nVersion
	else 'ERROR introduced when upgrading to version ' + @nVersion
	end [Description]

return (0)
set nocount off