using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class UpdateEmailDTO
    {
        [Required]
        [EmailAddress]
        public string OldEmail { get; set; }

        [Required]
        [EmailAddress]
        public string NewEmail { get; set; }


    }
}
