USE CCenterRIA
GO
ALTER PROCEDURE [dbo].[ccsp_GalateaAdminDispositionRelations]
@command INT,
@type TINYINT = NULL, --0=In, 1=Out
@cam_id SMALLINT = NULL,
@califIdLst VARCHAR(8000) = NULL,
@user_id SMALLINT = NULL,
@operationId INT = NULL
AS
set nocount on
declare @sql as nvarchar(max)

If @command = 1
begin
	select 
		cast (0 as int) [type], 
		i.inbound_id as cam_id, 
		c.calif_id 
	from ccInbound i inner join ccCalifCamp c on i.inbound_id = c.cam_id and c.tipo = 0
	inner join ccTipoCalif t on c.calif_id = t.calif_id
	UNION
	select 
		cast (1 as int) [type], 
		o.cam_id, 
		c.calif_id 
	from ccCamps o inner join ccCalifCamp c on o.cam_id = c.cam_id and c.tipo = 1
	inner join ccTipoCalifOUT co on c.calif_id = co.calif_id
	order by [type], cam_id, calif_id
end
IF @command=2  -- Assign disposition to inbound or outbound campaign
 BEGIN 
	IF @Type=0 
	begin	
		set @sql = 'declare @NotAssigned table(NotAssigned int); 
		declare @Assigned table(Assigned int);

		insert into @NotAssigned (NotAssigned)
		select calif_id from ccTipoCalif where CanReprogram=1 and calif_id in (' + @califIdLst + ')
		and exists(select inbound_id from ccInbound where cam_id is null and Inbound_id= ' + cast(@cam_id as varchar(10)) + ')

		insert into ccCalifCamp(calif_id,cam_id,tipo) 
		select f.calif_id, e.inbound_id, 0 
		from ccInbound e, cctipoCalif f 
		where f.Calif_Status=1 and f.calif_id in (' + @califIdLst + ') and f.calif_id not in (select NotAssigned from @NotAssigned)
		and Inbound_id = ' + cast(@cam_id as varchar(10)) + '
		and not exists(
			select a.calif_id,c.inbound_id,0 from cctipoCalif a
			join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 0
			join ccInbound c on c.inbound_id = b.cam_id
			where f.calif_id = a.calif_id and e.inbound_id = c.inbound_id
			and c.Inbound_id = ' + cast(@cam_id as varchar(10)) + ')

		insert into @Assigned (Assigned)
		select calif_id from ccTipoCalif where calif_id in (' + @califIdLst + ') and calif_id not in (select NotAssigned from @NotAssigned)

		declare @NotAssignedStr varchar(8000), @AssignedStr varchar(8000)
		SELECT @AssignedStr = COALESCE(@AssignedStr + '','', '''') + cast(Assigned as varchar(10)) from @Assigned
		select @NotAssignedStr = coalesce(@NotAssignedStr + '','', '''') + cast(NotAssigned as varchar(10)) from @NotAssigned

		select @AssignedStr [Assigned], @NotAssignedStr [NotAssigned]'
		EXECUTE sp_executesql @sql
	END
	ELSE
	BEGIN
		SET @sql = 'insert into ccCalifCamp(calif_id,cam_id,tipo) 
		select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalifOUT f where 
		f.CalifOut_Status=1 and f.calif_id in (' + @califIdLst + ') and cam_id = ' + CAST(@cam_id AS VARCHAR(10)) + '
		and not exists(
		select a.calif_id,c.cam_id, 1 from cctipoCalifOUT a
		join ccCalifCamp b on a.calif_id = b.calif_id and tipo = 1
		join ccCamps c on c.cam_id = b.cam_id
		where f.calif_id = a.calif_id and e.cam_id = c.cam_id
		and b.cam_id = ' + CAST(@cam_id AS VARCHAR(10)) + ')'
		EXECUTE sp_executesql @sql
		UPDATE ccCamps SET keepDial=dbo.fn_keepDial_Camps(@cam_id) WHERE cam_id=@cam_id	
		RETURN(0)
	END
 END
 IF @command=3 -- Unassign disposition to inbound or outbound
 BEGIN
	DELETE ccCalifCamp WHERE cam_id=@cam_id AND tipo=@type AND calif_id IN (SELECT value FROM dbo.fn_RIASplitDelimited(@califIdLst, ','))
	UPDATE ccCamps SET keepDial=dbo.fn_keepDial_Camps(@cam_id) WHERE cam_id=@cam_id
	RETURN(0)
 END
 IF @command=4 
 BEGIN
	IF(@type = 0) 
	BEGIN
		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
		SELECT 
			(SELECT AreaName FROM ccRIACat_Areas c INNER JOIN ccInbound i ON c.IDArea = i.IDArea WHERE Inbound_id = @cam_id),
			GETDATE(),
			(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
			68,
			7,
			'',
			Description,
			(SELECT descripcion FROM ccInbound WHERE Inbound_id = @cam_id)
			FROM ccTipoCalif 
			WHERE calif_id IN (SELECT value FROM dbo.fn_RIASplitDelimited(@califIdLst, ','))
	END
 END
 IF @command=5
 BEGIN
	IF(@type = 0) 
	BEGIN
		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
		SELECT 
			(SELECT AreaName FROM ccRIACat_Areas c INNER JOIN ccInbound i ON c.IDArea = i.IDArea WHERE Inbound_id = @cam_id),
			GETDATE(),
			(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
			69,
			7,
			'',
			Description,
			(SELECT descripcion FROM ccInbound WHERE Inbound_id = @cam_id)
			FROM ccTipoCalif 
			WHERE calif_id IN (SELECT value FROM dbo.fn_RIASplitDelimited(@califIdLst, ','))
	END
 END
 IF @command = 6 -- Assign dispositions to inbound or outbound AI campaign
 BEGIN
 	if @Type=0 
	begin	
		set @sql = 'declare @NotAssigned table(NotAssigned int); 
		declare @Assigned table(Assigned int);

		insert into @NotAssigned (NotAssigned)
		SELECT calif_id 
		FROM cctipoCalif_IA MAIN
		WHERE MAIN.calif_id IN ('+ @califIdLst+ ')
		AND EXISTS (
			SELECT 1 
			FROM ccInbound I
			WHERE I.Inbound_id = ' + cast(@cam_id as varchar(10)) + '
			AND (
				------------------------------------------------------------
				-- GRUPO 1: Validación de Reprogramación / Callback
				-- Si pide reprogramar, DEBE tener cam_id.
				------------------------------------------------------------
				(
				   (MAIN.CanReprogram = 1 OR MAIN.autoCallback = 1) 
				   AND 
				   (I.cam_id IS NULL OR I.cam_id = 0)
				)

				OR 
				------------------------------------------------------------
				-- GRUPO 2: Validación de Transferencia (AplTransfer)
				-- Si pide transferir, DEBE tener los IDs configurados.
				------------------------------------------------------------
				(
					MAIN.AplTransfer = 1 
					AND (
						-- Si Opcion es 1, ERROR si falta idForNonComprehension
						(MAIN.TransferOpcion = 1 
						AND (I.idForNonComprehension IS NULL OR I.idForNonComprehension = 0))
                
						OR
                
						-- Si Opcion es 2, ERROR si falta idForSuccessfulTransaction
						(MAIN.TransferOpcion = 2 AND 
						(I.idForSuccessfulTransaction IS NULL OR I.idForSuccessfulTransaction = 0))
					)
				)
			)
		)

		insert into ccCalifCampIA(calif_id,cam_id,tipo) 
		select f.calif_id, e.inbound_id, 0 
		from ccInbound e, cctipoCalif_IA f 
		where f.Cali_StatusIA=1 and f.calif_id in (' + @califIdLst + ') and f.calif_id not in (select NotAssigned from @NotAssigned)
		and Inbound_id = ' + cast(@cam_id as varchar(10)) + '
		and not exists(
			select a.calif_id,c.inbound_id,0 from cctipoCalif a
			join ccCalifCampIA b on a.calif_id = b.calif_id and tipo = 0
			join ccInbound c on c.inbound_id = b.cam_id
			where f.calif_id = a.calif_id and e.inbound_id = c.inbound_id
			and c.Inbound_id = ' + cast(@cam_id as varchar(10)) + ')

		insert into @Assigned (Assigned)
		select calif_id from cctipoCalif_IA where calif_id in (' + @califIdLst + ') and calif_id not in (select NotAssigned from @NotAssigned)

		declare @NotAssignedStr varchar(8000), @AssignedStr varchar(8000)
		SELECT @AssignedStr = COALESCE(@AssignedStr + '','', '''') + cast(Assigned as varchar(10)) from @Assigned
		select @NotAssignedStr = coalesce(@NotAssignedStr + '','', '''') + cast(NotAssigned as varchar(10)) from @NotAssigned

		select @AssignedStr [Assigned], @NotAssignedStr [NotAssigned], cast(1 as bit) as IsAICamp'
		execute sp_executesql @sql
		return(0)
	end
	else
	begin
		set @sql = 'insert into ccCalifCampIA(calif_id,cam_id,tipo) 
		select f.calif_id, e.cam_id, 1 from ccCamps e, cctipoCalif_IA f where 
		f.Cali_StatusIA=1 and f.calif_id in (' + @califIdLst + ') and cam_id = ' + cast(@cam_id as varchar(10)) + '
		and not exists(
		select a.calif_id,c.cam_id, 1 from cctipoCalif_IA a
		join ccCalifCampIA b on a.calif_id = b.calif_id and tipo = 1
		join ccCamps c on c.cam_id = b.cam_id
		where f.calif_id = a.calif_id and e.cam_id = c.cam_id
		and b.cam_id = ' + cast(@cam_id as varchar(10)) + ')'
		execute sp_executesql @sql
		return(0)
	end
 END
 IF @command = 7 -- Unassign dispositions to inbound or outbound AI campaign
 BEGIN 
	delete ccCalifCampIA WHERE cam_id=@cam_id and tipo=@type and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
	return(0)
 END
 If @command = 8
begin
	select 
		cast (0 as int) [type], 
		i.inbound_id as cam_id, 
		c.calif_id 
	from ccInbound i inner join dbo.ccCalifCampIA AS c on i.inbound_id = c.cam_id and c.tipo = 0
	inner join dbo.cctipoCalif_IA AS t on c.calif_id = t.calif_id
	UNION
	select 
		cast (1 as int) [type], 
		o.cam_id, 
		c.calif_id 
	from ccCamps o inner join ccCalifCampIA c on o.cam_id = c.cam_id and c.tipo = 1
	inner join cctipoCalif_IA co on c.calif_id = co.calif_id
	order by [type], cam_id, calif_id
END
IF @command = 9 -- Registry AI dispositions log to assign/unassign
BEGIN
	IF(@type = 0)
	BEGIN 
		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
		SELECT 
			(select AreaName from ccRIACat_Areas c inner join ccInbound i on c.IDArea = i.IDArea where Inbound_id = @cam_id),
			getDate(),
			(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
			@operationId,
			7,
			'',
			Name_cal,
			(select descripcion from ccInbound where Inbound_id = @cam_id)
			from cctipoCalif_IA 
			where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
	END
	ELSE
    BEGIN
		INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
		SELECT 
			(select AreaName from dbo.ccRIACat_Areas AS crca inner join dbo.ccCamps AS cc  on crca.IDArea = cc.IDArea where cc.cam_id = @cam_id),
			getDate(),
			(SELECT [Login] FROM ccUsers WHERE User_id = @user_id),
			@operationId,
			7,
			'',
			Name_cal,
			(select cam_descripcion from dbo.ccCamps  where cam_id = @cam_id)
			from cctipoCalif_IA 
			where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, ','))
	end
END


set nocount OFF