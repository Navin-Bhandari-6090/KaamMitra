using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace application.Models.DTOModels
{
    public class SharedMediaDTO
    {
    
        public int SharedMediaId { get; set; }

        [Required]
        public string MediaDescription { get; set; } = string.Empty;


        public IFormFile? ServicePhoto { get; set; } = null;


        public IFormFile? ServiceVideo { get; set; } = null;

        public IFormFile? ServiceFile { get; set; } = null;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public int? SenderNumber { get; set; }

        [Required]
        public int ReceiverNumber { get; set; }



    }
}
