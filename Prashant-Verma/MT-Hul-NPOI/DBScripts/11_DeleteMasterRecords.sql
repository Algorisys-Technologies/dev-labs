

/****** Object:  StoredProcedure [dbo].[Delete_mtSubCategoryTOTMaster]    Script Date: 07/12/2016 10:47:32 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_mtSubCategoryTOTMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_mtSubCategoryTOTMaster]
GO

/****** Object:  StoredProcedure [dbo].[Delete_mtSubCategoryTOTMaster]    Script Date: 07/12/2016 10:47:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Delete_mtSubCategoryTOTMaster]
      @id nvarchar(200) ,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN

 
      INSERT INTO mtAuditTrailMasterData   
   select newid() Id, 'SubCategoryTOTMaster' Entity,'Id' KeyName,Id as [Key], 
   'Chain Name' + ' : ' + ChainName +
   ' ^ Group Name' + ' : ' + GroupName +
   ' ^ Branch' + ' : ' + Branch +
   ' ^ TOT Sub Category' + ' : ' + TOTSubCategory +
   ' ^ On Invoice Rate' + ' : ' +CONVERT(varchar(50),OnInvoiceRate) +
   ' ^ Off Invoice Mthly Rate' + ' : ' + CONVERT(varchar(50),OffInvoiceMthlyRate) +
   ' ^ Off Invoice Mthly Rate' + ' : ' + CONVERT(varchar(50),OffInvoiceMthlyRate) as data,
      'D' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from mtSubCategoryTOTMaster
  where ChainName+GroupName=@id


	DELETE from  mtSubCategoryTOTMaster WHERE ChainName+GroupName=@id

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


/****** Object:  StoredProcedure [dbo].[Delete_mtSkuMaster]    Script Date: 07/12/2016 10:47:28 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_mtSkuMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_mtSkuMaster]
GO


/****** Object:  StoredProcedure [dbo].[Delete_mtSkuMaster]    Script Date: 07/12/2016 10:47:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Delete_mtSkuMaster]
      @id int ,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN

 
   INSERT INTO mtAuditTrailMasterData	  
	  select newid() Id, 'SkuMaster' Entity,'Id' KeyName,Id as [Key], 
   'Basepack Code' + ' : ' + BasepackCode +
   ' ^ RS Code' + ' : ' + TaxCode  as Data,
  	    'D' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from mtSkuMaster
  where Id=@id


	DELETE from  mtSkuMaster WHERE Id=@id

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


/****** Object:  StoredProcedure [dbo].[Delete_mtServiceTaxRateMaster]    Script Date: 07/12/2016 10:47:23 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_mtServiceTaxRateMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_mtServiceTaxRateMaster]
GO

/****** Object:  StoredProcedure [dbo].[Delete_mtServiceTaxRateMaster]    Script Date: 07/12/2016 10:47:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Delete_mtServiceTaxRateMaster]
      @id int ,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN

 
   INSERT INTO mtAuditTrailMasterData	  
	  select newid() Id, 'ServiceTaxRateMaster' Entity,'Id' KeyName,Id as [Key], 
	  'Chain Name' + ' : ' + ChainName +
	  ' ^ Group Name' + ' : ' + GroupName +
	  ' ^ Rate' + ' : ' + CONVERT(varchar(200),Rate) as Data,
		    'D' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from mtServiceTaxRateMaster
  where Id=@id


	DELETE from  mtServiceTaxRateMaster WHERE Id=@id

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


/****** Object:  StoredProcedure [dbo].[Delete_mtSalesTaxRateMaster]    Script Date: 07/12/2016 10:47:19 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_mtSalesTaxRateMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_mtSalesTaxRateMaster]
GO


/****** Object:  StoredProcedure [dbo].[Delete_mtSalesTaxRateMaster]    Script Date: 07/12/2016 10:47:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Delete_mtSalesTaxRateMaster]
      @id int ,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN


   INSERT INTO mtAuditTrailMasterData	  
	  select newid() Id, 'SalesTaxMaster' Entity,'Id' KeyName,Id as [Key], 
	  'Tax Code' + ' : ' + TaxCode +
	  ' ^ State Code' + ' : ' + StateCode +
	  ' ^ Sales Tax Rate' + ' : ' + CONVERT(varchar(200),SalesTaxRate)  as Data,
	    'D' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from mtSalesTaxMaster
  where Id=@id


	DELETE from  mtSalesTaxMaster WHERE Id=@id

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

/****** Object:  StoredProcedure [dbo].[Delete_mtOutletMaster]    Script Date: 07/12/2016 10:47:15 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_mtOutletMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_mtOutletMaster]
GO

/****** Object:  StoredProcedure [dbo].[Delete_mtOutletMaster]    Script Date: 07/12/2016 10:47:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Delete_mtOutletMaster]
      @id int ,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN

    INSERT INTO mtAuditTrailMasterData   
   select newid() Id, 'OutletMaster' Entity,'Id' KeyName,Id as [Key], 
   'Hul Outlet Code' + ' : ' + HulOutletCode +
   ' ^ Group Name' + ' : ' + GroupName + 
     ' ^ Chain Name' + ' : ' + ChainName +
      ' ^ Color Non-Color' + ' : ' + ColorNonColor  as Data,
    'D' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from mtOutletMaster
  where Id=@id


	DELETE from  mtOutletMaster WHERE Id=@id

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


/****** Object:  StoredProcedure [dbo].[Delete_mtMTTierBasedTOTMaster]    Script Date: 07/12/2016 10:47:11 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_mtMTTierBasedTOTMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_mtMTTierBasedTOTMaster]
GO


/****** Object:  StoredProcedure [dbo].[Delete_mtMTTierBasedTOTMaster]    Script Date: 07/12/2016 10:47:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Delete_mtMTTierBasedTOTMaster]
      @id int ,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN

 
     INSERT INTO mtAuditTrailMasterData	  
	  select newid() Id, 'TierBasedTOTRate' Entity,'Id' KeyName,Id as [Key], 
	  ' Chain Name' + ' : ' + ChainName +
	  ' ^ Group Name' + ' : ' + GroupName +
	  ' ^ Outlet Tier' + ' : ' + OutletTier +
	  ' ^ Color Non-Color' + ' : ' + ColorNonColor +
	  ' ^ Price List' + ' : ' + PriceList +
	  ' ^ On Invoice Rate' + ' : ' + CONVERT(varchar(200),OnInvoiceRate) +
	  ' ^ Off Invoice Mthly Rate' + ' : ' + CONVERT(varchar(200),OffInvoiceMthlyRate) + 
	  ' ^ Off Invoice Qtrly Rate' + ' : ' + CONVERT(varchar(200),OffInvoiceQtrlyRate)as Data,
	    'D' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from MTTierBasedTOTRate
  where Id=@id


	DELETE from  MTTierBasedTOTRate WHERE Id=@id

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


/****** Object:  StoredProcedure [dbo].[Delete_mtHuggiesBasepackMaster]    Script Date: 07/12/2016 10:47:07 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_mtHuggiesBasepackMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_mtHuggiesBasepackMaster]
GO


/****** Object:  StoredProcedure [dbo].[Delete_mtHuggiesBasepackMaster]    Script Date: 07/12/2016 10:47:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Delete_mtHuggiesBasepackMaster]
      @id int ,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN

   
    INSERT INTO mtAuditTrailMasterData   
   select newid() Id, 'HuggiesBasepackMaster' Entity,'Id' KeyName,Id as [Key], 
   'Basepack Code' + ' : ' + BasepackCode +
   'SKU Description' + ' : ' + SKUDescription +
   ' ^ RS Code' + ' : ' + CONVERT(varchar(200),Percentage)  as Data,
	  'D' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from mtHuggiesPercentageMaster
  where Id=@id


	DELETE from  mtHuggiesPercentageMaster WHERE Id=@id

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


/****** Object:  StoredProcedure [dbo].[Delete_mtCustomerGroupMaster]    Script Date: 07/12/2016 10:47:03 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_mtCustomerGroupMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_mtCustomerGroupMaster]
GO


/****** Object:  StoredProcedure [dbo].[Delete_mtCustomerGroupMaster]    Script Date: 07/12/2016 10:47:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Delete_mtCustomerGroupMaster]
      @id int ,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN


    INSERT INTO mtAuditTrailMasterData   
   select newid() Id, 'CustomerGroupMaster' Entity,'Id' KeyName,c1.Id as [Key], 
   'Customer Code' + ' : ' + c1.CustomerCode +
   ' ^ State Code' + ' : ' + c1.StateCode as Data ,+ 
   'D' as Operation ,
  getdate() as UpdatedAt,
  @user as UpdatedBy
  from mtCustomerGroupMaster c1
  where c1.Id=@id


	DELETE from  mtCustomerGroupMaster WHERE Id=@id

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


/****** Object:  StoredProcedure [dbo].[Delete_mtClusterRSCodeMappingMaster]    Script Date: 07/12/2016 10:46:59 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_mtClusterRSCodeMappingMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_mtClusterRSCodeMappingMaster]
GO


/****** Object:  StoredProcedure [dbo].[Delete_mtClusterRSCodeMappingMaster]    Script Date: 07/12/2016 10:46:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Delete_mtClusterRSCodeMappingMaster]
      @id int ,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN


    INSERT INTO mtAuditTrailMasterData   
   select newid() Id, 'ClusterRSCodeMappingMaster' Entity,'Id' KeyName , Id as [Key], 
   'Cluster Code' + ' : ' + ClusterCode +
   ' ^ RS Code' + ' : ' + RSCode  as Data,
	  'D' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from mtClusterRSCodeMappingMaster
  where Id=@id


	DELETE from  mtClusterRSCodeMappingMaster WHERE Id=@id

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


/****** Object:  StoredProcedure [dbo].[Delete_mtBrandwiseSubCategoryMaster]    Script Date: 07/12/2016 10:46:56 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_mtBrandwiseSubCategoryMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_mtBrandwiseSubCategoryMaster]
GO


/****** Object:  StoredProcedure [dbo].[Delete_mtBrandwiseSubCategoryMaster]    Script Date: 07/12/2016 10:46:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Delete_mtBrandwiseSubCategoryMaster]
      @id int ,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN


    INSERT INTO mtAuditTrailMasterData   
   select newid() Id, 'SubCategoryMappingMaster' Entity,'Id' KeyName,Id as [Key], 
   'PMH Brand Code' + ' : ' + PMHBrandCode +
   ' ^ PMH Brand Name' + ' : ' + PMHBrandName +
   ' ^ Sales Sub Cat' + ' : ' + SalesSubCat +
   ' ^ Price List' + ' : ' + PriceList +
   ' ^ TOT Sub Category' + ' : ' + TOTSubCategory  as Data,
	  'D' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from mtBrandWiseTOTSubCategoryMapping
  where Id=@id


	DELETE from  mtBrandWiseTOTSubCategoryMapping WHERE Id=@id

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


/****** Object:  StoredProcedure [dbo].[Delete_mtAdditionalMarginMaster]    Script Date: 07/12/2016 10:46:51 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_mtAdditionalMarginMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_mtAdditionalMarginMaster]
GO


/****** Object:  StoredProcedure [dbo].[Delete_mtAdditionalMarginMaster]    Script Date: 07/12/2016 10:46:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Delete_mtAdditionalMarginMaster]
      @id int ,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN


	   INSERT INTO mtAuditTrailMasterData	  
	  select newid() Id, 'AdditionalMarginMaster' Entity,'Id' KeyName,Id as [Key], 
	  'RS Code' + ' : ' + RSCode +
	  ' ^ RS Name' + ' : ' + RSName +
	  ' ^ Chain Name' + ' : ' + ChainName +
	  ' ^ Group Name' + ' : ' + GroupName +
	  ' ^ Price List' + ' : ' + PriceList +
	  ' ^ Percentage' + ' : ' + CONVERT(varchar(200),Percentage) ,
	  'D' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from mtAdditionalMarginMaster
  where Id=@id


	DELETE from  mtAdditionalMarginMaster WHERE Id=@id

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


