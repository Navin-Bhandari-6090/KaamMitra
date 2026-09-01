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
        public string Photo { get; set; } = string.Empty;
    }
}
