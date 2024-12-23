using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace HelpDoc.Models
{
    public class Section
    {
        public int Id { get; set; }

        public int PostId { get; set; }

        [Required]
        [StringLength(50)]
        public string Username { get; set; }

        [StringLength(100)]
        public string Title { get; set; }
        
        public string Body { get; set; }

        public virtual Post Post { get; set; }

        public virtual AppUser User { get; set; }
    }
}