CREATE PROCEDURE [dbo].[ccsp_GalateaAdminWorkgroups] 
	@Option AS SMALLINT,
	@AdminId AS INT = 0,
	@WorkgroupId AS INT = 0,
	@idArea AS INT = NULL,
	@Descripcion AS varchar(40) = null
AS
declare @users as int
declare @camps as int

BEGIN
	IF @Option = 1
	BEGIN 
		if exists (select * from ccUsers_Roles where User_id = @AdminId and Rol_id = (select Rol_id from ccRoles where Level = 7))
		BEGIN
			select  CAST(wg.IDWG as int)  as Id, wg.WGName Name, wg.StatusWorkGroup Status
			from ccRIACat_WorkGroup wg
			where StatusWorkGroup = 1
		END

		ELSE
		BEGIN
			SELECT @AdminId = ISNULL(@AdminId, 0)			
		
			SELECT CAST(wg.IDWG AS INT) AS Id, WGName Name, StatusWorkGroup Status  FROM ccRIAWorkGroupUsers wgu
			JOIN  ccRIACat_WorkGroup wg ON wg.IDWG = wgu.IDWG
			WHERE User_id = @AdminId
		END			
	END
	IF @Option = 2
	BEGIN 
		SELECT @WorkgroupId = ISNULL(@WorkgroupId, 0)			
		
		SELECT CAST(wg.IDWG AS INT) AS Id,
				WGName Name,
				StatusWorkGroup Status  
		FROM 
		ccRIACat_WorkGroup wg 
		WHERE IDWG = @WorkgroupId
					
	END

	IF @Option = 3 --Lista de wg 
	BEGIN 
	
		SELECT cast(IDWG as int) Id, WGName as Name
		FROM ccRIACat_WorkGroup 
					
	END

	IF @Option = 4 --Lista de wg por area
	BEGIN 
		SELECT @idArea = ISNULL(@idArea, 0)	

		SELECT CAST(IDWG as int) IDWG 
		FROM 
		ccRIAAreaWorkGroup
		WHERE IDArea = @idArea
					
	END

	IF @Option = 5 --Delete WG
	BEGIN
		--revisar tablas con relacion de grupos de trabajo
		SELECT @WorkgroupId = ISNULL(@WorkgroupId, 0)
		if  @WorkgroupId = 0
		begin
			SELECT 0
			return (0)
		end

		SELECT @users=count(IdCampEsp) 
		FROM ccRIACampEspWG 
		where IDWG= @WorkgroupId

		SELECT @users=count(User_id) 
		FROM ccRIAWorkGroupUsers 
		where IDWG= @WorkgroupId

		if @users>0 or @camps >0 
		begin
			select -1
		end
		else
		begin
			Update ccRIACat_WorkGroup set StatusWorkGroup = 0 where IDWG =@WorkgroupId 
			select 1
		end
		

	END

	if @option = 6 -- Verifica si existe el grupo
		 begin
		  	select @WorkgroupId = case when exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
			 then 1 else 0 end
		 
		 	if isnull(@IDArea,0)=0
			 begin
				select @WorkgroupId
				return(0)
			 end

		 	if @WorkgroupId=1
			 begin
			 set @WorkgroupId = -1
				select @WorkgroupId
				return(0)
			 end

			insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
			if @@rowcount = 1
				select @WorkgroupId = scope_identity()

			insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@WorkgroupId, @IDArea)
			select @WorkgroupId
			return(0)
		 end

END