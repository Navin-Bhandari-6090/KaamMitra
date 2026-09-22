using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class DescriptionBookingDTO
    {

        [Required]
        public string UserBookingDescription { get; set; } = string.Empty;

        [Required]
        public int BookId { get; set; }

        [Required]
        [EmailAddress]
        [StringLength(200)]
        public string UserEmail { get; set; }

    }
}
