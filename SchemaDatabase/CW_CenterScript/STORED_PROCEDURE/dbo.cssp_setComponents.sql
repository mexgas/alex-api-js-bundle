CREATE PROCEDURE [dbo].[cssp_setComponents]
        @Template_id int,
        @x int,
        @y int,
        @h int,
        @w int,
        @i varchar(50),
        @Text varchar(MAX) ='',
        @Component_id int,
        @Name varchar(50)='', 
        @properties varchar(max),
        @path varchar(255) =''
      AS
      SET nocount on;

      if(@Component_id=1) -- Label
        if exists(select * from labelComponent where i = @i and Template_id = @Template_id)
        begin
          update labelComponent set x= @x, y=@y, w=@w, h=@h, Name = @Name, Text=@Text where Template_id = @Template_id and i =@i
        end
        else
          Insert into dbo.labelComponent (Template_id,i,x,y,w,h,Text,Name)
          values (@Template_id,@i,@x,@y,@w,@h,@Text,@Name);
      ELSE IF(@Component_id=2) -- Image
        if exists(select * from ImageComponent where i = @i and Template_id = @Template_id)
        begin
          if(@path = '')
          begin
          update ImageComponent set x= @x, y=@y, w=@w, h=@h, Name=@Name where Template_id = @Template_id and i =@i
          end
          else 
          update ImageComponent set x= @x, y=@y, w=@w, h=@h, Name=@Name, Path = @path where Template_id = @Template_id and i =@i
        end
        else
          Insert into dbo.ImageComponent(Template_id,i,x,y,w,h,Path,Name)
          values (@Template_id,@i,@x,@y,@w,@h,@path,@Name);
        
      else if(SUBSTRING(@Name, 1, 1)='*')
    begin
        if exists(select * from componentsRelation where i=@i and Template_id = @Template_id)
        begin
          update componentsRelation set x= @x, y=@y, w=@w, h=@h, Name = @Name where Template_id = @Template_id and i =@i
        end
        else
    begin
          Insert into dbo.componentsRelation (Template_id,Component_id,i,x,y,w,h,Name)
          values (@Template_id,@Component_id,@i,@x,@y,@w,@h,@Name)
    end
    if exists(select * from Components_per_Template where i=@i and Template_id = @Template_id)
    begin
      delete from Components_per_Template where i=@i and Template_id = @Template_id 
    end
    end
      else
        begin        -- Update Relation
        if exists(select * from Components_per_Template where i=@i and Template_id = @Template_id)
        begin
          update Components_per_Template set x= @x, y=@y, w=@w, h=@h, Name = @Name, Properties = @properties, text=@Text
           where Template_id = @Template_id and i =@i
        end
        else
    begin
          Insert into dbo.Components_per_Template (Template_id,Component_id,i,x,y,w,h,Text,status,Name, Properties)
          values (@Template_id,@Component_id,@i,@x,@y,@w,@h,@Text,1,@Name, @properties) 
    end
    if exists(select * from componentsRelation where i=@i and Template_id = @Template_id)
    begin
      delete from componentsRelation where i=@i and Template_id = @Template_id 
    end
    end