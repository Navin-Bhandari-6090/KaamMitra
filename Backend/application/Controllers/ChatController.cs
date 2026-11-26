using application.Data;
using application.Models;
using application.Models.DTOModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using application.Services;

namespace application.Controllers
{
    // Route: api/Chat
    //
    //  OLD (kept, do not use in new code):
    //    POST getmychatmessage   loads EVERY message of the user (does not scale)
    //    POST getchatmessage     loads the whole history of one chat
    //
    //  NEW (used by the chat screen and the message screen):
    //    GET  conversations      my chats, newest first, paged
    //    GET  searchusers        people by name / id, paged
    //    POST messages           messages of one chat, paged (scroll up for more)
    //    POST send               save a message (Sent / Delivered / Read) + push it live
    //    POST markread           mark a chat as read + push read ticks
    //    GET  unread             total unread (home screen icon)
    //
    //  Status codes used by every method:
    //    525  current user is not valid (bad JWT, user not found, or blocked
    //         by KaamMitra): the frontend must log the user out.
    [Route("api/[controller]")]
    [ApiController]
    public class ChatController : ControllerBase
    {
        public DatabaseController Database { get; set; }
        private readonly IWebHostEnvironment _environment;
        private readonly IHubContext<ChatHub> _hub;

        public ChatController(
            DatabaseController database,
            IWebHostEnvironment environment,
            IHubContext<ChatHub> hub)
        {
            this.Database = database;
            this._environment = environment;
            this._hub = hub;
        }

        // =====================================================================
        // HELPERS
        // =====================================================================
        private bool TryGetMe(out int me)
        {
            return int.TryParse(
                User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out me);
        }

        // Current user from the JWT, only when the user exists and is not
        // blocked. Returns null otherwise (the caller returns 525).
        private async Task<int?> GetValidMeAsync()
        {
            if (!TryGetMe(out int me) || me <= 0)
            {
                return null;
            }

            bool valid = await Database.UserInfos.AsNoTracking()
                .AnyAsync(u => u.UserNumber == me && u.LoginAccess != false);

            return valid ? me : (int?)null;
        }

        private IActionResult NotValidated()
        {
            return StatusCode(525, "User is not validated.");
        }

        // Server time is UTC. "o" format ends with Z so every client reads it right.
        private static string Iso(DateTime d)
        {
            return DateTime.SpecifyKind(d, DateTimeKind.Utc).ToString("o");
        }

        private static string? IsoOrNull(DateTime? d)
        {
            return d.HasValue ? Iso(d.Value) : null;
        }

        // Status a new message gets right now:
        //   receiver is on this chat's message screen -> Read
        //   receiver is connected (any other screen)  -> Delivered
        //   receiver is offline                       -> Sent
        private static int StatusFor(int receiverNumber, int senderNumber)
        {
            if (ChatHub.IsChatOpen(receiverNumber, senderNumber))
            {
                return ChatMessageStatus.Read;
            }

            if (ChatHub.IsUserOnline(receiverNumber))
            {
                return ChatMessageStatus.Delivered;
            }

            return ChatMessageStatus.Sent;
        }

        private static object MessagePayload(ChatInfoModel m, string clientId)
        {
            return new
            {
                ChatId = m.ChatId,
                SenderNumber = m.SenderNumber,
                ReceiverNumber = m.ReceiverNumber,
                Message = m.Message,
                StoreAt = Iso(m.StoreAt),
                Status = m.Status,
                DeliveredAt = IsoOrNull(m.DeliveredAt),
                ReadAt = IsoOrNull(m.ReadAt),
                IsRead = m.Status == ChatMessageStatus.Read,
                ClientId = clientId
            };
        }

        // =====================================================================
        // NEW: conversations (one row per person, newest first, paged)
        // =====================================================================
        [Authorize(Policy = "RequireforAllRole")]
        [HttpGet]
        [Route("conversations")]
        public async Task<IActionResult> GetConversations(
            [FromQuery] int page = 1, [FromQuery] int pageSize = 30)
        {
            try
            {
                int? meValue = await GetValidMeAsync();
                if (!meValue.HasValue) return NotValidated();
                int me = meValue.Value;

                page = Math.Max(page, 1);
                pageSize = Math.Clamp(pageSize, 1, 50);

                var groups = Database.ChatInfos.AsNoTracking()
                    .Where(x => x.SenderNumber == me || x.ReceiverNumber == me)
                    .GroupBy(x => x.SenderNumber == me ? x.ReceiverNumber : x.SenderNumber)
                    .Select(g => new
                    {
                        Partner = g.Key,
                        LastChatId = g.Max(x => x.ChatId),
                        Unread = g.Count(x => x.ReceiverNumber == me &&
                                              x.Status < ChatMessageStatus.Read)
                    })
                    .OrderByDescending(g => g.LastChatId);

                var rows = await groups
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize + 1)
                    .ToListAsync();

                bool hasMore = rows.Count > pageSize;
                if (hasMore) rows = rows.Take(pageSize).ToList();

                var ids = rows.Select(r => r.LastChatId).ToList();
                var partners = rows.Select(r => r.Partner).ToList();

                var lastMsgs = await Database.ChatInfos.AsNoTracking()
                    .Where(x => ids.Contains(x.ChatId))
                    .ToDictionaryAsync(x => x.ChatId);

                var users = await Database.UserInfos.AsNoTracking()
                    .Where(u => partners.Contains(u.UserNumber))
                    .Select(u => new { u.UserNumber, u.FirstName, u.LastName, u.LoginAccess, u.Photo })
                    .ToDictionaryAsync(u => u.UserNumber);

                var items = rows.Select(r =>
                {
                    lastMsgs.TryGetValue(r.LastChatId, out var m);
                    users.TryGetValue(r.Partner, out var u);

                    int lastStatus = m?.Status ?? ChatMessageStatus.Read;

                    return new
                    {
                        UserNumber = r.Partner,
                        Name = u == null
                            ? $"User {r.Partner}"
                            : $"{u.FirstName} {u.LastName}".Trim(),
                        Photo = u?.Photo ?? "",
                        Blocked = u != null && u.LoginAccess == false,
                        LastChatId = r.LastChatId,
                        LastMessage = m?.Message ?? "",
                        LastSenderNumber = m?.SenderNumber ?? 0,
                        LastMessageAt = m == null ? "" : Iso(m.StoreAt),
                        LastStatus = lastStatus,
                        LastIsRead = lastStatus == ChatMessageStatus.Read,
                        UnreadCount = r.Unread
                    };
                }).ToList();

                // My own name + photo, sent once with page 1.
                object? meInfo = null;
                if (page == 1)
                {
                    var mine = await Database.UserInfos.AsNoTracking()
                        .Where(u => u.UserNumber == me)
                        .Select(u => new { u.UserNumber, u.FirstName, u.LastName, u.Photo })
                        .FirstOrDefaultAsync();

                    if (mine != null)
                    {
                        meInfo = new
                        {
                            UserNumber = mine.UserNumber,
                            Name = $"{mine.FirstName} {mine.LastName}".Trim(),
                            Photo = mine.Photo ?? ""
                        };
                    }
                }

                return Ok(new { items, hasMore, page, Me = meInfo });
            }
            catch (Exception)
            {
                return StatusCode(500, "Could not load conversations.");
            }
        }

        // =====================================================================
        // NEW: search people by name or user id (empty q = everyone), paged
        // =====================================================================
        [Authorize(Policy = "RequireforAllRole")]
        [HttpGet]
        [Route("searchusers")]
        public async Task<IActionResult> SearchUsers(
            [FromQuery] string? q, [FromQuery] int page = 1, [FromQuery] int pageSize = 30)
        {
            try
            {
                int? meValue = await GetValidMeAsync();
                if (!meValue.HasValue) return NotValidated();
                int me = meValue.Value;

                page = Math.Max(page, 1);
                pageSize = Math.Clamp(pageSize, 1, 50);

                var query = Database.UserInfos.AsNoTracking()
                    .Where(u => u.UserNumber != me && u.LoginAccess != false);

                string term = (q ?? "").Trim();
                if (term.Length > 0)
                {
                    string esc = term.Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_");
                    string pattern = $"%{esc}%";

                    query = query.Where(u =>
                        EF.Functions.ILike((u.FirstName ?? "") + " " + (u.LastName ?? ""), pattern, "\\") ||
                        u.UserNumber.ToString().Contains(term));
                }

                var rows = await query
                    .OrderBy(u => u.FirstName).ThenBy(u => u.LastName).ThenBy(u => u.UserNumber)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize + 1)
                    .Select(u => new { u.UserNumber, u.FirstName, u.LastName, u.Photo })
                    .ToListAsync();

                bool hasMore = rows.Count > pageSize;
                if (hasMore) rows = rows.Take(pageSize).ToList();

                var items = rows.Select(u => new
                {
                    u.UserNumber,
                    Name = $"{u.FirstName} {u.LastName}".Trim(),
                    Photo = u.Photo ?? ""
                });

                return Ok(new { items, hasMore, page });
            }
            catch (Exception)
            {
                return StatusCode(500, "Could not search users.");
            }
        }

        // =====================================================================
        // NEW: messages of one chat, paged. First page = newest messages.
        // Send BeforeChatId (the oldest ChatId you have) to load older ones.
        // =====================================================================
        [Authorize(Policy = "RequireforAllRole")]
        [HttpPost]
        [Route("messages")]
        public async Task<IActionResult> GetMessages([FromBody] ChatMessagesPageDTO model)
        {
            try
            {
                int? meValue = await GetValidMeAsync();
                if (!meValue.HasValue) return NotValidated();
                int me = meValue.Value;

                if (model == null || model.UserNumber <= 0 || model.UserNumber == me)
                    return StatusCode(400, "Invalid user.");

                int other = model.UserNumber;
                int limit = Math.Clamp(model.Limit, 1, 100);

                var query = Database.ChatInfos.AsNoTracking().Where(x =>
                    (x.SenderNumber == me && x.ReceiverNumber == other) ||
                    (x.SenderNumber == other && x.ReceiverNumber == me));

                if (model.BeforeChatId.HasValue)
                    query = query.Where(x => x.ChatId < model.BeforeChatId.Value);

                var page = await query
                    .OrderByDescending(x => x.ChatId)
                    .Take(limit + 1)
                    .ToListAsync();

                bool hasMore = page.Count > limit;
                if (hasMore) page = page.Take(limit).ToList();
                page.Reverse(); // oldest -> newest

                var messages = page.Select(x => MessagePayload(x, "")).ToList();

                // Photos only with the first page.
                string currentPhoto = "";
                string otherPhoto = "";
                if (!model.BeforeChatId.HasValue)
                {
                    var photos = await Database.UserInfos.AsNoTracking()
                        .Where(u => u.UserNumber == me || u.UserNumber == other)
                        .Select(u => new { u.UserNumber, u.Photo })
                        .ToListAsync();

                    currentPhoto = photos.FirstOrDefault(p => p.UserNumber == me)?.Photo ?? "";
                    otherPhoto = photos.FirstOrDefault(p => p.UserNumber == other)?.Photo ?? "";
                }

                return Ok(new
                {
                    messages,
                    hasMore,
                    currentUserPhoto = currentPhoto,
                    otherUserPhoto = otherPhoto
                });
            }
            catch (Exception)
            {
                return StatusCode(500, "Could not load messages.");
            }
        }

        // =====================================================================
        // NEW: send a message. Saves it with its first status, then pushes it
        // live to the receiver and to the sender's other tabs. Returns the
        // saved message (with Status) so the sender shows the right tick.
        //   400 invalid  403 receiver blocked  404 receiver not found
        //   525 sender not valid
        // =====================================================================
        [Authorize(Policy = "RequireforAllRole")]
        [HttpPost]
        [Route("send")]
        public async Task<IActionResult> Send([FromBody] ChatSendDTO model)
        {
            try
            {
                int? meValue = await GetValidMeAsync();
                if (!meValue.HasValue) return NotValidated();
                int me = meValue.Value;

                if (model == null || model.ReceiverNumber <= 0 || model.ReceiverNumber == me)
                    return StatusCode(400, "Invalid receiver.");

                string text = (model.Message ?? "").Trim();
                if (text.Length == 0 || text.Length > 4000)
                    return StatusCode(400, "Message must be 1 to 4000 characters.");

                string clientId = (model.ClientId ?? "").Trim();
                if (clientId.Length > 64) clientId = clientId.Substring(0, 64);

                int receiverNumber = model.ReceiverNumber;

                var receiver = await Database.UserInfos.AsNoTracking()
                    .Where(u => u.UserNumber == receiverNumber)
                    .Select(u => new { u.UserNumber, u.LoginAccess })
                    .FirstOrDefaultAsync();

                if (receiver == null)
                    return StatusCode(404, "The receiver was not found.");

                if (receiver.LoginAccess == false)
                    return StatusCode(403, "The receiver's account is blocked.");

                DateTime now = DateTime.UtcNow;
                int firstStatus = StatusFor(receiverNumber, me);

                var chat = new ChatInfoModel
                {
                    Message = text,
                    SenderNumber = me,
                    ReceiverNumber = receiverNumber,
                    StoreAt = now,
                    Status = firstStatus,
                    DeliveredAt = firstStatus >= ChatMessageStatus.Delivered ? now : (DateTime?)null,
                    ReadAt = firstStatus >= ChatMessageStatus.Read ? now : (DateTime?)null
                };

                Database.ChatInfos.Add(chat);
                await Database.SaveChangesAsync();

                // The receiver may have connected or opened this chat while the
                // message was being saved. Check once more and only move the
                // status forward, never backward.
                int finalStatus = StatusFor(receiverNumber, me);


                if (finalStatus > chat.Status)
                {
                    DateTime later = DateTime.UtcNow;
                    DateTime? laterValue = later;
                    DateTime? readAt = finalStatus >= ChatMessageStatus.Read ? later : (DateTime?)null;

                    int changed = await Database.ChatInfos
                        .Where(x => x.ChatId == chat.ChatId && x.Status < finalStatus)
                        .ExecuteUpdateAsync(s => s
                            .SetProperty(x => x.Status, finalStatus)
                            .SetProperty(x => x.DeliveredAt, x => x.DeliveredAt ?? laterValue)
                            .SetProperty(x => x.ReadAt, x => x.ReadAt ?? readAt));

                    if (changed > 0)
                    {
                        chat.Status = finalStatus;
                        chat.DeliveredAt ??= later;
                        chat.ReadAt ??= readAt;
                    }
                }



                var payload = MessagePayload(chat, clientId);

                // The message is saved. If the live push fails, the receiver
                // still gets it on the next refresh / reconnect.
                try
                {
                    await _hub.Clients.Group(ChatHub.UserGroup(receiverNumber))
                        .SendAsync("ReceiveMessage", payload);

                    await _hub.Clients.Group(ChatHub.UserGroup(me))
                        .SendAsync("ReceiveMessage", payload);
                }
                catch (Exception)
                {
                }

                return Ok(payload);
            }
            catch (Exception)
            {
                return StatusCode(500, "Could not send the message.");
            }
        }

        // =====================================================================
        // NEW: mark everything from one person as read + tell both sides.
        // The hub's OpenChat does the same over SignalR; this REST call is the
        // fallback when SignalR is not connected.
        // =====================================================================
        [Authorize(Policy = "RequireforAllRole")]
        [HttpPost]
        [Route("markread")]
        public async Task<IActionResult> MarkRead([FromBody] UserNumberDTO model)
        {
            try
            {
                int? meValue = await GetValidMeAsync();
                if (!meValue.HasValue) return NotValidated();
                int me = meValue.Value;

                if (model == null || model.UserNumber <= 0 || model.UserNumber == me)
                    return StatusCode(400, "Invalid user.");

                int other = model.UserNumber;

                DateTime now = DateTime.UtcNow;
                DateTime? nowValue = now;

                // Needs EF Core 7 or newer.
                int updated = await Database.ChatInfos
                    .Where(x => x.SenderNumber == other &&
                                x.ReceiverNumber == me &&
                                x.Status < ChatMessageStatus.Read)
                    .ExecuteUpdateAsync(s => s
                        .SetProperty(x => x.Status, ChatMessageStatus.Read)
                        .SetProperty(x => x.DeliveredAt, x => x.DeliveredAt ?? nowValue)
                        .SetProperty(x => x.ReadAt, nowValue));




                if (updated > 0)
                {
                    try
                    {
                        // Blue ticks for the sender (same event as the hub's OpenChat).
                        await _hub.Clients.Group(ChatHub.UserGroup(other))
                            .SendAsync("ConversationRead", new
                            {
                                ReaderNumber = me,
                                ReadAt = now
                            });

                        // Clears the unread badge in my other tabs / devices.
                        await _hub.Clients.Group(ChatHub.UserGroup(me))
                            .SendAsync("UnreadCleared", new { UserNumber = other });
                    }
                    catch (Exception)
                    {
                    }
                }

                return Ok(new { updated });
            }
            catch (Exception)
            {
                return StatusCode(500, "Could not mark messages as read.");
            }
        }

        // =====================================================================
        // NEW: total unread for me (home screen chat icon).
        // Unread = not Read yet (Sent or Delivered).
        // =====================================================================
        [Authorize(Policy = "RequireforAllRole")]
        [HttpGet]
        [Route("unread")]
        public async Task<IActionResult> GetUnread()
        {
            try
            {
                int? meValue = await GetValidMeAsync();
                if (!meValue.HasValue) return NotValidated();
                int me = meValue.Value;

                var unread = Database.ChatInfos.AsNoTracking()
                    .Where(x => x.ReceiverNumber == me &&
                                x.Status < ChatMessageStatus.Read);

                int total = await unread.CountAsync();
                int people = await unread.Select(x => x.SenderNumber).Distinct().CountAsync();

                return Ok(new { total, people });
            }
            catch (Exception)
            {
                return StatusCode(500, "Could not load the unread count.");
            }
        }

        // =====================================================================
        // OLD (same behavior, only the user check now returns 525)
        // =====================================================================
        [HttpPost]
        [Authorize(Policy = "RequireforAllRole")]
        [Route("getmychatmessage")]
        public async Task<IActionResult> GetMyChatMessages()
        {
            try
            {
                int? meValue = await GetValidMeAsync();
                if (!meValue.HasValue) return NotValidated();
                int CurrentUserNumber = meValue.Value;

                var ChatMessages = await Database.ChatInfos
                   .Where(x =>
                       (x.SenderNumber == CurrentUserNumber ||
                        x.ReceiverNumber == CurrentUserNumber)).OrderBy(x => x.StoreAt)
                   .ThenBy(x => x.ChatId)
                   .ToListAsync();

                return StatusCode(200, ChatMessages);
            }
            catch (Exception)
            {
                return StatusCode(500);
            }
        }

        [HttpPost]
        [Authorize(Policy = "RequireforAllRole")]
        [Route("getchatmessage")]
        public async Task<IActionResult> GetChatMessages([FromBody] UserNumberDTO model)
        {
            try
            {
                int? meValue = await GetValidMeAsync();
                if (!meValue.HasValue) return NotValidated();
                int CurrentUserNumber = meValue.Value;

                // Validate other user number
                if (model == null ||
                    model.UserNumber <= 0 ||
                    model.UserNumber == CurrentUserNumber)
                {
                    return StatusCode(507);
                }

                var OtherUserNumber = model.UserNumber;

                // Get both users' profile photos
                var UserPhotos = await Database.UserInfos
                    .Where(x =>
                        x.UserNumber == CurrentUserNumber ||
                        x.UserNumber == OtherUserNumber)
                    .Select(x => new
                    {
                        x.UserNumber,
                        x.Photo
                    })
                    .ToListAsync();

                // Check whether the other user exists
                var OtherUserData = UserPhotos
                    .FirstOrDefault(x => x.UserNumber == OtherUserNumber);

                if (OtherUserData == null)
                {
                    return StatusCode(512, "Other user not found");
                }

                // Retrieve messages in both directions
                var ChatMessages = await Database.ChatInfos
                    .Where(x =>
                        (x.SenderNumber == CurrentUserNumber &&
                         x.ReceiverNumber == OtherUserNumber)
                        ||
                        (x.SenderNumber == OtherUserNumber &&
                         x.ReceiverNumber == CurrentUserNumber))
                    .OrderBy(x => x.StoreAt)
                    .ThenBy(x => x.ChatId)
                    .ToListAsync();

                // Prepare response
                var Response = new ChatMessagesResponseDTO
                {
                    CurrentUserPhoto = UserPhotos
                        .FirstOrDefault(x => x.UserNumber == CurrentUserNumber)?.Photo,

                    OtherUserPhoto = OtherUserData.Photo,

                    ChatMessages = ChatMessages
                };

                return StatusCode(200, Response);
            }
            catch (Exception)
            {
                return StatusCode(500);
            }
        }
    }

    // =========================================================================
    // DTOs of the new endpoints
    // =========================================================================
    public class ChatSendDTO
    {
        public int ReceiverNumber { get; set; }
        public string? Message { get; set; }

        // Created by the app so it can match its temporary "sending" bubble.
        public string? ClientId { get; set; }
    }

    public class ChatMessagesPageDTO
    {
        public int UserNumber { get; set; }
        public int? BeforeChatId { get; set; }
        public int Limit { get; set; } = 30;
    }
}