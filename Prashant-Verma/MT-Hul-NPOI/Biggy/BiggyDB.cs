using System;
using System.Dynamic;

namespace Biggy
{

    public class BiggyDB : DynamicObject, IDisposable {

    BiggyList<dynamic> CurrentList { get; set; }

    public override bool TryGetMember(GetMemberBinder binder, out object result) {
      //return base.TryGetMember(binder, out result);
      CurrentList = CurrentList ??  new BiggyList<dynamic>(dbName: binder.Name);
      result = CurrentList;
      return true;
    }

    public void Dispose() {
		if (CurrentList == null)
			return;

      CurrentList.Clear();
      CurrentList = null;
    }
  }
}