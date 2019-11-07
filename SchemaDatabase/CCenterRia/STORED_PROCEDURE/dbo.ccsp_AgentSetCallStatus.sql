CREATE procedure [dbo].[ccsp_AgentSetCallStatus]
@callout_id int,
@cal_id int,
@TipoCall tinyint,	-- 1= IN,  2=Out
@TipoMov tinyint,	-- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
@cal_tXfer tinyint=0,
@cal_tring  smallint=0,
@user_id smallint=0,
@extension varchar(5)='',
@isChatCall bit = 0
AS
set nocount on

declare @RecicleSIC tinyint
SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id=60
Declare @ANI_x varchar(19)
declare @cal_inicio datetime
declare @callout_id_IN int
declare @cal_key varchar(20)
declare @cam_id int
declare @cal_telefono varchar(30)
declare @surveycamid int
declare @inbound_id int

if @TipoMov=4 or @TipoMov=14 -- DIALOG OnDialog
 begin
	if @TipoCall=2
	 begin
		if @TipoMov = 4 begin
			Update ccoCallsOUT with(rowlock) Set cal_Inicio=getdate(), statusCall_id=13, cal_manual=case when @isChatCall=1 then 3 else cal_manual end Where cal_id=@cal_id
		end
		else if @TipoMov = 14
			Update ccoCallsOUT with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id

		if @RecicleSIC=0
			DELETE ccoWorkingTable with(rowlock) WHERE callout_id=@callout_id

		update ccoCallBacks
		set [status] = 1, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 13

		-- calcula el costo de la llamada
		exec ccsp_CstoCalculaCosto @cal_id

		return(0)
	end


	if @TipoMov = 4
		Update ccCallsIN with(rowlock) Set statusCall_id=13 Where cal_id=@cal_id
	else if @TipoMov = 14
		Update ccCallsIN with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id

	-- Elimina callback generado por abandono
	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN =callout_id from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock)
	set [status] = 1, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	DELETE ccoWorkingTable with(rowlock) WHERE callout_id in (select distinct(callout_id) from ccRIAUpdateCallBack_Abandon with(rowlock) where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x

	return(0)
 end

if @TipoMov=7 --OTHER OFFHook_OnXfer
 begin
	if @cal_id<=0
		return(0)

	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=16 Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 16

		exec ccsp_CstoCalculaCosto @cal_id
		return(0)
	 end

	Update ccCallsIN with(rowlock) Set statusCall_id=16 Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock)
	set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

if  @TipoMov=9 --RING CallNoAnswered
 begin
	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 15

		exec ccsp_CstoCalculaCosto @cal_id
	 end

	Update ccCallsIN with(rowlock) Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock)
	set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

set nocount off