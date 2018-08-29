/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: 
		
Date: 2018/08/21
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

set @version = 120
set @versionfix = 24


/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 15
	begin
		begin tran
		begin try

		set @process = 'CW-1869 Med Fase 2 Alter column cal_telefono en ccocallsoutsource'
		set @Sql= 'if exists (select * from sys.columns where name = N''cal_telefono'' and Object_ID = Object_ID(N''ccocallsoutsource''))
	    begin
	      alter table ccocallsoutsource alter column cal_telefono varchar(30)
	    end'
		EXEC(@Sql)
	


		set @process = 'CW-1869 Med Fase 2 Alter setting 202 bLoadSettings = 1'
		set @Sql= '
			if exists (select * from ccSettings where setting_id = 202 )begin
			update ccSettings set bLoadSettings = 1 where setting_id = 202
			end
		'
		EXEC(@Sql)


		set @process = 'CW-1682 Permiso Exportación Finder'
		set @Sql= 'if not exists(select * from ccRIACat_AdminPermissions where per_id = 11 ) 
		begin
			insert into ccRIACat_AdminPermissions(per_desc,bStatus,release) 
			values(''Enviar y extraer archivos|Email and transfer files'',1,''f497d327698765762eea6d10a29f4b5168ff1469c6135b2a88aa48ea7404aeada5a285c1899dcea00a01033056a22f68effdc7bfba4357cc070ea32c48287a9c'')
		end'
		EXEC(@Sql)

		
		set @process = 'CW-1869 Med Fase2 insert Setting 206'
		set @Sql= 'if not exists(select * from ccSettings where setting_id = 206 ) 
		begin
		insert ccSettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) 
		values (206,1,''Deshabilita validaciones en la llamada manual'',1,''X'',
		''0 - Realiza las validaciones de marcacion normalmente / 1 - marca el numero sin validarlo'',''Quita validaciones de la llamada manual'',1,''.*'')
		end'
		EXEC(@Sql)
		

		set @process = 'CW-1508	Etiquetas En ingles incorrecta'
		set @Sql= 'update ccmenus set menu_descrip=''Respuestas(Encuestas de Satisfacción)|AnswersCustomerSatisfactionSurvey''
				where menu_id=8083 and type=3'
		EXEC(@Sql)


		set @process = 'CW-1869 med fase 2 alter SP de Limpia'
		set @sql = '
			ALTER procedure [dbo].[ccsp_Limpia]
			@tel varchar(30),
			@Camp int = 0
			as
			set nocount on
			declare @lon tinyint, @ld varchar(4), @pais varchar(3), @extLen smallint, @manOpt smallint, @validateTel smallint
			select @tel = dbo.limpia(@tel)
			select @lon = len(@tel)
			select @pais = valor from ccSettings with(nolock) where setting_id = 104
			select @ld = valor from ccSettings with(nolock) where setting_id = 17
			select @extLen = valor from ccsettings with(nolock) where setting_id = 108
			select @manOpt = valor from ccsettings with(nolock) where setting_id = 195
			select @validateTel = valor from ccsettings with(nolock) where setting_id = 206


			if @validateTel = 1
			begin
				select 1 as res, @tel as tel
				return(0) 
			end 			

			declare @telTemp as varchar(15)

			if @extLen=@lon and @lon>1
			 begin
				select 0 as res, @tel as tel -- Extension
				return(0)
			 end

			if @pais = 1
			 begin
				if @lon = 3 and @tel = ''911''
				begin
					select 4 as res, @tel as tel
					return(0)
				end

				if @lon < 7 or @lon = 7 and len(@ld) = 2 or @lon = 8 and len(@ld) = 3 or @lon in (9, 11) or @lon > 13
				 begin
					select 1 as res, @tel as tel --Longitud invalida
					return(0)
				 end

				if @lon = 12 and left(@tel, 2) <> ''01'' or @lon = 13 and left(@tel, 3) <> ''044'' and left(@tel, 3) <> ''045'' and left(@tel, 3) <> ''001''
				 begin
					select 2 as res, @tel as tel--Digitos incorrectos
					return(0)
				 end

				if left(@tel, 3) = ''001''
				 begin
					select 0 as res, @tel as tel
					return(0)
				 end

				declare @mod varchar(5)
				select @tel = case when @lon in (7, 8) then @ld + @tel else right(@tel, 10) end
				select @mod = modalidad from series where cld + serie = left(@tel, 6) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

				if exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra))
				on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
				 begin
					select 4 as res, @tel as tel
					return(0)
				 end

				if @mod = ''CPP''
				 begin
					select 0 as res, case left(@tel, len(@ld)) when @ld then ''044'' else ''045'' end + @tel as tel
					return(0)
				 end

				if @mod in (''FIJO'', ''MPP'')
				 begin
					if @manOpt = 1 --10 digits
					begin
						set @lon = len(@tel)
						if @lon = 10 - len(@ld)
							set @tel = @ld + @tel

						if @lon = 12 and left(@tel, 2) = ''01''
							set @tel = right(@tel, 10)
						select 0 as res, @tel
					end
					else
						select 0 as res, case left(@tel, len(@ld)) when @ld then right(@tel, 10 - len(@ld)) else ''01'' + @tel end as tel
					return(0)
				 end

				--if @mod is null
				select 3 as res, @tel as tel--No encontrado
				return(0)
			 end

			if @pais = 2
			 begin
				select @telTemp = @tel
				set @tel = dbo.completa(@tel, @pais, @ld)
				if left(@tel,1)=''E'' begin
					select 1 as res, @telTemp --Longitud Invalida
					return
				end

				select @tel = dbo.fnClearPhoneArg(@tel)

				if (len(@tel) = 10 or len(@ld + @tel) = 10) and left(@tel,1) <> ''E'' begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and (telefono = @tel or telefono= @ld + @tel) and status=1)
				   begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					end else begin
						select 4 as res, @tel
						return(0)
					end
				end else begin select 2 as res, @telTemp as tel end --Digitos incorrectos
			 end

			if @pais = 3
			 begin
				select @telTemp = @tel
				if @lon < 7 or @lon = 9 or (@lon = 10 and  left(@telTemp,1) <> ''3'') or (@lon = 11 and  left(@telTemp,2) <> ''03'') begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				end
				select @tel = dbo.Completa_ListaNegra(@tel)

				if (len(@tel) = 8 or len(@tel) = 10) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 4
			 begin
				exec ccsp_LimpiaUsa @tel, @Camp
				return(0)
			 end

			if @pais = 5
			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)

				if len(@tel) in(8,9) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 6
			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)


				if len(@tel) = 10 and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 7

			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)

				if (len(@tel) = 9 or len(@tel) = 10) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin

						select @tel = dbo.verifica(@tel)
						if left(@tel,1)=''E'' begin
							select 3 as res, @telTemp -- No existe el telefono
						end
						else begin
							select 0 as res, @telTemp  -- Todo Bien
						end
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel --lista negra
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end


			if @pais = 8
			 begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)

				if left(@tel,1)=''E'' begin
					select 1 as res, @telTemp --Longitud Invalida
					return (0)
				end

				if (len(@tel) = 9 or len(@tel) = 10 or len(@tel) = 11 )
				begin
					if not exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra)) on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					end
					else
					begin
						select 4 as res, @tel
						return(0)
					end
				end
			 end

			if @pais = 9 --Australia
			 begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)

				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			 end

			if @pais = 10 -- Brasil
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				set @lon = len(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 11 -- Guatemala
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 12 -- Costa Rica
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 13 -- Salvador
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 14 -- Spain
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end


			if @pais = 16 -- Panama
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end



		'




		set @process = 'CW-2016 --Ver en Finder solo los grupos de trabajo alter ccsp_BaseXmngr'
		set @Sql= '
		ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
		@action int,
		@option tinyint = 0,
		@ids varchar(max)=null,
		@name varchar(25) = NULL,
		@top varchar(max) = NULL,
		@dateIni datetime =null,
		@dateEnd datetime =null,
		@dateStart dateTime= null,
		@userId int = 0
		AS
		declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
		declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
		declare @status tinyint
		set @sql = ''''
		--nota: las acciones 3 y 4 hacerlas para casos dinamicos, (i.e.) si se va controlor por tamaño y asignar un xml nuevo, conusltar Daniel de CW :)

		if @action in (1,6) begin --obtiene los nodos a insertar en BX
		  if @action = 1 set @status =0
		  else if @action = 6 set @status = 2

		  if @option = 1 begin
		    set @tableName=''ccChatsNode''
		    set @columnId=''chatId''
		    set @tableNameHistory = ''ccChatsNodeHistory''
		  end
		  else if @option = 3 begin
		    set @tableName=''ccEmailNode''
		    set @columnId=''emailId''
		    set @tableNameHistory = ''ccEmailNodeHistory''
		  end
		  else if @option = 4 begin
		    set @tableName=''ccTwitterNode''
		    set @columnId=''conversationTwitterId''
		    set @tableNameHistory = ''ccTwitterNodeHistory''
		  end
		  if @option in (1,3,4) begin

		    declare @auxTag nvarchar(4)
		    select @auxTag =case when @option = 1 then ''@C09''
		               when @option in (3,4) then ''@C02''
		            end

		    set @sql=''declare @basexName varchar(max)

		select @basexName=Xname from ccBaseXDB where serviceId=''+cast(@option as nvarchar(3))+'' and isFull=0;

		    with node ( ''+@columnId+ '',xmlString,dateNode)
		    AS(
		      select top ('' + @top + '') ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
		      ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
		      from ''+ @tableName + '' A with(rowlock)
		      where A.status ='''''' + cast(@status as nvarchar(3)) +''''''
		      union
		      select top ('' + @top + '') ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
		      ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
		      from ''+ @tableNameHistory + '' A with(rowlock)
		      where A.status ='''''' + cast(@status as nvarchar(3)) +''''''   )

		    select node.''+@columnId+ '',node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
		    left join ccBaseXDB baseX on baseX.serviceId= ''++ cast(@option as nvarchar(3)) + '' and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
		    order by baseX.Xname''

		    --print(@sql)
		    exec(@sql)
		  end
		end
		else if @action in (2,7) begin--actualiza los nodos insertados en BX
		  if @action = 2 set @status =0
		  else if @action = 7 set @status = 2

		  set @sql = ''update ''+@tableName+'' with(rowlock) set [status] = ''+cast(@status as varchar(max))+''+ 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'' and [status] = ''+cast(@status as varchar(max))
		  exec(@sql)
		  set @sql = ''update ''+@tableNameHistory+'' with(rowlock) set [status] = ''+cast(@status as varchar(max))+''+ 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'' and [status] = ''+cast(@status as varchar(max))
		  exec(@sql)

		end
		else if @action = 3 --trae el nombre de la base de datos en BX
		begin
		  select Xname from ccBaseXDB where serviceId = @option and isFull=0
		end
		else if @action = 4 --inserta el nombre del xml en BX
		begin
		  insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option,@dateStart, @name,0)
		end
		else if @action = 5 begin --obtener servicios disponibles
		  select @chat= 0,@rec= 2,@email= 0,@twitter=0
		  select @chat = case when valor > 1 then 1 else 0 end from ccSettings where setting_id = 145
		  select @email = case when valor = 1 then 3 else 0 end from ccSettings where setting_id = 155
		  select @twitter = case when valor = 1 then 4 else 0 end from ccSettings where setting_id = 173
		  select id, ref  from ccFinderServices where id in (@chat, @rec, @email,@twitter)

		end
		else if @action = 8 begin--trae la lista de las bases para la busqueda
		  select Xname from ccBaseXDB where serviceId = @option
		   and (

		    @dateIni between dateStart and dateEnd
		    or @dateEnd between dateStart and dateEnd
		    or dateStart between @dateIni and @dateEnd
		  )
		  union
		  select Xname from ccBaseXDB where serviceId = @option and isFull=0
		   and (
		     dateStart between @dateIni and @dateEnd
		     or @dateIni>=dateStart

		  )
		end
		else if @action = 9 begin--Cierra la base datos
		  update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()) where serviceId= @option and  isfull = 0 and dateEnd is null
		end

		else if @action = 10 begin
			declare @filterWg varchar(max)
			declare @len int
			set @filterWg=''''
		 
			 select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
			 inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
			 where Wguser.User_id=@userId
		 
			 set @len=len(@filterWg)- CHARINDEX(''ro )'', REVERSE(@filterWg))
			 select SUBSTRING(@filterWg,0, @len)
		end


		else if @action = 11 begin--trae el nombre de la base de datos en BX

			if @option =1 begin
			SELECT isnull(ISNULL(min(node.value(''(/R01/@CDATE)[1]'',''datetime'')),min(node.value(''(/R01/@C09)[1]'',''datetime''))),GETDATE()) as node FROM ccChatsNode where status = 0
			end
			if @option =3 begin
			SELECT isnull(ISNULL(min(node.value(''(/R03/@CDATE)[1]'',''datetime'')),min(node.value(''(/R03/@C02)[1]'',''datetime''))),GETDATE()) as node FROM ccEmailNode where status = 0
			end
			if @option =4  begin
			SELECT isnull(ISNULL(min(node.value(''(/R04/@CDATE)[1]'',''datetime'')),min(node.value(''(/R04/@C02)[1]'',''datetime''))),GETDATE()) as node FROM ccTwitterNode where status = 0
			end

		end
   '
    EXEC(@Sql)

		
		set @process = 'CW-1869 Med Fase 2 Alter cSP ccsp_AGENTInsertCallOut'
		set @Sql= '
ALTER PROCEDURE [dbo].[ccsp_AGENTInsertCallOut]
@cam_id smallint,
@cal_Key varchar(20),
@cal_Telefono varchar(30),
@user_id int,
@cal_extension varchar(7),
@sData varchar(255) = '''', --HLAS para guardar notas de la llamada
@existCallOut as int = 0,
@callmode as smallint = 0
AS
set 
nocount on
declare @fecha as datetime, @callout_id as int, @cal_id as int, @calloutMaxTime as int
select @fecha=getdate()
declare @dialPrefix integer
select @dialPrefix = valor from ccSettings where setting_id = 202

if @callmode = 1 begin
	INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
	select @existCallOut, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 0, @cal_extension
	select @cal_id = scope_identity()

	insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
	select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
	from ccRIACampEspWG wg 
	where wg.tipo = 1 and wg.idcampesp =@cam_id

	select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
	select @existCallOut as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
  return(0)
end

if @existCallOut=0  begin
	declare @prefijoMarcacion varchar(100) 
	set @prefijoMarcacion = ''''
	declare @LasCallKey varchar(20)
	set @LasCallKey = @cal_Key
	declare @settingCallKey as int
	select @settingCallKey = valor from ccSettings where setting_id = 194
  
	if(@settingCallKey = 1) begin
		if (@cal_Key='''' or @cal_Key is null) begin   
			select top 1 @LasCallKey=cal_Key from ccoCallsOut where cam_id=@cam_id and cal_Inicio>=convert(datetime,getdate()) and cal_manual=0 order by cal_id desc
			set @cal_Key= @LasCallKey
		end
	end

	if @dialPrefix = 1 and len(@cal_telefono)>20
		begin
			set @prefijoMarcacion = LEFT(@cal_telefono ,len(@cal_telefono)-10)
			set @cal_telefono = RIGHT(@cal_telefono,10)		
		end
	else 
		begin
			set @prefijoMarcacion =''''			 
		end
	
	INSERT ccocallsoutsource (cal_key, cam_id, cal_telefono, cal_status, user_id, cal_fechaDial, dato1,dialPrefix)
	select @cal_Key, @cam_id, substring(@cal_Telefono, 1, 19), 6, @user_id, @fecha, @sData,@prefijoMarcacion
	select @callout_id = scope_identity()

	INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
	select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension
	select @cal_id = scope_identity()

	
 end

else begin --@existCallOut<>0
	Update ccocallsoutsource set cam_id=@cam_id, cal_telefono=substring(@cal_Telefono, 1, 19), dato1=@sData where callout_id = @existCallOut	
	Update ccocallsout set cam_id=@cam_id, cal_telefono=@cal_Telefono where callout_id = @existCallOut
	
	set @callout_id = @existCallOut

	select top 1 @cal_id=cal_id from ccocallsout where callout_id = @callout_id order by cal_id desc
	
	if exists(select * from ccoLogDials where cal_id=@cal_id) begin
		INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
		select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension
		select @cal_id = scope_identity()
	end
	 
 end
	
insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
from dbo.ccRIACampEspWG wg 
where wg.tipo = 1 and wg.idcampesp =@cam_id


select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
select @callout_id as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
return(0)
set nocount off
		'
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
