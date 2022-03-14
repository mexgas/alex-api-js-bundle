CREATE PROCEDURE [dbo].[ccsp_GalateaAdminBlacklistCatalog]
@BLID smallint,
@name varchar(50),
@Type tinyint
AS
set nocount on
if @Type=1-- Read black lists
 begin
	Select idtipolista AS ID, tipolista AS TIPO , DateCreation as DateCreation 
	from cctiposlistanegra where idtipolista = case isnull(@BLID,0) when 0 then idtipolista else @BLID end
	and Status= 1 order by 2
	return(0)
 end

If @Type=2 --Create black list
 begin
 DECLARE @newBlackListId INT= -1 --Nombre en Uso
	if not exists(select tipolista from cctiposlistanegra where tipolista=@name)
		begin
			insert into cctiposlistanegra (tipolista,DateCreation) values(@name, SYSDATETIME())
			SELECT @newBlackListId = SCOPE_IDENTITY() 
		end
	else if exists(select tipolista from cctiposlistanegra where tipolista=@name and Status = 0)
		begin
			declare @idBL int = (select idtipolista from cctiposlistanegra where tipolista=@name and Status = 0)
			update cctiposlistanegra set Status = 1, DateCreation =  SYSDATETIME() where idtipolista = @idBL
			select @newBlackListId = @idBL
		end 
	SELECT @newBlackListId as ReturnValue
	return(0)
 end

if @Type=4-- update 
 begin
 if not exists(select tipolista from cctiposlistanegra where tipolista=@name)
		begin
			update cctiposlistanegra set tipolista=@name where idtipolista= @BLID
			SELECT 200 as ReturnValue
		end
		else
			SELECT -1 as ReturnValue --Nombre en uso
 return(0)
 end

if @Type=5 --obtiene el id de lista llamada defaultList/General
	begin
		declare @dnclid as int
		set @dnclid = 0;

		select @dnclid = idtipolista from cctiposlistanegra where Tipolista = 'defaultList/General'
		select @dnclid
		return(0)
	end

set nocount off