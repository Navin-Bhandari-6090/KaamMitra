using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class DelNoOfResPerUserIDDTO
    {

        [Required]
        public int ResourcesNumberId { get; set; }
    }
}
