/****** Object:  Table [dbo].[mtUser]    Script Date: 06/27/2016 19:02:40 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtUser]') AND type in (N'U'))
DROP TABLE [dbo].[mtUser]
GO


/****** Object:  Table [dbo].[mtUser]    Script Date: 06/27/2016 19:02:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mtUser](
	[Id] [uniqueidentifier] NOT NULL,
	[UserName] [nvarchar](200) NULL,
	[IsActive] [bit] NOT NULL,
	[IsLocalUser] [bit] NULL,
	[Password] [nvarchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Table [dbo].[mtUser]    Script Date: 06/27/2016 19:08:50 ******/
INSERT [dbo].[mtUser] ([Id], [UserName], [IsActive], [IsLocalUser], [Password]) VALUES (N'0bc41bb7-dc4e-4e13-bf7d-311c12353d4d', N'b2c_team@unilever.com', 1, 1, N'123')
INSERT [dbo].[mtUser] ([Id], [UserName], [IsActive], [IsLocalUser], [Password]) VALUES (N'6b56efd8-7954-4fc1-985d-4abedf6a0f63', N'mt_finance_exec@unilever.com', 1, 1, N'123')
INSERT [dbo].[mtUser] ([Id], [UserName], [IsActive], [IsLocalUser], [Password]) VALUES (N'7f2939bf-e5c0-4dba-9ae7-55a1fed62dde', N'admin@unilever.com', 1, 1, N'123')
INSERT [dbo].[mtUser] ([Id], [UserName], [IsActive], [IsLocalUser], [Password]) VALUES (N'20a0cb49-e741-4538-974e-6eaf7f9fac13', N'anand.pawar@unilever.com', 1, 1, N'123')

---------------------   UserRole
INSERT [dbo].[mtUserRole] ([Id], [UserId], [RoleId]) VALUES (N'8f76058d-c449-4397-ad7f-7a4b77b90b32', N'0bc41bb7-dc4e-4e13-bf7d-311c12353d4d', N'bd46ed2b-00b8-47a0-853b-f6f95d158a05')
INSERT [dbo].[mtUserRole] ([Id], [UserId], [RoleId]) VALUES (N'4638abd9-d0bd-4ccb-90da-873a757085ba', N'7f2939bf-e5c0-4dba-9ae7-55a1fed62dde', N'caca17bd-b3ae-48fd-8997-ed334f1358c9')
INSERT [dbo].[mtUserRole] ([Id], [UserId], [RoleId]) VALUES (N'861c784b-ff6c-4996-9970-abfb6da7909f', N'6b56efd8-7954-4fc1-985d-4abedf6a0f63', N'1697032f-31dd-4371-bf77-8bc8b68b0f09')
INSERT [dbo].[mtUserRole] ([Id], [UserId], [RoleId]) VALUES (N'af592d49-543d-4b1f-ae62-f33df5597a9b', N'20a0cb49-e741-4538-974e-6eaf7f9fac13', N'bd46ed2b-00b8-47a0-853b-f6f95d158a05')
---------------------- Role
INSERT [dbo].[mtRole] ([Id], [RoleName]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'MT finance Exec')
INSERT [dbo].[mtRole] ([Id], [RoleName]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'Admin')
INSERT [dbo].[mtRole] ([Id], [RoleName]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'B2C team')

/****** Object:  Table [dbo].[RoleWisePageRightsMaster]    Script Date: 06/28/2016 11:52:07 ******/
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'CUSTGRP', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'SKU', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'SALESTAXRATE', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'OUTLETMASTER', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'ADDMARGIN', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'SERVICETAX', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'HUGGIESBAEPACK', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'CLUSTERRSCODE', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'TIERBASEDTOT', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'SUBCATMAPPING', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'SUBCATBASEDTOT', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'UPSEC', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'GSV', 0, 0, 0, 1)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'PVSION', 0, 0, 0, 1)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'JV', 0, 0, 0, 1)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'ExportJV', 0, 0, 1, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'9a2252f2-9063-4a6b-99f7-eb82e10062cb', N'CLSMOC', 0, 0, 0, 1)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'CUSTGRP', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'SKU', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'SALESTAXRATE', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'OUTLETMASTER', 1, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'ADDMARGIN', 1, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'SERVICETAX', 1, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'HUGGIESBAEPACK', 1, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'CLUSTERRSCODE', 1, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'TIERBASEDTOT', 1, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'SUBCATMAPPING', 1, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'SUBCATBASEDTOT', 1, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'UPSEC', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'GSV', 0, 0, 0, 1)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'PVSION', 0, 0, 0, 1)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'JV', 0, 0, 0, 1)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'ExportJV', 0, 0, 1, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'CLSMOC', 0, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'CUSTGRP', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'SKU', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'SALESTAXRATE', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'OUTLETMASTER', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'ADDMARGIN', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'SERVICETAX', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'HUGGIESBAEPACK', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'CLUSTERRSCODE', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'TIERBASEDTOT', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'SUBCATMAPPING', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'SUBCATBASEDTOT', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'UPSEC', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'GSV', 0, 0, 0, 1)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'PVSION', 0, 0, 0, 1)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'JV', 0, 0, 0, 1)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'ExportJV', 0, 0, 1, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'CLSMOC', 0, 0, 0, 1)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'CUSTGRP', 1, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'SKU', 1, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'SALESTAXRATE', 1, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'OUTLETMASTER', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'ADDMARGIN', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'SERVICETAX', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'HUGGIESBAEPACK', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'CLUSTERRSCODE', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'TIERBASEDTOT', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'SUBCATMAPPING', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'SUBCATBASEDTOT', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'UPSEC', 1, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'GSV', 0, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'PVSION', 0, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'JV', 0, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'ExportJV', 0, 0, 1, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'CLSMOC', 0, 0, 0, 0)
