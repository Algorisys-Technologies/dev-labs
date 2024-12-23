using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace HelpDoc.Models
{
    public class AppUser
    {
        public int Id { get; set; }
        
        [Required]
        [StringLength(100)]
        public string Username { get; set; }
        
        [Required]
        [StringLength(20)]
        public string Password { get; set; }

        public bool IsAdmin { get; set; }

        public AppUser()
        {
            IsAdmin = false;
        }
    }
}