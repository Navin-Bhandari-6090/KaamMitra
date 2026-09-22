using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class Update_UserName_DTO
    {

        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        public string LastName { get; set; } = string.Empty;

    }
}
