using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class SharedMediaIDDTO
    {
        [Required]
        public int SharedMediaId { get; set; }

    }
}
