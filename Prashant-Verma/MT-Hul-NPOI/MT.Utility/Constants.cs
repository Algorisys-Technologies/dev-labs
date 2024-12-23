using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Utility
{
    public class MTConstants
    {

    }
    public class MasterConstants
    {
        public static string[] Cutomer_Group_Excel_Column = { "Customer code", "Region" };
        public static string[] Cutomer_Group_DB_Column = { "CustomerCode", "StateCode" };
        public static string Customer_Group_Master_Table_Name = "mtCustomerGroupMaster";
        public static string Customer_Group_Master_UpdateSP_Name = "Update_mtCustomerGroupMaster";
        public static string[] Customer_Group_Unique_Column = { "Customer code" };


        public static string Customer_Group_Master_UpdateSP_Param_Name = "@tblCustomerGroup";

        public static string[] BrandWise_SubCategory_Excel_Column = { "PMH Brand", "PMH Brand Name", "Sales Sub-Category", "Price List", "TOT% Sub Category Name" };
        public static string[] BrandWise_SubCategory_DB_Column = { "PMHBrandCode", "PMHBrandName", "SalesSubCat", "PriceList", "TOTSubCategory" };
        public static string BrandWise_SubCategory_Master_Table_Name = "mtBrandWiseTOTSubCategoryMapping";
        public static string BrandWise_SubCategory_Master_UpdateSP_Name = "Update_mtBrandWiseTOTSubCategoryMapping";
        public static string BrandWise_SubCategory_Master_UpdateSP_Param_Name = "@tblBrandWiseTOTSubCategory";
        public static string[] BrandWise_SubCategory_Unique_Column = { "PMH Brand", "Sales Sub-Category", "Price List"};

        public static string[] ServiceTax_Excel_Column = { "Chain Name", "Group Name", "Rate" };
        public static string[] ServiceTax_DB_Column = { "ChainName", "GroupName", "Rate" };
        public static string ServiceTax_Master_Table_Name = "mtServiceTaxRateMaster";
        public static string ServiceTax_Master_UpdateSP_Name = "Update_mtServiceTaxRateMaster";
        public static string ServiceTax_Master_UpdateSP_Param_Name = "@tblServiceTaxRateMaster";

        public static string[] Sku_Excel_Column = { "Base Pack", "Tax code" };
        public static string[] Sku_Db_Column = {"BasepackCode", "TaxCode" };
        public static string Sku_Master_Table_Name = "mtSkuMaster";
        public static string Sku_Master_UpdateSP_Name = "Update_mtSkuMaster";
        public static string Sku_Master_UpdateSP_Param_Name = "@tblSku";

        public static string[] Gst_Excel_Column = { "Basepack code", "GST Rate" };
        public static string[] Gst_Db_Column = { "BasepackCode", "GstRate" };
        public static string Gst_Master_Table_Name = "mtGstMaster";
        public static string Gst_Master_UpdateSP_Name = "Update_mtGstMaster";
        public static string Gst_Master_UpdateSP_Param_Name = "@tblGst";


        public static string[] Outlet_Excel_Column = { "HUL Outlet Code", "Chain Name", "Group Name", "Color/Non color" };
        public static string[] Outlet_Db_Column = { "HulOutletCode", "ChainName", "GroupName", "ColorNonColor" };
        public static string Outlet_Master_Table_Name = "mtOutletMaster";
        public static string Oulet_Master_UpdateSP_Name = "Update_mtOutletMaster";
        public static string Oulet_Master_UpdateSP_Param_Name = "@tblOutlet";

        public static string[] HuggiesBasepack_Excel_Column = { "Huggies Basepack Code", "SKUs Description", "Percentage" };
        public static string[] HuggiesBasepack_Db_Column = { "BasepackCode", "SKUDescription", "Percentage" };
        public static string HuggiesBasepack_Master_Table_Name = "mtHuggiesPercentageMaster";
        public static string HuggiesBasepack_Master_UpdateSP_Name = "Update_mtHuggiesBasepackMaster";
        public static string HuggiesBasepack_Master_UpdateSP_Param_Name = "@tblHuggiesBasepack";

        public static string[] ClusterRSCodeMapping_Excel_Column = { "Cluster Code", "RS Code" };
        public static string[] ClusterRSCodeMapping_Db_Column = { "ClusterCode", "RSCode" };
        public static string ClusterRSCodeMapping_Master_Table_Name = "mtClusterRSCodeMappingMaster";
        public static string ClusterRSCodeMapping_Master_UpdateSP_Name = "Update_mtClusterRSCodeMappingMaster";
        public static string ClusterRSCodeMapping_Master_UpdateSP_Param_Name = "@tblClusterRSCodeMapping";

        public static string[] Sales_Tax_Excel_Column = { "TaxCode", "StateCode", "SalesTaxRate" };
        public static string[] Sales_Tax_DB_Column = { "TaxCode", "StateCode", "SalesTaxRate" };
        public static string Sales_Tax_Master_Table_Name = "mtSalesTaxMaster";
        public static string Sales_Tax_Master_Master_UpdateSP_Name = "Update_mtSalesTaxMaster";
        public static string Sales_Tax_Master_Master_UpdateSP_Param_Name = "@tblSalesTaxMaster";

        //public static string[] SubCategory_TOT_Excel_Column = { "Chain Name", "Group name (as per the base file)", "BRANCH", "Eye", "Face", "Lakme Skin ", "Lip", "Nail", "Ponds Top End ", "Nail Polish Remover ", "Other Items", "LIP & LOVE", "T&G" };
        public static string[] SubCategory_TOT_Excel_Column = { "Chain Name", "Group name (as per the base file)", "BRANCH" };
        public static string SubCategory_TOT_Table_Name = "mtSubCategoryTOTMaster";
        public static string[] SubCategory_TOT_DB_Column = { "ChainName", "GroupName", "Branch", "TOTSubCategory", "OnInvoiceRate", "OffInvoiceMthlyRate", "OffInvoiceQtrlyRate" };
        public static string SubCategory_TOT_Master_UpdateSP_Name = "Update_mtSubCategoryTOTMaster";
        public static string SubCategory_TOT_Master_UpdateSP_Param_Name = "@tblParam";
	    public static string[] SubCategory_TOT_Unique_Column = { "ChainName", "GroupName", "Branch", "TOTSubCategory" };	

        public static string[] AdditionalMargin_Excel_Column = { "RS Code", "RS Name", "Chain name", "Group name", "Price List", "% to be applied" };
	    public static string[] AdditionalMargin_DB_Column = { "RSCode", "RSName", "ChainName", "GroupName", "PriceList", "Percentage" };	
        public static string AdditionalMargin_Master_Table_Name = "mtAdditionalMarginMaster";
        public static string AdditionalMargin_Master_UpdateSP_Name = "Update_mtAdditionalMarginMaster";
        public static string AdditionalMargin_Master_UpdateSP_Param_Name = "@tblAdditionalMarginMaster";

        //public static string[] UploadSecondarySales_Excel_Column = { "Customer Code", "Customer Name", "Outlet Category Master", "Basepack Id", "Basepack Name", "PMH Brand Code", "PMH Brand Name", "Sales SubCategory", "Price List", "HUL Outlet Code", "Branch Code", "MOC", "Cluster Code", "Outlet Tier", "Total Sales Value (INR)", "Sales Return Value (INR)", "Net Sales Value (INR)", "Net Sales Qty (KGs)" };
        //public static string[] UploadSecondarySales_DB_Column = { "CustomerCode", "CustomerName", "OutletCategoryMaster", "BasepackCode", "BasepackName", "PMHBrandCode", "PMHBrandName", "SalesSubCat", "PriceList", "HulOutletCode", "BranchCode", "MOC", "ClusterCode", "OutletTier", "TotalSalesValue", "SalesReturnValue", "NetSalesValue", "NetSalesQty" };
        //public static string[] UploadSecondarySales_Excel_Column = { "Customer Code", "Customer Name", "Outlet Category Master", "Basepack Id", "Basepack Name", "PMH Brand Code", "PMH Brand Name", "Sales SubCategory", "Price List", "HUL Outlet Code", "HUL Outlet Code Name", "Branch Code", "Branch - Master", "MOC", "Outlet Secondary Channel", "Cluster Code", "Cluster Name", "Outlet Tier", "Total Sales Value (INR)", "Sales Return Value (INR)", "Net Sales Value (INR)", "Net Sales Qty (KGs)" };
        public static string[] UploadSecondarySales_Excel_Column = { "Customer", "Customer", "Outlet Category - Master", "Basepack", "Basepack", "PMH Brand", "PMH Brand", "Sales SubCategory", "Price List", "HUL Outlet Code", "HUL Outlet Code", "Branch - Master", "Branch - Master", "MOC", "Outlet Secondary Channel", "Cluster Code", "Cluster Code", "Outlet Tier", "Total Sales Value (INR)", "Sales Return Value (INR)", "Net Sales Value (INR)", "Net Sales Qty (KGs)" };
        public static string[] UploadSecondarySales_DB_Column = { "CustomerCode", "CustomerName", "OutletCategoryMaster", "BasepackCode", "BasepackName", "PMHBrandCode", "PMHBrandName", "SalesSubCat", "PriceList", "HulOutletCode", "HulOutletCodeName", "BranchCode", "BranchName", "MOC", "OutletSecChannel", "ClusterCode", "ClusterName", "OutletTier", "TotalSalesValue", "SalesReturnValue", "NetSalesValue", "NetSalesQty" };
        public static string[] UploadSecondarySales_Excel_Column_WithGst = { "Customer", "Customer", "Outlet Category - Master", "Basepack", "Basepack", "PMH Brand", "PMH Brand", "Sales SubCategory", "Price List", "HUL Outlet Code", "HUL Outlet Code", "Branch - Master", "Branch - Master", "MOC", "Outlet Secondary Channel", "Cluster Code", "Cluster Code", "Outlet Tier", "Total Sales Value (INR)", "Sales Return Value (INR)", "Net Sales Value (INR)", "Net Sales Qty (KGs)", "GST Applicable" };
        public static string[] UploadSecondarySales_DB_Column_WithGst = { "CustomerCode", "CustomerName", "OutletCategoryMaster", "BasepackCode", "BasepackName", "PMHBrandCode", "PMHBrandName", "SalesSubCat", "PriceList", "HulOutletCode", "HulOutletCodeName", "BranchCode", "BranchName", "MOC", "OutletSecChannel", "ClusterCode", "ClusterName", "OutletTier", "TotalSalesValue", "SalesReturnValue", "NetSalesValue", "NetSalesQty", "IsGstApplicable" };
        //public static string[] UploadSecondarySales_Excel_Column = { "Customer Code", "Customer Name"};
        //public static string[] UploadSecondarySales_DB_Column = { "CustomerCode", "CustomerName"};

        public static string UploadSecondarySales_Master_Table_Name = "mtSecSalesReport";
        public static string UploadSecondarySales_Master_UpdateSP_Name = "Update_mtSecSalesReport";

        public static string UploadSecondarySales_Master_UpdateSP_Param_Name = "@tblSecSalesReport";
        public static string Upload_SecSales_Search_Columns = "CustomerCode+CustomerName+OutletCategoryMaster+BasepackCode+BasepackName+PMHBrandCode+PMHBrandName+SalesSubCat+PriceList+HulOutletCode+BranchCode+ClusterCode+OutletTier";

        public static string[] MTTierBasedTOT_Excel_Column = { "Chain Name", "Group Name", "Tier", "Color / Non Color", "Price List", "On Invoice %", "Monthly Off Invoice %", "Qtrly Off Invoice %" };
        public static string[] MTTierBasedTOT_DB_Column = { "ChainName", "GroupName", "OutletTier", "ColorNonColor", "PriceList", "OnInvoiceRate", "OffInvoiceMthlyRate", "OffInvoiceQtrlyRate" };
        public static string MTTierBasedTOT_Master_Table_Name = "MTTierBasedTOTRate";
        public static string MTTierBasedTOT_Master_UpdateSP_Name = "Update_MTTierBasedTOTRate";
        public static string MTTierBasedTOT_Master_UpdateSP_Param_Name = "@tblTierBasedTOTRate";


        public static string[] DownloadAllFileFormatFileName = { "Annexure 1- Outlet Master file.rar", "Annexure 2- Tax masters.rar", "Annexure 3-Customer Group Dump.rar", "Annexure 4- SKU dump.rar", "BrandwiseSubcategorymapping.rar", "ClusterRSCodeMaping.rar", "HuggiesBasepack.rar", "ServiceTaxRate.rar", "TierBasedTOTRate.rar", "AdditionalMargin.rar", "Subcategory TOT%.rar", "Gst Master.rar" };
        //public static string[] DownloadAllFileFormatFileName = { "Annexure 1- Outlet Master file.rar", "Annexure 2- Tax masters.rar", "Annexure 3-Customer Group Dump.rar" };

        public static string MTGL_Master_UpdateSP_Name = "Update_GLMaster";
        public static string ChainName_Master_DleteSP_Name = "Delete_ChainName";
        public static string MTChainName_Master_UpdateSP_Name = "Update_ChainNameMaster";
        public static string PriceList_Master_DleteSP_Name = "Delete_PriceList";
        public static string MTPriceList_Master_UpdateSP_Name = "Update_PriceListMaster";
        public static string MTOnINnVoiceConfig_Master_UpdateSP_Name = "Update_OnInVoiceConfig";
        public static string OnInVoiceConfig_Master_DleteSP_Name = "Delete_OnInVoiceConfig";

    }
    public class DashBoardConstants
    {
        public static string Step_Master_Table_Name = "mtStepMaster";
        public static string MOC_Status_Table_Name = "mtMOCStatus";
        public static string MOC_Wise_StepDetails_Table_Name = "mtMOCWiseStepDetails";
        public static string UploadMaster_StepId = "UPM";
        public static string UploadProvisionMaster_StepId = "UPPM";
        public static string UploadSecSales_StepId = "UPSEC";
        public static string CalculateGSV_StepId = "GSV";
        public static string CalculateProvision_StepId = "PVSION";
        public static string GenerateJV_StepId = "JV";
        public static string ExportJV_StepId = "ExportJV";
        public static string CloseMOC_StepId = "CLSMOC";
    }

    public class UploadMasterConstants
    {
        public static string CUSTGRP_DetailedStep = "CUSTGRP";
        public static string SKU_DetailedStep = "SKU";
        public static string SALESTAXRATE_DetailedStep = "SALESTAXRATE";
        public static string GST_DetailedStep = "GST";
    }

    public class UploadProvisionalMasterConstants
    {
        public static string OUTLETMASTER_DetailedStep = "OUTLETMASTER";
        public static string ADDMARGIN_DetailedStep = "ADDMARGIN";
        public static string SERVICETAX_DetailedStep = "SERVICETAX";
        public static string HUGGIESBAEPACK_DetailedStep = "HUGGIESBAEPACK";
        public static string CLUSTERRSCODE_DetailedStep = "CLUSTERRSCODE";
        public static string TIERBASEDTOT_DetailedStep = "TIERBASEDTOT";
        public static string SUBCATMAPPING_DetailedStep = "SUBCATMAPPING";
        public static string SUBCATBASEDTOT_DetailedStep = "SUBCATBASEDTOT";
    }

    public class SecurityPageConstants
    {
        public static string PageRightMaster_TableName = "mtPageRightMaster";
        public static string UpdateRights_SpName = "UpdateRoleWisePageRights";
        public static string CustomerGrpMaster_PageId = "CUSTGRP";
        public static string SkuMaster_PageId = "SKU";
        public static string GstMaster_PageId = "GST";
        public static string SalesTaxRateMaster_PageId = "SALESTAXRATE";
        public static string OutletMaster_PageId = "OUTLETMASTER";
        public static string AddMarginMaster_PageId = "ADDMARGIN";
        public static string ServiceTaxMaster_PageId = "SERVICETAX";
        public static string HuggiesBasePackMaster_PageId = "HUGGIESBAEPACK";
        public static string ClusterRsCodeMaster_PageId = "CLUSTERRSCODE";
        public static string TierBasedTOTMaster_PageId = "TIERBASEDTOT";
        public static string SubCatMappingMaster_PageId = "SUBCATMAPPING";
        public static string SubCatTOTMaster_PageId = "SUBCATBASEDTOT";
        public static string SecSalesMaster_PageId = "UPSEC";
        public static string CalculateGSV_PageId = "GSV";
        public static string CalculateProvision_PageId = "PVSION";
        public static string GenerateJV_PageId = "JV";
        public static string ExportJV_PageId = "ExportJV";
        public static string CloseMOC_PageId = "CLSMOC";
        public static string ChainName_PageId = "CHAINNAME";
        public static string PriceList_PageId = "PriceList";
        public static string OnInvoiceConfig_PageId = "OnInvoiceVal";
        public static string GLMaster_PageId = "GL";   

    }

    public class ExportJVMasterConstants
    {

       public static string[] ColumnsToDisplay = { "GL Account", "Document Amount", "Cross Company Code", "Value Date", "GL Tax Code", "Cost Center", "Business Area", "Internal Order", "Transaction Type", "GL Assignment", "GL Item Text", "Trading Partner", "Material", "PO NUMBER", "Brand Code", "Distr Channel", "Plant", "Product", "Profit Center", "WBS Element", "Business Place", "COPA Customer" };

       public static string OnInVoiceExcelNameToDisplay = "JV-OnInvoice-MOC";
       //public static string OnInVoiceViewName = "vwExportOnInvoice";

       public static string OffInVoiceExcelNameToDisplay = "JV-OffInvoice-Mthly-MOC";
       //public static string OffInvoiceViewName = "vwExportOffInvoice";

       public static string OffInVoiceQtrlyExcelNameToDisplay = "JV-OffInvoice-Qtrly-MOC";
       //public static string OffInVoiceQtrlyViewName = "vwExportOffInvoiceQtrly";
    }

    public class ConfigConstants
    {
        public static bool IsLdapLoginEnabled = Convert.ToBoolean(ConfigurationSettings.AppSettings["IsLdapLoginEnabled"]);
        public static string DirectoryPath = ConfigurationSettings.AppSettings["DirectoryPath"];
        public static string DirectoryDomain = ConfigurationSettings.AppSettings["DirectoryDomain"];
        public static bool GstCheck = Convert.ToBoolean(ConfigurationSettings.AppSettings["GstCheck"]);
        public static int ArchiveYears = Convert.ToInt32(ConfigurationSettings.AppSettings["ArchiveYears"]);
    }
}
