CREATE procedure [dbo].[trsp_AdmPCISetConfig] (
	@action int,
	@id int,
	@isCampaign bit,
	@isOn bit,
	@xTimeStatus smallint,
	@words nvarchar(255),
	@list int
)
as
--insert procedure body here
Begin
	Declare @simbolo nvarchar
	Declare @sql int
	Set @simbolo = '#'
	Declare @aux varchar(255)
	--Prender o apagar PCI
	If @action = 1
	Begin
		If @isCampaign = 1
		Begin
			select @sql=Count(cam_id) from RIA_PCI_CAMP_Settings where cam_id=@id
			If @sql > 0
			Begin
				update RIA_PCI_CAMP_SETTINGS set onOff=@isOn where cam_id=@id
			End
			Else
			Begin
				insert into RIA_PCI_CAMP_SETTINGS values(@id,0,@isOn,@xTimeStatus)
			End
		End
		Else
		Begin
			select @sql=Count(Inbound_id) from RIA_PCI_ACD_Settings where Inbound_id=@id
			
			If @sql > 0
			Begin
				update RIA_PCI_ACD_Settings set onOff=@isOn where Inbound_id=@id
			End
			Else
			Begin
				insert into RIA_PCI_ACD_Settings values(@id,0,@isOn,@xTimeStatus)
			End
		End
	End
	Else
	Begin
		--Guardar una palabra en la lista
		If @action = 2
		Begin
			If @isCampaign = 1
			Begin
				insert into RIA_PCI_CAMP_LIST values (@id,@list+1,@words)
			End
			Else
			Begin
				insert into RIA_PCI_ACD_LIST values (@id,@list+1,@words)
			End
		End
		Else
		Begin
			--Change the status of the Xtime
			If @action = 3
			Begin
				If @isCampaign = 1
				Begin
					update RIA_PCI_CAMP_SETTINGS set ActiveXtime=@xTimeStatus where cam_id = @id
				End
				Else
				Begin
					update RIA_PCI_ACD_SETTINGS set ActiveXtime=@xTimeStatus where Inbound_id = @id
				End
			End
			Else
			Begin
				--Guardar una lista de palabras
				If @action = 4
				Begin
					If @isCampaign = 1
					Begin
						While (Charindex(@simbolo,@words)>0)
						Begin
							Set @aux = ltrim(rtrim(Substring(@words,1,Charindex(@simbolo,@words)-1)))
							select @sql=Count(cam_id) from RIA_PCI_CAMP_LIST where cam_id=@id and List_type=@list+1 and Keyword=@aux
							If @sql = 0
							Begin
								insert into RIA_PCI_CAMP_LIST values (@id,@list+1,@aux)
							End
							Set @words = Substring(@words,Charindex(@simbolo,@words)+len(@simbolo),len(@words))
						End
						Set @aux = ltrim(rtrim(@words))
						select @sql=Count(cam_id) from RIA_PCI_CAMP_LIST where cam_id=@id and List_type=@list+1 and Keyword=@aux
						If @sql = 0
						Begin
							insert into RIA_PCI_CAMP_LIST values (@id,@list+1,@aux)
						End
					End
					Else
					Begin
						While (Charindex(@simbolo,@words)>0)
						Begin
							Set @aux = ltrim(rtrim(Substring(@words,1,Charindex(@simbolo,@words)-1)))
							select @sql=Count(Inbound_id) from RIA_PCI_ACD_LIST where Inbound_id=@id and List_type=@list+1 and Keyword=@aux
							If @sql = 0
							Begin
								insert into RIA_PCI_ACD_LIST values (@id,@list+1,@aux)
							End
							Set @words = Substring(@words,Charindex(@simbolo,@words)+len(@simbolo),len(@words))
						End
						Set @aux = ltrim(rtrim(@words))
						select @sql=Count(Inbound_id) from RIA_PCI_ACD_LIST where Inbound_id=@id and List_type=@list+1 and Keyword=@aux
						If @sql = 0
						Begin
							insert into RIA_PCI_ACD_LIST values (@id,@list+1,@aux)
						End
					End
				End
				Else
				Begin
					--Borrar una lsita de palabras
					If @action = 5
					Begin
						If @isCampaign = 1
						Begin
							While (Charindex(@simbolo,@words)>0)
							Begin
								delete from RIA_PCI_CAMP_LIST where cam_id=@id and List_type = @list+1 and Keyword = ltrim(rtrim(Substring(@words,1,Charindex(@simbolo,@words)-1)))
								Set @words = Substring(@words,Charindex(@simbolo,@words)+len(@simbolo),len(@words))
							End
							delete from RIA_PCI_CAMP_LIST where cam_id=@id and List_type = @list+1 and Keyword = ltrim(rtrim(@words))
						End
						Else
						Begin
							While (Charindex(@simbolo,@words)>0)
							Begin
								delete from RIA_PCI_ACD_LIST where Inbound_id=@id and List_type = @list+1 and Keyword = ltrim(rtrim(Substring(@words,1,Charindex(@simbolo,@words)-1)))
								Set @words = Substring(@words,Charindex(@simbolo,@words)+len(@simbolo),len(@words))
							End
							delete from RIA_PCI_ACD_LIST where Inbound_id=@id and List_type = @list+1 and Keyword = ltrim(rtrim(@words))
						End
					End
				End
			End
		End
	End
	
End