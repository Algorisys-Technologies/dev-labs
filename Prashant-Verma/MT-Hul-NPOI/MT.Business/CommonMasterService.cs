using MT.DataAccessLayer;
using MT.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MT.Business
{
    public class CommonMasterService
    {
        public BaseResponse DeleteMasters(string[] idList, string StoredProcedureName, UserRoleRights loggedUser)
        {
            BaseResponse response = new BaseResponse();
            if (idList != null)
            {
                var lastColumn = idList.Last();
                foreach (var col in idList)
                {
                    DbRequest request = new DbRequest();
                    SmartData data = new SmartData();
                    request.Parameters = new List<Parameter>();
                    Parameter basepackcode = new Parameter("@Id", col);
                    Parameter pram = new Parameter("@user", loggedUser.UserId);
                    request.Parameters.Add(pram);
                    request.Parameters.Add(basepackcode);
                    request.StoredProcedureName = StoredProcedureName;
                    try
                    {
                        data.ExecuteStoredProcedure(request);
                    }
                    catch (Exception e)
                    {
                        response.IsSuccess = false;
                        response.MessageText = "Error:" + e.Message + "";
                        return response;
                    }

                }


                response.IsSuccess = true;
                response.MessageText = "Selected Row(s) Delete Successfully";
                return response;
            }
            return null;


        }

    }
}
