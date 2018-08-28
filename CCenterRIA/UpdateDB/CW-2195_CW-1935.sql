/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: 
		
Date: 2018/05/15
Description:

Database: CCenterRia
Required version: 120.14

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 120--**********actualizar a 119 sin fix
set @versionfix = 24
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'


if  @actualVersion = @version and  @actualVersionFix >= 22
	begin
		begin tran
		begin try

		set @process = 'CW-2195 Version 120.22 Drop Index series.IX_Series_1'
        set @Sql= 'drop index IX_Series_1 on series'
        EXEC(@Sql)

        set @process = 'CW-2195 Version 120.22 Delete From Row CLD'
        set @Sql= 'delete from series where CLD=''CLD'''
        EXEC(@Sql)

        set @process = 'CW-2195 Version 120.22 '
        set @Sql= 'alter table series alter column [NUMERACION INICIAL] int'
        EXEC(@Sql)

        set @process = 'CW-2195 Version 120.22 '
        set @Sql= 'alter table series alter column [NUMERACION FINAL] int'
        EXEC(@Sql)

        set @process = 'CW-2195 Version 120.22 Create index series.IX_Series_1'
        set @Sql= 'if not exists (select * from sys.indexes where name = N''IX_Series_1'' and object_id = OBJECT_ID(N''series''))
    begin
        Create index IX_Series_1 on series (cld,serie,[NUMERACION INICIAL],[NUMERACION FINAL])
    end'
        EXEC(@Sql)
				

		set @process = 'CW-2195 Version 120.22 Alter functio Verifica'
        set @Sql= 'ALTER FUNCTION [dbo].[Verifica](@tel varchar(32))
RETURNS varchar(32) AS
BEGIN
	
	declare @cldLocal varchar(7)
	declare @pais tinyint

	select @pais = valor from ccSettings with(nolock) where setting_id = 104
	select @cldLocal = valor from ccSettings with(nolock) where setting_id = 17

	return dbo.Verifica2(@tel,@pais,@cldLocal)

END'
        EXEC(@Sql)

        set @process = 'CW-2195 Version 120.22 Alter Verifica2'
        set @Sql= 'ALTER FUNCTION [dbo].[Verifica2]
(@tel varchar(32),@pais tinyint = 0, @cldLocal varchar(7) = '''')
RETURNS varchar(32) AS
BEGIN
declare @ld varchar(7)
declare @lon tinyint
declare @result tinyint
declare @mod varchar(10)
declare @Cadena varchar(32)

if (@pais = 0 and @cldLocal = '''') begin
  select @pais = valor from ccSettings with(nolock) where setting_id = 104
  select @cldLocal = valor from ccSettings with(nolock) where setting_id = 17
end

select @tel = dbo.limpia(@tel)

if @pais = 1 begin --Empieza Mexico
  select @lon = len(@tel),@mod=''''
  if @lon in(7,8) begin
    set @tel = @cldLocal + @tel
    set @ld=@cldLocal   
  end 
  select @tel = right(@tel, 10)
  select @lon = len(@tel)
  

  if @lon = 10 begin
    
    if @ld is null begin
      if(exists(select top 1 cld from series nolock where cld=left(@tel,2)))
        select @ld = left(@tel,2)
      else if(exists(select top 1 cld from series nolock where cld=left(@tel,3)))
        select @ld = left(@tel,3)
      else
        return ''E_'' + @tel
    end

    select top 1 @mod = modalidad from series nolock where cld = @ld and serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

    if @mod not in (''FIJO'', ''MPP'',''CPP'')  begin
      return ''E_'' + @tel
    end
      
    if (select valor from ccsettings with(nolock) where setting_id = 195) = ''1'' and @ld=  @cldLocal begin--10 digits  
      return @tel     
    end


    select @tel = case
      when @mod in (''FIJO'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''01'' + @tel end
      when @mod = ''CPP'' then case when @ld = @cldLocal then ''044'' + @tel else ''045'' + @tel end
      end
  end 
  else if @lon>0 begin     
    set @tel = ''E_'' + @tel
  end
 return @tel
end --Termina Mexico

 -- Empieza Argentina
    if @pais = 2 begin
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     if left(@tel,1) = ''E'' begin return @tel end
     select @lon = len(@tel)
     if @lon in(6,7,8) and left(@tel,2) <> ''15'' begin
      set @tel = @cldLocal + @tel
     end

     if @lon in (8,9,10) and left(@tel,2) = ''15'' begin
      set @tel = @cldLocal + substring(@tel,3,@lon - 2)
     end

     --Buscamos el 15
     if @lon = 13 begin
      declare @index as int
      select @index = charindex(''15'',@tel)
      --El unico caso en el que la lada tiene un 15 es con lada 3715
      if @index < 2 begin
       select @tel = ''E_'' + @tel
       return @tel
      end
      else begin
       if substring(@tel,@index-2,4) = ''3715''
        begin
         select @ld = ''3715''
         set @tel = @ld + right(@tel,6)
        end
       else
        begin
         select @ld = substring(@tel,2,@index-2)
         set @tel = @ld + right(@tel,13 - (@index + 1))
        end
      end
     end

     select @tel = right(@tel, 10)

     if len(@tel) = 10 begin
      declare @serie as varchar(5)
      begin
       -- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
       declare @contLD as int
       declare @cont as int
       set @contLD=4
        BuscaLada:
        if isnull(@ld,'''') = '''' and @contLD >= 2
         begin
          select @ld = cld from seriesArg where cld=left(@tel,@contLD)
          if isnull(@ld,'''') = '''' begin
           set @contLD = @contLD - 1
           goto BuscaLada
          end
         end
        else begin
          if isnull(@ld,'''') = '''' begin
           select @tel = ''E_'' + @tel
          end
        end
      end

      -- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
      begin
      if len(@ld) = 2 begin
        set @cont = 5
        buscaSerie2:
        if isnull(@serie,'''') = '''' and @cont >= 4 begin
         select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,3,@cont)
         if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie2 end
        end
      end
      else begin
       if len(@ld) = 3 begin
        set @cont = 4
        buscaSerie3:
        if isnull(@serie,'''') = '''' and @cont >= 3 begin
         select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,4,@cont)
         if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie3 end
        end
       end
       else begin
        if len(@ld) = 4 begin
         set @cont = 3
         buscaSerie4:
         if isnull(@serie,'''') = '''' and @cont >= 2 begin
          select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,5,@cont)
          if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie4 end
         end
        end
       end
      end

      end

      select @mod = modalidad from seriesArg where cld = @ld and serie = @serie and right(@tel, 10 - len(@ld) - len(@serie)) between [NUMERACION INICIAL] and [NUMERACION FINAL]

      -- Si la serie es nula, existe una posibilidad de que la lada este mal, asi que se quita un numero de la lada y se vuelve a buscar la serie
      --select @ld,@serie,@mod,@contLD
      if isNull(@serie,'''') = '''' and @contLD>1 begin
      set @contLD = len(@ld) - 1
      set @ld = null
      goto BuscaLada
      end

      select @tel = case
       when @mod in (''BASICA'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''0'' + @tel end
       when @mod = ''CPP'' then case when @ld = @cldLocal then ''15'' + right(@tel,10-len(@ld)) else ''0'' + @ld + ''15'' + right(@tel,10-len(@ld)) end
       else ''E_'' + @tel
      end
     end else begin
      if len(@tel) > 0 begin
       select @tel = ''E_'' + @tel
      end
     end
     return @tel
    end  --Termina Argentina

    if @pais = 3 begin  --Empieza Colombia
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     if left(@tel,1) = ''E'' begin
      return @tel
     end

     if len(@tel) not in (7,8,10,11) begin
      return ''E_'' + @tel
     end

     if len(@tel) = 7 begin
      if exists(select serie from seriesCol where serie = left(@tel,4) and @cldLocal = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end

     if len(@tel) = 8 begin
      if exists(select serie from seriesCol where serie = substring(@tel,2,4) and left(@tel,1) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end

     if len(@tel) = 10 begin
      if exists(select serie from seriesCol where serie = substring(@tel,5,3) and (left(@tel,3) + ''-'' + substring(@tel,4,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end

     if len(@tel) = 11 begin
      if exists(select serie from seriesCol where serie = substring(@tel,6,3) and (substring(@tel,2,3) + ''-'' + substring(@tel,5,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end
    end  --Termina Colombia

    -- Empieza Chile
    if @pais = 5 begin
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     if left(@tel,1) = ''E'' begin
      return @tel
     end

     if len(@tel) = 6 and len(@cldLocal) = 2 begin
      if exists(select serie from seriesChi where cld = @cldLocal and left(@tel,3) = serie and right(@tel,3) between numeracioninicial and numeracionFinal) begin
       return @tel
      end
      else begin return ''E_'' + @tel end
     end

     if len(@tel) = 7 begin
      if @cldLocal in (2,41,44,32) begin
       if exists(select serie from serieschi where serie = left(@tel,4)) begin return @tel end
       else begin
        if left(@tel,3) = ''200'' and exists(select serie from serieschi where serie = left(@tel,3) ) begin return @tel end
       end
      end
     end

     if len(@tel) = 8 begin
      if left(@tel,1) = ''2'' begin
        if exists(select serie from serieschi where serie = substring(@tel,2,4)) begin return @tel end
        else begin
         if exists(select serie from serieschi where serie = substring(@tel,2,5)) begin return @tel end
         else begin return ''E_'' + @tel end
        end
      end
      else begin
       return @tel
      end
     end

     if len(@tel) = 10 begin
      if left(@tel,2) = ''09'' begin
       if exists(select serie from serieschi where cld=substring(@tel,3,1) and serie = substring(@tel,5,3)) begin
        return @tel
       end
       else begin
        return ''E_'' + @tel
       end
      end

     end
    end
    --Termina Chile

    if @pais = 6 begin --Empieza Venezuela
     select @lon = len(@tel)
     if @lon = 7  begin
      set @tel = @cldLocal + @tel
     end

     select @tel = right(@tel, 10)

     if len(@tel) = 10 begin
      select @ld = left(@tel,3)
      select @mod = tipo from seriesVen where left(@tel,3) = LD

      if @mod = ''CPP'' begin
       if exists( select * from seriesVen where LD = @ld ) begin
        if @ld = @cldLocal begin
         select @tel = right(@tel,7)
        end
        else begin
         select @tel = ''0'' + @tel
        end
       end
       else begin
        select @tel = ''E_'' + @tel
       end
      end
      else begin
       if @mod = ''FIJO'' begin
        if exists( select serie from seriesVen where serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [Inicio] and [Fin]) begin
         if @ld = @cldLocal begin
          select @tel = right(@tel,7)
         end
         else begin
          select @tel = ''0'' + @tel
         end
        end
        else begin
         select @tel = ''E_'' + @tel
        end
       end
       else begin
        select @tel = ''E_'' + @tel
       end
      end
     end
     else begin
      if len(@tel) > 0 begin
       select @tel = ''E_'' + @tel
      end
     end
     return @tel
    end --Termina Venezuela

    if @pais = 7 begin -- Empieza UK
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     if left(@tel, 1) = ''E'' begin -- regresa error por longitud
      return @tel
     end
     select @lon = len(@tel)

     --numeros no geograficos
     if (left(@tel, 2) in(''03'', ''07'', ''09'') and @lon <> 11) or (left(@tel, 3) in(''055'', ''056'', ''070'') and @lon <> 11) begin
      return ''E_'' + @tel --error por longitud con lada correcta
     end
     else begin
      if left(@tel, 7) in(''0845464'') or left(@tel, 5) = ''07624'' or left(@tel, 4) in(''0500'', ''0800'') or left(@tel, 3) in(''055'', ''056'', ''070'', ''76'') or left(@tel, 2) in(''03'', ''07'', ''08'', ''09'') begin
       return @tel; --longitud correcta y numero no geografico
      end
     end

     --numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
     if (left(@tel, 7) in(''0159575'', ''0159576'')) or
      (left(@tel, 5) in(''02820'',''02821'',''02825'',''02827'',''02828'',''02829'',''02830'',''02837'',''02838'',''02840'',''02841'',''02842'',''02843'',''02844'',''02866'',''02867'',''02868'',''02870'',''02871'',''02877'',''02879'',''02880'',''02881'',''02882'',''02885'',''02886'',''02887'',''02889'',''02890''
,''02891'',''02892'',''02893'',''02894'',''02895'',''02897'') and @lon = 11) or --claves 2xxx tienen formato 4-6
      (left(@tel, 4) in(''0113'', ''0114'',''0115'',''0116'',''0117'',''0118'',''0121'',''0131'',''0141'',''0151'',''0161'',''0238'',''0239'') and @lon = 11) or --3-digit area codes have 7-digit subscribers.
      (left(@tel, 3) in(''020'',''024'',''029'') and @lon = 11) begin --2-digit area codes have 8-digit subscribers.
      return @tel;
     end

     --numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
     if left(@tel, 2) = ''01'' begin
      select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,4) --mayor numero de ladas (va primero por ser mas probable)
      if @ld > 0 begin
       return @tel;
      end
      else begin
       select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,5) --ladas restantes
       if @ld > 0 begin
        return @tel;
       end
      end
     end --si no encontro ni error ni coincidencia entonces esta mal
     return ''E_'' + @tel
    end --Termina UK

    if @pais = 8 begin --Empieza Arabia Saudita
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     select @lon = len(@tel)
     if @lon = 7 begin
      set @tel = ''0'' + @cldLocal + @tel
     end
     select @lon = len(@tel)

     if @lon = 9 begin
      if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,2) = cld) begin
       if (substring(@tel,2,1) = @cldLocal)
       begin
        return right(@tel,7)
       end else begin
        return @tel
       end
      end
      else begin
       return ''E_'' + @tel
      end
     end
     if @lon = 10 begin
      if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,4,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,3) = cld) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end
     if @lon = 11 begin
      if exists(select regiones,* from seriesSA where right(@tel,6) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 6 and left(@tel,2) = cld) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end
    end --Termina Arabia Saudita

    if @pais = 9
     begin --Empieza Australia
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      select @lon = len(@tel)

      if left(@tel,1) <> ''E''
       begin
        if exists(select Regiones
            from SeriesAU
            where convert(int,LD) = convert(int,substring(@tel, 1, 2))
            and convert(int,AreaCode) = convert(int,substring(@tel, 3, 2))
            and convert(int,substring(@tel, 5, 6)) between convert(int,SerieInicio) and convert(int,SerieFin))
         begin
          return @tel
         end
        else
         begin
          return ''E_'' + @tel
         end
       end
      else
       begin
        return @tel
       end
     end --Termina Australia

    if @pais= 10
     begin -- Inicia Brasil
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      select @lon = len(@tel)
      if left(@tel,1) <> ''E''
       begin
        if @lon in (8,9) begin --numero local
         if exists(
         select Regiones
          from seriesBR where
           convert(int,AreaCode) = convert(int,@cldLocal) and
           convert(int,@tel) between convert(int,SerieInicio) and convert(int,SerieFin)
         )
         begin
          return @tel
         end
         else begin
          return ''E_'' + @tel
         end
        end
        if @lon in (10,11) begin --numero nacional
         if exists(
         select Regiones
          from seriesBR where
           convert(int,AreaCode) = convert(int,left(@tel,2)) and
           convert(int,right(@tel, @lon-2)) between convert(int,SerieInicio) and convert(int,SerieFin)
         )
         begin
          return @tel
         end
         else begin
          return ''E_'' + @tel
         end
        end
       end

      else begin
       return @tel
      end
     end -- Termina Brasil

    if @pais= 11
     begin -- Inicia Guatemala
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      if left(@tel,1) <> ''E''
       begin
        if exists(select zonaGeografica from seriesGT (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
         return @tel
        else
         return ''E_'' + @tel
       end
      else
       return @tel
     end -- Termina Guatemala

     if @pais= 12
     begin -- Inicia Costa Rica
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      if left(@tel,1) <> ''E''
       begin
        if len(@tel)=8
         if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
          return @tel
         else
          return ''E_'' + @tel
        else if len(@tel)=10 begin
         if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,3) and right(@tel, 7) between rangoInicio and rangoFinal)
          return @tel
         else
          return ''E_'' + @tel
        end
        else
         if charindex(substring(@tel,1,2),''00,08'') <= 0
          return ''E_'' + @tel
         else
          return @tel
       end
     end -- Termina Costa Rica

    if @pais= 13
     begin -- Inicia Salvador
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      if left(@tel,1) <> ''E''
       begin
        if len(@tel)=8
         if exists(select zonaGeografica from seriesSV (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
          return @tel
         else
          return ''E_'' + @tel
        else
         if charindex(substring(@tel,1,2),''00'') <= 0
          return ''E_'' + @tel
         else
          return @tel
       end
     end -- Termina Salvador

    if @pais= 14
     begin -- Inicia Spain
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      if left(@tel,1) <> ''E''
       begin
        if len(@tel)=9
         if exists(select provincia from seriesEsp (nolock) where indicativo = substring(@tel,1,1) and right(@tel, 8) between numInicial and numFinal)
          return @tel
         else
          return ''E_'' + @tel
        else
         if charindex(substring(@tel,1,2),''00'') <= 0
          return ''E_'' + @tel
         else
          return @tel
       end
     end -- Termina Espa?a

    if @pais= 15 begin --Inicia Peru
     select @tel = dbo.Completa(@tel, @pais, @cldLocal)
     select @lon = len(@tel)
     if @lon between 6 and 7 begin
      set @tel = @cldLocal + @tel
     end
     select @tel = right(@tel, 9)
     select @lon = len(@tel)
     if left(@tel,1) <> ''E'' begin
      if @lon = 9 begin
       if exists(select zonaGeografica from seriesPE (nolock) where
        left(@tel,1) = 9 or
        substring(@tel,2,1) = 1 and areaNumeracion = 1 and right(@tel, 7) between rangoInicio and rangoFinal or
        substring(@tel,2,1) <> 1 and left(@tel,2) = areaNumeracion and right(@tel, 7) between rangoInicio and rangoFinal
       )
        return @tel
       else
        return ''E_'' + @tel
      end
     end
    end --Termina Peru

  if @pais = 16 begin --Panama
    select @tel = dbo.completa(@tel, @pais, @cldLocal)
     if left(@tel,1) <> ''E''
     begin
      if len(@tel)=7 begin -- Local
       if(substring(@tel,1,1) != ''6'') begin
        if exists(select zonaGeografica from seriesPa (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
       return @tel
      else
       return ''E_'' + @tel
       end
       else
        return ''E_'' + @tel
      end
      if len(@tel)=8 begin --Celular
       if(substring(@tel,1,1) = ''6'') begin
        if exists(select zonaGeografica from seriesPa (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
         return @tel
      else
       return ''E_'' + @tel
       end
       else
        return ''E_'' + @tel
      end
      else begin
       if charindex(substring(@tel,1,2),''00'') <= 0
        return ''E_'' + @tel
       else
        return @tel
      end
     end
  end

    return @tel
   end'
        EXEC(@Sql)

        set @process = 'CW-2195 Version 120.22 Alter FUNCTION VerificaRegionLocalidad'
        set @Sql= 'ALTER FUNCTION [dbo].[VerificaRegionLocalidad](@tel varchar(32),@pais tinyint = 0, @cldLocal varchar(7) = '''')
RETURNS @retVRL TABLE
(
    tel varchar(32) PRIMARY KEY NOT NULL,
    region varchar(32) NULL,
    localidad varchar(32) NULL
)
 BEGIN
 declare @ld varchar(7)
 declare @lon tinyint 
 declare @lonLd tinyint 
 declare @region varchar(20)
 declare @localidad varchar(20) 
 declare @serie varchar(4)
 
 select @region='''',@localidad=''''

 if (@pais = 0 and @cldLocal = '''') begin
	select @pais = valor from ccSettings with(nolock) where setting_id = 104
	select @cldLocal = valor from ccSettings with(nolock) where setting_id = 17
end

 select @tel = dbo.limpia(@tel)

if @pais = 1 begin --Empieza Mexico
	select @lon = len(@tel)
	if @lon in(7,8) begin
		set @tel = @cldLocal + @tel
		set @ld=@cldLocal
	end	
	
	select @tel = right(@tel, 10)
	select @lon = len(@tel)	
  if @lon = 10 begin		
	
		if @ld is null begin
			if(exists(select top 1 cld from series nolock where cld=left(@tel,2)))begin
				select @ld = left(@tel,2)			
			end
			else if(exists(select top 1 cld from series nolock where cld=left(@tel,3)))  begin
				select @ld = left(@tel,3)			
			end
		end

		if @ld is not null begin
			set @lonLd=len(@ld)		
			set @serie=substring(@tel,len(@ld)+1,case @lonLd when 2 then 4 else 3 end)		
			select top 1 @region = estado, @localidad = municipio from series nolock where cld=@ld and SERIE=@serie
		end
		else begin
			select top 1 @region = estado, @localidad = municipio from series nolock where cld=@cldLocal
		end

	end
   else  begin
		if (@region is null) begin
			select top 1 @region = estado from series nolock where cld=@cldLocal
		end		
	end
end --Termina Mexico

  INSERT @retVRL
        SELECT @tel as phone, @region as estado, @localidad as municipio
  RETURN

end'
        EXEC(@Sql)

       

				
		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix 

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
