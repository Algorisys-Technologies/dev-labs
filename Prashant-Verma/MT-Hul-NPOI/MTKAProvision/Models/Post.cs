using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace HelpDoc.Models
{
    public class Post
    {
        public int Id { get; set; }

        [Required]
        [StringLength(50)]
        public string Title { get; set; }

        [AllowHtml]
        public string Description { get; set; }

        [StringLength(50)]
        public string CreatedBy { get; set; }

        [StringLength(255)]
        public string Url { get; set; }

        public string ImageUrl { get; set; }

        public double ReadingTime { get; set; }

        public DateTime PublishedOn { get; set; }

        public int NormalizedRating { get; set; }
        public int Rating { get; set; }

        public decimal SortOrder { get; set; }

        public List<Section> Sections { get; set; }
        public List<Rating> Ratings { get; set; }

        public int? ParentId { get; set; }

        public List<Tag> Tags { get; set; }
        public Post()
        {
            Sections = new List<Section>();
            Ratings = new List<Rating>();
            Tags = new List<Tag>();
        }

    }
}