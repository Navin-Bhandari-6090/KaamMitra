using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class MessageDTO
    {

        [Required]
        public string Message { get; set; }
    }
}
