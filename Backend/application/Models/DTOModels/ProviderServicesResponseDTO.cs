namespace application.Models.DTOModels
{
    public class ProviderServicesResponseDTO
    {
        public int ProviderServiceId { get; set; }

        public string ServiceName { get; set; } = string.Empty;

        public string ServiceDocument { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public int UserNumber { get; set; }
    }
}
