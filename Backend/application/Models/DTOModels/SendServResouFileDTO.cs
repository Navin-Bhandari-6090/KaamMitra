namespace application.Models.DTOModels
{
    public class SendServResouFileDTO
    {

        public string ServiceName { get; set; } = string.Empty;

        public int ProviderServiceResourcesId { get; set; }

        public string ResourceFile { get; set; } = string.Empty;

        public int ProviderServiceId { get; set; }

        public string ServiceTitle { get; set; } = string.Empty;


    }
}
