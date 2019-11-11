CREATE procedure [dbo].[ccsp_IVRInCalls]
@action tinyint = 0 ,
@ani varchar(30) = null ,
@idIvr int = 0 ,
@option varchar(5)= null ,
@saveType tinyInt = null,
@dnis varchar(50) = null,
@name varchar(50) = null,
@questionId int = 0,
@surveyId int = 0,
@calId int = 0,
@callout_id int = 0,
@ttotalIVR int = 0
-- saveType 1 es menu 2 es dato
-- accion 1 siempre @ani  -> @idIvr
-- accion 2 siempre @idIvr @opcionDigitada -> nada
AS
IF @action = 1
BEGIN
    IF @ani IS NOT NULL
    BEGIN
        INSERT INTO IVRCallsIn(cal_ani,date,dnis,callout_id) values(@ani,getDate(),isnull(@dnis,''),@callout_id);
        Select 'ID'=scope_identity()
    END
END
ELSE IF @action = 2
BEGIN
    IF @option IS NOT NULL AND @idIvr IS NOT NULL
    BEGIN
        INSERT INTO IVROptions(IVR_id,selectedOption,date,saveType,name, questionId, surveyId, cal_id) values (@idIvr,@option,getDate(),@saveType,@name,isnull(@questionId,0),isnull(@surveyId,0),isnull(@calId,0))
        select 0
    END
    ELSE select -1
END
ELSE IF @action = 3
BEGIN
    UPDATE IVRCallsIn set tincall = @ttotalIVR where IVR_id = @idIvr and callout_id = @callout_id
    if @callout_id > 0
        exec ccsp_EngineLogTransfers 4, @callout_id, 0, 0, null
END