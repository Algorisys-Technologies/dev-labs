using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;

namespace MT.SessionManager
{
    public static class SessionManager<T>
    {
        private static ISessionManager currentStateManager = new WebSessionManager();

        public static string GetSessionId()
        {
            return currentStateManager.SessionId;
        }

        
        #region SetStateManager
        /// <summary>
        /// Sets the session Manager.
        /// </summary>
        /// <param name="manager">The manager.</param>
        public static void SetStateManager(ISessionManager manager)
        {
            currentStateManager = manager;
        } 
        #endregion

        #region Add
        /// <summary>
        /// Adds the specified key.
        /// </summary>
        /// <param name="key">The key.</param>
        /// <param name="value">The value.</param>
        public static void Add(string key, T value)
        {
            currentStateManager.Add(key, value);
        }
        
        #endregion

        #region Get
        /// <summary>
        /// Gets the specified key.
        /// </summary>
        /// <param name="key">The key.</param>
        /// <returns></returns>
        public static T Get(string key)
        {
                return (T)currentStateManager.Get(key);
        } 
        #endregion

        #region Remove
        /// <summary>
        /// Removes the specified key.
        /// </summary>
        /// <param name="key">The key.</param>
        public static void Remove(string key)
        {
            currentStateManager.Remove(key);
        } 
        #endregion

        #region Clear
        /// <summary>
        /// Clears this instance.
        /// </summary>
        public static void Clear()
        {
            currentStateManager.Clear();
        } 
        #endregion

        #region Abandon
        /// <summary>
        /// Abandons this instance.
        /// </summary>
        public static void Abandon()
        {
            currentStateManager.Abandon();
        } 
        #endregion

    }
}
