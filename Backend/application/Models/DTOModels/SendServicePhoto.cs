namespace application.Models.DTOModels
{
    public class SendServicePhoto
    {

        public string ServiceName { get; set; } = string.Empty;

        public int ProviderServiceResourcesId { get; set; }

        public string ServicePhoto { get; set; } = string.Empty;

        public int ProviderServiceId { get; set; }

        public string ServiceTitle { get; set; } = string.Empty;



    }
}
