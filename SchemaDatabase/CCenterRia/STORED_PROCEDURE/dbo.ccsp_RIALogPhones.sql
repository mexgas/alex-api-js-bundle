CREATE procedure [dbo].[ccsp_RIALogPhones]
@load_id int,
@Type smallint,
@GenCSV bit = 1-- 0:100 / 1:todos
as
set nocount on

declare @CaseType varchar(2000), @sql varchar(4000), @nType char(5)
select @CaseType = '', @nType = right('0000'+cast(@Type as varchar(5)), 5)

if @nType like '%____1%'
	select @CaseType = @CaseType + ' or isnull(telefono, '''') = '''' and tipoMov = 0 '

if @nType like '%___1_%'
	select @CaseType = @CaseType + ' or isnull(telefono, '''') <> '''' and tipoMov = 0 '

if @nType like '%__1__%'
	select @CaseType = @CaseType + ' or isnull(telefono, '''') = '''' and tipoMov = 1 '

if @nType like '%_1___%'
	select @CaseType = @CaseType + ' or isnull(telefono, '''') <> '''' and tipoMov = 1 '

if @nType like '%1____%'
	select @CaseType = @CaseType + ' or isnull(telefono, '''') = '''' and tipoMov = 2 '

if @CaseType = '' and @nType <> 0
	return(0)

set @sql = 'select ' + case @GenCSV when 0 then 'top 100 ' else '' end 
	+ 'load_id, cal_key, telefono, tipoMov, motivo 
	from ccRIALogPhones where load_id = ' 
	+ cast(@load_id as varchar(10)) + 
	case when @CaseType <> '' then ' and (' + substring(@CaseType, 5, len(@CaseType)) + ')' else '' end

exec(@sql)
return(0)

set nocount off