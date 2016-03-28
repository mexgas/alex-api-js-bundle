/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Perez
Date: 2016/04/11
Description:



Database: CCenterRia
Required version: 119.01

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
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 118 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 118 sin fix
set @versionfix = 2
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and actualVersionFix = versionfix-1
	begin
		begin tran
		begin try

		set @process = 'INSERT -------- ccMenus'
		set @sql ='if not exists(select * from ccmenus where type=3 and menu_id in(4220, 4230, 4240)) begin
						insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, [type], HelpSWF, release ) values (4220, ''Reporte de teléfonos por estado de la república|Telephone report ordered by republic states'', 4000, ''B'', 4, 3, '''', ''60b188045ce43b6a1d77f7a81f67767fc90fbef71d57e4498d362c5c67a3c097d076f2f127f0f7af01beda4ac36008993c52871865dfbcc8d37183f0a429089f59ae97a60b9d269449063e6d38f93222a414d69d2a3fb7b721155619d8e6b4e2'')
						insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, [type], HelpSWF, release ) values (4230, ''Reporte de Número de Teléfonos por Registro por Lista|Telephone Report per Registry List'',  4000, ''B'', 4, 3, '''',''074a6cc91623e51a5020bb702fad033d304b666112d87ff90249fb8676ec86395611c16cf4e162ebabf8555caeea9365241fede8508032e858587c216da52aa9fea8e00d5e2f12006bb1564615249179bb0886e83a3aa729313cdd7fcd79cf35'')
						insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, [type], HelpSWF, release ) values (4240, ''Reporte de resultados de marcación|Dialing Result Report'', 4000, ''B'', 4, 3, '''', ''9cf7679f1b10838b63e4eae2368159813ae5d3eecaf4bccecfb21a247080897dc3e3d80988c85c0931f5a2fe77da619d446f04bcc6ff01e8247b5531a00ded6b'')
				   end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -------- mcaTipoLlamada'
		set @sql='if not exists (select * from sys.tables where name = N''mcaTipoLlamada'') begin
					CREATE TABLE [dbo].[mcaTipoLlamada](
					[tipoLlamada_id] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
					[descrip] [varchar](30) NOT NULL,
					CONSTRAINT [PK_mcaTipoLlamada] PRIMARY KEY CLUSTERED 
					(
					[tipoLlamada_id] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					) ON [PRIMARY]
				 end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -------- mcaProtocolos'
		set @sql='if not exists (select * from sys.tables where name = N''mcaProtocolos'') begin
					CREATE TABLE [dbo].[mcaProtocolos](
					[protocolo_id] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
					[descrip] [varchar](30) NOT NULL,
					[nota] [varchar] (max)
					CONSTRAINT [PK_mcaProtocolos] PRIMARY KEY CLUSTERED 
					(
					[protocolo_id] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					) ON [PRIMARY]
				 end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -------- mcaProveedores'
		set @sql='if not exists (select * from sys.tables where name = N''mcaProveedores'') begin
					CREATE TABLE [dbo].[mcaProveedores](
					[provedor_id] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
					[descrip] [varchar](30) NOT NULL,
	
					CONSTRAINT [PK_mcaProveedores] PRIMARY KEY CLUSTERED 
					(
					[provedor_id] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON,  FILLFACTOR = 100) ON [PRIMARY]
					) ON [PRIMARY]
				 end'
		EXEC(@sql)

		set @process = 'CREATE TABLE --------mcaPlanMarcacion'
		set @sql='if not exists (select * from sys.tables where name = N''mcaPlanMarcacion'') begin
					CREATE TABLE [dbo].[mcaPlanMarcacion](
					[country_id] [smallint] NOT NULL,
					[provedor_id] [smallint] NOT NULL,
					[protocolo_id] [smallint] NOT NULL,
					[tipoLlamada_id] [smallint] NOT NULL,
					[prefijo] [varchar](15) NOT NULL,
					[longitud] [varchar](15) NULL
					CONSTRAINT [PK_mcaPlanMarcacion] PRIMARY KEY CLUSTERED 
					(
						[country_id], [provedor_id], [protocolo_id], [tipoLlamada_id] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					) ON [PRIMARY]
				  end'
		EXEC(@sql)

		set @process = 'INSERT -------- mcaTipoLlamada'
		set @sql='if not exists(select * from mcaTipoLlamada where tipoLlamada_id in(1, 2, 3, 4)) begin
					insert into mcaTipoLlamada (descrip) values (''Local'')
					insert into mcaTipoLlamada (descrip) values (''LD Nacional'')
					insert into mcaTipoLlamada (descrip) values (''Cel'')
					insert into mcaTipoLlamada (descrip) values (''Cel LD'')
				 end'
		EXEC(@sql)

		set @process = 'INSERT -------- mcaProveedores'
		set @sql='USE [CCenterRia]
					GO
					SET IDENTITY_INSERT [dbo].[mcaProveedores] ON 
					if not exists(select * from mcaProveedores where provedor_id in(1, 2, 3)) begin
					INSERT [dbo].[mcaProveedores] ([provedor_id], [descrip]) VALUES (1, N''Maxcom'')
					INSERT [dbo].[mcaProveedores] ([provedor_id], [descrip]) VALUES (2, N''Marcatel'')
					INSERT [dbo].[mcaProveedores] ([provedor_id], [descrip]) VALUES (3, N''Telmex'')
				 end'
		EXEC(@sql)

		set @process = 'INSERT -------- mcaProtocolos'
		set @sql='USE [CCenterRia]
					GO
					SET IDENTITY_INSERT [dbo].[mcaProtocolos] ON 
					if not exists(select * from mcaProtocolos where protocolo_id in(1, 2, 3, 4, 5)) begin
					INSERT [dbo].[mcaProtocolos] ([protocolo_id], [descrip]) VALUES (1, N''ISDN sin ANI Rotatorio'')
					INSERT [dbo].[mcaProtocolos] ([protocolo_id], [descrip], [nota]) VALUES (2, N''ISDN con Ani Rotatorio'', ''En las ciudades con LADA donde Maxcom tiene numeración los números celulares van como locales, para las ciudades Monterrey, GDl y DF solo se toman 2 dígitos de la lada'')
					INSERT [dbo].[mcaProtocolos] ([protocolo_id], [descrip]) VALUES (3, N''SIP sin Ani Rotatorio'')
					INSERT [dbo].[mcaProtocolos] ([protocolo_id], [descrip], [nota]) VALUES (4, N''SIP con Ani Rotatorio'', ''En las ciudades con LADA donde Maxcom tiene numeración los números celulares van como locales, para las ciudades Monterrey, GDl y DF solo se toman 2 dígitos de la lada'')
					INSERT [dbo].[mcaProtocolos] ([protocolo_id], [descrip]) VALUES (5, N''R2'')
					SET IDENTITY_INSERT [dbo].[mcaProtocolos] OFF
				 end'
		EXEC(@sql)

		set @process = 'INSERT -------- mcaPlanMarcacion'
		set @sql='if not exists(select * from mcaPlanMarcacion where protocolo_id in(1, 2, 3, 4, 5) and tipoLlamada_id in (1, 2, 3, 4, 5)) begin
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 1, 1, ''%'', ''7'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 2, 1, ''%'', ''10'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 3, 1, ''%'', ''10'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 4, 1, ''%'', ''10'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 5, 1, ''%'', ''7'')

					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 1, 2, ''01%'', ''12'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 2, 2, ''%'', ''10'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 3, 2, ''01%'', ''12'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 4, 2, ''%'', ''10'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 5, 2, ''01%'', ''12'')

					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 1, 3, ''044%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 2, 3, ''044%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 3, 3, ''044%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 4, 3, ''044%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 5, 3, ''044%'', ''13'')

					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 1, 4, ''045%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 2, 4, ''045%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 3, 4, ''045%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 4, 4, ''045%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 1, 5, 4, ''045%'', ''13'')

					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 2, 3, 1, ''%'', ''10'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 2, 3, 2, ''01%'', ''12'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 2, 3, 3, ''044%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 2, 3, 4, ''045%'', ''13'')

					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 3, 5, 1, ''%'', ''7'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 3, 5, 2, ''01%'', ''12'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 3, 5, 3, ''044%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud) 
					values (1, 3, 5, 4, ''045%'', ''13'')
				 end'
		EXEC(@sql)


		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
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
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ''', version to release: ''' + cast(@version as varchar(5))
	end

set nocount off