using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace HelpDoc.Models
{
    public class Tag
    {
        public string TagName { get; set; }

        public List<Post> Books { get; set; }
        public Tag(string tagName)
        {
            this.TagName = tagName;
            Books = new List<Post>();
        }
    }
}