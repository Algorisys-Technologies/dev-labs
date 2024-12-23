
/****** Object:  Table [dbo].[mtMailStatusDetail]    Script Date: 09/16/2016 10:11:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[mtMailStatusDetail](
	[MsgId] [uniqueidentifier] NULL,
	[Subject] [nvarchar](250) NULL,
	[MailFrom] [nvarchar](250) NULL,
	[MailTo] [nvarchar](max) NULL,
	[MailCC] [nvarchar](250) NULL,
	[MsgBody] [nvarchar](max) NULL,
	[Status] [char](1) NULL,
	[Date] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO




/****** Object:  StoredProcedure [dbo].[Insert_MailSendDetail]    Script Date: 09/16/2016 10:14:28 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Insert_MailSendDetail]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Insert_MailSendDetail]
GO


/****** Object:  StoredProcedure [dbo].[Insert_MailSendDetail]    Script Date: 09/16/2016 10:14:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[Insert_MailSendDetail]
@Subject varchar(200),
@MailFrom varchar(200),
@MailTo varchar(Max),
@MailCC varchar(200),
@MsgBody varchar(Max),
@Status char(1)

as 
begin
SET NOCOUNT ON;

insert into mtMailStatusDetail values( NEWID(),@Subject,@MailFrom,@MailTo,@MailCC,@MsgBody,@Status,getdate())



END
GO

/****** Object:  Table [dbo].[mtMailConfig]    Script Date: 09/16/2016 10:26:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mtMailConfig](
	[ConfigId] [nvarchar](250) NULL,
	[Description] [nvarchar](250) NULL,
	[MailFrom] [nvarchar](250) NULL,
	[SenderPassword] [nvarchar](250) NULL,
	[MailTo] [nvarchar](max) NULL,
	[MailCC] [nvarchar](max) NULL,
	[Enable] [bit] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Default [DF_mtMailConfig_Enable]    Script Date: 09/16/2016 10:26:00 ******/
ALTER TABLE [dbo].[mtMailConfig] ADD  CONSTRAINT [DF_mtMailConfig_Enable]  DEFAULT ((0)) FOR [Enable]
GO

DELETE FROM mtMailConfig
/****** Object:  Table [dbo].[mtMailConfig]    Script Date: 09/16/2016 10:33:48 ******/
INSERT [dbo].[mtMailConfig] ([ConfigId], [Description], [MailFrom], [SenderPassword], [MailTo], [MailCC], [Enable]) VALUES (N'TIERBASEDTOT', N'Tier Based TOT Master', N'pankaj.gholap@unilever.com', N'J9WGiMvuf2yEmnpQuFkZh2RoL4EM2biADM9S99FerXg=', N'pankaj.gholap.info@gmail.com,urvashi.sachdev@tekacademy.com', N'', 1)
INSERT [dbo].[mtMailConfig] ([ConfigId], [Description], [MailFrom], [SenderPassword], [MailTo], [MailCC], [Enable]) VALUES (N'SUBCATBASEDTOT', N'MT Subcategory TOT % Master ', N'pankaj.gholap@unilever.com', N'J9WGiMvuf2yEmnpQuFkZh2RoL4EM2biADM9S99FerXg=', N'pankaj.gholap.info@gmail.com,urvashi.sachdev@tekacademy.com', N'', 1)
INSERT [dbo].[mtMailConfig] ([ConfigId], [Description], [MailFrom], [SenderPassword], [MailTo], [MailCC], [Enable]) VALUES (N'CUSTGRP', N'Customer Group Master', NULL, NULL, NULL, NULL, 1)
INSERT [dbo].[mtMailConfig] ([ConfigId], [Description], [MailFrom], [SenderPassword], [MailTo], [MailCC], [Enable]) VALUES (N'SKU', N'SKU Dump Master', NULL, NULL, NULL, NULL, 1)
INSERT [dbo].[mtMailConfig] ([ConfigId], [Description], [MailFrom], [SenderPassword], [MailTo], [MailCC], [Enable]) VALUES (N'SALESTAXRATE', N'Sales Tax Rate Master', NULL, NULL, NULL, NULL, 1)
INSERT [dbo].[mtMailConfig] ([ConfigId], [Description], [MailFrom], [SenderPassword], [MailTo], [MailCC], [Enable]) VALUES (N'OUTLETMASTER', N'Outlet Master', NULL, NULL, NULL, NULL, 1)
INSERT [dbo].[mtMailConfig] ([ConfigId], [Description], [MailFrom], [SenderPassword], [MailTo], [MailCC], [Enable]) VALUES (N'ADDMARGIN', N'Addtional Margin Master',N'pankaj.gholap@unilever.com', N'J9WGiMvuf2yEmnpQuFkZh2RoL4EM2biADM9S99FerXg=', N'pankaj.gholap.info@gmail.com,urvashi.sachdev@tekacademy.com', N'', 1)
INSERT [dbo].[mtMailConfig] ([ConfigId], [Description], [MailFrom], [SenderPassword], [MailTo], [MailCC], [Enable]) VALUES (N'SERVICETAX', N'Service Tax Master', NULL, NULL, NULL, NULL, 0)
INSERT [dbo].[mtMailConfig] ([ConfigId], [Description], [MailFrom], [SenderPassword], [MailTo], [MailCC], [Enable]) VALUES (N'HUGGIESBAEPACK', N'Huggies basepack Master', NULL, NULL, NULL, NULL, 0)
INSERT [dbo].[mtMailConfig] ([ConfigId], [Description], [MailFrom], [SenderPassword], [MailTo], [MailCC], [Enable]) VALUES (N'CLUSTERRSCODE', N'Cluster RS code Mapping Master', NULL, NULL, NULL, NULL, 0)
INSERT [dbo].[mtMailConfig] ([ConfigId], [Description], [MailFrom], [SenderPassword], [MailTo], [MailCC], [Enable]) VALUES (N'SUBCATMAPPING', N'Sub Category Mapping Master', NULL, NULL, NULL, NULL, 0)

/****** Object:  Table [dbo].[mtPageRightMaster]    Script Date: 11/03/2016 12:37:57 ******/
DELETE FROM [mtPageRightMaster] where PageId='MailConfig'
INSERT [dbo].[mtPageRightMaster] ([PageId], [PageName], [Rights]) VALUES (N'MailConfig', N'Mail Configuration', N'read/write')

DELETE FROM [RoleWisePageRightsMaster] where PageId='MailConfig'
/****** Object:  Table [dbo].[RoleWisePageRightsMaster]    Script Date: 11/03/2016 12:37:58 ******/
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'caca17bd-b3ae-48fd-8997-ed334f1358c9', N'MailConfig', 1, 0, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'bd46ed2b-00b8-47a0-853b-f6f95d158a05', N'MailConfig', 1, 1, 0, 0)
INSERT [dbo].[RoleWisePageRightsMaster] ([RoleId], [PageId], [Read], [Write], [Extract], [Execute]) VALUES (N'1697032f-31dd-4371-bf77-8bc8b68b0f09', N'MailConfig', 1, 1, 0, 0)
