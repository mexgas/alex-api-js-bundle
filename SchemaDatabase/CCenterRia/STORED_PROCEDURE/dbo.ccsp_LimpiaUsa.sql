CREATE procedure [dbo].[ccsp_LimpiaUsa]
@tel varchar(20),
@Camp int = 0,
@calKey varchar(20) = ''
as
set nocount on
declare @lon tinyint

select @tel = dbo.limpia(@tel)
select @lon = len(@tel)

if @lon not in (7, 10, 11) and @tel <> '911'
 begin
	select 1 as res, @tel as tel --Longitud invalida
	return(0)
 end

if @tel = '911'
 begin
 	select 0 as res, @tel as tel -- ok
 	return(0)
 end

declare @ld varchar(4)
select @ld = valor from ccsettings where setting_id = 17

declare @len tinyint, @plans tinyint, @hl tinyint, @ht tinyint, @fl tinyint, @ft tinyint
declare @plan varchar(15), @tel10 varchar(10)
select @plan = valor from ccSettings where setting_id = 149
select @plans = COUNT(*) from dbo.fn_RIASplitDelimited(@plan,'|')
if @plans = 4
begin
	select 
	 @hl = case when id = 1 then cast(value as tinyint) else @hl end,
	 @ht = case when id = 2 then cast(value as tinyint) else @ht end,
	 @fl = case when id = 3 then cast(value as tinyint) else @fl end,
	 @ft = case when id = 4 then cast(value as tinyint) else @ft end from dbo.fn_RIASplitDelimited(@plan,'|')
	 print @hl
end
else if @plans = 2
begin
	select 
	 @hl = case when id = 1 then cast(value as tinyint) else @hl end,
	 @ft = case when id = 2 then cast(value as tinyint) else @ft end from dbo.fn_RIASplitDelimited(@plan,'|')
	 select @ht = @hl, @fl = @ft
end
select @tel10 = RIGHT(@ld + @tel, 10)
if SUBSTRING(@tel10, 1, LEN(@ld)) = @ld
begin --HNPA
	set @len = @hl
	if @hl <> @ht and (select COUNT(*) from ccNPALocalPrefixes) > 0 and not exists(select * from ccNPALocalPrefixes where NPA+NXX = SUBSTRING(@tel10, 1, 6))
		set @len = @ht
end
else --FNPA
begin
	set @len = @ft
	if @fl <> @ft and (select COUNT(*) from ccNPALocalPrefixes) > 0 and exists(select * from ccNPALocalPrefixes where NPA+NXX = SUBSTRING(@tel10, 1, 6))
		set @len = @fl
end

select @tel = case @len when 7 then SUBSTRING(@tel10, 4, 7) when 10 then @tel10 when 11 then '1' + @tel10 end

-- lista negra
if (select dbo.ValidateBlackListPhone(@tel,@Camp,@calKey))=1 begin
	select 4 as res, @tel as tel --blackList
	return(0)
end	

select 0 as res, @tel as tel

set nocount off