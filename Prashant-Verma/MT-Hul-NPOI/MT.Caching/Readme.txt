//Usage
if (!CacheEngine.CacheManager<string>.Cache.Contains("test"))
            {
                CacheEngine.CacheManager<string>.Cache.Add("test", "testData");
            }
            var data = CacheEngine.CacheManager<string>.Cache.Get("test");
