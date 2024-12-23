using HelpDoc.Data;
using HelpDoc.Models;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Web;
using System.Web.Http;

namespace MTKAProvision.Api
{
    public class PostController : ApiController
    {
        HelpDb db = new HelpDb();

        [ActionName("allposts")]
        public IEnumerable<Post> Get()
        {
            //return StubData.Posts;
            return db.All();
        }

        [ActionName("tags")]
        [HttpGet]
        public IEnumerable<Tag> Tags()
        {
            return db.Tags;
        }

        [ActionName("bytag")]
        [HttpGet]
        public IEnumerable<Post> ByTag(string id)
        {
            var tag = db.Tags.Where(g => g.TagName.ToLower() == id.ToLower()).FirstOrDefault();
            var posts = db.Posts.Where(b => b.Tags.Contains(tag));

            return posts;
        }

        // GET: api/Book/5
        [ActionName("byid")]
        public Post Get(int id)
        {
            var post = db.Posts.Where(b => b.Id == id).FirstOrDefault();
            //post.NormalizedRating = (int)post.Ratings.Average(b => b.Value);
            return post;
        }

        [ActionName("sectionsbypost")]
        public List<Section> GetSectionsById(int id)
        {
            var post = db.Posts.Where(b => b.Id == id).FirstOrDefault();
            return post.Sections;
        }

        // POST: api/Book/create

        [ActionName("create")]
        public int Create([FromBody]Post post)
        {
            if (db.Posts.Count == 0)
            {
                post.Id = 1;
                post.SortOrder = 1;
            }
            else
            {
                post.Id = db.Posts.Max(p => p.Id) + 1;
                post.SortOrder = db.Posts.Max(p => p.SortOrder) + 1;

            }

            post.PublishedOn = DateTime.UtcNow;

            post.CreatedBy = "admin";
            db.Posts.Add(post);
            db.Update(post);
            return post.Id;
        }

        [ActionName("update")]
        public int Update([FromBody]Post post)
        {

            db.Update(post);
            return post.Id;
        }

        [ActionName("uploadimage")]
        public HttpResponseMessage TinyMceUpload()
        {
            var file = HttpContext.Current.Request.Files.Count > 0 ?
                        HttpContext.Current.Request.Files[0] : null;

            var location = SaveFile(HttpContext.Current.Server.MapPath("~/uploads/"), file);

            //{"success":true,"file":"img_57a30bbec2fa34.24917109.png"}
            var response = this.Request.CreateResponse(HttpStatusCode.OK);
            string jsonString = "{\"success\":\"true\", \"file\":\"" + location + "\"}";

            response.Content = new StringContent(jsonString, Encoding.UTF8, "application/json");
            return response;
        }

        private static string SaveFile(string targetFolder, HttpPostedFile file)
        {
            const int megabyte = 1024 * 1024;

            if (!file.ContentType.StartsWith("image/"))
            {
                throw new InvalidOperationException("Invalid MIME content type.");
            }

            var extension = Path.GetExtension(file.FileName.ToLowerInvariant());
            string[] extensions = { ".gif", ".jpg", ".png" };
            if (!extensions.Contains(extension))
            {
                throw new InvalidOperationException("Invalid file extension.");
            }

            if (file.ContentLength > (8 * megabyte))
            {
                throw new InvalidOperationException("File size limit exceeded.");
            }

            var fileName = Guid.NewGuid() + extension;
            var path = Path.Combine(targetFolder, fileName);
            file.SaveAs(path);

            return Path.Combine("/uploads", fileName).Replace('\\', '/');
        }


        [ActionName("upvote")]
        public void UpVote([FromUri] int postId, string username)
        {
            var post = db.Posts.Where(b => b.Id == postId).FirstOrDefault();
            post.Rating++;
            post.Ratings.Add(new Rating
            {
                PostId = postId,
                Value = 5,
                Username = username
            });

        }

        [ActionName("downvote")]
        public void DownVote([FromUri] int postId, string username)
        {
            var post = db.Posts.Where(b => b.Id == postId).FirstOrDefault();
            post.Rating--;
            post.Ratings.RemoveAt(0);
        }


        // POST: api/Book/section
        [ActionName("section")]
        public Section Post([FromBody]Section section, [FromUri]string username)
        {
            section.Id = db.Sections.Count() + 1;
            section.Username = username;
            section.User = db.Users.Where(u => u.Username.ToLower() == username.ToLower()).FirstOrDefault();

            db.Sections.Add(section);

            var post = db.Posts.Where(b => b.Id == section.PostId).FirstOrDefault();
            post.Sections.Add(section);


            return section;
        }

        // PUT: api/Book/5
        public void Put(int id, [FromBody]Post post)
        {
        }

        [ActionName("remove")]
        [HttpPost]
        public void Delete(int id)
        {
            var post = db.Posts.Where(b => b.Id == id || b.ParentId == id).ToList();
            foreach (var deleteId in post)
            {
                db.Delete(deleteId);
            }
            //db.Delete(post);
        }
    }
}
