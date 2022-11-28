
IF NOT EXISTS(select 1 from sys.databases where name = 'BlogDB')
BEGIN
	CREATE DATABASE BlogDB
END

USE [BlogDB]

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'ApplicationUser')
BEGIN
	CREATE TABLE ApplicationUser (
		ApplicationUserId INT NOT NULL IDENTITY (1,1),
		Username VARCHAR(20) NOT NULL,
		NormalizedUsername VARCHAR(20) NOT NULL,
		Email VARCHAR(30) NOT NULL,
		NormalizedEmail VARCHAR(30) NOT NULL,
		Fullname VARCHAR(30) NULL,
		PasswordHash NVARCHAR(MAX) NOT NULL,
		PRIMARY KEY(ApplicationUserId)
	)
	CREATE INDEX [IX_NormalizedUsername_] ON [dbo].[ApplicationUser] ([NormalizedUsername])

	CREATE INDEX [IX_NormalizedEmail_] ON [dbo].[ApplicationUser] ([NormalizedEmail])
END

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Photo') 
BEGIN
	CREATE TABLE Photo (
		PhotoId INT NOT NULL IDENTITY(1,1),
		ApplicationUserId INT NOT NULL,
		PublicId VARCHAR(50) NOT NULL,
		ImageUrl VARCHAR(250) NOT NULL,
		[Description] VARCHAR(30) NOT NULL,
		PublishDate DATETIME NOT NULL DEFAULT GETDATE(),
		UpdateDate DATETIME NOT NULL DEFAULT GETDATE(),
		PRIMARY KEY(PhotoId),
		FOREIGN KEY(ApplicationUserId) REFERENCES ApplicationUser(ApplicationUserId)
	)
END

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Blog')
BEGIN
	CREATE TABLE Blog (
		BlogId INT NOT NULL IDENTITY(1,1),
		ApplicationUserId INT NOT NULL,
		PhotoId INT NULL,
		Title VARCHAR(50) NOT NULL,
		Content VARCHAR(MAX) NOT NULL,
		PublishDate DATETIME NOT NULL DEFAULT GETDATE(),
		UpdateDate DATETIME NOT NULL DEFAULT GETDATE(),
		ActiveInd BIT NOT NULL DEFAULT CONVERT(BIT, 1),
		PRIMARY KEY(BlogId),
		FOREIGN KEY(ApplicationUserId) REFERENCES ApplicationUser(ApplicationUserId),
		FOREIGN KEY(PhotoId) REFERENCES Photo(PhotoId)
	)
END

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'BlogComment')
BEGIN
	CREATE TABLE BlogComment (
		BlogCommentId INT NOT NULL IDENTITY(1,1),
		ParentBlogCommentId INT NULL,
		BlogId INT NOT NULL,
		ApplicationUserId INT NOT NULL,
		Content VARCHAR(300) NOT NULL,
		PublishDate DATETIME NOT NULL DEFAULT GETDATE(),
		UpdateDate DATETIME NOT NULL DEFAULT GETDATE(),
		ActiveInd BIT NOT NULL DEFAULT CONVERT(BIT, 1),
		PRIMARY KEY(BlogCommentId),
		FOREIGN KEY(BlogId) REFERENCES Blog(BlogId),
		FOREIGN KEY(ApplicationUserId) REFERENCES ApplicationUser(ApplicationUserId)
	)
END

IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'aggregate' ) 
BEGIN
	EXEC sp_executesql N'CREATE SCHEMA aggregate'
END

IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'Blog' and schema_id = SCHEMA_ID('aggregate'))
BEGIN
	EXEC sp_executesql N'
	CREATE VIEW [aggregate].[Blog]
	AS
		SELECT 
			t1.BlogId,
			t1.ApplicationUserId,
			t2.Username,
			t1.Title,
			t1.Content,
			t1.PhotoId,
			t1.PublishDate,
			t1.UpdateDate,
			t1.ActiveInd
		FROM
			dbo.Blog t1
		INNER JOIN
			dbo.ApplicationUser t2 ON t1.ApplicationUserId = t2.ApplicationUserId'
END

IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'BlogComment' and schema_id = SCHEMA_ID('aggregate'))
BEGIN
	EXEC sp_executesql N'
	CREATE VIEW [aggregate].[BlogComment]
	AS
		SELECT 
			t1.BlogCommentId,
			t1.ParentBlogCommentId,
			t1.BlogId,
			t1.Content,
			t2.Username,
			t1.ApplicationUserId,
			t1.PublishDate,
			t1.UpdateDate,
			t1.ActiveInd
		FROM
			dbo.BlogComment t1
		INNER JOIN
			dbo.ApplicationUser t2 ON t1.ApplicationUserId = t2.ApplicationUserId'
END

--CREATE TYPES -----------------------------------------------

IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = 'AccountType' and schema_id = SCHEMA_ID('dbo'))
BEGIN
	CREATE TYPE [dbo].[AccountType] AS TABLE
	(
		[Username] VARCHAR(20) NOT NULL,
		[NormalizedUsername] VARCHAR(20) NOT NULL,
		[Email] VARCHAR(30) NOT NULL,
		[NormalizedEmail] VARCHAR(30) NOT NULL,
		[Fullname] VARCHAR(30) NULL,
		[PasswordHash] NVARCHAR(MAX) NOT NULL
	)
END

IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = 'PhotoType' and schema_id = SCHEMA_ID('dbo'))
BEGIN
	CREATE TYPE [dbo].[PhotoType] AS TABLE
	(
		[PublicId] VARCHAR(50) NOT NULL,
		[ImageUrl] VARCHAR(250) NOT NULL,
		[Description] VARCHAR(30) NOT NULL
	)
END

IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = 'BlogType' and schema_id = SCHEMA_ID('dbo'))
BEGIN
	CREATE TYPE [dbo].[BlogType] AS TABLE
	(
		[BlogId] INT NOT NULL,
		[Title] VARCHAR(50) NOT NULL,
		[Content] VARCHAR(MAX) NOT NULL,
		[PhotoId] INT NULL
	)
END

IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = 'BlogCommentType' and schema_id = SCHEMA_ID('dbo'))
BEGIN
	CREATE TYPE [dbo].[BlogCommentType] AS TABLE
	(
		[BlogCommentId] INT NOT NULL,
		[ParentBlogCommentId] INT NULL,
		[BlogId] INT NOT NULL,
		[Content]VARCHAR(300) NOT NULL
	)
END


--STORED PROCEDURES-----------------------------------

IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'Account_GetByUsername')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[Account_GetByUsername]
		@NormalizedUsername VARCHAR(20)
	AS
		SELECT 
			[ApplicationUserId]
			,[Username]
			,[NormalizedUsername]
			,[Email]
			,[NormalizedEmail]
			,[Fullname]
			,[PasswordHash]
		FROM
			[dbo].[ApplicationUser] t1
		WHERE t1.[NormalizedUsername] = @NormalizedUsername'
END

--drop procedure [dbo].[Account_GetByUsername]


IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'Account_Insert')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[Account_Insert]
		@Account AccountType READONLY
	AS
		INSERT INTO [dbo].[ApplicationUser]
           ([Username]
           ,[NormalizedUsername]
           ,[Email]
           ,[NormalizedEmail]
           ,[Fullname]
           ,[PasswordHash])
		SELECT 
			[Username]
			,[NormalizedUsername]
			,[Email]
			,[NormalizedEmail]
			,[Fullname]
			,[PasswordHash]
		FROM
			@Account

		SELECT CAST(SCOPE_IDENTITY() AS INT);'
END


IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'Blog_Delete')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[Blog_Delete]
	@BlogId INT
AS
	UPDATE [dbo].[BlogComment]
	SET 
		[ActiveInd] = CONVERT(BIT, 0), [UpdateDate] = GetDate()
	WHERE 
		[BlogId] = @BlogId;

	UPDATE [dbo].[Blog]
	SET
		[PhotoId] = NULL,
		[ActiveInd] = CONVERT(BIT, 0),
		[UpdateDate] = GetDate()
	WHERE
		BlogId = @BlogId'
END

IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'Blog_Get')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[Blog_Get]
		@BlogId INT
	AS
		SELECT [BlogId]
			,[ApplicationUserId]
			,[Username]
			,[Title]
			,[Content]
			,[PhotoId]
			,[PublishDate]
			,[UpdateDate]
		FROM 
			[aggregate].[Blog] t1
		WHERE
			t1.[BlogId] = @BlogId AND
			t1.[ActiveInd] = CONVERT(BIT, 1)'
END


IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'Blog_GetAll')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[Blog_GetAll]
		@Offset INT,
		@PageSize INT
	AS
		SELECT 
			[BlogId]
			,[ApplicationUserId]
			,[Username]
			,[Title]
			,[Content]
			,[PhotoId]
			,[PublishDate]
			,[UpdateDate]
		FROM
			[aggregate].[Blog] t1
		WHERE
			t1.[ActiveInd] = CONVERT(BIT, 1)
		ORDER BY
			t1.[BlogId]
		OFFSET @Offset ROWS
		FETCH NEXT @PageSize ROWS ONLY;

		SELECT COUNT(*) FROM [aggregate].[Blog] t1 WHERE t1.[ActiveInd] = CONVERT(BIT, 1);'
END

IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'Blog_GetAllFamous')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[Blog_GetAllFamous]
AS
	SELECT 
	TOP 6
		t1.[BlogId]
		,t1.[ApplicationUserId]
		,t1.[PhotoId]
		,t1.[Title]
		,t1.[Content]
		,t1.[PublishDate]
		,t1.[UpdateDate]
	FROM 
		[aggregate].[Blog] t1
	INNER JOIN
		[dbo].[BlogComment] t2 ON t1.[BlogId] = t2.[BlogId]
	WHERE
		t1.ActiveInd = CONVERT(BIT, 1) AND
		t2.ActiveInd = CONVERT(BIT, 1)
	GROUP BY
		t1.[BlogId]
		,t1.[ApplicationUserId]
		,t1.[PhotoId]
		,t1.[Title]
		,t1.[Content]
		,t1.[PublishDate]
		,t1.[UpdateDate]
	ORDER BY
		COUNT(t2.[BlogCommentId]) 
	DESC'
END

IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'Blog_GetByUserId')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[Blog_GetByUserId]
	@ApplicationUserId INT
AS
	SELECT 
		t1.[BlogId]
		,t1.[ApplicationUserId]
		,t1.[PhotoId]
		,t1.[Title]
		,t1.[Content]
		,t1.[PublishDate]
		,t1.[UpdateDate]
	FROM
		[aggregate].[Blog] t1
	WHERE
		t1.ApplicationUserId = @ApplicationUserId AND
		t1.ActiveInd = CONVERT(BIT, 1);'
END

IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'Blog_Upsert')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[Blog_Upsert]
	@Blog BlogType READONLY,
	@ApplicationUserId INT
	AS
		MERGE INTO [dbo].[Blog] TARGET
		USING (
			SELECT
				BlogId,
				@applicationUserId [ApplicationUserId],
				Title,
				Content,
				PhotoId
			FROM
				@Blog
		) AS SOURCE
		ON
		(
			TARGET.BlogId = SOURCE.BlogId AND TARGET.ApplicationUserId = SOURCE.ApplicationUserId
		)
		WHEN MATCHED THEN
			UPDATE SET
				TARGET.[Title] = SOURCE.[Title],
				TARGET.[Content] = SOURCE.[Content],
				TARGET.[PhotoId] = SOURCE.[PhotoId],
				TARGET.[UpdateDate] = GETDATE()
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (
				[ApplicationUserId],
				[Title],
				[Content],
				[PhotoId]
			)
			VALUES (
				SOURCE.[ApplicationUserId],
				SOURCE.[Title],
				SOURCE.[Content],
				SOURCE.[PhotoId]
			);

		SELECT CAST(SCOPE_IDENTITY() AS INT);'
END

IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'BlogComment_Delete')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[BlogComment_Delete]
	@BlogCommentId INT
	AS
		DROP TABLE IF EXISTS #BlogCommentsToBeDeleted;

		WITH cte_blogComments AS (
			SELECT 
				t1.[BlogCommentId],
				t1.[ParentBlogCommentId]
			FROM
				[dbo].[BlogComment] t1
			WHERE
				t1.[BlogCommentId] = @BlogCommentId
			UNION ALL
			SELECT 
				t2.[BlogCommentId],
				t2.[ParentBlogCommentId]
			FROM
				[dbo].[BlogComment] t2
				INNER JOIN cte_blogComments t3
					ON t3.[BlogCommentId] = t2.[ParentBlogCommentId]
		) 
		SELECT
			[BlogCommentId],
			[ParentBlogCommentId]
		INTO
			#BlogCommentsToBeDeleted
		FROM
			cte_blogComments

		Update t1
		SET
			t1.[ActiveInd] = CONVERT(BIT, 0),
			t1.[UpdateDate] = GETDATE()
		FROM
			[dbo].[BlogComment] t1
			INNER JOIN #BlogCommentsToBeDeleted t2
				ON t1.[BlogCommentId] = t2.[BlogCommentId];'
END

IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'BlogComment_Get')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[BlogComment_Get]
	@BlogCommentId INT
	AS
		SELECT 
			t1.[BlogCommentId]
			,t1.[ParentBlogCommentId]
			,t1.[BlogId]
			,t1.[ApplicationUserId]
			,t1.[Username]
			,t1.[Content]
			,t1.[PublishDate]
			,t1.[UpdateDate]
		FROM 
			[aggregate].[BlogComment] t1
		WHERE
			t1.[BlogCommentId] = @BlogCommentId AND
			t1.[ActiveInd] = CONVERT(BIT, 1)'
END


IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'BlogComment_GetAll')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[BlogComment_GetAll]
	@BlogId INT
	AS
		SELECT 
			t1.[BlogCommentId]
			,t1.[ParentBlogCommentId]
			,t1.[BlogId]
			,t1.[Content]
			,t1.[Username]
			,t1.[ApplicationUserId]
			,t1.[PublishDate]
			,t1.[UpdateDate]
			,t1.[ActiveInd]
		FROM
			[aggregate].[BlogComment] t1
		WHERE
			t1.[BlogId] = @BlogId AND
			t1.[ActiveInd] = CONVERT(BIT, 1)
		ORDER BY
			t1.[UpdateDate] 
		DESC'
END

IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'BlogComment_Upsert')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[BlogComment_Upsert]
		@BlogComment BlogCommentType READONLY,
		@ApplicationUserId INT
	AS
		MERGE INTO [dbo].[BlogComment] TARGET
		USING (
			SELECT
				[BlogCommentId],
				[ParentBlogCommentId],
				[BlogId],
				[Content],
				@ApplicationUserId [ApplicationUserId]
			FROM
				@BlogComment
		) AS SOURCE
		ON
		(
			TARGET.[BlogCommentId] = SOURCE.[BlogCommentId] AND TARGET.[ApplicationUserId] = SOURCE.[ApplicationUserId]
		)
		WHEN MATCHED THEN
			UPDATE SET
				TARGET.[Content] = SOURCE.[Content],
				TARGET.[UpdateDate] = GETDATE()
		WHEN NOT MATCHED THEN
			INSERT (
				[ParentBlogCommentId],
				[BlogId],
				[ApplicationUserId],
				[Content]
			)
			VALUES
			(
				SOURCE.[ParentBlogCommentId],
				SOURCE.[BlogId],
				SOURCE.[ApplicationUserId],
				SOURCE.[Content]
			);

		SELECT CAST(SCOPE_IDENTITY() AS INT);'
END



IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'Photo_Delete')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[Photo_Delete]
	@PhotoId INT
	AS
		DELETE FROM 
			[dbo].[Photo] 
		WHERE 
			[PhotoId] = @PhotoId'
END

IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'Photo_Get')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[Photo_Get]
	@PhotoId INT
	AS
		SELECT 
			t1.[PhotoId]
			,t1.[ApplicationUserId]
			,t1.[PublicId]
			,t1.[ImageUrl]
			,t1.[Description]
			,t1.[PublishDate]
			,t1.[UpdateDate]
		  FROM 
			[dbo].[Photo] t1
		  WHERE
			t1.[PhotoId] = @PhotoId'
END

IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'Photo_GetByUserId')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[Photo_GetByUserId]
		@ApplicationUserId INT
	AS
		SELECT 
			t1.[PhotoId]
			,t1.[ApplicationUserId]
			,t1.[PublicId]
			,t1.[ImageUrl]
			,t1.[Description]
			,t1.[PublishDate]
			,t1.[UpdateDate]
		FROM 
			[dbo].[Photo] t1
		WHERE
			t1.[ApplicationUserId] = @ApplicationUserId'
END

IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'Photo_Insert')
BEGIN
	EXEC sp_executesql N'
	CREATE PROCEDURE [dbo].[Photo_Insert]
	@Photo PhotoType READONLY,
	@ApplicationUserId INT
	AS
		INSERT INTO [dbo].[Photo]
			([ApplicationUserId]
			,[PublicId]
			,[ImageUrl]
			,[Description])
		SELECT
			@ApplicationUserId,
			[PublicId],
			[ImageUrl],
			[Description]
		FROM
			@Photo;

		SELECT CAST(SCOPE_IDENTITY() AS INT);'
END









	









