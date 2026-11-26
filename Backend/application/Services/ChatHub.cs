using application.Data;
using application.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using System.Collections.Concurrent;
using System.Security.Claims;

namespace application.Services
{
    // Real-time channel (mapped at /chatHub, unchanged).
    //
    // Messages are NOT sent through the hub: ChatController saves them and
    // pushes "ReceiveMessage" to the user group. The hub does:
    //   - online / offline presence
    //   - which chat screen each connection currently has open
    //   - Delivered (on connect) and Read (on open chat) status updates
    //   - video-call signaling
    //   - NotifyNewMessage (OLD flow, kept so the old message screen still works)
    [Authorize(Policy = "RequireProviderUserRole")]
    public class ChatHub : Hub
    {
        private readonly DatabaseController Database;

        public ChatHub(DatabaseController database)
        {
            Database = database;
        }

        private static readonly ConcurrentDictionary<
            int,
            ConcurrentDictionary<string, byte>
        > OnlineUsers = new();

        // ConnectionId -> (user, the other user whose chat screen is open).
        private static readonly ConcurrentDictionary<
            string,
            (int UserNumber, int OtherNumber)
        > OpenChats = new();

        // Public: ChatController uses it to push to one user.
        public static string UserGroup(int UserNumber)
        {
            return $"user_{UserNumber}";
        }

        // Public: true when the user has at least one live connection.
        public static bool IsUserOnline(int UserNumber)
        {
            return OnlineUsers.TryGetValue(UserNumber, out var Set) && !Set.IsEmpty;
        }

        // Public: true when the user is on the message screen of this exact chat.
        public static bool IsChatOpen(int UserNumber, int OtherNumber)
        {
            foreach (var Item in OpenChats.Values)
            {
                if (Item.UserNumber == UserNumber && Item.OtherNumber == OtherNumber)
                {
                    return true;
                }
            }

            return false;
        }

        private int? GetCurrentUserNumber()
        {
            try
            {
                var UserNumberClaim =
                    Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (int.TryParse(UserNumberClaim, out int UserNumber))
                {
                    return UserNumber;
                }

                return null;
            }
            catch (Exception)
            {
                return null;
            }
        }

        private bool IsValidRecipient(int ReceiverNumber)
        {
            var CurrentUserNumber = GetCurrentUserNumber();

            return CurrentUserNumber.HasValue
                && ReceiverNumber > 0
                && ReceiverNumber != CurrentUserNumber.Value;
        }

        // ---------------------------------------------------------------------
        // PRESENCE (safe when one user connects / disconnects from many tabs
        // at the same moment)
        // ---------------------------------------------------------------------

        // Returns true when the user was offline before this connection.
        private static bool AddConnection(int UserNumber, string ConnectionId)
        {
            while (true)
            {
                var Set = OnlineUsers.GetOrAdd(
                    UserNumber,
                    _ => new ConcurrentDictionary<string, byte>()
                );

                lock (Set)
                {
                    // The set was removed by a disconnect just now: try again.
                    if (!OnlineUsers.TryGetValue(UserNumber, out var Current) ||
                        !ReferenceEquals(Current, Set))
                    {
                        continue;
                    }

                    bool WasOffline = Set.IsEmpty;
                    Set.TryAdd(ConnectionId, 0);
                    return WasOffline;
                }
            }
        }

        // Returns true when the user has no connection left.
        private static bool RemoveConnection(int UserNumber, string ConnectionId)
        {
            if (!OnlineUsers.TryGetValue(UserNumber, out var Set))
            {
                return false;
            }

            lock (Set)
            {
                Set.TryRemove(ConnectionId, out _);

                if (!Set.IsEmpty)
                {
                    return false;
                }

                OnlineUsers.TryRemove(
                    new KeyValuePair<int, ConcurrentDictionary<string, byte>>(
                        UserNumber,
                        Set
                    )
                );

                return true;
            }
        }

        public override async Task OnConnectedAsync()
        {
            try
            {
                var UserNumber = GetCurrentUserNumber();

                if (!UserNumber.HasValue)
                {
                    Context.Abort();
                    return;
                }

                await Groups.AddToGroupAsync(
                    Context.ConnectionId,
                    UserGroup(UserNumber.Value)
                );

                bool WasOffline = AddConnection(UserNumber.Value, Context.ConnectionId);

                if (WasOffline)
                {
                    await Clients.Others.SendAsync("UserOnline", UserNumber.Value);

                    // Messages sent while this user was offline are now Delivered.
                    await MarkSentAsDelivered(UserNumber.Value);
                }

                await Clients.Caller.SendAsync(
                    "OnlineUsers",
                    OnlineUsers.Keys.ToArray()
                );

                await base.OnConnectedAsync();
            }
            catch (Exception)
            {
                Context.Abort();
            }
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            try
            {
                // This connection can no longer have a chat screen open.
                OpenChats.TryRemove(Context.ConnectionId, out _);

                var UserNumber = GetCurrentUserNumber();

                if (UserNumber.HasValue &&
                    RemoveConnection(UserNumber.Value, Context.ConnectionId))
                {
                    await Clients.Others.SendAsync("UserOffline", UserNumber.Value);
                }

                await base.OnDisconnectedAsync(exception);
            }
            catch (Exception)
            {
            }
        }

        // ---------------------------------------------------------------------
        // MESSAGE STATUS: Sent(1) -> Delivered(2) -> Read(3), never backwards.
        // ---------------------------------------------------------------------

        // Receiver just came online: Sent -> Delivered, and tell each sender.
        private async Task MarkSentAsDelivered(int ReceiverNumber)
        {
            try
            {
                var Now = DateTime.UtcNow;
                DateTime? NowValue = Now;

                var SenderNumbers = await Database.ChatInfos
                    .Where(x => x.ReceiverNumber == ReceiverNumber &&
                                x.Status == ChatMessageStatus.Sent)
                    .Select(x => x.SenderNumber)
                    .Distinct()
                    .ToListAsync();

                if (SenderNumbers.Count == 0)
                {
                    return;
                }

                await Database.ChatInfos
                    .Where(x => x.ReceiverNumber == ReceiverNumber &&
                                x.Status == ChatMessageStatus.Sent)
                    .ExecuteUpdateAsync(s => s
                        .SetProperty(x => x.Status, ChatMessageStatus.Delivered)
                        .SetProperty(x => x.DeliveredAt, NowValue));

                foreach (var SenderNumber in SenderNumbers)
                {
                    await Clients.Group(UserGroup(SenderNumber)).SendAsync(
                        "MessagesDelivered",
                        new
                        {
                            ReceiverNumber,
                            DeliveredAt = Now
                        }
                    );
                }
            }
            catch (Exception)
            {
                // Status is best effort; the user connection must not fail.
            }
        }

        // The message screen for this chat is open (or came back to the front).
        // Marks every earlier message from OtherNumber as Read and tells them.
        public async Task OpenChat(int OtherNumber)
        {
            try
            {
                var UserNumber = GetCurrentUserNumber();

                if (!UserNumber.HasValue || !IsValidRecipient(OtherNumber))
                {
                    throw new HubException("Invalid chat.");
                }

                OpenChats[Context.ConnectionId] = (UserNumber.Value, OtherNumber);

                var Now = DateTime.UtcNow;
                DateTime? NowValue = Now;

                int Changed = await Database.ChatInfos
                    .Where(x => x.SenderNumber == OtherNumber &&
                                x.ReceiverNumber == UserNumber.Value &&
                                x.Status < ChatMessageStatus.Read)
                    .ExecuteUpdateAsync(s => s
                        .SetProperty(x => x.Status, ChatMessageStatus.Read)
                        .SetProperty(x => x.DeliveredAt, x => x.DeliveredAt ?? NowValue)
                        .SetProperty(x => x.ReadAt, NowValue));

                if (Changed > 0)
                {
                    // Blue ticks for the other person.
                    await Clients.Group(UserGroup(OtherNumber)).SendAsync(
                        "ConversationRead",
                        new
                        {
                            ReaderNumber = UserNumber.Value,
                            ReadAt = Now
                        }
                    );

                    // Clears the unread badge in my other tabs / devices.
                    await Clients.Group(UserGroup(UserNumber.Value)).SendAsync(
                        "UnreadCleared",
                        new { UserNumber = OtherNumber }
                    );
                }
            }
            catch (HubException)
            {
                throw;
            }
            catch (Exception)
            {
                throw new HubException("Could not open the chat.");
            }
        }

        // The message screen was closed, or the tab went to the background.
        public Task CloseChat()
        {
            OpenChats.TryRemove(Context.ConnectionId, out _);
            return Task.CompletedTask;
        }

        // The message screen is open and a new message arrived: mark it Read.
        public async Task MarkMessageRead(int ChatId)
        {
            try
            {
                var UserNumber = GetCurrentUserNumber();

                if (!UserNumber.HasValue || ChatId <= 0)
                {
                    throw new HubException("Invalid message.");
                }

                var Message = await Database.ChatInfos
                    .Where(x => x.ChatId == ChatId &&
                                x.ReceiverNumber == UserNumber.Value &&
                                x.Status < ChatMessageStatus.Read)
                    .Select(x => new { x.SenderNumber })
                    .FirstOrDefaultAsync();

                if (Message == null)
                {
                    return;
                }

                var Now = DateTime.UtcNow;
                DateTime? NowValue = Now;

                await Database.ChatInfos
                    .Where(x => x.ChatId == ChatId &&
                                x.ReceiverNumber == UserNumber.Value &&
                                x.Status < ChatMessageStatus.Read)
                    .ExecuteUpdateAsync(s => s
                        .SetProperty(x => x.Status, ChatMessageStatus.Read)
                        .SetProperty(x => x.DeliveredAt, x => x.DeliveredAt ?? NowValue)
                        .SetProperty(x => x.ReadAt, NowValue));

                await Clients.Group(UserGroup(Message.SenderNumber)).SendAsync(
                    "MessagesRead",
                    new
                    {
                        ReaderNumber = UserNumber.Value,
                        ChatIds = new[] { ChatId },
                        ReadAt = Now
                    }
                );

                // Clears this chat's unread badge in my other tabs / devices.
                await Clients.Group(UserGroup(UserNumber.Value)).SendAsync(
                    "UnreadCleared",
                    new { UserNumber = Message.SenderNumber }
                );
            }
            catch (HubException)
            {
                throw;
            }
            catch (Exception)
            {
                throw new HubException("Could not mark the message as read.");
            }
        }

        // ---------------------------------------------------------------------
        // OLD FLOW: called AFTER the REST API saved the message. The new screens
        // do not use it (ChatController/send pushes the message itself).
        // Remove it when the old message screen is gone.
        // ---------------------------------------------------------------------
        public async Task NotifyNewMessage(
            int ReceiverNumber,
            int ChatId,
            string Message,
            string StoreAt)
        {
            try
            {
                var SenderNumber = GetCurrentUserNumber();

                if (!SenderNumber.HasValue ||
                    !IsValidRecipient(ReceiverNumber) ||
                    ChatId <= 0 ||
                    string.IsNullOrWhiteSpace(Message))
                {
                    throw new HubException("Invalid message notification.");
                }

                await Clients.Group(UserGroup(ReceiverNumber)).SendAsync(
                    "ReceiveMessage",
                    new
                    {
                        ChatId,
                        SenderNumber = SenderNumber.Value,
                        ReceiverNumber,
                        Message,
                        StoreAt
                    }
                );
            }
            catch (HubException)
            {
                throw;
            }
            catch (Exception)
            {
                throw new HubException("Could not notify the recipient.");
            }
        }

        // ---------------------------------------------------------------------
        // VIDEO CALL SIGNALING (same method names and payloads as before)
        // ---------------------------------------------------------------------
        private async Task Relay(
            string ClientMethod,
            int ReceiverNumber,
            string CallId,
            string? PayloadName,
            object? Payload)
        {
            try
            {
                var SenderNumber = GetCurrentUserNumber();

                if (!SenderNumber.HasValue ||
                    !IsValidRecipient(ReceiverNumber) ||
                    string.IsNullOrWhiteSpace(CallId) ||
                    (PayloadName != null && Payload == null))
                {
                    throw new HubException("Invalid call request.");
                }

                var Data = new Dictionary<string, object?>
                {
                    ["callId"] = CallId,
                    ["senderNumber"] = SenderNumber.Value,
                    ["receiverNumber"] = ReceiverNumber
                };

                if (PayloadName != null)
                {
                    Data[PayloadName] = Payload;
                }

                await Clients.Group(UserGroup(ReceiverNumber))
                    .SendAsync(ClientMethod, Data);
            }
            catch (HubException)
            {
                throw;
            }
            catch (Exception)
            {
                throw new HubException("Could not send the call signal.");
            }
        }

        // WebRTC: send an offer to the recipient.
        public Task SendCallOffer(int ReceiverNumber, string CallId, object Offer)
        {
            return Relay("IncomingCall", ReceiverNumber, CallId, "offer", Offer);
        }

        // WebRTC: return the answer to the caller.
        public Task SendCallAnswer(int ReceiverNumber, string CallId, object Answer)
        {
            return Relay("CallAnswer", ReceiverNumber, CallId, "answer", Answer);
        }

        // WebRTC: exchange ICE candidates.
        public Task SendIceCandidate(int ReceiverNumber, string CallId, object Candidate)
        {
            return Relay("IceCandidate", ReceiverNumber, CallId, "candidate", Candidate);
        }

        // Tell the other participant that the call has ended.
        public Task EndVideoCall(int ReceiverNumber, string CallId)
        {
            return Relay("CallEnded", ReceiverNumber, CallId, null, null);
        }
    }
}