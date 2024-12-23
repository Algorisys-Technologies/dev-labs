/****** Object:  Table [dbo].[mtCustomerGroupMaster]    Script Date: 06/11/2016 14:27:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtCustomerGroupMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CustomerCode] [nvarchar](255) NULL,
	[StateCode] [nvarchar](255) NULL,
	[CreatedAt] [datetime] NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](100) NULL,
	[Operation] [char](1) NULL,
 CONSTRAINT [PK_mtCustomerGroupMaster] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  UserDefinedTableType [dbo].[mtCustomerGroupMasterType]    Script Date: 06/11/2016 14:28:39 ******/
IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'mtCustomerGroupMasterType' AND ss.name = N'dbo')
DROP TYPE [dbo].[mtCustomerGroupMasterType]
GO


/****** Object:  UserDefinedTableType [dbo].[mtCustomerGroupMasterType]    Script Date: 06/11/2016 14:28:39 ******/
CREATE TYPE [dbo].[mtCustomerGroupMasterType] AS TABLE(
	[CustomerCode] [nvarchar](255) NULL,
	[StateCode] [nvarchar](255) NULL
)
GO

/****** Object:  StoredProcedure [dbo].[Update_mtCustomerGroupMaster]    Script Date: 06/11/2016 14:29:14 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Update_mtCustomerGroupMaster]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Update_mtCustomerGroupMaster]
GO


/****** Object:  StoredProcedure [dbo].[Update_mtCustomerGroupMaster]    Script Date: 06/11/2016 14:29:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[Update_mtCustomerGroupMaster]
      @tblCustomerGroup mtCustomerGroupMasterType READONLY,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN


    INSERT INTO mtAuditTrailMasterData   
   select newid() Id, 'CustomerGroupMaster' Entity,'Id' KeyName,c1.Id as [Key], 
   'Customer Code' + ' : ' + c1.CustomerCode +
   ' ^ State Code' + ' : ' + c1.StateCode + ' | ' + c2.StateCode,
   'U' as Operation ,
  getdate() as UpdatedAt,
  @user as UpdatedBy
  from mtCustomerGroupMaster c1, @tblCustomerGroup c2
  where RTRIM(LTRIM(c1.CustomerCode))=RTRIM(LTRIM(c2.CustomerCode))
  And (RTRIM(LTRIM(c1.StateCode)) <> RTRIM(LTRIM(c2.StateCode)))


      MERGE INTO mtCustomerGroupMaster c1
      USING @tblCustomerGroup c2
      ON RTRIM(LTRIM(c1.CustomerCode))=RTRIM(LTRIM(c2.CustomerCode))  
      WHEN MATCHED THEN
  UPDATE SET
             c1.StateCode = RTRIM(LTRIM(c2.StateCode))       
   ,c1.UpdatedAt = getdate()
   ,c1.UpdatedBy = RTRIM(LTRIM(@user))
   ,c1.Operation = 'U'
  WHEN NOT MATCHED THEN
   INSERT VALUES(RTRIM(LTRIM(c2.CustomerCode)),RTRIM(LTRIM(c2.StateCode)),getdate(),RTRIM(LTRIM(@user)),null,null,'I');
    


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


CREATE FULLTEXT CATALOG CustomerFTC
WITH ACCENT_SENSITIVITY = OFF

CREATE FULLTEXT INDEX ON mtCustomerGroupMaster
(CustomerCode, StateCode)
KEY INDEX PK_mtCustomerGroupMaster
ON CustomerFTC
WITH STOPLIST = SYSTEM

/****** Object:  Table [dbo].[mtSkuMaster]    Script Date: 06/11/2016 14:15:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[mtSkuMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BasepackCode] [nvarchar](255) NULL,
	[TaxCode] [nvarchar](255) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](255) NOT NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](255) NULL,
	[Operation] [char](1) NOT NULL,
CONSTRAINT [PK__mtSku] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO



/****** Object:  UserDefinedTableType [dbo].[mtSkuMasterType]    Script Date: 06/11/2016 14:19:25 ******/
CREATE TYPE [dbo].[mtSkuMasterType] AS TABLE(
	[BasepackCode] [nvarchar](255) NULL,
	[TaxCode] [nvarchar](255) NULL
)
GO




/****** Object:  StoredProcedure [dbo].[Update_mtSkuMaster]    Script Date: 06/11/2016 14:24:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Update_mtSkuMaster]
      @tblSku mtSkuMasterType READONLY,
      @user varchar(200)
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN


    INSERT INTO mtAuditTrailMasterData   
   select newid() Id, 'SkuMaster' Entity,'Id' KeyName,c1.Id as [Key], 
   'Basepack Code' + ' : ' + c1.BasepackCode +
   ' ^ RS Code' + ' : ' + c1.TaxCode + ' | ' + Rtrim(LTrim(c2.TaxCode)) as Data,
   'U' as Operation ,
  getdate() as UpdatedAt,
  @user as UpdatedBy 
  from mtSkuMaster c1, @tblSku c2
  where c1.BasepackCode=Rtrim(LTrim(c2.BasepackCode)) 
  And (c1.TaxCode <> Rtrim(LTrim(c2.TaxCode)))


      MERGE INTO mtSkuMaster c1
      USING @tblSku c2
      ON c1.BasepackCode=Rtrim(LTrim(c2.BasepackCode)) 

      WHEN MATCHED THEN
  UPDATE SET
             c1.TaxCode = Rtrim(LTrim(c2.TaxCode))       
            
   ,c1.UpdatedAt = getdate()
   ,c1.UpdatedBy = @user
   ,c1.Operation = 'U' 
  WHEN NOT MATCHED THEN
   INSERT VALUES(Rtrim(LTrim(c2.BasepackCode)),Rtrim(LTrim(c2.TaxCode)),getdate(),@user,null,null,'I');
    


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




/****** Object:  Text Search [dbo].[mtSkuMaster]    Script Date: 06/11/2016 14:24:04 ******/

GO
CREATE FULLTEXT CATALOG HUL_FTS
WITH ACCENT_SENSITIVITY = OFF


CREATE FULLTEXT INDEX ON mtSkuMaster
(BasepackCode,TaxCode)
KEY INDEX PK__mtSku
ON HUL_FTS
WITH STOPLIST = SYSTEM