using System;
using System.Collections;
using System.Collections.Generic;

namespace MT.CacheEngine
{
    public class MemoryCache<T>: ICache<T>
    {
        static Hashtable ht = new Hashtable();

        public T Get(string key)
        {
            if(Contains(key))
            {               
                return (T)ht[key];
            }
            return default(T);
        }

        public void Add(string key, T value)
        {
            ht[key] = value;
        }

        public void Add(string key, T value, System.Web.Caching.CacheDependency dependencies)
        {
            ht[key] = value;
        }

        public void Add(string key, T value, System.Web.Caching.CacheDependency dependencies, DateTime absoluteExpiration, TimeSpan slidingExpiration)
        {
            ht[key] = value;
        }

        public void Remove(string key)
        {
            if(Contains(key))
            {
                ht.Remove(key);
            }
        }


        public void RemoveAll()
        {
            IDictionaryEnumerator enumerator = ht.GetEnumerator();
            List<string> keyList = new List<string>();
            while (enumerator.MoveNext())
            {
                keyList.Add(enumerator.Key.ToString());
            }
            foreach (string key in keyList)
            {
                Remove(key);
            }
        }


        public bool Contains(string key)
        {
            if (ht[key] != null)
                return true;
            
            return false;            
        }


        public long Count
        {
            get
            {
                return ht.Count;
            }
        }

        public T this[string key]
        {
            get {   return (T)ht[key]; }
            set { ht[key] = value; }
        }
        //public T GetResult<T>(string key) where T : class, new()
        //{
        //    return null;
        //    //return result;
        //}

    }
}
