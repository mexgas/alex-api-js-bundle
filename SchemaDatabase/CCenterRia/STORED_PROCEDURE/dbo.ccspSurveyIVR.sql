CREATE procedure [dbo].[ccspSurveyIVR]
@action as tinyint,@surveyId int =0,@description varchar(80) = null,@scriptId int=null,@isActive bit=null,  
@questionId int =0,@answerId int=0,@digit tinyint=null,@ids varchar(400)=null,@orden varchar(400)=null
AS  
  
declare @sql nvarchar(max)
declare @coma varchar(10)
declare @id int
set @coma=','  
set @id=0  
if @action = 1 begin --INSERT and Update Survey   
 select @id=surveyId from Survey where description=@description  
 if @id > 0 and @id<>@surveyId begin  
  select -1 as surveyId  
  return (0)  
 end  
 if @surveyId=0 begin     
  insert into Survey(description,scriptId,active) values(@description,@scriptId,1)  
  select @surveyId=IDENT_CURRENT('Survey')    
 end  
 else begin     
  update Survey set description=isnull(@description,description),scriptId=isnull(@scriptId,scriptId),active=isnull(@isActive,active) where surveyId=@surveyId     
 end  
 select @surveyId   
 return 0  
end  
else if @action = 2 begin --INSERT and Update SurveyQuestion  
 select @id=questionId from SurveyQuestion where description=@description  
 if @id > 0 and @id<>@questionId begin  
  select -1 as questionId  
  return (0)  
 end  
 if @questionId=0 begin    
  insert into SurveyQuestion(description,active) values(@description,1)  
  select @questionId=IDENT_CURRENT('SurveyQuestion')    
 end  
 else begin  
  update SurveyQuestion set description=isnull(@description,description),active=isnull(@isActive,active) where questionId=@questionId     
 end  
 select @questionId   
 return 0  
end  
else if @action = 3 begin --INSERT and Update SurveyAnswer  
 select @id=answerId from SurveyAnswer where description=@description  
 if @id > 0 and @id<>@answerId begin  
  select -1 as questionId  
  return (0)  
 end  
 if @answerId=0 begin  
  insert into SurveyAnswer(description,active,digit) values(@description,1,@digit)  
  select @answerId=IDENT_CURRENT('SurveyAnswer')
 end  
 else begin  
  update SurveyAnswer set description=isnull(@description,description),active=isnull(@isActive,active),digit=isnull(@digit,digit) where answerId=@answerId     
 end  
 select @answerId   
 return 0  
end  
else if @action = 4 begin --insert relationSurveyQuestion   
 set @sql ='insert into relationSurveyQuestion(surveyId,questionId,orden)  
 select '+convert(nvarchar(max),@surveyId)+',A.Value,C.Value from dbo.fn_RIASplitDelimited('''+@ids+''','''+@coma+''') A  
left join relationSurveyQuestion B on A.Value=B.questionId and B.surveyId='+convert(nvarchar(max),@surveyId)+' 
left join dbo.fn_RIASplitDelimited('''+@orden+''','''+@coma+''') C on C.Id=A.Id
where B.questionId is null'  
exec (@sql)   
end  
else if @action = 5 begin --insert relationQuestionAnswer  
 set @sql ='insert into relationQuestionAnswer(surveyId,questionId,answerId)  
 select '+convert(nvarchar(max),@surveyId)+','+convert(nvarchar(max),@questionId)+',A.Value from dbo.fn_RIASplitDelimited('''+@ids+''','''+@coma+''') A  
left join relationQuestionAnswer B on A.Value=B.answerId and B.questionId='+convert(nvarchar(max),@questionId)+'  
where B.answerId is null'   
 exec(@sql)   
end  
else if @action = 6 begin --delete relationSurveyQuestion   
 set @sql ='delete from relationSurveyQuestion where questionId in('+@ids+') and surveyId='+convert(nvarchar(max),@surveyId)  
 exec(@sql)   
end  
else if @action = 7 begin --delete relationQuestionAnswer   
 set @sql ='delete from relationQuestionAnswer where surveyId='  
 +convert(nvarchar(max),@surveyId)+' and questionId='+convert(nvarchar(max),@questionId) +  
 ' and answerId in('+@ids+') '  
 exec(@sql)  
end  
else if @action = 8 begin    
 select surveyId,description,scriptId from Survey where active=1  
end  
else if @action = 9 begin   
 select questionId,description from SurveyQuestion where active=1  
end  
else if @action = 10 begin   
 select answerId,description,digit from SurveyAnswer where active=1  
end  
else if @action = 11 begin   
 select a.questionId,b.description,A.orden from relationSurveyQuestion A left join SurveyQuestion B on a.questionId = b.questionId where a.surveyId=@surveyId and B.active=1  order by A.orden
end  
else if @action = 12 begin   
 select A.answerId,B.description,B.digit from relationQuestionAnswer A left join SurveyAnswer B on A.answerId=B.answerId  where a.surveyId=@surveyId  and a.questionId=@questionId
end
else if @action = 13 begin   
 select S.scriptId,S.description,a.questionId,b.description,isnull(rQA.answerId,0),isnull(SA.description,''),isnull(SA.digit,-1)
  from relationSurveyQuestion A 
  inner join SurveyQuestion B on a.questionId = b.questionId 
  inner join Survey S on S.surveyId=A.surveyId
  left join relationQuestionAnswer rQA on rQA.questionId=A.questionId
  left join SurveyAnswer SA on SA.answerId=rQA.answerId
  where a.surveyId=@surveyId and B.active=1  
  order by A.orden
end