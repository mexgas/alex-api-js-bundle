/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Armando Rodriguez, 
Date: 2017/10/16
Description:
	*se modifica SP ccsp_limpia para aceptar marcacion a 10 digitos para llamadas locales, LD, celular y celular LD.
	*

Database: CCenterRia
Required version: 119.09-2

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

set @version = 119--**********actualizar a 119 sin fix
set @versionfix = 93
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and (@actualVersionFix = @versionfix-1)
	begin
		begin tran
		begin try

	set @process = 'ALTER procedure ccsp_Limpia   -- CW-1186'
		set @Sql= 'ALTER procedure [dbo].[ccsp_Limpia]
			@tel varchar(30),
			@Camp int = 0
			as
			set nocount on
			declare @lon tinyint, @ld varchar(4), @pais varchar(3), @extLen smallint, @manOpt smallint
			select @tel = dbo.limpia(@tel)
			select @lon = len(@tel)
			select @pais = valor from ccSettings with(nolock) where setting_id = 104
			select @ld = valor from ccSettings with(nolock) where setting_id = 17
			select @extLen = valor from ccsettings with(nolock) where setting_id = 108
			select @manOpt = valor from ccsettings with(nolock) where setting_id = 195
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
				 	if @manOpt = 1 --10 digits
					begin
						select 0 as res, @tel as tel
					end
					else
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
						select 0 as res, @tel as tel
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
			'
    	EXEC(@Sql)
    	
    	set @process = ''
		set @Sql= ''
    	EXEC(@Sql)
		
    	
    	set @process = ''
		set @Sql= ''
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