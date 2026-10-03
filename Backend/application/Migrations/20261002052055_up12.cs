using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace application.Migrations
{
    /// <inheritdoc />
    public partial class up12 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ReceiverEmail",
                table: "NotificationInfos");

            migrationBuilder.DropColumn(
                name: "ReceiverEmail",
                table: "NewNotificationInfos");

            migrationBuilder.AddColumn<int>(
                name: "ReceiverNumber",
                table: "NotificationInfos",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "ReceiverNumber",
                table: "NewNotificationInfos",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ReceiverNumber",
                table: "NotificationInfos");

            migrationBuilder.DropColumn(
                name: "ReceiverNumber",
                table: "NewNotificationInfos");

            migrationBuilder.AddColumn<string>(
                name: "ReceiverEmail",
                table: "NotificationInfos",
                type: "character varying(200)",
                maxLength: 200,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ReceiverEmail",
                table: "NewNotificationInfos",
                type: "character varying(200)",
                maxLength: 200,
                nullable: false,
                defaultValue: "");
        }
    }
}
