using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data.Entity;

using System.Data.Entity.Infrastructure;


namespace HelpDoc.Models
{
    public class DbContext : System.Data.Entity.DbContext
    {
        public DbSet<Post> Posts { get; set; }
        public DbSet<Rating> Ratings { get; set; }
        public DbSet<Section> Sections { get; set; }
        public DbSet<Tag> Tags { get; set; }

        public DbContext() : base("name=HelpDb")
        {
            ((IObjectContextAdapter)this).ObjectContext.CommandTimeout = 300;  // ToDo: Move hardcoded value out..
        }

        

    }
}

