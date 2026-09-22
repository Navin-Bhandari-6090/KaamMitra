using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace application.Migrations
{
    /// <inheritdoc />
    public partial class adduserapprovalstatuscolumninadvancepaymentinfotable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AdvancePaymentQrInfos",
                columns: table => new
                {
                    QRId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ProviderEmail = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    ProviderNumber = table.Column<int>(type: "integer", nullable: false),
                    QRPhoto = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AdvancePaymentQrInfos", x => x.QRId);
                });

            migrationBuilder.CreateTable(
                name: "BookingInfos",
                columns: table => new
                {
                    BookId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    StartDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    EndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ProviderBookingDescription = table.Column<string>(type: "text", nullable: false),
                    UserBookingDescription = table.Column<string>(type: "text", nullable: false),
                    ServiceName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Distance = table.Column<double>(type: "double precision", nullable: false),
                    UserEmail = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    ProviderEmail = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    ProviderApprovalStatus = table.Column<bool>(type: "boolean", nullable: false),
                    UserApprovalStatus = table.Column<bool>(type: "boolean", nullable: false),
                    ProviderTaskCompleteStatus = table.Column<bool>(type: "boolean", nullable: false),
                    UserTaskCompleteStatus = table.Column<bool>(type: "boolean", nullable: false),
                    AdvancePaymentAmount = table.Column<double>(type: "double precision", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BookingInfos", x => x.BookId);
                });

            migrationBuilder.CreateTable(
                name: "NewNotificationInfos",
                columns: table => new
                {
                    NewNotId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ReceiverEmail = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Status = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NewNotificationInfos", x => x.NewNotId);
                });

            migrationBuilder.CreateTable(
                name: "NotificationInfos",
                columns: table => new
                {
                    NotId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ReceiverEmail = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Message = table.Column<string>(type: "text", nullable: false),
                    Date = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotificationInfos", x => x.NotId);
                });

            migrationBuilder.CreateTable(
                name: "RatingInfos",
                columns: table => new
                {
                    RtingId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    RatingReceiver = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    RatingGiver = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    RatingValue = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ServiceName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RatingInfos", x => x.RtingId);
                });

            migrationBuilder.CreateTable(
                name: "ServiceInfos",
                columns: table => new
                {
                    ServiceId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServiceName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ServiceDescription = table.Column<string>(type: "text", nullable: false),
                    DomesticPrice = table.Column<int>(type: "integer", nullable: false),
                    DomesticPriceDiscount = table.Column<int>(type: "integer", nullable: false),
                    InternationalPrice = table.Column<int>(type: "integer", nullable: false),
                    InternationalPriceDiscount = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServiceInfos", x => x.ServiceId);
                });

            migrationBuilder.CreateTable(
                name: "UserInfos",
                columns: table => new
                {
                    UserNumber = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    FirstName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    LastName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Email = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Address = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    PhoneNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    WhatsappPhoneNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Password = table.Column<string>(type: "text", nullable: false),
                    Latitude = table.Column<double>(type: "double precision", nullable: false),
                    Longitude = table.Column<double>(type: "double precision", nullable: false),
                    Photo = table.Column<string>(type: "text", nullable: false),
                    Role = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    LoginAccess = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserInfos", x => x.UserNumber);
                });

            migrationBuilder.CreateTable(
                name: "AdvancePaymentInfos",
                columns: table => new
                {
                    PaymentId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PaymentPhoto = table.Column<string>(type: "text", nullable: false),
                    BookId = table.Column<int>(type: "integer", nullable: false),
                    UserEmail = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    ProviderEmail = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    ProviderNumber = table.Column<int>(type: "integer", nullable: false),
                    UserNumber = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AdvancePaymentInfos", x => x.PaymentId);
                    table.ForeignKey(
                        name: "FK_AdvancePaymentInfos_BookingInfos_BookId",
                        column: x => x.BookId,
                        principalTable: "BookingInfos",
                        principalColumn: "BookId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ProviderServiceInfo",
                columns: table => new
                {
                    ProviderServiceId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServiceName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ServiceDocument = table.Column<string>(type: "text", nullable: false),
                    Email = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    UserNumber = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProviderServiceInfo", x => x.ProviderServiceId);
                    table.ForeignKey(
                        name: "FK_ProviderServiceInfo_UserInfos_UserNumber",
                        column: x => x.UserNumber,
                        principalTable: "UserInfos",
                        principalColumn: "UserNumber",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ProviderServiceResourcesInfo",
                columns: table => new
                {
                    ProviderServiceResourcesId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServicePhoto = table.Column<string>(type: "text", nullable: false),
                    ServiceVideo = table.Column<string>(type: "text", nullable: false),
                    ProviderServiceId = table.Column<int>(type: "integer", nullable: false),
                    Email = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    UserNumber = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProviderServiceResourcesInfo", x => x.ProviderServiceResourcesId);
                    table.ForeignKey(
                        name: "FK_ProviderServiceResourcesInfo_ProviderServiceInfo_ProviderSe~",
                        column: x => x.ProviderServiceId,
                        principalTable: "ProviderServiceInfo",
                        principalColumn: "ProviderServiceId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ProviderServiceResourcesInfo_UserInfos_UserNumber",
                        column: x => x.UserNumber,
                        principalTable: "UserInfos",
                        principalColumn: "UserNumber",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AdvancePaymentInfos_BookId",
                table: "AdvancePaymentInfos",
                column: "BookId");

            migrationBuilder.CreateIndex(
                name: "IX_ProviderServiceInfo_UserNumber",
                table: "ProviderServiceInfo",
                column: "UserNumber");

            migrationBuilder.CreateIndex(
                name: "IX_ProviderServiceResourcesInfo_ProviderServiceId",
                table: "ProviderServiceResourcesInfo",
                column: "ProviderServiceId");

            migrationBuilder.CreateIndex(
                name: "IX_ProviderServiceResourcesInfo_UserNumber",
                table: "ProviderServiceResourcesInfo",
                column: "UserNumber");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AdvancePaymentInfos");

            migrationBuilder.DropTable(
                name: "AdvancePaymentQrInfos");

            migrationBuilder.DropTable(
                name: "NewNotificationInfos");

            migrationBuilder.DropTable(
                name: "NotificationInfos");

            migrationBuilder.DropTable(
                name: "ProviderServiceResourcesInfo");

            migrationBuilder.DropTable(
                name: "RatingInfos");

            migrationBuilder.DropTable(
                name: "ServiceInfos");

            migrationBuilder.DropTable(
                name: "BookingInfos");

            migrationBuilder.DropTable(
                name: "ProviderServiceInfo");

            migrationBuilder.DropTable(
                name: "UserInfos");
        }
    }
}
