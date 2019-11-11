CREATE PROCEDURE [dbo].[ccsp_CreateNodeMultimedia]
@conversationId bigint,
@xml xml OUTPUT,
@supervisor varchar(255)='',
@template varchar (255)='',
@ScoreTemplate int=0,
@type int =1--1 EMAIL , 2 Twitter
AS
BEGIN
declare @info varchar(255)
declare @infoEscape varchar(max)
declare @charEscape varchar(255),@charReplace varchar(max)
set @charEscape='"|''''|<|>|&'
set @charReplace='&quot;|&apos;|&lt;|&gt;|&amp;'

declare @existAttached bit,@numInteracion smallint
if @type=0 begin--CHAT

    select @xml = convert(xml,'<R01 CDATE="'+rtrim(ltrim(convert(varchar(23), isNull(chatDate,requestDate), 126))) +
    '" C01="'+convert(varchar(max),chatId) +
    '" C02="'+convert(varchar(max),isnull(ccinbound.descripcion,'')) +
    '" C03="'+convert(varchar(max),domain) +
    '" C04="'+convert(varchar(max), Nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMAterno ) +
    '" C05="'+convert(varchar(max),tchatting) +
    '" C06="'+convert(varchar(max),isnull(cctipocalif.[Description],'N/A')) +
    '" C07="'+convert(varchar(max),isnull(cctipocalifsub.califSubdesc,'N/A')) +
    '" C08="'+convert(varchar(max),clientname) +
    '" C09="'+rtrim(ltrim(convert(varchar(23), chatDate, 126))) +
    '" C10="'+convert(varchar(max),isnull(@supervisor,'') ) +
    '" C11="'+convert(varchar(max),isnull(@template,'') )  +
    '" C12="'+convert(varchar(max),isnull(@ScoreTemplate,0)) +
    '" C13="'+convert(varchar(max),isnull(ccusers.[Login],'')) + '"/>')
    from ccRIAChats
    left outer join ccinbound on ccinbound.inbound_id = ccRIAChats.inboundid
    left outer join ccusers on ccusers.user_id = ccRIAChats.userid
    left outer join cctipocalif on cctipocalif.calif_id = ccRIAChats.disposition
    left outer join cctipocalifsub on cctipocalifsub.califsub_id = ccRIAChats.subdisposition and ccRIAChats.subdisposition <> 0
    where chatId = @conversationId and chatStatus = 4 and requestDate is not null and chatDate is not null

end
else if @type=1 begin--EMAIL
    SELECT @existAttached = case when count(*)>0 then 1 else 0 end
    from attached where messageId in (select messageId from message where conversationId=@conversationId)
    select @numInteracion = count(*) from message where conversationId=@conversationId
    --Replaza los caracteres por los comunes
    select @info=info from conversation where conversationId=@conversationId
    select @info=replace(@info,A.Value,B.Value) from dbo.fn_RIASplitDelimited(@charEscape,'|') A
    inner join dbo.fn_RIASplitDelimited(@charReplace,'|') B on A.Id=B.Id


    select @xml = convert(xml,'<R03 CDATE="'+ rtrim(ltrim(convert(varchar(23), isnull(max(b.tsend), getdate()), 126))) +
    '" C01="'+ convert(varchar(max),a.conversationId) +
    '" C02="'+ rtrim(ltrim(convert(varchar(23), isnull(max(b.tsend), getdate()), 126))) +
    '" C03="'+ convert(varchar(max),max(c.descripcion)) +
    '" C04="'+ convert(varchar,max(isnull(Nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMAterno,''))) +
    '" C05="'+ convert(varchar,max(isnull(cctipocalif.[Description],'N/A'))) +
    '" C06="'+ convert(varchar,max(replace(replace(a.mailClient,'<',' '),'>',' '))) +
    '" C07="'+ convert(varchar(max),sum(b.tRetention+b.tResponse+b.tWrapup)) +
    '" C08="'+ convert(varchar(max),min(isnull(@info,''))) +
    '" C09="'+ convert(varchar(max),max(b.messageStatusid) ) +'" C10="'+  convert(varchar(max), isnull(@numInteracion,0)) +
    '" C11="'+ convert(varchar(max),@existAttached) +'" C12="'+ convert(varchar(max),isnull(@supervisor,'') ) +
    '" C13="'+ convert(varchar(max),isnull(@template,'') )  +'" C14="'+convert(varchar(max),isnull(@ScoreTemplate,0)) +
    '" C15="'+ convert(varchar,max(isnull(cctipocalifsub.califSubdesc,'N/A'))) +
    '" C16="'+ convert(varchar(max),isnull(max(d.[Login]),'')) + '"/>')
    from conversation a
    inner join message b on a.conversationid=b.conversationid
    left outer join ccinbound c on c.inbound_id = a.inboundid
    left outer join ccusers d on d.user_id = b.userid
    left outer join relationmessageDisposition e on e.messageId=b.messageId
    left outer join cctipocalif on cctipocalif.calif_id = e.dispositionId
    left outer join cctipocalifsub on cctipocalifsub.califsub_id = e.subdispositionId and e.subdispositionId <> 0
    where a.conversationId=@conversationId
    group by a.conversationId,a.inboundid

end
else if @type=2 begin--Twitter
    select @numInteracion = sum(ninteration) from messageOutTwitter where conversationTwitterId=@conversationId

    select @xml = convert(xml,'<R04 CDATE="'+rtrim(ltrim(convert(varchar(23), min(b.date), 126))) +
    '" C01="'+convert(varchar(max),a.conversationTwitterId) +
    '" C02="'+rtrim(ltrim(convert(varchar(23), min(b.date), 126))) +
    '" C03="'+convert(varchar(max),max(c.descripcion)) +
    '" C04="'+ convert(varchar,max(isnull(Nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMAterno,''))) +
    '" C05="'+convert(varchar,max(isnull(cctipocalif.[Description],'N/A'))) +
    '" C06="'+ max(a.screenNameClient) +
    '" C07="'+convert(varchar(max),sum(b.tRetention+b.tResponse+b.tWrapup)) +
    '" C08="'+ max(a.screenNameInbound) +
    '" C09="'+convert(varchar(max),max(b.messageStatusid) ) +
    '" C10="'+  convert(varchar(max), isnull(@numInteracion,0)) +
    '" C11="'+ convert(varchar(max),isnull(@supervisor,'') ) +
    '" C12="'+convert(varchar(max),isnull(@template,''))  +
    '" C13="'+convert(varchar(max),isnull(@ScoreTemplate,0)) +
    '" C14="'+ convert(varchar,max(isnull(cctipocalifsub.califSubdesc,'N/A'))) +
    '" C15="'+convert(varchar(max),isnull(max(d.[Login]),'')) + '"/>')
    from conversationTwitter a
    inner join messageOutTwitter b on a.conversationTwitterId=b.conversationTwitterId
    left outer join ccinbound c on c.inbound_id = a.inboundid
    left outer join ccusers d on d.user_id = b.userid
    left outer join relationMessageDispositionTwit e on e.messageOutTwitterId=b.messageOutTwitterId
    left outer join cctipocalif on cctipocalif.calif_id = e.dispositionId
    left outer join cctipocalifsub on cctipocalifsub.califsub_id = e.subdispositionId and e.subdispositionId <> 0
    where a.conversationTwitterId=@conversationId
    group by a.conversationTwitterId,a.inboundid
end

END