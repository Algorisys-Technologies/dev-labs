using System;
using System.Web;
using System.Web.Caching;
using System.Collections;
using System.Collections.Generic;

namespace MT.CacheEngine
{
    public class WebCache<T>: ICache<T>
    {
        //private static Cache cache = new Cache();

        public T Get(string key)
        {            
            if(Contains(key))
                return (T)HttpContext.Current.Cache.Get(key);
            else
                 return default(T);            
        }

        public void Add(string key, T value)
        {
            HttpContext.Current.Cache.Insert(key, value);
        }

        public void Add(string key, T value, CacheDependency dependencies)
        {
            HttpContext.Current.Cache.Insert(key, value, dependencies);
        }

        public void Add(string key, T value, CacheDependency dependencies, DateTime absoluteExpiration, TimeSpan slidingExpiration)
        {
            HttpContext.Current.Cache.Insert(key, value, dependencies, absoluteExpiration, slidingExpiration);
        }

        public void Remove(string key)
        {
            if (Contains(key))
                HttpContext.Current.Cache.Remove(key);

        }

        public void RemoveAll()
        {
            IDictionaryEnumerator enumerator = HttpContext.Current.Cache.GetEnumerator();
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
            if (HttpContext.Current.Cache[key] != null)
                return true;
            
            return false;            
        }


        public long Count
        {
            get
            {
                return HttpContext.Current.Cache.Count;
            }
        }

        public T this[string key]
        {
            get {
                if (Contains(key))
                {
                    return (T)HttpContext.Current.Cache[key];
                }
                else return default(T);
            }
            set
            {
                if (HttpContext.Current.Cache[key] != null)
                    HttpContext.Current.Cache[key] = value;
                else
                    Add(key, value);
            }
        }

        //public T GetResult<T>(string key) where T : class, new()
        //{
        //    if (Contains(key))
        //        return (T)HttpContext.Current.Cache.Get(key);
        //    else
        //        return null;
        //}


    }
}
