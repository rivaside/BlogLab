using System;
using System.Collections.Generic;
using System.Text;

namespace BlogLab.Models.Account
{
    public class ApplicationUser
    {
        public int ApplicationUserId { get; set; }
        public string UserName { get; set; }
        public int Fullname { get; set; }
        public int Email { get; set; }
        public int Token { get; set; }
    }
}
