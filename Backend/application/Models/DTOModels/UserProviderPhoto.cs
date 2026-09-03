using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class UserProviderPhoto
    {
        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;


        [Required]
        public IFormFile Photo { get; set; } = null; 

       

        [Required]
        public string PhotoExtension { get; set; } = string.Empty;


    }
}
