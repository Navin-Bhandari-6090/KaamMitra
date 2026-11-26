using System.ComponentModel.DataAnnotations;

namespace application.Models.DTOModels
{
    public class NoticeInfoDTO
    {

 

        public int ProviderServiceId { get; set; }


        [Required]
        public string Message { get; set; } = string.Empty;

    }
}
