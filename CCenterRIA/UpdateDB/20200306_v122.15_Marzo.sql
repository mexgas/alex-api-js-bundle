/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/03/06
Description:

Database: CCenterRia
Required version: 122.14

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 122 --**********actualizar a 122 sin fix
SET @versionfix = 15
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 14
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'CW-3933 - Drop Fn ValidateBlackListPhoneByList '
		set @sql='if exists (select * from sys.objects where object_id = OBJECT_ID(N''ValidateBlackListPhoneByList'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
begin
    Drop function ValidateBlackListPhoneByList
end'
		EXEC(@sql)

		set @process = 'CW-3933 - Drop Fn GetDataPhone'
		set @sql='if exists (select * from sys.objects where object_id = OBJECT_ID(N''GetDataPhone'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
begin
    Drop function GetDataPhone
end'
		EXEC(@sql)

		set @process = 'CW-3533 Drop if exists ccspGalateaGetccCampsData'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccspGalateaGetccCampsData'')
	    begin
	        DROP PROCEDURE ccspGalateaGetccCampsData;
	    end'
	    exec (@sql)

	    SET @process = 'CW-3533 ALTER TABLE ADD COLUMN holdCall in ccCamps'
		SET @Sql = 'if not exists (select * from sys.columns where name = N''holdCall'' and Object_ID = Object_ID(N''ccCamps''))
		    begin
		    	ALTER TABLE ccCamps ADD holdCall BIT NOT NULL DEFAULT(1)
		    end'		
		EXEC(@sql)

		set @process = 'CW-3933 - CREATE Fn ValidateBlackListPhoneByList'
		set @sql='CREATE FUNCTION [dbo].[ValidateBlackListPhoneByList] (@tel VARCHAR(32), @calKey VARCHAR(20),@blackListId varchar(100))
RETURNS BIT
AS
BEGIN
	DECLARE @isBlackPhone BIT
	--PARA LA VALIDACION DE LISTAS NEGRAS CON HASH
	DECLARE @hasTelefono BIGINT

	if @tel is null or @tel =''''
		return 1 --No tiene valor

	SELECT @hasTelefono = dbo.hashPhone(@tel)	

	DECLARE @hasCalKey BIGINT

	IF @calKey IS NOT NULL OR @calKey <> ''''
		SELECT @hasCalKey = dbo.hashList(@calKey)

	SET @isBlackPhone = 0

	IF EXISTS (
			SELECT a1.idtipolista
			FROM cclistanegra a1
			INNER JOIN 
			dbo.fn_RIASplitDelimited(@blackListId,'','') b ON a1.idtipolista = b.Value						
			WHERE a1.Hashtel = @hasTelefono AND (a1.HashKey IS NULL OR a1.HashKey = @hasCalKey)
			)
		SET @isBlackPhone = 1

	RETURN @isBlackPhone
END
'
		EXEC(@sql)

		set @process = 'CW-3933 - CREATE Fn GetDataPhone '
		set @sql='CREATE FUNCTION [dbo].[GetDataPhone] (@tel VARCHAR(32), @pais TINYINT = 1, @cldLocal VARCHAR(7) = ''55'')
RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE @ld VARCHAR(7),@serie varchar(7),@rank varchar(7)
	DECLARE @lon TINYINT
	DECLARE @result TINYINT
	DECLARE @mod VARCHAR(10)
	DECLARE @Cadena VARCHAR(32)
	DECLARE @isLocal BIT
	declare @rankNum int

	declare @region varchar(20), @localidad varchar(20) 
	select @region='''',@localidad=''''
	SELECT @tel = dbo.limpia(@tel)

	if @tel='''' begin
		return ''''
	end

	IF @pais = 1
	BEGIN --Empieza Mexico
		SELECT @lon = len(@tel), @mod = ''''

		IF @lon < 10
		BEGIN
			RETURN ''E_'' + @tel
		END

		SELECT @tel = right(@tel, 10)

		SELECT @lon = len(@tel)

		IF @lon = 10
		BEGIN
			IF EXISTS (
					SELECT TOP 1 cld
					FROM series NOLOCK
					WHERE cld = left(@tel, 3)
					)
				SELECT @ld = left(@tel, 3)
			ELSE IF EXISTS (
					SELECT TOP 1 cld
					FROM series NOLOCK
					WHERE cld = left(@tel, 2)
					)
				SELECT @ld = left(@tel, 2)
			ELSE
				RETURN ''E_'' + @tel

			set @serie= substring(@tel, len(@ld) + 1, 6 - len(@ld))
			set @rank= right(@tel, 4)
			set @rankNum=cast(@rank as int)

			SELECT TOP 1 @mod = modalidad,@region = estado, @localidad = municipio
			FROM series NOLOCK
			WHERE cld = @ld AND serie = @serie AND @rankNum BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

			IF @mod NOT IN (''FIJO'', ''MPP'', ''CPP'')
			BEGIN
				RETURN ''E_'' + @tel
			END

			DECLARE @specialDialPlan TINYINT

			SELECT @specialDialPlan = valor
			FROM ccsettings WITH (NOLOCK)
			WHERE setting_id = 195


			SET @isLocal = 0

			IF @cldLocal = @ld or EXISTS (
					SELECT *
					FROM ccRiaArecode
					WHERE area = @ld
					)					
			BEGIN
				SET @isLocal = 1
			END		
			
			
			IF @specialDialPlan = 2
			BEGIN --Number 10 digits
				RETURN @ld+''|''+@serie+''|''+@rank+''|''+ @tel+''|''+@region+''|''+@localidad+''|''+case @mod when ''CPP'' then ''1'' else ''0'' end +''|''+case @isLocal when 1 then ''1'' else ''0'' end
			END	

			IF @specialDialPlan = 1
			BEGIN
				--Number local 10 digit
				--Number LD 12 digit
				--Number Cell 13 digit
				SELECT @tel = CASE WHEN @mod IN (''FIJO'', ''MPP'') THEN CASE WHEN @isLocal = 1 THEN @tel ELSE ''01'' + @tel END WHEN @mod = ''CPP'' THEN --Local y LD
								CASE WHEN @isLocal = 1 THEN ''044'' + @tel ELSE ''045'' + @tel END END --Celular
			END
			ELSE
			BEGIN
				--Number local 7 o 8 digit
				--Number LD 12 digit
				--Number Cell 13 digit
				SELECT @tel = CASE WHEN @mod IN (''FIJO'', ''MPP'') THEN CASE WHEN @isLocal = 1 THEN right(@tel, 10 - len(@ld)) ELSE ''01'' + @tel END WHEN @mod = ''CPP'' THEN --Local y LD
								CASE WHEN @isLocal = 1 THEN ''044'' + @tel ELSE ''045'' + @tel END END --Celular
			END
		END
		ELSE IF @lon > 0
		BEGIN
			SET @tel = ''E_'' + @tel
		END

		RETURN @ld+''|''+@serie+''|''+@rank+''|''+ @tel+''|''+@region+''|''+@localidad+''|''+case @mod when ''CPP'' then ''1'' else ''0'' end +''|''+case @isLocal when 1 then ''1'' else ''0'' end
	END --Termina Mexico
				
	Return ''''
END
'
		EXEC(@sql)

		set @process = 'CW-3533 Create SP ccspGalateaGetccCampsData'
		set @sql = 'CREATE PROCEDURE [dbo].[ccspGalateaGetccCampsData]
			@action tinyint,
			@cam_id int
			AS BEGIN
			    IF @action = 1  -- Check if DTMF function is enabled (type int) 
			    BEGIN
					select isnull(funcEspDtmf, 0) as FuncEspDtmf from ccCamps where cam_id = @cam_id	
			    END
			    IF @action = 2  -- Check if hold is enabled (type bit) 
			    BEGIN
					select holdCall from ccCamps where cam_id = @cam_id	
			    END
			END'
	    exec (@sql)

		set @process = 'CW-3933 - Alter Fn fnGetTimeZone'
		set @sql='ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
RETURNS int
AS
 BEGIN
  declare @lada as varchar(5)
  declare @timeZone as int
  declare @ld as varchar(5)
  declare @location as varchar(500)
  declare @locality as varchar(255)
  declare @country as tinyInt
  declare @pais varchar(2)
  declare @serie varchar(10)
  declare @rank int
  declare @len int

  select @lada = valor from ccsettings with(nolock) where setting_id = 17
  select @country = valor, @pais = valor from ccSettings with(nolock) where setting_id = 104

  select @ld = ''''
  select @location = ''''
  set @timeZone=0
	
  if @phone='''' begin
    return 0;
  end

  set @len=len(@phone)

    if @country = 1 begin

		if @len<10 and @len + len(@lada)=10 begin
			set @phone=@lada+@phone
			set @len=len(@phone)
		end      

      if @len = 10
        begin
          if(exists(select top 1 cld from series with(index(IX_CLD),nolock) where cld=left(@phone,2)))
            select @ld =  left(@phone,2)
          else if(exists(select top 1 cld from series with(index(IX_CLD),nolock) where cld=left(@phone,3)))
            select @ld = left(@phone,3)
        end    	

      if @ld <> ''''
        begin

			set @serie=substring(@phone, len(@ld) + 1, 6 - len(@ld))
		    set @rank=right(@phone, 4)

          select top 1 @location = estado, @locality = MUNICIPIO from series 
		  where cld = @ld and serie = @serie and @rank between [NUMERACION INICIAL] and [NUMERACION FINAL]

          if @location is null or not exists(select  locality from ccTimeZoneArea (nolock) where id_country=@country and area=@ld and locality=@locality)
            set @locality = null					         
        end
	else begin
		set @ld=@lada
	end

		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
          where id_country = @country and 
          area = @ld and 
		  ( @location is null or location=@location)

		return isNull(@timeZone,0)
    end

   else  if @country = 2 begin
      declare @telTemp varchar(15)
      set @telTemp = @phone
      select @phone = dbo.Completa(@phone, @pais, @lada)
      if left(@phone,1) = ''E'' begin set @phone = @telTemp end
      select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaArgDetail where
        ( len(@phone) = 6 and @lada = area and len(area) = 4 )
        or
        ( len(@phone) = 7 and @lada = area and len(area) = 3 )
        or
        ( len(@phone) = 8 and @lada = area and len(area) = 2 )
        or
        ( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
        or
        ( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
        or
        ( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
        or
        ( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
        or
        ( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
        or
        ( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 )
        if @timeZone is null
          begin
            select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
            where id_country = @country and (
              ( len(@phone) = 6 and @lada = area and len(area) = 4 )
              or
              ( len(@phone) = 7 and @lada = area and len(area) = 3 )
              or
              ( len(@phone) = 8 and @lada = area and len(area) = 2 )
              or
              ( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
              or
              ( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
              or
              ( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
              or
              ( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
              or
              ( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
              or
              ( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 ))
          end
    end

  else if @country = 3 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
    where id_country = @country and (
    ( len(@phone) = 7 and @lada = area )
    or
    ( len(@phone) = 8 and left(@phone,1) = area )
    or
    ( len(@phone) in(10,11) and (left(@phone,1) = ''3'' or substring(@phone,2,1) = ''3'')))
  end

   else if @country = 4

    begin
      select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaUsaDetail where
      ( len(@phone) = 7 and @lada = area and len(area) = 3 )
      or
      ( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 and left(right(@phone, 7), 3) = prefix)
      if @timeZone is null
        begin
          select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
          where id_country = @country and (
          ( len(@phone) = 7 and @lada = area and len(area) = 3 )
          or
          ( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
        end
    end

   else if @country = 5 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
    where id_country = @country and (
    ( len(@phone) = 6 and @lada = area )
    or
    ( len(@phone) = 7 and @lada = area )
    or
    ( len(@phone) = 8 and left(@phone,1) = area )
    or
    ( len(@phone) = 8 and left(@phone,2) = area )
    or
    ( len(@phone) = 9 and left(@phone,2) = area )
    or
    ( len(@phone) = 10 and substring(@phone,3,1) = area and left(@phone,2) = ''09'' ))
  end

  else if @country = 6 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
    where id_country = @country and (
    ( len(@phone) = 7 and @lada = area and len(area) = 3 )
    or
    ( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
  end

  else if @country = 7 begin
    declare @phoneTemp as varchar(10)
    select @phoneTemp = right ( @phone, 10 )
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
    where id_country = @country and (
    (len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
    (len(@phoneTemp) = 10 and left(@phoneTemp,5) = area ) or
    (len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
    (len(@phoneTemp) = 10 and left(@phoneTemp,4) = area ) or
    (len(@phoneTemp) = 9 and left(@phoneTemp,4) = area ) or
    (len(@phoneTemp) = 10 and left(@phoneTemp,3) = area ) or
    (len(@phoneTemp) = 10 and left(@phoneTemp,2) = area )
    )
  end

  if @country = 8 begin
    select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
    where id_country = @country and (
    (len(@phone) = 7 and @lada = area) or
    (len(@phone) = 9 and substring(@phone, 2, 1) = area) or
    (len(@phone) = 10 and substring(@phone, 2, 1) = area) or
    (len(@phone) = 11 and substring(@phone, 2, 1) = area))
  end

   else if @country = 9 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    -- len(@phone) = 10
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
      where id_country = @country and (
      (convert (int, substring(@phone, 1, 4)) = convert (int, area) and len(area) = 4) or
      (convert (int, substring(@phone, 1, 2)) = convert (int, area) and len(area) = 2))
    end
  end

 else  if @country = 10 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    -- 8 <= len(@phone) <= 19
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
      where id_country = @country and (
      ((len(@phone) between  8 and  9)                                      and                   @lada = area) or
      ((len(@phone) between 10 and 11)                                      and substring(@phone, 1, 2) = area) or
      ((len(@phone) between 12 and 13) and substring(@phone, 1, 4) = ''9090'' and                   @lada = area) or
      ((len(@phone)       = 13       )                                      and substring(@phone, 4, 2) = area) or
      ((len(@phone) between 14 and 15) and substring(@phone, 1, 2) = ''90''   and substring(@phone, 5, 2) = area) or
      ((len(@phone)       = 14       ) and substring(@phone, 1, 1) = ''0''    and substring(@phone, 4, 2) = area))
    end
  end

  else if @country = 11 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  else if @country = 12 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  if @country = 13 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
    end
  end

  else if @country = 14 begin
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      if len(@phone) = 9 begin
        select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
        where id_country = @country and ((substring(@phone, 1, 2) = area) or (substring(@phone, 1, 3) = area))
      end
    end
  end

 else  if @country = 15 OR @country = 16  begin --Peru
    select @phone = dbo.Completa(@phone, @pais, @lada)
    if (substring(@phone, 1, 1) <> ''E'') begin
      select @timeZone = 32
    end
  end

  return isNull(@timeZone,0)
 END'
		EXEC(@sql)		

		set @process = 'CW-3928 Drop if exists ccsp_GalateaAdminGetAgentCounters'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminGetAgentCounters'')
	    begin
	        DROP PROCEDURE ccsp_GalateaAdminGetAgentCounters;
	    end'
	    exec (@sql)

			set @process = 'CW-3928 Refactorizacion AM'
		set @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetAgentCounters] @type AS     INT, 
                                                    @sup_id AS   INT = 0, 
                                                    @agent_id AS INT = 0, 
                                                    @WG AS       INT = 0
AS
     SET NOCOUNT ON;
     IF @type = 1
         BEGIN
             WITH TableUserAgent(userId)
                  AS (SELECT DISTINCT 
                           wgAgt.User_id  AS Id --,usr.login 
                      FROM ccriaworkgroupusers wgAdmin
                           INNER JOIN ccriaworkgroupusers wgAgt ON wgAdmin.IDWG = wgAgt.IDWG
                           INNER JOIN ccUsers usr ON usr.User_id = wgAgt.User_id
                                                     AND usr.TipoUser_id = 1
                      WHERE wgAdmin.User_id = @sup_id)
                  SELECT CAST(a.User_id AS INT) Id, 
                         a.login AS Username, 
                         a.Nombres + '' '' + a.ApellidoPaterno + '' '' + a.ApellidoMaterno AS Name
                  FROM ccusers a(NOLOCK)--, ccGenViewRelsSupsAgent b
                       INNER JOIN TableUserAgent b ON a.User_id = b.userId
                  ORDER BY a.Login ASC;
     END;
     IF @type = 2
         BEGIN
             SELECT CAST(User_id AS INT) Id,
					Login Username, 
                    Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno Name
             FROM ccUsers
             WHERE User_id = @agent_id;
     END;
     IF @type = 3 --Agents by supervisor and WG
         BEGIN
             DECLARE @table2 TABLE
             (userId INT
              PRIMARY KEY NOT NULL
             );
             INSERT INTO @table2
                    SELECT DISTINCT 
                           wg.User_id
                    FROM ccRIAWorkGroupUsers wg
                         LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                    WHERE us.TipoUser_id = 1
                          AND wg.IDWG IN
                    (
                        SELECT IDWG
                        FROM ccRIAWorkGroupUsers
                        WHERE User_id = @sup_id
                              AND IDWG <> @WG
                    );
             SELECT CAST(B.User_id AS int) AS Id
             FROM @table2 A
                  RIGHT JOIN
             (
                 SELECT DISTINCT 
                        wg.User_id
                 FROM ccRIAWorkGroupUsers wg
                      LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                 WHERE wg.IDWG = @WG
                       AND us.TipoUser_id = 1
             ) B ON A.userId = B.User_id
             WHERE A.userId IS NULL;
     END;

	 IF @type = 4 --Agents IDs by WG
     BEGIN
		SELECT  CAST(wg.User_id AS INT) Id  
		FROM ccRIAWorkGroupUsers wg
		JOIN CCUsers u on u.user_id = wg.user_id AND u.TipoUser_id = 1
		where IDWG = @WG
     END;
     SET NOCOUNT ON;
'
	    exec (@sql)


			set @process = 'CW-3928 Drop if exists ccsp_GalateaAdminWorkgroups'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminWorkgroups'')
	    begin
	        DROP PROCEDURE ccsp_GalateaAdminWorkgroups;
	    end'
	    exec (@sql)

		
			set @process = 'CW-3928 Refactorizacion AM'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminWorkgroups] 
	@Option AS SMALLINT,
	@AdminId AS INT = 0,
	@WorkgroupId AS INT = 0
AS
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
END'
	    exec (@sql)


			set @process = 'CW-3928 Drop if exists ccsp_GalateaAdminCampaigns'
			set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminCampaigns'')
		    begin
		        DROP PROCEDURE ccsp_GalateaAdminCampaigns;
		    end'
		    exec (@sql)

			set @process = 'CW-3928 Drop if exists ccsp_GalateaAdminCampaigns'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS SMALLINT, 
												   @CampType AS SMALLINT = 0, 
												   @WorkgroupId AS INT = 0, 
												   @Id AS INT = 0,
												   @AdminId AS SMALLINT = 0, 
												   @PinUpdate AS SMALLINT = 0, 
												   @LoadId AS INT = 0
AS
BEGIN
	set nocount on
	IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type 
	BEGIN
		IF @CampType = 1 -- Campaigns Out 
		BEGIN
			IF @WorkgroupId IS NOT NULL
			BEGIN
				SELECT CAST(IdCampEsp AS INT) AS Id 
				FROM ccRIACampEspWG 
				WHERE IDWG = @WorkgroupId AND Tipo=1
				ORDER BY IdCampEsp ASC
			END
			ELSE
			BEGIN
				raiserror(''ERROR. No existe una lista de campa?as de salida con el id de grupo de trabajo especificado'', 18, 1)
			END	
		END
		IF @CampType = 0 -- Campaigns In (ACD)
		BEGIN
			IF @WorkgroupId IS NOT NULL
			BEGIN
				SELECT CAST(IdCampEsp AS INT) AS Id 
				FROM ccRIACampEspWG 
				WHERE IDWG = @WorkgroupId AND Tipo=0
				ORDER BY IdCampEsp ASC
			END
			ELSE
			BEGIN
				raiserror(''ERROR. No existe una lista de campa?as de entrada con el id de grupo de trabajo especificado'', 18, 1)
			END	
		END
	END
	
	IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id 
		BEGIN
			IF @CampType = 1 -- Campaigns Out 
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							SELECT DISTINCT 
								rel.cam_id AS Id, 
								camps.cam_descripcion AS Name, 
								CAST(graph.graphic_id AS INT) AS Frame, 
								CAST(rel.tipo AS SMALLINT) AS Type,
								cam_procesando IsStarted
							FROM ccSupervisorCam rel
								LEFT JOIN ccCamps camps ON camps.cam_id = rel.cam_id
								LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
							WHERE rel.cam_id = @Id AND rel.tipo = 1
							ORDER BY camps.cam_descripcion ASC;
						END
					ELSE
					BEGIN
						raiserror(''ERROR. No existe campa?as de salida con el id especificado'', 18, 1)
					END	
				END
			IF @CampType = 0 -- Campaigns In (ACD)
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							SELECT DISTINCT 
								rel.cam_id AS Id, 
								inbound.descripcion AS Name, 
								CAST(graph.graphic_id AS INT) AS Frame,
								0 Pin, 
								CAST(rel.tipo AS SMALLINT) AS Type,
								CAST(0 AS BIT) IsStarted
							FROM ccSupervisorCam rel
								LEFT JOIN ccInbound inbound ON inbound.Inbound_id = rel.cam_id
								LEFT JOIN ccRIAInboundGraph graph ON inbound.Inbound_id = graph.Inbound_id
							WHERE rel.cam_id = @Id AND rel.tipo = 0
							ORDER BY inbound.descripcion ASC;
						END
					ELSE
						BEGIN
							raiserror(''ERROR. No existe campa?as de entrada con el id especificado'', 18, 1)
						END	
				END
		END

	IF @Option = 3   -- Update OverallTotalNew By Campaign 
		BEGIN
			IF @Id IS NOT NULL
				BEGIN
					UPDATE ccCampsNvosCB SET OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id
				END
			ELSE
				BEGIN
					raiserror(''ERROR. No existe la campa?as de entrada con el id especificado'', 18, 1)
				END	
		END

	IF @Option = 4	 -- Update Pin from Campaign per Admin
		BEGIN
			IF @Id IS NOT NULL AND @AdminId IS NOT NULL
				BEGIN
					IF @PinUpdate = 1
						BEGIN
							INSERT INTO PinedCampaigns (CampId, AdminId)
								   VALUES (@Id, @AdminId);
						END;
					IF @PinUpdate = 0
						BEGIN
							DELETE FROM PinedCampaigns
							WHERE CampId = @Id AND AdminId = @AdminId;
						END;
				END
			ELSE
				BEGIN
					raiserror(''ERROR. La campa?as o administrador no existen'', 18, 1)
				END	
		END
	
	IF @Option = 5	 -- Get Pin from Campaign Ids per Admin
		BEGIN
			IF @AdminId IS NOT NULL
				BEGIN
					SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId
					ORDER BY Id ASC
				END
			ELSE
				BEGIN
					raiserror(''ERROR. El administrador con el id seleccionado no existe'', 18, 1)
				END	
		END

	IF @Option = 6	 -- Get Blacklist Ids by Campaign Id
	BEGIN
		IF @Id IS NOT NULL
			BEGIN
	            DECLARE @BlackListIds VARCHAR(MAX);
	            SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
	            FROM Camplistanegra
	            WHERE cam_id = @Id AND STATUS = 1;
	            SELECT isnull(@BlackListIds,''0'') AS BlackListIds;
			END
		ELSE
			BEGIN
				raiserror(''ERROR. La campa?as con el id seleccionado no existe'', 18, 1)
			END	
	END

	IF @Option = 7	 -- Get RegistryListIds Ids by Campaign Id
	BEGIN
		IF (@Id IS NOT NULL AND EXISTS(SELECT * FROM cccamps WHERE cam_id = @Id))
			BEGIN
				SELECT TOP 1 list_id FROM ccRIARegistryLists WHERE cam_id = @Id AND status = 2 ORDER BY list_id DESC
			END
		ELSE
			BEGIN
				--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
				raiserror(''ERROR. No existe una campa?a con el id especificado'', 18, 1)			
			END	
	END

	IF @Option = 8	 -- Delete RegistryListIds Ids by LoadId
	BEGIN
		IF (@LoadId IS NOT NULL AND EXISTS(SELECT * FROM ccRIARegistryLists WHERE list_id = @loadID and status <> 0))
			BEGIN
				UPDATE ccoCallsOutSource SET cal_status = ''5'' WHERE list_id = @loadID
				DELETE FROM ccoWorkingTable WHERE list_id = @LoadId 
				exec ccsp_RIARegistryLists @action=6, @list_id = @LoadId 
			END
		ELSE
			BEGIN
				--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
				raiserror(''ERROR. No existe una carga el id especificado'', 18, 1)
			END		
	END

	 IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
         BEGIN
             DECLARE @table TABLE
             (camId    INT, 
              campType TINYINT,
              PRIMARY KEY(camId, campType)
             );
             INSERT INTO @table
                    SELECT DISTINCT 
                           IdCampEsp, 
                           Tipo
                    FROM ccRIACampEspWG wg
                    WHERE wg.IDWG IN
                    (
                        SELECT IDWG
                        FROM ccRIAWorkGroupUsers
                        WHERE IDWG <> @WorkgroupId
                    );
             SELECT CAST(B.IdCampEsp AS INT) AS Id, 
                    B.Tipo AS Type
             FROM @table A
                  RIGHT JOIN
             (
                 SELECT wg.IdCampEsp, 
                        wg.Tipo
                 FROM ccRIACampEspWG wg
                 WHERE wg.IDWG = @WorkgroupId
             ) B ON A.camId = B.IdCampEsp
                    AND A.campType = B.Tipo
             WHERE A.camId IS NULL
             ORDER BY IdCampEsp;
     END;
END
'
	    exec (@sql)

		set @process = 'CW-3941 Refactor: Add new operation with id 178 into ccRIALog_Operation'
		set @sql = 'IF NOT EXISTS(SELECT * FROM ccRIALog_Operation WHERE operationType =  178)
						BEGIN 
							INSERT INTO ccRIALog_Operation(operationType,descripcion) VALUES (178,''CANCELAR PENDIENTES A NUEVOS|CANCEL PENDING TO NEW'');
						END'
	    exec (@sql)

		set @process = 'CW-3941 Refactor:  Drop if exists ccsp_GalateaGetRegistryListID'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetRegistryListID'')
	    begin
	        DROP PROCEDURE ccsp_GalateaGetRegistryListID;
	    end'
	    exec (@sql)

	    set @process = 'CW-3941 Refactor:  Drop if exists ccsp_GalateaDeleteRegistryList'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaDeleteRegistryList'')
	    begin
	        DROP PROCEDURE ccsp_GalateaDeleteRegistryList;
	    end'
	    exec (@sql)

	    set @process = 'CW-3941 Refactor:  Drop if exists ccsp_GalateaUpdateOverallTotalNew'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaUpdateOverallTotalNew'')
	    begin
	        DROP PROCEDURE ccsp_GalateaUpdateOverallTotalNew;
	    end'
	    exec (@sql)

		set @process = 'CW-3941 Refactor:  Drop if exists ccsp_GalateaLoadCamps'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaLoadCamps'')
	    begin
	        DROP PROCEDURE ccsp_GalateaLoadCamps;
	    end'
	    exec (@sql) 

	    set @process = 'CW-3941 Refactor:  Update PinedCampaigns Table '
		set @sql = 'IF EXISTS(SELECT * FROM sys.tables WHERE name = N''PinCampaings'')
						BEGIN 
							EXEC sp_rename ''PinCampaings'', ''PinedCampaigns''
							EXEC sp_rename ''PinedCampaigns.Cam_Id'', ''CampId''
							EXEC sp_rename ''PinedCampaigns.Sup_Id'', ''AdminId''
						END'
	    exec (@sql) 
	    
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		-- exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
