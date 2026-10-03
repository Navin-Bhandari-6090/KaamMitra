using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class UserNumberDTO
    {
        [Required]
        public int UserNumber { get; set; }
    }
}
