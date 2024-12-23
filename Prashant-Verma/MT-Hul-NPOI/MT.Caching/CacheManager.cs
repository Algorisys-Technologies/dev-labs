using System.Configuration;
namespace MT.CacheEngine
{
    public class CacheManager<T>
    {
        public static ICache<T> Cache
        {
            get
            {
                //string cacheContext = ConfigurationManager.AppSettings["CacheProvider"] as string;
                return new WebCache<T>();
                //if (cacheContext == "WebCache")
                //{
                //    return new WebCache();
                //}
                //else
                //{
                //    return new RedisCache();
                //}
            }
        }

        public static ICache<T> GetWebCache()
        {
            return new WebCache<T>();
        }
    }
}
