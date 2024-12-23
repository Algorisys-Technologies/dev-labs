


/****** Object:  Table [dbo].[mtJV]    Script Date: 06/17/2016 10:33:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mtJV](
	[Id] [uniqueidentifier] NOT NULL,
	[MOC] [nvarchar](8) NULL,
	[GLAccount] [nvarchar](15) NOT NULL,
	[Amount] [decimal](18, 1) NULL,
	[BranchCode] [nvarchar](5) NULL,
	[InternalOrder] [nvarchar](15) NULL,
	[GLItemText] [nvarchar](200) NULL,
	[PMHBrandCode] [nvarchar](6) NULL,
	[DistrChannel] [nvarchar](2) NULL,
	[ProfitCenter] [nvarchar](5) NULL,
	[COPACustomer] [nvarchar](10) NULL,
	[Type] [nvarchar](5) NULL
) ON [PRIMARY]

GO



/****** Object:  Table [dbo].[mtMOCCalculation]    Script Date: 06/17/2016 10:33:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[mtMOCCalculation](
	[SecSalesId] [uniqueidentifier] NOT NULL,
	[ChainName] [nvarchar](100) NULL,
	[GroupName] [nvarchar](100) NULL,
	[ColorNonColor] [nvarchar](100) NULL,
	[TaxCode] [nvarchar](4) NULL,
	[StateCode] [nvarchar](4) NULL,
	[SalesTaxRate] [decimal](5, 5) NULL,
	[GSV] [decimal](18, 2) NULL,
	[ServiceTaxRate] [decimal](18, 2) NULL,
	[ServiceTax] [decimal](18, 2) NULL,
	[AdditionalMarginRate] [decimal](18, 3) NULL,
	[AdditionalMargin] [decimal](18, 2) NULL,
	[HuggiesPackPercentage] [decimal](18, 2) NULL,
	[HuggiesPackMargin] [decimal](18, 2) NULL,
	[TOTSubCategory] [nvarchar](50) NULL,
	[OnInvoiceRate] [decimal](18, 4) NULL,
	[OffInvoiceMthlyRate] [decimal](18, 4) NULL,
	[OffInvoiceQtrlyRate] [decimal](18, 4) NULL,
	[OnInvoiceValue] [decimal](18, 2) NULL,
	[OffInvoiceMthlyValue] [decimal](18, 2) NULL,
	[OffInvoiceQtrlyValue] [decimal](18, 2) NULL,
	[OnInvoiceFinalValue] [decimal](18, 2) NULL,
	[OffInvoiceMthlyFinalValue] [decimal](18, 2) NULL,
	[OffInvoiceQtrlyFinalValue] [decimal](18, 2) NULL,
	[Cluster] [nvarchar](10) NULL,
	[FirstLetterBrand] [nvarchar](1) NULL,
 CONSTRAINT [PK_mtMOCCalculation] PRIMARY KEY CLUSTERED 
(
	[SecSalesId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_SalesTaxRate]  DEFAULT ((0)) FOR [SalesTaxRate]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_SalesTax]  DEFAULT ((0)) FOR [GSV]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_ServiceTaxRate]  DEFAULT ((0)) FOR [ServiceTaxRate]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_ServiceTax]  DEFAULT ((0)) FOR [ServiceTax]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_AdditionalMarginRate]  DEFAULT ((0)) FOR [AdditionalMarginRate]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_AdditionalMargin]  DEFAULT ((0)) FOR [AdditionalMargin]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_HuggiesPackPercentage]  DEFAULT ((0)) FOR [HuggiesPackPercentage]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_HuggiesPackMargin]  DEFAULT ((0)) FOR [HuggiesPackMargin]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_OnInvoiceRate]  DEFAULT ((0)) FOR [OnInvoiceRate]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_OffInvoiceMthlyRate]  DEFAULT ((0)) FOR [OffInvoiceMthlyRate]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_OffInvoiceQtrlyRate]  DEFAULT ((0)) FOR [OffInvoiceQtrlyRate]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_OnInvoiceValue]  DEFAULT ((0)) FOR [OnInvoiceValue]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_OffInvoiceMthlyValue]  DEFAULT ((0)) FOR [OffInvoiceMthlyValue]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_OffInvoiceQtrlyValue]  DEFAULT ((0)) FOR [OffInvoiceQtrlyValue]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_OnInvoiceFinalValue]  DEFAULT ((0)) FOR [OnInvoiceFinalValue]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_OffInvoiceMthlyFinalValue]  DEFAULT ((0)) FOR [OffInvoiceMthlyFinalValue]
GO

ALTER TABLE [dbo].[mtMOCCalculation] ADD  CONSTRAINT [DF_mtMOCCalculation_OffInvoiceQtrlyFinalValue]  DEFAULT ((0)) FOR [OffInvoiceQtrlyFinalValue]
GO



/****** Object:  StoredProcedure [dbo].[mtspCalculateGSV]    Script Date: 06/17/2016 10:21:44 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspCalculateGSV]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspCalculateGSV]
GO



/****** Object:  StoredProcedure [dbo].[mtspCalculateGSV]    Script Date: 06/17/2016 10:21:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspCalculateGSV] 
	@moc nvarchar(7)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if(select count(*) FROM mtMOCCalculation mocCal, mtSecSalesReport sec 
		where mocCal.SecSalesId=sec.Id and sec.moc = @moc) = 0
	begin
		print 'insert in mtmoccalculation'
		INSERT into mtMOCCalculation(SecSalesId)
		SELECT id from mtSecSalesReport where moc= @moc
	end

    --Update Chain Name, Group Name and Color
		--UPDATE
		--mocCal
		--SET
		--	ChainName = om.ChainName,
		--	GroupName = om.GroupName,
		--	ColorNonColor = om.ColorNoncolor
		--FROM
		--	mtMOCCalculation mocCal
		--	JOIN
		--	mtSecSalesReport sec ON 
		--	mocCal.SecSalesId=sec.Id 
		--	JOIN
		--	mtOutletMaster om ON 
		--om.HulOutletCode=sec.HulOutletCode
		--WHERE
		--sec.MOC= @moc


		--Update TaxCode
		UPDATE
			mocCal
		SET
			TaxCode = om.TaxCode
		FROM
			mtMOCCalculation mocCal
			JOIN
			mtSecSalesReport sec ON 

		mocCal.SecSalesId=sec.Id 
			JOIN
			mtSkuMaster om ON 

		om.BasepackCode=sec.BasepackCode
		WHERE
		sec.MOC= @moc

		--Update StateCode
		UPDATE
			mocCal
		SET
			StateCode = om.StateCode
		FROM
			mtMOCCalculation mocCal
			JOIN
			mtSecSalesReport sec ON 

		mocCal.SecSalesId=sec.Id 
			JOIN
			mtCustomerGroupMaster om ON 

		om.CustomerCode=sec.CustomerCode
		WHERE
		sec.MOC= @moc

		--Update Sales Tax Rate, Sales Tax
		UPDATE
			mocCal
		SET
			SalesTaxRate = om.SalesTaxRate,
			GSV = round((sec.NetSalesValue/(1+om.SalesTaxRate)),3)
		FROM
			mtMOCCalculation mocCal
			JOIN
			mtSecSalesReport sec ON 

		mocCal.SecSalesId=sec.Id 
			JOIN
			mtSalesTaxMaster om ON 

		om.StateCode=mocCal.StateCode and 

		om.TaxCode = mocCal.TaxCode
		WHERE
		sec.MOC= @moc

		
		
			--Update first letter of Brand
			UPDATE
			mocCal
			SET
				FirstLetterBrand = SUBSTRING(sec.PMHBrandCode,1,1)
			FROM
				mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 							
			WHERE
			sec.MOC=  @moc

END


GO



/****** Object:  StoredProcedure [dbo].[mtspCalculateProvision]    Script Date: 06/17/2016 10:21:48 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspCalculateProvision]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspCalculateProvision]
GO


/****** Object:  StoredProcedure [dbo].[mtspCalculateProvision]    Script Date: 06/17/2016 10:21:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspCalculateProvision] 
	@moc nvarchar(7)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	
	--Update Chain Name, Group Name and Color
		UPDATE
		mocCal
		SET
			ChainName = om.ChainName,
			GroupName = om.GroupName,
			ColorNonColor = om.ColorNoncolor
		FROM
			mtMOCCalculation mocCal
			JOIN
			mtSecSalesReport sec ON 
			mocCal.SecSalesId=sec.Id 
			JOIN
			mtOutletMaster om ON 
		om.HulOutletCode=sec.HulOutletCode
		WHERE
		sec.MOC= @moc

		
	
			--Get Huggies Pack % and also do calculation
		UPDATE
		mocCal
		SET
			HuggiesPackPercentage = om.Percentage,
			HuggiesPackMargin = sec.NetSalesValue * om.Percentage
		FROM
			mtMOCCalculation mocCal
			JOIN
			mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 			
			JOIN mtHuggiesPercentageMaster om ON om.BasepackCode=sec.BasepackCode
		WHERE
		sec.MOC= @moc
		and mocCal.ChainName in (select ChainName from mtChainNameMaster where IsHuggiesAppl=1)

		
		--Update Cluster/RS Code Based on Cluster Code
		UPDATE
			mocCal
			SET
				Cluster = om.RSCode
			FROM
				mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 			
				JOIN mtClusterRSCodeMappingMaster om ON om.clusterCode=sec.ClusterCode 
			WHERE
			sec.MOC= @moc
		
		
		--Update Additional Margin %
		UPDATE
		mocCal
		SET
			AdditionalMarginRate = om.Percentage,
			AdditionalMargin =ROUND( sec.NetSalesValue * om.Percentage,0)
		FROM
			mtMOCCalculation mocCal
			JOIN
			mtSecSalesReport sec ON mocCal.SecSalesId=sec.Id 
			JOIN
			mtAdditionalMarginMaster om ON om.RSCode=sec.CustomerCode and om.ChainName= mocCal.ChainName
			and  om.GroupName= mocCal.GroupName and  om.PriceList= sec.PriceList 
		WHERE
		sec.MOC= @moc

		--Update TOT % Subcategory Mapping
		UPDATE
		mocCal
		SET
			TOTSubCategory = om.TOTSubCategory
		FROM
			mtMOCCalculation mocCal
			JOIN
			(Select distinct ChainName, groupName from mtSubCategoryTOTMaster) subcatRate ON mocCal.ChainName = subcatRate.ChainName and mocCal.GroupName = subcatRate.GroupName			
			JOIN
			mtSecSalesReport sec ON mocCal.SecSalesId=sec.Id 
			JOIN
			mtBrandWiseTOTSubCategoryMapping om ON om.PMHBrandCode=sec.PMHBrandCode and om.SalesSubCat= sec.SalesSubCat 
			and  om.PriceList= sec.PriceList 
		WHERE		
		sec.MOC= @moc

		--Update OnInvoice Rate and Value based on Subcategory
		--Todo pending for Off Mnthly and Off Qtrly	
		UPDATE
		mocCal
		SET			
			OnInvoiceRate = om.OnInvoiceRate,
			OnInvoiceValue = round((mocCal.GSV * (om.OnInvoiceRate)),4),
			OnInvoiceFinalValue = AdditionalMargin + round((mocCal.GSV * (om.OnInvoiceRate)),4),
		 --Off Mnthly
			OffInvoiceMthlyRate = om.OffInvoiceMthlyRate,
			OffInvoiceMthlyValue = round((sec.NetSalesValue * (om.OffInvoiceMthlyRate)),4),
			OffInvoiceMthlyFinalValue = round((sec.NetSalesValue * (om.OffInvoiceMthlyRate)),4),
		--OFF Qtrly
			OffInvoiceQtrlyRate = om.OffInvoiceQtrlyRate,
			OffInvoiceQtrlyValue = round((sec.NetSalesValue * (om.OffInvoiceQtrlyRate)),4)
			--OffInvoiceQtrlyFinalValue = OffInvoiceQtrlyValue + ServiceTax + HuggiesPackMargin
		FROM
			mtMOCCalculation mocCal			
			JOIN
			mtSecSalesReport sec ON mocCal.SecSalesId=sec.Id 
			JOIN
			mtSubCategoryTOTMaster om ON om.ChainName=mocCal.ChainName and om.GroupName= mocCal.GroupName 
			and  om.TOTSubCategory= mocCal.TOTSubCategory and sec.BranchCode=om.Branch
		WHERE
		sec.MOC= @moc


	
		---Update OnInvoice Rate and Value based on Tier Based
		UPDATE
		mocCal
		SET			
			OnInvoiceRate = om.OnInvoiceRate,
			OnInvoiceValue = round((mocCal.GSV * (om.OnInvoiceRate)),4),
			OnInvoiceFinalValue = AdditionalMargin + round((mocCal.GSV * (om.OnInvoiceRate)),4),
		 --Off Mnthly
			OffInvoiceMthlyRate = om.OffInvoiceMthlyRate,
			OffInvoiceMthlyValue = round((sec.NetSalesValue * (om.OffInvoiceMthlyRate)),4),
			OffInvoiceMthlyFinalValue =round((sec.NetSalesValue * (om.OffInvoiceMthlyRate)),4),
		--OFF Qtrly
			OffInvoiceQtrlyRate = om.OffInvoiceQtrlyRate,
			OffInvoiceQtrlyValue = round((sec.NetSalesValue * (om.OffInvoiceQtrlyRate)),4)
			--OffInvoiceQtrlyFinalValue = OffInvoiceQtrlyValue + ServiceTax + HuggiesPackMargin
		FROM
			mtMOCCalculation mocCal	
			JOIN
			(Select distinct ChainName, groupName from MTTierBasedTOTRate) tierRate ON mocCal.ChainName = tierRate.ChainName and mocCal.GroupName = tierRate.GroupName										
			JOIN
			mtSecSalesReport sec ON mocCal.SecSalesId=sec.Id 
			JOIN
			MTTierBasedTOTRate om ON om.ChainName=mocCal.ChainName and om.GroupName= mocCal.GroupName 
			and  om.OutletTier= sec.OutletTier  and om.ColorNonColor=mocCal.ColorNonColor and om.PriceList=sec.PriceList
		WHERE
		sec.MOC= @moc
	
		
		--Update OnInvoice Rate and Value  
		--for some special cased where instead of GSV, Net sales values needs to be considered.
		UPDATE
		mocCal
		SET			
			--OnInvoiceRate = om.OnInvoiceRate,
			OnInvoiceValue = round((sec.NetSalesValue * (OnInvoiceRate)),4),
			OnInvoiceFinalValue = AdditionalMargin + round((sec.NetSalesValue * (OnInvoiceRate)),4),
			--Off Mnthly
			OffInvoiceMthlyValue = round((sec.NetSalesValue * (OffInvoiceMthlyRate)),4),
			OffInvoiceMthlyFinalValue = round(round((sec.NetSalesValue * (OffInvoiceMthlyRate)),4),0),
			--OFF Qtrly
			OffInvoiceQtrlyValue = round((sec.NetSalesValue * (OffInvoiceQtrlyRate)),4),
			OffInvoiceQtrlyFinalValue = round(round((sec.NetSalesValue * (OffInvoiceQtrlyRate)),4),0)
						
		FROM
			mtMOCCalculation mocCal			
			JOIN
			mtSecSalesReport sec ON mocCal.SecSalesId=sec.Id 			
		WHERE
		sec.MOC= @moc and mocCal.StateCode in (Select StateCode from mtOnInvoiceValueConfig where IsNetSalesValueAppl = 1)


		
	--	--Get Service Tax Rate 
	----Todo
	UPDATE
			mocCal
			SET
				ServiceTaxRate = om.Rate,
				--calculation pending (Off invoice Quarterly * om.Rate)
				ServiceTax = OffInvoiceQtrlyValue * om.Rate				
			FROM
				mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 			
				JOIN mtServiceTaxRateMaster om ON om.ChainName=mocCal.ChainName and om.GroupName=mocCal.GroupName
			WHERE
			sec.MOC= @moc
			
			
			--Update OffInvoiceQtrlyFinalValue 
			UPDATE
			mocCal
			SET				
				OffInvoiceQtrlyFinalValue = ROUND(OffInvoiceQtrlyValue + ServiceTax + HuggiesPackMargin,0)
			FROM
				mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 							
			WHERE
			sec.MOC= @moc



		

END


GO



/****** Object:  StoredProcedure [dbo].[mtspGenerateJV]    Script Date: 07/08/2016 12:14:28 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mtspGenerateJV]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mtspGenerateJV]
GO

/****** Object:  StoredProcedure [dbo].[mtspGenerateJV]    Script Date: 07/08/2016 12:14:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[mtspGenerateJV] 
	@moc nvarchar(7),
	@user nvarchar(100)
AS
BEGIN
	--Generate ON Invoice JV

	declare @mocMonthNumber integer
	declare @mocYearNumber integer

	declare @mocMonthName varchar(3)
	declare @mocYear varchar(2)
	declare @mocFullName varchar(5)
	declare @internalOrder varchar(12)
	declare @glItemText varchar(200)
	declare @debitGLAccount varchar(10)
	declare @creditGLAccount varchar(10)
	declare @distrChannel varchar(2)

	set @distrChannel= 'KA'
	set @mocMonthNumber = convert(int,substring(@moc,0,CHARINDEX('.',@moc)))
	select @mocMonthName = SUBSTRING('JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC ', (@mocMonthNumber * 4) - 3, 3)

	set @mocYearNumber = convert(int, substring(@moc,CHARINDEX('.',@moc)+1,4))
	set @mocYear = ( @mocYearNumber % 100 )
	set @mocFullName = @mocMonthName + CONVERT(varchar(2),@mocYear)

	set @internalOrder = 'Z6' + @mocFullName + 'VIST'
	
	
	select @debitGLAccount = GLAccount from mtGLMaster where dbcr='Dr'
	select @creditGLAccount = GLAccount from mtGLMaster where dbcr='Cr'



	print @mocFullName
	print @internalOrder
	print @glItemText

	--Generate On Invoice JV 
	set @glItemText = 'KA MOC TOT PROV MONTHLY ONINVOICE ' +  @mocFullName

	if exists (select * from mtJV where moc=@moc)
	begin
		print 'exists'
		delete from mtJV where moc=@moc
	end

	insert into mtJV(Id,MOC,GLAccount,Amount,BranchCode,InternalOrder,GLItemText,PMHBrandCode,DistrChannel,ProfitCenter,COPACustomer,[Type])	
	select NEWID(),@moc,@debitGLAccount,ROUND(sum(mocCal.OnInvoiceFinalValue),0),sec.BranchCode,@internalOrder,@glItemText,sec.PMHBrandCode,@distrChannel,'', RIGHT('0000000000'+ISNULL(mocCal.Cluster,''),10),'ON' 
		FROM
				mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 
				where sec.moc = @moc 
				group by mocCal.Cluster,sec.BranchCode,sec.PMHBrandCode
				having (sum(mocCal.OnInvoiceFinalValue) <> 0)


		----Todo- Credit entry
		--select mocCal.FirstLetterBrand, sum(mocCal.OnInvoiceFinalValue)
		--		from mtMOCCalculation mocCal
		--		JOIN
		--		mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 
		--		where sec.moc = @moc
		--		group by mocCal.FirstLetterBrand
		--		having (sum(mocCal.OnInvoiceFinalValue) > 0)
	
	--Credit entry	
	insert into mtJV(Id,MOC,GLAccount,Amount,BranchCode,InternalOrder,GLItemText,PMHBrandCode,DistrChannel,ProfitCenter,COPACustomer,[Type])	
	select NEWID(),@moc,@creditGLAccount,ROUND(sum(mocCal.OnInvoiceFinalValue),0)*-1,'',@internalOrder,@glItemText,'',@distrChannel,mocCal.FirstLetterBrand +'XXX', '','ON'
	from mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 
				where sec.moc = @moc and  mocCal.FirstLetterBrand not in('B','J')
				group by mocCal.FirstLetterBrand
				--having (sum(mocCal.OnInvoiceFinalValue) > 0)
		
	--B and J Combine in B brand		
				insert into mtJV(Id,MOC,GLAccount,Amount,BranchCode,InternalOrder,GLItemText,PMHBrandCode,DistrChannel,ProfitCenter,COPACustomer,[Type])	
	select NEWID(),@moc,@creditGLAccount,ROUND(sum(mocCal.OnInvoiceFinalValue),0)*-1,'',@internalOrder,@glItemText,'',@distrChannel,'BXXX', '','ON'
	from mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 
				where sec.moc = @moc and  mocCal.FirstLetterBrand in('B','J')
				--group by mocCal.FirstLetterBrand
				--having (sum(mocCal.OnInvoiceFinalValue) > 0)
	
	  
  


  --Todo Off Invoice Monthly JV
	set @glItemText = 'KA MOC TOT PROV MONTHLY OFFINVOICE ' +  @mocFullName

	insert into mtJV(Id,MOC,GLAccount,Amount,BranchCode,InternalOrder,GLItemText,PMHBrandCode,DistrChannel,ProfitCenter,COPACustomer,[Type])	
	select NEWID(),@moc,@debitGLAccount,ROUND(sum(mocCal.OffInvoiceMthlyFinalValue),0),sec.BranchCode,@internalOrder,@glItemText,sec.PMHBrandCode,@distrChannel,'', RIGHT('0000000000'+ISNULL(mocCal.Cluster,''),10),'OFFM' 
		FROM
				mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 
				where sec.moc = @moc 
				group by mocCal.Cluster,sec.BranchCode,sec.PMHBrandCode
				having (sum(mocCal.OffInvoiceMthlyFinalValue) <> 0)

	
	--Credit entry	
	insert into mtJV(Id,MOC,GLAccount,Amount,BranchCode,InternalOrder,GLItemText,PMHBrandCode,DistrChannel,ProfitCenter,COPACustomer,[Type])	
	select NEWID(),@moc,@creditGLAccount,ROUND(sum(mocCal.OffInvoiceMthlyFinalValue),0)*-1,'',@internalOrder,@glItemText,'',@distrChannel,mocCal.FirstLetterBrand +'XXX', '','OFFM'
	from mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 
				where sec.moc = @moc and  mocCal.FirstLetterBrand not in('B','J')
				group by mocCal.FirstLetterBrand
				--having (sum(mocCal.OffInvoiceMthlyFinalValue) > 0)
		
	--B and J Combine in B brand		
				insert into mtJV(Id,MOC,GLAccount,Amount,BranchCode,InternalOrder,GLItemText,PMHBrandCode,DistrChannel,ProfitCenter,COPACustomer,[Type])	
	select NEWID(),@moc,@creditGLAccount,ROUND(sum(mocCal.OffInvoiceMthlyFinalValue),0)*-1,'',@internalOrder,@glItemText,'',@distrChannel,'BXXX', '','OFFM'
	from mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 
				where sec.moc = @moc and  mocCal.FirstLetterBrand in('B','J')
				--group by mocCal.FirstLetterBrand
				--having (sum(mocCal.OffInvoiceMthlyFinalValue) > 0)
	
	  
  


  --Todo Off Invoice Qtrly JV
set @glItemText = 'KA MOC TOT PROV QTRLY OFFINVOICE ' +  @mocFullName


	insert into mtJV(Id,MOC,GLAccount,Amount,BranchCode,InternalOrder,GLItemText,PMHBrandCode,DistrChannel,ProfitCenter,COPACustomer,[Type])	
	select NEWID(),@moc,@debitGLAccount,ROUND(sum(mocCal.OffInvoiceQtrlyFinalValue),0),sec.BranchCode,@internalOrder,@glItemText,sec.PMHBrandCode,@distrChannel,'', RIGHT('0000000000'+ISNULL(mocCal.Cluster,''),10),'OFFQ' 
		FROM
				mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 
				where sec.moc = @moc 
				group by mocCal.Cluster,sec.BranchCode,sec.PMHBrandCode
				having (sum(mocCal.OffInvoiceQtrlyFinalValue) <> 0)

	
	--Credit entry	
	insert into mtJV(Id,MOC,GLAccount,Amount,BranchCode,InternalOrder,GLItemText,PMHBrandCode,DistrChannel,ProfitCenter,COPACustomer,[Type])	
	select NEWID(),@moc,@creditGLAccount,ROUND(sum(mocCal.OffInvoiceQtrlyFinalValue),0)*-1,'',@internalOrder,@glItemText,'',@distrChannel,mocCal.FirstLetterBrand +'XXX', '','OFFQ'
	from mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 
				where sec.moc = @moc and  mocCal.FirstLetterBrand not in('B','J')
				group by mocCal.FirstLetterBrand
				--having (sum(mocCal.OffInvoiceQtrlyFinalValue) > 0)
		
	--B and J Combine in B brand		
				insert into mtJV(Id,MOC,GLAccount,Amount,BranchCode,InternalOrder,GLItemText,PMHBrandCode,DistrChannel,ProfitCenter,COPACustomer,[Type])	
	select NEWID(),@moc,@creditGLAccount,ROUND(sum(mocCal.OffInvoiceQtrlyFinalValue),0)*-1,'',@internalOrder,@glItemText,'',@distrChannel,'BXXX', '','OFFQ'
	from mtMOCCalculation mocCal
				JOIN
				mtSecSalesReport sec ON  mocCal.SecSalesId=sec.Id 
				where sec.moc = @moc and  mocCal.FirstLetterBrand in('B','J')
				--group by mocCal.FirstLetterBrand
				--having (sum(mocCal.OffInvoiceQtrlyFinalValue) > 0)
	
	  


END



GO





