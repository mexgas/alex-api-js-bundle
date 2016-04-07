
/*
Fecha: 2014/05/12
Descripcion: 	
	Se agrega cambio en stored trsp_AdmVerifyMarksToExport para validar marcas de Agentes 
	Se agrega cambio en stored trsp_AdmGetMarkTimeToCut para validar marcas de Agentes
	Se agrega cambio en stored trsp_muevegrabaciones para mejorar su desempeño
Version requerida: 17
*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 18
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

	set @process = 'ALter Table- [trsp_AdmVerifyMarksToExport]'
	set @Sql='
		ALTER PROCEDURE  [dbo].[trsp_AdmVerifyMarksToExport]
		-- Add the parameters for the stored procedure here

		@cal_id int,
		@tipo_llamada smallint

		AS
		BEGIN
			
			select count (*) from CCRECORDERRIA.dbo.RIA_MARCAS where 
			call_id = @cal_id and tipo_llamada = @tipo_llamada

		END

	'
	EXEC(@Sql)

	set @process = 'ALter Table- [trsp_AdmGetMarkTimeToCut]'
	set @Sql='
		ALTER PROCEDURE [dbo].[trsp_AdmGetMarkTimeToCut]
		-- Add the parameters for the stored procedure here

		@cal_id int,
		@tipo_llamada smallint


		AS
		BEGIN

			select top 1 isnull(marca,''00:00:00'') from CCRECORDERRIA.dbo.RIA_MARCAS 
			where call_id = @cal_id and tipo_llamada = @tipo_llamada

		END
	'
	EXEC(@Sql)

	set @process = 'ALter Table- [trsp_muevegrabaciones]'
	set @Sql='
		ALTER PROCEDURE [dbo].[trsp_muevegrabaciones]
		AS
		BEGIN
			declare @fecha datetime

			set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

			SET IDENTITY_INSERT RIA_GRABACIONCONSULTA ON
			
			INSERT INTO [RIA_GRABACIONCONSULTA] (grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,tamano,dni,duracion,pos_pc,extension,razon_id,nombre_archivo,
			info1,info2,info3,info4,info5,borra_id,fvalida,fvalida2,tipo_Llamada,cam_id,calif_id,id_repositorio,id_nivel_grito,cal_id,cal_key,cal_manual,cal_fcallback,cal_extension,
			cal_whoHung,cal_whoRec,id_plantilla,dni_id,id_rep_video,extra_info,extra_info2) 
			SELECT grab_id,cli_id,age_id,puerto_id,tipo_grab_id,age_id_rec,ffin,finicio,ani,tamano,dni,duracion,pos_pc,extension,razon_id,nombre_archivo,info1,info2,info3,info4,
			info5,borra_id,fvalida,fvalida2,tipo_Llamada,cam_id,calif_id,id_repositorio,id_nivel_grito,cal_id,cal_key,cal_manual,cal_fcallback,cal_extension,cal_whoHung,cal_whoRec,
			id_plantilla,dni_id,id_rep_video,extra_info,extra_info2
			FROM [RIA_GRABACION] with(nolock, index(IX_RIA_GRABACION_3)) WHERE [finicio] < @fecha;
			
			SET IDENTITY_INSERT RIA_GRABACIONCONSULTA OFF

			DELETE RIA_GRABACION with(rowlock) WHERE [finicio] < @fecha;
		END
		'
	EXEC(@Sql)



------------------ fin SCRIPT @Sql ------------------
	--Generamos nueva version
	--exec dbo.ccsp_getVersion 'BD', @Version

	-- Updating DB Version
	
 	update trec_parametros set par_valor = @Version where par_id = 30 

	commit tran

	end try	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off


