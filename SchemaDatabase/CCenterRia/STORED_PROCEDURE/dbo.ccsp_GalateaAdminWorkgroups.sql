CREATE PROCEDURE [dbo].[ccsp_GalateaAdminWorkgroups] 
	@Option AS SMALLINT,
	@AdminId AS INT = 0,
	@WorkgroupId AS INT = 0,
	@idArea AS INT = NULL,
	@Descripcion AS varchar(40) = null,
	@groupList as varchar (MAX) = NULL

AS
declare @users as int
declare @camps as int
declare @sql as varchar(max)

BEGIN
	IF @Option = 1
	BEGIN 
		SELECT @AdminId = ISNULL(@AdminId, 0)			
		
		SELECT CAST(wg.IDWG AS INT) AS Id, WGName Name, StatusWorkGroup Status  FROM ccRIAWorkGroupUsers wgu
		JOIN  ccRIACat_WorkGroup wg ON wg.IDWG = wgu.IDWG
		WHERE User_id = @AdminId
					
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
		WHERE StatusWorkGroup =1
					
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
		IF OBJECT_ID('tempdb..#WGDelete') IS NOT NULL DROP TABLE #WGDelete;
		SELECT value As IDwg into #WGDelete FROM fn_RIASplitDelimited(@groupList, ',')

		SELECT @camps=count(IdCampEsp) 
		FROM ccRIACampEspWG 
		where IDWG in  (select IDwg from #WGDelete)

		SELECT @users=count(User_id) 
		FROM ccRIAWorkGroupUsers 
		where IDWG in (select IDwg from #WGDelete)

		if @users>0 or @camps >0 
		begin
			select -1
		end
		else
		begin
			Delete from ccRIAAreaWorkGroup where IDWG in (select IDwg from #WGDelete)
			Update ccRIACat_WorkGroup set StatusWorkGroup = 0 where IDWG in (select IDwg from #WGDelete)
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