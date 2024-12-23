
/****** Object:  Table [dbo].[mtPageRightMaster]    Script Date: 07/19/2016 18:51:10 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtPageRightMaster]') AND type in (N'U'))
DROP TABLE [dbo].[mtPageRightMaster]
GO


/****** Object:  Table [dbo].[mtPageRightMaster]    Script Date: 07/19/2016 18:51:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mtPageRightMaster](
	[PageId] [nvarchar](50) NOT NULL,
	[PageName] [nvarchar](100) NULL,
	[Rights] [nvarchar](100) NULL
) ON [PRIMARY]


/****** Object:  Table [dbo].[RoleWisePageRightsMaster]    Script Date: 06/22/2016 10:25:54 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RoleWisePageRightsMaster](
	[RoleId] [uniqueidentifier] NOT NULL,
	[PageId] [nvarchar](50) NULL,
	[Read] [bit] NULL,
	[Write] [bit] NULL,
	[Extract] [bit] NULL,
	[Execute] [bit] NULL
) ON [PRIMARY]

GO

/****** Object:  StoredProcedure [dbo].[UpdateRoleWisePageRights]    Script Date: 06/22/2016 10:28:13 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UpdateRoleWisePageRights]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[UpdateRoleWisePageRights]
GO


/****** Object:  UserDefinedTableType [dbo].[RoleWisePageRightsMasterType]    Script Date: 06/22/2016 10:28:50 ******/
IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'RoleWisePageRightsMasterType' AND ss.name = N'dbo')
DROP TYPE [dbo].[RoleWisePageRightsMasterType]
GO


/****** Object:  UserDefinedTableType [dbo].[RoleWisePageRightsMasterType]    Script Date: 06/22/2016 10:28:50 ******/
CREATE TYPE [dbo].[RoleWisePageRightsMasterType] AS TABLE(
	[RoleId] [uniqueidentifier] NOT NULL,
	[PageId] [nvarchar](50) NULL,
	[Read] [bit] NULL,
	[Write] [bit] NULL,
	[Extract] [bit] NULL,
	[Execute] [bit] NULL
)
GO


/****** Object:  StoredProcedure [dbo].[UpdateRoleWisePageRights]    Script Date: 06/22/2016 10:28:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateRoleWisePageRights]
      @tblPageRightMaster RoleWisePageRightsMasterType READONLY
AS
BEGIN
      SET NOCOUNT ON;
 BEGIN TRY
      BEGIN TRAN


      MERGE INTO RoleWisePageRightsMaster c1
      USING @tblPageRightMaster c2
      ON c1.RoleId=c2.RoleId AND c1.PageId=c2.PageId
      WHEN MATCHED THEN
  UPDATE SET
             c1.[Read] = c2.[Read]        
   ,c1.Write = c2.Write
   ,c1.Extract = c2.Extract
   ,c1.[Execute] = c2.[Execute]
  WHEN NOT MATCHED THEN
   INSERT VALUES(c2.RoleId,c2.PageId,c2.[Read],c2.Write,c2.Extract,c2.[Execute]);
    


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





