namespace application.Models.DTOModels
{
    public class SendResVideoDTO
    {

        public string ServiceName { get; set; } = string.Empty;

        public int ProviderServiceResourcesId { get; set; }

        public string ServiceVideo { get; set; } = string.Empty;

        public int ProviderServiceId { get; set; }

    }
}
