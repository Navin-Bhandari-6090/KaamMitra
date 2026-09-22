using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class UpdateAddressDTO
    {


        [Required]
        [StringLength(200)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        public string Address { get; set; } = string.Empty;


    }
}
