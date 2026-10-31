using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class SendSharedMediaDTO
    {

        public int SharedMediaId { get; set; }

      
        public string MediaDescription { get; set; } = string.Empty;


        public string? ServicePhoto { get; set; } = string.Empty;


        public string? ServiceVideo { get; set; } = string.Empty;

        public string? ServiceFile { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;


        public int SenderNumber { get; set; }

      
        public int ReceiverNumber { get; set; }

        public string SenderName { get; set; }

        public string ReceiverName { get; set; }


    }
}
