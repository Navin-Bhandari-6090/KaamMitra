namespace application.Models.DTOModels
{
    public class SendServDocumentDTO
    {

        public int ProviderServiceId { get; set; }

        public string ServiceName { get; set; } = string.Empty;

        public string ServiceDocument { get; set; } = string.Empty;

       
    }
}
