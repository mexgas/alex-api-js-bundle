/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/15/10
Description:

Database: CCenterRia
Required version: 123.14

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
SET @version = 123 --**********actualizar a 122 sin fix
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

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'CW-4919 ccLogDials'
	set @sql = 'IF EXISTS (SELECT * 
					  FROM sys.default_constraints
					   WHERE object_id = OBJECT_ID(N''dbo.DF__ccoLogDia__tDial__31D75E8D'')
					   AND parent_object_id = OBJECT_ID(N''dbo.ccoLogDials'')
					)
					BEGIN
						ALTER TABLE CCoLOGDIALS DROP CONSTRAINT DF__ccoLogDia__tDial__31D75E8D

						ALTER TABLE CCoLOGDIALS
						   ALTER COLUMN tdialing smallint not null

						ALTER TABLE CCoLOGDIALS ADD CONSTRAINT DF__ccoLogDia__tDial__31D75E8D DEFAULT(0) FOR tdialing
					END'
	exec (@sql)

	set @process = 'CW-4804 para corregir consulta de información de agentes por grupo de trabajo'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminGetAgentCounters] @type AS     INT, 
                                                    @sup_id AS   INT = 0, 
                                                    @agent_id AS INT = 0, 
                                                    @WG AS       INT = 0,
                          @campId AS INT = 0
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

   IF @type = 5 --Agents IDs by Campaign
     BEGIN
    SELECT Distinct(CAST(U.User_id AS INT)) Id FROM ccRIACampEspWG camp
    JOIN ccRIAWorkGroupUsers wg ON camp.IDWG = wg.IDWG
    JOIN ccUsers U ON U.User_id = WG.User_id AND U.TipoUser_id = 1
    WHERE IdCampEsp = @campId AND TIPO = 1
     END;

    IF @type = 6 -- Get Agent current state
   BEGIN
    WITH UserMaxFecha(User_id,fecha) as(
      SELECT User_id,max(fecha) as fecha from ccLogAgentesDia where fecha>=convert(date,getdate()) group by User_id
    )

    SELECT CASE WHEN CurrentState.currentStatus is null or  CurrentState.currentStatus<0 
          then 0 else CAST(CurrentState.currentStatus as int) end CurrentState
    from ccUsers u
    left join 
    (
    select A.User_id,B.currentStatus from UserMaxFecha A 
    inner join ccLogAgentesDia  B on A.User_id=B.User_id and A.fecha=B.fecha
    ) CurrentState on u.User_id=CurrentState.User_id
    where u.TipoUser_id=1 and u.User_id = @agent_id
   END

   IF @type = 7 -- Get superuser id''s except root
   BEGIN
    declare @superuserId as int
    set @superuserId = (select Rol_id from ccRoles where Level = 7) -- obtenemos el id del rol superusuario

    select CAST(cr.User_id AS INT) User_id 
    from ccUsers_Roles cr
    where Rol_id = @superuserId
    and cr.User_id not in (1) 
   END

   IF @type = 8 -- Get all Agent''s ID, Login and Full Names related to a workgroup
   BEGIN
    SELECT DISTINCT 
      Convert(INT,wg.User_id) Id,
      us.Login Username,
      us.Nombres + '' '' + us.ApellidoPaterno + '' '' + us.ApellidoMaterno Name
    FROM ccRIAWorkGroupUsers wg
      LEFT JOIN ccUsers us ON wg.User_id = us.User_id
    WHERE wg.IDWG = @WG
      AND us.TipoUser_id = 1
   END

     SET NOCOUNT ON;'
	exec (@sql)

  set @process = 'CW-2705 Alter function fnGetCallType '
  set @sql = '
		ALTER function [dbo].[fnGetCallType](@tel varchar(32))
		RETURNS tinyint
		AS
		BEGIN
				
			declare @ladatemp smallint, @ldlocal smallint, @serie smallint, @numeracion smallint, @lenght tinyint, @tipo tinyint
			declare @mod varchar(10)

			set @lenght = LEN(@tel)

			select top 1 @tipo=tipollamada_id from cstoTipoLlamada nolock where country_id=1 and tipoLlamada_id in (5,6,7) and (longitud=@lenght or longitud=0) and @tel like prefijo order by tipollamada_id

			if @tipo is not null
			begin
				return @tipo
			end

			select @tipo = 0, @ldlocal = valor from ccSettings with(nolock) where setting_id = 17
				
			if @lenght = 10 - LEN(@ldlocal) begin
				select @tel = convert(varchar(3),@ldlocal) + @tel
			end
				
			select @tel = RIGHT(@tel,10)
			select @ladatemp = left(@tel,2)
				
			if(@ladatemp in (55,56,33,81)) begin
				select @serie = convert(smallint,SUBSTRING(@tel,3,4)), @numeracion = RIGHT(@tel,4)
				select @mod = MODALIDAD from Series nolock where CLD = @ladatemp and SERIE = @serie and @numeracion between [NUMERACION INICIAL] and [NUMERACION FINAL]
			end
			else begin
				select @ladatemp = left(@tel,3)
				select @serie = convert(smallint,SUBSTRING(@tel,4,3)), @numeracion = RIGHT(@tel,4)
				select @mod =MODALIDAD from Series nolock where CLD = @ladatemp and SERIE = @serie and @numeracion between [NUMERACION INICIAL] and [NUMERACION FINAL]
			end

			declare @isLocal bit
			SET @isLocal = 0
			IF EXISTS (
					SELECT *
					FROM ccRiaArecode
					WHERE area = @ladatemp
					)
			BEGIN
				SET @isLocal = 1
			END
			ELSE IF @ldlocal = @ladatemp
			BEGIN
				SET @isLocal = 1
			END

				
			if @mod in (''FIJO'', ''MPP'') begin
				if @isLocal = 1 begin
					set @tipo = 1
				end
				else begin
					set @tipo = 2
				end
			end
				
			if @mod in (''CPP'') begin
				if @isLocal = 1 begin
					set @tipo = 3
				end
				else begin
					set @tipo = 4
				end
			end

			return @tipo
		END'
  exec (@sql)

  set @process = 'CW-2705 Alter function fnGetTipoLlamada'
  set @sql = '
		ALTER function [dbo].[fnGetTipoLlamada](@tel varchar(32))
		RETURNS tinyint
		AS
		BEGIN
		
		declare @ladatemp smallint, @ldlocal varchar(10), @serie smallint, @numeracion smallint, @lenght tinyint
		declare @mod varchar(10), @country tinyint
		
		select @country = valor from ccsettings where setting_id = 104
		select @lenght = LEN(@tel),
		@ldlocal = valor from ccSettings with(nolock) where setting_id = 17
		--print '' longitud: '' + convert(varchar(2),@lenght) + '' lada: '' + convert(varchar(3),@ldlocal)
		
			declare @table table(
			id int not null,
			prefijo nvarchar(100) not null
			)
		
			declare @t_tipos table(
			tipollamada_id int not null,
			prefijo nvarchar(100) not null,
			rowid int not null
			)
		
		declare @tipoLlamada_id smallint, @prefijo varchar(15), @tipo tinyint, @cantidadLL tinyint
		set @tipoLlamada_id = 0
		--set @tipo = 0
		
			insert into @t_tipos
			select tipoLlamada_id, prefijo, ROW_NUMBER() over(order by len(prefijo) desc) as rowid from (select tipoLlamada_id, longitud, prefijo, (select count(*) from fn_RIASplitDelimited(longitud,''|'') where value=@lenght) as exist
			from cstoTipoLlamada with(index(IX_cstoTipoLlamada),nolock) 
			where country_id = @country
			and (country_id <> 1 or (country_id = 1 and tipoLlamada_id not in (8,9,10,11,12))) ) as a where exist = 1
		
			select @cantidadLL =count(*) from @t_tipos 
			--print ''cantidad de regs'' + convert(varchar(2),@cantidadLL)
		
			if @cantidadLL <> 0 begin
			   --print ''existen opciones''
			   declare @i int ;
				set @i=1

			   while @i <= @cantidadLL
			   begin
					 select @tipoLlamada_id = tipoLlamada_id, @prefijo = prefijo from @t_tipos where rowid = @i
					 --print ''tipo llamada:'' + convert(varchar(2),@tipoLlamada_id) + '' prefijo:'' + @prefijo
		
					 insert into @table
					 select * from fn_RIASplitDelimited(@prefijo,''|'') order by len(value) desc
		
					 if (select count(*)	from @table	where @tel like prefijo) = 1
					 begin
						set @tipo = @tipoLlamada_id
						set @i = @cantidadLL
					 end
		
					 set @i = @i + 1
			   end
			end
			else begin
			   --print ''revisar contra longitud 0''
		
			   select @tipoLlamada_id = tipoLlamada_id, @prefijo = prefijo from (select tipoLlamada_id, longitud, prefijo, (select count(*) from fn_RIASplitDelimited(prefijo,''|'') where @tel like (value)) as exist
			   from cstoTipoLlamada with(index(IX_cstoTipoLlamada),nolock) 
			   where country_id = @country and longitud = ''0''
			   and (country_id <> 1 or (country_id = 1 and tipoLlamada_id not in (8,9,10,11,12))) ) as a where exist = 1
		
			   if @tipoLlamada_id <> 0 begin
					 set @tipo = @tipoLlamada_id
			   end
			   else begin
					 --print ''revisar contra series''
		
					 if @lenght = 10 - LEN(@ldlocal) begin
						select @tel = convert(varchar(3),@ldlocal) + @tel
					 end
		
					 select @tel = RIGHT(@tel,10)
					 select @ladatemp = left(@tel,2)
		
					 if(@ladatemp in (55,56,33,81)) begin
						--print ''es de dos digitos''
						select @serie = convert(smallint,SUBSTRING(@tel,3,4)), @numeracion = RIGHT(@tel,4)
						--print ''serie: '' + convert(varchar(4),@serie) + '' numeracion: '' + convert(varchar(4),@numeracion)
						select @mod = MODALIDAD from Series where CLD = @ladatemp and SERIE = @serie and @numeracion between [NUMERACION INICIAL] and [NUMERACION FINAL]
					 end
					 else begin
						--print ''es de tres digitos''
						select @ladatemp = left(@tel,3)
						select @serie = convert(smallint,SUBSTRING(@tel,4,3)), @numeracion = RIGHT(@tel,4)
						--print ''serie: '' + convert(varchar(4),@serie) + '' numeracion: '' + convert(varchar(4),@numeracion)
						select @mod =MODALIDAD from Series where CLD = @ladatemp and SERIE = @serie and @numeracion between [NUMERACION INICIAL] and [NUMERACION FINAL]
					 end


					declare @isLocal bit
					SET @isLocal = 0

					IF EXISTS (
							SELECT *
							FROM ccRiaArecode
							WHERE area = @ladatemp
							)
					BEGIN
						SET @isLocal = 1
					END
					ELSE IF @ldlocal = @ladatemp
					BEGIN
						SET @isLocal = 1
					END

		
					 if @mod in (''FIJO'', ''MPP'') begin
						if(@isLocal = 1)
						begin
							--print ''misma lada -> es local''
							set @tipo = 1
						end
						else begin
							--print ''diferente lada -> es ld''
							set @tipo = 2
						end
					 end
		
					 if @mod in (''CPP'') 
					 begin
						if(@isLocal = 1)
						begin
							--print ''misma lada -> es celular local''
							set @tipo = 3
						end
						else begin
							--print ''diferente lada -> es celular ld''
							set @tipo = 4
						end
					 end
			   end
			end
		
			return @tipo
		END'
  exec (@sql)
 
		set @process = 'CW-4918 CREATE FUNCTION [dbo].[fnGetTimeZone]'
		set @sql = 'ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
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
			IF EXISTS (
					SELECT TOP 1 cld
					FROM series NOLOCK
					WHERE cld = left(@phone, 3)
					and serie=SUBSTRING(@phone,4,3)
					)
				SELECT @ld = left(@phone, 3),@serie=SUBSTRING(@phone,4,3)
			ELSE IF EXISTS (
					SELECT TOP 1 cld
					FROM series NOLOCK
					WHERE cld = left(@phone, 2)
					and serie=SUBSTRING(@phone,3,4)
					)
				SELECT @ld = left(@phone, 2),@serie=SUBSTRING(@phone,3,4)


        end    	

      if @ld <> ''''
        begin			
		    set @rank=right(@phone, 4)

          select top 1 @location = estado, @locality = MUNICIPIO from series 
		  where cld = @ld and serie = @serie and @rank between [NUMERACION INICIAL] and [NUMERACION FINAL]

          if @location is null or not exists(select  locality from ccTimeZoneArea (nolock) where id_country=@country and area=@ld and locality=@locality)
            set @locality = null					         
        end
	else begin
		set @ld=@lada
	end

		set @location = case when @location = ''DF'' then ''CDMX'' else @location end

		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
          where id_country = @country and 
          area = @ld 
		  and ( @location is null or location = @location)
		
		if(@timeZone is null or @timeZone = 0)
		begin
			select top 1 @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end 
			from ccTimeZoneArea t
			where id_country = @country and area = @lada
		end
		
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

  if(@timeZone is null or @timeZone = 0)
	begin
		select top 1 @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end 
		from ccTimeZoneArea t
		where id_country = @country and area = @lada
	end 

  return isNull(@timeZone,0)
 END'
		EXEC(@sql)
		
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
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
