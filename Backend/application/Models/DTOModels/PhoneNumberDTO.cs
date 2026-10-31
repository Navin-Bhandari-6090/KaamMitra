using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class PhoneNumberDTO
    {
        [StringLength(50)]
        [RegularExpression(
            @"^\+\d+$",
            ErrorMessage = "Phone number must start with '+' followed by digits only."
        )]
        public string? PhoneNumber { get; set; }

        [StringLength(50)]
        [RegularExpression(
            @"^\+\d+$",
            ErrorMessage = "WhatsApp phone number must start with '+' followed by digits only."
        )]
        public string? WhatsappPhoneNumber { get; set; }
    }
}