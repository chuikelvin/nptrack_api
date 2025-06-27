-- =============================================
-- NpTrack Database Initialization Script
-- Compatible with any MSSQL Server instance
-- =============================================

USE [master]
GO

-- Ceate database if it doesn't exist (using default file locations)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'NpTrack')
BEGIN
    CREATE DATABASE [NpTrack]
    PRINT 'Database NpTrack created successfully.'
END
ELSE
BEGIN
    PRINT 'Database NpTrack already exists.'
END
GO

-- Only set database properties if the database was just created
-- This prevents conflicts with existing databases
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'NpTrack' AND create_date > DATEADD(MINUTE, -5, GETDATE()))
BEGIN
    PRINT 'Database already exists, skipping property settings to avoid conflicts.'
END
ELSE
BEGIN
    -- Set database properties only for newly created databases
    ALTER DATABASE [NpTrack] SET COMPATIBILITY_LEVEL = 120
    GO
    
    -- Enable full-text search if available
    IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
    BEGIN
        EXEC [NpTrack].[dbo].[sp_fulltext_database] @action = 'enable'
    END
    GO
    
    -- Set database options
    ALTER DATABASE [NpTrack] SET ANSI_NULL_DEFAULT OFF 
    GO
    ALTER DATABASE [NpTrack] SET ANSI_NULLS OFF 
    GO
    ALTER DATABASE [NpTrack] SET ANSI_PADDING OFF 
    GO
    ALTER DATABASE [NpTrack] SET ANSI_WARNINGS OFF 
    GO
    ALTER DATABASE [NpTrack] SET ARITHABORT OFF 
    GO
    ALTER DATABASE [NpTrack] SET AUTO_CLOSE OFF 
    GO
    ALTER DATABASE [NpTrack] SET AUTO_SHRINK OFF 
    GO
    ALTER DATABASE [NpTrack] SET AUTO_UPDATE_STATISTICS ON 
    GO
    ALTER DATABASE [NpTrack] SET CURSOR_CLOSE_ON_COMMIT OFF 
    GO
    ALTER DATABASE [NpTrack] SET CURSOR_DEFAULT GLOBAL 
    GO
    ALTER DATABASE [NpTrack] SET CONCAT_NULL_YIELDS_NULL OFF 
    GO
    ALTER DATABASE [NpTrack] SET NUMERIC_ROUNDABORT OFF 
    GO
    ALTER DATABASE [NpTrack] SET QUOTED_IDENTIFIER OFF 
    GO
    ALTER DATABASE [NpTrack] SET RECURSIVE_TRIGGERS OFF 
    GO
    ALTER DATABASE [NpTrack] SET DISABLE_BROKER 
    GO
    ALTER DATABASE [NpTrack] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
    GO
    ALTER DATABASE [NpTrack] SET DATE_CORRELATION_OPTIMIZATION OFF 
    GO
    ALTER DATABASE [NpTrack] SET TRUSTWORTHY OFF 
    GO
    ALTER DATABASE [NpTrack] SET ALLOW_SNAPSHOT_ISOLATION OFF 
    GO
    ALTER DATABASE [NpTrack] SET PARAMETERIZATION SIMPLE 
    GO
    ALTER DATABASE [NpTrack] SET READ_COMMITTED_SNAPSHOT OFF 
    GO
    ALTER DATABASE [NpTrack] SET HONOR_BROKER_PRIORITY OFF 
    GO
    ALTER DATABASE [NpTrack] SET RECOVERY SIMPLE 
    GO
    ALTER DATABASE [NpTrack] SET MULTI_USER 
    GO
    ALTER DATABASE [NpTrack] SET PAGE_VERIFY CHECKSUM  
    GO
    ALTER DATABASE [NpTrack] SET DB_CHAINING OFF 
    GO
    ALTER DATABASE [NpTrack] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
    GO
    ALTER DATABASE [NpTrack] SET TARGET_RECOVERY_TIME = 0 SECONDS 
    GO
    ALTER DATABASE [NpTrack] SET DELAYED_DURABILITY = DISABLED 
    GO
    PRINT 'Database properties set successfully.'
END
GO

-- Switch to NpTrack database
USE [NpTrack]
GO

-- =============================================
-- Create Tables (with proper error handling)
-- =============================================

-- Alerts table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Alerts' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Alerts](
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [Message] [varchar](50) NOT NULL,
        [Vehicle] [varchar](50) NOT NULL,
        [TypeOfMessage] [varchar](50) NULL CONSTRAINT [DF_Alerts_TypeOfMessage] DEFAULT ('unknown'),
        [Status] [varchar](50) NULL CONSTRAINT [DF_Alerts_Status] DEFAULT ((0)),
        [Location] [varchar](50) NULL,
        [CreatedAt] [datetime] NULL CONSTRAINT [DF_Alerts_CreatedAt] DEFAULT (getdate()),
        [UpdatedAt] [datetime] NULL CONSTRAINT [DF_Alerts_UpdatedAt] DEFAULT (getdate()),
        CONSTRAINT [PK_Alerts] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    PRINT 'Table Alerts created successfully.'
END
ELSE
BEGIN
    PRINT 'Table Alerts already exists.'
END
GO

-- Fleets table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Fleets' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Fleets](
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [Name] [varchar](50) NOT NULL,
        [Code] [varchar](50) NOT NULL,
        [Location] [varchar](150) NULL,
        [FleetManager] [varchar](50) NULL,
        [CreatedAt] [datetime] NULL CONSTRAINT [DF_Fleet_CreatedAt] DEFAULT (getdate()),
        [UpdatedAt] [datetime] NULL CONSTRAINT [DF_Fleet_UpdatedAt] DEFAULT (getdate()),
        CONSTRAINT [PK_Fleet] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    PRINT 'Table Fleets created successfully.'
END
ELSE
BEGIN
    PRINT 'Table Fleets already exists.'
END
GO

-- GeofenceBoundary table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='GeofenceBoundary' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[GeofenceBoundary](
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [FleetId] [bigint] NOT NULL,
        [Name] [varchar](50) NULL,
        [Code] [varchar](50) NULL,
        [Boundary] [varchar](300) NOT NULL,
        [CreatedBy] [varchar](50) NULL,
        [CreatedAt] [datetime] NULL CONSTRAINT [DF_GeofenceBoundary_CreatedAt] DEFAULT (getdate()),
        [UpdatedBy] [varchar](50) NULL,
        [UpdatedAt] [datetime] NULL CONSTRAINT [DF_GeofenceBoundary_UpdatedAt] DEFAULT (getdate()),
        CONSTRAINT [PK_GeofenceBoundary] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    PRINT 'Table GeofenceBoundary created successfully.'
END
ELSE
BEGIN
    PRINT 'Table GeofenceBoundary already exists.'
END
GO

-- idmsSysLog table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='idmsSysLog' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[idmsSysLog](
        [LogNo] [int] IDENTITY(1,1) NOT NULL,
        [LogDate] [datetime] NULL CONSTRAINT [DF_idmsSysLog_LogDate] DEFAULT (getdate()),
        [LogType] [varchar](200) NULL,
        [UserName] [varchar](150) NULL,
        [Source] [varchar](150) NULL,
        [Process] [varchar](150) NULL,
        [FolderNo] [int] NULL,
        [RecordID] [int] NULL,
        [Data] [nvarchar](max) NULL
    )
    PRINT 'Table idmsSysLog created successfully.'
END
ELSE
BEGIN
    PRINT 'Table idmsSysLog already exists.'
END
GO

-- LoginValidation table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='LoginValidation' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[LoginValidation](
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [UserId] [uniqueidentifier] NOT NULL,
        [Password] [varchar](200) NOT NULL,
        [OTP] [varchar](200) NULL,
        [OTPVerified] [int] NULL,
        [LoginTrials] [int] NULL,
        [Status] [int] NULL,
        [ChangePassword] [int] NULL,
        [OTPExpiry] [varchar](200) NULL,
        [CreatedAt] [datetime] NULL CONSTRAINT [DF_LoginValidation_CreatedAt] DEFAULT (getdate()),
        [UpdatedAt] [datetime] NULL CONSTRAINT [DF_LoginValidation_UpdatedAt] DEFAULT (getdate()),
        [Reference] [varchar](50) NULL,
        CONSTRAINT [PK_LoginValidation] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    PRINT 'Table LoginValidation created successfully.'
END
ELSE
BEGIN
    PRINT 'Table LoginValidation already exists.'
END
GO

-- Permissions table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Permissions' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Permissions](
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [Name] [varchar](50) NOT NULL,
        [CreatedAt] [datetime] NULL CONSTRAINT [DF_Permissions_CreatedAt] DEFAULT (getdate()),
        [UpdatedAt] [datetime] NULL CONSTRAINT [DF_Permissions_UpdatedAt] DEFAULT (getdate()),
        CONSTRAINT [PK_Permissions] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    PRINT 'Table Permissions created successfully.'
END
ELSE
BEGIN
    PRINT 'Table Permissions already exists.'
END
GO

-- RoleHasPermissions table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='RoleHasPermissions' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[RoleHasPermissions](
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [RoleId] [bigint] NOT NULL,
        [PermissionId] [bigint] NOT NULL,
        [CreatedAt] [datetime] NULL CONSTRAINT [DF_RoleHasPermissions_CreatedAt] DEFAULT (getdate()),
        [UpdatedAt] [datetime] NULL CONSTRAINT [DF_RoleHasPermissions_UpdatedAt] DEFAULT (getdate()),
        CONSTRAINT [PK_RoleHasPermissions] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    PRINT 'Table RoleHasPermissions created successfully.'
END
ELSE
BEGIN
    PRINT 'Table RoleHasPermissions already exists.'
END
GO

-- Roles table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Roles' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Roles](
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [Name] [varchar](50) NOT NULL,
        [CreatedAt] [datetime] NULL CONSTRAINT [DF_Roles_CreatedAt] DEFAULT (getdate()),
        [UpdatedAt] [datetime] NULL CONSTRAINT [DF_Roles_UpdatedAt] DEFAULT (getdate()),
        CONSTRAINT [PK_Roles] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    PRINT 'Table Roles created successfully.'
END
ELSE
BEGIN
    PRINT 'Table Roles already exists.'
END
GO

-- Trips table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Trips' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Trips](
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [Location] [varchar](150) NULL,
        [TimeStamp] [datetime] NULL,
        [Vehicle] [varchar](50) NULL,
        [InitialPoint] [varchar](150) NULL,
        [Destination] [varchar](150) NULL,
        [CreatedAt] [datetime] NULL CONSTRAINT [DF_Trips_CreatedAt] DEFAULT (getdate()),
        [UpdatedAt] [datetime] NULL CONSTRAINT [DF_Trips_UpdatedAt] DEFAULT (getdate()),
        CONSTRAINT [PK_Trips] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    PRINT 'Table Trips created successfully.'
END
ELSE
BEGIN
    PRINT 'Table Trips already exists.'
END
GO

-- Users table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Users](
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [Uuid] [uniqueidentifier] NULL CONSTRAINT [DF_Users_Uuid] DEFAULT (newid()),
        [FirstName] [varchar](50) NOT NULL,
        [LastName] [varchar](50) NULL,
        [IdNumber] [varchar](50) NULL,
        [Username] [varchar](50) NOT NULL,
        [Email] [varchar](50) NULL,
        [PhoneNumber] [varchar](50) NOT NULL,
        [Role] [varchar](50) NOT NULL,
        [Channel] [varchar](50) NULL,
        [Password] [varchar](200) NULL,
        [Status] [int] NULL CONSTRAINT [DF_Users_Status] DEFAULT ((0)),
        [CreatedAt] [datetime] NULL CONSTRAINT [DF_Users_CreatedAt] DEFAULT (getdate()),
        [CreatedBy] [varchar](50) NULL,
        [UpdatedAt] [datetime] NULL CONSTRAINT [DF_Users_UpdatedAt] DEFAULT (getdate()),
        [UpdatedBy] [varchar](50) NULL,
        CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    PRINT 'Table Users created successfully.'
END
ELSE
BEGIN
    PRINT 'Table Users already exists.'
END
GO

-- Vehicles table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Vehicles' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Vehicles](
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [NumberPlate] [varchar](50) NOT NULL,
        [Status] [varchar](50) NOT NULL CONSTRAINT [DF_Vehicles_Status] DEFAULT ((0)),
        [FleetCode] [varchar](50) NULL,
        [Driver] [bigint] NULL,
        [VehicleType] [varchar](50) NULL,
        [ManufacturedBy] [varchar](50) NULL,
        [CreatedAt] [datetime] NULL CONSTRAINT [DF_Vehicles_CreatedAt] DEFAULT (getdate()),
        [UpdatedAt] [datetime] NULL CONSTRAINT [DF_Vehicles_UpdatedAt] DEFAULT (getdate()),
        CONSTRAINT [PK_Vehicles] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    PRINT 'Table Vehicles created successfully.'
END
ELSE
BEGIN
    PRINT 'Table Vehicles already exists.'
END
GO

-- VehicleTypes table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='VehicleTypes' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[VehicleTypes](
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [Name] [varchar](50) NOT NULL,
        [CreatedAt] [datetime] NULL CONSTRAINT [DF_VehicleTypes_CreatedAt] DEFAULT (getdate()),
        [UpdatedAt] [datetime] NULL CONSTRAINT [DF_VehicleTypes_UpdatedAt] DEFAULT (getdate()),
        CONSTRAINT [PK_VehicleTypes] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    PRINT 'Table VehicleTypes created successfully.'
END
ELSE
BEGIN
    PRINT 'Table VehicleTypes already exists.'
END
GO

-- =============================================
-- Insert Initial Data (only if tables are empty)
-- =============================================

-- Insert Alerts data
IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[Alerts])
BEGIN
    SET IDENTITY_INSERT [dbo].[Alerts] ON
    INSERT [dbo].[Alerts] ([Id], [Message], [Vehicle], [TypeOfMessage], [Status], [Location], [CreatedAt], [UpdatedAt]) 
    VALUES (1, N'You are going out of bounds', N'KCT 343E', N'Geofence', N'0', NULL, CAST(N'2025-05-11 20:05:19.073' AS DateTime), CAST(N'2025-05-11 20:05:19.073' AS DateTime))
    INSERT [dbo].[Alerts] ([Id], [Message], [Vehicle], [TypeOfMessage], [Status], [Location], [CreatedAt], [UpdatedAt]) 
    VALUES (2, N'new alert here', N'kbc 0093', N'Maintenance', N'0', NULL, CAST(N'2025-06-22 16:34:04.000' AS DateTime), CAST(N'2025-06-22 16:34:04.000' AS DateTime))
    SET IDENTITY_INSERT [dbo].[Alerts] OFF
    PRINT 'Initial Alerts data inserted.'
END

-- Insert Permissions data
IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[Permissions])
BEGIN
    SET IDENTITY_INSERT [dbo].[Permissions] ON
    INSERT [dbo].[Permissions] ([Id], [Name], [CreatedAt], [UpdatedAt]) VALUES (1, N'create_users', CAST(N'2025-05-07 12:34:05.100' AS DateTime), CAST(N'2025-05-07 12:34:05.100' AS DateTime))
    INSERT [dbo].[Permissions] ([Id], [Name], [CreatedAt], [UpdatedAt]) VALUES (2, N'view_users', CAST(N'2025-05-10 12:13:59.357' AS DateTime), CAST(N'2025-05-10 12:13:59.357' AS DateTime))
    INSERT [dbo].[Permissions] ([Id], [Name], [CreatedAt], [UpdatedAt]) VALUES (3, N'manage_users', CAST(N'2025-05-11 14:21:37.690' AS DateTime), CAST(N'2025-05-11 14:21:37.690' AS DateTime))
    INSERT [dbo].[Permissions] ([Id], [Name], [CreatedAt], [UpdatedAt]) VALUES (4, N'view_roles', CAST(N'2025-05-11 14:21:45.150' AS DateTime), CAST(N'2025-05-11 14:21:45.150' AS DateTime))
    INSERT [dbo].[Permissions] ([Id], [Name], [CreatedAt], [UpdatedAt]) VALUES (5, N'view_permissions', CAST(N'2025-05-11 14:21:56.090' AS DateTime), CAST(N'2025-05-11 14:21:56.090' AS DateTime))
    SET IDENTITY_INSERT [dbo].[Permissions] OFF
    PRINT 'Initial Permissions data inserted.'
END

-- Insert Roles data
IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[Roles])
BEGIN
    SET IDENTITY_INSERT [dbo].[Roles] ON
    INSERT [dbo].[Roles] ([Id], [Name], [CreatedAt], [UpdatedAt]) VALUES (1, N'SuperAdmin', CAST(N'2025-05-07 10:37:14.727' AS DateTime), CAST(N'2025-05-07 10:37:14.727' AS DateTime))
    INSERT [dbo].[Roles] ([Id], [Name], [CreatedAt], [UpdatedAt]) VALUES (2, N'User', CAST(N'2025-05-11 14:35:23.580' AS DateTime), CAST(N'2025-05-11 14:35:23.580' AS DateTime))
    INSERT [dbo].[Roles] ([Id], [Name], [CreatedAt], [UpdatedAt]) VALUES (3, N'User', CAST(N'2025-05-11 14:36:32.970' AS DateTime), CAST(N'2025-05-11 14:36:32.970' AS DateTime))
    SET IDENTITY_INSERT [dbo].[Roles] OFF
    PRINT 'Initial Roles data inserted.'
END

-- Insert RoleHasPermissions data
IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[RoleHasPermissions])
BEGIN
    SET IDENTITY_INSERT [dbo].[RoleHasPermissions] ON
    INSERT [dbo].[RoleHasPermissions] ([Id], [RoleId], [PermissionId], [CreatedAt], [UpdatedAt]) VALUES (1, 1, 1, CAST(N'2025-05-07 12:33:13.350' AS DateTime), CAST(N'2025-05-07 12:33:13.350' AS DateTime))
    INSERT [dbo].[RoleHasPermissions] ([Id], [RoleId], [PermissionId], [CreatedAt], [UpdatedAt]) VALUES (2, 1, 2, CAST(N'2025-05-07 12:14:13.657' AS DateTime), CAST(N'2025-05-07 12:14:13.657' AS DateTime))
    INSERT [dbo].[RoleHasPermissions] ([Id], [RoleId], [PermissionId], [CreatedAt], [UpdatedAt]) VALUES (3, 1, 3, CAST(N'2025-05-07 12:22:14.190' AS DateTime), CAST(N'2025-05-07 12:22:14.190' AS DateTime))
    INSERT [dbo].[RoleHasPermissions] ([Id], [RoleId], [PermissionId], [CreatedAt], [UpdatedAt]) VALUES (4, 1, 4, CAST(N'2025-05-07 12:22:17.580' AS DateTime), CAST(N'2025-05-07 12:22:17.580' AS DateTime))
    INSERT [dbo].[RoleHasPermissions] ([Id], [RoleId], [PermissionId], [CreatedAt], [UpdatedAt]) VALUES (5, 1, 5, CAST(N'2025-05-07 12:22:25.270' AS DateTime), CAST(N'2025-05-07 12:22:25.270' AS DateTime))
    INSERT [dbo].[RoleHasPermissions] ([Id], [RoleId], [PermissionId], [CreatedAt], [UpdatedAt]) VALUES (6, 3, 2, CAST(N'2025-05-07 12:36:32.973' AS DateTime), CAST(N'2025-05-07 12:36:32.973' AS DateTime))
    INSERT [dbo].[RoleHasPermissions] ([Id], [RoleId], [PermissionId], [CreatedAt], [UpdatedAt]) VALUES (7, 3, 4, CAST(N'2025-05-07 12:36:32.973' AS DateTime), CAST(N'2025-05-07 12:36:32.973' AS DateTime))
    SET IDENTITY_INSERT [dbo].[RoleHasPermissions] OFF
    PRINT 'Initial RoleHasPermissions data inserted.'
END

-- Insert Users data
IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[Users])
BEGIN
    SET IDENTITY_INSERT [dbo].[Users] ON
    INSERT [dbo].[Users] ([Id], [Uuid], [FirstName], [LastName], [IdNumber], [Username], [Email], [PhoneNumber], [Role], [Channel], [Password], [Status], [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy]) 
    VALUES (1, N'65ea960d-5640-4a91-b35f-099879d5df1d', N'Calvin', N'Njuguna', N'36519838', N'Valcin', N'ncalvin67@gmail.com', N'254701141934', N'1', N'WEB', N'baa6dcc455cd7c5881d6897df95d303aa2feccb7549eb001637b224a195884f4', 1, CAST(N'2025-05-07 12:30:01.983' AS DateTime), NULL, CAST(N'2025-05-07 12:30:01.983' AS DateTime), NULL)
    INSERT [dbo].[Users] ([Id], [Uuid], [FirstName], [LastName], [IdNumber], [Username], [Email], [PhoneNumber], [Role], [Channel], [Password], [Status], [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy]) 
    VALUES (2, N'7e294879-3bc6-4cdc-8795-3c00e78b6bb9', N'Kelvin', N'Chui', N'34004142', N'Kelvin', N'chuikelvin2@gmail.com', N'254703719594', N'1', N'WEB', N'7284845179ccfc0253f9ecfaf3e5512ab6464f297841b94e3bc2e1fabbada222', 1, CAST(N'2025-05-11 14:59:16.637' AS DateTime), NULL, CAST(N'2025-05-11 14:59:16.637' AS DateTime), NULL)
    SET IDENTITY_INSERT [dbo].[Users] OFF
    PRINT 'Initial Users data inserted.'
END

-- Insert LoginValidation data
IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[LoginValidation])
BEGIN
    SET IDENTITY_INSERT [dbo].[LoginValidation] ON
    INSERT [dbo].[LoginValidation] ([Id], [UserId], [Password], [OTP], [OTPVerified], [LoginTrials], [Status], [ChangePassword], [OTPExpiry], [CreatedAt], [UpdatedAt], [Reference]) 
    VALUES (1, N'65ea960d-5640-4a91-b35f-099879d5df1d', N'7d83021c59894b9e01bd0e3ff844f6b6a73a122ad84ea79b0015717e7a9d8614', N'5cd79463ddd1c6f9bc7e5e3c300099f41cce682d22e0ddab4fcd8cced2e5b50a', 1, 0, 1, 0, N'Jun 19 2025  8:31PM', CAST(N'2025-05-07 12:30:01.987' AS DateTime), CAST(N'2025-06-19 20:29:44.920' AS DateTime), N'889249')
    INSERT [dbo].[LoginValidation] ([Id], [UserId], [Password], [OTP], [OTPVerified], [LoginTrials], [Status], [ChangePassword], [OTPExpiry], [CreatedAt], [UpdatedAt], [Reference]) 
    VALUES (2, N'7e294879-3bc6-4cdc-8795-3c00e78b6bb9', N'67bb213537cc67dde08b10a26d821a5ab366a2299ac20cec70a0554d8c831046', N'2a7ea207765edd8ca7cc11951a0293adec86eb8a8e7edb43c9eb434964dfadc5', 1, 1, 1, 0, N'May 11 2025  9:22PM', CAST(N'2025-05-11 14:59:16.650' AS DateTime), CAST(N'2025-06-19 20:06:29.147' AS DateTime), N'417995')
    SET IDENTITY_INSERT [dbo].[LoginValidation] OFF
    PRINT 'Initial LoginValidation data inserted.'
END

-- Insert VehicleTypes data
IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[VehicleTypes])
BEGIN
    SET IDENTITY_INSERT [dbo].[VehicleTypes] ON
    INSERT [dbo].[VehicleTypes] ([Id], [Name], [CreatedAt], [UpdatedAt]) VALUES (1, N'truck', CAST(N'2025-05-11 13:53:21.477' AS DateTime), CAST(N'2025-05-11 13:53:21.477' AS DateTime))
    SET IDENTITY_INSERT [dbo].[VehicleTypes] OFF
    PRINT 'Initial VehicleTypes data inserted.'
END

-- Insert Vehicles data
IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[Vehicles])
BEGIN
    SET IDENTITY_INSERT [dbo].[Vehicles] ON
    INSERT [dbo].[Vehicles] ([Id], [NumberPlate], [Status], [FleetCode], [Driver], [VehicleType], [ManufacturedBy], [CreatedAt], [UpdatedAt]) 
    VALUES (1, N'KCT 343E', N'1', N'001', 1, N'1', N'Mercedes', CAST(N'2025-05-11 13:33:51.360' AS DateTime), CAST(N'2025-05-11 13:33:51.360' AS DateTime))
    INSERT [dbo].[Vehicles] ([Id], [NumberPlate], [Status], [FleetCode], [Driver], [VehicleType], [ManufacturedBy], [CreatedAt], [UpdatedAt]) 
    VALUES (2, N'KAA 007S', N'1', N'002', 2, N'1', N'Aston Martin Db7', CAST(N'2025-05-11 20:15:04.693' AS DateTime), CAST(N'2025-05-11 20:15:04.693' AS DateTime))
    INSERT [dbo].[Vehicles] ([Id], [NumberPlate], [Status], [FleetCode], [Driver], [VehicleType], [ManufacturedBy], [CreatedAt], [UpdatedAt]) 
    VALUES (3, N'kAA 001A', N'1', N'9090', 1, N'1', N'Porshe', CAST(N'2025-06-22 14:02:26.053' AS DateTime), CAST(N'2025-06-22 14:02:26.053' AS DateTime))
    SET IDENTITY_INSERT [dbo].[Vehicles] OFF
    PRINT 'Initial Vehicles data inserted.'
END

-- Insert sample system logs (only a few recent ones to avoid overwhelming the log)
IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[idmsSysLog])
BEGIN
    SET IDENTITY_INSERT [dbo].[idmsSysLog] ON
    INSERT [dbo].[idmsSysLog] ([LogNo], [LogDate], [LogType], [UserName], [Source], [Process], [FolderNo], [RecordID], [Data]) 
    VALUES (1, CAST(N'2025-06-22 16:40:45.970' AS DateTime), N'UPDATE_ALERT', N'Calvin Njuguna', N'', N'UPDATE', 0, NULL, N'{"channel":"WEB","Id":"2","Status":"0","validation":"pass"}')
    INSERT [dbo].[idmsSysLog] ([LogNo], [LogDate], [LogType], [UserName], [Source], [Process], [FolderNo], [RecordID], [Data]) 
    VALUES (2, CAST(N'2025-06-22 16:34:04.007' AS DateTime), N'CREATE_ALERTS', N'Calvin Njuguna', N'', N'CREATE', NULL, 2, N'{"channel":"WEB","Message":"new alert here","Vehicle":"kbc 0093","TypeOfMessage":"Maintenance","validation":"pass"}')
    SET IDENTITY_INSERT [dbo].[idmsSysLog] OFF
    PRINT 'Initial system logs inserted.'
END

-- Set database to READ_WRITE
USE [master]
GO
ALTER DATABASE [NpTrack] SET READ_WRITE 
GO

PRINT '============================================='
PRINT 'NpTrack Database initialization completed successfully!'
PRINT 'Database: NpTrack'
PRINT 'Tables created: Alerts, Fleets, GeofenceBoundary, idmsSysLog, LoginValidation, Permissions, RoleHasPermissions, Roles, Trips, Users, Vehicles, VehicleTypes'
PRINT 'Initial data loaded successfully.'
PRINT '============================================='
GO
