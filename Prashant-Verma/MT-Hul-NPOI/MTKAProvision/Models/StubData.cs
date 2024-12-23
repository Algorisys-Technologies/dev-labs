using HelpDoc.Utilities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace HelpDoc.Models
{
    public static class StubData
    {
        public static List<Post> Posts = new List<Post>();
        public static List<AppUser> Users = new List<AppUser>();
        public static List<Section> Sections = new List<Section>();
        public static List<Rating> Ratings = new List<Rating>();

        //public static List<string> Tags = new List<string>();
        public static List<Tag> Tags = new List<Tag>();
        static StubData()
        {
            Tags.Add(new Tag("Customization"));
            Tags.Add(new Tag("FAQ"));
            Tags.Add(new Tag("Support"));
            Tags.Add(new Tag("Common Tasks"));

            SetupData();

        }
        public static void SetupData()
        {
            var encryption = new EncryptionHelper();
            string salt = SecurityUtil.GenerateSalt();

            // Create some users
            for (var i = 1; i <= 5; i++)
            {
                var user = new AppUser
                {
                    Id = 1,
                    Username = "user" + i.ToString(),
                    Password = encryption.EncodePassword("123456", 1, salt)
                };

                Users.Add(user);

            }

            // create an admin user
            var admin = new AppUser
            {
                Id = 99,
                Username = "admin",
                Password = encryption.EncodePassword("123456", 1, salt),
                IsAdmin = true
            };

            Users.Add(admin);


            int sectionCount = 10;

            Random rndDuration = new Random();
                    
            for (var i = 1; i <= 20; i++)
            {
                var post = new Post
                {
                    CreatedBy = "Author " + i.ToString(),
                    Title = "Help Topic  " + i.ToString(),
                    Url = "<a target='_blank' href='https://leanpub.com/qlikview-recipes'>Book webpage</a>",
                    Id = i,
                    ImageUrl = "/uploads/posts/" + (i % 2 == 0 ? "1.png" : "2.png"),
                    PublishedOn = DateTime.Now.AddDays(-i),
                    ReadingTime = rndDuration.Next(1, 12),
                    Description = "The content of the help goes here.  Be as detailed as possible. "
                    
                    //Tag = Tags.ElementAt(rndDuration.Next(1, Tags.Count))
                };

                var genCount = rndDuration.Next(1, Tags.Count);

                for (var g = 0; g < genCount; g++)
                {
                    post.Tags.Add(Tags[g]);
                    //Tags[g].Books.Add(post);
                }

                if (i % 2 == 0) sectionCount = 20;  // random section count

                for (var j = 1; j <= sectionCount; j++)
                {
                    var u = Users[j % 5];
                    var section = new Section
                    {
                        Title = "Section of " + post.Title,
                        Body = "An excellent post, " + post.Title ,
                        PostId = post.Id,
                        Id = i*j,
                        Username = u.Username,
                        User = u
                    };

                    Random rnd = new Random();
                    var rating = new Rating
                    {
                        PostId = post.Id,
                        Username = u.Username,
                        Value =  rnd.Next(0,5)
                    };

                    post.Sections.Add(section);
                    post.Ratings.Add(rating);

                    Ratings.Add(rating);
                    Sections.Add(section);

                }

                Posts.Add(post);
            }
        }
    }
 
}