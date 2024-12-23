using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace HelpDoc.Models
{
    public class Rating
    {
        public int PostId { get; set; }
        public string Username { get; set; }

        public int Value { get; set; }
    }
}