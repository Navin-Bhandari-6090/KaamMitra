namespace application.Models.DTOModels
{
    public class ChatMessagesResponseDTO
    {

        public string? CurrentUserPhoto { get; set; }
        public string? OtherUserPhoto { get; set; }

        public List<ChatInfoModel> ChatMessages { get; set; } = new();

    }
}
