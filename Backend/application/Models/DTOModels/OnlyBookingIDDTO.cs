using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class OnlyBookingIDDTO
    {
        [Required]
        public int BookId { get; set; }
    }
}
