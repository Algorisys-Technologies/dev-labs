/****** Object:  StoredProcedure [dbo].[Delete_mtGstMaster]    Script Date: 07/21/2017 11:24:56 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Delete_mtGstMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Delete_mtGstMaster]
GO

/****** Object:  StoredProcedure [dbo].[Delete_mtGstMaster]    Script Date: 07/21/2017 11:24:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[Delete_mtGstMaster]
      @id uniqueidentifier ,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN

 
   INSERT INTO mtAuditTrailMasterData	  
	  select newid() Id, 'GstMaster' Entity,'Id' KeyName,Id as [Key], 
   'Basepack Code' + ' : ' + BasepackCode +
   ' ^ Gst Rate' + ' : ' + CONVERT(varchar(200),GstRate)  as Data,
  	    'D' as Operation ,
	 getdate() as UpdatedAt,
	 @user as UpdatedBy 
	 from mtGstMaster
  where Id=@id


	DELETE from  mtGstMaster WHERE Id=@id

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


