using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;

namespace MT.SessionManager
{
    public class WebSessionManager:ISessionManager
    {
        #region IStateManager Members

        /// <summary>
        /// Gets the session id.
        /// </summary>
        /// <value>The session id.</value>
        public string SessionId
        {
            get { return HttpContext.Current.Session.SessionID; }
        }

        /// <summary>
        /// Adds the specified key.
        /// </summary>
        /// <param name="key">The key.</param>
        /// <param name="value">The value.</param>
        public void Add(string key, object value)
        {

            if (string.IsNullOrEmpty(key))
                throw new ArgumentException("The key should not be null or empty.");
            HttpContext.Current.Session[key] = value;         
        }

        /// <summary>
        /// Removes the specified key.
        /// </summary>
        /// <param name="key">The key.</param>
        public void Remove(string key)
        {
            HttpContext.Current.Session.Remove(key); 
        }

        /// <summary>
        /// Gets the specified key.
        /// </summary>
        /// <param name="key">The key.</param>
        /// <returns></returns>
        public object Get(string key)
        {
                return HttpContext.Current.Session[key];
        }

        /// <summary>
        /// Clears this instance.
        /// </summary>
        public void Clear()
        {
            HttpContext.Current.Session.Clear();
        }

        /// <summary>
        /// Abandons this instance.
        /// </summary>
        public void Abandon()
        {
            HttpContext.Current.Session.Abandon();
        }

        #endregion
    }
}
