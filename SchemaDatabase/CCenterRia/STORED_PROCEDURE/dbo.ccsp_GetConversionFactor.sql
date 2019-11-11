CREATE PROCEDURE [dbo].[ccsp_GetConversionFactor]
	@userId int = 0 ,
    @califId int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --Clean temp tables--

	IF OBJECT_ID('tempdb..#LoginTimeAgent') IS NOT NULL 
	BEGIN
	  DROP TABLE #LoginTimeAgent
	END

	--Clean temp tables--

	--Create time ranges--

	declare @fecha datetime
	select @fecha = convert(datetime,convert(varchar(11),getdate()))

	--Create time ranges--

	--Create flags for searches--

	declare @agentFlag bit 
	IF @userId < 1
	  BEGIN
		--Select all agents
		SET @agentFlag = 1
	  END
	ELSE
	  BEGIN
		--Find agent specified in param @userId
		SET @agentFlag = 0
	  END

	declare @califFlag bit
	IF @califId < 1
	  BEGIN
		--Select all califications
		SET @califFlag = 1
	  END
	ELSE
	  BEGIN
		--Find specified calification in param @califId
		SET @califFlag = 0
	  END

	--Create flags for searches--

	--Get login times of the current day for all agents--

	SELECT a.User_id as uid, case 
		WHEN sum(convert(int,DateDiff(second, '00:00', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0 
			THEN sum(convert(int,DateDiff(second, '00:00', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))  
		ELSE sum(convert(int,DateDiff(second, '00:00', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) + 
			convert(int,DateDiff(second, '00:00', Convert(VARCHAR(30), getdate(), 14)))
		END as time_secs
	INTO #LoginTimeAgent
	FROM ccLogLogin a, ccUsers b
	where fecha >= @fecha
	and a.User_id = b.User_id
	GROUP BY a.User_id

	--Get login times for the day of all agents--

	--Get disposition calls for the day of all agents--
	        	    
	SELECT R.user_id As 'userId',U.login,R.calif_id As 'califId',R.description,R.llamadas AS 'calls',CASE WHEN T.time_secs <1 THEN 1 ELSE T.time_secs END As 'time_secs' FROM
		((select calif.calif_id, description, 
		case when timegroup is null then convert(smalldatetime,convert(varchar(10),getdate(),121),121) else timegroup end timegroup,
		case when user_id is null then 0 else user_id end [user_id],
		case when llamadas is null then 0 else llamadas end [llamadas], 1 as type
		  from (select calif_id, description from cctipocalifout where califout_status = 1 AND (@califFlag=1 OR calif_id = @califId)) calif
		  left join (SELECT convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) AS timegroup, [user_id], calif_id, COUNT(*) llamadas
		FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2)) WHERE cal_inicio >= convert(smalldatetime,convert(varchar(10),getdate(),121),121) AND statuscall_id = 13  and calif_id > 0 
		 AND (@agentFlag=1 OR user_id = @userId) 
		 GROUP BY convert(smalldatetime,convert(varchar(10),cal_inicio,121),121), [user_id], calif_id 
		) data
		on (calif.calif_id = data.calif_id))
		union all
		(select calif.calif_id, description, 
		case when timegroup is null then convert(smalldatetime,convert(varchar(10),getdate(),121),121) else timegroup end timegroup,
		case when user_id is null then 0 else user_id end [user_id],
		case when llamadas is null then 0 else llamadas end [llamadas], 0 as type
		  from (select calif_id, description from cctipocalif where calif_status = 1 AND (@califFlag=1 OR calif_id = @califId)) calif
		  left join (SELECT convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) AS timegroup, [user_id], calif_id, COUNT(*) llamadas
		FROM cccallsin with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio >= convert(smalldatetime,convert(varchar(10),getdate(),121),121) AND statuscall_id = 13  and calif_id > 0 
		 AND (@agentFlag=1 OR user_id = @userId) 
		 GROUP BY convert(smalldatetime,convert(varchar(10),cal_inicio,121),121), [user_id], calif_id 
		) data
		on (calif.calif_id = data.calif_id))) AS R   
	, #LoginTimeAgent As T
	, ccUsers As U
	WHERE R.user_id = T.uid 
	AND R.user_id = U.user_id
	ORDER BY R.user_id

	--Get disposition calls for the day of all agents--

	--Clean temp tables--

	IF OBJECT_ID('tempdb..#LoginTimeAgent') IS NOT NULL 
	BEGIN
	  DROP TABLE #LoginTimeAgent
	END

	--Clean temp tables--

END