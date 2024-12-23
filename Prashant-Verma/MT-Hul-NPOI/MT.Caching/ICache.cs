using System;
using System.Web.Caching;

namespace MT.CacheEngine
{
    public interface ICache<T>
    {
        long Count { get; }
        bool Contains(string key);
        T this[string key] { get; set; }
        T Get(string key);
        //T GetResult<T>(string key) where T : class, new();
        void Add(string key, T value);
        void Add(string key, T value, CacheDependency dependencies);

        void Add(string key, T value, CacheDependency dependencies, DateTime absoluteExpiration,
                           TimeSpan slidingExpiration);

        void Remove(string key);

        void RemoveAll();
    }
}
