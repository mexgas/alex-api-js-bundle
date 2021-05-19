CREATE PROCEDURE [dbo].[ccsp_getTemplates]@Action SMALLINT
	,@TemplateName VARCHAR(100) = ''
	,@TemplateID INT = 0
	,@Statuscheck SMALLINT = 1
	,@inbound_id VARCHAR(2000) = ''
	,@cam_id INT = 0
	,@IDvalue INT = 0
	,@flag SMALLINT = 0
	,@Status INT = 0
	,@Description varchar(125)= ''
	,@UserID int = 22
AS
SET NOCOUNT ON;

IF (@Action = 1) --Select Template list
BEGIN
SELECT convert(VARCHAR, max(a.DATE)) AS [date]
		,b.Template_id AS id
		,b.name
		,convert(INT, b.actityAgent) AS [active]
		,ISNULL(c.Cam_id,'') AS [cam_id]
		,ISNULL(convert(VARCHAR(10), max(d.inbound_id)),'') AS [inbound_id], isnull(Description, '') as [description]
		,convert(int,isnull(b.EditStatus,0)) as [EditStatus] ,
		case when max(action_id) = 6 then isnull((select top 1 convert(varchar(50),max(date),110) from Logger),'')
		else  ''
		end as [lastDbUpload]
	FROM Logger a
	inner JOIN Templates b ON a.Template_id = b.Template_id
	LEFT JOIN Campaign c ON a.Template_id = c.Template_id
	LEFT JOIN Inbound_Campaign d ON a.Template_id = d.Template_id
	WHERE b.STATUS = 1
	GROUP BY b.Template_id
		,b.name
		,b.actityAgent
		,c.Cam_id
		,b.Description
		,b.EditStatus
	order by b.name
END

IF (@Action = 2) --Insert Templates
BEGIN
	IF NOT EXISTS (
			SELECT name
			FROM Templates
			WHERE name = @TemplateName and status=1
			)
	BEGIN
		INSERT INTO dbo.Templates (
			name
			,STATUS
			,actityAgent
			,dateCreated
			,Description
			,EditStatus
			)
		VALUES (
			@TemplateName
			,1
			,0
			,GETDATE(),
			isnull(@Description,'')
			,1
			);

		SELECT @IDvalue = Template_id
		FROM dbo.Templates
		WHERE name = @TemplateName

		IF @cam_id <> 0
		BEGIN
			INSERT INTO dbo.Campaign (
				Cam_Id
				,Template_id
				)
			VALUES (
				@cam_id
				,@IDvalue
				);
		END

		IF (@inbound_id <> N'')
		BEGIN
			INSERT INTO dbo.Inbound_Campaign (
				Template_id
				,inbound_id
				)
			SELECT @IDvalue
				,Value
			FROM fn_SplitDelimited(@inbound_id, ',');
		END

		EXEC ccsp_Logger @action = 2
			,@action_id = 1
			,@template_id = @IDvalue
		,@user_id = @UserID


		SELECT @IDvalue AS [id], isnull(@Description,'') as[description], 
		@inbound_id as[inbound_id], @cam_id as [cam_id], @TemplateName as[name], 1 as[EditStatus]

	END
	ELSE
		SELECT - 1
END

IF (@Action = 3) --Logic Delete Template
BEGIN
	UPDATE Templates
	SET STATUS = 0
	WHERE Template_id = @TemplateID;

	DELETE
	FROM Campaign
	WHERE Template_id = @TemplateID;

	DELETE
	FROM Inbound_Campaign
	WHERE Template_id = @TemplateID

	EXEC ccsp_Logger @action = 2
		,@action_id = 2
		,@template_id = @TemplateID
		,@user_id = @UserID


	SELECT 1 AS response
END

IF (@Action = 4) --Clone Template
BEGIN
	SELECT @TemplateName = name
	FROM Templates
	WHERE Template_id = @Templateid

	DECLARE @interator INT = 1
	DECLARE @Name VARCHAR(255) = @TemplateName

	WHILE (@flag <> 1)
	BEGIN
		IF EXISTS (
				SELECT *
				FROM Templates
				WHERE name = @Name and status=1
				)
		BEGIN
			SET @interator = @interator + 1
			SET @Name = @TemplateName + CONVERT(VARCHAR(10), @interator)
		END
		ELSE
		BEGIN
			INSERT INTO dbo.Templates (
				name
				,STATUS
				,actityAgent
				,dateCreated, Description, EditStatus
				)
			VALUES (
				@Name
				,1
				,0
				,GETDATE(), '', 1
				);

			SET @flag = 1
		END
	END

	SELECT @IDvalue = Template_id
	FROM Templates
	WHERE name = @Name

	INSERT labelComponent (
		Template_id
		,i
		,x
		,y
		,h
		,w
		,TEXT,
		Name
		)
	SELECT @IDvalue
		,i
		,x
		,y
		,h
		,w
		,TEXT
		,name
	FROM labelComponent
	WHERE Template_id = @Templateid

	INSERT Components_per_Template (
		Template_id
		,Component_id
		,i
		,x
		,y
		,h
		,w
		,TEXT
		,STATUS, Name,Properties
		)
	SELECT @IDvalue
		,Component_id
		,i
		,x
		,y
		,h
		,w
		,TEXT
		,1, Name,Properties
	FROM Components_per_Template
	WHERE Template_id = @Templateid

	INSERT ComponentsRelation(
		Template_id
		,Component_id
		,i
		,x
		,y
		,h
		,w
		,Name
		)
	SELECT @IDvalue
		,Component_id
		,i
		,x
		,y
		,h
		,w
		, Name
	FROM componentsRelation
	WHERE Template_id = @Templateid

	INSERT ImageComponent (
		Template_id
		,i
		,x
		,y
		,h
		,w
		,Path,Name
		)
	SELECT @IDvalue
		,i
		,x
		,y
		,h
		,w
		,Path, Name
	FROM ImageComponent
	WHERE Template_id = @Templateid

	EXEC ccsp_Logger @action = 2
		,@action_id = 1
		,@template_id = @IDvalue
		,@user_id = @UserID


	SELECT @IDvalue AS id
END

IF (@Action = 5) --Set template Status
BEGIN
declare @tableName varchar(1000) = 'CS_Data_' + convert(VARCHAR(10), @Templateid)
	UPDATE Templates
	SET actityAgent = convert(BIT, @Status)
	WHERE Template_id = @TemplateID
	exec ccsp_CreateDynamicTable @Template_id=@TemplateID,@Name=@tableName
END

if(@Action = 6)
begin
	if exists(select Template_id from Templates where Template_id = @TemplateID)
	begin
	update Templates
	set Description = @Description, name = @TemplateName
	where Template_id = @TemplateID
	EXEC ccsp_Logger @action = 2
		,@action_id = 3
		,@template_id = @TemplateID
		,@user_id = @UserID
	end
	else begin
	select -1
	end
end