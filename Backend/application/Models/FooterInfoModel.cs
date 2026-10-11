using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models
{
    public class FooterInfoModel
    {

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int FooterInfoId { get; set; }

        [Required]
  
        public string ContactNumber { get; set; } = string.Empty;


        [Required]

        public string Address { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]

        public string SocialMediaInfo{ get; set; } = string.Empty;


    }
}
