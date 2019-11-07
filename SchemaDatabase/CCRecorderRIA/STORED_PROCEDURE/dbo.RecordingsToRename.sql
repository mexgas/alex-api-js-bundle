CREATE procedure [dbo].[RecordingsToRename]
@action int,
@cam_id int = 0,
@tipo_llamada int = 0,
@userID int =0,
@oldName varchar(max) ='',
@newName varchar(max) = '',
@cal_id int = 0,
@prefijo varchar(maX) = ''

as
--Trae todas las grabaciones de una campaña que no se han renombrado 
if @action = 1
	begin
		declare @extension varchar(max)
		select @extension =par_valor from trec_parametros where par_id = 54

		declare @Encriptado varchar(max)
		select @Encriptado = case par_valor When 1 then '.enc' when 0 then '' end 
		from trec_parametros where par_id = 15


		select Cast(cal_id as int) Cal_id , Cast(id_repositorio as int) as Id_Repositorio
		,tipo_llamada as Tipo_Llamada ,@extension as Extension,@Encriptado as Encriptado,Cast(cam_id as int) as Cam_Id
		from RIA_GRABACION where cam_id = @cam_id and tipo_llamada = @tipo_llamada and (HasBeenToRename = 0 OR HasBeenToRename IS NULL)
	end
	--registra el cambio de nombre en la base de datos y modifica ria_recnode para que se pueda encontrar la grabacion en el finder
if @action = 2
	begin

		declare @tipo varchar(max)
		select @tipo = SUBSTRING(@oldName,1,1)		
		declare @PrefijocampOrAcd varchar(max)	
			
			select 	@PrefijocampOrAcd
		if @tipo = 'I'  
			begin
				select @PrefijocampOrAcd=prefijo from ccinbound where Inbound_id = @cam_id
			end
		
		if @tipo = 'O'
			begin
				select @PrefijocampOrAcd=prefijo  from cccamps where cam_id = @cam_id 
			end
		
		UPDATE RIA_GRABACION SET Prefijo =@PrefijocampOrAcd, HasBeenToRename = 1 where
		cal_id = @cal_id and tipo_llamada = case @tipo When 'I' then 1 when 'O' then 2 end   
				
	
		declare @grabId varchar(max)
		select @grabId = grab_id from RIA_GRABACION where cal_id = @cal_id and tipo_llamada = case @tipo When 'I' then 1 when 'O' then 2 end 
		
		select 	@grabId
		--AGREGA EL ATRIBBUTO C27 
		declare @resul int
		select @resul = count(node.value('(/R02/@C27)[1]', 'nvarchar(max)'))  from RIA_RecNode where grab_id = @grabId
		if(@resul = 0)
			begin
				UPDATE RIA_RecNode SET node.modify('insert attribute C27 { }  into (/R02)[1]')
				where grab_id = @grabId
			end
		
		--Actualiza el nodo en ria_recnode para que pueda ser consultado
		UPDATE RIA_RecNode 
		SET node.modify('replace value of (/R02/@C27)[1]  with sql:variable("@PrefijocampOrAcd") '),
		status = 2
		where grab_id = @grabId
		
		insert into LogRenameRecording (userID,camId,OldNameRec,NewNameRec,DateRename) values(@userID,@cam_id,@oldName,@newName,GETDATE())

	end
		
		
if @action = 3
	if @tipo_llamada = 1
	begin
		UPDATE ccInbound set prefijo = @prefijo where Inbound_id = @cam_id 
		select 'inbound'
	end
	if @tipo_llamada = 2
	begin
	select @cam_id
	select @prefijo
		UPDATE ccCamps set prefijo = @prefijo where cam_id = @cam_id 
		select 'camps'
	end