using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Collections.Concurrent;
using System.Security.Claims;

namespace application.Services
{
    [Authorize(Policy = "RequireProviderUserRole")]
    public class ChatHub : Hub
    {
        private static readonly ConcurrentDictionary<
            int,
            ConcurrentDictionary<string, byte>
        > OnlineUsers = new();

        private static string UserGroup(int UserNumber)
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
            catch (Exception ex)
            {
                Console.WriteLine($"GetCurrentUserNumber error: {ex.Message}");
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

                var Connections = OnlineUsers.GetOrAdd(
                    UserNumber.Value,
                    _ => new ConcurrentDictionary<string, byte>()
                );

                bool WasOffline = Connections.IsEmpty;

                Connections.TryAdd(Context.ConnectionId, 0);

                await Groups.AddToGroupAsync(
                    Context.ConnectionId,
                    UserGroup(UserNumber.Value)
                );

                Console.WriteLine(
                    $"SignalR connected: UserNumber={UserNumber.Value}, " +
                    $"ConnectionId={Context.ConnectionId}"
                );

                if (WasOffline)
                {
                    await Clients.All.SendAsync(
                        "UserOnline",
                        UserNumber.Value
                    );
                }

                await Clients.Caller.SendAsync(
                    "OnlineUsers",
                    OnlineUsers.Keys.ToArray()
                );

                await base.OnConnectedAsync();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"OnConnectedAsync error: {ex.Message}");
                Context.Abort();
            }
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            try
            {
                var UserNumber = GetCurrentUserNumber();

                if (UserNumber.HasValue &&
                    OnlineUsers.TryGetValue(UserNumber.Value, out var Connections))
                {
                    Connections.TryRemove(Context.ConnectionId, out _);

                    if (Connections.IsEmpty &&
                        OnlineUsers.TryRemove(UserNumber.Value, out _))
                    {
                        await Clients.All.SendAsync(
                            "UserOffline",
                            UserNumber.Value
                        );
                    }
                }

                Console.WriteLine(
                    $"SignalR disconnected: ConnectionId={Context.ConnectionId}, " +
                    $"Error={exception?.Message}"
                );

                await base.OnDisconnectedAsync(exception);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"OnDisconnectedAsync error: {ex.Message}");
            }
        }

        // Called AFTER the REST API has saved the message in PostgreSQL.
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
            catch (Exception ex)
            {
                Console.WriteLine($"NotifyNewMessage error: {ex.Message}");
                throw new HubException("Could not notify the recipient.");
            }
        }

        // WebRTC signaling: send an offer to the recipient.
        public async Task SendCallOffer(
            int ReceiverNumber,
            string CallId,
            object Offer)
        {
            try
            {
                var SenderNumber = GetCurrentUserNumber();

                if (!SenderNumber.HasValue ||
                    !IsValidRecipient(ReceiverNumber) ||
                    string.IsNullOrWhiteSpace(CallId) ||
                    Offer == null)
                {
                    throw new HubException("Invalid call offer.");
                }

                await Clients.Group(UserGroup(ReceiverNumber)).SendAsync(
                    "IncomingCall",
                    new
                    {
                        CallId,
                        SenderNumber = SenderNumber.Value,
                        ReceiverNumber,
                        Offer
                    }
                );
            }
            catch (HubException)
            {
                throw;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"SendCallOffer error: {ex.Message}");
                throw new HubException("Could not send the call offer.");
            }
        }

        // WebRTC signaling: return the answer to the caller.
        public async Task SendCallAnswer(
            int ReceiverNumber,
            string CallId,
            object Answer)
        {
            try
            {
                var SenderNumber = GetCurrentUserNumber();

                if (!SenderNumber.HasValue ||
                    !IsValidRecipient(ReceiverNumber) ||
                    string.IsNullOrWhiteSpace(CallId) ||
                    Answer == null)
                {
                    throw new HubException("Invalid call answer.");
                }

                await Clients.Group(UserGroup(ReceiverNumber)).SendAsync(
                    "CallAnswer",
                    new
                    {
                        CallId,
                        SenderNumber = SenderNumber.Value,
                        ReceiverNumber,
                        Answer
                    }
                );
            }
            catch (HubException)
            {
                throw;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"SendCallAnswer error: {ex.Message}");
                throw new HubException("Could not send the call answer.");
            }
        }

        // WebRTC signaling: exchange ICE candidates.
        public async Task SendIceCandidate(
            int ReceiverNumber,
            string CallId,
            object Candidate)
        {
            try
            {
                var SenderNumber = GetCurrentUserNumber();

                if (!SenderNumber.HasValue ||
                    !IsValidRecipient(ReceiverNumber) ||
                    string.IsNullOrWhiteSpace(CallId) ||
                    Candidate == null)
                {
                    throw new HubException("Invalid ICE candidate.");
                }

                await Clients.Group(UserGroup(ReceiverNumber)).SendAsync(
                    "IceCandidate",
                    new
                    {
                        CallId,
                        SenderNumber = SenderNumber.Value,
                        ReceiverNumber,
                        Candidate
                    }
                );
            }
            catch (HubException)
            {
                throw;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"SendIceCandidate error: {ex.Message}");
                throw new HubException("Could not send the ICE candidate.");
            }
        }

        // Notify the other participant that a call has ended.
        public async Task EndVideoCall(
            int ReceiverNumber,
            string CallId)
        {
            try
            {
                var SenderNumber = GetCurrentUserNumber();

                if (!SenderNumber.HasValue ||
                    !IsValidRecipient(ReceiverNumber) ||
                    string.IsNullOrWhiteSpace(CallId))
                {
                    throw new HubException("Invalid call-end request.");
                }

                await Clients.Group(UserGroup(ReceiverNumber)).SendAsync(
                    "CallEnded",
                    new
                    {
                        CallId,
                        SenderNumber = SenderNumber.Value,
                        ReceiverNumber
                    }
                );
            }
            catch (HubException)
            {
                throw;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"EndVideoCall error: {ex.Message}");
                throw new HubException("Could not end the call.");
            }
        }
    }
}