using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Collections.Concurrent;
using System.Security.Claims;

namespace application.Services
{
    // Real-time channel (mapped at /chatHub, unchanged).
    //
    // Messages are NOT sent through the hub any more: ChatController saves them
    // and pushes "ReceiveMessage", "MessagesRead" and "ConversationRead" to the
    // user group. The hub itself only does:
    //   - online / offline presence
    //   - video-call signaling
    //   - NotifyNewMessage (OLD flow, kept so the old message screen still works)
    [Authorize(Policy = "RequireProviderUserRole")]
    public class ChatHub : Hub
    {
        private static readonly ConcurrentDictionary<
            int,
            ConcurrentDictionary<string, byte>
        > OnlineUsers = new();

        // Public: ChatController uses it to push to one user.
        public static string UserGroup(int UserNumber)
        {
            return $"user_{UserNumber}";
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