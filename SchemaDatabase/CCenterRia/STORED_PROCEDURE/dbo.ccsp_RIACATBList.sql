CREATE PROCEDURE [dbo].[ccsp_RIACATBList]
@BLID smallint,
@name varchar(50),
@Type tinyint 
AS
set nocount on
if @Type=1
 begin
	Select idtipolista AS ID, tipolista AS TIPO 
	from cctiposlistanegra where idtipolista = case isnull(@BLID,0) when 0 then idtipolista else @BLID end
	and Status= 1 order by 2
	return(0)
 end

If @Type=2
 begin
	if exists(select tipolista from cctiposlistanegra where tipolista=@name)
		select 1, 'Nombre en Uso'
	else	
		insert into cctiposlistanegra (tipolista,DateCreation) values(@name, SYSDATETIME())
	return(0)
 end

if @Type=4
 begin
	update cctiposlistanegra set tipolista=@name where idtipolista= @BLID
 end

if @Type=5
	begin
		declare @dnclid as int
		set @dnclid = 0;

		select @dnclid = idtipolista from cctiposlistanegra where Tipolista = 'defaultList/General'
		select @dnclid
		return(0)
		end
set nocount off