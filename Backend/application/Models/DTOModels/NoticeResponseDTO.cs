using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class NoticeResponseDTO
    {

        public int NoticeId { get; set; }

        public int ProviderNumber { get; set; }

        public DateTime? CreatedAt { get; set; } = DateTime.UtcNow;

        public string Message { get; set; } = string.Empty;

   
        public string FirstName { get; set; } = string.Empty;

        public string LastName { get; set; } = string.Empty;

        public string Photo { get; set; } = string.Empty;

        public string ServiceName { get; set; } = string.Empty;


    }
}
