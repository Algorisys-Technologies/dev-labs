using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Collections;

namespace MT.SessionManager
{
    public class TestWebSessionManager: ISessionManager
    {
        static Hashtable hashTable = new Hashtable();
 
        #region IStateManager Members

        public string SessionId
        {
            get { return Guid.NewGuid().ToString(); }
        }


        public void Add(string key, object value)
        {
            hashTable[key] = value;
        }

        public void Remove(string key)
        {
            if (hashTable.Contains(key))
            {
                hashTable.Remove(key);
            }
        }

        public object Get(string key)
        {
            if (hashTable.Contains(key))
            {
                return hashTable[key];
            }
            else
            {
                return null;
            }
        }

        public void Clear()
        {
            hashTable.Clear(); 
        }

        public void Abandon()
        {
            hashTable.Clear();
        }

        #endregion        
    }
}
