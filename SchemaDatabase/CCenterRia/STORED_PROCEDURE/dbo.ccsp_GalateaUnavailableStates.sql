CREATE PROCEDURE [dbo].[ccsp_GalateaUnavailableStates]
@NotReady_id smallint = null,
@Description varchar(30)='',
@Acc_Time int = null,
@Intervals int = null,
@Pass_Supv tinyint = null,
@NextStatus int = null,
@Frame smallint = null,
@Type varchar(1)='',
@IsSupv int = null,
@NotReady_ids varchar(max)=''
AS
set nocount on
DECLARE @sql nvarchar(4000), @graph nvarchar(1000), @id smallint, @newGraph smallint

	if @Type = 1 -- LOAD
		begin
			SELECT distinct a1.TipoNotReady_id as NotReady_Id, a1.Descripcion as Description, a1.Time_Acum as Acc_Time, a1.Time_xEv as Intervals, 
			cast(a1.Pas_Sup as bit) Pass_Supv, a1.NextStatus, frame as Frame, cast(a1.IsSup as bit) IsSupv
			FROM ccTipoNotReady a1 
			inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
			inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
			where a1.StatusTipoNotReady=1 and a1.TipoNotReady_id between 0 and 250
			order by 2
		end

	If @Type=2 -- INSERT
	 begin
		if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Description)
		 begin		
			select -1
			return(0)
		 end
		if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=0 and Descripcion=@Description)
			begin		
				select @id=TipoNotReady_id from ccTipoNotReady where Descripcion=@Description
				update ccTipoNotReady set 
				Time_acum=@Acc_Time,
				Time_xEv=@Intervals,
				Pas_Sup=@Pass_Supv,
				NextStatus=@NextStatus,
				IsSup=@IsSupv,
				StatusTipoNotReady=1
				where Descripcion=@Description
				If not exists(select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
					Begin
						insert into ccRIAGraphics (frame, type_id) select @Frame,4
					End
			
				insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
				select cast(@id as int)
				return(0)		
			end
		If not exists(select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
		 Begin
			insert into ccRIAGraphics (frame, type_id) select @Frame,4
		 End

		insert ccTipoNotReady (Descripcion, Time_Acum, Time_xEv, Pas_Sup, NextStatus, IsSup, StatusTipoNotReady) 
		select @Description, @Acc_Time, @Intervals, @Pass_Supv, @NextStatus, @IsSupv,1
		select @id=SCOPE_IDENTITY()
		insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
		select cast(@id as int)
	 end

	If @Type=3 -- DELETE
	 begin
		 declare @NDs_Ids table (id int primary key not null)

		if @NotReady_id is null
		 begin
			insert into @NDs_Ids
			select value from dbo.fn_RIASplitDelimited (@NotReady_ids, ',')
		 end
		else
		 begin
			insert into @NDs_Ids
			select @NotReady_id
		 end

		exec ccsp_AdminNotready 3,0,@NotReady_id,0, @NotReady_ids
		delete ccRIANotReadyGraph where tipoNotReady_id in (select id from @NDs_Ids)
		update ccTipoNotReady set StatusTipoNotReady=0 where tipoNotReady_id in (select id from @NDs_Ids)
		update ccTipoNotReady set NextStatus=-1 where NextStatus in (select id from @NDs_Ids)
	
		select cast(id as smallint) NotReady_Id, 0 as Related from @NDs_Ids
	 end

	if(@Type=4) --UPDATE
	 begin

		if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Description and TipoNotReady_id not in (@NotReady_id))
		 begin		
			select -1
			return(0)
		 end

		update ccTipoNotReady set 
		 Descripcion=case @Description when '' then Descripcion else @Description end,
		 Time_Acum=ISNULL(@Acc_Time,Time_Acum),
		 Time_xEv=ISNULL(@Intervals,Time_xEv),
		 Pas_Sup=ISNULL(@Pass_Supv,Pas_Sup), 
		 NextStatus=ISNULL(@NextStatus,NextStatus), 
		 IsSup=ISNULL(@IsSupv,IsSup)
		where TipoNotReady_id=@NotReady_id

		IF ISNULL(@Frame,'') not in('')
		 BEGIN
			If not exists (select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
			 begin
				insert into ccRIAGraphics (frame, type_id) select @Frame,4
			 end

			select @graph = graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
			update ccRIANotReadyGraph set graphic_id=cast(@graph as smallint) where TipoNotReady_id=cast(@NotReady_id as tinyint)
		 END
		 select 1
	 end

	if @Type = 5
	 begin
		select cast(NextStatus as smallint) NotReady_Id, cast(TipoNotReady_id as int) Related
		from ccTipoNotReady 
		where StatusTipoNotReady=1 and NextStatus in (select value from dbo.fn_RIASplitDelimited (@NotReady_ids, ','))
	 end

set nocount off