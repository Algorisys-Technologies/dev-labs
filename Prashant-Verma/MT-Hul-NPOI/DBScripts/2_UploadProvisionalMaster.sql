/****** Object:  Table [dbo].[mtBrandWiseTOTSubCategoryMapping]    Script Date: 06/11/2016 14:30:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtBrandWiseTOTSubCategoryMapping](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PMHBrandCode] [nvarchar](6) NOT NULL,
	[PMHBrandName] [nvarchar](250) NULL,
	[SalesSubCat] [nvarchar](250) NOT NULL,
	[PriceList] [nvarchar](6) NOT NULL,
	[TOTSubCategory] [nvarchar](250) NULL,
	[CreatedAt] [datetime] NULL,
	[CreatedBy] [nvarchar](250) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](250) NULL,
	[Operation] [char](1) NULL,
 CONSTRAINT [PK_mtBrandWiseTOTSubCategoryMapping] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  UserDefinedTableType [dbo].[mtBrandWiseTOTSubCategoryMappingType]    Script Date: 06/11/2016 14:30:48 ******/
IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'mtBrandWiseTOTSubCategoryMappingType' AND ss.name = N'dbo')
DROP TYPE [dbo].[mtBrandWiseTOTSubCategoryMappingType]
GO


/****** Object:  UserDefinedTableType [dbo].[mtBrandWiseTOTSubCategoryMappingType]    Script Date: 06/11/2016 14:30:48 ******/
CREATE TYPE [dbo].[mtBrandWiseTOTSubCategoryMappingType] AS TABLE(
	[PMHBrandCode] [nvarchar](6) NOT NULL,
	[PMHBrandName] [nvarchar](250) NULL,
	[SalesSubCat] [nvarchar](250) NOT NULL,
	[PriceList] [nvarchar](6) NOT NULL,
	[TOTSubCategory] [nvarchar](250) NULL
)
GO


/****** Object:  StoredProcedure [dbo].[Update_mtBrandWiseTOTSubCategoryMapping]    Script Date: 06/11/2016 14:31:12 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_mtBrandWiseTOTSubCategoryMapping]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_mtBrandWiseTOTSubCategoryMapping]
GO


/****** Object:  StoredProcedure [dbo].[Update_mtBrandWiseTOTSubCategoryMapping]    Script Date: 06/11/2016 14:31:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[Update_mtBrandWiseTOTSubCategoryMapping]
      @tblBrandWiseTOTSubCategory mtBrandWiseTOTSubCategoryMappingType READONLY,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN


    INSERT INTO mtAuditTrailMasterData   
   select newid() Id, 'SubCategoryMappingMaster' Entity,'Id' KeyName,c1.Id as [Key], 
   'PMH Brand Code' + ' : ' + c1.PMHBrandCode +
   ' ^ PMH Brand Name' + ' : ' + c1.PMHBrandName + ' | ' + c2.PMHBrandName+
   ' ^ Sales Sub Cat' + ' : ' + c1.SalesSubCat +
   ' ^ Price List' + ' : ' + c1.PriceList +
   ' ^ TOT Sub Category' + ' : ' + c1.TOTSubCategory + ' | ' + c2.TOTSubCategory as Data,
   'U' as Operation ,
  getdate() as UpdatedAt,
  @user as UpdatedBy
  from mtBrandWiseTOTSubCategoryMapping c1, @tblBrandWiseTOTSubCategory c2
  where RTRIM(LTRIM(c1.PMHBrandCode))=RTRIM(LTRIM(c2.PMHBrandCode)) AND RTRIM(LTRIM(c1.SalesSubCat))=RTRIM(LTRIM(c2.SalesSubCat)) AND RTRIM(LTRIM(c1.PriceList))=RTRIM(LTRIM(c2.PriceList))
  And (RTRIM(LTRIM(c1.PMHBrandName)) <> RTRIM(LTRIM(c2.PMHBrandName)) OR RTRIM(LTRIM(c1.TOTSubCategory)) <> RTRIM(LTRIM(c2.TOTSubCategory)))


      MERGE INTO mtBrandWiseTOTSubCategoryMapping c1
      USING @tblBrandWiseTOTSubCategory c2
      ON c1.PMHBrandCode=c2.PMHBrandCode AND c1.SalesSubCat=c2.SalesSubCat AND c1.PriceList=c2.PriceList 
      WHEN MATCHED THEN
  UPDATE SET
             c1.PMHBrandName = RTRIM(LTRIM(c2.PMHBrandName))
             ,c1.TOTSubCategory = RTRIM(LTRIM(c2.TOTSubCategory))         
   ,c1.UpdatedAt = getdate()
   ,c1.UpdatedBy = @user
   ,c1.Operation = 'U'
  WHEN NOT MATCHED THEN
   INSERT VALUES(RTRIM(LTRIM(c2.PMHBrandCode)),RTRIM(LTRIM(c2.PMHBrandName)),RTRIM(LTRIM(c2.SalesSubCat)),RTRIM(LTRIM(c2.PriceList)),RTRIM(LTRIM(c2.TOTSubCategory)),getdate(),@user,null,null,'I');
    


COMMIT
    END TRY
   BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
                ROLLBACK
END CATCH;
END




GO

/****** Object:  Table [dbo].[mtSubCategoryTOTMaster]    Script Date: 06/11/2016 14:31:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtSubCategoryTOTMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ChainName] [nvarchar](500) NULL,
	[GroupName] [nvarchar](500) NULL,
	[Branch] [nvarchar](50) NULL,
	[TOTSubCategory] [nvarchar](100) NULL,
	[OnInvoiceRate] [decimal](18, 4) NULL,
	[OffInvoiceMthlyRate] [decimal](18, 4) NULL,
	[OffInvoiceQtrlyRate] [decimal](18, 4) NULL,
	[CreatedAt] [date] NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[UpdatedAt] [date] NULL,
	[UpdatedBy] [nvarchar](100) NULL,
	[Operation] [char](1) NULL,
 CONSTRAINT [PK_mtSubCategoryTOTMaster] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  UserDefinedTableType [dbo].[mtSubCategoryTOTMasterType]    Script Date: 06/11/2016 14:32:25 ******/
IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'mtSubCategoryTOTMasterType' AND ss.name = N'dbo')
DROP TYPE [dbo].[mtSubCategoryTOTMasterType]
GO


/****** Object:  UserDefinedTableType [dbo].[mtSubCategoryTOTMasterType]    Script Date: 06/11/2016 14:32:25 ******/
CREATE TYPE [dbo].[mtSubCategoryTOTMasterType] AS TABLE(
	[ChainName] [nvarchar](500) NULL,
	[GroupName] [nvarchar](500) NULL,
	[Branch] [nvarchar](50) NULL,
	[TOTSubCategory] [nvarchar](100) NULL,
	[OnInvoiceRate] [decimal](18, 4) NULL,
	[OffInvoiceMthlyRate] [decimal](18, 4) NULL,
	[OffInvoiceQtrlyRate] [decimal](18, 4) NULL
)
GO


/****** Object:  StoredProcedure [dbo].[Update_mtSubCategoryTOTMaster]    Script Date: 06/11/2016 14:33:35 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_mtSubCategoryTOTMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_mtSubCategoryTOTMaster]
GO


/****** Object:  StoredProcedure [dbo].[Update_mtSubCategoryTOTMaster]    Script Date: 06/11/2016 14:33:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[Update_mtSubCategoryTOTMaster]
      @tblParam mtSubCategoryTOTMasterType READONLY,
      @user varchar(200),
      @totCategory varchar(20)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN


    INSERT INTO mtAuditTrailMasterData   
   select newid() Id, 'SubCategoryTOTMaster' Entity,'Id' KeyName,c1.Id as [Key], 
   'Chain Name' + ' : ' + c1.ChainName +
   ' ^ Group Name' + ' : ' + c1.GroupName +
   ' ^ Branch' + ' : ' + c1.Branch +
   ' ^ TOT Sub Category' + ' : ' + c1.TOTSubCategory +
   ' ^ On Invoice Rate' + ' : ' +CONVERT(varchar(50),c1.OnInvoiceRate) + ' | ' + CONVERT(varchar(50),c2.OnInvoiceRate)+
   ' ^ Off Invoice Mthly Rate' + ' : ' + CONVERT(varchar(50),c1.OffInvoiceMthlyRate) + ' | ' + CONVERT(varchar(50),c2.OffInvoiceMthlyRate)+
   ' ^ Off Invoice Qtrly Rate' + ' : ' + CONVERT(varchar(50),c1.OffInvoiceQtrlyRate) + ' | ' + CONVERT(varchar(50),c2.OffInvoiceQtrlyRate) as data,
   'U' as Operation ,
  getdate() as UpdatedAt,
  @user as UpdatedBy
  from mtSubCategoryTOTMaster c1, @tblParam c2
  where c1.ChainName=c2.ChainName AND c1.GroupName=c2.GroupName AND c1.Branch=c2.Branch AND c1.TOTSubCategory=c2.TOTSubCategory
  And (c1.OnInvoiceRate <> c2.OnInvoiceRate OR c1.OffInvoiceMthlyRate <> c2.OffInvoiceMthlyRate OR c1.OffInvoiceQtrlyRate <> c2.OffInvoiceQtrlyRate)


      MERGE INTO mtSubCategoryTOTMaster c1
      USING @tblParam c2
      ON c1.ChainName=c2.ChainName AND c1.GroupName=c2.GroupName AND c1.Branch=c2.Branch AND c1.TOTSubCategory=c2.TOTSubCategory
      WHEN MATCHED THEN
  UPDATE SET
             c1.OnInvoiceRate = CASE  
         WHEN @totCategory='on' THEN c2.OnInvoiceRate  
         ELSE c1.OnInvoiceRate  
      END  
             ,c1.OffInvoiceMthlyRate = CASE  
         WHEN @totCategory='off' THEN c2.OffInvoiceMthlyRate  
         ELSE c1.OffInvoiceMthlyRate  
      END
             ,c1.OffInvoiceQtrlyRate = CASE  
         WHEN @totCategory='quarterly' THEN c2.OffInvoiceQtrlyRate  
         ELSE c1.OffInvoiceQtrlyRate  
      END          
   ,c1.UpdatedAt = getdate()
   ,c1.UpdatedBy = @user
   ,c1.Operation = 'U'
  WHEN NOT MATCHED THEN
   INSERT VALUES(c2.ChainName,c2.GroupName,c2.Branch,c2.TOTSubCategory,c2.OnInvoiceRate,c2.OffInvoiceMthlyRate,c2.OffInvoiceQtrlyRate,getdate(),@user,null,null,'I');
    


COMMIT
    END TRY
    BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
                ROLLBACK
END CATCH;
END




GO

CREATE FULLTEXT CATALOG MTSubCategoryFTS
WITH ACCENT_SENSITIVITY = OFF

CREATE FULLTEXT INDEX ON mtBrandWiseTOTSubCategoryMapping
(PMHBrandCode, PMHBrandName,SalesSubCat,PriceList,TOTSubCategory)
KEY INDEX PK_mtBrandWiseTOTSubCategoryMapping
ON MTSubCategoryFTS
WITH STOPLIST = SYSTEM



/****** Object:  Table [dbo].[mtHuggiesPercentageMaster]    Script Date: 06/16/2016 14:59:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtHuggiesPercentageMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BasepackCode] [nvarchar](255) NOT NULL,
	[SKUDescription] [nvarchar](255) NOT NULL,
	[Percentage] [decimal](5, 3) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NOT NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NOT NULL,
 CONSTRAINT [PK__mtHuggies] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF


GO





/****** Object:  UserDefinedTableType [dbo].[mtHuggiesBasepackMasterType]    Script Date: 06/16/2016 15:01:02 ******/
CREATE TYPE [dbo].[mtHuggiesBasepackMasterType] AS TABLE(
	[BasepackCode] [nvarchar](255) NOT NULL,
	[SKUDescription] [nvarchar](255) NOT NULL,
	[Percentage] [decimal](5, 3) NULL
)
GO



/****** Object:  StoredProcedure [dbo].[Update_mtHuggiesBasepackMaster]    Script Date: 06/16/2016 15:00:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[Update_mtHuggiesBasepackMaster]
      @tblHuggiesBasepack mtHuggiesBasepackMasterType READONLY,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN


    INSERT INTO mtAuditTrailMasterData   
   select newid() Id, 'HuggiesBasepackMaster' Entity,'Id' KeyName,c1.Id as [Key], 
   'Basepack Code' + ' : ' + c1.BasepackCode +
   'SKU Description' + ' : ' + c1.SKUDescription +'|'+Ltrim(Rtrim(c2.SKUDescription))+
   ' ^ RSCode' + ' : ' + CONVERT(varchar(200),c1.Percentage) + ' | ' + CONVERT(varchar(200),c2.Percentage) as Data,
   'U' as Operation ,
  getdate() as UpdatedAt,
  @user as UpdatedBy 
  from mtHuggiesPercentageMaster c1, @tblHuggiesBasepack c2
  where c1.BasepackCode=Ltrim(Rtrim(c2.BasepackCode)) 
  And (c1.Percentage <> Convert(decimal(5,3),c2.Percentage) or (c1.SKUDescription <> Ltrim(Rtrim(c2.SKUDescription))))


      MERGE INTO mtHuggiesPercentageMaster c1
      USING @tblHuggiesBasepack c2
      ON c1.BasepackCode=Ltrim(Rtrim(c2.BasepackCode)) 
      

      WHEN MATCHED THEN
  UPDATE SET
             c1.Percentage = Convert(decimal(5,3),c2.Percentage)
             ,c1.SKUDescription=Ltrim(Rtrim(c2.SKUDescription))    
            
   ,c1.UpdatedAt = getdate()
   ,c1.UpdatedBy = @user
   ,c1.Operation = 'U' 
  WHEN NOT MATCHED THEN
   INSERT VALUES(Ltrim(Rtrim(c2.BasepackCode)),Ltrim(Rtrim(c2.SKUDescription)),c2.Percentage,getdate(),@user,null,null,'I');
    



COMMIT
    END TRY
   
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
                ROLLBACK
END CATCH;
END




GO

/****** Object:  Fulltext catalog    Script Date: 06/11/2016 14:28:21 ******/

GO

/****** Object:  Fulltext search [dbo].[mtHuggiesBasepackMaster]    Script Date: 06/11/2016 14:28:21 ******/
CREATE FULLTEXT INDEX ON mtHuggiesPercentageMaster
(BasepackCode,SKUDescription)
KEY INDEX PK__mtHuggies
ON HUL_FTS
WITH STOPLIST = SYSTEM



/****** Object:  Table [dbo].[mtClusterRSCodeMappingMaster]    Script Date: 06/11/2016 14:32:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtClusterRSCodeMappingMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ClusterCode] [nvarchar](255) NOT NULL,
	[RSCode] [nvarchar](255) NOT NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NOT NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NOT NULL,
CONSTRAINT [PK__mtCluster] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO





/****** Object:  UserDefinedTableType [dbo].[mtClusterRSCodeMappingMasterType]    Script Date: 06/11/2016 14:33:25 ******/
CREATE TYPE [dbo].[mtClusterRSCodeMappingMasterType] AS TABLE(
	[ClusterCode] [nvarchar](255) NULL,
	[RSCode] [nvarchar](255) NULL
)
GO




/****** Object:  StoredProcedure [dbo].[Update_mtClusterRSCodeMappingMaster]    Script Date: 06/11/2016 14:33:54 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Update_mtClusterRSCodeMappingMaster]
      @tblClusterRSCodeMapping mtClusterRSCodeMappingMasterType READONLY,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN


    INSERT INTO mtAuditTrailMasterData   
   select newid() Id, 'ClusterRSCodeMappingMaster' Entity,'Id' KeyName,c1.Id as [Key], 
   'Cluster Code' + ' : ' + c1.ClusterCode +
   ' ^ RS Code' + ' : ' + c1.RSCode + ' | ' + Ltrim(Rtrim(c2.RSCode)) as Data,
   'U' as Operation ,
  getdate() as UpdatedAt,
  @user as UpdatedBy 
  from mtClusterRSCodeMappingMaster c1, @tblClusterRSCodeMapping c2
  where c1.ClusterCode=Ltrim(Rtrim(c2.ClusterCode)) 
  And (c1.RSCode <> Ltrim(Rtrim(c2.RSCode)))


      MERGE INTO mtClusterRSCodeMappingMaster c1
      USING @tblClusterRSCodeMapping c2
      ON c1.ClusterCode=c2.ClusterCode 

      WHEN MATCHED THEN
  UPDATE SET
             c1.RSCode = Ltrim(Rtrim(c2.RSCode))       
            
   ,c1.UpdatedAt = getdate()
   ,c1.UpdatedBy = @user
   ,c1.Operation = 'U' 
  WHEN NOT MATCHED THEN
   INSERT VALUES(Ltrim(Rtrim(c2.ClusterCode)),Ltrim(Rtrim(c2.RSCode)),getdate(),@user,null,null,'I');
    


COMMIT
    END TRY
    
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
                ROLLBACK
END CATCH;
END

GO





/****** Object: Fulltext search   [dbo].[mtClusterRSCodeMappingMaster]    Script Date: 06/11/2016 14:33:54 ******/

CREATE FULLTEXT INDEX ON mtClusterRSCodeMappingMaster
(ClusterCode,RSCode)
KEY INDEX PK__mtCluster
ON HUL_FTS
WITH STOPLIST = SYSTEM





/****** Object:  Table [dbo].[mtOutletMaster]    Script Date: 06/11/2016 14:37:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtOutletMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[HulOutletCode] [nvarchar](255) NULL,
	[ChainName] [nvarchar](255) NULL,
	[GroupName] [nvarchar](255) NULL,
	[ColorNonColor] [nvarchar](255) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NOT NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NOT NULL,
CONSTRAINT [PK__mtoutlet] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO





/****** Object:  UserDefinedTableType [dbo].[mtOutletMasterType]    Script Date: 06/11/2016 14:37:33 ******/
CREATE TYPE [dbo].[mtOutletMasterType] AS TABLE(
	[HulOutletCode] [nvarchar](255) NULL,
	[ChainName] [nvarchar](255) NULL,
	[GroupName] [nvarchar](255) NULL,
	[ColorNonColor] [nvarchar](255) NULL
)
GO




/****** Object:  StoredProcedure [dbo].[Update_mtOutletMaster]    Script Date: 06/11/2016 14:37:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Update_mtOutletMaster]
      @tblOutlet mtOutletMasterType READONLY,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN


    INSERT INTO mtAuditTrailMasterData   
   select newid() Id, 'OutletMaster' Entity,'Id' KeyName,c1.Id as [Key], 
   'Hul Outlet Code' + ' : ' + c1.HulOutletCode +
   ' ^ Group Name' + ' : ' + c1.GroupName + ' | ' + Ltrim(Rtrim(c2.GroupName))+
     ' ^ Chain Name' + ' : ' + c1.ChainName + ' | ' + Ltrim(Rtrim(c2.ChainName))+
      ' ^ Color Non-Color' + ' : ' + c1.ColorNonColor + ' | ' + Ltrim(Rtrim(c2.ColorNonColor)) as Data,
   'U' as Operation ,
  getdate() as UpdatedAt,
  @user as UpdatedBy 
  from mtOutletMaster c1, @tblOutlet c2
  where c1.HulOutletCode=Ltrim(Rtrim(c2.HulOutletCode)) 
  And (c1.GroupName <> Ltrim(Rtrim(c2.GroupName)) or c1.ChainName<>Ltrim(Rtrim(c2.ChainName)) or c1.ColorNonColor<>Ltrim(Rtrim(c2.ColorNonColor)))


      MERGE INTO mtOutletMaster c1
      USING @tblOutlet c2
      ON c1.HulOutletCode=Ltrim(Rtrim(c2.HulOutletCode))

      WHEN MATCHED THEN
  UPDATE SET
         c1.HulOutletCode=Ltrim(Rtrim(c2.HulOutletCode))
             ,c1.GroupName = Ltrim(Rtrim(c2.GroupName))
             ,c1.ChainName=Ltrim(Rtrim(c2.ChainName))
             ,c1.ColorNonColor=Ltrim(Rtrim(c2.ColorNonColor))      
            
   ,c1.UpdatedAt = getdate()
   ,c1.UpdatedBy = @user
   ,c1.Operation = 'U' 
  WHEN NOT MATCHED THEN
   INSERT VALUES(Ltrim(Rtrim(c2.HulOutletCode)),Ltrim(Rtrim(c2.ChainName)),Ltrim(Rtrim(c2.GroupName)),Ltrim(Rtrim(c2.ColorNonColor)),getdate(),@user,null,null,'I');
    


COMMIT
    END TRY
   
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
                ROLLBACK
END CATCH;
END

GO



/****** Object:  FullTextSearch [dbo].[mtOutletMaster]    Script Date: 06/11/2016 14:37:56 ******/

CREATE FULLTEXT INDEX ON mtOutletMaster
(HulOutletCode,GroupName,ChainName,ColorNonColor)
KEY INDEX PK__mtOutlet
ON HUL_FTS
WITH STOPLIST = SYSTEM




