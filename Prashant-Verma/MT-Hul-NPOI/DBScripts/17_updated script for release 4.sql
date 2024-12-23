
update mtAuditTrailMasterData set Entity='BrandWiseSubCategoryMaster' where entity ='SubCategoryMappingMaster'



/****** Object:  StoredProcedure [dbo].[Delete_mtBrandwiseSubCategoryMaster]    Script Date: 09/02/2016 17:59:15 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_mtBrandwiseSubCategoryMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_mtBrandwiseSubCategoryMaster]
GO


/****** Object:  StoredProcedure [dbo].[Delete_mtBrandwiseSubCategoryMaster]    Script Date: 09/02/2016 17:59:15 ******/
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




/****** Object:  StoredProcedure [dbo].[Update_mtBrandWiseTOTSubCategoryMapping]    Script Date: 09/02/2016 17:58:31 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_mtBrandWiseTOTSubCategoryMapping]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_mtBrandWiseTOTSubCategoryMapping]
GO


/****** Object:  StoredProcedure [dbo].[Update_mtBrandWiseTOTSubCategoryMapping]    Script Date: 09/02/2016 17:58:31 ******/
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


