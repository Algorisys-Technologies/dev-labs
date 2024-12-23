using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace MT.SessionManager
{
    /// <summary>
    /// Common interface for SessionManager
    /// </summary>
    public interface ISessionManager
    {
        string SessionId { get;}

        void Add(string key, object value);       
        void Remove(string key);
        object Get(string key);
        void Clear();
        void Abandon();
    }
}
