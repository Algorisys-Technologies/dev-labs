using Biggy;
using HelpDoc.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Biggy.Extensions;

namespace HelpDoc.Data
{
    public class HelpDb
    {
        static string DB_PATH = HttpContext.Current.Server.MapPath("~/files");

        public BiggyList<Post> Posts = new BiggyList<Post>(DB_PATH);

        public BiggyList<Tag> Tags = new BiggyList<Tag>(DB_PATH);

        public BiggyList<Section> Sections = new BiggyList<Section>(DB_PATH);

        public BiggyList<AppUser> Users = new BiggyList<AppUser>(DB_PATH);

        public bool Create(Post post)
        {
            Posts.Add(post);
            Posts.Save();
            return true;
        }

        public bool Update(Post post)
        {
            var find = Posts.First<Post>(p => p.Id == post.Id);
            var currentId = find.Id;
            Posts.Remove(find);
            post.Id = currentId;
            Posts.Add(post);
            Posts.Save();
            return true;
        }

        public void Delete(Post post)
        {
            Posts.Remove(post);
            Posts.Save();
        }

        public List<Post> All()
        {
            var posts = Posts.TryLoadFileData(DB_PATH + "/posts.json");
            return posts;
        }
    }
}