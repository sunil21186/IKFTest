USE [IKFAssignmentSunil]
GO
/****** Object:  Table [dbo].[UserMaster]    Script Date: 06/09/2021 08:57:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UserMaster](
	[UserId] [int] NOT NULL,
	[UserName] [varchar](50) NULL,
	[DOB] [datetime] NULL,
	[Designation] [varchar](50) NULL,
 CONSTRAINT [PK_UserMaster] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[SplitString]    Script Date: 06/09/2021 08:57:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[SplitString]  
(  
   @Input NVARCHAR(MAX),  
   @Character CHAR(1)  
)  
RETURNS @Output TABLE (  
   Item NVARCHAR(1000)  
)  
AS  
BEGIN  
DECLARE @StartIndex INT, @EndIndex INT  
SET @StartIndex = 1  
IF SUBSTRING(@Input, LEN(@Input) - 1, LEN(@Input)) <> @Character  
BEGIN  
SET @Input = @Input + @Character  
END  
WHILE CHARINDEX(@Character, @Input) > 0  
BEGIN  
SET @EndIndex = CHARINDEX(@Character, @Input)  
INSERT INTO @Output(Item)  
SELECT SUBSTRING(@Input, @StartIndex, @EndIndex - 1)  
SET @Input = SUBSTRING(@Input, @EndIndex + 1, LEN(@Input))  
END  
RETURN  
END
GO
/****** Object:  Table [dbo].[SkillMaster]    Script Date: 06/09/2021 08:57:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SkillMaster](
	[SkillId] [int] NOT NULL,
	[SkillName] [varchar](50) NULL,
 CONSTRAINT [PK_SkillMaster] PRIMARY KEY CLUSTERED 
(
	[SkillId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UserSkillLinking]    Script Date: 06/09/2021 08:57:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserSkillLinking](
	[UserId] [int] NULL,
	[SkillId] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[UserSkill_CRUD]    Script Date: 06/09/2021 08:57:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Name
-- Create date: 
-- Description:	 UserSkill_CRUD 'SELECT', 1, 'SUNIL'
-- =============================================
CREATE PROCEDURE [dbo].[UserSkill_CRUD] 
	@Action varchar(10),
	@UserId int = 0,
	@UserName varchar(50) = NULL,
	@DOB datetime = NULL,
	@Designation varchar(50) = NULL,
	@SkillIds varchar(max) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	--SET NOCOUNT ON;

    -- Insert statements for procedure here
	If @Action = 'SELECT'
	BEGIN
		SELECT UM1.UserId, UM1.UserName, UM1.DOB, UM1.Designation,
		(SELECT STUFF((SELECT ',' + SM.SkillName FROM UserSkillLinking L
		INNER JOIN UserMaster UM ON UM.UserId = L.UserId
		INNER JOIN SkillMaster SM ON SM.SkillId = L.SkillId
		WHERE L.UserId = UM1.UserId FOR XML PATH('')), 1, 1, '')) Skills,
		(SELECT STUFF((SELECT ',' + CONVERT(VARCHAR, SM.SkillId) FROM UserSkillLinking L
		INNER JOIN UserMaster UM ON UM.UserId = L.UserId
		INNER JOIN SkillMaster SM ON SM.SkillId = L.SkillId
		WHERE L.UserId = UM1.UserId FOR XML PATH('')), 1, 1, '')) SkillIds
		FROM UserMaster UM1
	END
	
	If @Action = 'INSERT'
	BEGIN
		SET @UserId = ISNULL((SELECT MAX(UserId) FROM UserMaster), 0) + 1
		INSERT INTO UserMaster(UserId, UserName, DOB, Designation)
		VALUES(@UserId, @UserName, @DOB, @Designation)
		
		DECLARE @CUR_SKILLID INT
		
		DECLARE db_cursor CURSOR FOR 
		SELECT Item FROM DBO.SPLITSTRING(@SkillIds,',');  

		OPEN db_cursor  
		FETCH NEXT FROM db_cursor INTO @CUR_SKILLID  

		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			  
			  INSERT INTO UserSkillLinking(UserId, SkillId)
			  VALUES(@UserId, @CUR_SKILLID)
			  
			  FETCH NEXT FROM db_cursor INTO @CUR_SKILLID 
		END 

		CLOSE db_cursor  
		DEALLOCATE db_cursor 
	END
	
	If @Action = 'UPDATE'
	BEGIN
	
		UPDATE UserMaster SET UserName = @UserName, DOB = @DOB, Designation = @Designation WHERE UserId = @UserId
		
		DELETE FROM UserSkillLinking WHERE UserId = @UserId
		
		DECLARE @CUR_SKILLID_UPDATE INT
		
		DECLARE db_cursor CURSOR FOR 
		SELECT Item FROM DBO.SPLITSTRING(@SkillIds,',');  

		OPEN db_cursor  
		FETCH NEXT FROM db_cursor INTO @CUR_SKILLID_UPDATE  

		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			  
			  INSERT INTO UserSkillLinking(UserId, SkillId)
			  VALUES(@UserId, @CUR_SKILLID_UPDATE)
			  
			  FETCH NEXT FROM db_cursor INTO @CUR_SKILLID_UPDATE 
		END 

		CLOSE db_cursor  
		DEALLOCATE db_cursor 
	END
	
	If @Action = 'DELETE'
	BEGIN
		DELETE FROM UserMaster WHERE UserId = @UserId
		
		DELETE FROM UserSkillLinking WHERE UserId = @UserId
	END
END
GO
/****** Object:  StoredProcedure [dbo].[SP_SkillsMasterList]    Script Date: 06/09/2021 08:57:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Name
-- Create date: 
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[SP_SkillsMasterList]
AS
BEGIN
	SELECT SkillId, SkillName FROM SkillMaster
END
GO
